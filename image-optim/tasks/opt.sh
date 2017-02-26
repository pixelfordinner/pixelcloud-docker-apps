#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get settings
source ${DIR}/conf/settings.sh

# Usage backup-files incremental|full

for client_dir in ${source_dir}/*/; do
    client_name=$(basename ${client_dir})
    echo "Found client ${client_name}..."

    for project_dir in ${client_dir}/*/; do
        project_name=$(basename ${project_dir})

        if [ -d "${project_dir}/${optim_dir}" ]; then

          target_dir=/mnt/data/${client_name}/${project_name}/${optim_dir}

          echo ">> Optimizing ${project_name}'s images...'"

          docker run --rm --user $UID:$(id -g) --cpuset-cpus="0" \
                        -v ${source_dir}:/mnt/data \
                        --name pixelcloud-image-optim \
                        pixelfordinner/image-optim-toolbox \
                        $@ $target_dir

          echo ">> ${project_name}'s images have been optimized."
      else
          echo ">> Optimization directory doesn't exist: [${project_dir}/${optim_dir}]"
      fi

      echo
      echo
    done
done
