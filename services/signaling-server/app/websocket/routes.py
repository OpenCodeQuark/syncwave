from __future__ import annotations

import logging
import uuid

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from .handlers import WebSocketEventHandler

logger = logging.getLogger(__name__)


def build_websocket_router(handler: WebSocketEventHandler) -> APIRouter:
    router = APIRouter()

    @router.websocket('/ws')
    async def websocket_endpoint(websocket: WebSocket) -> None:
        peer_id = websocket.query_params.get('peerId') or f'peer_{uuid.uuid4().hex[:8]}'
        await handler.connect(peer_id=peer_id, websocket=websocket)
        await handler.send_connection_ready(peer_id=peer_id)

        try:
            while True:
                payload = await websocket.receive_json()
                if isinstance(payload, dict):
                    await handler.handle_message(peer_id=peer_id, raw_message=payload)
        except WebSocketDisconnect:
            room_id = await handler.disconnect(peer_id=peer_id)
            logger.info('Peer disconnected: %s room=%s', peer_id, room_id)

    return router
