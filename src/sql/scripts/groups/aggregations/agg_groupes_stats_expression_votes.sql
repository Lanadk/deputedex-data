-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_expression_votes
-- ============================================================
-- Participation comptable des groupes parlementaires aux scrutins
--
-- En d'autres termes :
--   dans ce groupe, sur l’ensemble des positions observées,
--   quelle part correspond à une participation politique
--   (pour / contre / abstention) par rapport à l’ensemble des positions
--   (y compris non votants)
--
-- Logique :
--   - Agrégation des positions de vote par groupe à partir des
--     agrégats de scrutin par groupe (scrutins_groupes_agregats)
--   - Distinction entre :
--       * participation politique :
--           - pour
--           - contre
--           - abstention
--       * non participation :
--           - non_votants
--           - non_votants_volontaires
--   - Calcul :
--       * du nombre total de positions politiques
--       * du nombre de non votants
--       * du total de positions observées
--       * du taux d’expression politique
--   - Calcul également de la couverture des scrutins :
--       part des scrutins pour lesquels le groupe dispose d’un agrégat
--
-- Colonnes :
--   - groupe_id                   : identifiant technique du groupe
--   - legislature                 : législature du groupe
--   - code                        : code court du groupe
--   - libelle                     : nom du groupe
--
--   - nb_scrutins                 : nombre de scrutins avec agrégat pour le groupe
--   - nb_scrutins_legislature     : nombre total de scrutins de la législature
--   - taux_couverture_scrutins    : part (%) des scrutins couverts par le groupe
--
--   - nb_positions_participantes  : total des positions politiques (pour/contre/abstention)
--   - nb_non_votants              : total des non votants (incluant volontaires)
--   - total_positions             : total de toutes les positions observées
--
--   - taux_expression_votes       : % de positions politiques
--                                  = participation politique / total positions
--
-- Remarque :
--   - Cette vue est une synthèse globale par groupe et législature
--   - Elle ne donne pas la répartition des positions (voir vues :
--       * agg_groupes_stats_votes_positions_comptables
--       * agg_groupes_stats_votes_positions_politiques)
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_expression_votes AS
WITH scrutins_legislature AS (SELECT s.legislature_snapshot AS legislature,
                                     COUNT(*)               AS nb_scrutins_legislature
                              FROM scrutins s
                              GROUP BY s.legislature_snapshot)
SELECT sg.groupe_id,
       sg.groupe_legislature           AS legislature,
       rg.code,
       rg.libelle,

       -- couverture
       COUNT(DISTINCT sga.scrutin_uid) AS nb_scrutins,

       sl.nb_scrutins_legislature,

       ROUND(
               COUNT(DISTINCT sga.scrutin_uid)::numeric
                   / NULLIF(sl.nb_scrutins_legislature, 0) * 100,
               2
       )                               AS taux_couverture_scrutins,

       -- participation
       SUM(
               COALESCE(sga.pour, 0)
                   + COALESCE(sga.contre, 0)
                   + COALESCE(sga.abstentions, 0)
       )                               AS nb_positions_participantes,

       SUM(
               COALESCE(sga.non_votants, 0)
                   + COALESCE(sga.non_votants_volontaires, 0)
       )                               AS nb_non_votants,

       SUM(
               COALESCE(sga.pour, 0)
                   + COALESCE(sga.contre, 0)
                   + COALESCE(sga.abstentions, 0)
                   + COALESCE(sga.non_votants, 0)
                   + COALESCE(sga.non_votants_volontaires, 0)
       )                               AS total_positions,

       ROUND(
               SUM(
                       COALESCE(sga.pour, 0)
                           + COALESCE(sga.contre, 0)
                           + COALESCE(sga.abstentions, 0)
               )::numeric
                   / NULLIF(
                       SUM(
                               COALESCE(sga.pour, 0)
                                   + COALESCE(sga.contre, 0)
                                   + COALESCE(sga.abstentions, 0)
                                   + COALESCE(sga.non_votants, 0)
                                   + COALESCE(sga.non_votants_volontaires, 0)
                       ),
                       0
                     ) * 100,
               2
       )                               AS taux_expression_votes

FROM scrutins_groupes sg

         LEFT JOIN scrutins_groupes_agregats sga
                   ON sga.scrutin_uid = sg.scrutin_uid
                       AND sga.groupe_id = sg.groupe_id
                       AND sga.groupe_legislature = sg.groupe_legislature

         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = sg.groupe_id
                       AND rg.groupe_legislature = sg.groupe_legislature

         LEFT JOIN scrutins_legislature sl
                   ON sl.legislature = sg.groupe_legislature

GROUP BY sg.groupe_id,
         sg.groupe_legislature,
         rg.code,
         rg.libelle,
         sl.nb_scrutins_legislature;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_expression_votes_uq ON agg_groupes_stats_expression_votes (groupe_id, legislature);