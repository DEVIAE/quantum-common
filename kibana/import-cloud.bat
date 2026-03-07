@echo off
REM =============================================================================
REM Quantum File Processor - Import Dashboards to Elastic Cloud Serverless
REM =============================================================================
REM Importa data views, saved searches y dashboards a Elastic Cloud.
REM
REM Uso:
REM   import-cloud.bat                        (usa defaults)
REM   import-cloud.bat [KIBANA_URL] [API_KEY]
REM
REM NOTA: Elastic Cloud Serverless NO soporta Watcher ni ILM.
REM       Usa Data Stream Lifecycle y Kibana Alerting en su lugar.
REM =============================================================================

setlocal enabledelayedexpansion

REM --- Configuracion ---
set KIBANA_URL=%~1
set API_KEY=%~2

if "%KIBANA_URL%"=="" set KIBANA_URL=https://my-elasticsearch-project-c3fe02.kb.us-central1.gcp.elastic.cloud:443
if "%API_KEY%"=="" set API_KEY=WDVHTHhad0JaVlZyenNpZlhfdmg6dDgwaEVPZGFZVVBvWUF6bkZxYU5rZw==

set SCRIPT_DIR=%~dp0

echo =============================================
echo  Quantum ELK - Import to Elastic Cloud
echo =============================================
echo.
echo  Kibana URL: %KIBANA_URL%
echo.

REM --- Verificar conectividad ---
echo [0/3] Verificando conectividad...
curl -sf -H "Authorization: ApiKey %API_KEY%" "%KIBANA_URL%/api/status" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  ERROR: No se puede conectar a Kibana en %KIBANA_URL%
    echo  Verifica que el endpoint y API Key sean correctos.
    exit /b 1
)
echo  Kibana Cloud OK
echo.

REM =============================================================================
REM PASO 1: Importar Data Views + Saved Searches
REM =============================================================================
echo [1/3] Importando Data Views y Saved Searches...

echo  Data Views (logs, audit, metrics)...
curl -sf -X POST ^
  -H "Authorization: ApiKey %API_KEY%" ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%01-data-views.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.

echo  Saved Search: Chunk Events Explorer...
curl -sf -X POST ^
  -H "Authorization: ApiKey %API_KEY%" ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%02-discover-logs.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.

echo  Saved Search: Chunks Fallidos...
curl -sf -X POST ^
  -H "Authorization: ApiKey %API_KEY%" ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%03-discover-audit.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.
echo  Data Views y Saved Searches importados.
echo.

REM =============================================================================
REM PASO 2: Importar Dashboards (Lens inline - Serverless compatible)
REM =============================================================================
echo [2/3] Importando Dashboards...

echo  Dashboard: Quantum Chunk Events - Monitoreo...
curl -sf -X POST ^
  -H "Authorization: ApiKey %API_KEY%" ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%04-dashboard-logs.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.

echo  Dashboard: Quantum Chunk Events - Resumen por Archivo...
curl -sf -X POST ^
  -H "Authorization: ApiKey %API_KEY%" ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%05-dashboard-audit.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.

echo  Dashboard: Quantum Overview - Procesamiento...
curl -sf -X POST ^
  -H "Authorization: ApiKey %API_KEY%" ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%06-dashboard-overview.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.
echo  Dashboards importados.
echo.

REM =============================================================================
REM PASO 3: Verificacion
REM =============================================================================
echo [3/3] Verificando importacion...
curl -sf -H "Authorization: ApiKey %API_KEY%" -H "kbn-xsrf: true" ^
  "%KIBANA_URL%/api/saved_objects/_find?type=dashboard&per_page=10" 2>nul
echo.
echo.

REM =============================================================================
REM Resumen
REM =============================================================================
echo =============================================
echo  Importacion Completada
echo =============================================
echo.
echo  Objetos importados:
echo    - 4 Data Views (logs, audit, metrics, chunk-events)
 echo    - 2 Saved Searches (chunk events explorer, chunks fallidos)
 echo    - 3 Dashboards (chunk events, resumen por archivo, overview)
echo.
echo  NOTA: Elastic Cloud Serverless no soporta:
echo    - Watcher (usar Kibana Alerting Rules)
echo    - ILM (usa Data Stream Lifecycle automatico)
echo.
echo  Acceder a Kibana: %KIBANA_URL%
echo    Analytics ^> Dashboard  - Ver dashboards
echo    Analytics ^> Discover   - Explorar logs/audit
echo.

endlocal
