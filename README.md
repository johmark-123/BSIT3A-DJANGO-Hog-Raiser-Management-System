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

See `sql/initial_design.sql` for the initial database design (generated from the
Django migrations for the `farm` and `info` apps).
