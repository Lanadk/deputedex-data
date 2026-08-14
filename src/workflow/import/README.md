# Import — JSON vers PostgreSQL avec split automatique

Chargement des fichiers JSON normalisés (produits par `workflow/parser`) dans PostgreSQL, domaine par
domaine, sans passer par des fichiers intermédiaires ou `docker exec psql` : tout se fait en TypeScript, via
un `Pool` `pg` partagé (`workflow/_common/infrastructure/db/pool.ts`).

## Architecture

```
src/workflow/import/job/
├── trtImportCollecte.ts        # Orchestrateur : lance les 6 imports domaine par domaine
└── unit-import/
    ├── importActeurs.ts
    ├── importScrutins.ts
    ├── importMandats.ts
    ├── importAmendements.ts
    ├── importDossiers.ts
    ├── importDocuments.ts
    └── json-splitter.ts        # Utilitaire CLI de split JSON (voir plus bas)

src/workflow/_common/
├── job/PipelineJob.ts                          # Moteur générique à steps déclaratifs
└── infrastructure/db/
    ├── copyJsonLinesToRaw.ts                    # Import JSON-lines → table raw via COPY, par chunks
    └── sqlRunner.ts                              # Exécution de fichiers .sql / refresh de vues
```

## Fonctionnement

Chaque job unitaire (`unit-import/import<Domaine>.ts`) construit une liste de `Step` et la confie à
`PipelineJob.run()` :

1. **`sqlFile` (schema)** — applique `src/sql/schema/<domaine>.schema.sql` (DDL des tables raw/snapshot).
2. **`importRaw`**, une fois par (législature × fichier JSON du domaine) — copie le fichier JSON-lines dans
   une table `xxx_raw(data JSONB)` par chunks streamés via `COPY ... FORMAT csv` (125 Mo/chunk par défaut),
   applique le fichier de projection SQL (`sql/scripts/<domaine>/projections/project_*.sql`) après chaque
   chunk, puis `TRUNCATE` la table raw avant le chunk suivant.
3. **`sqlFile` (sync)** — fusionne les tables « snapshot » vers les tables finales
   (`sql/scripts/<domaine>/sync/sync_snapshot_to_final.sql`).
4. **`sqlFile` (cleanup snapshots)** — toujours exécuté : drop des tables snapshot intermédiaires.
5. **Cleanup des tables raw** — optionnel : demandé interactivement (`confirm()`), sauf si le job est lancé
   avec `--auto-cleanup`.
6. **`sqlFile` (verify)** — affiche les comptages finaux du domaine (`verify/final_counts.sql`).

```
votesDeputes.json (250 Mo)
    │  COPY par chunks de 125 Mo (copyJsonLinesToRaw.ts)
    ▼
votes_deputes_raw (JSONB, une ligne par record)
    │  projection SQL (project_votes_deputes.sql)
    ▼
votes_deputes (snapshot) ──sync──▶ votes_deputes (table finale)
```

Les fichiers plus petits que la taille de chunk passent en un seul `COPY`, sans découpage.

## Utilisation

### Tous les domaines

```bash
npx ts-node src/workflow/import/job/trtImportCollecte.ts [--auto-cleanup]
```

### Un domaine

```bash
npx ts-node src/workflow/import/job/unit-import/importActeurs.ts [--auto-cleanup]
npx ts-node src/workflow/import/job/unit-import/importScrutins.ts [--auto-cleanup]
# ... importMandats / importAmendements / importDossiers / importDocuments
```

`--auto-cleanup` supprime automatiquement les tables `*_raw` en fin de job, sans invite de confirmation
(utilisé par le menu et par `workflow_init`/`workflow_update` dans `src/menu.sh`).

## `json-splitter.ts` — utilitaire CLI autonome

Un utilitaire ligne de commande, indépendant du pipeline d'import ci-dessus, pour découper à la main un gros
fichier JSON-lines en plusieurs fichiers `<nom>_partN.json` :

```bash
npx ts-node src/workflow/import/job/unit-import/json-splitter.ts <fichier.json> <taille-max-mo>
```

## Limite PostgreSQL

PostgreSQL limite les valeurs JSONB à ~268 Mo. Le découpage par défaut à 125 Mo (voir
`DEFAULT_MAX_SIZE_MB` dans `copyJsonLinesToRaw.ts`) laisse une marge de sécurité confortable.

## Avantages de cette approche

- ✅ Pas de limite de taille pratique sur les fichiers sources
- ✅ Mémoire maîtrisée (streaming, jamais plus d'un chunk en mémoire)
- ✅ Aucun fichier intermédiaire sur disque, aucune dépendance à `docker exec`
- ✅ Code partagé et typé (`PipelineJob`, `copyJsonLinesToRaw`) entre tous les domaines
- ✅ Compatible Windows/Linux/macOS (tout passe par le driver `pg`, pas par un shell)
