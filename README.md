# DeputedexData 🏛️

Pipeline ETL qui télécharge, parse et charge les données ouvertes de l'**Assemblée nationale française**
(acteurs, mandats, groupes, scrutins, votes, amendements, dossiers et documents parlementaires) dans une base
PostgreSQL, via [Prisma](https://www.prisma.io/).

Ce repo est le **propriétaire exclusif du schéma de base de données** (`prisma/schema.prisma`) et de ses
migrations. Le frontend ([`deputedex`](#lécosystème-deputedex)) consomme le client Prisma généré ici en
**lecture seule** et ne doit jamais exécuter de migration.

## Sommaire

- [Présentation](#présentation)
- [Architecture du pipeline](#architecture-du-pipeline)
- [Structure du projet](#structure-du-projet)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Modèle de données](#modèle-de-données)
- [Tests](#tests)
- [CI/CD](#cicd)
- [Travailler avec Prisma](#travailler-avec-prisma)
- [Docker](#docker)
- [Dépannage](#dépannage)
- [L'écosystème Deputedex](#lécosystème-deputedex)

## Présentation

L'Assemblée nationale publie ses données en open data (fichiers XML/JSON zippés) sur
[data.assemblee-nationale.fr](https://data.assemblee-nationale.fr/). `deputydex-data` automatise
l'intégralité du cycle nécessaire pour transformer ces archives en une base relationnelle exploitable :

1. **Téléchargement** des archives par source de données et par législature.
2. **Parsing** des XML/JSON bruts vers des fichiers JSON normalisés, un domaine à la fois.
3. **Import** en base : chargement JSON → tables `*_raw` → projection SQL vers tables « snapshot » → fusion
   dans les tables finales, avec nettoyage des tables intermédiaires.
4. **Référentiels** : (re)construction des tables de lookup (groupes, types de scrutin, types d'organe, etc.).
5. **Enrichissement** : jointures/complétions post-import (ex. rattachement des photos d'acteurs).
6. **Agrégation** : calcul des statistiques et vues agrégées consommées par le frontend (résultats de
   scrutins par groupe, activité des groupes, calendrier, etc.).
7. **Monitoring** : traçabilité des exécutions (source par source et dataset par dataset).

Chaque étape est rejouable indépendamment (voir [Utilisation](#utilisation)), et les deux workflows
composites `Init` / `Update` du menu interactif enchaînent l'ensemble du pipeline.

### Stack technique

- **Node.js / TypeScript**, exécuté via `ts-node`
- **PostgreSQL 17** (image Docker construite depuis ce repo)
- **Prisma 7** (`@prisma/client` + `@prisma/adapter-pg`) pour le schéma, les migrations et les accès typés
- **pg** / **pg-copy-streams** pour les imports bulk via `COPY`
- **Jest** (`ts-jest`) pour les tests unitaires et d'intégration
- **GitHub Actions** pour la CI et la synchronisation du schéma vers le frontend

## Architecture du pipeline

```
data.assemblee-nationale.fr
        │  (zip XML/JSON par source × législature)
        ▼
   [ DOWNLOAD ]  workflow/download   → data/download/<domaine>/<legislature>/...
        ▼
   [ PARSER   ]  workflow/parser     → data/parser/tables/<legislature>/*.json (JSON normalisé)
        ▼
   [ IMPORT   ]  workflow/import     → raw (JSONB) → snapshot → tables finales (Postgres)
        ▼
   [ REFERENTIELS ] workflow/referentials → tables ref_* (lookups)
        ▼
   [ ENRICHMENT   ] workflow/enrichment   → complétions post-import
        ▼
   [ AGGREGAT     ] workflow/aggregat     → tables/vues de statistiques
        ▼
   [ MONITORING   ] workflow/_common      → monitor_data_set_update
        ▼
   Base PostgreSQL (Prisma) ──── lecture seule ────▶ repo frontend `deputedex`
```

Le dossier `data/` (téléchargements bruts + JSON parsés) vit **en dehors de ce repo**, en sibling directory
(`../data` par rapport à la racine du repo — voir la résolution de chemin dans les jobs `workflow/*/job`).

### Découpage `download` / `parser` (clean architecture allégée)

Ces deux workflows suivent un découpage hexagonal :

- `domain/models/` — logique cœur (ex. `DownloadItemProcessor`, `ActeursExtractor`, `BatchProcessor`)
- `domain/models/entities/` — entités typées par type de donnée
- `domain/usecases/` — orchestration (`DownloadFilesUsecase`, `ParseFilesUseCase`)
- `infrastructure/I*.ts` + `infrastructure/impl/*` — interfaces et implémentations pour les effets de bord
  (téléchargement, extraction, vérification, source de fichiers, écriture JSON)
- `job/*.ts` — composition root : câble les implémentations concrètes + le usecase, exposé à la fois comme
  `main()` importable et comme entrée CLI (`require.main === module`)

`workflow/_common/` regroupe l'infrastructure transverse : `repositories/` (accès données, ex.
`ParamDataSource`, `MonitorDataDownload`, `ParamCurrentLegislature`) et `services/` qui les enveloppent, tous
deux avec la même paire interface/impl. `workflow/_common/job/PipelineJob.ts` fournit un petit moteur de job
« piloté par étapes déclaratives » (`sqlFile`, `createView`, `refreshView`, `importRaw`) réutilisé par
`import`, `referentials`, `enrichment` et `aggregat`.

### Import : raw → snapshot → final

Un step `importRaw` (`PipelineJob`) copie un fichier JSON-lines dans une table `xxx_raw(data JSONB)` par
chunks streamés via `COPY` (par défaut 125 Mo/chunk — la limite JSONB de Postgres est ~268 Mo), applique le
fichier SQL de projection après chaque chunk, puis `TRUNCATE` la table raw. Une fois toutes les sources
d'un domaine chargées, un script SQL fusionne les tables « snapshot » vers les tables finales, les tables
intermédiaires sont nettoyées (`cleanup/`, avec confirmation interactive sauf `--auto-cleanup`), et un
script `verify/` affiche les comptages finaux.

## Structure du projet

```
deputydex-data/
├── prisma/
│   ├── migrations/            # Migrations SQL versionnées
│   ├── schema.prisma          # Schéma de la base — source de vérité
│   ├── prisma.ts              # Client Prisma (adapter-pg) partagé par les scripts
│   ├── seed.ts                # Exécute src/sql/data/seed.sql
│   └── drop-views.ts          # Drop des vues avant un reset
├── generated/
│   └── prisma/                # Client Prisma généré (gitignored)
├── local/
│   └── local-db-init.ts       # Bootstrap docker compose + création des rôles writer/reader
├── src/
│   ├── config/env.ts          # Charge .env.local si DB_URL n'est pas déjà présent
│   ├── utils/                 # logger, hash, unzip, confirm, utils partagés
│   ├── sql/
│   │   ├── schema/*.schema.sql       # DDL de base par domaine
│   │   ├── scripts/<domaine>/        # SQL par domaine, groupé par étape :
│   │   │                             #   sync/ projections/ cleanup/ verify/
│   │   │                             #   referentials/ aggregations/ enrichment/
│   │   ├── scripts/_shared/          # SQL transverse (ex. vérifications)
│   │   ├── scripts/scripts/          # Copié dans l'image Docker (voir Dockerfile)
│   │   ├── data/seed.sql             # Données de référence statiques
│   │   └── queries/*.queries.sql     # Requêtes ad hoc
│   ├── menu.sh                # Menu interactif (à lancer depuis src/)
│   └── workflow/
│       ├── download/          # Téléchargement des archives AN
│       ├── parser/            # Extraction XML/JSON → JSON normalisé
│       ├── import/            # Chargement en base (raw → snapshot → final)
│       ├── referentials/      # (Re)construction des tables de référence
│       ├── enrichment/        # Enrichissement post-import
│       ├── aggregat/          # Tables/vues de statistiques
│       └── _common/           # Repositories, services, PipelineJob, pool pg
├── docker-compose.yml         # Container PostgreSQL local
├── Dockerfile                 # Image Postgres + scripts SQL embarqués
├── jest.config.js             # Projets Jest "unit" et "integration"
└── package.json
```

## Prérequis

- **Node.js 22+** et npm (la CI tourne sur Node 22)
- **Docker** et Docker Compose
- **Git**
- Un dossier `data/` en sibling de ce repo (créé automatiquement par les jobs au premier run)

## Installation

### 1. Cloner le projet

```bash
git clone <url-du-repo> deputydex-data
cd deputydex-data
```

### 2. Installer les dépendances

```bash
npm install
```

### 3. Configurer les variables d'environnement

Créer un fichier `.env.local` à la racine du projet :

```env
# Connexion applicative (utilisée par Prisma / les jobs TS)
DB_URL=postgresql://user_etl_writer:toto@localhost:5432/deputydex

# Paramètres de connexion Docker
DB_HOST=localhost
DB_PORT=5432
DB_NAME=deputydex

# Utilisateur "admin" créé par docker compose (sert à provisionner les rôles ci-dessous)
DB_USER=dev
DB_PASSWORD=dev

# Rôle ETL writer — utilisé par ce repo pour toutes les écritures/migrations
DB_USER_WRITER=user_etl_writer
DB_PASSWORD_WRITER=toto

# Rôle App reader — lecture seule, utilisé par le frontend
DB_USER_READER=user_app_reader
DB_PASSWORD_READER=toto
```

### 4. Premier setup

```bash
npm run first-setup
```

Ce script enchaîne :
1. `docker-image:build` — build de l'image Postgres (`deputydex-db-image`, embarque `src/sql/scripts`)
2. `docker:db` — démarre `docker compose`, attend que Postgres réponde, crée les rôles `writer`/`reader`
   et leurs grants (`local/local-db-init.ts`)
3. `prisma:migrate-dev` — applique les migrations et régénère le client
4. `prisma:generate` — (re)génère le client Prisma dans `./generated/prisma`
5. `prisma:seed` — exécute `src/sql/data/seed.sql` (données de référence statiques)

À la fin, la base est prête : rôles configurés, tables créées selon `schema.prisma`, données de référence
en place. Il reste à charger les données de l'Assemblée nationale (étape suivante).

## Utilisation

### Option 1 — Menu interactif (recommandé)

Le menu doit être lancé **depuis `src/`** (il utilise des chemins relatifs du type `./workflow/...`) :

```bash
cd src
./menu.sh
```

```
DEPUTYDEX MAIN MENU
-----------
WORKFLOWS
-----------
1) Init          (Download + Parse + Import + Referentials CREATE + Enrichment + Aggregate CREATE)
2) Update        (Download + Parse + Import + Referentials UPDATE + Enrichment + Aggregate UPDATE)
-----------
FULL JOBS
-----------
3) Download All
4) Parse All
5) Import All
6) Aggregate All (Refresh)
7) Aggregate All (One shot)
8) Referentials Create / Update
9) Enrichment All
-----------
UNIT JOBS
-----------
11) See unit Jobs   → sous-menus Download / Parser / Import / Aggregation, domaine par domaine
0) Quit
```

- **`Init`** (option 1) : à lancer sur une base vierge — utilise la variante *one-shot* pour créer les
  tables d'agrégation (non idempotente, ne pas relancer telle quelle).
- **`Update`** (option 2) : à lancer pour rafraîchir une base déjà initialisée — utilise la variante
  *refresh* de l'agrégation.
- Les options « One shot » du menu (agrégation) demandent une confirmation explicite (`y/n`) car elles sont
  destructives/non idempotentes : elles ne doivent être lancées qu'une seule fois, à la création.

### Option 2 — Commandes unitaires

Chaque job est un binaire `ts-node` autonome, invocable directement (utile en CI, en cron, ou pour ne rejouer
qu'un domaine) :

| Étape | Commande | Portée |
|---|---|---|
| Download | `npx ts-node src/workflow/download/job/trtCollecteData.ts` | Toutes les sources |
| Parser | `npx ts-node src/workflow/parser/job/trtCheckCollecte.ts` | Tous les domaines |
| Parser (unitaire) | `npx ts-node src/workflow/parser/job/unit-parser/parse<Domaine>.ts` | Acteurs · Scrutins · Amendements · Dossiers · Documents |
| Import | `npx ts-node src/workflow/import/job/trtImportCollecte.ts [--auto-cleanup]` | Tous les domaines |
| Import (unitaire) | `npx ts-node src/workflow/import/job/unit-import/import<Domaine>.ts [--auto-cleanup]` | Acteurs · Scrutins · Mandats · Amendements · Dossiers · Documents |
| Référentiels | `npx ts-node src/workflow/referentials/job/trtUpdateReferentials.ts` | Toutes les tables `ref_*` |
| Enrichissement | `npx ts-node src/workflow/enrichment/job/trtEnrichmentCollecte.ts` | Toutes les tables |
| Agrégation (refresh) | `npx ts-node src/workflow/aggregat/job/trtAggregatCollecte.ts` | Acteurs · Groupes · Calendar · Députés |
| Agrégation (one-shot) | `npx ts-node src/workflow/aggregat/job/trtAggregatCollecte-oneshot.ts` | ⚠️ Création initiale uniquement, non idempotent |
| Monitoring | `npx ts-node src/workflow/_common/job/logDatasetUpdate.ts` | Enregistre un run dans `monitor_data_set_update` |

`--auto-cleanup` (import) supprime automatiquement les tables `*_raw` après import, sans demander de
confirmation.

## Modèle de données

Le schéma (`prisma/schema.prisma`) couvre les domaines suivants :

| Domaine | Modèles clés | Contenu |
|---|---|---|
| **Pilotage AN** | `ParamLegislature`, `ParamCurrentLegislature`, `RefDataDomain`, `ParamDataSource`, `MonitorDataDownload`, `MonitorDataSetsUpdate` | Législatures suivies, sources de données à télécharger par domaine/législature, suivi des téléchargements et des runs du pipeline |
| **Acteurs** | `Acteurs`, `ActeursAdressesPostales`, `ActeursAdressesMails`, `ActeursReseauxSociaux`, `ActeursTelephones`, `ActeursGroupes` | Fiches des parlementaires : identité, coordonnées, appartenance aux groupes |
| **Députés & Scrutins** | `Deputes`, `Scrutins`, `ScrutinsGroupes`, `VotesDeputes`, `ScrutinsAgregats`, `ScrutinsGroupesAgregats` | Scrutins publics, votes individuels, résultats agrégés par scrutin et par groupe |
| **Mandats** | `Mandats`, `MandatsSuppleants` | Mandats successifs d'un acteur et leurs suppléants |
| **Référentiels** | `GroupesParlementaires`, `RefGroupes`, `RefGroupesFondation`, `RefScrutinType`, `RefOrganeType`, `RefActeursPhotos` | Groupes parlementaires (dont année de fondation, site officiel), types de scrutin/organe, photos |
| **Amendements** | `amendements`, `amendements_co_auteurs` | Amendements déposés et leurs co-auteurs |
| **Dossiers législatifs** | `DossierParlementaire`, `DossierInitiateur`, `ActeLegislatif`, `ActeRapporteur`, `ActeTexteAssocie`, `ActeReunion`, `ActeVote`, `ActeDecision` | Dossiers parlementaires et l'arbre hiérarchique de leurs actes (lecture, rapport, réunion, vote, décision) |
| **Documents** | `documents`, `documents_classifications`, `documents_auteurs`, `documents_co_signataires`, `documents_organes_referents`, `documents_imprimeries`, `documents_depot_amendements` | Documents parlementaires (textes, rapports…), leurs auteurs et métadonnées d'impression |

Conventions transverses : la quasi-totalité des tables porte `row_hash` (déduplication/upsert par hash de
contenu) et `legislature_snapshot` (législature d'origine de la ligne), en plus de `created_at`/`updated_at`.

## Tests

```bash
npm test              # = test:unit — alias utilisé par la CI
npm run test:unit      # tests unitaires (*.spec.ts), aucune dépendance externe
npm run test:integration  # tests d'intégration (*.it.spec.ts), nécessitent une vraie base Postgres
npm run test:all       # les deux projets, en séquence (--runInBand)
```

Jest (`jest.config.js`) définit deux projets :

- **`unit`** — `src/**/*.spec.ts`, `local/**/*.spec.ts`, `prisma/**/*.spec.ts` (les `*.it.spec.ts` sont
  explicitement exclus). Aucune connexion base requise.
- **`integration`** — `src/**/*.it.spec.ts`, `prisma/**/*.it.spec.ts`. Nécessitent `DB_URL` pointé vers une
  base Postgres réelle (voir `test-integration` dans la CI, ou une base locale via `docker:db`).
  `forceExit: true` est nécessaire car l'adapter Prisma (`prisma/prisma.ts`) enveloppe un `Pool` `pg`
  créé manuellement, dont `prisma.$disconnect()` ne maîtrise pas totalement le cycle de vie.

Pas de config de lint dans ce repo actuellement.

## CI/CD

`.github/workflows/ci.yml` s'exécute sur push/PR vers `master` :

```
test  ──▶  test-integration  ──▶  build  ──▶  sync-schema*  ──▶  trigger-deploy*
(unit)     (postgres:16 service,     (tsc      (push master   (push master
           npm run test:integration)  --noEmit) uniquement)     uniquement)
```

- **`test`** — `npm test` (projet Jest `unit`)
- **`test-integration`** — démarre un service `postgres:16`, `prisma generate` + `prisma migrate deploy`,
  puis `npm run test:integration`
- **`build`** — `tsc --noEmit` : garde-fou de compilation (aucun bundler, aucun `dist/` consommé)
- **`sync-schema`** *(push sur `master` uniquement)* — si `prisma/schema.prisma` a changé, le copie tel quel
  vers `main` du repo frontend (`lanadk/deputydex`, chemin `app/infrastructure/db/prisma/schema.prisma`) via
  un commit automatique (`DEPUTYDEX_PUSH_TOKEN`). Ne fait **que** copier le fichier : `prisma generate` doit
  toujours être relancé côté frontend (normalement fait par son propre build).
- **`trigger-deploy`** *(push sur `master` uniquement)* — déclenche un `repository_dispatch` (`deploy-etl`)
  vers `lanadk/deputydex-cd` (`CD_DISPATCH_TOKEN`).

## Travailler avec Prisma

Prisma est utilisé à deux endroits dans l'écosystème Deputedex :
- **Backend ETL** (ce repo) : gère le schéma, les migrations et les imports.
- **Frontend** (`deputedex`) : utilise le client Prisma généré, en lecture seule, **jamais** de migration.

### Modifier le schéma

1. **Éditer** `prisma/schema.prisma`.
2. **Créer/appliquer la migration** :
   ```bash
   npm run prisma:migrate-dev
   # Prisma demande un nom, ex: "add_age_to_acteurs"
   ```
   Cette commande génère le SQL dans `prisma/migrations/`, l'applique sur la base locale (`.env.local`) et
   régénère le client automatiquement.
3. **Pousser sur `master`** : le job `sync-schema` de la CI détecte le diff sur `schema.prisma` et le
   commit directement sur `main` du repo frontend (voir [CI/CD](#cicd)). Penser à relancer `prisma generate`
   côté frontend.

### Commandes Prisma

| Commande | Usage | Contexte |
|---|---|---|
| `npm run prisma:generate` | Génère le client dans `./generated/prisma` | Après toute modif de schéma |
| `npm run prisma:migrate-dev` | Crée/applique une migration + régénère le client | Dev, ce repo uniquement |
| `npm run prisma:migrate-prod` | `prisma migrate deploy` | CI/CD uniquement |
| `npm run prisma:seed` | Exécute `src/sql/data/seed.sql` | Peuplement des données de référence |
| `npm run prisma:pull` | Introspecte une base existante | Rare |
| `npm run drop-views` | Supprime les vues avant un reset | Utilisé par `prisma:reset` |
| `npm run prisma:reset` | `drop-views` + `prisma migrate reset` | ⚠️ Destructif — drop toutes les tables |

**⚠️ Ne jamais exécuter `prisma migrate` depuis le repo frontend** — les migrations sont gérées
exclusivement par ce repo ETL.

### Utiliser le client généré

```typescript
import { prisma } from './prisma/prisma';

const deputes = await prisma.deputes.findMany();
const count = await prisma.scrutins.count();
```

## Docker

```bash
npm run docker-image:build   # (re)build de l'image deputydex-db-image (embarque src/sql/scripts)
npm run docker:db            # démarre docker compose + provisionne les rôles writer/reader

docker compose up -d         # démarrer le container
docker compose down          # arrêter
docker compose logs -f       # logs
docker compose down -v       # ⚠️ reset complet, supprime le volume de données
```

## Dépannage

- **`DB_URL is not defined`** : `.env.local` absent ou mal placé (doit être à la racine du repo, à côté de
  `package.json`) — voir `prisma/prisma.ts` et `local/local-db-init.ts`.
- **`.env.local introuvable` au lancement de `npm run docker:db`** : le fichier doit exister *avant* le
  premier lancement (il n'est pas généré automatiquement).
- **Un domaine échoue en base sur un gros fichier JSON** : la limite JSONB de Postgres est ~268 Mo ; l'import
  découpe automatiquement par chunks de 125 Mo via `COPY` (voir
  [Import : raw → snapshot → final](#import--raw--snapshot--final)) — aucune action manuelle nécessaire.
- **Tables `*_raw` qui traînent après un import interrompu** : relancer le job d'import unitaire concerné
  avec `--auto-cleanup`, ou répondre `y` à l'invite de nettoyage.
- **Frontend désynchronisé du schéma** : vérifier que le job `sync-schema` de la CI est passé sur le dernier
  push `master`, puis que `prisma generate` a bien été relancé côté frontend.

## L'écosystème Deputedex

- `deputydex-data` *(ce repo)* — ETL, schéma, migrations
- [`deputedex`](https://github.com/lanadk/deputydex) — frontend, consomme le client Prisma en lecture seule
- `deputydex-cd` — déploiement continu de l'ETL, déclenché en fin de pipeline CI
- Source des données : [data.assemblee-nationale.fr](https://data.assemblee-nationale.fr/)
