# Hashowanie i sprawdzanie haseł (WNF.02: hasło zapisane jako hash, nigdy jawnie) oraz tokeny logowania.
from datetime import datetime, timedelta, timezone

import jwt
from pwdlib import PasswordHash

from src.config import get_settings

# Zalecane ustawienia pwdlib: algorytm Argon2 z losową solą zapisaną w samym hashu
password_hash = PasswordHash.recommended()

# HS256: token podpisany jednym tajnym kluczem z .env, ten sam klucz służy do sprawdzenia podpisu
JWT_ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return password_hash.verify(password, hashed)


def create_access_token(user_id: int) -> str:
    settings = get_settings()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    # sub: id użytkownika (JWT wymaga tekstu), exp: data wygaśnięcia sprawdzana przy odczycie tokenu
    payload = {"sub": str(user_id), "exp": expires_at}
    return jwt.encode(payload, settings.jwt_secret, algorithm=JWT_ALGORITHM)
