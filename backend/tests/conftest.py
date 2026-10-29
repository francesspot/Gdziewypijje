# Wspólne fixtury pytest dla testów backendu.
import pytest
from fastapi.testclient import TestClient

from src.main import app


@pytest.fixture
def client() -> TestClient:
    # Klient wywołuje aplikację bez uruchamiania serwera
    return TestClient(app)
