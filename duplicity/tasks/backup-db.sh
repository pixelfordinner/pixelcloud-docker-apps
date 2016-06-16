#!/bin/bash

# Get running php containers and have wp-cli make a backup.
containers=$(docker ps -q -f name='-php')

for container in $containers
do
    # Clear old dumps (> 1 month)
    echo "[${container}] Clearing old dumps..."
    $(which docker) exec -it $container find /opt/data -type f -name '*.sql' -mtime +60 -delete
    echo "[${container}] Dumping database..."
    # Generate new dumnp
    $(which docker) exec -it $container wp db export /opt/data/$(date +%Y.%m.%d).sql
    echo "[${container}] Done."
done
