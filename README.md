# hAI.FullBackupScript

Wiederverwendbares Bash-Template zum vollstaendigen Sichern von Docker-Containern
(Image + Volumes + optionalem DB-Dump) auf ein NAS, inklusive Crontab-Backup.

## Was macht dieses Repo?

- **Vollsicherung pro Container**: `docker commit` + `docker save` + `gzip` + `rsync` aufs NAS
- **Volume/Bind-Sicherung**: reine Datenverzeichnisse werden zusaetzlich per rsync gespiegelt
- **Datenbank-Dumps**: fuer Postgres-Container per `pg_dumpall` (logisch konsistent statt Dateisystem-Snapshot)
- **Crontab-Backup**: sichert deine aktuelle Cron-Konfiguration mit
- **Volume-Finder**: findet automatisch die Mount-Pfade jedes Containers

## Dateien

| Datei | Zweck |
|---|---|
| `scripts/full_backup_template.sh` | Haupt-Backup-Script mit Platzhaltern |
| `scripts/find_volumes.sh` | Ermittelt Volume-/Bind-Pfade aller Container |
| `docs/ANLEITUNG.md` | Schritt-fuer-Schritt Setup-Anleitung |
| `docs/index.html` | GitHub Pages Uebersichtsseite |
| `docs/crontab_beispiel.txt` | Beispiel-Cronjob-Zeile |

## Quickstart

1. Repo klonen bzw. auf den Docker-Host kopieren.
2. `scripts/find_volumes.sh` anpassen (Containernamen eintragen) und ausfuehren, um die echten Volume-Pfade zu bekommen.
3. `scripts/full_backup_template.sh` kopieren (z.B. als `full_backup_5.sh`) und alle `<PLATZHALTER>` durch echte Werte ersetzen.
4. Testlauf: `bash full_backup_5.sh`
5. Cronjob einrichten, siehe `docs/crontab_beispiel.txt`.

Details siehe [docs/ANLEITUNG.md](docs/ANLEITUNG.md).

## Platzhalter-Uebersicht

| Platzhalter | Bedeutung | Beispiel |
|---|---|---|
| `<HOSTNAME>` / `<HOST_NAME>` | Name des Docker-Hosts | highfish5 |
| `<HOST_ID>` | Kurz-ID des Hosts | 5, 10 |
| `<NAS_MOUNT>` | Mount-Punkt des NAS | highfishNAS25 |
| `<CONTAINER_NAME>` | Exakter Container-Name | matchtreff_padel_web |
| `<VOLUME_SOURCE_PATH>` | Pfad aus find_volumes.sh Output | /mnt/dietpi_userdata/docker-data/volumes/xyz/_data |
| `<DB_CONTAINER_NAME>` | Name des DB-Containers | hai_anythingmcp_postgres |
| `<DB_USER>` | DB-Benutzername | postgres |

## Lizenz

Privates Nutzungs-Template, keine Gewaehrleistung fuer Datensicherheit.
Immer Testlauf vor produktivem Einsatz durchfuehren.
