-- ============================================================
-- VIEW : agg_acteurs_stats_genre
-- ============================================================
-- Répartition H/F des députés par législature et type d'organe
--
-- Logique de filtrage des mandats :
--   - Legislature courante : uniquement les mandats actifs (date_fin IS NULL)
--   - Legislatures archivées : tous les députés ayant siégé
--
-- Colonnes :
--   - legislature       : numéro de la législature
--   - type_organe       : type d'organe parlementaire
--   - genre             : 'H' ou 'F' dérivé de la civilité
--   - nb_acteurs        : nombre de députés pour ce genre
--   - total_legislature : total des députés (pour % côté front)
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_acteurs_stats_genre AS
SELECT m.legislature,
       m.type_organe,
       CASE
           WHEN a.civilite = 'M.' THEN 'H'
           WHEN a.civilite = 'Mme' THEN 'F'
           ELSE 'Inconnu'
           END               as genre,
       COUNT(DISTINCT a.uid) as nb_acteurs,
       SUM(COUNT(DISTINCT a.uid)) OVER (
           PARTITION BY m.legislature, m.type_organe
           )                 as total_legislature,
    ROUND(
            COUNT(DISTINCT a.uid)::numeric * 100 /
               SUM(COUNT(DISTINCT a.uid)) OVER (
                   PARTITION BY m.legislature, m.type_organe
                   ), 2
    )                     as pourcentage
FROM acteurs a
         INNER JOIN mandats m ON m.acteur_uid = a.uid
    AND (
                                     m.date_fin IS NULL -- mandat en cours (leg courante)
                                         OR
                                     m.legislature !=
                                     (SELECT number FROM param_current_legislatures) -- pour les legs archivées : prendre tous les mandats de la leg
                                     )
GROUP BY m.legislature, m.type_organe, genre;

-- agg_acteurs_stats_genre
CREATE UNIQUE INDEX IF NOT EXISTS agg_acteurs_stats_genre_uq ON agg_acteurs_stats_genre(legislature, type_organe, genre);