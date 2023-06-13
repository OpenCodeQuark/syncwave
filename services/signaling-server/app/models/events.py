import time
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field


class EventEnvelope(BaseModel):
    model_config = ConfigDict(extra='forbid', populate_by_name=True)

    type: str
    request_id: Optional[str] = Field(default=None, alias='requestId')
    room_id: Optional[str] = Field(default=None, alias='roomId')
    peer_id: Optional[str] = Field(default=None, alias='peerId')
    timestamp: int = Field(default_factory=lambda: int(time.time() * 1000))
    payload: dict[str, Any] = Field(default_factory=dict)

    def to_wire(self) -> dict[str, Any]:
        return self.model_dump(by_alias=True)
