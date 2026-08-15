-- OK VALIDE MAIS IL SEMBLE MANQUER 2 MEMBRES , 1 DANS NI-17 , 1 DANS LIOT

-- ============================================================
-- VIEW : agg_groupes_effectifs_current
-- ============================================================
-- Effectif actuel / de référence des groupes parlementaires
--
-- Logique :
--   - Pour chaque législature, on définit une date de référence :
--       * CURRENT_DATE pour la législature en cours
--       * end_date pour les législatures terminées
--   - On reconstitue les appartenances actives à cette date
--   - Un acteur ne compte qu'une seule fois par groupe
--
-- Colonnes :
--   - groupe_id     : identifiant technique du groupe
--   - legislature   : législature du groupe
--   - libelle       : nom du groupe
--   - code          : code court du groupe
--   - nb_acteurs    : nombre de membres du groupe à la date de référence
--
-- Remarque :
--   - Cette vue donne une "photo" du groupe :
--       * photo actuelle pour la législature en cours
--       * photo de fin de législature pour les législatures passées
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_effectifs_current AS
WITH legislatures_ref AS (
    SELECT pl.number AS legislature,
           CASE
               WHEN pl.number IN (SELECT number FROM param_current_legislatures)
                   THEN CURRENT_DATE
               ELSE pl.end_date
           END AS date_reference
    FROM param_legislatures pl
),
members_at_ref_date AS (
    SELECT ag.groupe_id,
           ag.groupe_legislature,
           ag.acteur_uid
    FROM acteurs_groupes ag
    INNER JOIN legislatures_ref lr
        ON lr.legislature = ag.groupe_legislature
    WHERE lr.date_reference IS NOT NULL
      AND ag.date_debut <= lr.date_reference
      AND (ag.date_fin IS NULL OR ag.date_fin >= lr.date_reference)
),
grouped AS (
    SELECT m.groupe_id,
           m.groupe_legislature         AS legislature,
           rg.libelle,
           rg.code,
           COUNT(DISTINCT m.acteur_uid) AS nb_acteurs
    FROM members_at_ref_date m
    LEFT JOIN ref_groupes rg
        ON rg.groupe_id = m.groupe_id
    GROUP BY m.groupe_id,
             m.groupe_legislature,
             rg.libelle,
             rg.code
)
SELECT groupe_id,
       legislature,
       libelle,
       code,
       nb_acteurs,
       RANK() OVER (PARTITION BY legislature ORDER BY nb_acteurs DESC)::integer AS groupe_rank
FROM grouped;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_effectifs_current_uq ON agg_groupes_effectifs_current(groupe_id, legislature);