@echo off
echo ============================================
echo SnapBill Backend Server Startup
echo ============================================
echo.
echo Checking network connection...
python test_connection.py
echo.
echo ============================================
if %ERRORLEVEL% EQU 0 (
    echo Starting server...
    echo Server will run at http://0.0.0.0:8000
    echo Press Ctrl+C to stop
    echo ============================================
    echo.
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
) else (
    echo.
    echo ERROR: Cannot connect to database!
    echo Please connect to mobile hotspot or VPN and try again.
    echo.
    pause
)
