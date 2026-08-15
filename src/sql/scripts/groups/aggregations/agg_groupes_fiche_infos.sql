-- OK VALIDE

CREATE MATERIALIZED VIEW IF NOT EXISTS agg_groupes_fiche_infos AS
WITH total_effectifs AS (SELECT ael.legislature,
                                SUM(ael.nb_acteurs_photo) AS total_nb_acteurs_photo
                         FROM agg_groupes_effectifs_legislature ael
                         GROUP BY ael.legislature)
SELECT rg.groupe_id,
       rg.groupe_legislature             AS legislature,
       rg.libelle                        AS groupe_label,
       rg.code                           AS groupe_code,
       NULL::text                         AS groupe_position,
       COALESCE(ael.nb_acteurs_photo, 0) AS groupe_count_members,
       ael.groupe_rank                   AS groupe_rank,
       NULL::text                        AS groupe_year_of_creation,
       NULL::text                        AS groupe_web_site,
       NULL::text                        AS groupe_color,
       CONCAT_WS(' ', gp.prenom, gp.nom) AS groupe_president_full_name,
       COALESCE(REPLACE(gp.lib_qualite_sex, ' du', ''), '') AS groupe_quality_sex_label,
       CASE
           WHEN te.total_nb_acteurs_photo IS NULL OR te.total_nb_acteurs_photo = 0 THEN 0::numeric
           ELSE ROUND(
                   (COALESCE(ael.nb_acteurs_photo, 0)::numeric / te.total_nb_acteurs_photo::numeric) * 100,
                   2
                )
           END                           AS groupe_seats_share_percent
FROM ref_groupes rg
         LEFT JOIN agg_groupes_effectifs_legislature ael
                   ON ael.groupe_id = rg.groupe_id
                       AND ael.legislature = rg.groupe_legislature
         LEFT JOIN total_effectifs te
                   ON te.legislature = rg.groupe_legislature
         LEFT JOIN mv_groupes_presidents gp
                   ON gp.groupe_id = rg.groupe_id
                       AND gp.legislature = rg.groupe_legislature;

CREATE UNIQUE INDEX IF NOT EXISTS idx_agg_groupes_fiche_infos_unique
    ON agg_groupes_fiche_infos (groupe_id, groupe_code, legislature);