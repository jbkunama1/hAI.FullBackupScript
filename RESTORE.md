# Restore-Anleitung: hAI.FullBackupScript

## 1. Container-Image wiederherstellen (aus .tar.gz)

```bash
# Dump vom NAS zurueckholen und entpacken
gunzip -k <CONTAINER_NAME>_<HOST_ID>.tar.gz

# Image in Docker laden
docker load -i <CONTAINER_NAME>_<HOST_ID>.tar

# Neuen Container aus dem Image starten (Ports/Volumes ggf. anpassen)
docker run -d --name <CONTAINER_NAME> <CONTAINER_NAME>_<HOST_ID>:latest
```

## 2. Volume/Bind-Daten wiederherstellen

```bash
# Zieldata-Verzeichnis leeren/anlegen
mkdir -p <VOLUME_SOURCE_PATH>

# Daten vom NAS zurueckspielen
rsync -Pru --delete "${NAS_BASE}/<CONTAINER_NAME>/" <VOLUME_SOURCE_PATH>
```

Wichtig: Container vor dem Zurueckspielen stoppen, damit keine Dateien
waehrend des Schreibens ueberschrieben werden:

```bash
docker stop <CONTAINER_NAME>
# rsync ausfuehren
docker start <CONTAINER_NAME>
```

## 3. Postgres-Datenbank aus SQL-Dump wiederherstellen

```bash
# Dump entpacken
gunzip -k <DB_CONTAINER_NAME>_<HOST_ID>.sql.gz

# Neuen/leeren Postgres-Container starten, dann Dump einspielen
cat <DB_CONTAINER_NAME>_<HOST_ID>.sql | docker exec -i <DB_CONTAINER_NAME> psql -U <DB_USER>
```

## 4. Crontab wiederherstellen

```bash
crontab my_crontab_<HOST_ID>.backup
crontab -l   # zur Kontrolle
```

## 5. Vollstaendiger Restore-Test (Empfehlung)

Fuehre mindestens 1x pro Quartal einen echten Restore-Test auf einem
Test-Host durch. Ein Backup, das nie zurueckgespielt wurde, ist nicht
verifiziert.
