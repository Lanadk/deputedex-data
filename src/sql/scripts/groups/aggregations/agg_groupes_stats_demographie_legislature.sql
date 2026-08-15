-- OK VALIDE

-- ============================================================
-- VIEW : agg_groupes_stats_demographie_legislature
-- ============================================================
-- Photo démographique des groupes parlementaires par législature
--
-- Logique :
--   - Pour chaque législature, on définit une date de référence :
--       * CURRENT_DATE pour la législature en cours
--       * end_date pour les législatures terminées
--   - On reconstitue les membres actifs du groupe à cette date
--   - On calcule ensuite :
--       * l'effectif du groupe à date
--       * l'âge moyen à date
--       * la répartition hommes / femmes à date
--
-- Remarque :
--   - Le sexe est ici déduit de la civilité :
--       * 'M.'  -> homme
--       * 'Mme' -> femme
--   - Les civilités nulles ou non reconnues sont exclues
--     du calcul des taux hommes / femmes
--
-- Colonnes :
--   - groupe_id      : identifiant technique du groupe
--   - legislature    : législature
--   - code           : code court du groupe
--   - libelle        : nom du groupe
--   - nb_acteurs     : effectif du groupe à la date de référence
--   - age_moyen      : âge moyen des membres du groupe à la date de référence
--   - nb_hommes      : nombre d'hommes à la date de référence
--   - nb_femmes      : nombre de femmes à la date de référence
--   - taux_hommes    : part des hommes parmi les membres sexés du groupe
--   - taux_femmes    : part des femmes parmi les membres sexés du groupe
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_stats_demographie_legislature AS
WITH legislatures_ref AS (SELECT pl.number AS legislature,
                                 CASE
                                     WHEN pl.number IN (SELECT number FROM param_current_legislatures)
                                         THEN CURRENT_DATE
                                     ELSE pl.end_date
                                     END   AS date_reference
                          FROM param_legislatures pl),
     members_at_ref_date AS (SELECT ag.groupe_id,
                                    ag.groupe_legislature AS legislature,
                                    ag.acteur_uid,
                                    a.date_naissance,
                                    a.civilite,
                                    lr.date_reference
                             FROM acteurs_groupes ag
                                      INNER JOIN legislatures_ref lr
                                                 ON lr.legislature = ag.groupe_legislature
                                      INNER JOIN acteurs a
                                                 ON a.uid = ag.acteur_uid
                             WHERE lr.date_reference IS NOT NULL
                               AND ag.date_debut <= lr.date_reference
                               AND (ag.date_fin IS NULL OR ag.date_fin >= lr.date_reference))
SELECT rg.groupe_id,
       rg.groupe_legislature        AS legislature,
       rg.code,
       rg.libelle,
       COUNT(DISTINCT m.acteur_uid) AS nb_acteurs,

       ROUND(AVG(
                     DATE_PART('year', AGE(m.date_reference, m.date_naissance))
             )::numeric, 2)         AS age_moyen,

       COUNT(DISTINCT m.acteur_uid) FILTER (
           WHERE LOWER(TRIM(COALESCE(m.civilite, ''))) IN ('m.')
           )                        AS nb_hommes,

       COUNT(DISTINCT m.acteur_uid) FILTER (
           WHERE LOWER(TRIM(COALESCE(m.civilite, ''))) IN ('mme')
           )                        AS nb_femmes,

       ROUND(
                       COUNT(DISTINCT m.acteur_uid) FILTER (
                   WHERE LOWER(TRIM(COALESCE(m.civilite, ''))) IN ('m.')
                   )::numeric
                   / NULLIF(
                                       COUNT(DISTINCT m.acteur_uid) FILTER (
                                   WHERE LOWER(TRIM(COALESCE(m.civilite, ''))) IN
                                         ('m.', 'mme')
                                   ),
                                       0
                     ) * 100,
                       2
       )                            AS taux_hommes,

       ROUND(
                       COUNT(DISTINCT m.acteur_uid) FILTER (
                   WHERE LOWER(TRIM(COALESCE(m.civilite, ''))) IN ('mme')
                   )::numeric
                   / NULLIF(
                                       COUNT(DISTINCT m.acteur_uid) FILTER (
                                   WHERE LOWER(TRIM(COALESCE(m.civilite, ''))) IN
                                         ('m.', 'mme')
                                   ),
                                       0
                     ) * 100,
                       2
       )                            AS taux_femmes

FROM ref_groupes rg
         LEFT JOIN members_at_ref_date m
                   ON m.groupe_id = rg.groupe_id
                       AND m.legislature = rg.groupe_legislature
GROUP BY rg.groupe_id,
         rg.groupe_legislature,
         rg.code,
         rg.libelle;

CREATE UNIQUE INDEX IF NOT EXISTS agg_groupes_stats_demographie_legislature_uq ON agg_groupes_stats_demographie_legislature (groupe_id, legislature);