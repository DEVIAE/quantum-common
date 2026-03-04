@echo off
REM =============================================================================
REM Quantum ELK - Health Check Script
REM R26: Auditar salud de servicios
REM R28: Monitoreo de recursos
REM =============================================================================

echo =============================================
echo   Quantum ELK - Health Check
echo =============================================
echo.

set ES_URL=http://localhost:9200
set ES_USER=elastic
set ES_PASS=quantum_elastic_2026

echo === Elasticsearch Cluster Health ===
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/_cluster/health?pretty"
echo.

echo === Elasticsearch Nodes Stats ===
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/_cat/nodes?v&h=name,heap.percent,ram.percent,cpu,load_1m,disk.used_percent"
echo.

echo === Index Stats ===
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/_cat/indices/quantum-*?v&h=index,docs.count,store.size,health,status"
echo.

echo === ILM Policy Status ===
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/_ilm/status?pretty"
echo.

echo === Logstash Stats ===
curl -sf http://localhost:9600/_node/stats/pipelines?pretty 2>nul || echo Logstash no disponible
echo.

echo === Kibana Status ===
curl -sf http://localhost:5601/api/status 2>nul | findstr "overall" || echo Kibana no disponible
echo.

echo === Docker Containers ===
docker ps --filter "name=quantum" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.

echo === Active Alerts ===
curl -sf -u %ES_USER%:%ES_PASS% "%ES_URL%/quantum-alerts/_count?pretty" 2>nul || echo No hay alertas
echo.

echo =============================================
echo   Health Check Complete
echo =============================================

pause
