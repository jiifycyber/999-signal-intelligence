import asyncio
import json
import os
from aiohttp import web, WSMsgType
from websockets.asyncio.client import connect

SCANNER_CLIENTS = set()

TWELVE_DATA_API_KEY = os.environ.get("TWELVE_DATA_API_KEY", "").strip()
TWELVE_WS_BASE = "wss://ws.twelvedata.com/v1/quotes/price"

SYMBOLS = "EUR/USD"


async def health(request):
    key_status = "configured" if TWELVE_DATA_API_KEY else "missing"

    return web.json_response({
        "service": "999 Signal Intelligence",
        "status": "online",
        "twelve_data_key": key_status,
        "scanner_clients": len(SCANNER_CLIENTS),
    })


async def broadcast_tick(data):
    if data.get("event") != "price":
        return

    symbol = data.get("symbol")
    price = data.get("price")
    timestamp = data.get("timestamp")

    if not symbol or price is None:
        return

    try:
        clean = json.dumps({
            "symbol": symbol,
            "timestamp": float(timestamp),
            "price": float(price),
        })
    except Exception:
        return

    dead = []

    for client in list(SCANNER_CLIENTS):
        try:
            await client.send_str(clean)
        except Exception:
            dead.append(client)

    for client in dead:
        SCANNER_CLIENTS.discard(client)


async def scanner_handler(request):
    ws = web.WebSocketResponse(heartbeat=20)
    await ws.prepare(request)

    SCANNER_CLIENTS.add(ws)
    print("Scanner connected. Clients:", len(SCANNER_CLIENTS))

    try:
        async for msg in ws:
            if msg.type == WSMsgType.ERROR:
                print("Scanner error:", ws.exception())
    finally:
        SCANNER_CLIENTS.discard(ws)
        print("Scanner disconnected. Clients:", len(SCANNER_CLIENTS))

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
                print("Capture message error:", e)

    finally:
        print("Capture disconnected")

    return ws


async def twelve_data_loop(app):
    if not TWELVE_DATA_API_KEY:
        print("ERROR: TWELVE_DATA_API_KEY is missing", flush=True)
        return

    url = f"{TWELVE_WS_BASE}?apikey={TWELVE_DATA_API_KEY}"

    while True:
        try:
            print("Connecting to Twelve Data...", flush=True)

            async with connect(
                url,
                open_timeout=20,
                ping_interval=None,
                additional_headers={
                    "User-Agent": "999-Signal-Intelligence/1.0"
                },
            ) as ws:

                print("Connected to Twelve Data", flush=True)

                await ws.send(json.dumps({
                    "action": "subscribe",
                    "params": {
                        "symbols": SYMBOLS
                    }
                }))

                print(f"Subscribed to: {SYMBOLS}", flush=True)

                async def heartbeat_loop():
                    while True:
                        await asyncio.sleep(10)
                        try:
                            await ws.send(json.dumps({
                                "action": "heartbeat"
                            }))
                        except Exception:
                            return

                heartbeat_task = asyncio.create_task(heartbeat_loop())

                try:
                    async for raw in ws:
                        try:
                            data = json.loads(raw)

                            if data.get("event") == "subscribe-status":
                                print("Twelve Data status:", data, flush=True)

                            if data.get("event") == "price":
                                print(
                                    "Twelve Data tick:",
                                    data.get("symbol"),
                                    data.get("price"),
                                    flush=True,
                                )

                            await broadcast_tick(data)

                        except Exception as e:
                            print("Twelve Data parse error:", repr(e), flush=True)

                finally:
                    heartbeat_task.cancel()

        except Exception as e:
            print("Twelve Data connection error:", repr(e), flush=True)

        print("Reconnecting to Twelve Data in 5 seconds...", flush=True)
        await asyncio.sleep(5)


async def start_background_tasks(app):
    app["twelve_task"] = asyncio.create_task(
        twelve_data_loop(app)
    )


async def cleanup_background_tasks(app):
    task = app.get("twelve_task")

    if task:
        task.cancel()

        try:
            await task
        except asyncio.CancelledError:
            pass


app = web.Application()

app.router.add_get("/", health)
app.router.add_get("/scanner", scanner_handler)
app.router.add_get("/capture", capture_handler)


async def main():
    port = int(os.environ.get("PORT", "10000"))

    runner = web.AppRunner(app)
    await runner.setup()

    site = web.TCPSite(
        runner,
        host="0.0.0.0",
        port=port,
    )

    await site.start()

    print(
        f"999 Signal Intelligence server listening on port {port}",
        flush=True,
    )
    print(
        "Twelve Data key configured:",
        bool(TWELVE_DATA_API_KEY),
        flush=True,
    )

    twelve_task = asyncio.create_task(
        twelve_data_loop(app)
    )

    try:
        await asyncio.Event().wait()
    finally:
        twelve_task.cancel()

        try:
            await twelve_task
        except asyncio.CancelledError:
            pass

        await runner.cleanup()


if __name__ == "__main__":
    asyncio.run(main())
