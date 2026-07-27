-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_proximite_votes_legislature
-- ============================================================
-- Proximité de vote entre groupes parlementaires
--
-- Logique :
--   - Pour chaque paire de groupes d'une même législature,
--     on compare leur position majoritaire sur les scrutins communs
--   - Seules les positions politiques explicites sont prises en compte :
--       * pour
--       * contre
--       * abstention
--   - La proximité est mesurée comme la part de scrutins communs
--     où les deux groupes adoptent la même position majoritaire
--
-- Colonnes :
--   - legislature                  : législature
--   - groupe_a_id                  : identifiant technique du groupe A
--   - groupe_a_code                : code court du groupe A
--   - groupe_a_libelle             : nom du groupe A
--   - groupe_b_id                  : identifiant technique du groupe B
--   - groupe_b_code                : code court du groupe B
--   - groupe_b_libelle             : nom du groupe B
--   - nb_scrutins_communs          : nombre de scrutins politiques comparables
--   - nb_scrutins_alignes          : nombre de scrutins avec même position
--   - taux_proximite               : score de proximité entre 0 et 1
-- ============================================================

CREATE MATERIALIZED VIEW agg_groupes_stats_proximite_votes_legislature AS
WITH positions_politiques AS (
    SELECT
        sg.scrutin_uid,
        sg.groupe_id,
        sg.groupe_legislature AS legislature,
        sg.position_majoritaire
    FROM scrutins_groupes sg
    WHERE sg.position_majoritaire IN ('pour', 'contre', 'abstention')
),
     paires_groupes AS (
         SELECT
             a.legislature,
             a.scrutin_uid,
             a.groupe_id AS groupe_a_id,
             b.groupe_id AS groupe_b_id,
             a.position_majoritaire AS position_a,
             b.position_majoritaire AS position_b
         FROM positions_politiques a
                  INNER JOIN positions_politiques b
                             ON b.scrutin_uid = a.scrutin_uid
                                 AND b.legislature = a.legislature
                                 AND a.groupe_id < b.groupe_id
     ),
     proximite_base AS (
         SELECT
             pg.legislature,
             pg.groupe_a_id,
             pg.groupe_b_id,
             COUNT(*) AS nb_scrutins_communs,
             COUNT(*) FILTER (
                 WHERE pg.position_a = pg.position_b
                 ) AS nb_scrutins_alignes
         FROM paires_groupes pg
         GROUP BY
             pg.legislature,
             pg.groupe_a_id,
             pg.groupe_b_id
     )
SELECT
    pb.legislature,
    pb.groupe_a_id,
    rga.code AS groupe_a_code,
    rga.libelle AS groupe_a_libelle,
    pb.groupe_b_id,
    rgb.code AS groupe_b_code,
    rgb.libelle AS groupe_b_libelle,
    pb.nb_scrutins_communs,
    pb.nb_scrutins_alignes,
    ROUND(
            pb.nb_scrutins_alignes::numeric
                / NULLIF(pb.nb_scrutins_communs, 0),
            4
    ) AS taux_proximite
FROM proximite_base pb
         LEFT JOIN ref_groupes rga
                   ON rga.groupe_id = pb.groupe_a_id
                       AND rga.groupe_legislature = pb.legislature
         LEFT JOIN ref_groupes rgb
                   ON rgb.groupe_id = pb.groupe_b_id
                       AND rgb.groupe_legislature = pb.legislature;

CREATE UNIQUE INDEX ON agg_groupes_stats_proximite_votes_legislature (legislature, groupe_a_id, groupe_b_id);