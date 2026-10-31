# Hashowanie i sprawdzanie haseł (WNF.02: hasło zapisane jako hash, nigdy jawnie).
from pwdlib import PasswordHash

# Zalecane ustawienia pwdlib: algorytm Argon2 z losową solą zapisaną w samym hashu
password_hash = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return password_hash.verify(password, hashed)
