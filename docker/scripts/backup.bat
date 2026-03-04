@echo off
REM =============================================================================
REM Quantum ELK - Backup Script
REM R8: Plan de respaldo y recuperacion de datos
REM =============================================================================

echo =============================================
echo   Quantum ELK - Backup
echo =============================================

set ES_URL=http://localhost:9200
set ES_USER=elastic
set ES_PASS=quantum_elastic_2026

REM Crear snapshot
set SNAPSHOT_NAME=quantum-backup-%date:~-4,4%%date:~-7,2%%date:~-10,2%-%time:~0,2%%time:~3,2%
set SNAPSHOT_NAME=%SNAPSHOT_NAME: =0%

echo Creando snapshot: %SNAPSHOT_NAME%

curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_snapshot/quantum-backup/%SNAPSHOT_NAME%?wait_for_completion=true" ^
  -d "{\"indices\": \"quantum-*\", \"ignore_unavailable\": true, \"include_global_state\": false}"

echo.
echo Snapshot creado exitosamente.
echo.

REM Listar snapshots
echo Snapshots disponibles:
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/_snapshot/quantum-backup/_all?pretty"

pause
