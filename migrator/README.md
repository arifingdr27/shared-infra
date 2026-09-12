# Migrator (per project)

Satu **folder = satu project/aplikasi**. Semua SQL schema per app hidup di sini, bukan di repo app (supaya multi-app bisa pakai Postgres `shared-infra` yang sama).

```
migrator/
├── README.md          ← file ini
├── migrate.sh         ← runner
├── splitbill/         ← project Splitbill
│   ├── 000001_init.up.sql
│   └── 000001_init.down.sql
└── <project-lain>/    ← tambah folder baru untuk app berikutnya
    ├── 000001_....up.sql
    └── ...
```

## Aturan

| Aturan | Keterangan |
|--------|------------|
| Nama folder | = nama database (contoh folder `splitbill` → DB `splitbill`) |
| Nama file | `{versi}_{nama}.up.sql` / `.down.sql` (contoh `000001_init.up.sql`) |
| Urutan | Lexical / numeric prefix — `000001` lalu `000002` |
| Jangan edit | File `.up.sql` yang sudah pernah dijalankan di production |
| Satu concern | Satu migration file = satu perubahan jelas |

## Prasyarat

1. Shared infra sudah jalan: `docker compose up -d`
2. File `.env` sudah diisi (`POSTGRES_USER`, `POSTGRES_PASSWORD`)
3. Database project sudah ada (init `postgres/init/01-create-databases.sql`, atau buat manual)

## Menjalankan migration

Dari root repo `shared-infra`:

```bash
chmod +x migrator/migrate.sh

# Terapkan semua pending untuk project splitbill
./migrator/migrate.sh splitbill up

# Cek versi sekarang
./migrator/migrate.sh splitbill version

# Rollback 1 step
./migrator/migrate.sh splitbill down 1
```

Atau via Makefile:

```bash
make migrate PROJECT=splitbill
make migrate-version PROJECT=splitbill
```

## Tambah project baru

```bash
mkdir -p migrator/myapp
# buat DB sekali (jika belum):
docker exec -it shared_postgres psql -U "$POSTGRES_USER" -c 'CREATE DATABASE myapp;'

# tulis migration pertama
$EDITOR migrator/myapp/000001_init.up.sql
$EDITOR migrator/myapp/000001_init.down.sql

./migrator/migrate.sh myapp up
```

Tambahkan juga `CREATE DATABASE myapp;` di `postgres/init/` bila volume masih fresh (hanya jalan saat volume kosong pertama kali).

## Tambah migration pada project yang sudah ada

```bash
# Jangan ubah 000001_*.sql yang sudah applied
$EDITOR migrator/splitbill/000002_add_something.up.sql
$EDITOR migrator/splitbill/000002_add_something.down.sql
./migrator/migrate.sh splitbill up
```

## Cara kerja teknis

- Tool: [`migrate/migrate`](https://github.com/golang-migrate/migrate) (Docker image)
- Network: `shared_infra` → host DB `shared_postgres`
- Tabel tracking: `schema_migrations` (otomatis dibuat tool di dalam DB project)

## Project terdaftar

| Folder | Database | Aplikasi |
|--------|----------|----------|
| `splitbill` | `splitbill` | splitbill-arifin (API OCR) |

## Troubleshooting

| Gejala | Perbaikan |
|--------|-----------|
| `network shared_infra not found` | `docker compose up -d` dulu di root shared-infra |
| `database does not exist` | `CREATE DATABASE <project>;` di Postgres |
| `Dirty database` | Cek `schema_migrations`, perbaiki SQL, lalu `./migrator/migrate.sh <project> force <versi>` (hati-hati) |
| Password auth failed | Samakan `POSTGRES_*` di `.env` |

## Relasi dengan repo aplikasi

- **Sumber kebenaran schema** = folder di `migrator/<project>/` (repo ini).
- App (mis. `splitbill-arifin`) boleh punya salinan untuk auto-migrate saat start, tapi **ubah dulu di sini**, lalu sync ke app bila perlu.
