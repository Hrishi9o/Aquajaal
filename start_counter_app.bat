@echo off
title Yashodhar Enterprises - Aquajaal POS Counter Server
color 1F

echo ===============================================================
echo   YASHODHAR ENTERPRISES - AQUAJAAL POS BILLING COUNTER
echo   Packaged Drinking Water Distributor - Shirva, Udupi
echo ===============================================================
echo.
echo Starting local production POS web server on port 8080...
echo Opening POS Counter application in your default browser...
echo.
echo Press Ctrl+C at any time to stop the server.
echo ===============================================================
echo.

start "" "http://localhost:8080"
python -m http.server 8080 --directory build\web

pause
