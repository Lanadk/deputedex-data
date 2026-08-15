-- ============================================================
-- VIEW : agg_assemblee_stats_participation_legislature
-- ============================================================
-- Taux de participation moyen de l’Assemblée par législature
--
-- Logique :
--   - On agrège les taux de participation calculés au niveau groupe
--   - Chaque groupe contribue de manière équivalente (moyenne simple)
--   - Le taux groupe est lui-même basé sur :
--       * moyenne des taux individuels par scrutin (logique métier)
--
-- Colonnes :
--   - legislature                               : législature concernée
--   - taux_participation_moyen_assemblee        : participation moyenne de l’ensemble des groupes
--
-- Remarque :
--   - Cet indicateur donne une vision "macro" de la participation
--   - Non pondéré par les effectifs des groupes
--   - Peut différer d’un calcul direct au niveau député
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_assemblee_stats_participation_legislature AS
SELECT
    legislature,
    ROUND(AVG(taux_participation_legislature), 2) AS taux_participation_moyen_assemblee
FROM agg_groupes_stats_participation_legislature
GROUP BY legislature;

CREATE UNIQUE INDEX IF NOT EXISTS agg_assemblee_stats_participation_legislature_uq ON agg_assemblee_stats_participation_legislature (legislature);