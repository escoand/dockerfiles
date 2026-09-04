#!/usr/bin/env python3

import asyncio
import collections
import datetime as dt
import hashlib
import json
import logging
import os
import socket
import struct
import subprocess
import time

from aiohttp import web
from aiohttp.client_exceptions import ClientConnectionResetError
from systemd import journal

API_VERSION = "1.41"
PROXY_NAME = "journald-docker-proxy"
JOURNAL_ID = os.environ.get("JOURNAL_ID", "_journal")
LOGGER = logging.getLogger(PROXY_NAME)
UNIT_CACHE_TTL = float(os.environ.get("UNIT_CACHE_TTL", "2"))
UNIT_CACHE = {"expires": 0.0, "items": []}


def _parse_bool(raw, default=False):
    if raw is None:
        return default
    if isinstance(raw, bool):
        return raw
    return str(raw).strip().lower() in ("1", "true", "yes", "on")


def _api_headers(extra=None):
    headers = {"Api-Version": API_VERSION}
    if extra:
        headers.update(extra)
    return headers


def _utc_now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")


def _to_str(value, default=""):
    if value is None:
        return default
    return str(value)


def _to_str_list(value) -> list:
    if value is None:
        return []
    if isinstance(value, str):
        return value.split()
    return [_to_str(item) for item in value]


def _safe_int(raw, default=0) -> int:
    if isinstance(raw, bool):
        return default
    if isinstance(raw, int):
        return raw
    raw = _to_str(raw).strip()
    if raw and raw.lstrip("-").isdigit():
        return int(raw)
    return default


def _scoped_unit_id(unit_name: str, scope: str) -> str:
    # Include scope to avoid collisions between user and system unit names.
    return hashlib.sha256(f"{scope}:{unit_name}".encode("utf-8")).hexdigest()


def _journal_full_id() -> str:
    return _scoped_unit_id(JOURNAL_ID, "journal")


def _timestamp_from_usec(raw):
    usec = _safe_int(raw, default=0)
    if usec <= 0:
        return None
    return dt.datetime.fromtimestamp(usec / 1_000_000, tz=dt.timezone.utc)


def _invocation_id(raw) -> str:
    if isinstance(raw, list):
        return bytes(int(x) & 0xFF for x in raw).hex()
    return _to_str(raw).strip().replace("-", "")


def _run_busctl(*args) -> dict:
    result = subprocess.run(
        ["busctl", "--user", "--json=short", *args],
        capture_output=True,
        text=True,
        timeout=10,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"busctl {' '.join(args)} failed: {result.stderr.strip()}"
        )
    output = result.stdout.strip()
    return json.loads(output) if output else {"data": []}


def _bus_value(value):
    if isinstance(value, dict) and "data" in value:
        return value["data"]
    return value


def _bus_properties(payload: dict) -> dict:
    data = payload.get("data") or []
    raw_props = data[0] if data else {}
    return {key: _bus_value(value) for key, value in raw_props.items()}


def _unit_path(unit_name: str) -> str:
    payload = _run_busctl(
        "call",
        "org.freedesktop.systemd1",
        "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager",
        "GetUnit",
        "s",
        unit_name,
    )
    return (payload.get("data") or [None])[0]


def _list_service_properties() -> list:
    payload = _run_busctl(
        "call",
        "org.freedesktop.systemd1",
        "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager",
        "ListUnitsByPatterns",
        "asas",
        "0",
        "1",
        "*.service",
    )
    rows = (payload.get("data") or [[]])[0]
    return [
        {
            "Id": row[0],
            "Description": row[1],
            "LoadState": row[2],
            "ActiveState": row[3],
            "SubState": row[4],
            "Names": [row[0]],
            "_ObjectPath": row[6],
        }
        for row in rows
    ]


def _unit_properties(unit_name: str) -> dict:
    unit_path = _unit_path(unit_name)
    unit_props = _bus_properties(
        _run_busctl(
            "call",
            "org.freedesktop.systemd1",
            unit_path,
            "org.freedesktop.DBus.Properties",
            "GetAll",
            "s",
            "org.freedesktop.systemd1.Unit",
        )
    )
    service_props = _bus_properties(
        _run_busctl(
            "call",
            "org.freedesktop.systemd1",
            unit_path,
            "org.freedesktop.DBus.Properties",
            "GetAll",
            "s",
            "org.freedesktop.systemd1.Service",
        )
    )
    return {**unit_props, **service_props}


