from fastapi.testclient import TestClient

from app.core.config import get_settings
from app.main import app, create_app


def test_root_redirects_to_project_repository() -> None:
    with TestClient(app) as client:
        response = client.get('/', follow_redirects=False)

    assert response.status_code in {302, 307}
    assert response.headers['location'] == 'https://github.com/OpenCodeQuark/syncwave'


def test_root_redirect_uses_env_override(monkeypatch) -> None:
    monkeypatch.setenv('GITHUB_REDIRECT', 'https://example.com/custom')
    get_settings.cache_clear()
    test_app = create_app()

    with TestClient(test_app) as client:
        response = client.get('/', follow_redirects=False)

    assert response.status_code in {302, 307}
    assert response.headers['location'] == 'https://example.com/custom'
    get_settings.cache_clear()


def test_health_endpoint_returns_json() -> None:
    with TestClient(app) as client:
        response = client.get('/health')

    assert response.status_code == 200
    payload = response.json()
    assert payload['status'] == 'ok'
    assert payload['service'] == 'SyncWave Signaling Server'
    assert 'timestamp' in payload


def test_status_endpoint_returns_json() -> None:
    with TestClient(app) as client:
        response = client.get('/status')

    assert response.status_code == 200
    payload = response.json()
    assert payload['app'] == 'SyncWave Signaling Server'
    assert payload['version'] == '1.1.4'
    assert payload['status'] == 'ok'
    assert payload['websocketPath'] == '/ws'
    assert isinstance(payload['activeRooms'], int)
    assert isinstance(payload['activeConnections'], int)


def test_global_error_handler_returns_structured_json() -> None:
    with TestClient(app) as client:
        response = client.get('/rooms/UNKNOWN-ROOM')

    assert response.status_code == 404
    payload = response.json()
    assert 'error' in payload
    assert payload['error']['code'] == 'http_404'
    assert 'message' in payload['error']


def test_stream_join_route_serves_html() -> None:
    with TestClient(app) as client:
        response = client.get('/stream/join?room=WAN-RM01P')

    assert response.status_code == 200
    assert 'text/html' in response.headers['content-type']
    assert 'SyncWave' in response.text
    assert 'WAN-RM01P' in response.text
    assert "appVersion: '1.1.4'" in response.text
    assert 'serverPinInput' not in response.text
    assert "clientRole: 'listener'" in response.text
    assert 'let targetBufferMs = 420' in response.text
    assert 'function failConnection' in response.text
    assert 'unlockConnectSoon' in response.text
    assert 'function enqueueSilence' in response.text


def test_favicon_route_serves_icon() -> None:
    with TestClient(app) as client:
        response = client.get('/favicon.ico')

    assert response.status_code == 200
    assert response.headers['content-type'].startswith('image/x-icon')
