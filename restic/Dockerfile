ARG RCLONE_TAG=latest
ARG RESTIC_TAG=latest

FROM rclone/rclone:${RCLONE_TAG} as rclone
FROM restic/restic:${RESTIC_TAG}

COPY --from=rclone /usr/local/bin/rclone /usr/bin/rclone
