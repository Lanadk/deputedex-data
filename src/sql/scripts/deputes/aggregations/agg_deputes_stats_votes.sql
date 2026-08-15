-- ============================================================
-- VIEW : agg_deputes_stats_votes
-- ============================================================
-- Synthèse des statistiques de vote d'un député, par législature
--
-- Logique :
--   - Agrège les positions de vote du député sur l'ensemble des
--     scrutins de la législature
--   - Calcule la fidélité au groupe : part des votes alignés avec
--     la position majoritaire du groupe, parmi les votes exprimés
--     (hors non-votants) sur les scrutins où le groupe a une
--     position majoritaire connue
--   - Calcule la participation : part des scrutins où le député a
--     exprimé une position (pour / contre / abstention), parmi
--     l'ensemble de ses votes enregistrés
--
-- Colonnes :
--   - depute_uid           : identifiant technique du député
--   - legislature          : législature (legislature_snapshot du scrutin)
--   - total_votes          : nombre total de votes enregistrés
--   - total_pour           : nombre de votes "pour"
--   - total_contre         : nombre de votes "contre"
--   - total_abstentions    : nombre de votes "abstention"
--   - total_non_votants    : nombre de "non votant"
--   - total_rebel          : nombre de votes en désaccord avec la
--                            position majoritaire du groupe
--   - taux_fidelite        : % de votes alignés avec le groupe
--   - taux_participation   : % de votes exprimés (hors non-votants)
-- ============================================================

CREATE MATERIALIZED VIEW agg_deputes_stats_votes AS
SELECT
    vd.depute_id                                                                          AS depute_uid,
    s.legislature_snapshot                                                                AS legislature,

    COUNT(*)                                                                              AS total_votes,
    COUNT(*) FILTER (WHERE vd.position = 'pour')                                          AS total_pour,
    COUNT(*) FILTER (WHERE vd.position = 'contre')                                        AS total_contre,
    COUNT(*) FILTER (WHERE vd.position = 'abstention')                                    AS total_abstentions,
    COUNT(*) FILTER (WHERE vd.position = 'non_votant')                                    AS total_non_votants,
    COUNT(*) FILTER (WHERE sg.position_majoritaire IS NOT NULL
                        AND vd.position != sg.position_majoritaire
                        AND vd.position != 'non_votant')                                  AS total_rebel,

    ROUND(
        COUNT(*) FILTER (WHERE sg.position_majoritaire IS NOT NULL
                            AND vd.position = sg.position_majoritaire)
            * 100.0 / NULLIF(
                COUNT(*) FILTER (WHERE sg.position_majoritaire IS NOT NULL
                                    AND vd.position != 'non_votant'), 0
            ), 1
    )                                                                                      AS taux_fidelite,

    ROUND(
        COUNT(*) FILTER (WHERE vd.position != 'non_votant')
            * 100.0 / NULLIF(COUNT(*), 0), 1
    )                                                                                      AS taux_participation

FROM votes_deputes vd
         JOIN scrutins s
              ON s.uid = vd.scrutin_uid
         LEFT JOIN scrutins_groupes sg
                   ON sg.scrutin_uid = vd.scrutin_uid
                       AND sg.groupe_id = vd.groupe_id
GROUP BY
    vd.depute_id,
    s.legislature_snapshot;

CREATE UNIQUE INDEX ON agg_deputes_stats_votes (depute_uid, legislature);