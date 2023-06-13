from __future__ import annotations

from typing import Any

from ..models.events import EventEnvelope
from ..models.peer import Peer
from .room_service import RoomError, RoomService
from .sync_service import SyncService


class SignalingService:
    def __init__(self, room_service: RoomService, sync_service: SyncService):
        self._room_service = room_service
        self._sync_service = sync_service

    def handle(self, event: EventEnvelope) -> tuple[EventEnvelope, list[EventEnvelope]]:
        if event.type == 'room.create':
            return self._handle_room_create(event)
        if event.type == 'room.join':
            return self._handle_room_join(event)
        if event.type == 'room.leave':
            return self._handle_room_leave(event)
        if event.type == 'sync.ping':
            return self._handle_sync_ping(event)

        return (
            EventEnvelope(
                type='error',
                requestId=event.request_id,
                roomId=event.room_id,
                payload={'message': f'Unsupported event type: {event.type}'},
            ),
            [],
        )

    def _handle_room_create(
        self, event: EventEnvelope
    ) -> tuple[EventEnvelope, list[EventEnvelope]]:
        payload = event.payload

        room_name = str(payload.get('roomName', 'SyncWave Room')).strip() or 'SyncWave Room'
        host_peer_id = str(event.peer_id or payload.get('hostPeerId') or '').strip()
        if not host_peer_id:
            raise RoomError('host peerId is required')

        host_device_name = str(payload.get('deviceName') or 'Unknown Host').strip()
        host_platform = str(payload.get('platform') or 'unknown').strip().lower()
        pin = payload.get('pin')

        room = self._room_service.create_room(
            room_name=room_name,
            host_peer_id=host_peer_id,
            host_device_name=host_device_name,
            host_platform=host_platform,
            pin=pin if isinstance(pin, str) and pin else None,
        )

        response = EventEnvelope(
            type='room.created',
            requestId=event.request_id,
            roomId=room.room_id,
            peerId=host_peer_id,
            payload={'room': room.model_dump(by_alias=True, mode='json')},
        )
        return response, []

    def _handle_room_join(self, event: EventEnvelope) -> tuple[EventEnvelope, list[EventEnvelope]]:
        if event.room_id is None:
            raise RoomError('roomId is required for room.join')
        if event.peer_id is None:
            raise RoomError('peerId is required for room.join')

        payload = event.payload
        listener = Peer(
            peerId=event.peer_id,
            deviceName=str(payload.get('deviceName') or 'Unknown Listener'),
            platform=(str(payload.get('platform') or 'unknown')).lower(),
            role='listener',
        )

        room = self._room_service.join_room(
            room_id=event.room_id,
            peer=listener,
            pin=payload.get('pin') if isinstance(payload.get('pin'), str) else None,
        )

        joined_response = EventEnvelope(
            type='room.joined',
            requestId=event.request_id,
            roomId=room.room_id,
            peerId=event.peer_id,
            payload={
                'room': room.model_dump(by_alias=True, mode='json'),
            },
        )

        broadcast_events = [
            EventEnvelope(
                type='participant.joined',
                roomId=room.room_id,
                peerId=event.peer_id,
                payload={'participant': listener.model_dump(by_alias=True, mode='json')},
            )
        ]

        return joined_response, broadcast_events

    def _handle_room_leave(self, event: EventEnvelope) -> tuple[EventEnvelope, list[EventEnvelope]]:
        if event.room_id is None or event.peer_id is None:
            raise RoomError('roomId and peerId are required for room.leave')

        room = self._room_service.leave_room(room_id=event.room_id, peer_id=event.peer_id)

        response_payload: dict[str, Any] = {
            'status': 'left',
        }
        if room is not None:
            response_payload['roomStatus'] = room.status

        left_response = EventEnvelope(
            type='room.left',
            requestId=event.request_id,
            roomId=event.room_id,
            peerId=event.peer_id,
            payload=response_payload,
        )

        broadcasts = [
            EventEnvelope(
                type='participant.left',
                roomId=event.room_id,
                peerId=event.peer_id,
                payload={'peerId': event.peer_id},
            )
        ]

        if room is not None and room.status == 'closed':
            broadcasts.append(
                EventEnvelope(
                    type='room.closed',
                    roomId=event.room_id,
                    payload={'reason': 'host_left_or_empty_room'},
                )
            )

        return left_response, broadcasts

    def _handle_sync_ping(self, event: EventEnvelope) -> tuple[EventEnvelope, list[EventEnvelope]]:
        return (
            EventEnvelope(
                type='sync.pong',
                requestId=event.request_id,
                roomId=event.room_id,
                peerId=event.peer_id,
                payload={
                    'serverTimestamp': self._sync_service.server_timestamp_ms(),
                },
            ),
            [],
        )
