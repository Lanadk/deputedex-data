-- PAS ENCORE VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_cohesion_legislature
-- ============================================================
-- Synthèse de la cohésion des groupes parlementaires
-- à l'échelle de la législature
--
-- Logique :
--   - Agrège la cohésion calculée au niveau des scrutins
--   - Le taux de cohésion final correspond à la moyenne des
--     cohésions par scrutin
--   - Le score est exprimé sur une échelle de 0 à 1
--
-- Colonnes :
--   - groupe_id              : identifiant technique du groupe
--   - legislature            : législature
--   - code                   : code court du groupe
--   - libelle                : nom du groupe
--   - nb_scrutins_couverts   : nombre de scrutins pris en compte
--   - nb_votes_eligibles     : nombre total de votes comparables
--   - nb_votes_alignes       : nombre total de votes alignés
--   - taux_cohesion          : score de cohésion, entre 0 et 1
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_cohesion_legislature AS
WITH cohesion_par_scrutin AS (
    SELECT
        vd.groupe_id,
        vd.groupe_legislature AS legislature,
        vd.scrutin_uid,
        COUNT(*) FILTER (
            WHERE sg.position_majoritaire IN ('pour', 'contre', 'abstention')
                AND vd.position IN ('pour', 'contre', 'abstention')
            ) AS nb_votes_eligibles,
        COUNT(*) FILTER (
            WHERE sg.position_majoritaire IN ('pour', 'contre', 'abstention')
                AND vd.position = sg.position_majoritaire
            ) AS nb_votes_alignes
    FROM votes_deputes vd
             INNER JOIN scrutins_groupes sg
                        ON sg.scrutin_uid = vd.scrutin_uid
                            AND sg.groupe_id = vd.groupe_id
                            AND sg.groupe_legislature = vd.groupe_legislature
    WHERE vd.groupe_id IS NOT NULL
    GROUP BY
        vd.groupe_id,
        vd.groupe_legislature,
        vd.scrutin_uid
),
     cohesion_par_scrutin_calculee AS (
         SELECT
             cps.groupe_id,
             cps.legislature,
             cps.scrutin_uid,
             cps.nb_votes_eligibles,
             cps.nb_votes_alignes,
             cps.nb_votes_alignes::numeric / NULLIF(cps.nb_votes_eligibles, 0) AS taux_cohesion_scrutin
         FROM cohesion_par_scrutin cps
         WHERE cps.nb_votes_eligibles > 0
     )
SELECT
    c.groupe_id,
    c.legislature,
    rg.code,
    rg.libelle,
    COUNT(DISTINCT c.scrutin_uid) AS nb_scrutins_couverts,
    SUM(c.nb_votes_eligibles) AS nb_votes_eligibles,
    SUM(c.nb_votes_alignes) AS nb_votes_alignes,
    ROUND(AVG(c.taux_cohesion_scrutin), 4) AS taux_cohesion
FROM cohesion_par_scrutin_calculee c
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = c.groupe_id
                       AND rg.groupe_legislature = c.legislature
GROUP BY
    c.groupe_id,
    c.legislature,
    rg.code,
    rg.libelle;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_cohesion_legislature_uq ON agg_groupes_stats_cohesion_legislature (groupe_id, legislature);