# Restic Backup Script for Docker Containers

This script automates Restic backups for Docker containers using labels to configure backup behavior.

## Environment

### Compose

Set the following environment variables in a ``.env`` file.

| Variable | Description | Example |
|-------|-------------|---------|
| `RESTIC_TAG` | Restic (``restic/restic``) [docker tag](https://hub.docker.com/r/restic/restic/tags) | `0.16.5` |
| `RCLONE_TAG` | Rclone (``rclone/rclone``) [docker tag](https://hub.docker.com/r/rclone/rclone/tags) | `1.67.0` |
| `RESTIC_PASSWORD_FILE` | Name of the [password file](https://restic.readthedocs.io/en/latest/045_working_with_repos.html) (located in ``volumes/secrets``) | `password.txt` |
| `RESTIC_EXCLUDE_FILE` | Name of the restic [exclude file](https://restic.readthedocs.io/en/latest/040_backup.html#backup-excluding-files) (located in ``volumes/conf/restic/exclude``) | `exclude.txt` |
| `HOSTNAME` | Hostname restic should use for backups | `prod-srv-04` |

### Restic

Set the following environment variables (if needed) in a ``.env.restic`` file.


| Variable | Description | Example |
|-------|-------------|---------|
| `RESTICRESTIC_BASE_REPO_TAG` | Restic main repository (backups using ``backup.sh`` will be sub-repositories) | `s3:s3.us-east-005.backblazeb2.com/my-bucket` |
| `AWS_ACCESS_KEY_ID` | Your S3 key id, if using an S3 repository | `XXXXXXXXXXXXXXXXX` |
| `AWS_SECRET_ACCESS_KEY` | Your S3 access key, if using an S3 repository | `XXXXXXXXXXXXXXXXX` |

## Labels

The following labels can be added to your Docker containers to control the backup process:

| Label | Description | Example |
|-------|-------------|---------|
| `pixelcloud.restic.backup.enabled` | Indicates if the container should be considered for backup. | `pixelcloud.restic.backup.enabled=true` |
| `pixelcloud.restic.backup.repository` | Specifies the Restic sub-repository for the container. | `pixelcloud.restic.backup.repository=myapp` |
| `pixelcloud.restic.backup.path` | Defines the path inside the container to be backed up. | `pixelcloud.restic.backup.path=/data` |
| `pixelcloud.restic.backup.run.before` | Command to run before the backup starts. | `pixelcloud.restic.backup.run.before=pg_dump -U postgres mydb > /backup/mydb.sql` |
| `pixelcloud.restic.backup.run.after` | Command to run after the backup completes. | `pixelcloud.restic.backup.run.after=rm /backup/mydb.sql` |
| `pixelcloud.restic.backup.healthcheck` | URL to ping for healthcheck after successful backup. | `pixelcloud.restic.backup.healthcheck=https://hc-ping.com/your-uuid-here` |
| `pixelcloud.restic.backup.forget` | Restic forget command options to manage snapshots. | `pixelcloud.restic.backup.forget=--keep-last 7 --keep-weekly 4 --keep-monthly 6` |


## Label Details

### pixelcloud.restic.backup.enabled

Set this to `true` for any container you want to be included in the backup process.

### pixelcloud.restic.backup.repository

Specify the Restic sub-repository where backups should be stored. Main repository needs to be setup in .env.restic along with password file.

### pixelcloud.restic.backup.path

The path inside the container that should be backed up. If not specified, the script will attempt to use the container's working directory.

### pixelcloud.restic.backup.run.before

A command to run inside the container before the backup starts. Useful for preparing data, like dumping a database.

### pixelcloud.restic.backup.run.after

A command to run inside the container after the backup completes. Can be used for cleanup tasks.

### pixelcloud.restic.backup.healthcheck

A URL to ping after a successful backup. This can be used with services like Healthchecks.io to monitor your backup process.

### pixelcloud.restic.backup.forget

Specifies the policy for removing old snapshots. This should be a string of valid Restic forget command options.

## Example

Here's an example of how you might label a Docker container for use with this backup script:

```yaml
version: '3'
services:
  myapp:
    image: myapp:latest
    labels:
      - "pixelcloud.restic.backup.enabled=true"
      - "pixelcloud.restic.backup.repository=myapp"
      - "pixelcloud.restic.backup.path=/app/data"
      - "pixelcloud.restic.backup.run.before=pg_dump -U postgres mydb > /app/data/mydb.sql"
      - "pixelcloud.restic.backup.run.after=rm /app/data/mydb.sql"
      - "pixelcloud.restic.backup.healthcheck=https://hc-ping.com/your-uuid-here"
      - "pixelcloud.restic.backup.forget=--keep-last 7 --keep-weekly 4 --keep-monthly 6"
```
