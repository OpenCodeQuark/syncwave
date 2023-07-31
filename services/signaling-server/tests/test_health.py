from fastapi.testclient import TestClient

from app.main import app


def test_root_endpoint_returns_server_metadata() -> None:
    with TestClient(app) as client:
        response = client.get('/')

    assert response.status_code == 200
    payload = response.json()
    assert payload['app'] == 'SyncWave Signaling Server'
    assert payload['version'] == '1.0.0'
    assert payload['status'] == 'ok'
    assert payload['mode'] == 'optional-internet-signaling'
    assert payload['websocket'] == '/ws'


def test_health_endpoint_returns_ok() -> None:
    with TestClient(app) as client:
        response = client.get('/health')

    assert response.status_code == 200
    payload = response.json()
    assert payload['status'] == 'ok'
    assert payload['service'] == 'SyncWave Signaling Server'


def test_status_endpoint_returns_runtime_status() -> None:
    with TestClient(app) as client:
        response = client.get('/status')

    assert response.status_code == 200
    payload = response.json()
    assert payload['app'] == 'SyncWave Signaling Server'
    assert payload['version'] == '1.0.0'
    assert payload['status'] == 'ok'
    assert payload['websocketPath'] == '/ws'
    assert payload['supportedProtocolVersion'] == '1'
    assert isinstance(payload['activeRooms'], int)
    assert isinstance(payload['activeConnections'], int)
    assert isinstance(payload['redisConnected'], bool)
