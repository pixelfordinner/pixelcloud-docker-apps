#!/bin/bash

log() {
    local prefix=""
    if [ -n "$2" ]; then
        prefix="[$2] "
    fi
    echo "${prefix}$1"
}

get_host_path() {
    local container_id="$1"
    local container_path="$2"

    docker inspect --format="{{range .Mounts}}{{if eq .Destination \"$container_path\"}}{{.Source}}{{end}}{{end}}" "$container_id"
}

get_workdir_host_path() {
    local container_id="$1"
    local workdir=$(docker inspect --format='{{.Config.WorkingDir}}' "$container_id")

    if [ -n "$workdir" ]; then
        get_host_path "$container_id" "$workdir"
    fi
}

# Function to get the current time in seconds with high precision
get_current_time() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Use perl to get high precision current time
        perl -MTime::HiRes -e 'printf("%.6f\n", Time::HiRes::time())'
    else
        # Linux: Use date to get nanoseconds
        date +%s.%N
    fi
}

format_time() {
    LC_NUMERIC="en_US.UTF-8"
    local duration=$1

    if (( $(echo "$duration < 1" | bc -l) )); then
        # Convert to milliseconds
        duration_ms=$(echo "$duration * 1000" | bc -l)
        printf "%.0f ms" "$duration_ms"
    elif (( $(echo "$duration < 60" | bc -l) )); then
        # Convert to seconds
        printf "%.2f s" "$duration"
    else
        # Convert to minutes and seconds
        duration_min=$(echo "$duration / 60" | bc -l)
        duration_sec=$(echo "$duration % 60" | bc -l)
        printf "%d m %.2f s" "$duration_min" "$duration_sec"
    fi
}

execute_timed_command() {
    local container=$1
    local command=$2
    local command_type=$3
    local container_name=$4

    log "Executing $command_type command: $command" "$container_name"
    start_time=$(get_current_time)
    docker exec "$container" sh -c "$command"
    local exit_code=$?
    end_time=$(get_current_time)
    duration=$(echo "$end_time - $start_time" | bc -l)
    formatted_time=$(format_time "$duration")

    if [ $exit_code -eq 0 ]; then
        log "$command_type command completed in $formatted_time" "$container_name"
    else
        log "$command_type command failed with exit code $exit_code after $formatted_time" "$container_name"
    fi
}

