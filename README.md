# Hog Raiser Management System

AI-Powered Hog Raiser Management System with Smart Health Monitoring and Farm Automation —
a Django capstone project for managing the full hog-raising process, from piglet care to
market readiness (life-cycle tracking, feeding/vitamin plans, AI health triage, medicine
library, growth prediction, inventory/finance, and automated farm alerts).

## Team

- John Mark Gitalan
- Ralph De Leon
- Cristian Guilaran

## Tech Stack

- Backend: Django (see `requirements.txt`)
- Database: SQLite (`db.sqlite3`) for development — initial design in `sql/`
- Frontend: Django templates (Tabler theme in `templates/` + `static/`)

## Quick Start

```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

- Farm Dashboard (public, no login): `http://127.0.0.1:8000/farm/`
- Admin login: `http://127.0.0.1:8000/` → sidebar → Admin Login

## AI Setup (optional)

Set these environment variables to enable live AI (Gemini primary, OpenRouter fallback).
Without keys the system still works in rule-based mode.

```bash
set GEMINI_API_KEY=your-key-here
set OPENROUTER_API_KEY=your-key-here
```

## Database Design

See [sql/initial_design.sql](sql/initial_design.sql) for the SQLite application
table design and relationships. It covers hog profiles, weight and feeding
records, health reports, care schedules, medicines, inventory, expenses,
alerts, AI consultations, reference articles, and the existing info model.
Application tables reference Django's built-in `auth_user` table. Use
`python manage.py migrate` to create or update the database; the SQL file is a
schema reference for a fresh database, not an upgrade script.

---

## System Overview

The Hog Raiser Management System is a full-featured Django application for managing the complete hog-raising lifecycle — from piglet care through to market readiness. It combines life-cycle tracking, growth prediction, smart feeding and care scheduling, AI-powered health triage, a verified medicine library, inventory and finance tracking, batch/FCR analysis, and automated farm alerts.

### Core Capabilities

- **Hog Life-Cycle Tracking** — Register hogs with ear tag (code), breed, sex, birth date, stage, status, weight, and costs.
- **Growth Monitoring & Prediction** — Weight records auto-sync to hog weight; computes Average Daily Gain (ADG), predicts market date, classifies growth status (slow/fair/good/losing), and estimates profit.
- **Smart Feeding & Care** — Age-based feeding guide with kg/day recommendations and stage-specific vitamin plans. Care schedules for feeding, vitamins, vaccines, deworming, checkups, breeding, and farrowing with due-date tracking.
- **AI Health Assistant** — Symptom reporting with AI triage (urgency, possible causes, recommended steps, vet referral). Floating chat widget for medicine, feed, and sell-readiness queries. All AI output includes a veterinary safety disclaimer.
- **AI Automation Engine** — Automatically detects slow growth, missed feedings, due/overdue care, low/expiring stock, urgent health cases, and possible disease outbreaks; creates actionable alerts.
- **Medicine Library** — Verified medicine references with active ingredients, intended use, dosage, precautions, withdrawal days, prescription flags, and stock tracking. Auto-matches medicines to open health reports.
- **Inventory & Finance** — Track feed, vitamins, medicine, and equipment stock with low-stock/expiry flags. Record expenses by category with totals and breakdowns.
- **Batch & FCR Tracking** — Hog batches with weight gain, total feed consumed, and Feed Conversion Ratio (FCR).
- **Medical Treatment Logs** — Record treatments with automatic medicine stock deduction (validates sufficient stock).
- **AI Farm Report** — Generates comprehensive farm summary with statistics and AI-written priorities (Gemini/OpenRouter with rules-based fallback).
- **Public & Authenticated Modes** — Public/customer mode requires no login (anonymous writes attributed to a shared `public-farm` account). Authenticated users get scoped data; superusers access admin functions (user management, medicine library, admin overview).
- **Brute-Force Login Protection** — 5 failed login attempts triggers a 1-minute lockout with countdown timer.
- **Responsive Tabler UI** — Tabler CSS theme with Bootstrap 5, Font Awesome, ApexCharts charts, vector maps, and dark/light theme settings.

---

## Architecture

### Django Apps

All apps live under the `apps/` package:

| App | Purpose |
|-----|---------|
| `apps.core` | Authentication — login, logout, registration with brute-force lockout |
| `apps.users` | Superuser-only Django User administration (CRUD via AJAX) |
| `apps.info` | Simple scoped info/contact records CRUD (legacy/demo app) |
| `apps.farm` | Core farm management system — hogs, health, feeding, care, medicines, inventory, alerts, AI |

### Key Models (`apps.farm/models.py`)

- `Hog` — central entity (code, breed, sex, birth date, stage, status, weight, costs)
- `WeightRecord` — weight tracking that auto-syncs to `Hog.current_weight_kg`
- `FeedingRecord` — per-hog feeding records by feed category and amount
- `CareSchedule` — care tasks (vaccine, deworming, checkup, etc.) with due dates
- `HealthReport` — symptom reports with AI triage fields and urgency
- `Medicine` — verified medicine library with withdrawal days and stock
- `InventoryItem` — stock tracking with low-stock and expiry flags
- `Expense` — expense recording by category
- `Alert` — automated and manual alerts with severity and resolution
- `ReferenceArticle` — knowledge base articles (feeding, health, breeding, management)
- `AIConsultation` — AI chat history per user/hog
- `HogMedicine` — links hogs to administered medicines with withdrawal dates
- `BreedingRecord` — breeding and farrowing records (114-day expected farrowing)
- `HealthTriageLog` — AI symptom triage logs
- `HogBatch` / `BatchFeedingRecord` — batch weight gain and FCR tracking
- `MedicalTreatmentLog` / `FeedInventory` / `BatchFeedDeduction` — treatment and feed deduction with stock validation

