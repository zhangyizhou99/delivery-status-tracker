from typing import Annotated, Literal

from fastapi import Depends, FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.config import settings
from app.database import is_database_ready
from app.routers.shipments import router as shipments_router


class HealthResponse(BaseModel):
    status: Literal["ok", "unavailable"]
    database: Literal["up", "down"]


app = FastAPI(title="Delivery Status Tracker API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins),
    allow_credentials=False,
    allow_methods=["GET", "POST", "PATCH"],
    allow_headers=["Content-Type"],
)
app.include_router(shipments_router)


@app.get(
    "/api/health",
    response_model=HealthResponse,
    responses={
        status.HTTP_503_SERVICE_UNAVAILABLE: {
            "model": HealthResponse,
            "description": "The database is unavailable",
        }
    },
)
def health_check(
    response: Response,
    database_ready: Annotated[bool, Depends(is_database_ready)],
) -> HealthResponse:
    if not database_ready:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return HealthResponse(status="unavailable", database="down")

    return HealthResponse(status="ok", database="up")
