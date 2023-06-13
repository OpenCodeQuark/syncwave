from __future__ import annotations

import logging
import time
from typing import Optional

from fastapi import WebSocket
from pydantic import ValidationError

from ..models.events import EventEnvelope
from ..services.room_service import RoomError
from ..services.signaling_service import SignalingService
from .connection_manager import ConnectionManager

logger = logging.getLogger(__name__)


class WebSocketEventHandler:
    def __init__(self, *, manager: ConnectionManager, signaling: SignalingService):
        self._manager = manager
        self._signaling = signaling

    async def connect(self, *, peer_id: str, websocket: WebSocket) -> None:
        await self._manager.connect(websocket=websocket, peer_id=peer_id)

    async def send_connection_ready(self, *, peer_id: str) -> None:
        await self._manager.send_to_peer(
            peer_id=peer_id,
            event=EventEnvelope(
                type='connection.ready',
                peerId=peer_id,
                payload={'serverTimestamp': int(time.time() * 1000)},
            ),
        )

    async def disconnect(self, *, peer_id: str) -> Optional[str]:
        return self._manager.disconnect(peer_id=peer_id)

    async def handle_message(self, *, peer_id: str, raw_message: dict) -> None:
        try:
            event = EventEnvelope.model_validate(raw_message)
            if not event.peer_id:
                event = event.model_copy(update={'peer_id': peer_id})

            response, broadcasts = self._signaling.handle(event)

            if event.type in {'room.create', 'room.join'} and response.room_id:
                self._manager.register_peer_room(peer_id=peer_id, room_id=response.room_id)

            if event.type == 'room.leave':
                self._manager.unregister_peer_room(peer_id=peer_id)

            await self._manager.send_to_peer(peer_id=peer_id, event=response)

            room_id = response.room_id or event.room_id
            if room_id is None:
                return

            for broadcast in broadcasts:
                await self._manager.broadcast_to_room(
                    room_id=room_id,
                    event=broadcast,
                    exclude_peer_ids={peer_id},
                )

        except ValidationError as exc:
            logger.warning('Invalid websocket payload from %s: %s', peer_id, exc)
            await self._manager.send_to_peer(
                peer_id=peer_id,
                event=EventEnvelope(
                    type='error',
                    peerId=peer_id,
                    payload={'message': 'Invalid event schema'},
                ),
            )
        except RoomError as exc:
            await self._manager.send_to_peer(
                peer_id=peer_id,
                event=EventEnvelope(
                    type='room.join_failed',
                    peerId=peer_id,
                    payload={'message': str(exc)},
                ),
            )
