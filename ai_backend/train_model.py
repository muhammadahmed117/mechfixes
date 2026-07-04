"""
Train the Mechfixes ML classifier and RAG vector database.

Usage:
    1. Place your CSV at: data/ML Car Diagnostic Agent AI Assistant.csv
    2. Run: python train_model.py  (RAG uses local HuggingFace embeddings — no API key)

Outputs:
    - artifacts/ml_model.pkl   (TF-IDF + RandomForest + label encoder)
    - artifacts/rag_db/        (FAISS index for LangChain RetrievalQA)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import joblib
import pandas as pd
from langchain_core.documents import Document
from langchain_community.vectorstores import FAISS
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder

from embeddings import get_huggingface_embeddings
from config import (
    COL_CAR_NAME,
    COL_COMBINED,
    COL_DIAGNOSIS,
    COL_ECU,
    COL_PROBLEM,
    COL_SOLUTION,
    CSV_PATH,
    ML_MODEL_PATH,
    RAG_DB_PATH,
)


def _normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Map CSV headers to expected names (case-insensitive, flexible spacing)."""
    rename_map: dict[str, str] = {}
    expected = {
        COL_CAR_NAME.lower(): COL_CAR_NAME,
        "car name": COL_CAR_NAME,
        "carname": COL_CAR_NAME,
        COL_PROBLEM.lower(): COL_PROBLEM,
        "problem description": COL_PROBLEM,
        "problem": COL_PROBLEM,
        COL_ECU.lower(): COL_ECU,
        "ecu data": COL_ECU,
        "ecu": COL_ECU,
        COL_DIAGNOSIS.lower(): COL_DIAGNOSIS,
        "diagnosis": COL_DIAGNOSIS,
        "fault": COL_DIAGNOSIS,
        COL_SOLUTION.lower(): COL_SOLUTION,
        "solution": COL_SOLUTION,
        "repair solution": COL_SOLUTION,
    }

    for col in df.columns:
        key = str(col).strip().lower()
        if key in expected:
            rename_map[col] = expected[key]

    df = df.rename(columns=rename_map)
    required = [COL_PROBLEM, COL_ECU, COL_DIAGNOSIS]
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(
            f"CSV is missing required columns: {missing}. "
            f"Found columns: {list(df.columns)}"
        )
    return df


def _clean_text(value: object) -> str:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return ""
    return str(value).strip()


def load_dataset(csv_path: Path) -> pd.DataFrame:
    if not csv_path.exists():
        raise FileNotFoundError(
            f"Dataset not found at '{csv_path}'. "
            "Place 'ML Car Diagnostic Agent AI Assistant.csv' in the data/ folder."
        )

    df = pd.read_csv(csv_path)
    df = _normalize_columns(df)

    for col in [COL_CAR_NAME, COL_PROBLEM, COL_ECU, COL_DIAGNOSIS, COL_SOLUTION]:
        if col in df.columns:
            df[col] = df[col].map(_clean_text)
        elif col != COL_CAR_NAME and col != COL_SOLUTION:
            df[col] = ""

    if COL_CAR_NAME not in df.columns:
        df[COL_CAR_NAME] = "Unknown Car"
    if COL_SOLUTION not in df.columns:
        df[COL_SOLUTION] = ""

    # Drop rows without a diagnosis label
    df = df[df[COL_DIAGNOSIS].astype(str).str.len() > 0].copy()
    if df.empty:
        raise ValueError("No valid training rows found after cleaning the CSV.")

    df[COL_COMBINED] = df.apply(
        lambda row: (
            f"Car: {row[COL_CAR_NAME]}\n"
            f"Problem: {row[COL_PROBLEM]}\n"
            f"ECU Data: {row[COL_ECU]}\n"
            f"Diagnosis: {row[COL_DIAGNOSIS]}\n"
            f"Solution: {row[COL_SOLUTION]}"
        ),
        axis=1,
    )
    return df.reset_index(drop=True)


def train_ml_model(df: pd.DataFrame) -> dict:
    """Train TF-IDF + RandomForest to predict Diagnosis from symptoms + ECU text."""
    feature_text = (
        df[COL_PROBLEM].fillna("") + " " + df[COL_ECU].fillna("")
    ).str.strip()

    label_encoder = LabelEncoder()
    labels = label_encoder.fit_transform(df[COL_DIAGNOSIS])

    pipeline = Pipeline(
        steps=[
            (
                "tfidf",
                TfidfVectorizer(
                    max_features=8000,
                    ngram_range=(1, 2),
                    stop_words="english",
                    min_df=1,
                ),
            ),
            (
                "clf",
                RandomForestClassifier(
                    n_estimators=200,
                    random_state=42,
                    class_weight="balanced_subsample",
                    n_jobs=-1,
                ),
            ),
        ]
    )
    pipeline.fit(feature_text, labels)

    return {
        "pipeline": pipeline,
        "label_encoder": label_encoder,
        "feature_columns": [COL_PROBLEM, COL_ECU],
        "target_column": COL_DIAGNOSIS,
    }


def build_rag_index(df: pd.DataFrame, rag_path: Path) -> None:
    """Build and persist a FAISS vector store from Combined_Info documents."""
    documents = [
        Document(
            page_content=row[COL_COMBINED],
            metadata={
                "car_name": row[COL_CAR_NAME],
                "diagnosis": row[COL_DIAGNOSIS],
                "row_index": int(idx),
            },
        )
        for idx, row in df.iterrows()
    ]

    print("Loading local HuggingFace embeddings (all-MiniLM-L6-v2) ...")
    embeddings = get_huggingface_embeddings()
    vector_store = FAISS.from_documents(documents, embeddings)
    rag_path.parent.mkdir(parents=True, exist_ok=True)
    vector_store.save_local(str(rag_path))
    print(f"RAG index saved to {rag_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Train Mechfixes ML + RAG artifacts")
    parser.add_argument(
        "--csv",
        type=Path,
        default=CSV_PATH,
        help="Path to the diagnostic CSV dataset",
    )
    parser.add_argument(
        "--skip-rag",
        action="store_true",
        help="Only train the ML model (skip FAISS RAG index)",
    )
    args = parser.parse_args()

    print(f"Loading dataset from {args.csv} ...")
    df = load_dataset(args.csv)
    print(f"Loaded {len(df)} rows, {df[COL_DIAGNOSIS].nunique()} unique diagnoses.")

    print("Training RandomForest + TF-IDF model ...")
    artifact = train_ml_model(df)
    ML_MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(artifact, ML_MODEL_PATH)
    print(f"ML model saved to {ML_MODEL_PATH}")

    if not args.skip_rag:
        print("Building FAISS RAG index (local HuggingFace embeddings) ...")
        build_rag_index(df, RAG_DB_PATH)

    print("Training complete. You can now run the server!")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc