# Aggregat — vues matérialisées de statistiques

Dernière étape du pipeline : calcule les statistiques et vues agrégées consommées par le frontend
(effectifs et cohésion des groupes, participation aux scrutins, calendrier d'activité, fiches députés…) sous
forme de **vues matérialisées PostgreSQL** (`agg_*` / `mv_*`).

## Deux modes, par domaine

Chaque domaine (`acteurs`, `groups`, `calendar`, `deputes`) a **deux jobs** :

| Job | Rôle | Idempotent ? | Quand l'utiliser |
|---|---|---|---|
| `aggregation-oneshot.ts` | `CREATE MATERIALIZED VIEW` pour chaque vue du domaine, depuis `src/sql/scripts/<domaine>/aggregations/<vue>.sql` | ❌ Non — échoue si la vue existe déjà | Une seule fois, à l'initialisation d'une base (`workflow_init` / menu → option 7) |
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
| **deputes** | `agg_deputes_cards.sql` | `agg_deputes_cards` |

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

- Ne **jamais** relancer un `aggregation-oneshot.ts` sur une base où les vues existent déjà : la création
  échouera (et certains scripts peuvent être écrits de façon non idempotente au-delà du simple `CREATE`).
- Toujours ajouter une nouvelle vue aux **deux** jobs du domaine concerné (`VIEWS` dans `aggregation.ts` et
  `aggregation-oneshot.ts`) ainsi qu'au fichier `.sql` correspondant dans `aggregations/`, pour que création
  et refresh restent synchronisés.
