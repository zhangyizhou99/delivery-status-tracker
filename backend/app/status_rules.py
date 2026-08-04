from app.models import ShipmentStatus

_ALLOWED_NEXT_STATUSES: dict[ShipmentStatus, tuple[ShipmentStatus, ...]] = {
    ShipmentStatus.CREATED: (ShipmentStatus.PICKED_UP, ShipmentStatus.FAILED),
    ShipmentStatus.PICKED_UP: (ShipmentStatus.IN_TRANSIT, ShipmentStatus.FAILED),
    ShipmentStatus.IN_TRANSIT: (ShipmentStatus.DELIVERED, ShipmentStatus.FAILED),
    ShipmentStatus.DELIVERED: (),
    ShipmentStatus.FAILED: (),
}


def allowed_next_statuses(current_status: ShipmentStatus) -> tuple[ShipmentStatus, ...]:
    return _ALLOWED_NEXT_STATUSES[current_status]


def can_set_status(current_status: ShipmentStatus, requested_status: ShipmentStatus) -> bool:
    return requested_status == current_status or requested_status in allowed_next_statuses(
        current_status
    )
