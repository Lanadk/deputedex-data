-- ============================================================
-- VIEW : agg_acteurs_stats_age
-- ============================================================
-- Répartition des députés par tranche d'âge, législature et type d'organe
--
-- Logique de filtrage des mandats :
--   - Legislature courante : uniquement les mandats actifs (date_fin IS NULL)
--   - Legislatures archivées : tous les députés ayant siégé
--
-- Colonnes :
--   - legislature       : numéro de la législature
--   - type_organe       : type d'organe parlementaire
--   - tranche_age       : tranche d'âge (<30, 30-39, 40-49, 50-59, 60-69, 70+)
--   - nb_acteurs        : nombre de députés pour cette tranche
--   - total_legislature : total des députés (pour % côté front)
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_acteurs_stats_age AS
SELECT m.legislature,
       m.type_organe,
       CASE
           WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 30 THEN '<30'
           WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 40 THEN '30-39'
           WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 50 THEN '40-49'
           WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 60 THEN '50-59'
           WHEN EXTRACT(YEAR FROM AGE(a.date_naissance::date)) < 70 THEN '60-69'
           ELSE '70+'
           END               as tranche_age,
       COUNT(DISTINCT a.uid) as nb_acteurs,
       SUM(COUNT(DISTINCT a.uid)) OVER (
           PARTITION BY m.legislature, m.type_organe
           )                 as total_legislature,
    ROUND(
            COUNT(DISTINCT a.uid)::numeric * 100 /
               SUM(COUNT(DISTINCT a.uid)) OVER (
                   PARTITION BY m.legislature, m.type_organe
                   ), 2
    )                     as pourcentage
FROM acteurs a
         INNER JOIN mandats m ON m.acteur_uid = a.uid
    AND (
                                     m.date_fin IS NULL -- mandat en cours (leg courante)
                                         OR
                                     m.legislature !=
                                     (SELECT number FROM param_current_legislatures) -- pour les legs archivées : prendre tous les mandats de la leg
                                     )
WHERE a.date_naissance IS NOT NULL
GROUP BY m.legislature, m.type_organe, tranche_age;

-- agg_acteurs_stats_age
CREATE UNIQUE INDEX IF NOT EXISTS agg_acteurs_stats_age_uq ON agg_acteurs_stats_age(legislature, type_organe, tranche_age);