execute_forget_command() {
    local container=$1
    local container_name=$2
    local repository=$3

    local forget_policy=$(docker inspect --format '{{index .Config.Labels "pixelcloud.restic.backup.forget"}}' "$container")

    if [ -n "$forget_policy" ]; then
        log "Executing forget command with policy: $forget_policy" "$container_name"

        forget_summary=$(./restic.sh forget "$repository" $forget_policy --json | jq -r '
            def sum(f): reduce .[] as $x (0; . + ($x | f));
            if length == 0 then
                "No snapshots matched the forget policy"
            else
                "Hosts affected: \(map(.host) | unique | join(", "))\n" +
                "Total snapshots kept: \(sum(.keep | length))\n" +
                if sum(.remove | length) > 0 then
                    "Total snapshots removed: \(sum(.remove | length))\n" +
                    "Total size freed: \(sum(.remove_size // 0) | . / 1024 / 1024 | floor) MiB"
                else
                    "No snapshots were removed"
                end
            end
        ')

        if [ -n "$forget_summary" ]; then
            log "Forget command completed. Summary:" "$container_name"
            echo "$forget_summary" | while IFS= read -r line; do
                log "## $line" "$container_name"
            done
        else
            log "Forget command failed or produced no summary" "$container_name"
        fi
    else
        log "No forget policy specified, skipping forget command" "$container_name"
    fi
}

perform_healthcheck() {
    local container=$1
    local container_name=$2

    local healthcheck_url=$(docker inspect --format '{{index .Config.Labels "pixelcloud.restic.backup.healthcheck"}}' "$container")

    if [ -n "$healthcheck_url" ]; then
        log "Running healthcheck" "$container_name"
        if curl -sfS "$healthcheck_url" > /dev/null; then
            log "Healthcheck successful" "$container_name"
        else
            log "Healthcheck failed" "$container_name"
        fi
    else
        log "No healthcheck url specified, skipping healthcheck command" "$container_name"
    fi
}

log "Starting backup process"

# Check if Docker is installed and running
if ! docker info >/dev/null 2>&1; then
    log "Docker is not running or not accessible. Exiting."
    exit 1
fi

# Get all running containers with the specified label
containers=$(docker ps --filter "label=pixelcloud.restic.backup.candidate=true" --format "{{.ID}}")

container_count=$(echo "$containers" | wc -w | xargs)
log "Found $container_count containers to process"

if [ "$container_count" -eq 0 ]; then
    log "No containers found with the specified label. Exiting."
    exit 0
fi

# Iterate through containers
current_container=0
for container in $containers; do
    ((current_container++))

    container_name=$(docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' "$container")
    if [ -z "$container_name" ]; then
        container_name=$(docker inspect --format '{{.Name}}' "$container" | sed 's/\///')
    fi

    log "Processing container $current_container of $container_count" "$container_name"

    # Check and execute pre-backup command
    pre_command=$(docker inspect --format '{{index .Config.Labels "pixelcloud.restic.backup.command.pre"}}' "$container")
    if [ -n "$pre_command" ]; then
        execute_timed_command "$container" "$pre_command" "pre-backup" "$container_name"
    fi

    # Get repository from label
    repository=$(docker inspect --format '{{index .Config.Labels "pixelcloud.restic.backup.repository"}}' "$container")

    # Try to get path from label
    container_path=$(docker inspect --format '{{index .Config.Labels "pixelcloud.restic.backup.path"}}' "$container")
    host_path=$(get_host_path "$container" "$container_path")

    # If host_path is empty, try to use working directory
    if [ -z "$host_path" ]; then
        log "Couldn't get host path from label. Trying container's working directory." "$container_name"
        host_path=$(get_workdir_host_path "$container")
        if [ -n "$host_path" ]; then
            container_path=$(docker inspect --format='{{.Config.WorkingDir}}' "$container")
        fi
    fi

    # Run restic backup if both repository and path are set
    if [ -n "$repository" ] && [ -n "$host_path" ]; then
        log "Checking restic repository" "$container_name"

        # Check if the repository exists
        if ! ./restic.sh snapshots "$repository" &>/dev/null; then
            log "Repository does not exist. Initializing..." "$container_name"
            if ./restic.sh init "$repository"; then
                log "Repository initialized successfully." "$container_name"
            else
                log "Failed to initialize repository. Skipping backup" "$container_name"
                continue
            fi
        fi

        log "Container path: $container_path" "$container_name"
        log "Host path: $host_path" "$container_name"

        # Execute forget command
        execute_forget_command "$container" "$container_name" "$repository"

        backup_summary=$(./restic.sh backup "$repository" "$host_path" --json --quiet | jq -r '
            if .message_type == "summary" then
                "Files: \(.files_new) new, \(.files_changed) changed, \(.total_files_processed) total\n" +
                "Bytes: \(.data_added | tonumber / 1024 / 1024 | floor) MiB added\n" +
                "Duration: \(.total_duration | floor) seconds"
            else
                empty
            end
        ')

        if [ -n "$backup_summary" ]; then
            log "Backup completed. Summary:" "$container_name"
            echo "$backup_summary" | while IFS= read -r line; do
                log "## $line" "$container_name"
            done

            # Perform healthcheck after successful backup
            perform_healthcheck "$container" "$container_name"
        else
            log "Backup failed or produced no summary" "$container_name"
        fi
    else
        log "Skipping restic backup: repository or path not set or not found" "$container_name"
    fi

    # Check and execute post-backup command
    post_command=$(docker inspect --format '{{index .Config.Labels "pixelcloud.restic.backup.command.post"}}' "$container")
    if [ -n "$post_command" ]; then
        execute_timed_command "$container" "$post_command" "post-backup" "$container_name"
    fi

    log "Finished processing" "$container_name"
done

log "Backup process completed"
