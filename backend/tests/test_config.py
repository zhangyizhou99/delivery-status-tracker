from pytest import MonkeyPatch

from app.config import Settings


def test_settings_uses_web_port_for_default_cors_origins(monkeypatch: MonkeyPatch) -> None:
    monkeypatch.delenv("CORS_ORIGINS", raising=False)
    monkeypatch.setenv("WEB_PORT", "5184")

    settings = Settings.from_environment()

    assert settings.cors_origins == (
        "http://localhost:5184",
        "http://127.0.0.1:5184",
    )


def test_settings_preserves_explicit_cors_origins(monkeypatch: MonkeyPatch) -> None:
    monkeypatch.setenv("WEB_PORT", "5184")
    monkeypatch.setenv("CORS_ORIGINS", "https://tracker.example")

    settings = Settings.from_environment()

    assert settings.cors_origins == ("https://tracker.example",)
