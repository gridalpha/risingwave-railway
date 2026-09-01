# risingwave-railway

Deployment files for running [RisingWave](https://github.com/risingwavelabs/risingwave)
as a distributed cluster on [Railway](https://railway.com).

RisingWave's meta, compute and compactor nodes run from the published
`risingwavelabs/risingwave` image unchanged — every command-line option has an
`RW_*` environment variable, so they need only a start command. This repository
carries the two pieces the published image cannot provide.

## `risingwave/` — frontend node

A one-layer image on top of `risingwavelabs/risingwave` that adds `psql` and a
boot script. RisingWave creates the superuser `root` with **no password** and
exposes no setting for it, while the frontend is the role published to the
internet through a Railway TCP proxy. The script applies `RW_ROOT_PASSWORD` over
the pgwire port as soon as the listener accepts connections, on every boot, so
that variable is the source of truth for the superuser password.

## `gateway/` — meta dashboard gateway

`caddy:2-alpine` with HTTP basic auth in front of the meta node's dashboard,
which ships no authentication of its own and so never gets a public domain
directly. The bcrypt hash `basic_auth` needs cannot be expressed as a Railway
variable, so it is derived from `DASHBOARD_PASSWORD` at boot.

| Variable | Used by | Notes |
|---|---|---|
| `RW_ROOT_PASSWORD` | `risingwave/` | Superuser password, applied on every boot |
| `RW_PGWIRE_PORT` | `risingwave/` | Defaults to `4566` |
| `DASHBOARD_USERNAME` | `gateway/` | Basic-auth user |
| `DASHBOARD_PASSWORD` | `gateway/` | Basic-auth password, hashed at boot |
| `DASHBOARD_UPSTREAM` | `gateway/` | Defaults to `meta.railway.internal:5691` |

Every other setting is a stock `RW_*` variable read by the upstream binaries.

## `prometheus/` — metrics for the meta dashboard

`prom/prometheus` with a scrape config covering all four RisingWave roles. The
meta dashboard's metrics panels answer `500 Prometheus endpoint is not set`
without it, so `RW_PROMETHEUS_ENDPOINT` on the meta and frontend nodes points
here. Private only — nothing outside the project reaches it.
