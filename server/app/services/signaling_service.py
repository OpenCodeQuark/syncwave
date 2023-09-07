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
        if event.type == 'stream.host_start':
            return self._handle_stream_host_start(event)
        if event.type == 'stream.host_stop':
            return self._handle_stream_host_stop(event)
        if event.type == 'stream.listener_join':
            return self._handle_stream_listener_join(event)
        if event.type == 'stream.audio_chunk':
            return self._handle_stream_audio_chunk(event)
        if event.type == 'stream.ping':
            return self._handle_stream_ping(event)

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
            room_id=payload.get('roomId')
            if isinstance(payload.get('roomId'), str)
            else None,
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
            ),
            EventEnvelope(
                type='stream.listener_count',
                roomId=room.room_id,
                payload={'count': len(room.participants)},
            ),
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
            ),
            EventEnvelope(
                type='stream.listener_count',
                roomId=event.room_id,
                payload={'count': len(room.participants) if room is not None else 0},
            ),
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

    def _handle_stream_host_start(
        self, event: EventEnvelope
    ) -> tuple[EventEnvelope, list[EventEnvelope]]:
        if event.room_id is None:
            raise RoomError('roomId is required for stream.host_start')

        room = self._room_service.get_room(event.room_id)
        if room is None or room.status != 'active':
            raise RoomError('Room is not active for stream.host_start')

        return (
            EventEnvelope(
                type='stream.ready',
                requestId=event.request_id,
                roomId=event.room_id,
                peerId=event.peer_id,
                payload={
                    'roomId': event.room_id,
                    'serverTimestamp': self._sync_service.server_timestamp_ms(),
                    'streamStartedAt': event.payload.get('streamStartedAt'),
                    'targetBufferMs': event.payload.get('targetBufferMs', 260),
                },
            ),
            [
                EventEnvelope(
                    type='stream.meta',
                    roomId=event.room_id,
                    peerId=event.peer_id,
                    payload={
                        'roomId': event.room_id,
                        'streamStartedAt': event.payload.get('streamStartedAt'),
                        'targetBufferMs': event.payload.get('targetBufferMs', 260),
                        'serverTime': self._sync_service.server_timestamp_ms(),
                    },
                )
            ],
        )

    def _handle_stream_host_stop(
        self, event: EventEnvelope
    ) -> tuple[EventEnvelope, list[EventEnvelope]]:
        if event.room_id is None:
            raise RoomError('roomId is required for stream.host_stop')

        return (
            EventEnvelope(
                type='stream.host_stopped',
                requestId=event.request_id,
                roomId=event.room_id,
                peerId=event.peer_id,
                payload={'roomId': event.room_id},
            ),
            [
                EventEnvelope(
                    type='stream.host_stopped',
                    roomId=event.room_id,
                    peerId=event.peer_id,
                    payload={'roomId': event.room_id},
                )
            ],
        )

    def _handle_stream_listener_join(
        self, event: EventEnvelope
    ) -> tuple[EventEnvelope, list[EventEnvelope]]:
        if event.room_id is None:
            raise RoomError('roomId is required for stream.listener_join')

        return (
            EventEnvelope(
                type='stream.listener_joined',
                requestId=event.request_id,
                roomId=event.room_id,
                peerId=event.peer_id,
                payload={'roomId': event.room_id},
            ),
            [],
        )

    def _handle_stream_audio_chunk(
        self, event: EventEnvelope
    ) -> tuple[EventEnvelope, list[EventEnvelope]]:
        if event.room_id is None:
            raise RoomError('roomId is required for stream.audio_chunk')

        room = self._room_service.get_room(event.room_id)
        if room is None or room.status != 'active':
            raise RoomError('Room is not active for stream.audio_chunk')

        chunk_payload = dict(event.payload)
        chunk_payload['serverTime'] = self._sync_service.server_timestamp_ms()
        if 'roomId' not in chunk_payload:
            chunk_payload['roomId'] = event.room_id

        return (
            EventEnvelope(
                type='stream.audio_accepted',
                requestId=event.request_id,
                roomId=event.room_id,
                peerId=event.peer_id,
                payload={
                    'roomId': event.room_id,
                    'sequence': chunk_payload.get('sequence'),
                },
            ),
            [
                EventEnvelope(
                    type='stream.audio_chunk',
                    roomId=event.room_id,
                    peerId=event.peer_id,
                    payload=chunk_payload,
                )
            ],
        )

    def _handle_stream_ping(
        self, event: EventEnvelope
    ) -> tuple[EventEnvelope, list[EventEnvelope]]:
        return (
            EventEnvelope(
                type='stream.pong',
                requestId=event.request_id,
                roomId=event.room_id,
                peerId=event.peer_id,
                payload={
                    'serverTime': self._sync_service.server_timestamp_ms(),
                    'clientTime': event.payload.get('clientTime'),
                },
            ),
            [],
        )

    def handle_disconnect(self, *, room_id: str, peer_id: str) -> list[EventEnvelope]:
        room = self._room_service.leave_room(room_id=room_id, peer_id=peer_id)
        events = [
            EventEnvelope(
                type='participant.left',
                roomId=room_id,
                peerId=peer_id,
                payload={'peerId': peer_id},
            ),
            EventEnvelope(
                type='stream.listener_count',
                roomId=room_id,
                payload={'count': len(room.participants) if room is not None else 0},
            ),
        ]
        if room is not None and room.status == 'closed':
            events.append(
                EventEnvelope(
                    type='room.closed',
                    roomId=room_id,
                    payload={'reason': 'host_left_or_empty_room'},
                )
            )
        return events
