# Anleitung: hAI.FullBackupScript einrichten

## 1. Voraussetzungen

- Docker-Host mit Bash, `rsync`, `gzip`, `crontab`
- NAS oder anderes Sicherungsziel per Mount erreichbar (z.B. `/mnt/<NAS_MOUNT>/...`)
- SSH-Zugriff auf den Docker-Host

## 2. Volume-Pfade ermitteln

Bevor du das Backup-Script fuellen kannst, musst du wissen, wo die Daten
jedes Containers tatsaechlich liegen.

```bash
chmod +x scripts/find_volumes.sh
nano scripts/find_volumes.sh   # Containernamen eintragen, z.B.:
# CONTAINERS="mein_container_web mein_container_bot"
./scripts/find_volumes.sh
```

Die Ausgabe zeigt pro Container `Type`, `Name`, `Source` und `Destination`.
`Source` ist der Pfad, den du fuer `<VOLUME_SOURCE_PATH>` brauchst.

## 3. Backup-Script erstellen

```bash
cp scripts/full_backup_template.sh full_backup_<HOST_ID>.sh
nano full_backup_<HOST_ID>.sh
```

Ersetze im Kopf des Scripts:

- `<HOST_ID>` -> z.B. `5` oder `10`
- `<NAS_MOUNT>` -> Mount-Name deines NAS
- `<HOST_NAME>` -> Name des Docker-Hosts

Kopiere dann den Block "Vollsicherung (Image + Volume)" **einmal pro Container**
und ersetze:

- `<CONTAINER_NAME>` -> exakter Containername aus Portainer/`docker ps`
- `<VOLUME_SOURCE_PATH>` -> Pfad aus Schritt 2

Falls ein Container eine Datenbank enthaelt (Postgres etc.), nutze zusaetzlich
den Block "SQL Dump" und setze `<DB_CONTAINER_NAME>` und `<DB_USER>`.

Container, die du **nicht** sichern willst (z.B. Portainer selbst, Cloudflared),
laesst du einfach weg.

## 4. Testlauf

```bash
chmod +x full_backup_<HOST_ID>.sh
bash full_backup_<HOST_ID>.sh
```

Pruefe die Ausgabe auf Fehler wie "No such container" oder
"No such file or directory" -- das deutet meist auf einen falschen
Container- oder Volume-Namen hin. Mit `docker ps` bzw. Portainer
("Containers" / "Volumes") nachschauen und korrigieren.

## 5. Automatisierung per Cronjob

Siehe `docs/crontab_beispiel.txt`. Kurzfassung:

```bash
crontab -e
```

Zeile einfuegen (Beispiel: taeglich um 03:00 Uhr):

```
0 3 * * * /bin/bash /home/Scripts/full_backup_<HOST_ID>.sh >> /home/Scripts/full_backup_<HOST_ID>.log 2>&1
```

## 6. Wiederverwendung fuer neue Container

1. `find_volumes.sh` mit neuem Containernamen ausfuehren.
2. Neuen Block aus `full_backup_template.sh` in dein bestehendes Script kopieren.
3. Platzhalter ersetzen.
4. Testlauf.

## 7. Troubleshooting

| Fehler | Ursache | Loesung |
|---|---|---|
| `No such container` | Containername falsch/Container geloescht | Namen in Portainer pruefen |
| `invalid output path: stat ... no such file or directory` | Zielordner fuer `docker save` fehlt | `mkdir -p` vor dem `save`-Befehl sicherstellen (im Template bereits enthalten) |
| `rsync: change_dir ... failed` | Volume-Pfad falsch | `find_volumes.sh` erneut ausfuehren |
| Punkt im Containernamen (`app.name`) | Manche Docker-Versionen mit `docker commit` problematisch | Container ggf. umbenennen oder Namen in Anfuehrungszeichen testen |


## 8. Optionale Features aktivieren

Das Template enthaelt zwei optionale Erweiterungen, die standardmaessig
**deaktiviert** sind (kein Einfluss auf bestehende Scripts, wenn du nichts aenderst).

### 8.1 Fehler-Benachrichtigung

Im Kopf des Scripts:

```bash
ENABLE_NOTIFICATIONS=true
NOTIFY_METHOD="ntfy"          # oder "mail"
NTFY_URL="https://ntfy.sh/<DEIN_NTFY_TOPIC>"
NOTIFY_EMAIL="<DEINE_EMAIL@BEISPIEL.DE>"
```

- **ntfy**: Kostenloser Push-Dienst, kein Login noetig. Eigenes Topic waehlen
  (z.B. `https://ntfy.sh/highfish5-backup-<zufallsstring>`), App installieren
  und Topic abonnieren.
- **mail**: Benoetigt lokal installiertes `mail`/`sendmail` bzw. `msmtp`.

Nach jedem Lauf bekommst du eine Nachricht "erfolgreich" oder "FEHLGESCHLAGEN"
inklusive Fehlerdetails.

### 8.2 Versionierung mit Rollback

Im Kopf des Scripts:

```bash
ENABLE_VERSIONING=true
VERSION_KEEP_COUNT=7          # wie viele alte Versionen behalten werden
```

Statt jedes Mal die alte Sicherung zu ueberschreiben (`--delete`), legt das
Script pro Lauf einen neuen Ordner mit Zeitstempel an
(z.B. `.../portainer/2026-07-27_03-00/`). Aeltere Versionen werden automatisch
geloescht, sobald mehr als `VERSION_KEEP_COUNT` vorhanden sind.

**Hinweis**: Versionierung braucht deutlich mehr Speicherplatz auf dem NAS,
da nichts mehr ueberschrieben wird. Bei grossen Docker-Images (mehrere GB)
kann das schnell viel Platz kosten -- `VERSION_KEEP_COUNT` entsprechend klein halten.

### 8.3 Beides kombinieren

Beide Flags sind unabhaengig voneinander und koennen gleichzeitig aktiviert
werden. Bei einem Fehler bekommst du dann sowohl die Benachrichtigung als
auch weiterhin Zugriff auf die letzten `VERSION_KEEP_COUNT` Versionen.
