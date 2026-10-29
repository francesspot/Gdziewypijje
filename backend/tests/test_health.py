# Testy ścieżki /health.
import psycopg

from src.api import health


def test_health_returns_ok_when_database_is_available(client):
    # Wymaga działającej bazy (docker compose up -d) i pliku backend/.env
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_health_returns_503_when_database_is_unavailable(client, monkeypatch):
    def failing_connect():
        raise psycopg.OperationalError("connection refused")

    # Podmiana connect w module health symuluje niedostępną bazę
    monkeypatch.setattr(health, "connect", failing_connect)

    response = client.get("/health")

    assert response.status_code == 503
    assert response.json() == {"detail": "Brak połączenia z bazą danych"}
