from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_session
from app.models import Shipment
from app.schemas import (
    ShipmentListResponse,
    ShipmentResetResponse,
    ShipmentResponse,
    ShipmentSort,
    ShipmentStatusUpdate,
    shipment_response,
)
from app.seed import load_seed_records
from app.status_rules import allowed_next_statuses, can_set_status

router = APIRouter(prefix="/api/shipments", tags=["shipments"])


def ordered_shipments(session: Session, sort_by: ShipmentSort) -> list[Shipment]:
    statement = select(Shipment)
    if sort_by == ShipmentSort.LAST_UPDATED:
        statement = statement.order_by(Shipment.updated_at.desc(), Shipment.reference.asc())
    else:
        statement = statement.order_by(Shipment.reference.asc())
    return list(session.scalars(statement).all())


@router.get("", response_model=ShipmentListResponse)
def list_shipments(
    session: Annotated[Session, Depends(get_session)],
    sort_by: Annotated[ShipmentSort, Query(alias="sort")] = ShipmentSort.REFERENCE,
) -> ShipmentListResponse:
    shipments = ordered_shipments(session, sort_by)
    items = [shipment_response(shipment) for shipment in shipments]
    return ShipmentListResponse(items=items, total=len(items))


@router.post("/reset", response_model=ShipmentResetResponse)
def reset_shipment_statuses(
    session: Annotated[Session, Depends(get_session)],
    sort_by: Annotated[ShipmentSort, Query(alias="sort")] = ShipmentSort.REFERENCE,
) -> ShipmentResetResponse:
    initial_statuses = {record.reference: record.status for record in load_seed_records()}
    shipments = session.scalars(
        select(Shipment).where(Shipment.reference.in_(initial_statuses)).with_for_update()
    ).all()

    reset_count = 0
    for shipment in shipments:
        initial_status = initial_statuses[shipment.reference]
        if shipment.status != initial_status:
            shipment.status = initial_status
            shipment.updated_at = func.now()
            reset_count += 1

    session.commit()
    items = [shipment_response(shipment) for shipment in ordered_shipments(session, sort_by)]
    return ShipmentResetResponse(
        items=items,
        total=len(items),
        reset_count=reset_count,
    )


@router.patch("/{reference}/status", response_model=ShipmentResponse)
def update_shipment_status(
    reference: str,
    request: ShipmentStatusUpdate,
    session: Annotated[Session, Depends(get_session)],
) -> ShipmentResponse:
    shipment = session.scalar(
        select(Shipment).where(Shipment.reference == reference).with_for_update()
    )
    if shipment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "shipment_not_found",
                "message": f"Shipment {reference} was not found.",
                "reference": reference,
            },
        )

    current_status = shipment.status
    if request.status == current_status:
        return shipment_response(shipment)

    if not can_set_status(current_status, request.status):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "invalid_status_transition",
                "message": (
                    f"Cannot transition {reference} from {current_status.value} "
                    f"to {request.status.value}."
                ),
                "current_status": current_status.value,
                "requested_status": request.status.value,
                "allowed_statuses": [
                    next_status.value for next_status in allowed_next_statuses(current_status)
                ],
            },
        )

    shipment.status = request.status
    shipment.updated_at = func.now()
    session.commit()
    session.refresh(shipment)
    return shipment_response(shipment)
