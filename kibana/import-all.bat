@echo off
REM =============================================================================
REM Quantum File Processor - Script de Importacion de Dashboards ELK
REM =============================================================================
REM Importa todos los saved objects, alertas Watcher e ILM policies a ELK.
REM Uso: import-all.bat [KIBANA_URL] [ES_URL] [USER] [PASS]
REM =============================================================================

setlocal enabledelayedexpansion

REM --- Configuracion ---
set KIBANA_URL=%~1
set ES_URL=%~2
set ES_USER=%~3
set ES_PASS=%~4

if "%KIBANA_URL%"=="" set KIBANA_URL=http://localhost:5601
if "%ES_URL%"=="" set ES_URL=http://localhost:9200
if "%ES_USER%"=="" set ES_USER=elastic
if "%ES_PASS%"=="" set ES_PASS=quantum_elastic_2026

set SCRIPT_DIR=%~dp0

echo =============================================
echo  Quantum ELK - Importacion de Dashboards
echo =============================================
echo.
echo  Kibana URL: %KIBANA_URL%
echo  ES URL:     %ES_URL%
echo  Usuario:    %ES_USER%
echo.

REM --- Verificar conectividad ---
echo [0/5] Verificando conectividad...
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/_cluster/health" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  ERROR: No se puede conectar a Elasticsearch en %ES_URL%
    echo  Verifica que ELK este corriendo y las credenciales sean correctas.
    exit /b 1
)
echo  Elasticsearch OK
curl -sf -u %ES_USER%:%ES_PASS% "%KIBANA_URL%/api/status" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo  ERROR: No se puede conectar a Kibana en %KIBANA_URL%
    exit /b 1
)
echo  Kibana OK
echo.

REM =============================================================================
REM PASO 1: Importar Data Views (Index Patterns)
REM =============================================================================
echo [1/5] Importando Data Views...
curl -sf -X POST -u %ES_USER%:%ES_PASS% ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%01-data-views.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.
echo  Data Views importados.
echo.

REM =============================================================================
REM PASO 2: Importar Saved Searches (Discover)
REM =============================================================================
echo [2/5] Importando Saved Searches...

echo  Importando Logs Explorer...
curl -sf -X POST -u %ES_USER%:%ES_PASS% ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%02-discover-logs.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.

echo  Importando Audit Explorer...
curl -sf -X POST -u %ES_USER%:%ES_PASS% ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%03-discover-audit.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.
echo  Saved Searches importados.
echo.

REM =============================================================================
REM PASO 3: Importar Dashboards + Visualizaciones
REM =============================================================================
echo [3/5] Importando Dashboards...

echo  Importando Dashboard de Logs...
curl -sf -X POST -u %ES_USER%:%ES_PASS% ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%04-dashboard-logs.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.

echo  Importando Dashboard de Auditoria...
curl -sf -X POST -u %ES_USER%:%ES_PASS% ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%05-dashboard-audit.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.

echo  Importando Dashboard Principal (Overview)...
curl -sf -X POST -u %ES_USER%:%ES_PASS% ^
  -H "kbn-xsrf: true" ^
  --form file=@"%SCRIPT_DIR%06-dashboard-overview.ndjson" ^
  "%KIBANA_URL%/api/saved_objects/_import?overwrite=true"
echo.
echo  Dashboards importados.
echo.

REM =============================================================================
REM PASO 4: Crear Alertas Watcher
REM =============================================================================
echo [4/5] Creando alertas Watcher...

echo  Creando alerta: high-error-rate...
curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_watcher/watch/high-error-rate" ^
  -d "{\"trigger\":{\"schedule\":{\"interval\":\"5m\"}},\"input\":{\"search\":{\"request\":{\"indices\":[\"quantum-logs-*\"],\"body\":{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"term\":{\"log.level\":\"ERROR\"}},{\"range\":{\"@timestamp\":{\"gte\":\"now-5m\"}}}]}}}}}},\"condition\":{\"compare\":{\"ctx.payload.hits.total.value\":{\"gt\":10}}},\"actions\":{\"log_alert\":{\"logging\":{\"text\":\"ALERT: High error rate detected - {{ctx.payload.hits.total.value}} errors in last 5 minutes\"}},\"index_alert\":{\"index\":{\"index\":\"quantum-alerts\",\"doc_id\":\"high-error-rate-{{ctx.trigger.triggered_time}}\"}}}}"
echo.

echo  Creando alerta: chunk-failure-alert...
curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_watcher/watch/chunk-failure-alert" ^
  -d "{\"trigger\":{\"schedule\":{\"interval\":\"10m\"}},\"input\":{\"search\":{\"request\":{\"indices\":[\"quantum-logs-*\"],\"body\":{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"terms\":{\"tags\":[\"chunk_failure\"]}},{\"range\":{\"@timestamp\":{\"gte\":\"now-10m\"}}}]}}}}}},\"condition\":{\"compare\":{\"ctx.payload.hits.total.value\":{\"gt\":5}}},\"actions\":{\"log_alert\":{\"logging\":{\"text\":\"ALERT: Multiple chunk failures - {{ctx.payload.hits.total.value}} failures in last 10 minutes\"}},\"index_alert\":{\"index\":{\"index\":\"quantum-alerts\",\"doc_id\":\"chunk-failure-{{ctx.trigger.triggered_time}}\"}}}}"
