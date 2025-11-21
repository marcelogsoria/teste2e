set -e
echo "=========================================="
echo "Ejecutando tests con Maestro"
echo "=========================================="

# Asegurar que Maestro esté en el PATH
export PATH="$PATH:$HOME/.maestro/bin"

# Verificar que Maestro esté instalado
maestro --version || echo "Advertencia: Maestro no está disponible"

# Verificar directorio de trabajo y existencia del archivo
echo "Directorio de trabajo actual: $(pwd)"
echo "Verificando archivo de test..."
if [ -f ".maestro/wikipedia-ios.yaml" ]; then
  echo "Archivo encontrado: .maestro/wikipedia-ios.yaml"
else
  echo "ERROR: Archivo .maestro/wikipedia-ios.yaml no encontrado"
  echo "Archivos en .maestro/:"
  ls -la .maestro/ || echo "Directorio .maestro no existe"
  exit 1
fi

# Ejecutar tests con Maestro (con debug y screenshots)
xcrun simctl io booted recordVideo --force ./recording.mov &
VIDEO_PID=$!
echo "PID del proceso de grabación: $VIDEO_PID"

set +e  # No fallar inmediatamente si Maestro falla
maestro test .maestro/wikipedia-ios.yaml --format junit --output maestro-report.xml
MAESTRO_EXIT_CODE=$?
#set -e  # Volver a activar el modo estricto

kill $VIDEO_PID
sleep 2  # darle tiempo a cerrar el archivo

echo ""
echo "=========================================="
echo "Resultados de las pruebas"
echo "=========================================="
echo ""
echo "Tests ejecutados con Maestro Mobile Test"
echo "Aplicación: UIKitCatalog iOS"
echo "Fecha: $(date)"
echo ""

if [ "$MAESTRO_EXIT_CODE" != "0" ]; then
  cp ./recording.mov ./videos/maestro-video.mov
fi

# Si Maestro falló, obtener información adicional de debug
# if [ "$MAESTRO_EXIT_CODE" != "0" ]; then
#   echo "=========================================="
#   echo "DEBUG: Información de la pantalla actual (Maestro falló)"
#   echo "=========================================="
  
#   UDID="${{ steps.boot-simulator.outputs.udid }}"
  
#   echo ""
#   echo "--- Capturando screenshot manual del estado actual ---"
#   SCREENSHOT_NAME="maestro-failure-$(date +%Y%m%d-%H%M%S).png"
#   xcrun simctl io "$UDID" screenshot "$SCREENSHOT_NAME" 2>/dev/null && echo "Screenshot guardado: $SCREENSHOT_NAME" || echo "No se pudo capturar screenshot"
  
#   echo ""
#   echo "--- Logs recientes del simulador ---"
#   xcrun simctl spawn "$UDID" log show --predicate 'processImagePath contains "UIKitCatalog"' --last 1m --style compact | tail -50 || echo "No se pudieron obtener logs"
  
#   echo ""
#   echo "--- Screenshots generados por Maestro ---"
#   find . -name "*.png" -type f -mmin -5 | head -10 || echo "No se encontraron screenshots recientes de Maestro"
  
#   echo ""
# fi

if [ -f maestro-report.xml ]; then
  echo "Reporte generado: maestro-report.xml"
  cat maestro-report.xml
else
  echo "No se generó reporte de Maestro"
fi

echo "=========================================="

# Guardar screenshots en un directorio para artefactos
mkdir -p maestro-screenshots

# Copiar screenshots de Maestro (ubicación por defecto)
# Maestro guarda los resultados en carpetas con timestamp dentro de ~/.maestro/tests/
if [ -d "$HOME/.maestro/tests" ]; then
  echo "Encontrados artefactos en default location, copiando..."
  cp -r "$HOME/.maestro/tests/"* maestro-screenshots/ || true
else
  echo "No se encontró el directorio $HOME/.maestro/tests/"
fi

# Copiar screenshots manuales (si los hubo)
find . -name "*.mov" -exec cp {} maestro-screenshots/ \; || true
find . -name "*.png" -exec cp {} maestro-screenshots/ \; || true
