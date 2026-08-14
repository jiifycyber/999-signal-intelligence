import os
import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="999 Signal Intelligence API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://jiifycyber.github.io",
        "http://localhost:3000",
        "http://localhost:5000",
    ],
    allow_credentials=False,
    allow_methods=["GET"],
    allow_headers=["*"],
)

API_KEY = os.getenv("TWELVE_DATA_API_KEY", "")

@app.get("/")
def root():
    return {"status": "online", "service": "999 Signal Intelligence"}

@app.get("/quote/{symbol}")
async def quote(symbol: str):
    if not API_KEY:
        raise HTTPException(status_code=500, detail="TWELVE_DATA_API_KEY missing")

    pair = symbol.replace("-", "/").upper()

    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.get(
            "https://api.twelvedata.com/price",
            params={"symbol": pair, "apikey": API_KEY},
        )

    data = response.json()

    if "price" not in data:
        raise HTTPException(status_code=502, detail=data)

    return {
        "symbol": pair,
        "price": float(data["price"]),
        "source": "Twelve Data",
    }
