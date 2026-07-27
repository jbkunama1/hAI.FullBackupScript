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
### OPTIONALE Features - auf "true" setzen um zu aktivieren
##############################
ENABLE_NOTIFICATIONS=false        # Fehler-Benachrichtigung per ntfy/E-Mail
ENABLE_VERSIONING=false           # Zeitstempel-Ordner statt --delete (Rollback moeglich)

# --- Notification Config (nur relevant wenn ENABLE_NOTIFICATIONS=true) ---
NTFY_URL="https://ntfy.sh/<DEIN_NTFY_TOPIC>"           # z.B. eigener ntfy-Server/Topic
NOTIFY_EMAIL="<DEINE_EMAIL@BEISPIEL.DE>"               # benoetigt lokal 'mail'/'sendmail'
NOTIFY_METHOD="ntfy"                                   # "ntfy" oder "mail" oder "none"

# --- Versioning Config (nur relevant wenn ENABLE_VERSIONING=true) ---
VERSION_TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
VERSION_KEEP_COUNT=7                                   # Anzahl behaltener Versionen pro Ziel

##############################
### Hilfsfunktionen (nicht anpassen)
##############################
ERROR_LOG="/tmp/full_backup_${HOST_ID}_errors.log"
> "$ERROR_LOG"

run_step() {
  # Fuehrt einen Befehl aus, loggt Fehler statt das ganze Script abzubrechen
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    echo "FEHLER (exit $status): $*" >> "$ERROR_LOG"
  fi
  return $status
}

notify() {
  local message="$1"
  [ "$ENABLE_NOTIFICATIONS" != "true" ] && return 0
  case "$NOTIFY_METHOD" in
    ntfy)
      curl -s -d "$message" "$NTFY_URL" >/dev/null 2>&1
      ;;
    mail)
      echo "$message" | mail -s "Backup Host <HOST_NAME> - Status" "$NOTIFY_EMAIL" >/dev/null 2>&1
      ;;
    *)
      : # NOTIFY_METHOD=none -> nichts tun
      ;;
  esac
}

# rsync-Wrapper: nutzt Versionierung (Zeitstempel-Ordner) wenn aktiviert,
# sonst klassisches --delete Mirror wie bisher.
backup_rsync() {
  local source="$1"
  local dest_base="$2"
  if [ "$ENABLE_VERSIONING" = "true" ]; then
    local dest="${dest_base%/}/${VERSION_TIMESTAMP}/"
    mkdir -p "$dest"
    run_step rsync -Pru "$source" "$dest"
    # alte Versionen aufraeumen, nur die letzten VERSION_KEEP_COUNT behalten
    ls -1dt "${dest_base%/}"/*/ 2>/dev/null | tail -n +$((VERSION_KEEP_COUNT + 1)) | xargs -r rm -rf
  else
    run_step rsync -Pru --delete "$source" "$dest_base"
  fi
}

##############################
### Docker Cleanup
##############################
run_step docker image prune -a -f --filter "until=${IMAGE_PRUNE_AGE}"

##############################
### Portainer Config Backup
##############################
backup_rsync /mnt/dietpi_userdata/docker-data/volumes/portainer_data/_data "${NAS_BASE}/portainer/"

##############################
### <CONTAINER_NAME> - Vollsicherung (Image + Volume)
### Kopiere diesen Block pro Container und ersetze die Platzhalter
##############################
CONTAINER="<CONTAINER_NAME>"          # exakter Name aus 'docker ps' / Portainer
IMAGE_TAG="<CONTAINER_NAME>_${HOST_ID}"
BACKUP_DIR="${BACKUP_TMP}/<CONTAINER_NAME>Backup"
NAS_DIR="${NAS_BASE}/<CONTAINER_NAME>/Docker"

mkdir -p "${BACKUP_DIR}"
run_step docker commit -p "${CONTAINER}" "${IMAGE_TAG}"
run_step docker save -o "${BACKUP_DIR}/${IMAGE_TAG}.tar" "${IMAGE_TAG}"
run_step gzip -f "${BACKUP_DIR}/${IMAGE_TAG}.tar"
mkdir -p "${NAS_DIR}"
backup_rsync "${BACKUP_DIR}/${IMAGE_TAG}.tar.gz" "${NAS_DIR}/"
#untag um Speicherplatz freizugeben (kein Docker-Hub-Push)
run_step docker rmi "${IMAGE_TAG}:latest"

##############################
### <CONTAINER_NAME> - Volume/Bind Backup (nur Daten, kein commit)
### Pfad mit scripts/find_volumes.sh ermitteln!
##############################
backup_rsync "<VOLUME_SOURCE_PATH>" "${NAS_BASE}/<CONTAINER_NAME>/"

##############################
### <DB_CONTAINER_NAME> - Postgres/SQL Dump (konsistentes DB-Backup)
### Nur falls Container eine Datenbank enthaelt
##############################
DB_CONTAINER="<DB_CONTAINER_NAME>"
DB_USER="<DB_USER>"                    # z.B. postgres
DB_DUMP_DIR="${BACKUP_TMP}/${DB_CONTAINER}Dump"
mkdir -p "${DB_DUMP_DIR}"
run_step bash -c "docker exec -t '${DB_CONTAINER}' pg_dumpall -U '${DB_USER}' > '${DB_DUMP_DIR}/${DB_CONTAINER}_${HOST_ID}.sql'"
run_step gzip -f "${DB_DUMP_DIR}/${DB_CONTAINER}_${HOST_ID}.sql"
mkdir -p "${NAS_BASE}/<CONTAINER_NAME>/PostgresDump"
backup_rsync "${DB_DUMP_DIR}/${DB_CONTAINER}_${HOST_ID}.sql.gz" "${NAS_BASE}/<CONTAINER_NAME>/PostgresDump/"

##############################
### Backup Scripts selbst sichern
##############################
backup_rsync /home/Scripts "${NAS_BASE}/Scripts/"

##############################
### Crontab Backup
##############################
mkdir -p /home/BACKUP/CronBackup/
cd /home/BACKUP/CronBackup/ || exit 1
crontab -l > "my_crontab_${HOST_ID}.backup"
backup_rsync /home/BACKUP/CronBackup/ "${NAS_BASE}/CronBackup/"

##############################
### Abschluss-Benachrichtigung
##############################
if [ -s "$ERROR_LOG" ]; then
  notify "Backup <HOST_NAME> (${HOST_ID}) FEHLGESCHLAGEN:
$(cat "$ERROR_LOG")"
else
  notify "Backup <HOST_NAME> (${HOST_ID}) erfolgreich abgeschlossen."
fi
