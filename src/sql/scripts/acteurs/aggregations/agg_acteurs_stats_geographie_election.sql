-- ============================================================
-- VIEW : agg_acteurs_stats_geographie_election
-- ============================================================
-- Répartition des députés par département et région d'élection
-- pour chaque législature et type d'organe.
--
-- Logique de filtrage des mandats :
--   - Legislature courante : uniquement les mandats actifs (date_fin IS NULL)
--   - Legislatures archivées : tous les députés ayant siégé
--   - type_organe : pas de filtre, tous les organes sont inclus
--                   le filtrage se fait côté front selon le contexte
--
-- Colonnes :
--   - legislature            : numéro de la législature
--   - type_organe            : type d'organe parlementaire
--   - election_region        : région d'élection
--   - election_region_type   : type de région
--   - election_departement   : département d'élection
--   - nb_acteurs             : nombre de députés pour ce territoire
--   - total_legislature      : total des députés de la législature
--   - pourcentage            : part en % sur le total de la législature
--
-- Usage : carte des circonscriptions, répartition territoriale
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_acteurs_stats_geographie_election AS
SELECT m.legislature,
       m.type_organe,
       m.election_region,
       m.election_region_type,
       m.election_departement,
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
WHERE m.election_departement IS NOT NULL
GROUP BY m.legislature, m.type_organe, m.election_region, m.election_region_type, m.election_departement;

-- agg_acteurs_stats_geographie_election
CREATE UNIQUE INDEX IF NOT EXISTS agg_acteurs_stats_geographie_election_uq ON agg_acteurs_stats_geographie_election(legislature, type_organe, election_region, election_departement);