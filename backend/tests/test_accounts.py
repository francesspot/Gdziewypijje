# Testy kont: rejestracja (T1, PU.01), logowanie, /auth/me i role.
# Testy wywołujące ścieżki /auth wymagają działającej bazy (docker compose up -d) i pliku backend/.env,
# testy tokenu i require_admin działają bez bazy.
import uuid
from datetime import datetime, timedelta, timezone

import jwt
import pytest
from fastapi import HTTPException

from src.api.dependencies import require_admin
from src.config import get_settings
from src.db.connection import connect
from src.security import JWT_ALGORITHM, decode_access_token

PASSWORD = "tajnehaslo"


@pytest.fixture
def email():
    # Losowy adres, żeby testy nie zderzały się z danymi testowymi ani ze sobą
    address = f"test-{uuid.uuid4().hex[:12]}@test.pl"
    yield address
    # Sprzątanie po teście: konto testowe jest usuwane razem z profilem
    with connect() as conn:
        conn.execute(
            "DELETE FROM user_profiles WHERE user_id IN (SELECT id FROM users WHERE email = %s)",
            (address,),
        )
        conn.execute("DELETE FROM users WHERE email = %s", (address,))


def register(client, email):
    return client.post(
        "/auth/register",
        json={"email": email, "password": PASSWORD, "display_name": "Tester"},
    )


def test_register_creates_account_with_profile_and_returns_token(client, email):
    response = register(client, email)

    assert response.status_code == 201
    body = response.json()
    assert body["token_type"] == "bearer"
    assert decode_access_token(body["access_token"]) == body["user"]["id"]
    assert body["user"]["email"] == email
    assert body["user"]["role"] == "user"
    assert body["user"]["display_name"] == "Tester"


def test_register_stores_password_as_hash(client, email):
    register(client, email)

    with connect() as conn:
        row = conn.execute("SELECT password_hash FROM users WHERE email = %s", (email,)).fetchone()

    # WNF.02: w bazie jest hash Argon2, a nie jawne hasło
    assert row["password_hash"] != PASSWORD
    assert row["password_hash"].startswith("$argon2")


def test_register_duplicate_email_returns_409(client, email):
    register(client, email)

    # Ten sam adres wielkimi literami też jest duplikatem
    response = register(client, email.upper())

    assert response.status_code == 409
    assert response.json() == {"detail": "Konto z tym adresem e-mail już istnieje"}


def test_register_invalid_data_returns_422(client):
    response = client.post(
        "/auth/register",
        json={"email": "bez-malpy", "password": "krotkie", "display_name": "J"},
    )

    assert response.status_code == 422
    fields = {error["loc"][-1] for error in response.json()["detail"]}
    assert fields == {"email", "password", "display_name"}


def test_login_returns_token(client, email):
    register(client, email)

    response = client.post("/auth/login", json={"email": email, "password": PASSWORD})

    assert response.status_code == 200
    assert response.json()["user"]["email"] == email


def test_login_wrong_password_returns_401(client, email):
    register(client, email)

    response = client.post("/auth/login", json={"email": email, "password": "zlehaslo1"})

    assert response.status_code == 401
    assert response.json() == {"detail": "Nieprawidłowy e-mail lub hasło"}


def test_me_returns_logged_in_user(client, email):
    token = register(client, email).json()["access_token"]

    response = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 200
    assert response.json()["email"] == email


def test_me_without_token_returns_401(client):
    response = client.get("/auth/me")

    assert response.status_code == 401
    assert response.json() == {"detail": "Wymagane zalogowanie"}


def test_expired_token_is_rejected():
    expired = jwt.encode(
        {"sub": "1", "exp": datetime.now(timezone.utc) - timedelta(minutes=1)},
        get_settings().jwt_secret,
        algorithm=JWT_ALGORITHM,
    )

    assert decode_access_token(expired) is None


def test_require_admin_rejects_regular_user_with_403():
    with pytest.raises(HTTPException) as error:
        require_admin({"id": 1, "role": "user"})

    assert error.value.status_code == 403


def test_require_admin_accepts_admin():
    admin = {"id": 1, "role": "admin"}

    assert require_admin(admin) == admin
