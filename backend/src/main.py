# Punkt wejścia aplikacji FastAPI.
from fastapi import FastAPI

from src.api import accounts, health

app = FastAPI(title="Gdziewypije API")

app.include_router(health.router)
app.include_router(accounts.router)
