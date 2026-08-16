-- ============================================================
-- VIEW : agg_deputes_stats_age
-- ============================================================
-- Âge de chaque député, par législature, à la date de référence
-- (aujourd'hui pour la législature courante, date de fin de
-- législature pour les archivées) — même population et même
-- logique de date de référence que agg_deputes_cards (mandat
-- ASSEMBLEE actif/ayant siégé), pour que depute_uid+legislature
-- soit toujours joignable avec agg_deputes_cards côté front.
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_deputes_stats_age AS
WITH legislature_ref AS (
    SELECT
        pl.number AS legislature,
        CASE
            WHEN pl.number IN (SELECT number FROM param_current_legislatures)
                THEN CURRENT_DATE
            ELSE pl.end_date
            END AS date_reference
    FROM param_legislatures pl
),
     mandats_actifs AS (
         SELECT DISTINCT ON (m.acteur_uid, lr.legislature)
             m.acteur_uid,
             lr.legislature
         FROM mandats m
                  INNER JOIN legislature_ref lr ON lr.legislature = m.legislature
         WHERE
             m.type_organe = 'ASSEMBLEE'
           AND m.date_debut <= lr.date_reference
           AND (
             -- Legislature courante : actif aujourd'hui
             m.date_fin IS NULL OR m.date_fin >= lr.date_reference
                 OR
             -- Legislature archivée : a siégé à un moment dans la législature
             lr.legislature NOT IN (SELECT number FROM param_current_legislatures)
             )
         ORDER BY m.acteur_uid, lr.legislature, m.date_debut DESC
     )
SELECT
    ma.acteur_uid                                                AS depute_uid,
    ma.legislature,
    EXTRACT(YEAR FROM AGE(lr.date_reference, a.date_naissance))::int AS age
FROM mandats_actifs ma
         INNER JOIN acteurs a ON a.uid = ma.acteur_uid
         INNER JOIN legislature_ref lr ON lr.legislature = ma.legislature
WHERE a.date_naissance IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS agg_deputes_stats_age_uq ON agg_deputes_stats_age (depute_uid, legislature);
