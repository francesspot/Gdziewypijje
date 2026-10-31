# Modele danych dla rejestracji, logowania i konta użytkownika.
from pydantic import BaseModel, ConfigDict, Field, field_validator

# Uproszczone sprawdzenie e-maila: tekst@domena.końcówka, bez spacji
EMAIL_PATTERN = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"


class RegisterRequest(BaseModel):
    # Spacje na początku i końcu są obcinane przed walidacją
    model_config = ConfigDict(str_strip_whitespace=True)

    email: str = Field(pattern=EMAIL_PATTERN)
    password: str = Field(min_length=8)
    # PU.01 (3b): nazwa krótsza niż 2 znaki jest odrzucana, tak samo jak CHECK w user_profiles
    display_name: str = Field(min_length=2)

    # Małe litery, żeby Jan@x.pl i jan@x.pl były tym samym kontem (UNIQUE w bazie rozróżnia wielkość liter)
    @field_validator("email")
    @classmethod
    def lowercase_email(cls, value: str) -> str:
        return value.lower()


class LoginRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    email: str
    password: str

    @field_validator("email")
    @classmethod
    def lowercase_email(cls, value: str) -> str:
        return value.lower()


class UserResponse(BaseModel):
    id: int
    email: str
    role: str
    display_name: str


class TokenResponse(BaseModel):
    # PU.01 (5): po rejestracji użytkownik jest od razu zalogowany, więc rejestracja też zwraca token
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
