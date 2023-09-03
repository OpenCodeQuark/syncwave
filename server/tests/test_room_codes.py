import re

from fastapi.testclient import TestClient

from app.main import create_app


def test_wan_room_code_generation_and_uniqueness() -> None:
    app = create_app()
    with TestClient(app) as client:
        first = client.post('/rooms', json={'roomName': 'WAN One'})
        second = client.post('/rooms', json={'roomName': 'WAN Two'})

    assert first.status_code == 201
    assert second.status_code == 201

    first_code = first.json()['roomId']
    second_code = second.json()['roomId']
    assert re.match(r'^WAN-[A-Z0-9]{5}$', first_code)
    assert re.match(r'^WAN-[A-Z0-9]{5}$', second_code)
    assert first_code != second_code


def test_duplicate_wan_room_code_rejected_when_manually_provided() -> None:
    app = create_app()
    with TestClient(app) as client:
        first = client.post('/rooms', json={'roomName': 'WAN', 'roomId': 'WAN-ABCDE'})
        duplicate = client.post('/rooms', json={'roomName': 'WAN', 'roomId': 'WAN-ABCDE'})

    assert first.status_code == 201
    assert duplicate.status_code == 409


def test_room_code_cleanup_releases_name() -> None:
    app = create_app()
    with TestClient(app) as client:
        created = client.post('/rooms', json={'roomName': 'WAN', 'roomId': 'WAN-ZZ999'})
        assert created.status_code == 201
        room_service = client.app.state.room_service
        room = room_service.get_room('WAN-ZZ999')
        assert room is not None
        room_service.leave_room(room_id='WAN-ZZ999', peer_id=room.host_id)

        recreated = client.post('/rooms', json={'roomName': 'WAN', 'roomId': 'WAN-ZZ999'})

    assert recreated.status_code == 201


def test_invalid_wan_room_code_rejected() -> None:
    app = create_app()
    with TestClient(app) as client:
        response = client.post('/rooms', json={'roomName': 'WAN', 'roomId': 'W-123'})

    assert response.status_code == 409

