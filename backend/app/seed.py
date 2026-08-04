import csv
from dataclasses import dataclass
from pathlib import Path
from typing import TextIO

from sqlalchemy import func, select, text
from sqlalchemy.dialects.postgresql import insert

from app.database import SessionLocal
from app.models import Shipment, ShipmentStatus

SHIPMENTS_CSV = Path(__file__).resolve().parents[2] / "data" / "shipments.csv"
EXPECTED_HEADERS = ("reference", "customer_name", "status")


class CsvValidationError(ValueError):
    pass


@dataclass(frozen=True)
class ShipmentSeedRecord:
    reference: str
    customer_name: str
    status: ShipmentStatus


@dataclass(frozen=True)
class SeedResult:
    inserted: int
    skipped: int
    total: int


def parse_shipments_csv(csv_file: TextIO) -> list[ShipmentSeedRecord]:
    reader = csv.DictReader(csv_file)
    headers = tuple(reader.fieldnames or ())
    if headers != EXPECTED_HEADERS:
        expected = ",".join(EXPECTED_HEADERS)
        actual = ",".join(headers) if headers else "<missing>"
        raise CsvValidationError(f"CSV header must be {expected}; received {actual}")

    records: list[ShipmentSeedRecord] = []
    reference_lines: dict[str, int] = {}

    try:
        for row in reader:
            line_number = reader.line_num
            if None in row:
                raise CsvValidationError(f"Line {line_number}: too many columns")

            values: dict[str, str] = {}
            for header in EXPECTED_HEADERS:
                value = row.get(header)
                if value is None or not value.strip():
                    raise CsvValidationError(f"Line {line_number}: {header} is required")
                if value != value.strip():
                    raise CsvValidationError(
                        f"Line {line_number}: {header} must not have surrounding whitespace"
                    )
                values[header] = value

            reference = values["reference"]
            customer_name = values["customer_name"]
            status_value = values["status"]

            if len(reference) > 32:
                raise CsvValidationError(f"Line {line_number}: reference exceeds 32 characters")
            if len(customer_name) > 255:
                raise CsvValidationError(
                    f"Line {line_number}: customer_name exceeds 255 characters"
                )

            try:
                shipment_status = ShipmentStatus(status_value)
            except ValueError as error:
                allowed = ", ".join(status.value for status in ShipmentStatus)
                raise CsvValidationError(
                    f"Line {line_number}: status must be one of {allowed}"
                ) from error

            if reference in reference_lines:
                first_line = reference_lines[reference]
                raise CsvValidationError(
                    f"Line {line_number}: duplicate reference {reference}; "
                    f"first seen on line {first_line}"
                )

            reference_lines[reference] = line_number
            records.append(
                ShipmentSeedRecord(
                    reference=reference,
                    customer_name=customer_name,
                    status=shipment_status,
                )
            )
    except csv.Error as error:
        raise CsvValidationError(f"CSV parse error near line {reader.line_num}: {error}") from error

    if not records:
        raise CsvValidationError("CSV must contain at least one shipment")

    return records


def load_seed_records() -> list[ShipmentSeedRecord]:
    with SHIPMENTS_CSV.open("r", encoding="utf-8-sig", newline="") as csv_file:
        return parse_shipments_csv(csv_file)


def _record_values(records: list[ShipmentSeedRecord]) -> list[dict[str, object]]:
    return [
        {
            "reference": record.reference,
            "customer_name": record.customer_name,
            "status": record.status,
        }
        for record in records
    ]


def seed_shipments() -> SeedResult:
    records = load_seed_records()

    with SessionLocal.begin() as session:
        statement = (
            insert(Shipment)
            .values(_record_values(records))
            .on_conflict_do_nothing(constraint="uq_shipments_reference")
            .returning(Shipment.reference)
        )
        inserted_count = len(session.scalars(statement).all())
        total = int(session.scalar(select(func.count()).select_from(Shipment)) or 0)

    return SeedResult(
        inserted=inserted_count,
        skipped=len(records) - inserted_count,
        total=total,
    )


def reset_shipments() -> SeedResult:
    records = load_seed_records()

    with SessionLocal.begin() as session:
        session.execute(text("TRUNCATE TABLE shipments RESTART IDENTITY"))
        session.execute(insert(Shipment).values(_record_values(records)))
        total = int(session.scalar(select(func.count()).select_from(Shipment)) or 0)

    return SeedResult(inserted=len(records), skipped=0, total=total)


if __name__ == "__main__":
    result = seed_shipments()
    print(f"seed inserted={result.inserted} skipped={result.skipped} total={result.total}")
