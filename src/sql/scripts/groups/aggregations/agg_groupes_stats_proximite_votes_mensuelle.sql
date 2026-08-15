-- PAS ENCORE VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_proximite_votes_mensuelle
-- ============================================================
-- Proximité mensuelle de vote entre groupes parlementaires
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_proximite_votes_mensuelle AS
WITH positions_politiques AS (
    SELECT
        sg.scrutin_uid,
        sg.groupe_id,
        sg.groupe_legislature AS legislature,
        sg.position_majoritaire,
        date_trunc('month', s.date_scrutin)::date AS mois
    FROM scrutins_groupes sg
             INNER JOIN scrutins s
                        ON s.uid = sg.scrutin_uid
    WHERE sg.position_majoritaire IN ('pour', 'contre', 'abstention')
      AND s.date_scrutin IS NOT NULL
),
     paires_groupes AS (
         SELECT
             a.legislature,
             a.mois,
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
             pg.mois,
             pg.groupe_a_id,
             pg.groupe_b_id,
             COUNT(*) AS nb_scrutins_communs,
             COUNT(*) FILTER (
                 WHERE pg.position_a = pg.position_b
                 ) AS nb_scrutins_alignes
         FROM paires_groupes pg
         GROUP BY
             pg.legislature,
             pg.mois,
             pg.groupe_a_id,
             pg.groupe_b_id
     )
SELECT
    pb.legislature,
    pb.mois,
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

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_proximite_votes_mensuelle_uq ON agg_groupes_stats_proximite_votes_mensuelle (legislature, mois, groupe_a_id, groupe_b_id);