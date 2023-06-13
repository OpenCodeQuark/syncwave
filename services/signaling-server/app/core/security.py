import hashlib
import hmac
import secrets
import string

ROOM_PREFIX = 'SW'
ROOM_CHARS = string.ascii_uppercase + string.digits


def generate_room_id() -> str:
    chunk_1 = ''.join(secrets.choice(ROOM_CHARS) for _ in range(4))
    chunk_2 = ''.join(secrets.choice(ROOM_CHARS) for _ in range(2))
    return f'{ROOM_PREFIX}-{chunk_1}-{chunk_2}'


def hash_pin(pin: str, secret: str) -> str:
    digest = hmac.new(secret.encode('utf-8'), pin.encode('utf-8'), hashlib.sha256)
    return digest.hexdigest()


def verify_pin(pin: str, hashed_pin: str, secret: str) -> bool:
    computed = hash_pin(pin=pin, secret=secret)
    return hmac.compare_digest(computed, hashed_pin)
