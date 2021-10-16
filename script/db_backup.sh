#!/usr/bin/env bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

file="$(date +%F)_h$(date +%H).sql"
mkdir -p $SCRIPT_DIR/../data/db_backup
docker exec -u postgres yiffyapi pg_dump e621 > $SCRIPT_DIR/../data/db_backup/$file
