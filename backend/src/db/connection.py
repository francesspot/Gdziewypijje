# Otwieranie połączeń z PostgreSQL na podstawie ustawień z .env.
from collections.abc import Iterator

import psycopg
from psycopg.rows import dict_row

from src.config import get_settings


def connect() -> psycopg.Connection:
    settings = get_settings()
    return psycopg.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname=settings.db_name,
        user=settings.db_user,
        password=settings.db_password,
        # Wiersze jako słowniki {kolumna: wartość}, gotowe do zwrócenia w JSON
        row_factory=dict_row,
    )


def get_connection() -> Iterator[psycopg.Connection]:
    """Zależność FastAPI: jedno połączenie na żądanie.

    Blok with zatwierdza transakcję, gdy ścieżka zakończy się bez wyjątku,
    wycofuje ją przy wyjątku (także HTTPException) i zamyka połączenie.
    Dzięki temu zapisy do kilku tabel w jednym żądaniu są jedną transakcją.
    """
    with connect() as conn:
        yield conn
