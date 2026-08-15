-- ============================================================
-- VIEW : agg_acteurs_stats_geographie_naissance
-- ============================================================
-- Répartition des députés par département et pays de naissance
-- pour chaque législature et type d'organe.
--
-- Logique de filtrage des mandats :
--   - Legislature courante : uniquement les mandats actifs (date_fin IS NULL)
--   - Legislatures archivées : tous les députés ayant siégé
--   - type_organe : pas de filtre, tous les organes sont inclus
--                   le filtrage se fait côté front selon le contexte
--
-- Colonnes :
--   - legislature              : numéro de la législature
--   - type_organe              : type d'organe parlementaire
--   - pays_naissance           : pays de naissance
--   - departement_naissance    : département de naissance
--   - nb_acteurs               : nombre de députés pour cette origine
--   - total_legislature        : total des députés de la législature
--   - pourcentage              : part en % sur le total de la législature
--
-- Usage : origine géographique des députés, diversité territoriale
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_acteurs_stats_geographie_naissance AS
SELECT m.legislature,
       m.type_organe,
       a.pays_naissance,
       a.departement_naissance,
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
WHERE a.pays_naissance IS NOT NULL
GROUP BY m.legislature, m.type_organe, a.pays_naissance, a.departement_naissance;

-- agg_acteurs_stats_geographie_naissance
CREATE UNIQUE INDEX IF NOT EXISTS agg_acteurs_stats_geographie_naissance_uq ON agg_acteurs_stats_geographie_naissance(legislature, type_organe, pays_naissance, departement_naissance);