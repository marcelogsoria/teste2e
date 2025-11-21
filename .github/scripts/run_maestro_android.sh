#!/bin/bash
set -e

echo "=========================================="
echo "Emulador iniciado correctamente"
echo "=========================================="
adb devices
adb wait-for-device
echo "Dispositivo conectado y listo"
echo ""

echo "Preparando aplicación desde mobileBuilds/build.apk..."
if [ -f "mobileBuilds/build.apk" ]; then
  echo "APK encontrado en mobileBuilds/build.apk"
  cp mobileBuilds/build.apk wikipedia.apk
else
  echo "ERROR: APK no encontrado en mobileBuilds/build.apk"
  exit 1
fi

echo "Instalando aplicación..."
adb install -r wikipedia.apk
echo "Aplicación instalada correctamente"

echo ""
echo "=========================================="
echo "Ejecutando tests con Maestro"
echo "=========================================="

# Asegurar que Maestro esté en el PATH
export PATH="$PATH:$HOME/.maestro/bin"

# Verificar que Maestro esté instalado
if ! command -v maestro &> /dev/null; then
    echo "Advertencia: Maestro no está disponible en el PATH"
    maestro --version || echo "No se pudo ejecutar maestro --version"
fi

# Verificar directorio de trabajo y existencia del archivo
echo "Directorio de trabajo actual: $(pwd)"

# Ejecutar tests con Maestro (con debug y screenshots)
# set +e  # No fallar inmediatamente si Maestro falla
# maestro test .maestro/wikipedia-test.yaml --format junit --output maestro-report.xml
# MAESTRO_EXIT_CODE=$?
# #set -e  # Volver a activar el modo estricto

echo ""
echo "=========================================="
echo "Resultados de las pruebas"
echo "=========================================="
echo ""
echo "Tests ejecutados con Maestro Mobile Test"
echo "Aplicación: Wikipedia Mobile"
echo "Fecha: $(date)"
echo ""

set +e  # No fallar inmediatamente si Maestro falla
maestro test .maestro/android/ --format html --output maestro-report.xml
MAESTRO_EXIT_CODE=$?
set -e  # Volver a activar el modo estricto

if [ $MAESTRO_EXIT_CODE -eq 0 ]; then
  echo "Tests OK"
else
  echo "Tests FAILED"
fi

if [ -f maestro-report.xml ]; then
  echo "Reporte generado: maestro-report.xml"
  cat maestro-report.xml
else
  echo "No se generó reporte de Maestro"
fi

# mkdir -p videos
# for file in .maestro/android/*.yaml; do
#   echo "Ejecutando $file"

#   #adb shell screenrecord /sdcard/test-video.mp4
#   #echo $! > record.pid
#   set +e  # No fallar inmediatamente si Maestro falla
#   maestro test $file --format html --output maestro-report.xml
#   MAESTRO_EXIT_CODE=$?
#   #set -e  # Volver a activar el modo estricto
#   #kill -INT $(cat record.pid)
  
#   if [ $MAESTRO_EXIT_CODE -eq 0 ]; then
#     echo "Test OK → no se copia video"
#   else
#     echo "Test FAILED → guardando video"
#     #adb pull /sdcard/test-video.mp4 "$(basename $file .yaml).mp4"
#   fi

#   if [ -f maestro-report.xml ]; then
#     echo "Reporte generado: maestro-report.xml"
#     cat maestro-report.xml
#   else
#     echo "No se generó reporte de Maestro"
#   fi

#   echo "=========================================="
# done

# Si Maestro falló, obtener información adicional de debug
# if [ "$MAESTRO_EXIT_CODE" != "0" ]; then
#   echo "=========================================="
#   echo "DEBUG: Información de la pantalla actual (Maestro falló)"
#   echo "=========================================="
  
#   # Obtener información de la jerarquía de la UI actual
#   echo ""
#   echo "--- Jerarquía completa de la UI (uiautomator dump) ---"
#   adb shell uiautomator dump /sdcard/ui_dump.xml
#   adb pull /sdcard/ui_dump.xml ui_dump.xml 2>/dev/null || echo "No se pudo obtener dump de UI"
#   if [ -f ui_dump.xml ]; then
#     echo "Contenido del dump de UI:"
#     cat ui_dump.xml | head -200
#     echo ""
#     echo "... (truncado, archivo completo guardado en ui_dump.xml)"
#   fi
  
#   echo ""
#   echo "--- Información de ventanas activas (dumpsys window) ---"
#   adb shell dumpsys window windows | grep -E "mCurrentFocus|mFocusedApp" | head -10 || echo "No se pudo obtener información de ventanas"
  
#   echo ""
#   echo "--- Elementos visibles en pantalla (texto) ---"
#   adb shell uiautomator dump /dev/tty 2>/dev/null | grep -oP 'text="[^"]*"' | head -30 || echo "No se pudieron obtener elementos de texto"
  
#   echo ""
#   echo "--- Capturando screenshot manual del estado actual ---"
#   SCREENSHOT_NAME="maestro-failure-$(date +%Y%m%d-%H%M%S).png"
#   adb shell screencap -p /sdcard/screenshot.png
#   adb pull /sdcard/screenshot.png "$SCREENSHOT_NAME" 2>/dev/null && echo "Screenshot guardado: $SCREENSHOT_NAME" || echo "No se pudo capturar screenshot"
  
#   echo ""
#   echo "--- Logs recientes de la aplicación ---"
#   adb logcat -d -t 100 | grep -i "wikipedia\|error\|exception" | tail -50 || adb logcat -d | tail -30
  
#   echo ""
#   echo "--- Screenshots generados por Maestro ---"
#   find . -name "*.png" -type f -mmin -5 | head -10 || echo "No se encontraron screenshots recientes de Maestro"
  
#   echo ""
# fi



# Guardar screenshots y dumps en un directorio para artefactos
mkdir -p maestro-screenshots
find . -name "*.png" -type f -mmin -5 -exec cp {} maestro-screenshots/ \; || true
find . -name "*.mp4" -type f -mmin -5 -exec cp {} maestro-screenshots/ \; || true
find . -name "maestro-report.xml" -exec cp {} maestro-screenshots/ \; || true

# Exit with the error code if tests failed
if [ "$MAESTRO_EXIT_CODE" != "0" ]; then
  exit $MAESTRO_EXIT_CODE
fi
