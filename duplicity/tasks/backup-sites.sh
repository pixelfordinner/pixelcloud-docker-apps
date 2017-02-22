#!/bin/bash

$(which bash) ./backup-db.sh && \
$(which bash) ./backup-files.sh && \
$(which bash) ./backup-clean.sh && \
$(which curl) -fsS --retry 3 $HEALTHCHECK > /dev/null
