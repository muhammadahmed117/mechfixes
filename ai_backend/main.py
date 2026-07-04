"""
Mechfixes AI Diagnostic API — FastAPI server.

Startup:
    1. Copy .env.example to .env and set GROQ_API_KEY
    2. Train models: python train_model.py
    3. Run server:  python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

Flutter call example:
    POST http://<your-ip>:8000/api/diagnose
    Body: {"symptoms": "engine shaking on idle, check engine light on"}
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from dataclasses import dataclass
from typing import Any

import joblib
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_groq import ChatGroq
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from config import GROQ_API_KEY, GROQ_MODEL, ML_MODEL_PATH, RAG_DB_PATH
from embeddings import get_huggingface_embeddings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mechfixes-ai")

_DIAGNOSTIC_PROMPT = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            (
                "You are Mechfixes, a professional and polite car diagnostic AI.\n"
                "SEQUENCE RULES: Provide 3 to 4 concise bullet points in a logical repair sequence: "
                "1. Safety, 2. Visual Inspection, 3. Testing, 4. Fix.\n"
                "LANGUAGE & FORMAT RULES: You MUST output exactly TWO blocks of text.\n"
                "Block 1 must be in standard English.\n"
                "Block 2 must be in Roman Urdu. CRITICAL: Roman Urdu MUST be written using "
                "English Alphabets (A-Z) ONLY (e.g., 'Engine ko check karein'). "
                "ABSOLUTELY NO Arabic/Urdu script (اردو).\n\n"
                "You MUST use this exact format with no extra tags:\n"
                "[ENGLISH]\n"
                "<english advice here>\n"
                "[ROMAN_URDU]\n"
                "<roman urdu advice here>"
            ),
        ),
        (
            "human",
            (
                "Retrieved knowledge:\n{context}\n\n"
                "User question:\n{question}\n\n"
                "Helpful answer:"
            ),
        ),
    ]
)

_ROMAN_URDU_MARKER = "[ROMAN_URDU]"
_ENGLISH_MARKER = "[ENGLISH]"


@dataclass
class DiagnosticRagPipeline:
    """Lightweight RAG pipeline compatible with LangChain 1.x (no langchain.chains)."""

    retriever: Any
    llm: ChatGroq

    def generate(self, question: str) -> str:
        docs = self.retriever.invoke(question)
        context = "\n\n".join(doc.page_content for doc in docs)
        response = self.llm.invoke(
            _DIAGNOSTIC_PROMPT.format_messages(context=context, question=question)
        )
        content = getattr(response, "content", response)
        if isinstance(content, str):
            return content.strip()
        if isinstance(content, list):
            return "".join(str(part) for part in content).strip()
        return str(content).strip()


# ── Globals loaded on startup ────────────────────────────────────────────────

ml_artifact: dict[str, Any] | None = None
rag_pipeline: DiagnosticRagPipeline | None = None


def _create_groq_llm() -> ChatGroq:
    """Initialize Groq chat model using GROQ_API_KEY from the environment."""
    if not GROQ_API_KEY:
        raise EnvironmentError(
            "GROQ_API_KEY is missing. Set it in ai_backend/.env"
        )

    return ChatGroq(
        model_name=GROQ_MODEL,
        temperature=0.6,
        groq_api_key=GROQ_API_KEY,
    )


def _predict_fault(symptoms: str) -> str:
    """Run the saved sklearn pipeline and decode the diagnosis label."""
    if ml_artifact is None:
        raise RuntimeError("ML model is not loaded.")

    pipeline = ml_artifact["pipeline"]
    label_encoder = ml_artifact["label_encoder"]
    text = symptoms.strip()

    if not text:
        raise ValueError("Symptoms text is empty.")

    encoded = pipeline.predict([text])[0]
    return str(label_encoder.inverse_transform([encoded])[0])


def _build_rag_pipeline() -> DiagnosticRagPipeline:
    """Load FAISS retriever + Groq chat model."""
    if not GROQ_API_KEY:
        raise EnvironmentError(
            "GROQ_API_KEY is missing. Set it in ai_backend/.env"
        )

    if not RAG_DB_PATH.exists():
        raise FileNotFoundError(
            f"RAG database not found at '{RAG_DB_PATH}'. Run train_model.py first."
        )

    embeddings = get_huggingface_embeddings()
    vector_store = FAISS.load_local(
        str(RAG_DB_PATH),
        embeddings,
        allow_dangerous_deserialization=True,
    )
    retriever = vector_store.as_retriever(search_kwargs={"k": 4})

    llm = _create_groq_llm()
    logger.info("Using Groq model: %s", GROQ_MODEL)

    return DiagnosticRagPipeline(retriever=retriever, llm=llm)


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Load ML model and RAG pipeline when the server starts."""
    global ml_artifact, rag_pipeline

    if not ML_MODEL_PATH.exists():
        logger.warning(
            "ML model not found at %s — run train_model.py first.", ML_MODEL_PATH
        )
    else:
        ml_artifact = joblib.load(ML_MODEL_PATH)
        logger.info("ML model loaded from %s", ML_MODEL_PATH)

    try:
        rag_pipeline = _build_rag_pipeline()
        logger.info("RAG pipeline ready (HuggingFace + Groq).")
    except Exception as exc:
        rag_pipeline = None
        logger.warning("RAG pipeline not loaded: %s", exc)

    yield

    ml_artifact = None
    rag_pipeline = None


