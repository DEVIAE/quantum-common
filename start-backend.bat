@echo off
setlocal enabledelayedexpansion
title Quantum Common - Build & Install
echo ========================================
echo   Quantum Common - Shared Library
echo   Spring Boot 3.2.4 + Java 21
echo   Version: 1.0.0
echo ========================================
echo.

set JAVA_HOME=C:\Program Files\Java\jdk-21
set MAVEN_HOME=E:\Projects\Java\Maven\apache-maven-3.8.6
set PATH=%JAVA_HOME%\bin;%MAVEN_HOME%\bin;%PATH%

cd /d %~dp0

echo [INFO] JAVA_HOME = %JAVA_HOME%
echo [INFO] MAVEN_HOME = %MAVEN_HOME%
echo.

:: ========================================
:: Crear carpeta logs y generar nombre de archivo (ddmmyyhhmm.log)
:: ========================================
if not exist logs mkdir logs

set "DD=%date:~0,2%"
set "MM=%date:~3,2%"
set "YY=%date:~8,2%"
set "HH=%time:~0,2%"
set "MI=%time:~3,2%"
set "HH=!HH: =0!"
set "LOG_FILE=logs\!DD!!MM!!YY!!HH!!MI!.log"

for %%F in ("!LOG_FILE!") do set "LOG_FULL=%%~fF"

echo [INFO] Log: !LOG_FULL!
echo.
echo ========================================
echo   Tipo:     Libreria compartida (JAR)
echo   Accion:   mvn clean install
echo   Registry: Maven local (~/.m2/repository)
echo ========================================
echo.
echo [INFO] Este proyecto es una LIBRERIA, no un servicio ejecutable.
echo [INFO] Se compilara e instalara en el repositorio Maven local.
echo [INFO] Los servicios (file-ingester, chunk-processor) dependen de esta libreria.
echo.

:: ========================================
:: Ejecutar Maven clean install con salida a log y consola
:: ========================================
echo ======================================== >> "!LOG_FULL!"
echo   Quantum Common - Build: %date% %time% >> "!LOG_FULL!"
echo ======================================== >> "!LOG_FULL!"

set "PS_SCRIPT=%TEMP%\quantum-common-build.ps1"
(
    echo $ErrorActionPreference = 'Continue'
    echo $logFile = '!LOG_FULL!'
    echo Write-Host "[INFO] Ejecutando mvn clean install..."
    echo Write-Host "[INFO] Log: $logFile"
    echo ^& mvn clean install 2^>^&1 ^| ForEach-Object {
    echo     $line = $_
    echo     Write-Host $line
    echo     $line ^| Out-File -FilePath $logFile -Append -Encoding utf8
    echo }
    echo Write-Host ""
    echo if ($LASTEXITCODE -eq 0^) {
    echo     Write-Host "[OK] quantum-common instalado correctamente en Maven local." -ForegroundColor Green
    echo     Write-Host "[INFO] Ahora puedes compilar quantum-file-ingester y quantum-chunk-processor."
    echo } else {
    echo     Write-Host "[ERROR] Build fallido. Revisa el log: $logFile" -ForegroundColor Red
    echo }
) > "!PS_SCRIPT!"

powershell -NoProfile -ExecutionPolicy Bypass -File "!PS_SCRIPT!"

del "!PS_SCRIPT!" >nul 2>&1

echo.
echo [INFO] Build finalizado. Log guardado en !LOG_FULL!
pause
