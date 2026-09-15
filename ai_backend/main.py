"""
Mechfixes AI Diagnostic API — FastAPI server (Groq-only).

Startup:
    1. Copy .env.example to .env and set GROQ_API_KEY
    2. Run server:  python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

Flutter call example:
    POST http://<your-ip>:8000/api/diagnose
    Body: {"symptoms": "engine shaking on idle, check engine light on"}
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from langchain_groq import ChatGroq
from langchain_core.messages import HumanMessage, SystemMessage
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from config import GROQ_API_KEY, GROQ_MODEL

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mechfixes-ai")

_FAULT_MARKER = "[FAULT]"
_ENGLISH_MARKER = "[ENGLISH]"
_ROMAN_URDU_MARKER = "[ROMAN_URDU]"

_SYSTEM_PROMPT = """You are Mechfixes, an expert automotive diagnostic mechanic AI.
You diagnose car problems from owner-described symptoms and give practical DIY guidance.

RULES:
1. Infer the most likely fault / diagnosis from the symptoms.
2. Give 3 to 4 concise bullet points in a logical repair sequence:
   Safety → Visual Inspection → Testing → Fix.
3. Be professional, polite, and clear. Do not invent unsafe procedures.
4. Output EXACTLY three labeled blocks and nothing else:

[FAULT]
<short fault name, e.g. Oil pan gasket leak>

[ENGLISH]
<english advice with bullet points>

[ROMAN_URDU]
<same advice in Roman Urdu using English letters A-Z only — NEVER use Arabic/Urdu script>
"""

# Lazy-initialized Groq client (no heavy local models).
_llm: ChatGroq | None = None


def _create_groq_llm() -> ChatGroq:
    if not GROQ_API_KEY:
        raise EnvironmentError(
            "GROQ_API_KEY is missing. Set it in ai_backend/.env or Render env vars."
        )
    return ChatGroq(
        model=GROQ_MODEL,
        temperature=0.4,
        api_key=GROQ_API_KEY,
    )


def _get_llm() -> ChatGroq:
    global _llm
    if _llm is None:
        _llm = _create_groq_llm()
    return _llm


def _parse_diagnostic_response(raw: str) -> tuple[str, str, str]:
    """Extract fault, English, and Roman Urdu sections from Groq output."""
    text = (raw or "").strip()
    if not text:
        return "Unknown fault", "", ""

    upper = text.upper()

    def _section(start_marker: str, end_marker: str | None) -> str:
        start = upper.find(start_marker)
        if start == -1:
            return ""
        content_start = start + len(start_marker)
        if end_marker:
            end = upper.find(end_marker, content_start)
            chunk = text[content_start:end] if end != -1 else text[content_start:]
        else:
            chunk = text[content_start:]
        return chunk.strip()

    fault = _section(_FAULT_MARKER, _ENGLISH_MARKER)
    english = _section(_ENGLISH_MARKER, _ROMAN_URDU_MARKER)
    roman = _section(_ROMAN_URDU_MARKER, None)

    # Fallback if model skipped markers
    if not fault and not english:
        english = text
        fault = "General diagnostic review"

    if not fault:
        fault = "Unknown fault"

    return fault, english, roman


def _generate_diagnosis(symptoms: str) -> tuple[str, str, str]:
    llm = _get_llm()
    user_prompt = (
        f"Customer symptoms:\n{symptoms}\n\n"
        "Diagnose the most likely fault and respond in the required [FAULT] / "
        "[ENGLISH] / [ROMAN_URDU] format only."
    )
    response = llm.invoke(
        [
            SystemMessage(content=_SYSTEM_PROMPT),
            HumanMessage(content=user_prompt),
        ]
    )
    content = getattr(response, "content", response)
    if isinstance(content, list):
        content = "".join(str(part) for part in content)
    return _parse_diagnostic_response(str(content))


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Validate Groq config on startup — no local models loaded."""
    global _llm
    if not GROQ_API_KEY:
        logger.warning("GROQ_API_KEY is not set — /api/diagnose will return 503.")
    else:
        try:
            _llm = _create_groq_llm()
            logger.info("Groq client ready (model=%s). No local ML/RAG loaded.", GROQ_MODEL)
        except Exception as exc:
            _llm = None
            logger.warning("Groq client init failed: %s", exc)
    yield
    _llm = None


app = FastAPI(
    title="Mechfixes AI Diagnostic API",
    description="Groq-powered car diagnostic advice for the Mechfixes Flutter app",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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


class HealthResponse(BaseModel):
    status: str
    groq_configured: bool
    model: str


@app.get("/")
async def root() -> dict[str, Any]:
    return {
        "service": "Mechfixes AI Diagnostic API",
        "status": "running",
        "mode": "groq-only",
        "docs": "/docs",
        "health": "/health",
        "diagnose": "POST /api/diagnose",
    }


@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        groq_configured=bool(GROQ_API_KEY) and _llm is not None,
        model=GROQ_MODEL,
    )


@app.post("/api/diagnose", response_model=DiagnoseResponse)
async def diagnose(request: DiagnoseRequest) -> DiagnoseResponse:
    """Send symptoms to Groq and return fault + bilingual DIY advice."""
    symptoms = request.symptoms.strip()

    if not GROQ_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="GROQ_API_KEY is missing. Set it in environment variables.",
        )

    try:
        fault, english, roman = _generate_diagnosis(symptoms)
    except Exception as exc:
        logger.exception("Groq diagnosis failed")
        raise HTTPException(
            status_code=502,
            detail=f"AI advice generation failed: {exc}",
        ) from exc

    if not english and not roman:
        english = "Sorry, advice could not be generated. Please try again."
        roman = "Maaf kijiye, abhi advice generate nahi ho saki. Dobara try karein."

    return DiagnoseResponse(
        predicted_fault=fault,
        ai_advice_english=english,
        ai_advice_roman_urdu=roman,
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
