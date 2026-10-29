# Punkt wejścia aplikacji FastAPI.
from fastapi import FastAPI

from src.api import health

app = FastAPI(title="Gdziewypije API")

app.include_router(health.router)
