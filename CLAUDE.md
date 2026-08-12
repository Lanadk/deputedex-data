# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

ETL backend for **Deputedex**: downloads, parses, and loads French National Assembly (Assemblée nationale) open data into PostgreSQL via Prisma. This repo owns the database schema and migrations. A separate frontend repo (`deputedex`) consumes the generated Prisma client read-only and must never run migrations.

The repo lives in a small monorepo layout: sibling directories include a `data/` folder (outside this repo, used for downloaded/parsed files — see path resolution below) and the `deputedex` frontend repo.

## Commands

```bash
npm run first-setup          # full bootstrap: build db image, start docker, migrate, generate, seed
npm run docker-image:build   # docker build -t deputydex-db-image . (Dockerfile just COPYs src/sql/scripts into the image)
npm run docker:db            # ts-node local/local-db-init.ts — starts docker compose, waits for pg, creates writer/reader roles+grants
npm run prisma:generate      # prisma generate -> output goes to ./generated/prisma
npm run prisma:migrate-dev   # dotenv -e .env.local -- npx prisma migrate dev (also regenerates client)
npm run prisma:migrate-prod  # prisma migrate deploy (CI/CD only)
npm run prisma:seed          # ts-node prisma/seed.ts
npm run prisma:seed-data-sources # ts-node prisma/seed-data-sources.ts -- seeds ref_data_sources + ref_block_data_sources only (frontend transparency popover content)
npm run prisma:pull          # introspect existing DB
npm run drop-views           # ts-node prisma/drop-views.ts
npm run prisma:reset         # drop-views + prisma migrate reset (⚠️ destructive, drops all tables)
```

There is no test suite, lint config, or build step configured in this repo currently.

### Running the ETL workflows

`src/menu.sh` is the interactive entry point (must be run from inside `src/`, it uses relative paths like `./workflow/...`). It wraps individual job commands:

```bash
npx ts-node ./workflow/download/job/trtCollecteData.ts          # download all sources
npx ts-node ./workflow/parser/job/trtCheckCollecte.ts            # parse all
npx ts-node ./workflow/parser/job/unit-parser/parse<Domain>.ts   # parse one domain (Acteurs/Scrutins/Amendements/Dossiers/Documents/Mandats)
./workflow/import/job/trtImportCollecte.sh [--auto-cleanup]      # import all (bash, calls unit-import/*.sh per domain)
./workflow/referentials/job/trtUpdateReferentials.sh             # (re)build referential tables
./workflow/enrichment/job/trtEnrichmentCollecte.sh                # enrichment pass
./workflow/aggregat/job/trtAggregatCollecte.sh                    # refresh aggregate/stats tables
./workflow/aggregat/job/trtAggregatCollecte-oneshot.sh            # create aggregate tables (run once only)
npx ts-node ./workflow/_common/job/logDatasetUpdate.ts            # record dataset update monitoring row
```

The two composite workflows in `menu.sh` (`workflow_init`, `workflow_update`) chain: download → parse → import → referentials → enrichment → aggregate → monitor log. `init` uses the one-shot aggregate creation; `update` uses the refresh variant. Aggregate "one-shot" scripts are destructive/non-idempotent and prompt for confirmation in the menu — don't invoke them as part of a routine update.

## Architecture

### Layout

```
src/
  config/env.ts        # loads .env.local if DB_URL isn't already set
  utils/                # logger, hash, unzip, generic utils shared across workflows
  sql/
    schema/*.schema.sql       # base table DDL per domain
    scripts/<domain>/         # per-domain SQL, grouped by pipeline stage (see below)
    scripts/_shared/          # cross-domain SQL (e.g. verification)
    scripts/scripts/          # copied into the Postgres docker image at build time (Dockerfile)
    data/seed.sql             # reference/static seed data
    queries/*.queries.sql     # ad hoc query files
  workflow/<stage>/     # one directory per pipeline stage: download, parser, import, referentials, enrichment, aggregat, _common
prisma/
  schema.prisma         # single source of truth for DB schema; migrations/seed live here
  seed.ts
generated/prisma/       # prisma client output (gitignored, regenerated via prisma:generate)
local/local-db-init.ts  # local docker bootstrap (creates writer/reader roles + grants)
```

Each SQL domain folder (`acteurs`, `amendements`, `calendar`, `deputes`, `documents`, `dossiers`, `groups`, `mandats`, `scrutins`) follows the same stage subfolders where applicable: `sync/` (raw → snapshot), `projections/` (snapshot → final tables), `cleanup/` (drop raw/snapshot tables), `verify/` (row-count sanity checks), `referentials/` (lookup tables), `aggregations/` (stats tables), `enrichment/`. Not every domain has every stage.

### TypeScript workflow modules (download, parser)

`download` and `parser` follow a light hexagonal/clean-architecture split:

- `domain/models/` — core logic (e.g. `DownloadItemProcessor`, `ActeursExtractor`)
- `domain/models/entities/` — typed entities per data type
- `domain/usecases/` — orchestration (`DownloadFilesUsecase`, `ParseFilesUseCase`)
- `infrastructure/I*.ts` + `infrastructure/impl/*` — interface/implementation pairs for side-effecting concerns (file download, extraction, verification, directory sourcing, JSON writing) — swap implementations behind the interface rather than reaching into concrete classes
- `job/*.ts` — thin composition root: wires concrete infra + usecase, calls `.run()`, exposed as both an importable `main()` and a `require.main === module` CLI entry point

`workflow/_common/` holds cross-workflow infrastructure reused by multiple stages: `repositories/` (data access, e.g. `ParamDataSource`, `MonitorDataDownload`, `ParamCurrentLegislature`) each with an `I*.repository.ts` interface and `impl/`, plus `services/` wrapping those repositories the same interface/impl way.

The remaining stages (`import`, `referentials`, `enrichment`, `aggregat`) are primarily bash scripts that shell out to `docker exec ... psql` against the running `deputydex-db` container, running the SQL files from `src/sql/scripts/`. `import`'s `json-splitter.ts` splits JSON files >125MB before import (Postgres JSONB has a ~268MB limit); see `src/workflow/import/README.md` for the raw-table → projection → truncate cycle.

### Database access model

Two DB roles are used everywhere, provisioned by `local/local-db-init.ts`:
- `DB_USER_WRITER` (`user_etl_writer`) — used by this repo for all ETL writes/migrations
- `DB_USER_READER` (`user_app_reader`) — read-only, used by the frontend

`.env.local` (gitignored) holds `DB_URL`, `DB_HOST/PORT/NAME`, and the writer/reader credentials — see README.md for the required keys. Bash scripts under `workflow/` currently hardcode `DB_CONTAINER`/`DB_USER_WRITER`/`DB_NAME` rather than sourcing them from `.env.local` (marked `TODO` in the scripts themselves — be aware these can drift from the real env values).

### Schema change workflow

1. Edit `prisma/schema.prisma`.
2. `npm run prisma:migrate-dev` — generates the migration SQL in `prisma/migrations/` and regenerates the client.
3. Copy the updated `schema.prisma` into the frontend repo (`../deputydex/app/infrastructure/db/prisma/schema.prisma`) and run `prisma generate` there. This sync is currently manual (not yet automated via CI).
4. Never run `prisma migrate` from the frontend repo — migrations are owned exclusively by this repo.