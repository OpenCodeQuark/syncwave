from __future__ import annotations

import os
import re
from contextlib import contextmanager
from typing import Iterator, Optional

from fastapi.testclient import TestClient

from app.core.config import get_settings
from app.main import create_app


@contextmanager
def make_client(env: Optional[dict[str, str]] = None) -> Iterator[TestClient]:
    original: dict[str, str | None] = {}
    if env:
        for key, value in env.items():
            original[key] = os.environ.get(key)
            os.environ[key] = value

    get_settings.cache_clear()
    app = create_app()

    try:
        with TestClient(app) as client:
            yield client
    finally:
        get_settings.cache_clear()
        for key, previous in original.items():
            if previous is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = previous


def send_hello(websocket, *, protocol_version: str = '1', pin: Optional[str] = None) -> dict:
    payload = {
        'appName': 'SyncWave App',
        'appVersion': '1.0.0',
        'protocolVersion': protocol_version,
        'clientPlatform': 'android',
    }
    if pin is not None:
        payload['serverConnectionPin'] = pin

    websocket.send_json(
        {
            'type': 'server.hello',
            'requestId': 'hello-1',
            'payload': payload,
        }
    )
    return websocket.receive_json()


def create_room(websocket, *, request_id: str = 'create-1') -> str:
    websocket.send_json(
        {
            'type': 'room.create',
            'requestId': request_id,
            'payload': {
                'roomName': 'Test Room',
                'deviceName': 'Host Device',
                'platform': 'android',
            },
        }
    )
    response = websocket.receive_json()
    assert response['type'] == 'room.created'
    assert re.match(r'^WAN-[A-Z0-9]{5}$', response['roomId'])
    return response['roomId']


def test_websocket_connect_and_server_hello_success() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=peer_test') as websocket:
            ready = websocket.receive_json()
            assert ready['type'] == 'connection.ready'
            hello_response = send_hello(websocket)

    assert hello_response['type'] == 'server.ready'
    assert hello_response['payload']['serverVersion'] == '1.0.0'


def test_server_hello_requires_auth_when_enabled() -> None:
    env = {
        'REQUIRE_SERVER_CONNECTION_PIN': 'true',
        'SERVER_CONNECTION_PIN': '12345678',
    }
    with make_client(env) as client:
        with client.websocket_connect('/ws?peerId=peer_auth') as websocket:
            websocket.receive_json()
            response = send_hello(websocket)

    assert response['type'] == 'server.auth_required'


def test_server_hello_auth_failed_with_wrong_pin() -> None:
    env = {
        'REQUIRE_SERVER_CONNECTION_PIN': 'true',
        'SERVER_CONNECTION_PIN': '12345678',
    }
    with make_client(env) as client:
        with client.websocket_connect('/ws?peerId=peer_auth_fail') as websocket:
            websocket.receive_json()
            response = send_hello(websocket, pin='87654321')

    assert response['type'] == 'server.auth_failed'


def test_server_hello_unsupported_protocol_version() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=peer_version') as websocket:
            websocket.receive_json()
            response = send_hello(websocket, protocol_version='2')

    assert response['type'] == 'server.unsupported_version'


def test_room_create_join_leave_and_sync_success() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=host_a') as host:
            host.receive_json()
            assert send_hello(host)['type'] == 'server.ready'
            room_id = create_room(host)

            with client.websocket_connect('/ws?peerId=listener_a') as listener:
                listener.receive_json()
                assert send_hello(listener)['type'] == 'server.ready'

                listener.send_json(
                    {
                        'type': 'room.join',
                        'requestId': 'join-1',
                        'roomId': room_id,
                        'payload': {
                            'deviceName': 'Listener Device',
                            'platform': 'ios',
                        },
                    }
                )
                joined = listener.receive_json()
                assert joined['type'] == 'room.joined'

                participant_joined = host.receive_json()
                assert participant_joined['type'] == 'participant.joined'

                listener.send_json(
                    {
                        'type': 'sync.ping',
                        'requestId': 'sync-1',
                        'roomId': room_id,
                        'payload': {},
                    }
                )
                sync_response = listener.receive_json()
                assert sync_response['type'] == 'sync.pong'

                listener.send_json(
                    {
                        'type': 'room.leave',
                        'requestId': 'leave-1',
                        'roomId': room_id,
                        'payload': {},
                    }
                )
                left = listener.receive_json()
                assert left['type'] == 'room.left'


def test_invalid_event_returns_typed_error() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=peer_invalid') as websocket:
            websocket.receive_json()
            websocket.send_json({'payload': {'x': 1}})
            response = websocket.receive_json()

    assert response['type'] == 'error'
    assert response['payload']['code'] == 'invalid_event_schema'


