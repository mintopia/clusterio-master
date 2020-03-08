#!/bin/bash
set -e

cp config.json.dist config.json

sed -i "s@CLUSTERIO_MASTER_AUTH_SECRET@${CLUSTERIO_MASTER_AUTH_SECRET}@" config.json

exec "$@"