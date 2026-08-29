# 🚀 hAI.FullBackupScript

[![Buy me a coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/highfish)

[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)](https://github.com/jbkunama1/hAI.FullBackupScript)
[![Docker](https://img.shields.io/badge/Docker-Backup-2496ED?logo=docker&logoColor=white)](https://github.com/jbkunama1/hAI.FullBackupScript)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/jbkunama1/hAI.FullBackupScript)
[![Version](https://img.shields.io/badge/version-1.1.0-blue)](https://github.com/jbkunama1/hAI.FullBackupScript)
[![Status](https://img.shields.io/badge/status-active-brightgreen)](https://github.com/jbkunama1/hAI.FullBackupScript)
[![Maintained](https://img.shields.io/badge/maintained-yes-blue)](https://github.com/jbkunama1/hAI.FullBackupScript)

Wiederverwendbares Bash-Template zum vollstaendigen Sichern von Docker-Containern
(Image + Volumes + optionalem DB-Dump) auf ein NAS, inklusive Crontab-Backup.

## 📖 Was macht dieses Repo?

- **Vollsicherung pro Container**: `docker commit` + `docker save` + `gzip` + `rsync` aufs NAS
- **Volume/Bind-Sicherung**: reine Datenverzeichnisse werden zusaetzlich per rsync gespiegelt
- **Datenbank-Dumps**: fuer Postgres-Container per `pg_dumpall` (logisch konsistent statt Dateisystem-Snapshot)
- **Crontab-Backup**: sichert deine aktuelle Cron-Konfiguration mit
- **Volume-Finder**: findet automatisch die Mount-Pfade jedes Containers
- **Optional**: Fehler-Benachrichtigung (ntfy/E-Mail) und Versionierung mit Rollback

## 📚 Dateien

| Datei | Zweck |
|---|---|
| `scripts/full_backup_template.sh` | Haupt-Backup-Script mit Platzhaltern |
| `scripts/find_volumes.sh` | Ermittelt Volume-/Bind-Pfade aller Container |
| `docs/ANLEITUNG.md` | Schritt-fuer-Schritt Setup-Anleitung |
| `docs/RESTORE.md` | Wiederherstellung im Notfall |
| `docs/index.html` | GitHub Pages Uebersichtsseite |
| `docs/crontab_beispiel.txt` | Beispiel-Cronjob-Zeile |
| `CHANGELOG.md` | Versionsverlauf des Templates |
| `LICENSE` | MIT-Lizenz |

## 🚀 Quickstart

1. Repo klonen bzw. auf den Docker-Host kopieren.
2. `scripts/find_volumes.sh` anpassen (Containernamen eintragen) und ausfuehren, um die echten Volume-Pfade zu bekommen.
3. `scripts/full_backup_template.sh` kopieren (z.B. als `full_backup_5.sh`) und alle `<PLATZHALTER>` durch echte Werte ersetzen.
4. Testlauf: `bash full_backup_5.sh`
5. Cronjob einrichten, sieh `docs/crontab_beispiel.txt`.

Details sieh [docs/ANLEITUNG.md](docs/ANLEITUNG.md).

## 📦 Optionale Features (seit v1.1.0)

Im Kopf des Scripts stehen zwei Schalter, standardmaessig deaktiviert:

```bash
ENABLE_NOTIFICATIONS=false   # Fehler-Benachrichtigung per ntfy/E-Mail
ENABLE_VERSIONING=false      # Zeitstempel-Ordner statt --delete (Rollback moeglich)
```

- **Benachrichtigung**: sendet nach jedem Lauf Erfolg/Fehler per ntfy oder E-Mail.
- **Versionierung**: legt pro Lauf einen Zeitstempel-Ordner an statt zu ueberschreiben,
  behaelt automatisch die letzten `VERSION_KEEP_COUNT` Versionen (Rollback moeglich).

Details und Aktivierung sieh Abschnitt 8 in [docs/ANLEITUNG.md](docs/ANLEITUNG.md).

## 🛡️ Wiederherstellung im Notfall

Wenn ein Container oder eine Datenbank wiederhergestellt werden muss, folge
[docs/RESTORE.md](docs/RESTORE.md). Dort findest du fertige Befehle fuer:

- **Image-Restore**: `docker load` aus dem `.tar.gz` + `docker run`
- **Volume/Bind-Restore**: `rsync` vom NAS zurueck auf den Host (Container vorher stoppen!)
- **Datenbank-Restore**: SQL-Dump per `psql` in einen (neuen) Postgres-Container einspielen
- **Crontab-Restore**: `crontab my_crontab_<HOST_ID>.backup`

**Empfehlung**: Mindestens 1x pro Quartal einen echten Restore-Test auf einem
Test-Host durchfuehren. Ein Backup, das nie zurueckgespielt wurde, ist nicht verifiziert.

## 📖 Platzhalter-Uebersicht

| Platzhalter | Bedeutung | Beispiel |
|---|---|---|
| `<HOSTNAME>` / `<HOST_NAME>` | Name des Docker-Hosts | highfish5 |
| `<HOST_ID>` | kurz-ID des Hosts | 5, 10 |
| `<NAS_MOUNT>` | Mount-Punkt des NAS | highfishNAS25 |
| `<CONTAINER_NAME>` | Exakter Container-Name | matchtreff_padel_web |
| `<VOLUME_SOURCE_PATH>` | Pfad aus find_volumes.sh Output | /mnt/dietpi_userdata/docker-data/volumes/xyz/_data |
| `<DB_CONTAINER_NAME>` | Name des DB-Containers | hai_anythingmcp_postgres |
| `<DB_USER>` | DB-Benutzername | postgres |

## 📄 Lizenz

MIT-Lizenz, sieh [LICENSE](LICENSE). Keine Gewaehrleistung fuer Datensicherheit --
immer Testlauf und Restore-Test vor produktivem Einsatz durchfuehren.
