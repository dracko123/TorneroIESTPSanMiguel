@echo off
title Servidor Web Portal - Torneo Deportivo
echo ========================================================
echo   Iniciando Web del Torneo Deportivo en vivo...
echo   Se abrira en tu navegador predeterminado:
echo   http://localhost:5173
echo ========================================================
cd /d "%~dp0"
call npm.cmd run dev -- --open --port 5173
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] No se pudo iniciar con npm. Intentando directamente con npx vite...
    call npx.cmd vite --open --port 5173
)
pause

