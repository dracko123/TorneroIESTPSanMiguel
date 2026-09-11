@echo off
title Servidor Web Portal - Torneo Deportivo
echo ========================================================
echo   Iniciando Web del Torneo Deportivo en vivo...
echo   Se abrira en tu navegador predeterminado:
echo   http://localhost:5173
echo ========================================================
cd /d "%~dp0"
call npm run dev -- --open
pause
