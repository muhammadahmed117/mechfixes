@echo off
setlocal
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] Virtual environment not found. Run setup.bat first.
    pause
    exit /b 1
)

if not exist ".env" (
    echo [WARNING] .env not found. Copy .env.example to .env and set GROQ_API_KEY.
    echo.
)

call .venv\Scripts\activate.bat

echo Starting FastAPI server at http://0.0.0.0:8000
echo Android emulator URL: http://10.0.2.2:8000
echo Press Ctrl+C to stop.
echo.

python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
