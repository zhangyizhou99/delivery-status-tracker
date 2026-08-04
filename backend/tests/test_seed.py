from io import StringIO

import pytest

from app.models import ShipmentStatus
from app.seed import CsvValidationError, parse_shipments_csv


def test_parse_shipments_csv_accepts_valid_rows() -> None:
    csv_file = StringIO(
        "reference,customer_name,status\n"
        "TEST-001,Example Retail,created\n"
        "TEST-002,Example Freight,in_transit\n"
    )

    records = parse_shipments_csv(csv_file)

    assert [(record.reference, record.customer_name, record.status) for record in records] == [
        ("TEST-001", "Example Retail", ShipmentStatus.CREATED),
        ("TEST-002", "Example Freight", ShipmentStatus.IN_TRANSIT),
    ]


def test_parse_shipments_csv_rejects_wrong_header() -> None:
    csv_file = StringIO("reference,status\nTEST-001,created\n")

    with pytest.raises(CsvValidationError, match="CSV header must be"):
        parse_shipments_csv(csv_file)


def test_parse_shipments_csv_rejects_unknown_status_with_line_number() -> None:
    csv_file = StringIO("reference,customer_name,status\nTEST-001,Example Retail,waiting\n")

    with pytest.raises(CsvValidationError, match=r"Line 2: status must be one of"):
        parse_shipments_csv(csv_file)


def test_parse_shipments_csv_rejects_duplicate_reference() -> None:
    csv_file = StringIO(
        "reference,customer_name,status\n"
        "TEST-001,Example Retail,created\n"
        "TEST-001,Another Retail,picked_up\n"
    )

    with pytest.raises(
        CsvValidationError,
        match=r"Line 3: duplicate reference TEST-001; first seen on line 2",
    ):
        parse_shipments_csv(csv_file)


def test_parse_shipments_csv_rejects_blank_required_value() -> None:
    csv_file = StringIO("reference,customer_name,status\nTEST-001,,created\n")

    with pytest.raises(CsvValidationError, match=r"Line 2: customer_name is required"):
        parse_shipments_csv(csv_file)
