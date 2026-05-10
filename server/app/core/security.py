import hashlib
import hmac
import re
import secrets
import string

WAN_ROOM_PREFIX = 'WAN'
ROOM_CHARS = string.ascii_uppercase + string.digits
WAN_ROOM_PATTERN = rf'^{WAN_ROOM_PREFIX}-[A-Z0-9]{{5}}$'
ROOM_PIN_PATTERN = r'^\d{6}$'
SERVER_CONNECTION_PIN_PATTERN = r'^\d{8}$'


def generate_wan_room_id() -> str:
    suffix = ''.join(secrets.choice(ROOM_CHARS) for _ in range(5))
    return f'{WAN_ROOM_PREFIX}-{suffix}'


def is_valid_wan_room_id(room_id: str) -> bool:
    return bool(re.match(WAN_ROOM_PATTERN, room_id.strip().upper()))


def is_valid_room_pin(pin: str) -> bool:
    return bool(re.match(ROOM_PIN_PATTERN, pin.strip()))


def is_valid_server_connection_pin(pin: str) -> bool:
    return bool(re.match(SERVER_CONNECTION_PIN_PATTERN, pin.strip()))


def hash_pin(pin: str, secret: str) -> str:
    digest = hmac.new(secret.encode('utf-8'), pin.encode('utf-8'), hashlib.sha256)
    return digest.hexdigest()


def verify_pin(pin: str, hashed_pin: str, secret: str) -> bool:
    computed = hash_pin(pin=pin, secret=secret)
    return hmac.compare_digest(computed, hashed_pin)
