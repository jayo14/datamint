"""Application configuration via Pydantic Settings."""

from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # General
    PROJECT_NAME: str = "DataMint API"
    ENVIRONMENT: str = "development"
    DEBUG: bool = False
    API_V1_STR: str = "/api/v1"

    # Database
    DATABASE_URL: str = Field(
        default="postgresql+asyncpg://datamint:datamint_password@localhost:5432/datamint_db",
        description="Async PostgreSQL connection string",
    )
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Security & JWT
    JWT_SECRET_KEY: str = Field(
        default="dev-secret-key-change-in-production-datamint-celo-ai",
        description="Cryptographic secret for signing JWTs",
    )
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    NONCE_EXPIRE_SECONDS: int = 300

    # Blockchain (Celo)
    CELO_RPC_URL: str = "https://forno.celo.org"
    CELO_CHAIN_ID: int = 42220
    ESCROW_CONTRACT_ADDRESS: str = "0x0000000000000000000000000000000000000000"
    PLATFORM_SIGNER_PRIVATE_KEY: str = (
        "0x0000000000000000000000000000000000000000000000000000000000000001"
    )

    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "https://datamint.ai",
        "https://www.datamint.ai",
    ]


settings = Settings()
