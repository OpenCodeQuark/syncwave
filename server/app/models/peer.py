from datetime import datetime, timezone
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class Peer(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    peer_id: str = Field(alias='peerId')
    device_name: str = Field(alias='deviceName')
    platform: Literal['android', 'ios', 'web', 'unknown']
    role: Literal['host', 'listener']
    joined_at: datetime = Field(
        default_factory=lambda: datetime.now(tz=timezone.utc),
        alias='joinedAt',
    )
