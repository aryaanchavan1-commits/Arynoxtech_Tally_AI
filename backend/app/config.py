import os
from pydantic_settings import BaseSettings
from pydantic import ConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "Arynoxtech_Tally"
    OWNER: str = "Aryan Chavan"
    COMPANY: str = "Arynoxtech"
    TAGLINE: str = "AI-Powered Smart Accounting for Small Businesses"
    SECRET_KEY: str = "arynoxtech-tally-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 480
    ENCRYPTION_KEY: str = "arynoxtech-encryption-key-32chars!!"

    model_config = ConfigDict(env_file=".env")


settings = Settings()
