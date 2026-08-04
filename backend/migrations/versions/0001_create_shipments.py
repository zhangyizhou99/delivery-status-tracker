"""Create shipments table.

Revision ID: 0001_create_shipments
Revises:
Create Date: 2026-08-04
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0001_create_shipments"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "shipments",
        sa.Column("id", sa.BigInteger(), sa.Identity(), nullable=False),
        sa.Column("reference", sa.String(length=32), nullable=False),
        sa.Column("customer_name", sa.String(length=255), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "btrim(customer_name) <> ''",
            name="ck_shipments_customer_name_not_blank",
        ),
        sa.CheckConstraint(
            "btrim(reference) <> ''",
            name="ck_shipments_reference_not_blank",
        ),
        sa.CheckConstraint(
            "status IN ('created', 'picked_up', 'in_transit', 'delivered', 'failed')",
            name="ck_shipments_status",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_shipments"),
        sa.UniqueConstraint("reference", name="uq_shipments_reference"),
    )


def downgrade() -> None:
    op.drop_table("shipments")
