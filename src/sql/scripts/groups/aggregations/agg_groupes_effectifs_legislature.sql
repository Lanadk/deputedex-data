-- OK VALIDE MAIS IL SEMBLE MANQUER 2 MEMBRES , 1 DANS NI-17 , 1 DANS LIOT

-- ============================================================
-- VIEW : agg_groupes_legislature_effectifs
-- ============================================================
-- Effectifs des groupes parlementaires à l’échelle de la législature
--
-- Logique :
--   - Deux types d’effectifs sont calculés :
--
--  Effectif "photo" :
--        - Nombre de députés appartenant au groupe à une date de référence
--        - Date de référence :
--            * aujourd’hui (CURRENT_DATE) pour la législature en cours
--            * date de fin de législature pour les précédentes
--        - Représente la composition actuelle (ou finale) du groupe
--
--  Effectif "historique" :
--        - Nombre total de députés distincts ayant appartenu au groupe
--          à un moment quelconque de la législature
--        - Permet de mesurer la rotation / renouvellement du groupe
--
-- Colonnes :
--   - groupe_id                           : identifiant technique du groupe
--   - legislature                         : législature
--   - code                                : code court du groupe
--   - libelle                             : nom du groupe
--   - nb_acteurs_photo                    : effectif à date (photo actuelle / fin de législature)
--   - nb_acteurs_distincts_legislature    : nombre total de députés passés dans le groupe
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_effectifs_legislature AS
WITH legislatures_ref AS (
    SELECT pl.number AS legislature,
           CASE
               WHEN pl.number IN (SELECT number FROM param_current_legislatures)
                   THEN CURRENT_DATE
               ELSE pl.end_date
               END AS date_reference
    FROM param_legislatures pl
),
     effectifs_photo AS (
         SELECT ag.groupe_id,
                ag.groupe_legislature         AS legislature,
                COUNT(DISTINCT ag.acteur_uid) AS nb_acteurs_photo
         FROM acteurs_groupes ag
                  INNER JOIN legislatures_ref lr
                             ON lr.legislature = ag.groupe_legislature
         WHERE lr.date_reference IS NOT NULL
           AND ag.date_debut <= lr.date_reference
           AND (ag.date_fin IS NULL OR ag.date_fin >= lr.date_reference)
         GROUP BY ag.groupe_id,
                  ag.groupe_legislature
     ),
     effectifs_historiques AS (
         SELECT ag.groupe_id,
                ag.groupe_legislature         AS legislature,
                COUNT(DISTINCT ag.acteur_uid) AS nb_acteurs_distincts_legislature
         FROM acteurs_groupes ag
         GROUP BY ag.groupe_id,
                  ag.groupe_legislature
     ),
     grouped AS (
         SELECT rg.groupe_id,
                rg.groupe_legislature                            AS legislature,
                rg.code,
                rg.libelle,
                COALESCE(ep.nb_acteurs_photo, 0)                 AS nb_acteurs_photo,
                COALESCE(eh.nb_acteurs_distincts_legislature, 0) AS nb_acteurs_distincts_legislature
         FROM ref_groupes rg
                  LEFT JOIN effectifs_photo ep
                            ON ep.groupe_id = rg.groupe_id
                                AND ep.legislature = rg.groupe_legislature
                  LEFT JOIN effectifs_historiques eh
                            ON eh.groupe_id = rg.groupe_id
                                AND eh.legislature = rg.groupe_legislature
     )
SELECT groupe_id,
       legislature,
       code,
       libelle,
       nb_acteurs_photo,
       nb_acteurs_distincts_legislature,
       RANK() OVER (PARTITION BY legislature ORDER BY nb_acteurs_photo DESC)::integer AS groupe_rank
FROM grouped;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_effectifs_legislature_uq ON agg_groupes_effectifs_legislature (groupe_id, legislature);