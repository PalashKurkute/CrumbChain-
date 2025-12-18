@echo off
REM CrumbChain Backend - Quick Start Wrapper
REM This allows running with: python app.py

echo ============================================================
echo   CrumbChain Backend - Starting with venv_gpu
echo ============================================================
echo.

REM Check if venv exists
if not exist "venv_gpu\Scripts\activate.bat" (
    echo [ERROR] venv_gpu not found!
    echo Please run: start_server.ps1
    pause
    exit /b 1
)

REM Activate venv and run
echo Activating virtual environment...
call venv_gpu\Scripts\activate.bat

echo.
echo Starting Flask server with PyTorch support...
echo Server will be at: http://192.168.0.100:5000
echo.
python app.py
