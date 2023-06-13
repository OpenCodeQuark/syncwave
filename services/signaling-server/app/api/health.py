import time
from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ..core.config import Settings, get_settings

router = APIRouter(tags=['system'])


class HealthResponse(BaseModel):
    status: Literal['ok']
    service: str
    environment: str
    timestamp: int


@router.get('/health', response_model=HealthResponse)
def health(settings: Settings = Depends(get_settings)) -> HealthResponse:
    return HealthResponse(
        status='ok',
        service=settings.app_name,
        environment=settings.app_env,
        timestamp=int(time.time() * 1000),
    )
