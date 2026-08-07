"""
ShopFront - simulated e-commerce API with Prometheus metrics.
Generates catalog / cart / checkout traffic and optional chaos modes.
"""
from __future__ import annotations

import os
import random
import threading
import time
from typing import Optional

import psycopg2
from flask import Flask, jsonify, request
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)

APP_PORT = int(os.getenv("PORT", "8080"))
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://grafana:grafana@postgres:5432/demo",
)
CHAOS_LATENCY_MS = int(os.getenv("CHAOS_LATENCY_MS", "0"))
CHAOS_ERROR_RATE = float(os.getenv("CHAOS_ERROR_RATE", "0.02"))
TRAFFIC_RPS = float(os.getenv("TRAFFIC_RPS", "4"))

app = Flask(__name__)

REQUESTS = Counter(
    "http_requests_total",
    "HTTP requests",
    ["method", "route", "status"],
)
REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["method", "route"],
    buckets=(0.05, 0.1, 0.2, 0.35, 0.5, 0.75, 1.0, 2.0, 5.0),
)
ORDERS_TOTAL = Counter(
    "shopfront_orders_total",
    "Orders created",
    ["status"],
)
IN_FLIGHT = Gauge("http_requests_in_flight", "In-flight HTTP requests")
ACTIVE_SESSIONS = Gauge(
    "shopfront_active_sessions",
    "Synthetic active shopping sessions",
)


def db_conn():
    return psycopg2.connect(DATABASE_URL)


def record(route: str, method: str, status: int, elapsed: float) -> None:
    REQUESTS.labels(method=method, route=route, status=str(status)).inc()
    REQUEST_DURATION.labels(method=method, route=route).observe(elapsed)


def chaos_delay() -> None:
    base = random.uniform(0.02, 0.18)
    extra = CHAOS_LATENCY_MS / 1000.0
    if extra:
        extra += random.uniform(0, extra * 0.5)
    time.sleep(base + extra)


@app.before_request
def _before():
    IN_FLIGHT.inc()


@app.after_request
def _after(resp):
    IN_FLIGHT.dec()
    return resp


@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "shopfront-api"})


@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.get("/api/catalog")
def catalog():
    start = time.perf_counter()
    route = "/api/catalog"
    chaos_delay()
    status = 500 if random.random() < CHAOS_ERROR_RATE / 4 else 200
    body = (
        {"items": [{"sku": "TEE-01", "price": 29.0}, {"sku": "MUG-02", "price": 14.5}]}
        if status == 200
        else {"error": "catalog unavailable"}
    )
    record(route, "GET", status, time.perf_counter() - start)
    return jsonify(body), status


@app.post("/api/cart")
def cart():
    start = time.perf_counter()
    route = "/api/cart"
    chaos_delay()
    status = 500 if random.random() < CHAOS_ERROR_RATE / 3 else 200
    record(route, "POST", status, time.perf_counter() - start)
    return jsonify({"cart_id": "c-" + str(random.randint(1000, 9999)), "ok": status == 200}), status


@app.post("/api/checkout")
def checkout():
    start = time.perf_counter()
    route = "/api/checkout"
    chaos_delay()

    # Payment simulator outcomes
    roll = random.random()
    if roll < CHAOS_ERROR_RATE:
        status = 500
        order_status = "failed"
    elif roll < CHAOS_ERROR_RATE + 0.03:
        status = 402
        order_status = "declined"
    else:
        status = 200
        order_status = "paid"

    amount = round(random.uniform(12, 220), 2)
    if status == 200:
        try:
            with db_conn() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "INSERT INTO orders (status, amount, channel) VALUES (%s, %s, %s)",
                        (order_status, amount, "web"),
                    )
                conn.commit()
            ORDERS_TOTAL.labels(status="paid").inc()
        except Exception:
            status = 500
            order_status = "failed"
            ORDERS_TOTAL.labels(status="failed").inc()
    else:
        ORDERS_TOTAL.labels(status=order_status).inc()

    record(route, "POST", status, time.perf_counter() - start)
    return jsonify({"status": order_status, "amount": amount}), status


@app.post("/chaos")
def set_chaos():
    """Toggle lab chaos: {"latency_ms": 800, "error_rate": 0.2}"""
    global CHAOS_LATENCY_MS, CHAOS_ERROR_RATE
    data = request.get_json(force=True, silent=True) or {}
    if "latency_ms" in data:
        CHAOS_LATENCY_MS = int(data["latency_ms"])
    if "error_rate" in data:
        CHAOS_ERROR_RATE = float(data["error_rate"])
    return jsonify(
        {"latency_ms": CHAOS_LATENCY_MS, "error_rate": CHAOS_ERROR_RATE}
    )


def traffic_loop() -> None:
    """Background synthetic shoppers so dashboards are never empty."""
    routes = [
        ("GET", "/api/catalog"),
        ("POST", "/api/cart"),
        ("POST", "/api/checkout"),
    ]
    weights = [0.45, 0.30, 0.25]
    while True:
        ACTIVE_SESSIONS.set(random.randint(40, 120))
        method, path = random.choices(routes, weights=weights, k=1)[0]
        try:
            with app.test_client() as client:
                if method == "GET":
                    client.get(path)
                else:
                    client.post(path, json={})
        except Exception:
            pass
        time.sleep(max(0.05, 1.0 / max(TRAFFIC_RPS, 0.1)))


def wait_for_db(retries: int = 30) -> None:
    for _ in range(retries):
        try:
            with db_conn() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1")
            return
        except Exception:
            time.sleep(1)
    raise RuntimeError("PostgreSQL not reachable")


if __name__ == "__main__":
    wait_for_db()
    t = threading.Thread(target=traffic_loop, daemon=True)
    t.start()
    app.run(host="0.0.0.0", port=APP_PORT, threaded=True)
