-- OK VALIDE

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_parite AS
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
     )
SELECT m.groupe_id,
       rg.code                                                                  AS groupe_code,
       m.legislature,
       COUNT(DISTINCT CASE WHEN a.civilite = 'M.' THEN a.uid END)               AS nb_hommes,
       COUNT(DISTINCT CASE WHEN a.civilite = 'Mme' THEN a.uid END)              AS nb_femmes,
       COUNT(DISTINCT a.uid)                                                    AS nb_total,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN a.civilite = 'M.' THEN a.uid END)
                 / NULLIF(COUNT(DISTINCT a.uid), 0), 2)                         AS pct_hommes,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN a.civilite = 'Mme' THEN a.uid END)
                 / NULLIF(COUNT(DISTINCT a.uid), 0), 2)                         AS pct_femmes
FROM members_at_ref_date m
         INNER JOIN acteurs a ON a.uid = m.acteur_uid
         INNER JOIN ref_groupes rg ON rg.groupe_id = m.groupe_id AND rg.groupe_legislature = m.legislature
GROUP BY m.groupe_id, rg.code, m.legislature;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_parite_uq ON agg_groupes_stats_parite (groupe_id, groupe_code, legislature);