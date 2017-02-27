#!/bin/bash

$(which bash) ./opt.sh opt-all -mtime 0  && \
$(which curl) -fsS --retry 3 $HEALTHCHECK > /dev/null
