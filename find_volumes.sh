#!/bin/bash
###############################################################
# find_volumes.sh
# Zeigt fuer jeden angegebenen Container die Mounts/Volumes an.
# Nutze das Ergebnis, um die Platzhalter im Backup-Template
# (<VOLUME_SOURCE_PATH> etc.) korrekt zu befuellen.
###############################################################

# Container-Namen anpassen (Leerzeichen getrennt), oder leer lassen
# um automatisch ALLE laufenden Container zu pruefen.
CONTAINERS="<CONTAINER_1> <CONTAINER_2> <CONTAINER_3>"

if [ -z "$CONTAINERS" ]; then
  CONTAINERS=$(docker ps --format '{{.Names}}')
fi

for c in $CONTAINERS; do
  echo "=============================================="
  echo "Container: $c"
  echo "=============================================="
  docker inspect --format '{{range .Mounts}}Type={{.Type}}  Name={{.Name}}  Source={{.Source}}  Destination={{.Destination}}
{{end}}' "$c" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "FEHLER: Container $c nicht gefunden"
  fi
  echo ""
done
