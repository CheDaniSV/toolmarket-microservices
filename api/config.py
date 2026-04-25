import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = str(os.getenv("PROJECT_NAME")) + " API"
    VERSION: str = "1.0.0"
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    ALGORITHM: str = os.getenv("ALGORITHM")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 дней

settings = Settings()