def _restart_unit(unit_name: str):
    _run_busctl(
        "call",
        "org.freedesktop.systemd1",
        "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager",
        "RestartUnit",
        "ss",
        unit_name,
        "replace",
    )


def _unit_image(unit_name: str) -> str:
    return f"systemd:{unit_name}"


def _unit_names(unit_name: str, props: dict) -> list:
    names = [f"/{unit_name}"]
    for n in _to_str_list(props.get("Names")):
        n = _to_str(n)
        if n and f"/{n}" not in names:
            names.append(f"/{n}")
    return names


def _container_list_entry(
    unit_name: str, scope: str, state: str, props: dict = None
) -> dict:
    props = props or {}
    inv_id = _invocation_id(props.get("InvocationID"))
    return {
        "Created": None,
        "Id": f"_{_scoped_unit_id(unit_name, scope)}",
        "Image": _unit_image(unit_name),
        "Names": _unit_names(unit_name, props),
        "State": state or "unknown",
        "_invocation_id": inv_id if inv_id.strip("0") else "",
        "_unit": unit_name,
        "_scope": scope,
    }


def _build_containers():
    items = []
    for props in _list_service_properties():
        unit_name = props.get("Id")
        if not unit_name:
            continue
        items.append(
            _container_list_entry(unit_name, "user", props.get("SubState"), props)
        )

    reader = journal.Reader()
    # systemd journal can enumerate unique values for indexed fields.
    for raw in reader.query_unique("_SYSTEMD_UNIT"):
        unit_name = _to_str(raw).strip()
        if not unit_name or not unit_name.endswith(".service"):
            continue
        items.append(_container_list_entry(unit_name, "system", "running"))

    items.append(
        {
            "Created": None,
            "Id": f"_{_journal_full_id()}",
            "Image": _unit_image(JOURNAL_ID),
            "Names": [f"/{JOURNAL_ID}"],
            "State": "running",
            "_unit": None,
            "_scope": "journal",
        }
    )
    return items


def list_containers():
    now = time.monotonic()
    if now >= UNIT_CACHE["expires"]:
        UNIT_CACHE["items"] = _build_containers()
        UNIT_CACHE["expires"] = now + UNIT_CACHE_TTL
    return [dict(item) for item in UNIT_CACHE["items"]]


def find_target(container_id: str):
    if container_id == JOURNAL_ID:
        return {"unit": None, "scope": "journal", "id": _journal_full_id()}
    needle = container_id[1:] if container_id.startswith("_") else container_id
    if not needle:
        return None

    for item in list_containers():
        full_id = item["Id"].lstrip("_")
        inv_id = item.get("_invocation_id", "")
        if full_id.startswith(needle) or (inv_id and inv_id.startswith(needle)):
            return {
                "unit": item["_unit"],
                "scope": item["_scope"],
                "id": full_id,
            }

    return None


def docker_info():
    mem_total = 0
    try:
        page_size = os.sysconf("SC_PAGE_SIZE")
        phys_pages = os.sysconf("SC_PHYS_PAGES")
        mem_total = int(page_size) * int(phys_pages)
    except (AttributeError, ValueError, OSError):
        mem_total = 0

    cpu_count = os.cpu_count() or 1
    containers = list_containers()

    running_states = {"running"}
    paused_states = {"paused"}

    containers_running = 0
    containers_paused = 0
    for c in containers:
        state = _to_str(c.get("State", "")).lower()
        if state in running_states:
            containers_running += 1
        elif state in paused_states:
            containers_paused += 1

    containers_total = len(containers)
    containers_stopped = max(
        0, containers_total - containers_running - containers_paused
    )

    return {
        "ID": socket.gethostname(),
        "Containers": containers_total,
        "ContainersRunning": containers_running,
        "ContainersPaused": containers_paused,
        "ContainersStopped": containers_stopped,
        # There is no image registry in this shim, so mirror current discovered entries.
        "Images": containers_total,
        "NCPU": cpu_count,
        "MemTotal": mem_total,
        "ServerVersion": PROXY_NAME,
        "SwapFree": 0,
        "SwapTotal": 0,
    }


def docker_version():
    return {
        "Platform": {"Name": PROXY_NAME},
        "Components": [
            {
                "Name": PROXY_NAME,
                "Version": "1.0.0",
                "Details": {},
            }
        ],
        "Version": "1.0.0",
        "ApiVersion": API_VERSION,
        "MinAPIVersion": API_VERSION,
        "GitCommit": "",
        "GoVersion": "",
        "Os": "linux",
        "Arch": "amd64",
        "KernelVersion": "",
        "BuildTime": "",
    }


