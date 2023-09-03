from fastapi import APIRouter

from .health import router as health_router
from .rooms import router as rooms_router
from .root import router as root_router
from .status import router as status_router
from .stream import router as stream_router

router = APIRouter()
router.include_router(root_router)
router.include_router(health_router)
router.include_router(status_router)
router.include_router(stream_router)
router.include_router(rooms_router)

