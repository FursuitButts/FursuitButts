#!/usr/bin/env bash

file="$(date +%F_%H-%M-%s_e621).sql"
mkdir -p data/db_backup
docker exec -u postgres e621 pg_dump e621 > data/db_backup
