from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient

from app.database import is_database_ready
from app.main import app


@pytest.fixture(autouse=True)
def clear_dependency_overrides() -> Generator[None, None, None]:
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


def test_health_reports_ready_database() -> None:
    app.dependency_overrides[is_database_ready] = lambda: True

    with TestClient(app) as client:
        response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "up"}


def test_health_rejects_unavailable_database() -> None:
    app.dependency_overrides[is_database_ready] = lambda: False

    with TestClient(app) as client:
        response = client.get("/api/health")

    assert response.status_code == 503
    assert response.json() == {"status": "unavailable", "database": "down"}


def test_health_allows_local_vite_origin() -> None:
    app.dependency_overrides[is_database_ready] = lambda: True

    with TestClient(app) as client:
        response = client.get(
            "/api/health",
            headers={"Origin": "http://127.0.0.1:5173"},
        )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://127.0.0.1:5173"
