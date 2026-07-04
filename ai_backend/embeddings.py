"""Shared local embedding model for FAISS build and load."""

from __future__ import annotations

from langchain_huggingface import HuggingFaceEmbeddings

from config import HUGGINGFACE_EMBEDDING_MODEL


def get_huggingface_embeddings() -> HuggingFaceEmbeddings:
    """Return the same HuggingFace embeddings used when building the FAISS index."""
    return HuggingFaceEmbeddings(model_name=HUGGINGFACE_EMBEDDING_MODEL)
