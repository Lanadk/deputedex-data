-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_votes_positions_politiques
-- ============================================================
-- Répartition politique des positions de vote par groupe parlementaire
--
-- En d'autres termes :
--   dans ce groupe, sur l’ensemble des votes politiques observés,
--   X% sont des votes pour, Y% contre, Z% abstentions
--
-- Logique :
--   - Agrégation des votes individuels des députés
--   - Prise en compte uniquement des positions politiques :
--       * pour
--       * contre
--       * abstention
--   - Calcul du volume total de votes politiques par groupe et législature
--   - Calcul du pourcentage de chaque position politique
--
-- Colonnes :
--   - groupe_id     : identifiant technique du groupe
--   - libelle       : nom du groupe (référentiel)
--   - code          : code court du groupe
--   - legislature   : législature du groupe
--   - position      : position politique de vote
--   - nb_votes      : nombre de votes pour cette position
--   - total_votes   : total des votes politiques du groupe
--   - pourcentage   : part (%) de cette position dans les votes politiques du groupe
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_votes_positions_politiques AS
SELECT vd.groupe_id,
       rg.libelle,
       rg.code,
       vd.groupe_legislature AS legislature,
       vd.position,
       COUNT(*)              AS nb_votes,
       SUM(COUNT(*)) OVER (
           PARTITION BY vd.groupe_id, vd.groupe_legislature
           )                 AS total_votes,
       ROUND(
               COUNT(*)::numeric * 100
                   / SUM(COUNT(*)) OVER (
                   PARTITION BY vd.groupe_id, vd.groupe_legislature
                   ),
               2
       )                     AS pourcentage
FROM votes_deputes vd
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = vd.groupe_id
                       AND rg.groupe_legislature = vd.groupe_legislature
WHERE vd.groupe_id IS NOT NULL
  AND vd.position IN ('pour', 'contre', 'abstention')
GROUP BY vd.groupe_id,
         rg.libelle,
         rg.code,
         vd.groupe_legislature,
         vd.position;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_votes_positions_politiques_uq ON agg_groupes_stats_votes_positions_politiques (groupe_id, legislature, position);