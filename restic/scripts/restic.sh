#!/bin/bash

# Load environment variables from .env file
if [ -f ../.env.restic ]; then
    export $(grep -v '^#' ../.env.restic | xargs)
fi

show_help() {
    echo "Usage: $0 <command> [arguments]"
    echo
    echo "Commands:"
    echo "  init <repository>              Initialize a new sub-repository"
    echo "  backup <repository> <path>     Backup a directory"
    echo "  restore <repository> <snapshot> <path>  Restore a snapshot"
    echo "  snapshots <repository>              List snapshots in a repository"
    echo "  check <repository>             Check repository for errors"
    echo "  forget <repository> [flags]    Forget old snapshots"
    echo "  version                        Show Restic version"
    echo "  help                           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 init repo"
    echo "  $0 backup repo /home/user/Documents"
    echo "  $0 restore repo latest /home/user/Restore"
    echo "  $0 snapshots repo"
    echo "  $0 check repo"
    echo "  $0 forget repo --keep-last 7 --prune"
    echo "  $0 version"
    echo
    echo "Note: For Dropbox, use 'rclone:dropbox:path' as the repository."
    echo "      For other repository types, use the appropriate Restic syntax."
}

# Check if a command is provided
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Main script logic
case "$1" in
    init)
        if [ $# -ne 2 ]; then
            echo "Usage: $0 init <repository>"
            exit 1
        fi
        docker compose run --rm \
            -e RESTIC_REPOSITORY="${RESTIC_BASE_REPO}/${2}" \
            restic init
        ;;

    backup)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 backup <repository> <path>"
            exit 1
        fi
        REPO=$2
        HOST_PATH=$3
        shift 3
        docker compose run --rm \
            -e RESTIC_REPOSITORY="${RESTIC_BASE_REPO}/${REPO}" \
            -v "${HOST_PATH}:/data:ro" \
            restic backup --exclude-file /root/.config/restic/exclude /data "$@"
        ;;

    restore)
        if [ $# -ne 4 ]; then
            echo "Usage: $0 restore <repository> <snapshot> <path>"
            exit 1
        fi
        docker compose run --rm \
            -e RESTIC_REPOSITORY="${RESTIC_BASE_REPO}/${2}" \
            -v "$4:/restore:rw" \
            restic restore $3 --target /restore
        ;;

    snapshots)
        if [ $# -ne 2 ]; then
            echo "Usage: $0 snapshots <repository>"
            exit 1
        fi
        docker compose run --rm \
            -e RESTIC_REPOSITORY="${RESTIC_BASE_REPO}/${2}" \
            restic snapshots
        ;;

    check)
        if [ $# -ne 2 ]; then
            echo "Usage: $0 check <repository>"
            exit 1
        fi
        docker compose run --rm \
            -e RESTIC_REPOSITORY="${RESTIC_BASE_REPO}/${2}" \
            restic -v check
        ;;

    forget)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 forget <repository> [flags]"
            exit 1
        fi
        REPO=$2
        shift 2
        docker compose run --rm \
            -e RESTIC_REPOSITORY="${RESTIC_BASE_REPO}/${REPO}" \
            restic forget "$@"
        ;;

    version)
        docker compose run --rm restic version
        ;;

    help)
        show_help
        ;;

    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