def parse_unix_ts(raw: str):
    if raw is None or raw == "":
        return None
    try:
        ts = float(raw)
    except ValueError:
        return None
    return dt.datetime.fromtimestamp(ts, tz=dt.timezone.utc)


def parse_logs_query(query):
    follow = _parse_bool(query.get("follow"), default=False)
    since_raw = query.get("since")
    until_raw = query.get("until")
    tail_raw = query.get("tail", "all")

    since = None
    until = None
    # Preserve existing quirky behavior where negative since is interpreted as until.
    if since_raw and since_raw.startswith("-"):
        until = parse_unix_ts(since_raw[1:])
    else:
        since = parse_unix_ts(since_raw)

    if until is None:
        until = parse_unix_ts(until_raw)

    tail = None
    if tail_raw and tail_raw != "all":
        try:
            tail = max(0, int(tail_raw))
        except ValueError:
            tail = None

    return {"follow": follow, "since": since, "until": until, "tail": tail}


def entry_ts(entry):
    ts = entry.get("__REALTIME_TIMESTAMP")
    if isinstance(ts, dt.datetime):
        return ts.astimezone(dt.timezone.utc)
    if isinstance(ts, (int, float)):
        return dt.datetime.fromtimestamp(float(ts) / 1_000_000, tz=dt.timezone.utc)
    return None


def format_line(entry):
    ts = entry_ts(entry) or dt.datetime.now(dt.timezone.utc)
    host = entry.get("_HOSTNAME", "localhost")
    ident = entry.get("SYSLOG_IDENTIFIER") or entry.get("_COMM") or "journal"
    pid = entry.get("_PID", "?")
    msg = entry.get("MESSAGE", "")
    return f"{ts.isoformat().replace('+00:00', 'Z')} {host} {ident}[{pid}]: {msg}"


def iter_journal_lines(service, opts, unit_field="USER_UNIT"):
    reader = journal.Reader()
    if service:
        reader.add_match(**{unit_field: service})

    if opts["tail"] is not None and not opts["since"]:
        collected = collections.deque()
        reader.seek_tail()
        for _ in range(opts["tail"]):
            entry = reader.get_previous()
            if not entry:
                break
            ts = entry_ts(entry)
            if opts["until"] and ts and ts > opts["until"]:
                continue
            collected.appendleft(format_line(entry))
    elif opts["since"]:
        reader.seek_realtime(opts["since"])
        reader.get_next()
        collected = collections.deque(maxlen=opts["tail"] or None)
        for entry in reader:
            ts = entry_ts(entry)
            if opts["until"] and ts and ts > opts["until"]:
                break
            collected.append(format_line(entry))
    else:
        reader.seek_head()
        collected = collections.deque(maxlen=opts["tail"] or None)
        for entry in reader:
            ts = entry_ts(entry)
            if opts["until"] and ts and ts > opts["until"]:
                break
            collected.append(format_line(entry))

    for line in collected:
        yield line

    if not opts["follow"]:
        return

    reader.seek_tail()
    reader.get_previous()
    reader.get_next()
    while True:
        rv = reader.wait(1_000_000)  # 1s
        if rv == journal.NOP:
            continue
        for entry in reader:
            ts = entry_ts(entry)
            if opts["until"] and ts and ts > opts["until"]:
                return
            yield format_line(entry)


async def iter_journal_lines_async(service, opts, unit_field="USER_UNIT"):
    iterator = iter_journal_lines(service, opts, unit_field=unit_field)
    done = object()

    def next_line():
        try:
            return next(iterator)
        except StopIteration:
            return done

    while True:
        line = await asyncio.to_thread(next_line)
        if line is done:
            return
        yield line


def docker_mux_frame(line: str) -> bytes:
    payload = (line + "\r\n").encode("utf-8", errors="replace")
    header = struct.pack(
        ">BxxxI", 2, len(payload)
    )  # stream 2=stderr, Docker multiplexed format
    return header + payload


def _json_response(code, body):
    return web.json_response(body, status=code, headers=_api_headers())


def _text_response(code, text):
    return web.Response(text=text, status=code, headers=_api_headers())


def _container_id(request):
    container_id = request.match_info.get("container_id")
    if not container_id:
        raise web.HTTPBadRequest(
            text='{"message":"Invalid container path"}', headers=_api_headers()
        )
    return container_id


async def handle_ping(_request):
    return _text_response(200, "OK")


async def handle_info(_request):
    return _json_response(200, docker_info())


async def handle_version(_request):
    return _json_response(200, docker_version())


