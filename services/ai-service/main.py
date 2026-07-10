"""PARRALAX AI Service entrypoint."""

import uvicorn

from app import app

if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8084,
        workers=4,
        log_level="info",
        access_log=True,
    )
