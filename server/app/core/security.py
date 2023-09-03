import hashlib
import hmac
import re
import secrets
import string

WAN_ROOM_PREFIX = 'WAN'
ROOM_CHARS = string.ascii_uppercase + string.digits
WAN_ROOM_PATTERN = rf'^{WAN_ROOM_PREFIX}-[A-Z0-9]{{5}}$'


def generate_wan_room_id() -> str:
    suffix = ''.join(secrets.choice(ROOM_CHARS) for _ in range(5))
    return f'{WAN_ROOM_PREFIX}-{suffix}'


def is_valid_wan_room_id(room_id: str) -> bool:
    return bool(re.match(WAN_ROOM_PATTERN, room_id.strip().upper()))


def hash_pin(pin: str, secret: str) -> str:
    digest = hmac.new(secret.encode('utf-8'), pin.encode('utf-8'), hashlib.sha256)
    return digest.hexdigest()


def verify_pin(pin: str, hashed_pin: str, secret: str) -> bool:
    computed = hash_pin(pin=pin, secret=secret)
    return hmac.compare_digest(computed, hashed_pin)
