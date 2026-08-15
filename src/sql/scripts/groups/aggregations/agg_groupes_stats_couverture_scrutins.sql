-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_couverture_scrutins
-- ============================================================
-- Couverture des scrutins par les groupes parlementaires
--
-- Logique :
--   - Mesure la présence institutionnelle d’un groupe
--     dans les scrutins d’une législature
--   - Un groupe est considéré comme "couvert" sur un scrutin
--     dès lors qu’il apparaît dans scrutins_groupes
--   - Comparaison entre :
--       * le nombre de scrutins couverts par le groupe
--       * le nombre total de scrutins de la législature
--
-- Important :
--   - Cette vue mesure une présence structurelle,
--     indépendamment du comportement de vote des membres
--   - Elle est complémentaire à :
--       agg_groupes_stats_votes_participation
--     qui mesure la participation des membres
--
-- Colonnes :
--   - groupe_id                  : identifiant technique du groupe
--   - legislature                : législature du groupe
--   - code                       : code court du groupe
--   - libelle                    : nom du groupe
--   - nb_scrutins_couverts       : nombre de scrutins où le groupe est présent
--   - nb_scrutins_legislature    : nombre total de scrutins dans la législature
--   - taux_couverture_scrutins   : % de scrutins couverts par le groupe
--
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_couverture_scrutins AS
WITH scrutins_legislature AS (SELECT s.legislature_snapshot AS legislature,
                                     COUNT(*)               AS nb_scrutins_legislature
                              FROM scrutins s
                              GROUP BY s.legislature_snapshot)
SELECT rg.groupe_id,
       rg.groupe_legislature          AS legislature,
       rg.code,
       rg.libelle,

       COUNT(DISTINCT sg.scrutin_uid) AS nb_scrutins_couverts,

       sl.nb_scrutins_legislature,

       ROUND(
               COUNT(DISTINCT sg.scrutin_uid)::numeric
                   / NULLIF(sl.nb_scrutins_legislature, 0) * 100,
               2
       )                              AS taux_couverture_scrutins

FROM ref_groupes rg

         LEFT JOIN scrutins_groupes sg
                   ON sg.groupe_id = rg.groupe_id
                       AND sg.groupe_legislature = rg.groupe_legislature

         LEFT JOIN scrutins_legislature sl
                   ON sl.legislature = rg.groupe_legislature

GROUP BY rg.groupe_id,
         rg.groupe_legislature,
         rg.code,
         rg.libelle,
         sl.nb_scrutins_legislature;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_couverture_scrutins_uq ON agg_groupes_stats_couverture_scrutins (groupe_id, legislature);