async def handle_events(_request):
    resp = web.StreamResponse(
        status=200, headers=_api_headers({"Content-Type": "application/json"})
    )
    await resp.prepare(_request)
    while True:
        await asyncio.sleep(3600)


async def handle_containers_json(_request):
    items = list_containers()
    for i in items:
        i.pop("_invocation_id", None)
        i.pop("_unit", None)
        i.pop("_scope", None)
    return _json_response(200, items)


def _docker_state_flags(status: str) -> dict:
    status = (status or "").lower()
    return {
        "Running": status in ("running", "reload", "start-pre", "start", "start-post"),
        "Paused": status == "paused",
        "Restarting": status == "auto-restart",
        "Dead": status in ("dead", "failed"),
    }


def _container_json_body(
    container_id: str,
    name: str,
    created_iso: str,
    status: str,
    pid: int,
    restart_count: int,
    memory_limit: int,
    image: str,
) -> dict:
    # Dozzle (and other Docker API clients) dereference Config/State/NetworkSettings
    # unconditionally, so these must always be present, never omitted/null.
    flags = _docker_state_flags(status)
    return {
        "Id": container_id,
        "Created": created_iso,
        "Path": "",
        "Args": [],
        "State": {
            "Status": status or "unknown",
            "Running": flags["Running"],
            "Paused": flags["Paused"],
            "Restarting": flags["Restarting"],
            "OOMKilled": False,
            "Dead": flags["Dead"],
            "Pid": pid,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": created_iso,
            "FinishedAt": "0001-01-01T00:00:00Z",
        },
        "Image": image,
        "Name": name,
        "RestartCount": restart_count,
        "HostConfig": {
            "NetworkMode": "default",
            "Memory": memory_limit,
        },
        "Mounts": [],
        "Config": {
            "Hostname": socket.gethostname(),
            "Image": image,
            "Labels": {},
            "Env": [],
            "Cmd": [],
        },
        "NetworkSettings": {
            "Networks": {},
        },
    }


async def handle_container_json(request):
    container_id = _container_id(request)
    target = find_target(container_id)
    if not target:
        return _json_response(404, {"message": f"No such container: {container_id}"})

    if target["scope"] != "user":
        body = _container_json_body(
            container_id=f"_{target['id']}",
            name=target["unit"] or JOURNAL_ID,
            created_iso=_utc_now_iso(),
            status="running",
            pid=0,
            restart_count=0,
            memory_limit=0,
            image=_unit_image(target["unit"] or JOURNAL_ID),
        )
        return _json_response(200, body)

    service = target["unit"]
    props = _unit_properties(service)
    created = _timestamp_from_usec(props.get("ExecMainStartTimestamp"))
    created_iso = (
        _utc_now_iso()
        if created is None
        else created.isoformat().replace("+00:00", "Z")
    )
    body = _container_json_body(
        container_id=f"_{target['id']}",
        name=service,
        created_iso=created_iso,
        status=props.get("SubState") or "unknown",
        pid=_safe_int(props.get("MainPID")),
        restart_count=_safe_int(props.get("NRestarts")),
        memory_limit=_safe_int(props.get("MemoryAvailable")),
        image=_unit_image(service),
    )
    return _json_response(200, body)


async def handle_container_stats(request):
    container_id = _container_id(request)
    target = find_target(container_id)
    if not target:
        return _json_response(404, {"message": f"No such container: {container_id}"})

    if target["scope"] != "user":
        return _json_response(
            200,
            {
                "id": f"_{target['id']}",
                "name": target["unit"] or JOURNAL_ID,
                "cpu_stats": {"cpu_usage": {"total_usage": 0}},
                "precpu_stats": {"cpu_usage": {"total_usage": 0}},
                "pids_stats": {"current": 0},
                "memory_stats": {"limit": 0, "max_usage": 0, "usage": 0},
            },
        )

    service = target["unit"]
    props = _unit_properties(service)
    cpu_usage = _safe_int(props.get("CPUUsageNSec"))
    payload = {
        "id": f"_{target['id']}",
        "name": service,
        "cpu_stats": {"cpu_usage": {"total_usage": cpu_usage}},
        "precpu_stats": {"cpu_usage": {"total_usage": 0}},
        "pids_stats": {"current": _safe_int(props.get("MainPID"))},
        "memory_stats": {
            "limit": _safe_int(props.get("MemoryAvailable")),
            "max_usage": _safe_int(props.get("MemoryPeak")),
            "usage": _safe_int(props.get("MemoryCurrent")),
        },
    }
    return _json_response(200, payload)


