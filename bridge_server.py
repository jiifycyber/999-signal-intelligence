import json
import os
from aiohttp import web, WSMsgType

SCANNER_CLIENTS = set()

async def health(request):
    return web.Response(text="999 Signal Intelligence relay online")

async def scanner_handler(request):
    ws = web.WebSocketResponse(heartbeat=20)
    await ws.prepare(request)
    SCANNER_CLIENTS.add(ws)
    print("Scanner connected")

    try:
        async for msg in ws:
            if msg.type == WSMsgType.ERROR:
                print("Scanner error:", ws.exception())
    finally:
        SCANNER_CLIENTS.discard(ws)
        print("Scanner disconnected")

    return ws

async def capture_handler(request):
    ws = web.WebSocketResponse(heartbeat=20)
    await ws.prepare(request)
    print("Capture connected")

    try:
        async for msg in ws:
            if msg.type != WSMsgType.TEXT:
                continue

            try:
                data = json.loads(msg.data)
                clean = json.dumps({
                    "symbol": data.get("symbol"),
                    "timestamp": float(data.get("timestamp")),
                    "price": float(data.get("price")),
                })

                for client in list(SCANNER_CLIENTS):
                    try:
                        await client.send_str(clean)
                    except Exception:
                        SCANNER_CLIENTS.discard(client)

            except Exception as e:
                print("Bad message:", e)
    finally:
        print("Capture disconnected")

    return ws

app = web.Application()
app.router.add_get("/", health)
app.router.add_get("/scanner", scanner_handler)
app.router.add_get("/capture", capture_handler)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "10000"))
    web.run_app(app, host="0.0.0.0", port=port)
