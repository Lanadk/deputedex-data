# Aggregat — vues matérialisées de statistiques

Dernière étape du pipeline : calcule les statistiques et vues agrégées consommées par le frontend
(effectifs et cohésion des groupes, participation aux scrutins, calendrier d'activité, fiches députés…) sous
forme de **vues matérialisées PostgreSQL** (`agg_*` / `mv_*`).

## Deux modes, par domaine

Chaque domaine (`acteurs`, `groups`, `calendar`, `deputes`) a **deux jobs** :

| Job | Rôle | Idempotent ? | Quand l'utiliser |
|---|---|---|---|
| `aggregation-oneshot.ts` | `CREATE MATERIALIZED VIEW IF NOT EXISTS` pour chaque vue du domaine, depuis `src/sql/scripts/<domaine>/aggregations/<vue>.sql` | ✅ Oui — les vues (et leurs index) déjà existantes sont ignorées, sans erreur | Initialisation d'une base (`workflow_init` / menu → option 7), **et rejouable à chaque déploiement** pour créer automatiquement les vues nouvellement ajoutées (voir « Créer une vue manquante en prod » ci-dessous) |
| `aggregation.ts` | `REFRESH MATERIALIZED VIEW` pour chaque vue du domaine | ✅ Oui | À chaque mise à jour des données (`workflow_update` / menu → option 6) |

Les deux s'appuient sur `PipelineJob` (`workflow/_common/job/PipelineJob.ts`) avec les steps `createView` /
`refreshView` respectivement, exécutés séquentiellement dans l'ordre de la liste `VIEWS` du job.

`trtAggregatCollecte.ts` (refresh) et `trtAggregatCollecte-oneshot.ts` orchestrent les 4 domaines dans
l'ordre : `acteurs → groupes → calendar → deputes`.

## Domaines et vues

| Domaine | Fichier SQL | Vues (`src/sql/scripts/<domaine>/aggregations/`) |
|---|---|---|
| **acteurs** | `agg_acteurs_stats_*.sql` | `agg_acteurs_stats_professions`, `agg_acteurs_stats_genre`, `agg_acteurs_stats_age`, `agg_acteurs_stats_geographie_election`, `agg_acteurs_stats_geographie_naissance` |
| **groups** | `agg_groupes_*.sql`, `mv_groupes_*.sql`, `agg_assemblee_*.sql`, `mv_assemblee_*.sql` | 27 vues : effectifs (courant/législature), cohésion (mensuelle/législature), couverture des scrutins, participation, expression des votes, positions politiques/comptables, démographie, stabilité, proximité de votes, professions (+ catégories/familles), présidents de groupe (`mv_groupes_presidents`), fiche infos, âge, parité, cumul de mandats, géographie (élection / naissance dép. / naissance pays), tranche d'âge, participation de l'Assemblée, présidents de l'Assemblée (`mv_assemblee_presidents`) |
| **calendar** | `agg_activity_calendar_mv.sql`, `agg_activity_calendar_details_mv.sql` | `agg_activity_calendar_mv`, `agg_activity_calendar_details_mv` |
| **deputes** | `agg_deputes_cards.sql`, `agg_deputes_stats_votes.sql`, `agg_deputes_stats_age.sql` | `agg_deputes_cards`, `agg_deputes_stats_votes`, `agg_deputes_stats_age` |

## Utilisation

```bash
# Tous domaines
npx ts-node src/workflow/aggregat/job/trtAggregatCollecte.ts            # refresh
npx ts-node src/workflow/aggregat/job/trtAggregatCollecte-oneshot.ts    # create (⚠️ une seule fois)

# Un domaine
npx ts-node src/workflow/aggregat/job/groups/aggregation.ts             # refresh
npx ts-node src/workflow/aggregat/job/groups/aggregation-oneshot.ts     # create (⚠️ une seule fois)
# idem pour acteurs/ calendar/ deputes/
```

Le menu interactif (`src/menu.sh`) expose ces deux modes pour chaque domaine sous *Aggregation Jobs*, et
demande une confirmation explicite avant tout job « One shot ».

## ⚠️ Attention

- Idempotence = protège uniquement le cas **« nouvelle vue »**. Si la définition SQL d'une vue **déjà créée**
  est modifiée, `IF NOT EXISTS` l'ignorera silencieusement — la prod garde l'ancienne définition sans erreur
  ni log visible. Pour propager un changement de définition, utiliser `recreateView.ts` (voir
  « Modifier la définition d'une vue déjà créée » ci-dessous) plutôt qu'un `DROP` à la main.
- Toujours ajouter une nouvelle vue aux **deux** jobs du domaine concerné (`VIEWS` dans `aggregation.ts` et
  `aggregation-oneshot.ts`, cette dernière exportée pour alimenter `registry.ts`) ainsi qu'au fichier `.sql`
  correspondant dans `aggregations/`, pour que création, refresh et recréation restent synchronisés.

## Modifier la définition d'une vue déjà créée

`recreateView.ts` fait le `DROP MATERIALIZED VIEW IF EXISTS ... CASCADE` puis rejoue le `.sql` du domaine
(résolu via `registry.ts`, construit à partir des `VIEWS` exportées des `aggregation-oneshot.ts`) — pour une
ou plusieurs vues nommées explicitement. C'est le seul chemin qui propage un changement de définition SQL sur
une vue déjà en prod ; ni le one-shot (`IF NOT EXISTS`) ni le refresh (`REFRESH MATERIALIZED VIEW`) ne le font.

```bash
# Dry-run par défaut : liste ce qui serait droppé/recréé, ne fait rien sans --yes
npx ts-node src/workflow/aggregat/job/recreateView.ts agg_groupes_effectifs_current

# Confirmé : DROP CASCADE + recréation
npx ts-node src/workflow/aggregat/job/recreateView.ts agg_groupes_effectifs_current --yes

# Plusieurs vues en une commande
npx ts-node src/workflow/aggregat/job/recreateView.ts agg_deputes_cards agg_deputes_stats_age --yes
```

⚠️ `CASCADE` peut emporter d'autres objets qui dépendent de la vue (une autre vue matérialisée, un index...) —
le job affiche la liste des vues ciblées avant d'agir, mais ne détaille pas les dépendances en cascade.
Vérifier `pg_depend`/tester en dev si un doute. Disponible aussi via `menu.sh` → *Aggregation Jobs* → option
*« Recreate View(s) »*, qui ajoute une confirmation `y/N` avant de passer `--yes`. Après recréation, rien
d'autre à faire : le prochain passage du refresh (cron `updateAll.ts`) reprend le rafraîchissement des
données normalement.

## Créer une vue manquante en prod (déploiement en attendant l'automatisation complète)

Le déploiement (`prisma migrate deploy`, voir le rôle `deploy-etl` de `deputydex-cd`) ne crée **aucune** vue
matérialisée — c'est le rôle de ces jobs d'aggregat. Depuis que `aggregation-oneshot.ts` est idempotent, on
peut le rejouer sans risque après un déploiement pour rattraper une vue nouvellement ajoutée :

```bash
npx ts-node src/workflow/aggregat/job/trtAggregatCollecte-oneshot.ts   # toutes les vues, tous domaines
# ou, ciblé sur un seul domaine :
npx ts-node src/workflow/aggregat/job/<domaine>/aggregation-oneshot.ts
```

contre la base de prod (`DB_URL` pointé dessus). Les vues déjà existantes sont ignorées ; seule la vue
manquante est créée. Côté `deputydex-cd`, le rôle Ansible `deploy-etl-sql` (playbook dédié, chaîné juste après
`deploy-etl` — qui lui reste Prisma-only) exécute maintenant cette étape automatiquement à chaque déploiement,
avec les jobs referentials et enrichment — voir `ansible/roles/deploy-etl-sql/tasks/main.yml`.
