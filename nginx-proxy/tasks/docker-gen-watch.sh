#!/bin/bash

DOCKER_GEN_CONTAINER=app-pixelcloud-nginx_proxy-nginx_gen
DOCKER_GEN_RUNNING="$($(which docker) inspect -f '{{.State.Running}}' $DOCKER_GEN_CONTAINER)"

if [ "$DOCKER_GEN_RUNNING" != "true" ]; then
    $(which docker) restart "$DOCKER_GEN_CONTAINER"
    echo "$DOCKER_GEN_CONTAINER" restarted
    echo
fi
