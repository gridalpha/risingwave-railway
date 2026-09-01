#!/bin/sh
# HTTP basic-auth gateway for the RisingWave meta dashboard.
#
# The dashboard has no authentication of its own, so it is never given a public
# domain directly. Caddy's basic_auth wants a bcrypt hash, which no Railway
# variable can compute, so it is derived here at boot.
set -eu

if [ -z "${DASHBOARD_USERNAME:-}" ] || [ -z "${DASHBOARD_PASSWORD:-}" ]; then
	echo "gateway: DASHBOARD_USERNAME and DASHBOARD_PASSWORD must both be set" >&2
	exit 1
fi

# A ${{meta.RAILWAY_PRIVATE_DOMAIN}} reference renders empty until that service
# owns a deployment, which would bake ":5691" as the upstream. Repair it on the
# value's shape rather than trusting the variable to be unset.
: "${DASHBOARD_UPSTREAM:=meta.railway.internal:5691}"
case "$DASHBOARD_UPSTREAM" in
	"" | ":"*) DASHBOARD_UPSTREAM=meta.railway.internal:5691 ;;
esac

# --plaintext is the only scriptable form; piping to stdin returns an empty hash.
DASHBOARD_PASSWORD_HASH="$(caddy hash-password --plaintext "$DASHBOARD_PASSWORD")"
if [ -z "$DASHBOARD_PASSWORD_HASH" ]; then
	echo "gateway: failed to hash DASHBOARD_PASSWORD" >&2
	exit 1
fi
unset DASHBOARD_PASSWORD
export DASHBOARD_USERNAME DASHBOARD_PASSWORD_HASH DASHBOARD_UPSTREAM

echo "gateway: proxying ${DASHBOARD_UPSTREAM} behind basic auth on :${PORT:-8080}"
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
