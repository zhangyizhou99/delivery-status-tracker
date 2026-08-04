import pytest

from app.models import ShipmentStatus
from app.status_rules import allowed_next_statuses, can_set_status


@pytest.mark.parametrize(
    ("current_status", "expected"),
    [
        (ShipmentStatus.CREATED, (ShipmentStatus.PICKED_UP, ShipmentStatus.FAILED)),
        (ShipmentStatus.PICKED_UP, (ShipmentStatus.IN_TRANSIT, ShipmentStatus.FAILED)),
        (ShipmentStatus.IN_TRANSIT, (ShipmentStatus.DELIVERED, ShipmentStatus.FAILED)),
        (ShipmentStatus.DELIVERED, ()),
        (ShipmentStatus.FAILED, ()),
    ],
)
def test_allowed_next_statuses(
    current_status: ShipmentStatus,
    expected: tuple[ShipmentStatus, ...],
) -> None:
    assert allowed_next_statuses(current_status) == expected


_ALLOWED_PAIRS = {
    (ShipmentStatus.CREATED, ShipmentStatus.CREATED),
    (ShipmentStatus.CREATED, ShipmentStatus.PICKED_UP),
    (ShipmentStatus.CREATED, ShipmentStatus.FAILED),
    (ShipmentStatus.PICKED_UP, ShipmentStatus.PICKED_UP),
    (ShipmentStatus.PICKED_UP, ShipmentStatus.IN_TRANSIT),
    (ShipmentStatus.PICKED_UP, ShipmentStatus.FAILED),
    (ShipmentStatus.IN_TRANSIT, ShipmentStatus.IN_TRANSIT),
    (ShipmentStatus.IN_TRANSIT, ShipmentStatus.DELIVERED),
    (ShipmentStatus.IN_TRANSIT, ShipmentStatus.FAILED),
    (ShipmentStatus.DELIVERED, ShipmentStatus.DELIVERED),
    (ShipmentStatus.FAILED, ShipmentStatus.FAILED),
}


@pytest.mark.parametrize(
    ("current_status", "requested_status"),
    [
        (current_status, requested_status)
        for current_status in ShipmentStatus
        for requested_status in ShipmentStatus
    ],
)
def test_can_set_status_covers_complete_transition_matrix(
    current_status: ShipmentStatus,
    requested_status: ShipmentStatus,
) -> None:
    assert can_set_status(current_status, requested_status) is (
        (current_status, requested_status) in _ALLOWED_PAIRS
    )
