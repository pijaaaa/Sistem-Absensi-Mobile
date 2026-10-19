import os
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException

load_dotenv()

TOKEN = os.environ.get("FACE_SERVICE_SECRET", "")

app = FastAPI(title="Face Service", version="0.1")


@app.get("/health")
async def health(x_face_secret: str = Header(default=None, alias="x-face-secret")):
    if x_face_secret != TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return {"status": "ok", "service": "face-service"}