def test_room_leave_failure_uses_typed_error_event() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=peer_leave_fail') as websocket:
            websocket.receive_json()
            assert send_hello(websocket)['type'] == 'server.ready'
            websocket.send_json(
                {
                    'type': 'room.leave',
                    'requestId': 'leave-fail-1',
                    'payload': {},
                }
            )
            response = websocket.receive_json()

    assert response['type'] == 'room.leave_failed'


def test_disconnect_cleanup_broadcasts_participant_left_and_room_closed() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=host_disconnect') as host:
            host.receive_json()
            assert send_hello(host)['type'] == 'server.ready'
            room_id = create_room(host)

            with client.websocket_connect('/ws?peerId=listener_disconnect') as listener:
                listener.receive_json()
                assert send_hello(listener)['type'] == 'server.ready'

                listener.send_json(
                    {
                        'type': 'room.join',
                        'requestId': 'join-disconnect-1',
                        'roomId': room_id,
                        'payload': {
                            'deviceName': 'Listener',
                            'platform': 'android',
                        },
                    }
                )
                joined = listener.receive_json()
                assert joined['type'] == 'room.joined'

                host.receive_json()  # participant.joined

                host.close()

                event_one = listener.receive_json()
                event_two = listener.receive_json()
                event_three = listener.receive_json()
                event_types = {event_one['type'], event_two['type'], event_three['type']}

    assert 'participant.left' in event_types
    assert 'stream.listener_count' in event_types
    assert 'room.closed' in event_types


def test_stream_ping_returns_server_time() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=peer_stream_ping') as websocket:
            websocket.receive_json()
            assert send_hello(websocket)['type'] == 'server.ready'
            websocket.send_json(
                {
                    'type': 'stream.ping',
                    'requestId': 'stream-ping-1',
                    'payload': {'clientTime': 12345},
                }
            )
            response = websocket.receive_json()

    assert response['type'] == 'stream.pong'
    assert 'serverTime' in response['payload']
    assert response['payload']['clientTime'] == 12345


def test_stream_audio_chunk_routes_to_room_listeners() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=host_stream') as host:
            host.receive_json()
            assert send_hello(host)['type'] == 'server.ready'
            room_id = create_room(host)

            with client.websocket_connect('/ws?peerId=listener_stream') as listener:
                listener.receive_json()
                assert send_hello(listener)['type'] == 'server.ready'

                listener.send_json(
                    {
                        'type': 'room.join',
                        'requestId': 'join-stream-1',
                        'roomId': room_id,
                        'payload': {'deviceName': 'Listener', 'platform': 'ios'},
                    }
                )
                joined = listener.receive_json()
                assert joined['type'] == 'room.joined'

                host.receive_json()  # participant.joined
                host.receive_json()  # stream.listener_count

                host.send_json(
                    {
                        'type': 'stream.audio_chunk',
                        'requestId': 'audio-1',
                        'roomId': room_id,
                        'payload': {
                            'sequence': 1,
                            'sampleRate': 48000,
                            'channelCount': 1,
                            'durationMs': 40,
                            'format': 'pcm16',
                            'payload': 'AAAB',
                        },
                    }
                )
                accepted = host.receive_json()
                routed = listener.receive_json()

    assert accepted['type'] == 'stream.audio_accepted'
    assert routed['type'] == 'stream.audio_chunk'
    assert routed['payload']['sequence'] == 1


def test_listener_count_updates_on_join_and_leave() -> None:
    with make_client() as client:
        with client.websocket_connect('/ws?peerId=host_count') as host:
            host.receive_json()
            assert send_hello(host)['type'] == 'server.ready'
            room_id = create_room(host)

            with client.websocket_connect('/ws?peerId=listener_count') as listener:
                listener.receive_json()
                assert send_hello(listener)['type'] == 'server.ready'
                listener.send_json(
                    {
                        'type': 'room.join',
                        'requestId': 'join-count-1',
                        'roomId': room_id,
                        'payload': {'deviceName': 'Listener', 'platform': 'android'},
                    }
                )
                listener.receive_json()  # room.joined
                host.receive_json()  # participant.joined
                join_count = host.receive_json()

                listener.send_json(
                    {
                        'type': 'room.leave',
                        'requestId': 'leave-count-1',
                        'roomId': room_id,
                        'payload': {},
                    }
                )
                listener.receive_json()  # room.left
                leave_event = host.receive_json()
                leave_count = host.receive_json()

    assert join_count['type'] == 'stream.listener_count'
    assert join_count['payload']['count'] >= 2
    assert leave_event['type'] == 'participant.left'
    assert leave_count['type'] == 'stream.listener_count'
