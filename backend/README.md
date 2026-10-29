# Backend

Aplikacja FastAPI (Python). Kod w `src/`, testy w `tests/`, konfiguracja połączenia z bazą w `.env` (wzór w `.env.example`).

## Wymagania

- Python 3.11 lub nowszy
- Docker Desktop (baza PostgreSQL + PostGIS z `docker-compose.yml` w katalogu głównym)

## Uruchomienie

1. Baza, w katalogu głównym repozytorium:

   ```
   copy .env.example .env
   docker compose up -d
   ```

2. Backend, w katalogu `backend/`:

   ```
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements-dev.txt
   copy .env.example .env
   uvicorn src.main:app --reload
   ```

3. Sprawdzenie: `http://127.0.0.1:8000/health` zwraca `{"status": "ok"}`, a `http://127.0.0.1:8000/docs` pokazuje Swaggera.

Na Linuksie i macOS: `cp` zamiast `copy` oraz `source .venv/bin/activate`.

## Testy

W katalogu `backend/`, z aktywnym środowiskiem:

```
pytest
```

Test `test_health_returns_ok_when_database_is_available` wymaga działającej bazy.
