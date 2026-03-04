@echo off
REM =============================================================================
REM Quantum ELK Stack - Start Script
REM Inicia Elasticsearch + Logstash + Kibana + Metricbeat + Heartbeat
REM =============================================================================

echo =============================================
echo   Quantum ELK Stack - Starting...
echo =============================================

REM Verificar Docker
docker --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker no esta instalado o no esta en el PATH
    echo Instalar Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Verificar Docker Compose
docker compose version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker Compose no esta disponible
    pause
    exit /b 1
)

REM Verificar que Docker esta corriendo
docker info >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker Desktop no esta corriendo. Inicialo primero.
    pause
    exit /b 1
)

cd /d "%~dp0docker"

echo.
echo [1/3] Levantando infraestructura ELK...
docker compose up -d elasticsearch

echo.
echo [2/3] Esperando que Elasticsearch este listo (60s max)...
timeout /t 30 /nobreak >nul

:WAIT_ES
docker compose exec -T elasticsearch curl -sf http://localhost:9200/_cluster/health?wait_for_status=yellow >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   Elasticsearch aun no esta listo, esperando 10s...
    timeout /t 10 /nobreak >nul
    goto WAIT_ES
)

echo   Elasticsearch listo!

echo.
echo [3/3] Levantando Logstash, Kibana, Metricbeat, Heartbeat...
docker compose up -d

echo.
echo =============================================
echo   Quantum ELK Stack - Listo!
echo =============================================
echo.
echo   Elasticsearch: http://localhost:9200
echo   Kibana:        http://localhost:5601
echo   Logstash TCP:  localhost:5000
echo   Artemis:       http://localhost:8161
echo   Redis:         localhost:6379
echo.
echo   Credenciales:
echo     elastic / quantum_elastic_2026
echo     quantum_admin / quantum_admin_2026
echo     quantum_dev / quantum_dev_2026
echo.
echo   Para ver logs: docker compose -f docker/docker-compose.yml logs -f
echo   Para parar:    docker compose -f docker/docker-compose.yml down
echo =============================================

pause
