from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, Field

from .peer import Peer


class Room(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    room_id: str = Field(alias='roomId')
    room_name: str = Field(alias='roomName')
    host_id: str = Field(alias='hostId')
    pin_protected: bool = Field(alias='pinProtected')
    pin_hash: Optional[str] = Field(default=None, alias='pinHash')
    created_at: datetime = Field(alias='createdAt')
    expires_at: datetime = Field(alias='expiresAt')
    status: Literal['active', 'closed', 'expired']
    participants: list[Peer]
