CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_geographie_election AS
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
       rg.code                                                          AS groupe_code,
       m.legislature,
       man.election_region,
       man.election_region_type,
       man.election_departement,
       COUNT(DISTINCT m.acteur_uid)                                     AS nb_acteurs,
       SUM(COUNT(DISTINCT m.acteur_uid)) OVER (
           PARTITION BY m.groupe_id, m.legislature
           )                                                                AS nb_total_groupe,
       ROUND(
               COUNT(DISTINCT m.acteur_uid)::numeric * 100 /
               NULLIF(SUM(COUNT(DISTINCT m.acteur_uid)) OVER (
                   PARTITION BY m.groupe_id, m.legislature
                   ), 0), 2
       )                                                                AS pct_dans_groupe
FROM members_at_ref_date m
         INNER JOIN ref_groupes rg
                    ON rg.groupe_id = m.groupe_id
                        AND rg.groupe_legislature = m.legislature
         INNER JOIN mandats man
                    ON man.acteur_uid = m.acteur_uid
                        AND man.legislature = m.legislature
WHERE man.election_departement IS NOT NULL
GROUP BY m.groupe_id, rg.code, m.legislature, man.election_region, man.election_region_type, man.election_departement;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_geographie_election_uq ON agg_groupes_stats_geographie_election (groupe_id, groupe_code, legislature, election_region, election_departement);