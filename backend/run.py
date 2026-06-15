import os
import uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=os.environ.get("UVICORN_RELOAD", "false").lower() == "true",
        log_level=os.environ.get("UVICORN_LOG_LEVEL", "info"),
    )
