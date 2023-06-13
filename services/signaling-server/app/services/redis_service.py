from typing import Optional

from redis.asyncio import Redis


class RedisService:
    def __init__(self, redis_url: str):
        self._redis_url = redis_url
        self._client: Optional[Redis] = None

    async def connect(self) -> None:
        self._client = Redis.from_url(self._redis_url, decode_responses=True)

    async def close(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None
