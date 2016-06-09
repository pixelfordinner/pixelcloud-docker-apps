DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get settings
source ${DIR}/inc/settings.sh

# Usage backup-restore client_name project_name destination_dir

alias duplicity="docker run --rm --user $UID \
                      -e \"PASSPHRASE=${passphrase}\" \
                      -v \"${DIR}/../volumes/duplicity:/home/duplicity\" \
                      -v $3:/data \
                      --name pixelcloud-duplicity \
                      pixelfordinner/duplicity \
                      duplicity"

bucket_dest=${bucket}/$1/$2

mkdir -p $3/$1/$2

echo "Restoring ${bucket_dest} -> $3/$1/$2"
duplicity restore --allow-source-mismatch ${bucket_dest} /data/$1/$2

