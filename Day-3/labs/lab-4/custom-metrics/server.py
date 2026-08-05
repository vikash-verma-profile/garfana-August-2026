#!/usr/bin/env python3
"""Custom metrics API for Day 3 Lab 4.

Create gauges/counters, insert values, and expose Prometheus /metrics.

  GET  /health
  GET  /metrics
  GET  /api/metrics              - list registered metrics
  POST /api/metrics              - create or update a metric
       JSON: {"name":"lab_orders_open","type":"gauge","value":12,"labels":{"region":"us"}}
  GET  /set?name=&value=&type=gauge&key=val  - curl-friendly insert
  DELETE /api/metrics/<name>     - remove a metric (all label sets)
"""

from __future__ import annotations

import json
import re
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

START = time.time()
LOCK = threading.Lock()

# name -> {"type": "gauge"|"counter", "help": str, "series": {frozenset(labels): float}}
METRICS: dict[str, dict] = {}

NAME_RE = re.compile(r"^[a-zA-Z_:][a-zA-Z0-9_:]*$")
LABEL_RE = re.compile(r"^[a-zA-Z_][a-zA-Z0-9_]*$")


def _seed() -> None:
    """Starter metrics so the lab has data before students push values."""
    _upsert("lab_demo_temperature_celsius", "gauge", 21.5, {"location": "classroom"}, "Demo temperature gauge")
    _upsert("lab_demo_orders_total", "counter", 100, {"region": "lab"}, "Demo order counter")


def _upsert(
    name: str,
    mtype: str,
    value: float,
    labels: dict[str, str] | None,
    help_text: str | None = None,
) -> None:
    if not NAME_RE.match(name):
        raise ValueError(f"invalid metric name: {name}")
    mtype = mtype.lower()
    if mtype not in ("gauge", "counter"):
        raise ValueError("type must be gauge or counter")
    labels = labels or {}
    for k, v in labels.items():
        if not LABEL_RE.match(k):
            raise ValueError(f"invalid label name: {k}")
        if not isinstance(v, str):
            raise ValueError(f"label {k} value must be a string")

    key = frozenset(labels.items())
    with LOCK:
        if name not in METRICS:
            METRICS[name] = {
                "type": mtype,
                "help": help_text or f"Custom lab metric {name}",
                "series": {},
            }
        entry = METRICS[name]
        if entry["type"] != mtype:
            raise ValueError(f"{name} already registered as {entry['type']}")
        if help_text:
            entry["help"] = help_text
        if mtype == "counter":
            prev = entry["series"].get(key, 0.0)
            if value < prev:
                raise ValueError("counter values must not decrease")
            entry["series"][key] = float(value)
        else:
            entry["series"][key] = float(value)


def _delete(name: str) -> bool:
    with LOCK:
        return METRICS.pop(name, None) is not None


def _list() -> list[dict]:
    out = []
    with LOCK:
        for name, entry in sorted(METRICS.items()):
            for labels_fs, value in entry["series"].items():
                out.append(
                    {
                        "name": name,
                        "type": entry["type"],
                        "value": value,
                        "labels": dict(labels_fs),
                        "help": entry["help"],
                    }
                )
    return out


def _escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')


def _render_prometheus() -> bytes:
    lines: list[str] = []
    with LOCK:
        for name, entry in sorted(METRICS.items()):
            lines.append(f"# HELP {name} {entry['help']}")
            lines.append(f"# TYPE {name} {entry['type']}")
            for labels_fs, value in sorted(entry["series"].items(), key=lambda x: sorted(x[0])):
                if labels_fs:
                    label_str = ",".join(
                        f'{k}="{_escape(v)}"' for k, v in sorted(labels_fs)
                    )
                    lines.append(f"{name}{{{label_str}}} {value}")
                else:
                    lines.append(f"{name} {value}")
        uptime = time.time() - START
    lines.append("# HELP custom_metrics_up 1 if the custom-metrics process is running.")
    lines.append("# TYPE custom_metrics_up gauge")
    lines.append("custom_metrics_up 1")
    lines.append("# HELP custom_metrics_uptime_seconds Process uptime in seconds.")
    lines.append("# TYPE custom_metrics_uptime_seconds gauge")
    lines.append(f"custom_metrics_uptime_seconds {uptime:.3f}")
    return ("\n".join(lines) + "\n").encode()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        print(
            json.dumps(
                {
                    "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    "msg": fmt % args,
                    "path": getattr(self, "path", ""),
                }
            ),
            flush=True,
        )

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"

        if path == "/health":
            self._json(200, {"status": "ok"})
            return
        if path == "/metrics":
            body = _render_prometheus()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/api/metrics":
            self._json(200, {"metrics": _list()})
            return
        if path == "/set":
            qs = parse_qs(parsed.query)
            try:
                name = qs["name"][0]
                value = float(qs["value"][0])
                mtype = qs.get("type", ["gauge"])[0]
                help_text = qs.get("help", [None])[0]
                reserved = {"name", "value", "type", "help"}
                labels = {k: v[0] for k, v in qs.items() if k not in reserved}
                _upsert(name, mtype, value, labels, help_text)
            except KeyError as exc:
                self._json(400, {"error": f"missing query param: {exc.args[0]}"})
                return
            except ValueError as exc:
                self._json(400, {"error": str(exc)})
                return
            self._json(200, {"ok": True, "name": name, "value": value, "type": mtype, "labels": labels})
            return

        self._json(
            200,
            {
                "service": "custom-metrics",
                "endpoints": [
                    "GET /health",
                    "GET /metrics",
                    "GET /api/metrics",
                    "POST /api/metrics",
                    "GET /set?name=&value=&type=gauge&label=value",
                    "DELETE /api/metrics/<name>",
                ],
            },
        )

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"
        if path != "/api/metrics":
            self._json(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw.decode() or "{}")
            name = payload["name"]
            value = float(payload["value"])
            mtype = payload.get("type", "gauge")
            labels = payload.get("labels") or {}
            help_text = payload.get("help")
            _upsert(name, mtype, value, labels, help_text)
        except (KeyError, json.JSONDecodeError, TypeError, ValueError) as exc:
            self._json(400, {"error": str(exc)})
            return
        self._json(201, {"ok": True, "name": name, "value": value, "type": mtype, "labels": labels})

    def do_DELETE(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        parts = [p for p in parsed.path.split("/") if p]
        if len(parts) == 3 and parts[0] == "api" and parts[1] == "metrics":
            name = parts[2]
            if _delete(name):
                self._json(200, {"ok": True, "deleted": name})
            else:
                self._json(404, {"error": f"metric not found: {name}"})
            return
        self._json(404, {"error": "not found"})

    def _json(self, status: int, body: dict) -> None:
        raw = json.dumps(body, indent=2).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)


if __name__ == "__main__":
    _seed()
    server = ThreadingHTTPServer(("0.0.0.0", 8081), Handler)
    print(json.dumps({"msg": "custom-metrics listening", "port": 8081}), flush=True)
    server.serve_forever()
