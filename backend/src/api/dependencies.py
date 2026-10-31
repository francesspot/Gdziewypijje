# Zależności FastAPI wspólne dla ścieżek: zalogowany użytkownik i administrator.
import psycopg
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from src.db.connection import get_connection
from src.security import decode_access_token

# Odczyt nagłówka "Authorization: Bearer <token>". Brak tokenu obsługuje get_current_user,
# żeby zwrócić komunikat po polsku zamiast domyślnego "Not authenticated".
bearer_scheme = HTTPBearer(auto_error=False)


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


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    conn: psycopg.Connection = Depends(get_connection),
) -> dict:
    # Nagłówek WWW-Authenticate jest wymagany przez standard HTTP przy odpowiedzi 401
    unauthorized_headers = {"WWW-Authenticate": "Bearer"}
    if credentials is None:
        raise HTTPException(status_code=401, detail="Wymagane zalogowanie", headers=unauthorized_headers)

    user_id = decode_access_token(credentials.credentials)
    if user_id is None:
        raise HTTPException(status_code=401, detail="Nieprawidłowy lub wygasły token", headers=unauthorized_headers)

    # Token mógł zostać wydany przed wyłączeniem konta, więc konto jest sprawdzane w bazie przy każdym żądaniu
    user = fetch_user(conn, user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="Konto nie istnieje lub jest wyłączone", headers=unauthorized_headers)
    return user


def require_admin(user: dict = Depends(get_current_user)) -> dict:
    # WNF.06: ścieżki administratora tylko dla roli admin
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Brak uprawnień administratora")
    return user
