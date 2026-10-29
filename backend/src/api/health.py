# Ścieżka sprawdzająca, czy backend działa i ma połączenie z bazą.
import psycopg
from fastapi import APIRouter, HTTPException

from src.db.connection import connect

router = APIRouter(tags=["health"])


@router.get("/health")
def health() -> dict:
    # Połączenie otwierane ręcznie, a nie przez get_connection, żeby brak bazy dał czytelny błąd zamiast 500
    try:
        with connect() as conn:
            conn.execute("SELECT 1")
    except psycopg.OperationalError:
        raise HTTPException(status_code=503, detail="Brak połączenia z bazą danych")
    return {"status": "ok"}
