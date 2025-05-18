## Postgres

### Backup Old Data
```shell
docker volume create femboyfans_pg15.7
docker run --rm -v femboyfans_db_data:/old -v femboyfans_pg15.7:/new busybox sh -c "cp -r /old/* /new/"
```

### Dump Old Data
```shell
docker run --rm -v femboyfans_db_data:/var/lib/postgresql/data -e POSTGRES_USER=femboyfans -e POSTGRES_DB=femboyfans_development -e POSTGRES_HOST_AUTH_METHOD=trust -d --name femboyfans_pg15.7 postgres:15.7-alpine3.20
docker exec femboyfans_pg15.7 pg_dumpall -U femboyfans > ./pg15.7_dump.sql
docker rm -f femboyfans_pg15.7
```

### Import Old Data
```shell
docker volume create femboyfans_pg17.5
docker run --rm -v femboyfans_pg17.5:/var/lib/postgresql/data -e POSTGRES_USER=femboyfans -e POSTGRES_DB=femboyfans_development -e POSTGRES_HOST_AUTH_METHOD=trust -d --name femboyfans_pg17.5 postgres:17.5-alpine3.20
cat pg15.7_dump.sql | docker exec -i femboyfans_pg17.5 psql -U femboyfans -d postgres
docker rm -f femboyfans_pg17.5
```

### Replace Old Data
```shell
docker run --rm -v femboyfans_db_data:/old busybox sh -c "rm -rf /old/*"
docker run --rm -v femboyfans_pg17.5:/old -v femboyfans_db_data:/new busybox sh -c "cp -r /old/* /new/"
```

### Remove Intermediate Volume
```shell
docker volume rm femboyfans_pg17.5
```

### Remove Backup Data
```shell
docker volume rm femboyfans_pg15.7
```
