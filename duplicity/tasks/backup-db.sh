#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get settings
source ${DIR}/conf/settings.sh

# Get running php containers and have wp-cli make a backup.
containers=$(docker ps -q -f name='-php')

for container in $containers
do
    # Ensure dump dir exists
    $(which docker) exec $container mkdir -p ${dumps_dir}
    # Clear old dumps (> 8 days)
    echo ">> [${container}] Clearing old dumps..."
    $(which docker) exec $container find ${dumps_dir} -type f \( -name '*.sql' -o -name '*.sql.gz' \) -mtime +8 -delete
    echo ">> [${container}] Dumping database..."
    # Generate new dump
    $(which docker) exec $container wp db export ${dumps_dir}/$(date +%Y.%m.%d).sql
    echo ">> [${container}] Compressing dump..."
    # Cmpressing dump
    $(which docker) exec $container gzip -7 ${dumps_dir}/$(date +%Y.%m.%d).sql
    echo ">> [${container}] Done."
    echo
    echo
done
