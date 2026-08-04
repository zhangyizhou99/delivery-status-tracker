from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel

from app.models import Shipment, ShipmentStatus
from app.status_rules import allowed_next_statuses


class ShipmentResponse(BaseModel):
    reference: str
    customer_name: str
    status: ShipmentStatus
    allowed_next_statuses: list[ShipmentStatus]
    updated_at: datetime


class ShipmentListResponse(BaseModel):
    items: list[ShipmentResponse]
    total: int


class ShipmentResetResponse(ShipmentListResponse):
    reset_count: int


class ShipmentSort(StrEnum):
    REFERENCE = "reference"
    LAST_UPDATED = "last_updated"


class ShipmentStatusUpdate(BaseModel):
    status: ShipmentStatus


def shipment_response(shipment: Shipment) -> ShipmentResponse:
    return ShipmentResponse(
        reference=shipment.reference,
        customer_name=shipment.customer_name,
        status=shipment.status,
        allowed_next_statuses=list(allowed_next_statuses(shipment.status)),
        updated_at=shipment.updated_at,
    )
