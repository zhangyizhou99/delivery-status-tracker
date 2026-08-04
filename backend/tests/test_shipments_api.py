from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Shipment, ShipmentStatus
from app.seed import ShipmentSeedRecord


def add_shipment(
    database_session: Session,
    *,
    status: ShipmentStatus = ShipmentStatus.CREATED,
) -> Shipment:
    shipment = Shipment(
        reference="TEST-001",
        customer_name="Example Retail",
        status=status,
        updated_at=datetime(2024, 1, 1, tzinfo=UTC),
    )
    database_session.add(shipment)
    database_session.commit()
    return shipment


def test_list_shipments_returns_empty_collection(client: TestClient) -> None:
    response = client.get("/api/shipments")

    assert response.status_code == 200
    assert response.json() == {"items": [], "total": 0}


def test_list_shipments_returns_sorted_items_and_allowed_statuses(
    client: TestClient,
    database_session: Session,
) -> None:
    database_session.add_all(
        [
            Shipment(
                reference="TEST-002",
                customer_name="Example Freight",
                status=ShipmentStatus.DELIVERED,
            ),
            Shipment(
                reference="TEST-001",
                customer_name="Example Retail",
                status=ShipmentStatus.CREATED,
            ),
        ]
    )
    database_session.commit()

    response = client.get("/api/shipments")

    assert response.status_code == 200
    payload = response.json()
    assert payload["total"] == 2
    assert [item["reference"] for item in payload["items"]] == ["TEST-001", "TEST-002"]
    assert payload["items"][0]["allowed_next_statuses"] == ["picked_up", "failed"]
    assert payload["items"][1]["allowed_next_statuses"] == []


def test_list_shipments_can_sort_by_last_updated(
    client: TestClient,
    database_session: Session,
) -> None:
    database_session.add_all(
        [
            Shipment(
                reference="TEST-001",
                customer_name="Older Shipment",
                status=ShipmentStatus.CREATED,
                updated_at=datetime(2024, 1, 1, tzinfo=UTC),
            ),
            Shipment(
                reference="TEST-002",
                customer_name="Latest Shipment",
                status=ShipmentStatus.CREATED,
                updated_at=datetime(2024, 2, 1, tzinfo=UTC),
            ),
        ]
    )
    database_session.commit()

    response = client.get("/api/shipments?sort=last_updated")

    assert response.status_code == 200
    assert [item["reference"] for item in response.json()["items"]] == [
        "TEST-002",
        "TEST-001",
    ]


def test_list_shipments_rejects_unknown_sort(client: TestClient) -> None:
    response = client.get("/api/shipments?sort=customer")

    assert response.status_code == 422


def test_reset_shipment_statuses_restores_fixture_values(
    client: TestClient,
    database_session: Session,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    initial_records = [
        ShipmentSeedRecord(
            reference="TEST-001",
            customer_name="Example Retail",
            status=ShipmentStatus.CREATED,
        ),
        ShipmentSeedRecord(
            reference="TEST-002",
            customer_name="Example Freight",
            status=ShipmentStatus.PICKED_UP,
        ),
    ]
    monkeypatch.setattr(
        "app.routers.shipments.load_seed_records",
        lambda: initial_records,
    )
    database_session.add_all(
        [
            Shipment(
                reference="TEST-001",
                customer_name="Example Retail",
                status=ShipmentStatus.DELIVERED,
            ),
            Shipment(
                reference="TEST-002",
                customer_name="Example Freight",
                status=ShipmentStatus.PICKED_UP,
            ),
        ]
    )
    database_session.commit()

    response = client.post("/api/shipments/reset?sort=reference")

    assert response.status_code == 200
    payload = response.json()
    assert payload["reset_count"] == 1
    assert [item["reference"] for item in payload["items"]] == ["TEST-001", "TEST-002"]
    assert [item["status"] for item in payload["items"]] == ["created", "picked_up"]
    database_session.expire_all()
    persisted_statuses = database_session.execute(
        select(Shipment.reference, Shipment.status).order_by(Shipment.reference)
    ).all()
    assert persisted_statuses == [
        ("TEST-001", ShipmentStatus.CREATED),
        ("TEST-002", ShipmentStatus.PICKED_UP),
    ]

    repeated_response = client.post("/api/shipments/reset?sort=reference")

    assert repeated_response.status_code == 200
    assert repeated_response.json()["reset_count"] == 0


def test_update_shipment_status_persists_valid_transition(
    client: TestClient,
    database_session: Session,
) -> None:
    shipment = add_shipment(database_session)
    previous_updated_at = shipment.updated_at

    response = client.patch(
        "/api/shipments/TEST-001/status",
        json={"status": "picked_up"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "picked_up"
    assert payload["allowed_next_statuses"] == ["in_transit", "failed"]
    returned_updated_at = datetime.fromisoformat(payload["updated_at"].replace("Z", "+00:00"))
    assert returned_updated_at > previous_updated_at
    database_session.expire_all()
    persisted = database_session.scalar(select(Shipment).where(Shipment.reference == "TEST-001"))
    assert persisted is not None
    assert persisted.status == ShipmentStatus.PICKED_UP


def test_update_shipment_status_is_idempotent_for_same_status(
    client: TestClient,
    database_session: Session,
) -> None:
    shipment = add_shipment(database_session)
    previous_updated_at = shipment.updated_at

    response = client.patch(
        "/api/shipments/TEST-001/status",
        json={"status": "created"},
    )

    assert response.status_code == 200
    returned_updated_at = datetime.fromisoformat(
        response.json()["updated_at"].replace("Z", "+00:00")
    )
    assert returned_updated_at == previous_updated_at


def test_update_shipment_status_rejects_invalid_transition(
    client: TestClient,
    database_session: Session,
) -> None:
    add_shipment(database_session)

    response = client.patch(
        "/api/shipments/TEST-001/status",
        json={"status": "delivered"},
    )

    assert response.status_code == 409
    assert response.json() == {
        "detail": {
            "code": "invalid_status_transition",
            "message": "Cannot transition TEST-001 from created to delivered.",
            "current_status": "created",
            "requested_status": "delivered",
            "allowed_statuses": ["picked_up", "failed"],
        }
    }
    database_session.expire_all()
    persisted_status = database_session.scalar(
        select(Shipment.status).where(Shipment.reference == "TEST-001")
    )
    assert persisted_status == ShipmentStatus.CREATED


@pytest.mark.parametrize("body", [{"status": "lost"}, {}])
def test_update_shipment_status_rejects_invalid_body(
    client: TestClient,
    database_session: Session,
    body: dict[str, str],
) -> None:
    add_shipment(database_session)

    response = client.patch("/api/shipments/TEST-001/status", json=body)

    assert response.status_code == 422


def test_update_shipment_status_returns_not_found(client: TestClient) -> None:
    response = client.patch(
        "/api/shipments/TEST-404/status",
        json={"status": "picked_up"},
    )

    assert response.status_code == 404
    assert response.json()["detail"] == {
        "code": "shipment_not_found",
        "message": "Shipment TEST-404 was not found.",
        "reference": "TEST-404",
    }
