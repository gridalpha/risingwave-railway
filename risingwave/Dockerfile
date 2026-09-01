# RisingWave frontend node for Railway.
#
# The published image is used unchanged for the meta, compute and compactor
# roles. Only the frontend needs a wrapper: RisingWave ships a superuser `root`
# with no password and exposes no environment variable for it, while this role
# is the one reachable from the internet through a Railway TCP proxy. The
# password is therefore applied over the pgwire port at boot, which needs a
# PostgreSQL client the base image does not carry.
FROM risingwavelabs/risingwave:v3.0.3

USER root

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends postgresql-client \
 && rm -rf /var/lib/apt/lists/*

COPY frontend-entrypoint.sh /usr/local/bin/rw-frontend-entrypoint.sh
RUN chmod +x /usr/local/bin/rw-frontend-entrypoint.sh \
 && bash -n /usr/local/bin/rw-frontend-entrypoint.sh \
 && psql --version
