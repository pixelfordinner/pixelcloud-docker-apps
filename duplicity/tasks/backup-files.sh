DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get settings
source ${DIR}/inc/settings.sh

# Usage backup-files incremental|full

alias duplicity="docker run --rm --user $UID \
                      -e \"PASSPHRASE=${passphrase}\" \
                      -v \"${DIR}/../volumes/duplicity:/home/duplicity\" \
                      -v ${source_dir}:/data:ro \
                      --name pixelcloud-duplicity \
                      pixelfordinner/duplicity \
                      duplicity"


for client_dir in ${source_dir}/*/; do
    client_name=$(basename ${client_dir})
    echo "Found client ${client_name}..."

    for project_dir in ${client_dir}/*/; do
        project_name=$(basename ${project_dir})
        bucket_dest=${bucket}/${client_name}/${project_name}
        echo "> ${project_name} -> ${bucket_dest}..."
        duplicity $1 --allow-source-mismatch /data/${client_name}/${project_name} ${bucket_dest}
        echo "> ${project_name} -> ${bucket_dest} = Done."
    done
done

