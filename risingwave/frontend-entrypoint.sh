#!/usr/bin/env bash
# Start the RisingWave frontend node and close its default-credential window.
#
# RisingWave creates the superuser `root` with no password on first boot and has
# no configuration knob for it, so the only way to set one is SQL over the
# pgwire port. This service is published through a Railway TCP proxy, so the
# password is applied as soon as the listener accepts connections, on every
# boot: RW_ROOT_PASSWORD is the source of truth for the superuser password.
set -euo pipefail

PGWIRE_PORT="${RW_PGWIRE_PORT:-4566}"

if [ -z "${RW_ROOT_PASSWORD:-}" ]; then
  echo "rw-bootstrap: RW_ROOT_PASSWORD is empty — refusing to start a publicly reachable frontend with a password-less superuser" >&2
  exit 1
fi

bootstrap_root_password() {
  # Double every single quote so the literal is safe inside the SQL string.
  local escaped="${RW_ROOT_PASSWORD//\'/\'\'}"
  local i
  for i in $(seq 1 150); do
    if PGPASSWORD="$RW_ROOT_PASSWORD" psql \
         --host=127.0.0.1 --port="$PGWIRE_PORT" --username=root --dbname=dev \
         --no-password --quiet --set=ON_ERROR_STOP=1 \
         --command="ALTER USER root WITH PASSWORD '${escaped}'" >/dev/null 2>&1; then
      echo "rw-bootstrap: superuser root password applied from RW_ROOT_PASSWORD"
      return 0
    fi
    sleep 2
  done
  echo "rw-bootstrap: FAILED to apply the root password after 300s — the frontend may still accept password-less superuser logins" >&2
  return 1
}

bootstrap_root_password &

exec /risingwave/bin/risingwave frontend-node "$@"
