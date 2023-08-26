from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.health import router as health_router
from .api.rooms import router as rooms_router
from .core.config import get_settings
from .core.logging import configure_logging
from .services.redis_service import RedisService
from .services.room_service import RoomService
from .services.signaling_service import SignalingService
from .services.sync_service import SyncService
from .websocket.connection_manager import ConnectionManager
from .websocket.handlers import WebSocketEventHandler
from .websocket.routes import build_websocket_router

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)

    redis_service = RedisService(redis_url=settings.redis_url)
    room_service = RoomService(
        ttl_seconds=settings.room_ttl_seconds,
        max_participants=settings.max_participants_per_room,
        pin_hash_secret=settings.pin_hash_secret,
    )
    sync_service = SyncService()
    signaling_service = SignalingService(room_service=room_service, sync_service=sync_service)
    connection_manager = ConnectionManager()
    websocket_handler = WebSocketEventHandler(
        manager=connection_manager,
        signaling=signaling_service,
        settings=settings,
    )

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        try:
            await redis_service.connect()
            if redis_service.is_connected:
                logger.info('Redis connected')
            else:
                logger.info('Redis disabled, using in-memory room state')
        except Exception:  # noqa: BLE001
            logger.warning('Redis unavailable, continuing with in-memory room state')

        yield

        await redis_service.close()

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        lifespan=lifespan,
    )

    origins = [origin.strip() for origin in settings.allowed_origins.split(',') if origin.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins or ['*'],
        allow_credentials=True,
        allow_methods=['*'],
        allow_headers=['*'],
    )

    app.state.room_service = room_service
    app.state.redis_service = redis_service
    app.state.connection_manager = connection_manager
    app.include_router(health_router)
    app.include_router(rooms_router)
    app.include_router(
        build_websocket_router(
            websocket_handler,
            websocket_path=settings.websocket_path,
        )
    )

    return app


app = create_app()
