import time
from typing import Literal

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel

from ..core.config import Settings, get_settings
from ..services.redis_service import RedisService
from ..services.room_service import RoomService
from ..websocket.connection_manager import ConnectionManager

router = APIRouter(tags=['system'])


class RootResponse(BaseModel):
    app: str
    version: str
    status: Literal['ok']
    mode: Literal['optional-internet-signaling']
    websocket: str
    health: str
    statusEndpoint: str


class HealthResponse(BaseModel):
    status: Literal['ok']
    service: str
    environment: str
    timestamp: int


class StatusResponse(BaseModel):
    app: str
    version: str
    environment: str
    status: Literal['ok']
    serverTime: int
    redisConnected: bool
    activeRooms: int
    activeConnections: int
    websocketPath: str
    supportedProtocolVersion: str
    authenticationRequired: bool


@router.get('/', response_model=RootResponse)
def root(settings: Settings = Depends(get_settings)) -> RootResponse:
    return RootResponse(
        app=settings.app_name,
        version=settings.app_version,
        status='ok',
        mode='optional-internet-signaling',
        websocket=settings.websocket_path,
        health='/health',
        statusEndpoint='/status',
    )


@router.get('/health', response_model=HealthResponse)
def health(settings: Settings = Depends(get_settings)) -> HealthResponse:
    return HealthResponse(
        status='ok',
        service=settings.app_name,
        environment=settings.app_env,
        timestamp=int(time.time() * 1000),
    )


@router.get('/status', response_model=StatusResponse)
def status(request: Request, settings: Settings = Depends(get_settings)) -> StatusResponse:
    redis_service: RedisService = request.app.state.redis_service
    room_service: RoomService = request.app.state.room_service
    connection_manager: ConnectionManager = request.app.state.connection_manager

    return StatusResponse(
        app=settings.app_name,
        version=settings.app_version,
        environment=settings.app_env,
        status='ok',
        serverTime=int(time.time() * 1000),
        redisConnected=redis_service.is_connected,
        activeRooms=room_service.active_room_count(),
        activeConnections=connection_manager.active_connection_count(),
        websocketPath=settings.websocket_path,
        supportedProtocolVersion=settings.protocol_version,
        authenticationRequired=settings.require_server_connection_pin,
    )
