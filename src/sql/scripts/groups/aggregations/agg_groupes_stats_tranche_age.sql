CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_tranche_age AS
WITH
    legislatures_ref AS (
        SELECT pl.number AS legislature,
               CASE
                   WHEN EXISTS (
                       SELECT 1
                       FROM param_current_legislatures pcl
                       WHERE pcl.number = pl.number
                   )
                       THEN current_date
                   ELSE pl.end_date
                   END AS date_reference
        FROM param_legislatures pl
    ),
     members_at_ref_date AS (
         SELECT DISTINCT
             ag.groupe_id,
             ag.groupe_legislature AS legislature,
             ag.acteur_uid
         FROM acteurs_groupes ag
                  INNER JOIN legislatures_ref lr
                             ON lr.legislature = ag.groupe_legislature
         WHERE lr.date_reference IS NOT NULL
           AND ag.date_debut <= lr.date_reference
           AND (ag.date_fin IS NULL OR ag.date_fin >= lr.date_reference)
     )
SELECT
    m.groupe_id,
    rg.code AS groupe_code,
    m.legislature,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 30 THEN '<30'
        WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 40 THEN '30-39'
        WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 50 THEN '40-49'
        WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 60 THEN '50-59'
        WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 70 THEN '60-69'
        ELSE '70+'
        END                                         AS tranche_age,
    COUNT(DISTINCT a.uid)                           AS nb_acteurs,
    SUM(COUNT(DISTINCT a.uid)) OVER (
        PARTITION BY m.groupe_id, m.legislature
        )                                           AS total_groupe,
    ROUND(
            COUNT(DISTINCT a.uid)::numeric * 100 /
            NULLIF(
                            SUM(COUNT(DISTINCT a.uid)) OVER (
                        PARTITION BY m.groupe_id, m.legislature
                        ), 0
            ),
            2
    )                                               AS pourcentage
FROM members_at_ref_date m
         INNER JOIN acteurs a
                    ON a.uid = m.acteur_uid
         INNER JOIN ref_groupes rg
                    ON rg.groupe_id = m.groupe_id
                        AND rg.groupe_legislature = m.legislature
WHERE a.date_naissance IS NOT NULL
GROUP BY
    m.groupe_id,
    rg.code,
    m.legislature,
    tranche_age;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_tranche_age_uq ON agg_groupes_stats_tranche_age
    (groupe_id, groupe_code, legislature, tranche_age);