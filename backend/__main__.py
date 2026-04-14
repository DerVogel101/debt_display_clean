import uvicorn

from backend.config import settings
from backend.main import app


def main() -> None:
    uvicorn.run(app, host=settings.BACKEND_HOST, port=settings.BACKEND_PORT)


if __name__ == "__main__":
    main()
