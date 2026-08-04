from app.seed import reset_shipments


def main() -> None:
    result = reset_shipments()
    print(f"reset inserted={result.inserted} total={result.total}")


if __name__ == "__main__":
    main()
