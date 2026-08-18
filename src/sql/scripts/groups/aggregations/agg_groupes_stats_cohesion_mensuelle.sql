-- PAS ENCORE VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_cohesion_mensuelle
-- ============================================================
-- Cohésion politique mensuelle des groupes parlementaires
--
-- Logique :
--   - Pour chaque groupe et chaque mois, on compare :
--       * le vote individuel du député
--       * la position majoritaire politique du groupe sur le scrutin
--   - Sont pris en compte uniquement les votes politiques explicites :
--       * pour
--       * contre
--       * abstention
--   - Exclusion :
--       * des scrutins sans position majoritaire politique exploitable
--       * des votes individuels non politiques (non-votant, etc.)
--   - Le taux de cohésion final est la moyenne NON pondérée des taux
--     de cohésion par scrutin (chaque scrutin = une observation,
--     quel que soit son nombre de votants) — convention standard des
--     indices de cohésion parlementaire (indice de Rice / Agreement
--     Index, cf. méthodologie VoteWatch Europe et Hix/Noury/Roland)
--   - Le taux de cohésion est exprimé sur une échelle de 0 à 1 :
--       * 1    = alignement parfait
--       * 0.83 = 83 % des votes alignés
--
-- Colonnes :
--   - groupe_id            : identifiant technique du groupe
--   - legislature          : législature
--   - code                 : code court du groupe
--   - libelle              : nom du groupe
--   - mois                 : mois d'observation
--   - nb_scrutins_mois     : nombre de scrutins du mois pris en compte
--   - nb_votes_eligibles   : nombre de votes individuels comparables
--   - nb_votes_alignes     : nombre de votes alignés avec la majorité du groupe
--   - taux_cohesion        : score de cohésion, entre 0 et 1
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_cohesion_mensuelle AS
WITH cohesion_par_scrutin AS (
                              SELECT vd.groupe_id,
                                     vd.groupe_legislature                     AS legislature,
                                     vd.scrutin_uid,
                                     date_trunc('month', s.date_scrutin)::date AS mois,
                                     COUNT(*) FILTER (
                                         WHERE sg.position_majoritaire IN ('pour', 'contre', 'abstention')
                                             AND vd.position IN ('pour', 'contre', 'abstention')
                                         )                                     AS nb_votes_eligibles,
                                     COUNT(*) FILTER (
                                         WHERE sg.position_majoritaire IN ('pour', 'contre', 'abstention')
                                             AND vd.position = sg.position_majoritaire
                                         )                                     AS nb_votes_alignes
                              FROM votes_deputes vd
                                       INNER JOIN scrutins_groupes sg
                                                  ON sg.scrutin_uid = vd.scrutin_uid
                                                      AND sg.groupe_id = vd.groupe_id
                                                      AND sg.groupe_legislature = vd.groupe_legislature
                                       INNER JOIN scrutins s
                                                  ON s.uid = vd.scrutin_uid
                                       INNER JOIN scrutins_groupes_agregats sga
                                                  ON sga.scrutin_uid = vd.scrutin_uid
                                                      AND sga.groupe_id = vd.groupe_id
                                                      AND sga.groupe_legislature = vd.groupe_legislature
                              WHERE vd.groupe_id IS NOT NULL
                                AND s.date_scrutin IS NOT NULL
                                AND (
                                        COALESCE(sga.pour, 0)
                                            + COALESCE(sga.contre, 0)
                                            + COALESCE(sga.abstentions, 0)
                                        ) >= 5
                              GROUP BY vd.groupe_id,
                                       vd.groupe_legislature,
                                       vd.scrutin_uid,
                                       date_trunc('month', s.date_scrutin)::date),
     cohesion_par_scrutin_calculee AS (SELECT cps.groupe_id,
                                              cps.legislature,
                                              cps.scrutin_uid,
                                              cps.mois,
                                              cps.nb_votes_eligibles,
                                              cps.nb_votes_alignes,
                                              cps.nb_votes_alignes::numeric / NULLIF(cps.nb_votes_eligibles, 0) AS taux_cohesion_scrutin
                                       FROM cohesion_par_scrutin cps
                                       WHERE cps.nb_votes_eligibles > 0)
SELECT c.groupe_id,
       c.legislature,
       rg.code,
       rg.libelle,
       c.mois,
       COUNT(DISTINCT c.scrutin_uid)          AS nb_scrutins_mois,
       SUM(c.nb_votes_eligibles)              AS nb_votes_eligibles,
       SUM(c.nb_votes_alignes)                AS nb_votes_alignes,
       ROUND(AVG(c.taux_cohesion_scrutin), 4) AS taux_cohesion
FROM cohesion_par_scrutin_calculee c
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = c.groupe_id
                       AND rg.groupe_legislature = c.legislature
GROUP BY c.groupe_id,
         c.legislature,
         rg.code,
         rg.libelle,
         c.mois;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_cohesion_mensuelle_uq ON agg_groupes_stats_cohesion_mensuelle (groupe_id, legislature, mois);