from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = 'SyncWave Signaling Server'
    app_version: str = '1.1.0'
    app_env: str = 'development'
    app_host: str = '0.0.0.0'
    app_port: int = 8000
    websocket_path: str = '/ws'
    protocol_version: str = '1'
    require_server_connection_pin: bool = False
    server_connection_pin: str = ''
    redis_url: str = ''
    room_ttl_seconds: int = 21600
    max_participants_per_room: int = 20
    pin_hash_secret: str = 'change-this-in-production'
    allowed_origins: str = '*'
    log_level: str = 'INFO'
    github_redirect: str = 'https://github.com/rjrajujha/syncwave'

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        case_sensitive=False,
    )


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
