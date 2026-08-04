from collections.abc import Generator
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, delete, func, select
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session, sessionmaker

from app.database import get_session
from app.main import app
from app.models import Shipment

TEST_DATABASE_URL = "postgresql+psycopg://tracker:tracker@localhost:5432/tracker_test"
database_name = make_url(TEST_DATABASE_URL).database or ""
if not database_name.endswith("_test"):
    raise RuntimeError("Integration tests require a database name ending in _test")

test_engine = create_engine(TEST_DATABASE_URL, pool_pre_ping=True)
TestSessionLocal = sessionmaker(bind=test_engine, expire_on_commit=False)


@pytest.fixture(scope="session", autouse=True)
def migrated_test_database() -> Generator[None, None, None]:
    backend_directory = Path(__file__).resolve().parents[1]
    alembic_config = Config(str(backend_directory / "alembic.ini"))
    alembic_config.set_main_option("sqlalchemy.url", TEST_DATABASE_URL)
    command.upgrade(alembic_config, "head")

    with test_engine.begin() as connection:
        connection.execute(delete(Shipment))

    yield

    with test_engine.begin() as connection:
        connection.execute(delete(Shipment))
        remaining = connection.scalar(select(func.count()).select_from(Shipment))
        if remaining:
            raise AssertionError("Integration tests left shipment data behind")


@pytest.fixture
def database_session() -> Generator[Session, None, None]:
    with TestSessionLocal() as session:
        session.execute(delete(Shipment))
        session.commit()
        yield session
        session.rollback()
        session.execute(delete(Shipment))
        session.commit()


@pytest.fixture
def client(database_session: Session) -> Generator[TestClient, None, None]:
    def override_session() -> Generator[Session, None, None]:
        yield database_session

    app.dependency_overrides[get_session] = override_session
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.pop(get_session, None)
