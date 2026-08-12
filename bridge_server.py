import asyncio
import json
import os
import websockets

SCANNER_CLIENTS = set()
CAPTURE_CLIENTS = set()

async def handler(ws):
    path = ws.request.path

    if path == "/scanner":
        SCANNER_CLIENTS.add(ws)
        print("Scanner connected")

        try:
            await ws.wait_closed()
        finally:
            SCANNER_CLIENTS.discard(ws)
            print("Scanner disconnected")

    elif path == "/capture":
        CAPTURE_CLIENTS.add(ws)
        print("Capture connected")

        try:
            async for message in ws:
                try:
                    data = json.loads(message)

                    clean = json.dumps({
                        "symbol": data.get("symbol"),
                        "timestamp": float(data.get("timestamp")),
                        "price": float(data.get("price")),
                    })

                    dead = []

                    for client in list(SCANNER_CLIENTS):
                        try:
                            await client.send(clean)
                        except Exception:
                            dead.append(client)

                    for client in dead:
                        SCANNER_CLIENTS.discard(client)

                except Exception as e:
                    print("Bad message:", e)

        finally:
            CAPTURE_CLIENTS.discard(ws)
            print("Capture disconnected")

    else:
        await ws.close(code=1008, reason="Use /scanner or /capture")


async def main():
    port = int(os.environ.get("PORT", "10000"))

    print(f"999 Signal Intelligence relay running on port {port}")
    print("Scanner endpoint: /scanner")
    print("Capture endpoint: /capture")

    async with websockets.serve(
        handler,
        "0.0.0.0",
        port,
        ping_interval=20,
        ping_timeout=20,
    ):
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