echo.

echo  Creando alerta: dlq-alert...
curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_watcher/watch/dlq-alert" ^
  -d "{\"trigger\":{\"schedule\":{\"interval\":\"5m\"}},\"input\":{\"search\":{\"request\":{\"indices\":[\"quantum-logs-*\"],\"body\":{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"terms\":{\"tags\":[\"dlq_event\"]}},{\"range\":{\"@timestamp\":{\"gte\":\"now-5m\"}}}]}}}}}},\"condition\":{\"compare\":{\"ctx.payload.hits.total.value\":{\"gt\":0}}},\"actions\":{\"log_alert\":{\"logging\":{\"text\":\"ALERT: Messages sent to DLQ - {{ctx.payload.hits.total.value}} DLQ events in last 5 minutes\"}},\"index_alert\":{\"index\":{\"index\":\"quantum-alerts\",\"doc_id\":\"dlq-event-{{ctx.trigger.triggered_time}}\"}}}}"
echo.

echo  Creando alerta: service-down-alert...
curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_watcher/watch/service-down-alert" ^
  -d "{\"trigger\":{\"schedule\":{\"interval\":\"2m\"}},\"input\":{\"search\":{\"request\":{\"indices\":[\"heartbeat-*\"],\"body\":{\"size\":0,\"query\":{\"bool\":{\"must\":[{\"term\":{\"monitor.status\":\"down\"}},{\"range\":{\"@timestamp\":{\"gte\":\"now-2m\"}}}]}}}}}},\"condition\":{\"compare\":{\"ctx.payload.hits.total.value\":{\"gt\":0}}},\"actions\":{\"log_alert\":{\"logging\":{\"text\":\"CRITICAL: Service DOWN - {{ctx.payload.hits.total.value}} health check failures\"}},\"index_alert\":{\"index\":{\"index\":\"quantum-alerts\",\"doc_id\":\"service-down-{{ctx.trigger.triggered_time}}\"}}}}"
echo.
echo  Alertas Watcher creadas.
echo.

REM =============================================================================
REM PASO 5: Crear Politicas ILM
REM =============================================================================
echo [5/5] Creando politicas ILM...

echo  Creando quantum-logs-policy (7d hot, 30d warm, 90d cold, 180d delete)...
curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_ilm/policy/quantum-logs-policy" ^
  -d "{\"policy\":{\"phases\":{\"hot\":{\"min_age\":\"0ms\",\"actions\":{\"rollover\":{\"max_primary_shard_size\":\"10gb\",\"max_age\":\"7d\"},\"set_priority\":{\"priority\":100}}},\"warm\":{\"min_age\":\"30d\",\"actions\":{\"shrink\":{\"number_of_shards\":1},\"forcemerge\":{\"max_num_segments\":1},\"set_priority\":{\"priority\":50}}},\"cold\":{\"min_age\":\"90d\",\"actions\":{\"set_priority\":{\"priority\":0}}},\"delete\":{\"min_age\":\"180d\",\"actions\":{\"delete\":{}}}}}}"
echo.

echo  Creando quantum-metrics-policy (1d hot, 30d delete)...
curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_ilm/policy/quantum-metrics-policy" ^
  -d "{\"policy\":{\"phases\":{\"hot\":{\"min_age\":\"0ms\",\"actions\":{\"rollover\":{\"max_primary_shard_size\":\"5gb\",\"max_age\":\"1d\"}}},\"delete\":{\"min_age\":\"30d\",\"actions\":{\"delete\":{}}}}}}"
echo.

echo  Creando quantum-audit-policy (30d hot, 90d warm, 365d delete)...
curl -sf -X PUT -u %ES_USER%:%ES_PASS% ^
  -H "Content-Type: application/json" ^
  "%ES_URL%/_ilm/policy/quantum-audit-policy" ^
  -d "{\"policy\":{\"phases\":{\"hot\":{\"min_age\":\"0ms\",\"actions\":{\"rollover\":{\"max_primary_shard_size\":\"10gb\",\"max_age\":\"30d\"}}},\"warm\":{\"min_age\":\"90d\",\"actions\":{\"forcemerge\":{\"max_num_segments\":1}}},\"delete\":{\"min_age\":\"365d\",\"actions\":{\"delete\":{}}}}}}"
echo.
echo  Politicas ILM creadas.
echo.

REM =============================================================================
REM Resumen
REM =============================================================================
echo =============================================
echo  Importacion Completada
echo =============================================
echo.
echo  Objetos importados:
echo    - 3 Data Views (logs, audit, metrics)
echo    - 2 Saved Searches (logs explorer, audit explorer)
echo    - 3 Dashboards (logs, audit, overview)
echo    - 4 Alertas Watcher
echo    - 3 Politicas ILM
echo.
echo  Acceder a Kibana: %KIBANA_URL%
echo    Analytics ^> Dashboard  - Ver dashboards
echo    Analytics ^> Discover   - Explorar logs/audit
echo    Stack Management ^> Watcher   - Gestionar alertas
echo    Stack Management ^> ILM       - Politicas de retencion
echo.

endlocal
