-- PAS ENCORE VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_stabilite
-- ============================================================
-- Stabilité des groupes parlementaires par législature
--
-- Logique :
--   - Chaque ligne de acteurs_groupes correspond à un épisode
--     d'appartenance d'un acteur à un groupe
--   - Les groupes techniques (ex: PO0 / NI technique) sont neutralisés
--     dans le calcul des entrées/sorties réelles
--   - Une entrée réelle = un épisode dans un groupe "réel" qui ne prolonge
--     pas le même groupe réel après un simple passage technique
--     (l'affectation initiale d'un acteur en tout début de législature
--     n'est PAS comptée : ce n'est pas un mouvement, juste sa photo de départ)
--   - Une sortie réelle = une sortie d'un groupe "réel" qui n'est pas suivie
--     d'un retour dans ce même groupe après un simple passage technique
--   - Le taux de rotation est calculé comme :
--       nb_acteurs_distincts_legislature / nb_acteurs_photo
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_stabilite AS
WITH legislatures_ref AS (SELECT pl.number AS legislature,
                                 CASE
                                     WHEN pl.number IN (SELECT number FROM param_current_legislatures)
                                         THEN CURRENT_DATE
                                     ELSE pl.end_date
                                     END   AS date_reference
                          FROM param_legislatures pl),

     episodes_raw AS (SELECT ag.groupe_id,
                             ag.groupe_legislature AS legislature,
                             ag.acteur_uid,
                             ag.date_debut,
                             ag.date_fin,
                             lr.date_reference,
                             rg.code,
                             rg.libelle,
                             CASE
                                 WHEN ag.date_fin IS NOT NULL THEN ag.date_fin
                                 ELSE lr.date_reference
                                 END               AS date_fin_effective,
                             CASE
                                 WHEN ag.groupe_id = 'PO0' THEN TRUE
                                 WHEN rg.code LIKE '%NI%' AND rg.libelle ILIKE '%technique%' THEN TRUE
                                 WHEN rg.code = 'TBD' THEN TRUE
                                 ELSE FALSE
                                 END               AS is_technical_group
                      FROM acteurs_groupes ag
                               INNER JOIN legislatures_ref lr
                                          ON lr.legislature = ag.groupe_legislature
                               LEFT JOIN ref_groupes rg
                                         ON rg.groupe_id = ag.groupe_id
                                             AND rg.groupe_legislature = ag.groupe_legislature
                      WHERE lr.date_reference IS NOT NULL),

-- Tous les épisodes, pour les volumes bruts
     episodes_all AS (SELECT *
                      FROM episodes_raw),

-- Uniquement les épisodes de groupes "réels"
     episodes_real AS (SELECT *
                       FROM episodes_raw
                       WHERE is_technical_group = FALSE),

-- Timeline des seuls groupes réels par acteur/législature
     episodes_real_timeline AS (SELECT er.*,
                                       LAG(er.groupe_id) OVER (
                                           PARTITION BY er.acteur_uid, er.legislature
                                           ORDER BY er.date_debut, er.groupe_id
                                           ) AS prev_real_groupe_id,
                                       LEAD(er.groupe_id) OVER (
                                           PARTITION BY er.acteur_uid, er.legislature
                                           ORDER BY er.date_debut, er.groupe_id
                                           ) AS next_real_groupe_id
                                FROM episodes_real er),

-- Agrégats bruts : tout ce qui existe dans acteurs_groupes
     stabilite_brute AS (SELECT e.groupe_id,
                                e.legislature,
                                COUNT(*)                     AS nb_entrees,
                                COUNT(*) FILTER (
                                    WHERE e.date_fin IS NOT NULL
                                    )                        AS nb_sorties,
                                COUNT(*) FILTER (
                                    WHERE e.date_fin IS NOT NULL
                                        AND e.date_fin < e.date_reference
                                    )                        AS nb_sorties_reelles_brutes,
                                COUNT(*) FILTER (
                                    WHERE e.date_fin IS NOT NULL
                                        AND e.date_fin = e.date_reference
                                    )                        AS nb_sorties_fin_legislature,
                                COUNT(DISTINCT e.acteur_uid) AS nb_acteurs_distincts_legislature,
                                ROUND(
                                        AVG((e.date_fin_effective - e.date_debut))::numeric,
                                        2
                                )                            AS duree_moyenne_appartenance_jours
                         FROM episodes_all e
                         GROUP BY e.groupe_id,
                                  e.legislature),

-- Agrégats "réels" : passages techniques neutralisés
     stabilite_reelle AS (SELECT e.groupe_id,
                                 e.legislature,

                                 COUNT(*) FILTER (
                                     WHERE e.prev_real_groupe_id IS NOT NULL
                                         AND e.prev_real_groupe_id IS DISTINCT FROM e.groupe_id
                                     ) AS nb_entrees_reelles,

                                 COUNT(*) FILTER (
                                     WHERE e.date_fin IS NOT NULL
                                         AND e.date_fin < e.date_reference
                                         AND e.next_real_groupe_id IS DISTINCT FROM e.groupe_id
                                     ) AS nb_sorties_reelles

                          FROM episodes_real_timeline e
                          GROUP BY e.groupe_id,
                                   e.legislature)

SELECT sb.groupe_id,
       sb.legislature,
       rg.code,
       rg.libelle,
       COALESCE(gle.nb_acteurs_photo, 0)  AS nb_acteurs_photo,
       sb.nb_acteurs_distincts_legislature,

       -- volumes bruts
       sb.nb_entrees,
       sb.nb_sorties,
       sb.nb_sorties_fin_legislature,

       -- volumes réels corrigés des passages techniques
       COALESCE(sr.nb_entrees_reelles, 0) AS nb_entrees_reelles,
       COALESCE(sr.nb_sorties_reelles, 0) AS nb_sorties_reelles,

       sb.duree_moyenne_appartenance_jours,

       ROUND(
               sb.nb_acteurs_distincts_legislature::numeric
                   / NULLIF(COALESCE(gle.nb_acteurs_photo, 0), 0),
               4
       )                                  AS taux_rotation

FROM stabilite_brute sb
         LEFT JOIN stabilite_reelle sr
                   ON sr.groupe_id = sb.groupe_id
                       AND sr.legislature = sb.legislature
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = sb.groupe_id
                       AND rg.groupe_legislature = sb.legislature
         LEFT JOIN agg_groupes_effectifs_legislature gle
                   ON gle.groupe_id = sb.groupe_id
                       AND gle.legislature = sb.legislature;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_stabilite_uq ON agg_groupes_stats_stabilite (groupe_id, legislature);