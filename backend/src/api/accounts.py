# Ścieżki kont: rejestracja (PU.01) i logowanie.
import psycopg
from fastapi import APIRouter, Depends, HTTPException

from src.db.connection import get_connection
from src.schemas.accounts import LoginRequest, RegisterRequest, TokenResponse
from src.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["accounts"])


def fetch_user(conn: psycopg.Connection, user_id: int) -> dict | None:
    # Konto razem z profilem (relacja 1:1), bez hasha hasła
    return conn.execute(
        """
        SELECT u.id, u.email, u.role, p.display_name
        FROM users u
        JOIN user_profiles p ON p.user_id = u.id
        WHERE u.id = %s AND u.is_active
        """,
        (user_id,),
    ).fetchone()


@router.post("/register", status_code=201, response_model=TokenResponse)
def register(data: RegisterRequest, conn: psycopg.Connection = Depends(get_connection)) -> dict:
    # T1: register_user zapisuje konto i profil w jednej transakcji żądania
    try:
        row = conn.execute(
            "SELECT register_user(%s, %s, %s) AS id",
            (data.email, hash_password(data.password), data.display_name),
        ).fetchone()
    except psycopg.errors.UniqueViolation:
        # PU.01 (3a): e-mail jest już w bazie
        raise HTTPException(status_code=409, detail="Konto z tym adresem e-mail już istnieje")
    # PU.01 (5): po rejestracji użytkownik jest od razu zalogowany
    return {"access_token": create_access_token(row["id"]), "user": fetch_user(conn, row["id"])}


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, conn: psycopg.Connection = Depends(get_connection)) -> dict:
    row = conn.execute(
        "SELECT id, password_hash FROM users WHERE email = %s AND is_active",
        (data.email,),
    ).fetchone()
    # Ten sam komunikat dla złego e-maila i złego hasła, żeby nie zdradzać, które konta istnieją
    if row is None or not verify_password(data.password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Nieprawidłowy e-mail lub hasło")
    return {"access_token": create_access_token(row["id"]), "user": fetch_user(conn, row["id"])}
