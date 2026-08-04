import os
from dataclasses import dataclass


def _parse_origins(value: str) -> tuple[str, ...]:
    origins = tuple(origin.strip() for origin in value.split(",") if origin.strip())
    if not origins:
        raise ValueError("CORS_ORIGINS must contain at least one origin")
    return origins


@dataclass(frozen=True)
class Settings:
    database_url: str
    cors_origins: tuple[str, ...]

    @classmethod
    def from_environment(cls) -> "Settings":
        web_port = os.getenv("WEB_PORT", "5173")
        return cls(
            database_url=os.getenv(
                "DATABASE_URL",
                "postgresql+psycopg://tracker:tracker@localhost:5432/tracker",
            ),
            cors_origins=_parse_origins(
                os.getenv(
                    "CORS_ORIGINS",
                    f"http://localhost:{web_port},http://127.0.0.1:{web_port}",
                )
            ),
        )


settings = Settings.from_environment()