app = FastAPI(
    title="Mechfixes AI Diagnostic API",
    description="ML fault prediction + LangChain RAG repair advice for Flutter app",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request / Response models ────────────────────────────────────────────────


class DiagnoseRequest(BaseModel):
    """POST /api/diagnose — send {\"symptoms\": \"your car problem description\"}."""

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "symptoms": (
                        "Engine vibrates on idle, check engine light blinking"
                    ),
                }
            ]
        }
    )

    symptoms: str = Field(
        ...,
        min_length=3,
        description="User-described car symptoms / problem description",
    )

    @model_validator(mode="before")
    @classmethod
    def _normalize_body(cls, data: Any) -> Any:
        if isinstance(data, str):
            return {"symptoms": data}
        if not isinstance(data, dict):
            return data

        if data.get("symptoms"):
            return data

        for alias in ("message", "query", "user_query", "text", "problem"):
            value = data.get(alias)
            if value is not None and str(value).strip():
                data["symptoms"] = str(value).strip()
                break

        return data

    @field_validator("symptoms")
    @classmethod
    def _strip_symptoms(cls, value: str) -> str:
        return value.strip()


class DiagnoseResponse(BaseModel):
    predicted_fault: str
    ai_advice_english: str
    ai_advice_roman_urdu: str


def _parse_bilingual_advice(ai_advice: str) -> tuple[str, str]:
    """Split LLM output into English and Roman Urdu sections."""
    text = ai_advice.strip()
    if not text:
        return "", ""

    try:
        upper_text = text.upper()
        marker_index = upper_text.find(_ROMAN_URDU_MARKER)

        if marker_index != -1:
            english_part = text[:marker_index]
            roman_part = text[marker_index + len(_ROMAN_URDU_MARKER) :]

            english = (
                english_part.replace(_ENGLISH_MARKER, "")
                .replace("[english]", "")
                .strip()
            )
            roman_urdu = (
                roman_part.replace(_ROMAN_URDU_MARKER, "")
                .replace(_ENGLISH_MARKER, "")
                .replace("[english]", "")
                .strip()
            )
            return english, roman_urdu

        english_only = (
            text.replace(_ENGLISH_MARKER, "")
            .replace("[english]", "")
            .replace(_ROMAN_URDU_MARKER, "")
            .strip()
        )
        return english_only, ""
    except Exception:
        logger.warning("Failed to parse bilingual advice markers; using full text as English.")
        return text.strip(), ""


class HealthResponse(BaseModel):
    status: str
    ml_model_loaded: bool
    rag_loaded: bool


# ── Routes ───────────────────────────────────────────────────────────────────


@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        ml_model_loaded=ml_artifact is not None,
        rag_loaded=rag_pipeline is not None,
    )


@app.post("/api/diagnose", response_model=DiagnoseResponse)
async def diagnose(request: DiagnoseRequest) -> DiagnoseResponse:
    """
    1. Predict fault with the trained RandomForest model.
    2. Generate conversational Roman Urdu/English DIY advice via RAG + Groq.
    """
    symptoms = request.symptoms.strip()

    if ml_artifact is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "ML model not loaded. Run: python train_model.py "
                f"(expected file: {ML_MODEL_PATH})"
            ),
        )

    if rag_pipeline is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "RAG pipeline not loaded. Run train_model.py to build the FAISS index "
                "and set GROQ_API_KEY in .env for Groq chat."
            ),
        )

    try:
        predicted_fault = _predict_fault(symptoms)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("ML prediction failed")
        raise HTTPException(status_code=500, detail=f"ML prediction failed: {exc}") from exc

    rag_question = (
        f"User symptoms: {symptoms}\n"
        f"ML predicted fault: {predicted_fault}\n"
        "Respond with exactly two blocks using [ENGLISH] and [ROMAN_URDU] markers only. "
        "Roman Urdu must use Latin letters A-Z only — no Arabic/Urdu script."
    )

    try:
        ai_advice = rag_pipeline.generate(rag_question)
        if not ai_advice:
            ai_advice = (
                "[ENGLISH]\n"
                "Sorry, advice could not be generated. Please try again.\n"
                "[ROMAN_URDU]\n"
                "Maaf kijiye, abhi advice generate nahi ho saki. Dobara try karein."
            )
    except Exception as exc:
        logger.exception("RAG generation failed")
        raise HTTPException(
            status_code=502,
            detail=f"AI advice generation failed: {exc}",
        ) from exc

    ai_advice_english, ai_advice_roman_urdu = _parse_bilingual_advice(ai_advice)

    return DiagnoseResponse(
        predicted_fault=predicted_fault,
        ai_advice_english=ai_advice_english,
        ai_advice_roman_urdu=ai_advice_roman_urdu,
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
