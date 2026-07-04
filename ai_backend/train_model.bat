@echo off
setlocal
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] Virtual environment not found. Run setup.bat first.
    pause
    exit /b 1
)

call .venv\Scripts\activate.bat

echo Installing/updating dependencies...
python -m pip install -q sentence-transformers huggingface-hub langchain-huggingface
if errorlevel 1 (
    echo [ERROR] pip install failed.
    pause
    exit /b 1
)

echo.
echo Training ML model and RAG index...
python train_model.py
if errorlevel 1 (
    echo.
    echo [ERROR] Training failed. Check CSV path and internet connection for HuggingFace model download.
    pause
    exit /b 1
)

echo.
echo Training finished successfully.
pause
