from fastapi import APIRouter, Depends
from fastapi.responses import RedirectResponse

from ..core.config import Settings, get_settings

router = APIRouter(tags=['root'])


@router.get('/')
def root(settings: Settings = Depends(get_settings)) -> RedirectResponse:
    redirect_url = (
        settings.github_redirect.strip() or 'https://github.com/rjrajujha/syncwave'
    )
    if not redirect_url.startswith(('http://', 'https://')):
        redirect_url = f'https://{redirect_url}'
    return RedirectResponse(
        url=redirect_url,
        status_code=307,
    )
