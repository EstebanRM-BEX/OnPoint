#!/bin/bash
# Muestrea la memoria de la app en la PDA cada N segundos y la guarda en CSV.
# Uso: ./medir_memoria.sh [device_id] [segundos]
# Columnas en MB: total PSS, heap Java, heap nativo (Dart/Flutter), gráficos, RSS.
DEV=${1:-$(adb devices | awk 'NR==2{print $1}')}
INT=${2:-5}
PKG=com.onpoint.wms
OUT=memoria_$(date +%Y%m%d_%H%M%S).csv
echo "hora,pss_total,java,nativo,graficos,rss" | tee "$OUT"
while true; do
  M=$(adb -s "$DEV" shell dumpsys meminfo "$PKG" 2>/dev/null)
  kb() { echo "$M" | awk -v k="$1" '$0 ~ k {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/){print int($i/1024); exit}}'; }
  echo "$(date +%H:%M:%S),$(kb 'TOTAL PSS:'),$(kb 'Java Heap:'),$(kb 'Native Heap:'),$(kb 'Graphics:'),$(kb 'TOTAL RSS:')" | tee -a "$OUT"
  sleep "$INT"
done
