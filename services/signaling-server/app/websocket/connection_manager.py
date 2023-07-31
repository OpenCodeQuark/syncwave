from __future__ import annotations

from collections import defaultdict
from typing import DefaultDict, Optional, Set

from fastapi import WebSocket

from ..models.events import EventEnvelope


class ConnectionManager:
    def __init__(self) -> None:
        self._connections: dict[str, WebSocket] = {}
        self._peer_rooms: dict[str, str] = {}
        self._room_peers: DefaultDict[str, set[str]] = defaultdict(set)

    async def connect(self, *, websocket: WebSocket, peer_id: str) -> None:
        await websocket.accept()
        self._connections[peer_id] = websocket

    async def send_to_peer(self, *, peer_id: str, event: EventEnvelope) -> None:
        socket = self._connections.get(peer_id)
        if socket is None:
            return
        await socket.send_json(event.to_wire())

    async def broadcast_to_room(
        self,
        *,
        room_id: str,
        event: EventEnvelope,
        exclude_peer_ids: Optional[Set[str]] = None,
    ) -> None:
        exclusions = exclude_peer_ids or set()
        for peer_id in self._room_peers.get(room_id, set()):
            if peer_id in exclusions:
                continue
            await self.send_to_peer(peer_id=peer_id, event=event)

    def register_peer_room(self, *, peer_id: str, room_id: str) -> None:
        self._peer_rooms[peer_id] = room_id
        self._room_peers[room_id].add(peer_id)

    def unregister_peer_room(self, *, peer_id: str) -> Optional[str]:
        room_id = self._peer_rooms.pop(peer_id, None)
        if room_id is None:
            return None

        peers = self._room_peers.get(room_id)
        if peers is not None:
            peers.discard(peer_id)
            if not peers:
                self._room_peers.pop(room_id, None)

        return room_id

    def disconnect(self, *, peer_id: str) -> Optional[str]:
        self._connections.pop(peer_id, None)
        return self.unregister_peer_room(peer_id=peer_id)

    def active_connection_count(self) -> int:
        return len(self._connections)

    def active_room_count(self) -> int:
        return len(self._room_peers)
