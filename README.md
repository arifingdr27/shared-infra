# Shared Infra

Postgres + Redis + RabbitMQ untuk dipakai banyak aplikasi. Data disimpan di Docker named volumes (aman saat `restart` / `compose down` tanpa `-v`).

## Quick start

```bash
cp .env.example .env
# edit semua password di .env
docker compose up -d
docker compose ps
```

| Service | Host (default) | Dalam Docker network `shared_infra` |
|---------|----------------|--------------------------------------|
| Postgres | `127.0.0.1:5432` | `shared_postgres:5432` |
| Redis | `127.0.0.1:6379` | `shared_redis:6379` |
| RabbitMQ AMQP | `127.0.0.1:5672` | `shared_rabbitmq:5672` |
| RabbitMQ UI | http://127.0.0.1:15672 | — |

Port di-bind ke **localhost saja** supaya tidak terbuka ke internet.

## Connect dari aplikasi lain (Docker Compose)

Contoh Splitbill API:

```yaml
services:
  splitbill_api:
    networks:
      - shared_infra
    # DATABASE_URL di .env:
    # postgres://shared:PASSWORD@shared_postgres:5432/splitbill?sslmode=disable

networks:
  shared_infra:
    external: true
    name: shared_infra
```

DB `splitbill` dibuat otomatis saat volume Postgres pertama kali diinisialisasi (`postgres/init/01-create-databases.sql`).

## Migrator (schema per project)

Satu folder per aplikasi di `migrator/<nama-project>/`.

```bash
./migrator/migrate.sh splitbill up
# atau
make migrate PROJECT=splitbill
```

Panduan lengkap: [`migrator/README.md`](migrator/README.md)

## Persistensi

| Volume | Isi |
|--------|-----|
| `shared_postgres_data` | Data Postgres |
| `shared_redis_data` | Redis AOF |
| `shared_rabbitmq_data` | RabbitMQ |
| `shared_rabbitmq_log` | Log RabbitMQ |

- `docker compose restart` / `down` → data **tetap**
- `docker compose down -v` → data **hapus** (jangan dipakai sembarangan)

## Keamanan (ringkas)

- Password wajib di `.env` (jangan commit)
- Port hanya `127.0.0.1`
- Redis: password + AOF; `FLUSHALL` dinonaktifkan
- `no-new-privileges`, log di-rotate
- Guest RabbitMQ hanya loopback

## Perintah berguna

```bash
docker compose logs -f postgres
docker volume ls | grep shared_
docker compose down          # stop, keep volumes
docker compose down -v       # DANGER: wipe data
```
