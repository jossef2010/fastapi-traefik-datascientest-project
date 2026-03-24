from __future__ import annotations

import threading
import time
from collections import defaultdict
from collections.abc import Callable

from fastapi import FastAPI, Request, Response
from fastapi.responses import PlainTextResponse

_START_TIME = time.time()
_REQUESTS_TOTAL = 0
_REQUESTS_BY_ROUTE: defaultdict[tuple[str, str, int], int] = defaultdict(int)
_LOCK = threading.Lock()


def _escape_label(value: str) -> str:
    return value.replace("\\", r"\\").replace('"', r'\"').replace("\n", r"\n")


def _render_metrics() -> str:
    with _LOCK:
        requests_total = _REQUESTS_TOTAL
        requests_by_route = dict(_REQUESTS_BY_ROUTE)

    lines = [
        "# HELP app_http_requests_total Total HTTP requests handled by the backend.",
        "# TYPE app_http_requests_total counter",
    ]

    for (method, path, status_code), count in sorted(requests_by_route.items()):
        lines.append(
            "app_http_requests_total"
            f'{{method="{_escape_label(method)}",path="{_escape_label(path)}",status="{status_code}"}} {count}'
        )

    lines.extend(
        [
            "# HELP app_http_requests_sum Total HTTP requests handled by the backend.",
            "# TYPE app_http_requests_sum counter",
            f"app_http_requests_sum {requests_total}",
            "# HELP app_uptime_seconds Uptime of the backend process in seconds.",
            "# TYPE app_uptime_seconds gauge",
            f"app_uptime_seconds {time.time() - _START_TIME:.3f}",
            "",
        ]
    )

    return "\n".join(lines)


async def metrics_endpoint() -> PlainTextResponse:
    return PlainTextResponse(
        _render_metrics(), media_type="text/plain; version=0.0.4; charset=utf-8"
    )


def setup_metrics(app: FastAPI) -> None:
    @app.middleware("http")
    async def collect_metrics(request: Request, call_next: Callable[..., Response]) -> Response:
        response = await call_next(request)

        route = request.scope.get("route")
        route_path = getattr(route, "path", request.url.path)

        with _LOCK:
            global _REQUESTS_TOTAL
            _REQUESTS_TOTAL += 1
            _REQUESTS_BY_ROUTE[(request.method, route_path, response.status_code)] += 1

        return response

    app.add_api_route("/metrics", metrics_endpoint, methods=["GET"], include_in_schema=False, tags=["monitoring"])
