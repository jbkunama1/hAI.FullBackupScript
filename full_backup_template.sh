#!/bin/bash
###############################################################
# Full Backup Script - Template
# Host: <HOSTNAME>            (z.B. highfish5, highfish_10)
# Erstellt mit hAI.FullBackupScript
###############################################################

##############################
### Konfiguration (anpassen!)
##############################
HOST_ID="<HOST_ID>"                                   # z.B. 5, 10
NAS_BASE="/mnt/<NAS_MOUNT>/Sicherung/<HOST_NAME>"      # Ziel auf dem NAS
BACKUP_TMP="/home/BACKUP"                              # lokaler Zwischenspeicher
IMAGE_PRUNE_AGE="48h"                                  # Alter fuer image prune

##############################
### Docker Cleanup
##############################
docker image prune -a -f --filter "until=${IMAGE_PRUNE_AGE}"

##############################
### Portainer Config Backup
##############################
rsync -Pru --delete /mnt/dietpi_userdata/docker-data/volumes/portainer_data/_data "${NAS_BASE}/portainer/"

##############################
### <CONTAINER_NAME> - Vollsicherung (Image + Volume)
### Kopiere diesen Block pro Container und ersetze die Platzhalter
##############################
CONTAINER="<CONTAINER_NAME>"          # exakter Name aus 'docker ps' / Portainer
IMAGE_TAG="<CONTAINER_NAME>_${HOST_ID}"
BACKUP_DIR="${BACKUP_TMP}/<CONTAINER_NAME>Backup"
NAS_DIR="${NAS_BASE}/<CONTAINER_NAME>/Docker"

mkdir -p "${BACKUP_DIR}"
docker commit -p "${CONTAINER}" "${IMAGE_TAG}"
docker save -o "${BACKUP_DIR}/${IMAGE_TAG}.tar" "${IMAGE_TAG}"
gzip -f "${BACKUP_DIR}/${IMAGE_TAG}.tar"
mkdir -p "${NAS_DIR}"
rsync -Pru --delete "${BACKUP_DIR}/${IMAGE_TAG}.tar.gz" "${NAS_DIR}/"
#untag um Speicherplatz freizugeben (kein Docker-Hub-Push)
docker rmi "${IMAGE_TAG}:latest"

##############################
### <CONTAINER_NAME> - Volume/Bind Backup (nur Daten, kein commit)
### Pfad mit scripts/find_volumes.sh ermitteln!
##############################
rsync -Pru --delete "<VOLUME_SOURCE_PATH>" "${NAS_BASE}/<CONTAINER_NAME>/"

##############################
### <DB_CONTAINER_NAME> - Postgres/SQL Dump (konsistentes DB-Backup)
### Nur falls Container eine Datenbank enthaelt
##############################
DB_CONTAINER="<DB_CONTAINER_NAME>"
DB_USER="<DB_USER>"                    # z.B. postgres
DB_DUMP_DIR="${BACKUP_TMP}/${DB_CONTAINER}Dump"
mkdir -p "${DB_DUMP_DIR}"
docker exec -t "${DB_CONTAINER}" pg_dumpall -U "${DB_USER}" > "${DB_DUMP_DIR}/${DB_CONTAINER}_${HOST_ID}.sql"
gzip -f "${DB_DUMP_DIR}/${DB_CONTAINER}_${HOST_ID}.sql"
mkdir -p "${NAS_BASE}/<CONTAINER_NAME>/PostgresDump"
rsync -Pru --delete "${DB_DUMP_DIR}/${DB_CONTAINER}_${HOST_ID}.sql.gz" "${NAS_BASE}/<CONTAINER_NAME>/PostgresDump/"

##############################
### Backup Scripts selbst sichern
##############################
rsync -Pru --delete /home/Scripts "${NAS_BASE}/Scripts/"

##############################
### Crontab Backup
##############################
mkdir -p /home/BACKUP/CronBackup/
cd /home/BACKUP/CronBackup/ || exit 1
crontab -l > "my_crontab_${HOST_ID}.backup"
rsync -Pru --delete /home/BACKUP/CronBackup/ "${NAS_BASE}/CronBackup/"
