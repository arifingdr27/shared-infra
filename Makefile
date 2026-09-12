.PHONY: up down ps logs migrate migrate-version migrate-down

up:
	docker compose up -d

down:
	docker compose down

ps:
	docker compose ps

logs:
	docker compose logs -f --tail=100

# Usage: make migrate PROJECT=splitbill
migrate:
	@test -n "$(PROJECT)" || (echo 'set PROJECT=... e.g. make migrate PROJECT=splitbill' >&2; exit 1)
	./migrator/migrate.sh $(PROJECT) up

migrate-version:
	@test -n "$(PROJECT)" || (echo 'set PROJECT=...' >&2; exit 1)
	./migrator/migrate.sh $(PROJECT) version

migrate-down:
	@test -n "$(PROJECT)" || (echo 'set PROJECT=...' >&2; exit 1)
	./migrator/migrate.sh $(PROJECT) down 1
