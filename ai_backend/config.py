"""Central configuration for paths and environment variables."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

CSV_PATH = Path(
    os.getenv("CSV_PATH", BASE_DIR / "data" / "ML Car Diagnostic Agent AI Assistant.csv")
)
ML_MODEL_PATH = Path(os.getenv("ML_MODEL_PATH", BASE_DIR / "artifacts" / "ml_model.pkl"))
RAG_DB_PATH = Path(os.getenv("RAG_DB_PATH", BASE_DIR / "artifacts" / "rag_db"))

# Groq API key must come from environment or .env
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant")

# Local HuggingFace embeddings for FAISS (no API key required)
HUGGINGFACE_EMBEDDING_MODEL = os.getenv(
    "HUGGINGFACE_EMBEDDING_MODEL", "all-MiniLM-L6-v2"
)

# Expected CSV columns (case-insensitive matching is applied in train_model.py)
COL_CAR_NAME = "Car Name"
COL_PROBLEM = "Problem Description"
COL_ECU = "ECU Data"
COL_DIAGNOSIS = "Diagnosis"
COL_SOLUTION = "Solution"
COL_COMBINED = "Combined_Info"
