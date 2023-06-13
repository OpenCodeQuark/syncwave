from fastapi.testclient import TestClient

from app.main import app


def test_websocket_accepts_connection_and_sends_ready_event() -> None:
    with TestClient(app) as client:
        with client.websocket_connect('/ws?peerId=peer_test') as websocket:
            message = websocket.receive_json()

    assert message['type'] == 'connection.ready'
    assert message['peerId'] == 'peer_test'
