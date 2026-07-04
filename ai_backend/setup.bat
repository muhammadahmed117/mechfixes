@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo  Mechfixes AI Backend - Setup
echo ============================================
echo.

where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not on PATH.
    echo.
    echo 1. Download Python 3.11+ from:
    echo    https://www.python.org/downloads/
    echo 2. During install, CHECK this box:
    echo    "Add python.exe to PATH"
    echo 3. Close and reopen PowerShell, then run setup.bat again.
    echo.
    pause
    exit /b 1
)

echo Using:
python --version
echo.

if not exist ".venv\Scripts\python.exe" (
    echo Creating virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
)

call .venv\Scripts\activate.bat

echo Installing dependencies...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] pip install failed.
    pause
    exit /b 1
)

echo.
echo ============================================
echo  Setup complete!
echo ============================================
echo.
echo Next steps:
echo   1. Copy .env.example to .env and add OPENAI_API_KEY
echo   2. Put your CSV in the data\ folder
echo   3. Run: train_model.bat
echo   4. Run: start_server.bat
echo.
pause