async def handle_image_json(request):
    image = request.match_info.get("image", "")
    created = _utc_now_iso()
    return _json_response(
        200,
        {
            "Id": f"sha256:{hashlib.sha256(image.encode('utf-8')).hexdigest()}",
            "RepoTags": [image] if image else [],
            "RepoDigests": [],
            "Created": created,
            "Size": 0,
            "VirtualSize": 0,
            "Labels": {},
            "Config": {
                "Image": image,
                "Labels": {},
                "Env": [],
                "Cmd": [],
            },
            "Architecture": "amd64",
            "Os": "linux",
        },
    )


async def handle_container_logs(request):
    container_id = _container_id(request)
    target = find_target(container_id)
    if not target:
        return _json_response(404, {"message": f"No such container: {container_id}"})

    unit_field = "USER_UNIT"
    service = target["unit"]
    if target["scope"] == "journal":
        service = None
    elif target["scope"] == "system":
        unit_field = "_SYSTEMD_UNIT"

    opts = parse_logs_query(request.query)
    resp = web.StreamResponse(status=200, headers=_api_headers())
    await resp.prepare(request)
    try:
        async for line in iter_journal_lines_async(
            service, opts, unit_field=unit_field
        ):
            await resp.write(docker_mux_frame(line))
        await resp.write_eof()
    except (ConnectionResetError, ClientConnectionResetError):
        LOGGER.info(
            "log stream closed by client path=%s remote=%s",
            request.path_qs,
            request.remote,
        )
    return resp


async def handle_container_restart(request):
    container_id = _container_id(request)
    target = find_target(container_id)
    if not target:
        return _json_response(404, {"message": f"No such container: {container_id}"})
    if target["scope"] != "user":
        return _json_response(
            501, {"message": "Restart is only supported for user units"}
        )
    _restart_unit(target["unit"])
    return _text_response(200, "OK")


async def handle_not_implemented(_request):
    return _json_response(501, {"message": "Not Implemented"})


@web.middleware
async def log_request(request, handler):
    started = time.monotonic()
    LOGGER.info(
        "request method=%s path=%s remote=%s",
        request.method,
        request.path_qs,
        request.remote,
    )
    try:
        response = await handler(request)
    except Exception:
        LOGGER.exception(
            "request failed method=%s path=%s remote=%s duration_ms=%.1f",
            request.method,
            request.path_qs,
            request.remote,
            (time.monotonic() - started) * 1000,
        )
        raise
    LOGGER.info(
        "response method=%s path=%s remote=%s status=%s duration_ms=%.1f",
        request.method,
        request.path_qs,
        request.remote,
        response.status,
        (time.monotonic() - started) * 1000,
    )
    return response


def _register_versioned_routes(app):
    app.router.add_get("/{version}/info", handle_info)
    app.router.add_get("/{version}/version", handle_version)
    app.router.add_get("/{version}/events", handle_events)
    app.router.add_get("/{version}/images/{image}/json", handle_image_json)
    app.router.add_get("/{version}/containers/json", handle_containers_json)
    app.router.add_get(
        "/{version}/containers/{container_id}/json", handle_container_json
    )
    app.router.add_get(
        "/{version}/containers/{container_id}/stats", handle_container_stats
    )
    app.router.add_get(
        "/{version}/containers/{container_id}/logs", handle_container_logs
    )
    app.router.add_post(
        "/{version}/containers/{container_id}/restart", handle_container_restart
    )


def _register_unversioned_routes(app):
    app.router.add_get("/_ping", handle_ping)
    app.router.add_get("/info", handle_info)
    app.router.add_get("/version", handle_version)
    app.router.add_get("/events", handle_events)
    app.router.add_get("/images/{image}/json", handle_image_json)
    app.router.add_get("/containers/json", handle_containers_json)
    app.router.add_get("/containers/{container_id}/json", handle_container_json)
    app.router.add_get("/containers/{container_id}/stats", handle_container_stats)
    app.router.add_get("/containers/{container_id}/logs", handle_container_logs)
    app.router.add_post("/containers/{container_id}/restart", handle_container_restart)


def create_app():
    app = web.Application(middlewares=[log_request])
    _register_unversioned_routes(app)
    _register_versioned_routes(app)
    app.router.add_route("*", "/{tail:.*}", handle_not_implemented)
    return app


def main():
    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    port = int(os.environ.get("PORT", "2375"))
    web.run_app(create_app(), host="0.0.0.0", port=port, access_log=None)


if __name__ == "__main__":
    main()
