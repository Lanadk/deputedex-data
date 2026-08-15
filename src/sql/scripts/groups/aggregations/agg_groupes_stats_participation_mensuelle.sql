-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_participation_mensuelle
-- ============================================================
-- Participation mensuelle moyenne des députés par groupe
--
-- Moyenne des députés par mois
-- Logique :
--   - Pour chaque scrutin, on reconstitue les membres actifs du groupe
--     à la date du scrutin
--   - Pour chaque député actif, on vérifie s'il a participé politiquement
--     au scrutin (pour / contre / abstention)
--   - On calcule ensuite, par mois, le taux de participation de chaque député
--   - Enfin, on calcule la moyenne de ces taux au niveau du groupe
--
-- taux_participation_depute(d, m) =
--     nb_scrutins_participes(d, m)
--     /
--     nb_scrutins_eligibles(d, m)
-- nb_eligibles = nombre de scrutins du mois où le groupe existe et où le député appartient au groupe
-- nb_participes = nombre de ces scrutins où : position ∈ {pour, contre, abstention}
-- taux_participation_groupe(m) = moyenne des taux des députés du groupe
-- taux_participation_groupe(m) = (1 / N) × Σ [ nb_participes(d) / nb_eligibles(d) ]
-- N = nombre de députés du groupe actifs ce mois
--
-- Colonnes :
--   - groupe_id                         : identifiant technique du groupe
--   - legislature                       : législature
--   - code                              : code court du groupe
--   - libelle                           : nom du groupe
--   - mois                              : mois d'observation
--   - nb_deputes_concernes              : nombre de députés actifs concernés
--   - nb_scrutins_mois                  : nombre de scrutins du mois pour le groupe
--   - taux_participation_moyen_deputes  : moyenne mensuelle des taux individuels
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_participation_mensuelle AS
WITH scrutins_mensuels AS (SELECT s.uid                                     AS scrutin_uid,
                                  s.legislature_snapshot                    AS legislature,
                                  s.date_scrutin,
                                  date_trunc('month', s.date_scrutin)::date AS mois
                           FROM scrutins s
                           WHERE s.date_scrutin IS NOT NULL),

     groupe_membres_scrutins AS (SELECT sm.scrutin_uid,
                                        sm.legislature,
                                        sm.mois,
                                        sg.groupe_id,
                                        sg.groupe_legislature,
                                        ag.acteur_uid AS depute_id
                                 FROM scrutins_mensuels sm
                                          INNER JOIN scrutins_groupes sg
                                                     ON sg.scrutin_uid = sm.scrutin_uid
                                                         AND sg.groupe_legislature = sm.legislature
                                          INNER JOIN acteurs_groupes ag
                                                     ON ag.groupe_id = sg.groupe_id
                                                         AND ag.groupe_legislature = sg.groupe_legislature
                                                         AND ag.date_debut <= sm.date_scrutin
                                                         AND (ag.date_fin IS NULL OR ag.date_fin >= sm.date_scrutin)),

     participations_individuelles AS (SELECT gms.groupe_id,
                                             gms.groupe_legislature          AS legislature,
                                             gms.mois,
                                             gms.depute_id,
                                             COUNT(DISTINCT gms.scrutin_uid) AS nb_scrutins_eligibles,
                                             COUNT(DISTINCT gms.scrutin_uid) FILTER (
                                                 WHERE vd.position IN ('pour', 'contre', 'abstention')
                                                 )                           AS nb_scrutins_participes
                                      FROM groupe_membres_scrutins gms
                                               LEFT JOIN votes_deputes vd
                                                         ON vd.scrutin_uid = gms.scrutin_uid
                                                             AND vd.depute_id = gms.depute_id
                                                             AND vd.groupe_legislature = gms.groupe_legislature
                                      GROUP BY gms.groupe_id,
                                               gms.groupe_legislature,
                                               gms.mois,
                                               gms.depute_id),

     participations_groupes_mensuelles AS (SELECT pi.groupe_id,
                                                  pi.legislature,
                                                  pi.mois,
                                                  COUNT(*)                      AS nb_deputes_concernes,
                                                  SUM(pi.nb_scrutins_eligibles) AS nb_scrutins_deputes_cumules,
                                                  ROUND(
                                                          AVG(
                                                                  pi.nb_scrutins_participes::numeric
                                                                      / NULLIF(pi.nb_scrutins_eligibles, 0)
                                                          ) * 100,
                                                          2
                                                  )                             AS taux_participation_moyen_deputes
                                           FROM participations_individuelles pi
                                           GROUP BY pi.groupe_id,
                                                    pi.legislature,
                                                    pi.mois),

     scrutins_groupes_mensuels AS (SELECT sg.groupe_id,
                                          sg.groupe_legislature                     AS legislature,
                                          date_trunc('month', s.date_scrutin)::date AS mois,
                                          COUNT(DISTINCT sg.scrutin_uid)            AS nb_scrutins_mois
                                   FROM scrutins_groupes sg
                                            INNER JOIN scrutins s
                                                       ON s.uid = sg.scrutin_uid
                                   WHERE s.date_scrutin IS NOT NULL
                                   GROUP BY sg.groupe_id,
                                            sg.groupe_legislature,
                                            date_trunc('month', s.date_scrutin)::date)
SELECT pgm.groupe_id,
       pgm.legislature,
       rg.code,
       rg.libelle,
       pgm.mois,
       pgm.nb_deputes_concernes,
       COALESCE(sgm.nb_scrutins_mois, 0) AS nb_scrutins_mois,
       pgm.taux_participation_moyen_deputes
FROM participations_groupes_mensuelles pgm
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = pgm.groupe_id
                       AND rg.groupe_legislature = pgm.legislature
         LEFT JOIN scrutins_groupes_mensuels sgm
                   ON sgm.groupe_id = pgm.groupe_id
                       AND sgm.legislature = pgm.legislature
                       AND sgm.mois = pgm.mois;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_participation_mensuelle_uq ON agg_groupes_stats_participation_mensuelle (groupe_id, legislature, mois);