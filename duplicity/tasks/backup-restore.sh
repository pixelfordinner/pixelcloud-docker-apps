#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get settings
source ${DIR}/conf/settings.sh

# Usage backup-restore client_name project_name destination_dir

bucket_dest=${bucket}/$1/$2

mkdir -p $3/$1/$2

echo ">> Restoring ${bucket_dest} -> $3/$1/$2"
docker run --rm --user $UID:$(id -g) --cpuset-cpus="0" \
                      -e "PASSPHRASE=${passphrase}" \
                      -v "${DIR}/../volumes/app:/mnt/app" \
                      -v $3:/mnt/data \
                      --name pixelcloud-duplicity \
                      pixelfordinner/duplicity \
                      restore --allow-source-mismatch ${bucket_dest} /mnt/data/$1/$2
echo ">> Done."
echo
echo
