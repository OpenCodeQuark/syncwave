from typing import Optional

from fastapi import APIRouter, HTTPException, Request, status
from pydantic import BaseModel

from ..services.room_service import RoomService

router = APIRouter(prefix='/rooms', tags=['rooms'])


class CreateRoomRequest(BaseModel):
    roomName: str = 'SyncWave WAN Room'
    hostPeerId: str = 'api_host'
    hostDeviceName: str = 'API Host'
    hostPlatform: str = 'android'
    pin: Optional[str] = None
    roomId: Optional[str] = None


class CreateRoomResponse(BaseModel):
    roomId: str
    roomName: str
    pinProtected: bool


@router.get('/{room_id}')
def get_room(room_id: str, request: Request) -> dict:
    room_service: RoomService = request.app.state.room_service
    room = room_service.get_room(room_id)
    if room is None:
        raise HTTPException(status_code=404, detail='Room not found')

    return {
        'room': room.model_dump(by_alias=True, mode='json'),
    }


@router.post('', response_model=CreateRoomResponse, status_code=status.HTTP_201_CREATED)
def create_room(payload: CreateRoomRequest, request: Request) -> CreateRoomResponse:
    room_service: RoomService = request.app.state.room_service
    try:
        room = room_service.create_room(
            room_name=payload.roomName,
            host_peer_id=payload.hostPeerId,
            host_device_name=payload.hostDeviceName,
            host_platform=payload.hostPlatform,
            pin=payload.pin,
            room_id=payload.roomId,
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=409, detail=str(exc)) from exc

    return CreateRoomResponse(
        roomId=room.room_id,
        roomName=room.room_name,
        pinProtected=room.pin_protected,
    )
