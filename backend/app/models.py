from datetime import datetime
from enum import StrEnum

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    Enum,
    Identity,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class ShipmentStatus(StrEnum):
    CREATED = "created"
    PICKED_UP = "picked_up"
    IN_TRANSIT = "in_transit"
    DELIVERED = "delivered"
    FAILED = "failed"


class Base(DeclarativeBase):
    pass


class Shipment(Base):
    __tablename__ = "shipments"
    __table_args__ = (
        CheckConstraint("btrim(reference) <> ''", name="ck_shipments_reference_not_blank"),
        CheckConstraint(
            "btrim(customer_name) <> ''",
            name="ck_shipments_customer_name_not_blank",
        ),
        CheckConstraint(
            "status IN ('created', 'picked_up', 'in_transit', 'delivered', 'failed')",
            name="ck_shipments_status",
        ),
        UniqueConstraint("reference", name="uq_shipments_reference"),
    )

    id: Mapped[int] = mapped_column(BigInteger, Identity(), primary_key=True)
    reference: Mapped[str] = mapped_column(String(32), nullable=False)
    customer_name: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[ShipmentStatus] = mapped_column(
        Enum(
            ShipmentStatus,
            name="shipment_status",
            native_enum=False,
            create_constraint=False,
            validate_strings=True,
            values_callable=lambda enum_type: [item.value for item in enum_type],
            length=32,
        ),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
