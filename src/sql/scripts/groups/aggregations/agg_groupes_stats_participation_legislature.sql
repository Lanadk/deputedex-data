-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_participation_legislature
-- ============================================================
-- Synthèse de la participation des députés par groupe
-- à l’échelle de la législature
--
-- Ratio pondéré global
-- Logique :
--   - Reconstitue, pour chaque député, les scrutins auxquels il
--     pouvait participer pendant qu’il appartenait au groupe
--   - Calcule le nombre de scrutins éligibles et le nombre de
--     scrutins effectivement participés (pour / contre / abstention)
--   - Agrège ensuite au niveau groupe / législature
--   - Le taux final correspond à une moyenne pondérée par le nombre
--     réel de scrutins éligibles, et non à une moyenne simple des mois
--
-- Colonnes :
--   - groupe_id                      : identifiant technique du groupe
--   - legislature                    : législature
--   - code                           : code court du groupe
--   - libelle                        : nom du groupe
--   - nb_deputes_concernes           : nombre de députés concernés
--   - nb_scrutins_eligibles_total    : nombre total de scrutins éligibles cumulés
--   - nb_scrutins_participes_total   : nombre total de scrutins participés cumulés
--   - taux_participation_legislature : taux de participation global du groupe
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_participation_legislature AS
WITH scrutins_legislature AS (SELECT s.uid                  AS scrutin_uid,
                                     s.legislature_snapshot AS legislature,
                                     s.date_scrutin
                              FROM scrutins s
                              WHERE s.date_scrutin IS NOT NULL),
     groupe_membres_scrutins AS (SELECT sl.scrutin_uid,
                                        sl.legislature,
                                        ag.groupe_id,
                                        ag.groupe_legislature,
                                        ag.acteur_uid AS depute_id
                                 FROM scrutins_legislature sl
                                          INNER JOIN acteurs_groupes ag
                                                     ON ag.groupe_legislature = sl.legislature
                                                         AND ag.date_debut <= sl.date_scrutin
                                                         AND (ag.date_fin IS NULL OR ag.date_fin >= sl.date_scrutin)),
     participations_individuelles AS (SELECT gms.groupe_id,
                                             gms.groupe_legislature          AS legislature,
                                             gms.depute_id,
                                             COUNT(DISTINCT gms.scrutin_uid) AS nb_scrutins_eligibles,
                                             COUNT(DISTINCT gms.scrutin_uid) FILTER (
                                                 WHERE vd.position IN ('pour', 'contre', 'abstention')
                                                 )                           AS nb_scrutins_participes
                                      FROM groupe_membres_scrutins gms
                                               LEFT JOIN votes_deputes vd
                                                         ON vd.scrutin_uid = gms.scrutin_uid
                                                             AND vd.depute_id = gms.depute_id
                                                             AND vd.groupe_id = gms.groupe_id
                                                             AND vd.groupe_legislature = gms.groupe_legislature
                                      GROUP BY gms.groupe_id,
                                               gms.groupe_legislature,
                                               gms.depute_id)
SELECT pi.groupe_id,
       pi.legislature,
       rg.code,
       rg.libelle,
       COUNT(*)                       AS nb_deputes_concernes,
       SUM(pi.nb_scrutins_eligibles)  AS nb_scrutins_eligibles_total,
       SUM(pi.nb_scrutins_participes) AS nb_scrutins_participes_total,
       ROUND(
               SUM(pi.nb_scrutins_participes)::numeric
                   / NULLIF(SUM(pi.nb_scrutins_eligibles), 0) * 100,
               2
       )                              AS taux_participation_legislature
FROM participations_individuelles pi
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = pi.groupe_id
                       AND rg.groupe_legislature = pi.legislature
GROUP BY pi.groupe_id,
         pi.legislature,
         rg.code,
         rg.libelle;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_participation_legislature_uq ON agg_groupes_stats_participation_legislature (groupe_id, legislature);