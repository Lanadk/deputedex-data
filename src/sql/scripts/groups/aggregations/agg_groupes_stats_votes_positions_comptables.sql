-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_votes_positions_comptables
-- ============================================================
-- Répartition comptable des positions de vote par groupe parlementaire
--
-- En d'autres termes :
--   dans ce groupe, sur l’ensemble des positions observées,
--   X% sont des votes pour, Y% contre, Z% abstentions,
--   A% non votants, B% non votants volontaires
--
-- Logique :
--   - Agrégation des votes individuels des députés
--   - Prise en compte de toutes les positions observées :
--       * pour
--       * contre
--       * abstention
--       * non_votant
--       * non_votant_volontaire
--   - Calcul du volume total de positions par groupe et législature
--   - Calcul du pourcentage de chaque position
--
-- Colonnes :
--   - groupe_id     : identifiant technique du groupe
--   - libelle       : nom du groupe (référentiel)
--   - code          : code court du groupe
--   - legislature   : législature du groupe
--   - position      : position de vote
--   - nb_votes      : nombre de votes pour cette position
--   - total_votes   : total des positions du groupe
--   - pourcentage   : part (%) de cette position dans l’ensemble des positions du groupe
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_votes_positions_comptables AS
WITH positions AS (SELECT sga.groupe_id,
                          sga.groupe_legislature     AS legislature,
                          'pour'                     AS position,
                          SUM(COALESCE(sga.pour, 0)) AS nb_votes
                   FROM scrutins_groupes_agregats sga
                   GROUP BY sga.groupe_id, sga.groupe_legislature

                   UNION ALL

                   SELECT sga.groupe_id,
                          sga.groupe_legislature       AS legislature,
                          'contre'                     AS position,
                          SUM(COALESCE(sga.contre, 0)) AS nb_votes
                   FROM scrutins_groupes_agregats sga
                   GROUP BY sga.groupe_id, sga.groupe_legislature

                   UNION ALL

                   SELECT sga.groupe_id,
                          sga.groupe_legislature            AS legislature,
                          'abstention'                      AS position,
                          SUM(COALESCE(sga.abstentions, 0)) AS nb_votes
                   FROM scrutins_groupes_agregats sga
                   GROUP BY sga.groupe_id, sga.groupe_legislature

                   UNION ALL

                   SELECT sga.groupe_id,
                          sga.groupe_legislature            AS legislature,
                          'non_votant'                      AS position,
                          SUM(COALESCE(sga.non_votants, 0)) AS nb_votes
                   FROM scrutins_groupes_agregats sga
                   GROUP BY sga.groupe_id, sga.groupe_legislature

                   UNION ALL

                   SELECT sga.groupe_id,
                          sga.groupe_legislature                        AS legislature,
                          'non_votant_volontaire'                       AS position,
                          SUM(COALESCE(sga.non_votants_volontaires, 0)) AS nb_votes
                   FROM scrutins_groupes_agregats sga
                   GROUP BY sga.groupe_id, sga.groupe_legislature)
SELECT p.groupe_id,
       rg.libelle,
       rg.code,
       p.legislature,
       p.position,
       p.nb_votes,
       SUM(p.nb_votes) OVER (
           PARTITION BY p.groupe_id, p.legislature
           ) AS total_votes,
       ROUND(
               p.nb_votes::numeric * 100
                   / NULLIF(
                               SUM(p.nb_votes) OVER (
                           PARTITION BY p.groupe_id, p.legislature
                           ),
                               0
                     ),
               2
       )     AS pourcentage
FROM positions p
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = p.groupe_id
                       AND rg.groupe_legislature = p.legislature;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_votes_positions_comptables_uq ON agg_groupes_stats_votes_positions_comptables (groupe_id, legislature, position);