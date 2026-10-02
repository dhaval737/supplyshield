from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "SupplyShield"
    VERSION: str = "1.0.0"
    API_PREFIX: str = "/api/v1"
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-2.5-flash"
    DATABASE_URL: str = "sqlite:///./supplyshield.db"
    MOCK_ERP_BASE_URL: str = "http://localhost:8000/erp"

    class Config:
        env_file = ".env"

settings = Settings()
