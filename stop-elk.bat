@echo off
REM =============================================================================
REM Quantum ELK Stack - Stop Script
REM =============================================================================

echo Deteniendo Quantum ELK Stack...

cd /d "%~dp0docker"
docker compose down

echo.
echo ELK Stack detenido.
echo Para eliminar volumenes: docker compose -f docker/docker-compose.yml down -v
pause
