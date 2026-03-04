@echo off
REM =============================================================================
REM Quantum ELK - Restore Script
REM R8: Recuperacion de datos
REM =============================================================================

echo =============================================
echo   Quantum ELK - Restore
echo =============================================

set ES_URL=http://localhost:9200
set ES_USER=elastic
set ES_PASS=quantum_elastic_2026

REM Listar snapshots disponibles
echo Snapshots disponibles:
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/_snapshot/quantum-backup/_all?pretty"

echo.
set /p SNAPSHOT_NAME="Ingrese el nombre del snapshot a restaurar: "

if "%SNAPSHOT_NAME%"=="" (
    echo No se ingreso nombre de snapshot.
    pause
    exit /b 1
)

echo.
echo Restaurando snapshot: %SNAPSHOT_NAME%
echo ADVERTENCIA: Esto cerrara los indices existentes antes de restaurar.
echo.
set /p CONFIRM="Confirmar? (S/N): "
if /I not "%CONFIRM%"=="S" (
    echo Operacion cancelada.
    pause
    exit /b 0
)

REM Cerrar indices antes de restaurar
curl -sf -X POST -u %ES_USER%:%ES_PASS% "%ES_URL%/quantum-*/_close"

REM Restaurar
curl -sf -X POST -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_snapshot/quantum-backup/%SNAPSHOT_NAME%/_restore?wait_for_completion=true" ^
  -d "{\"indices\": \"quantum-*\", \"ignore_unavailable\": true}"

echo.
echo Restauracion completada.
pause
