#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

file="$(date +%F_%H-%M-%s_e621).sql"
mkdir -p data/db_backup
docker exec -u postgres e621 pg_dump e621 > $SCRIPT_DIR/../data/db_backup
