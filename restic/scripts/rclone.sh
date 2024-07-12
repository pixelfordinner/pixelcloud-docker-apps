#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 <command> [arguments]"
    echo
    echo "Commands:"
    echo "  config                         Create or update rclone config"
    echo "  ls <remote:path>               List directories and files"
    echo "  copy <source> <dest>           Copy files from source to dest"
    echo "  sync <source> <dest>           Sync source to dest"
    echo "  mkdir <remote:path>            Make a directory"
    echo "  rmdir <remote:path>            Remove a directory"
    echo "  delete <remote:path>           Delete a file"
    echo "  cat <remote:path>              Concatenate files and send to stdout"
    echo "  help                           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 config"
    echo "  $0 ls dropbox:backup"
    echo "  $0 copy /local/path dropbox:backup"
    echo "  $0 sync /local/path dropbox:backup"
    echo
    echo "Note: For more advanced rclone operations, refer to the rclone documentation."
}

# Check if a command is provided
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Main script logic
case "$1" in
    config)
        shift
        docker compose run -it --entrypoint="rclone config $*" restic
        ;;

    ls|copy|sync|mkdir|rmdir|delete|cat)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 $1 <arguments>"
            exit 1
        fi
        COMMAND=$1
        shift
        docker compose run -it --entrypoint="rclone $COMMAND $@" restic
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