### AI Services (`apps/farm/ai_service.py`)

Dual-provider AI with graceful fallback:

1. **Gemini** (primary) — Google Generative AI
2. **OpenRouter** (fallback) — LLM fallback provider
3. **Rule-based** (offline) — deterministic symptom keyword matching and farm summaries

All AI responses append `SAFETY_FOOTER`: *"Not a veterinary diagnosis. Consult a licensed veterinarian."*

### Automation Engine (`apps/farm/automation.py`)

Four-step process: Collect → Detect → Guide → Persist. Idempotent (skips near-duplicate alerts within 3 days). Detects:

- Slow growth / weight loss / market readiness
- Missed feeding records (no feed log in 2 days)
- Care tasks due or overdue (within 3 days)
- Low stock and expiring inventory items (≤30 days)
- Urgent health concerns (open reports in last 7 days)
- Outbreak heuristic (≥3 open health cases in 7 days)

---

## Installation

### Prerequisites

- Python 3.10+
- `pip`

### Setup

```bash
# Clone the repository
git clone <repository-url>
cd BSIT3A-DJANGO-Hog-Raiser-Management-System

# Create a virtual environment
python -m venv venv
venv\Scripts\activate   # Windows
# source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
copy .env.example .env   # Windows
# cp .env.example .env   # macOS/Linux
# Edit .env with your SECRET_KEY and optional AI API keys

# Run migrations
python manage.py migrate

# Create a superuser (for admin features)
python manage.py createsuperuser

# Start the development server
python manage.py runserver
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY` | Yes | Django secret key |
| `DEBUG` | No | `True` for development (default) |
| `GEMINI_API_KEY` | No | Google Gemini API key (enables live AI) |
| `GEMINI_MODEL` | No | Gemini model (default: `gemini-3.7-flash`) |
| `OPENROUTER_API_KEY` | No | OpenRouter API key (AI fallback) |
| `OPENROUTER_MODEL` | No | OpenRouter model (default: `meta-llama/llama-3-8b-instruct`) |
| `OPENROUTER_REFERER` | No | OpenRouter referer header |

Without AI keys, the system runs in rule-based mode and all features remain functional.

---

## Usage

### Access Points

| URL | Description | Auth |
|-----|-------------|------|
| `/` | Login page (root redirect) | Public |
| `/farm/` | Farm dashboard | Public |
| `/farm/hogs/` | Hog management list | Public |
| `/farm/hogs/<id>/` | Hog detail page | Public |
| `/farm/care/` | Care schedule & growth monitor | Public |
| `/farm/health/` | Health monitoring & AI assistant | Public |
| `/farm/medicines/` | Medicine library | Public (admin to add) |
| `/farm/inventory/` | Inventory & expenses | Public |
| `/farm/alerts/` | Alerts list | Public |
| `/farm/report/` | AI farm report | Public |
| `/farm/search/` | Global search | Public |
| `/farm/ai-triage/` | AI health triage | Login required |
| `/farm/feeding/add/` | Batch feeding record | Login required |
| `/farm/treatment/add/` | Medical treatment log | Login required |
| `/farm/admin-overview/` | System-wide admin stats | Superuser |
| `/users/` | User management | Superuser |

### Quick Start

```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

- Farm Dashboard (public, no login): `http://127.0.0.1:8000/farm/`
- Admin login: `http://127.0.0.1:8000/` → sidebar → Admin Login

### AI Setup (Optional)

Set environment variables to enable live AI (Gemini primary, OpenRouter fallback). Without keys the system still works in rule-based mode.

```bash
set GEMINI_API_KEY=your-key-here
set OPENROUTER_API_KEY=your-key-here
```

---

## Project Structure

```
BSIT3A-DJANGO-Hog-Raiser-Management-System/
├── manage.py                 # Django CLI entry point
├── requirements.txt          # Python dependencies
├── pytest.ini                # Pytest configuration
├── bsitcrud.sql              # Raw SQL dump
├── .env.example              # Environment variable template
├── mysite/                   # Project configuration
│   ├── settings.py
│   ├── urls.py               # Root URL configuration
│   └── views.py
├── apps/                     # Django applications
│   ├── core/                 # Authentication
│   ├── users/                # User administration
│   ├── info/                 # Info records CRUD
│   └── farm/                 # Core farm management system
│       ├── models.py         # 16+ models
│       ├── views.py          # All farm views
│       ├── urls.py           # Farm URL patterns
│       ├── ai_service.py     # Dual-provider AI service
│       ├── automation.py     # AI automation engine
│       ├── feeding.py        # Rule-based feeding planner
│       ├── services.py       # Google GenAI client service
│       └── context_processors.py
├── templates/                # Django templates
│   ├── theme/                # Shared UI (base, sidebar, chat widget, etc.)
│   ├── auth/                 # Login, register
│   ├── farm/                 # Farm management templates
│   └── users/, info/         # User and info management
├── static/                   # Static assets (CSS, JS, images, vendor libs)
├── sql/                      # SQL schema reference
└── media/                    # User-uploaded media
```

---

## Testing

```bash
pytest
```

---

## Tech Stack

- **Backend:** Django 5.0.14
- **Database:** SQLite (`db.sqlite3`) for development; `mysqlclient` available for MySQL
- **Frontend:** Django templates (Tabler theme, Bootstrap 5, Font Awesome, ApexCharts)
- **AI:** Google Generative AI (`google-genai`), OpenRouter fallback, rule-based offline mode
- **Excel:** `openpyxl` for export features

---

## Team

- John Mark Gitalan
- Ralph De Leon
- Cristian Guilaran
