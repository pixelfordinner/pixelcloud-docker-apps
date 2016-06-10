DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get settings
source ${DIR}/conf/settings.sh

for client_dir in ${source_dir}/*/; do
    client_name=$(basename ${client_dir})
    echo "Found client ${client_name}..."

    for project_dir in ${client_dir}/*/; do
        project_name=$(basename ${project_dir})
        bucket_dest=${bucket}/${client_name}/${project_name}
        echo "> ${project_name} -> [${full_backups}] -> ${bucket_dest}..."
        docker run --rm --user $UID \
                      -e "PASSPHRASE=${passphrase}" \
                      -v "${DIR}/../volumes/duplicity:/home/duplicity" \
                      --name pixelcloud-duplicity \
                      pixelfordinner/duplicity \
                      duplicity remove-all-but-n-full --allow-source-mismatch ${full_backups} --force ${bucket_dest}
    done
done

