#!/usr/bin/env bash
# Smoke test: ActiveMQ broker starts, the image healthcheck goes healthy, the
# web console and STOMP/OpenWire ports accept connections, JMX exporter serves.
# Usage: test/smoke.sh <image>
set -euo pipefail
IMAGE="${1:?usage: $0 <image>}"
NAME="activemq-smoke-$$"
trap 'rc=$?; [ $rc -ne 0 ] && docker logs "$NAME" >&2 2>&1; docker rm -f "$NAME" >/dev/null 2>&1; exit $rc' EXIT

docker run -d --name "$NAME" "$IMAGE" >/dev/null

echo "waiting for healthcheck..."
for _ in $(seq 1 120); do
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$NAME")"
  [ "$health" = "healthy" ] && break
  [ "$(docker inspect -f '{{.State.Running}}' "$NAME")" = "true" ] || { echo "FAIL: container exited" >&2; exit 1; }
  sleep 2
done
[ "$health" = "healthy" ] || { echo "FAIL: container never became healthy ($health)" >&2; exit 1; }
echo "ok: healthcheck passing"

code="$(docker exec "$NAME" curl -s -o /dev/null -w '%{http_code}' http://localhost:8161/ || true)"
case "$code" in 200|302|401) echo "ok: web console responds ($code)" ;; *) echo "FAIL: web console returned $code" >&2; exit 1 ;; esac

for p in 61616 61613; do
  docker exec "$NAME" sh -c "echo > /dev/tcp/127.0.0.1/$p" 2>/dev/null \
    || docker exec "$NAME" sh -c "nc -z 127.0.0.1 $p" \
    || { echo "FAIL: port $p not accepting connections" >&2; exit 1; }
  echo "ok: port $p open"
done

# Capture first: grep -q closing the pipe early would trip pipefail via curl.
metrics="$(docker exec "$NAME" curl -sf http://localhost:3001/metrics)"
grep -qE '^(jvm|java_lang)_' <<<"$metrics" \
  || { echo "FAIL: JMX exporter metrics missing on :3001" >&2; exit 1; }
echo "ok: JMX exporter serving metrics"
echo "smoke test passed"
