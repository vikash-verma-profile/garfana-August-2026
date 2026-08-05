#!/usr/bin/env python3
"""Minimal demo API for Day 2 labs.

Exposes:
  GET /          - increments counters/histograms and returns JSON
  GET /metrics   - Prometheus text exposition (counters + histogram)
"""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from collections import defaultdict
import json
import random
import threading
time = __import__("time")

START = time.time()
COUNTERS = defaultdict(int)
# Histogram buckets for request duration in seconds
BUCKETS = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
HIST_COUNTS = defaultdict(int)  # le -> count (cumulative filled at scrape)
HIST_SUM = 0.0
HIST_COUNT = 0
INSTANCE = "demo-api:8080"
LOCK = threading.Lock()


def observe(method: str, path: str, status: int, duration_s: float) -> None:
    global HIST_SUM, HIST_COUNT
    with LOCK:
        COUNTERS[(method, path, str(status), INSTANCE)] += 1
        HIST_SUM += duration_s
        HIST_COUNT += 1
        # Store non-cumulative observations per upper bound; export as cumulative
        placed = False
        for le in BUCKETS:
            if duration_s <= le:
                HIST_COUNTS[le] += 1
                placed = True
                break
        if not placed:
            HIST_COUNTS[float("inf")] += 1


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:
        print(
            json.dumps(
                {
                    "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    "level": "info",
                    "job": "node",
                    "msg": fmt % args,
                    "path": getattr(self, "path", ""),
                }
            ),
            flush=True,
        )

    def do_GET(self) -> None:  # noqa: N802
        t0 = time.time()
        if self.path.startswith("/metrics"):
            self._metrics()
            return
        if self.path.startswith("/health"):
            self._json(200, {"status": "ok"})
            observe("GET", "/health", 200, time.time() - t0)
            return

        path = self.path.split("?", 1)[0]
        if path not in ("/", "/api", "/checkout", "/cart", "/pay"):
            path = "/api"
        # Simulated latency for histogram / heatmap labs
        time.sleep(random.choice([0.002, 0.008, 0.02, 0.04, 0.09, 0.2, 0.4]))
        status = 200 if random.random() > 0.08 else random.choice([400, 500])
        duration = time.time() - t0
        observe("GET", path, status, duration)
        if status >= 400:
            print(
                json.dumps(
                    {
                        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                        "level": "error",
                        "job": "node",
                        "msg": f"request failed status={status}",
                        "path": path,
                    }
                ),
                flush=True,
            )
        self._json(status, {"path": path, "status": status, "instance": INSTANCE})

    def _json(self, status: int, body: dict) -> None:
        raw = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def _metrics(self) -> None:
        lines = [
            "# HELP http_requests_total Total HTTP requests handled by demo-api.",
            "# TYPE http_requests_total counter",
        ]
        with LOCK:
            for (method, path, status, instance), value in sorted(COUNTERS.items()):
                lines.append(
                    f'http_requests_total{{method="{method}",path="{path}",'
                    f'status="{status}",instance="{instance}",job="demo-api"}} {value}'
                )
            lines.append(
                "# HELP http_request_duration_seconds Request latency histogram."
            )
            lines.append("# TYPE http_request_duration_seconds histogram")
            cumulative = 0
            for le in BUCKETS:
                cumulative += HIST_COUNTS[le]
                lines.append(
                    f'http_request_duration_seconds_bucket{{le="{le}",'
                    f'instance="{INSTANCE}",job="demo-api"}} {cumulative}'
                )
            cumulative += HIST_COUNTS[float("inf")]
            lines.append(
                f'http_request_duration_seconds_bucket{{le="+Inf",'
                f'instance="{INSTANCE}",job="demo-api"}} {cumulative}'
            )
            lines.append(
                f'http_request_duration_seconds_sum{{instance="{INSTANCE}",'
                f'job="demo-api"}} {HIST_SUM:.6f}'
            )
            lines.append(
                f'http_request_duration_seconds_count{{instance="{INSTANCE}",'
                f'job="demo-api"}} {HIST_COUNT}'
            )
            uptime = time.time() - START
        lines.append("# HELP demo_api_up 1 if the demo API process is running.")
        lines.append("# TYPE demo_api_up gauge")
        lines.append(f'demo_api_up{{instance="{INSTANCE}"}} 1')
        lines.append("# HELP process_uptime_seconds Process uptime in seconds.")
        lines.append("# TYPE process_uptime_seconds gauge")
        lines.append(f'process_uptime_seconds{{instance="{INSTANCE}"}} {uptime:.3f}')
        body = ("\n".join(lines) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def traffic_loop() -> None:
    import urllib.request

    paths = ["/", "/api", "/checkout", "/cart", "/pay", "/health"]
    while True:
        try:
            urllib.request.urlopen(
                f"http://127.0.0.1:8080{random.choice(paths)}", timeout=5
            )
        except Exception:
            pass
        time.sleep(random.uniform(0.3, 1.2))


if __name__ == "__main__":
    threading.Thread(target=traffic_loop, daemon=True).start()
    server = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)
    print(
        json.dumps({"msg": "demo-api listening", "port": 8080, "job": "node"}),
        flush=True,
    )
    server.serve_forever()
