DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get settings
source ${DIR}/conf/settings.sh

# Usage backup-restore client_name project_name destination_dir

bucket_dest=${bucket}/$1/$2

mkdir -p $3/$1/$2

echo "Restoring ${bucket_dest} -> $3/$1/$2"
docker run --rm --user $UID \
                      -e "PASSPHRASE=${passphrase}" \
                      -v "${DIR}/../volumes/duplicity:/home/duplicity" \
                      -v $3:/data \
                      --name pixelcloud-duplicity \
                      pixelfordinner/duplicity \
                      duplicity restore --allow-source-mismatch ${bucket_dest} /data/$1/$2

