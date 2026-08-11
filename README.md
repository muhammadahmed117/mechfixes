# Mechfixes

[![Flutter](https://img.shields.io/badge/Flutter-2CC5E8?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev) [![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org) [![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com) [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)

> A full-stack vehicle repair coordination platform with AI diagnostics, local mechanic discovery, and multilingual mobile support.

## 🚗 Project Overview

Mechfixes solves the problem of finding trusted car repair services while giving drivers fast, AI-powered diagnostic guidance. It combines:

- a Flutter mobile app for customers, mechanics, and admin users
- Firebase Authentication + Firestore for profile, verification, and mechanic discovery
- Google Maps routing and nearby mechanic filtering
- a Python FastAPI backend with an ML diagnosis model and RAG-powered AI advice

The app is designed for vehicle repair coordination, showing nearby verified mechanics, route guidance, and step-by-step repair recommendations in both English and Roman Urdu.

## ✨ Key Features

### Frontend Features

- Role-based mobile experience for `Customer`, `Mechanic`, and `Admin`
- Firebase Authentication for secure sign-in, signup, and sessions
- Mechanic onboarding and admin verification workflow
- Google Maps integration for mechanic location, routing, and nearby mechanic display
- Distance-aware mechanic selection using a 5km (5000m) radius filter
- Directions API route drawing and travel distance estimation
- Local fallback route calculation when Directions API is unavailable
- Multilingual UI support with English and Roman Urdu text
- Voice input using device microphone
- Text-to-speech playback for AI diagnostic advice
- Customer-side mechanic search and category filtering

### Backend Features

- Python FastAPI server exposing `/health` and `/api/diagnose`
- Trained ML classification pipeline using TF-IDF + RandomForest
- Local RAG vector store built with FAISS and HuggingFace embeddings
- Groq Chat model integration for bilingual AI advice generation
- Bilingual output parsing into `[ENGLISH]` and `[ROMAN_URDU]` sections
- Graceful error handling for model loading, prediction, and AI generation

## 🧠 Tech Stack

- Frontend
  - Flutter
  - Firebase Auth
  - Cloud Firestore
  - Google Maps Flutter
  - Geolocator
  - Geocoding
  - HTTP
  - speech_to_text
  - flutter_tts

- Backend
  - Python 3.11+ compatible
  - FastAPI
  - Uvicorn
  - scikit-learn
  - pandas
  - joblib
  - langchain-core
  - langchain-community
  - langchain-groq
  - FAISS vector store
  - dotenv

- Database
  - Firebase Firestore (mechanic profiles, user/admin data)
  - Local RAG index saved with FAISS
  - Local trained ML artifact saved with joblib

- Third-Party APIs
  - Google Maps Directions API
  - Groq AI model API
  - Local HuggingFace embeddings for FAISS vectorization

## 📁 Folder Structure

```text
D:/Mechfixes/
├── ai_backend/
│   ├── main.py                # FastAPI diagnostic server
│   ├── train_model.py         # Train ML classifier + build FAISS RAG index
│   ├── config.py              # env config, paths, Groq model settings
│   ├── embeddings.py          # HuggingFace embeddings helper
│   ├── requirements.txt       # Python backend dependencies
│   ├── start_server.bat       # Windows helper to launch FastAPI
│   ├── setup.bat              # Windows helper for backend setup
│   ├── train_model.bat        # Windows helper for training artifacts
│   ├── .env.example           # Example environment variables
│   ├── data/                  # Training CSV source data
│   └── artifacts/             # Saved ML and FAISS artifacts
├── android/                   # Android build and Gradle config
├── assets/
│   └── images/mechfixes_logo.png
├── lib/
│   ├── Admin/                 # Admin dashboard and management screens
│   ├── Customer/              # Customer screens, AI diagnostics, mechanic map
│   ├── Mechanic/              # Mechanic onboarding, profile, dashboard
│   ├── chat/                  # Chat screen UI
│   ├── core/
│   │   ├── config/            # app config values and API endpoints
│   │   ├── localization/      # language controls and translations
│   │   └── navigation/        # auth gate and app navigation
│   ├── data/                  # Firestore parsers and models
│   ├── models/                # shared data models
│   ├── services/              # API, location, maps, auth, and voice services
│   ├── create_account.dart
│   ├── login_screen.dart
│   ├── main.dart
│   ├── welcome_screen.dart
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## 🔧 Environment Variables & Secrets

### Backend `.env` variables

The Python backend expects the following values in `ai_backend/.env`.

```env
GROQ_API_KEY=your_groq_api_key
GROQ_MODEL=llama-3.1-8b-instant
HUGGINGFACE_EMBEDDING_MODEL=all-MiniLM-L6-v2
CSV_PATH=data/ML Car Diagnostic Agent AI Assistant.csv
ML_MODEL_PATH=artifacts/ml_model.pkl
RAG_DB_PATH=artifacts/rag_db
```

> Note: `ai_backend/config.py` currently includes a local Groq API key placeholder for development, but you should keep your real key secret and use `.env` for production.

### Flutter / Google Maps / Firebase secrets

- `lib/core/config/google_maps_config.dart` contains `GoogleMapsConfig.apiKey`
- `lib/core/config/diagnostic_api_config.dart` contains `pcLanIp` for physical-device backend access
- `lib/firebase_options.dart` is generated by `flutterfire configure`

You should replace the hardcoded Google Maps API key with your own secure configuration value in production.

## 🚀 Installation & Getting Started

### 1) Clone repository

```bash
git clone https://github.com/muhammadahmed117/mechfixes.git
cd mechfixes
```

### 2) Set up the Python FastAPI backend

```bash
cd ai_backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1    # PowerShell
pip install -r requirements.txt
copy .env.example .env
```

Edit `ai_backend/.env` and set `GROQ_API_KEY`, then optionally adjust `GROQ_MODEL`.

### 3) Train the AI artifacts

```bash
python train_model.py
```

This generates:

- `artifacts/ml_model.pkl`
- `artifacts/rag_db/`

If you only want the ML model without the RAG index:

```bash
python train_model.py --skip-rag
```

### 4) Start the backend server

```bash
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Or use the provided Windows helper:

```powershell
.\start_server.bat
```

### 5) Prepare the Flutter app

From repository root:

```bash
flutter pub get
```

If you need to regenerate Firebase config:

```bash
flutterfire configure
```

### 6) Run the Flutter app

#### Android emulator

```bash
flutter run
```

#### Physical device (APK)

Update `lib/core/config/diagnostic_api_config.dart`:

- set `pcLanIp` to your PC local network IP
- ensure the phone and PC are on the same Wi-Fi network

Then build and install:

```bash
flutter build apk --release
```

## 🧩 How the System Works

### Flutter app

- Launches with Firebase initialization and language controller
- AuthGate resolves current user role and routes to Customer, Mechanic, or Admin screens
- The customer app can request AI diagnostics and view mechanic locations on a map
- The mechanic app supports profile management, verification status, and admin workflows

### AI backend

- `train_model.py` loads `data/ML Car Diagnostic Agent AI Assistant.csv`
- training merges problem and ECU text into a combined feature set
- model pipeline: `TfidfVectorizer` + `RandomForestClassifier`
- RAG index stores `Combined_Info` documents in FAISS
- FastAPI server loads the ML artifact and RAG pipeline at startup
- `/api/diagnose` returns:
  - `predicted_fault`
  - `ai_advice_english`
  - `ai_advice_roman_urdu`

### AI prompt behavior

- Backend prompt uses a custom multi-step repair sequence
- AI is instructed to return exactly two blocks:
  - `[ENGLISH]`
  - `[ROMAN_URDU]`
- Roman Urdu advice is enforced to use Latin letters only

## ✅ Production Notes

- Replace hardcoded API keys before publishing
- Keep `GROQ_API_KEY` private
- Use Firebase rules to secure Firestore collections
- Verify device network access for the backend API
- Ensure `ai_backend` is reachable from device via local LAN IP if using a phone

## 🌱 Future Scope / To-Do

- Add mechanic appointment booking and service scheduling
- Support real-time mechanic availability and live chat
- Add push notifications for customer/ mechanic updates
- Add more comprehensive issue categories and service pricing
- Expand AI diagnostics to support image-based vehicle problem detection
- Implement stronger secret handling with `.env` for Flutter and backend keys

## 📌 Useful Commands

```bash
# Flutter
flutter pub get
flutter run
flutter build apk --release

# Backend
cd ai_backend
pip install -r requirements.txt
python train_model.py
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

If you need help customizing this README further for a portfolio or GitHub release, I can also add a polished `Project Overview` section and visual badges.
