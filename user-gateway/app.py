from pathlib import Path

import httpx
from fastapi import FastAPI, Request, Response
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

ROOT_DIR = Path(__file__).parent
STATIC_DIR = ROOT_DIR / "static"
API_SERVICE = "http://api:8000"

app = FastAPI(title="Toolmarket User Gateway")
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.on_event("startup")
async def startup_event():
    app.state.client = httpx.AsyncClient(base_url=API_SERVICE, follow_redirects=True)


@app.on_event("shutdown")
async def shutdown_event():
    await app.state.client.aclose()


@app.get("/", response_class=FileResponse)
async def root():
    return STATIC_DIR / "index.html"


@app.api_route("/api/v1/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"])
async def proxy_api(path: str, request: Request):
    client: httpx.AsyncClient = request.app.state.client
    content = await request.body()
    headers = {
        key: value
        for key, value in request.headers.items()
        if key.lower() not in {"host", "content-length", "accept-encoding", "connection"}
    }
    response = await client.request(
        request.method,
        f"/api/v1/{path}",
        headers=headers,
        content=content,
        params=request.query_params,
    )

    excluded_headers = {
        "content-length",
        "transfer-encoding",
        "connection",
        "keep-alive",
        "proxy-authenticate",
        "proxy-authorization",
        "te",
        "trailers",
        "upgrade",
    }
    response_headers = {
        key: value for key, value in response.headers.items() if key.lower() not in excluded_headers
    }
    return Response(content=response.content, status_code=response.status_code, headers=response_headers, media_type=response.headers.get("content-type"))


@app.get("/{full_path:path}", response_class=FileResponse)
async def spa(full_path: str):
    return STATIC_DIR / "index.html"
