from fastapi import APIRouter, HTTPException, Request

from ..services.room_service import RoomService

router = APIRouter(prefix='/rooms', tags=['rooms'])


@router.get('/{room_id}')
def get_room(room_id: str, request: Request) -> dict:
    room_service: RoomService = request.app.state.room_service
    room = room_service.get_room(room_id)
    if room is None:
        raise HTTPException(status_code=404, detail='Room not found')

    return {
        'room': room.model_dump(by_alias=True, mode='json'),
    }
