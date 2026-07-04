@echo off
setlocal
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] Virtual environment not found. Run setup.bat first.
    pause
    exit /b 1
)

if not exist "artifacts\ml_model.pkl" (
    echo [WARNING] ML model not found. Run train_model.bat first.
    echo Server may return errors until training is done.
    echo.
)

call .venv\Scripts\activate.bat

echo Starting FastAPI server at http://0.0.0.0:8000
echo Android emulator URL: http://10.0.2.2:8000
echo Press Ctrl+C to stop.
echo.

python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
