CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_cumul_mandats AS
WITH legislatures_ref AS (
    SELECT pl.number AS legislature,
           CASE
               WHEN EXISTS (SELECT 1 FROM param_current_legislatures pcl WHERE pcl.number = pl.number)
                   THEN current_date
               ELSE pl.end_date
               END AS date_reference
    FROM param_legislatures pl
),
     members_at_ref_date AS (
         SELECT DISTINCT ag.groupe_id,
                         ag.groupe_legislature AS legislature,
                         ag.acteur_uid
         FROM acteurs_groupes ag
                  INNER JOIN legislatures_ref lr ON lr.legislature = ag.groupe_legislature
         WHERE lr.date_reference IS NOT NULL
           AND ag.date_debut <= lr.date_reference
           AND (ag.date_fin IS NULL OR ag.date_fin >= lr.date_reference)
     ),
     duree_par_acteur AS (
         SELECT m.acteur_uid,
                SUM(
                        EXTRACT(EPOCH FROM AGE(
                                COALESCE(m.date_fin, lr.date_reference),
                                m.date_debut
                                           )) / (365.25 * 24 * 3600)
                ) AS nb_annees_cumul
         FROM mandats m
                  INNER JOIN legislatures_ref lr ON lr.legislature = m.legislature
         WHERE m.type_organe = 'GP'
         GROUP BY m.acteur_uid
     )
SELECT m.groupe_id,
       rg.code                                  AS groupe_code,
       m.legislature,
       ROUND(AVG(dpa.nb_annees_cumul)::numeric, 1) AS average_cumulated_years
FROM members_at_ref_date m
         INNER JOIN ref_groupes rg ON rg.groupe_id = m.groupe_id AND rg.groupe_legislature = m.legislature
         LEFT JOIN duree_par_acteur dpa ON dpa.acteur_uid = m.acteur_uid
GROUP BY m.groupe_id, rg.code, m.legislature;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_cumul_mandats_uq ON agg_groupes_stats_cumul_mandats (groupe_id, groupe_code, legislature);