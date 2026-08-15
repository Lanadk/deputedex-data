-- ============================================================
-- VIEW : agg_acteurs_stats_professions
-- ============================================================
-- Répartition des députés par catégorie et famille de profession
-- pour chaque législature.
--
-- Logique de filtrage des mandats :
--   - Legislature courante : uniquement les mandats actifs (date_fin IS NULL)
--   - Legislatures archivées : tous les députés ayant siégé
--
-- Colonnes :
--   - legislature         : numéro de la législature
--   - type_organe         : type d'organe parlementaire
--   - profession_categorie : catégorie socioprofessionnelle INSEE
--   - profession_famille  : famille socioprofessionnelle INSEE
--   - nb_acteurs          : nombre de députés pour cette profession
--   - total_legislature   : total des députés de la législature
--   - pourcentage         : nb_acteurs / total_legislature * 100
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_acteurs_stats_professions AS
SELECT m.legislature,
       m.type_organe,
       a.profession_categorie,
       a.profession_famille,
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
WHERE a.profession_categorie IS NOT NULL
GROUP BY m.legislature, m.type_organe, a.profession_categorie, a.profession_famille;

-- agg_acteurs_stats_professions
CREATE UNIQUE INDEX IF NOT EXISTS agg_acteurs_stats_professions_uq ON agg_acteurs_stats_professions(legislature, type_organe, profession_categorie, profession_famille);