# Changelog

Alle nennenswerten Aenderungen an diesem Template werden hier dokumentiert.
Format angelehnt an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

## [1.1.0] - 2026-07-27

### Hinzugefuegt
- Optionale Fehler-Benachrichtigung (`ENABLE_NOTIFICATIONS`) per ntfy oder E-Mail,
  standardmaessig deaktiviert
- Optionale Versionierung mit Rollback (`ENABLE_VERSIONING`), legt Zeitstempel-Ordner
  statt `--delete`-Mirror an, mit automatischer Aufraeumung alter Versionen
  (`VERSION_KEEP_COUNT`)
- Fehler-Sammel-Log (`run_step`-Wrapper), damit ein einzelner fehlgeschlagener
  Schritt nicht das ganze Script abbricht
- Abschnitt 8 in `docs/ANLEITUNG.md` zur Aktivierung der optionalen Features

## [1.0.0] - 2026-07-27

### Hinzugefuegt
- Initiales Backup-Template (`scripts/full_backup_template.sh`) mit Platzhaltern
  fuer Container-Image-Backup (commit/save/gzip/rsync), Volume/Bind-Backup und
  Postgres SQL-Dump (`pg_dumpall`)
- Volume-Finder (`scripts/find_volumes.sh`) zur automatischen Ermittlung von
  Mount-Pfaden je Container
- README mit Quickstart und Platzhalter-Uebersicht
- Ausfuehrliche Setup-Anleitung (`docs/ANLEITUNG.md`) inkl. Troubleshooting-Tabelle
- Restore-Anleitung (`docs/RESTORE.md`) fuer Image-, Volume- und DB-Wiederherstellung
- GitHub Pages Startseite (`docs/index.html`)
- Beispiel-Cronjob-Zeilen (`docs/crontab_beispiel.txt`)
- MIT-Lizenz
- `.gitignore`, damit lokal befuellte Backup-Scripts mit echten Containernamen
  nicht versehentlich committet werden

### Geplant / Ideen fuer naechste Versionen
- Verschluesselung (gpg) vor dem rsync-Transfer
- Log-Rotation fuer Cronjob-Logs
- ShellCheck GitHub Action fuer automatische Syntax-Pruefung
