CREATE MATERIALIZED VIEW agg_deputes_cards AS
WITH legislature_ref AS (
    SELECT
        pl.number AS legislature,
        CASE
            WHEN pl.number IN (SELECT number FROM param_current_legislatures)
                THEN CURRENT_DATE
            ELSE pl.end_date
            END AS date_reference
    FROM param_legislatures pl
),
     mandats_actifs AS (
         SELECT DISTINCT ON (m.acteur_uid, lr.legislature)
             m.acteur_uid,
             lr.legislature,
             m.lib_qualite AS role
         FROM mandats m
                  INNER JOIN legislature_ref lr ON lr.legislature = m.legislature
         WHERE
             m.type_organe = 'ASSEMBLEE'
           AND m.date_debut <= lr.date_reference
           AND (
             -- Legislature courante : actif aujourd'hui
             m.date_fin IS NULL OR m.date_fin >= lr.date_reference
                 OR
             -- Legislature archivée : a siégé à un moment dans la législature
             lr.legislature NOT IN (SELECT number FROM param_current_legislatures)
             )
         ORDER BY m.acteur_uid, lr.legislature, m.date_debut DESC
     ),
     groupes_actifs AS (
         SELECT DISTINCT ON (ag.acteur_uid, ag.groupe_legislature)
             ag.acteur_uid,
             ag.groupe_legislature AS legislature,
             ag.groupe_id
         FROM acteurs_groupes ag
                  INNER JOIN legislature_ref lr ON lr.legislature = ag.groupe_legislature
         WHERE
             lr.date_reference IS NOT NULL
           AND ag.date_debut <= lr.date_reference
           AND (ag.date_fin IS NULL OR ag.date_fin >= lr.date_reference)
         ORDER BY ag.acteur_uid, ag.groupe_legislature, ag.date_debut DESC
     )
SELECT
    a.uid                           AS depute_uid,
    CONCAT(a.prenom, ' ', a.nom)    AS depute_full_name,
    rg.code                         AS depute_groupe_code,
    COALESCE(rap.photo_path, '')    AS depute_image,
    NULLIF(ma.role, 'Député')       AS depute_role,
    ma.legislature
FROM mandats_actifs ma
         INNER JOIN acteurs a ON a.uid = ma.acteur_uid
         LEFT JOIN groupes_actifs ga
                   ON ga.acteur_uid = ma.acteur_uid
                       AND ga.legislature = ma.legislature
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = ga.groupe_id
                       AND rg.groupe_legislature = ga.legislature
         LEFT JOIN ref_acteurs_photos rap
                   ON rap.acteur_uid = a.uid
                       AND rap.legislature = (
                           SELECT MAX(r2.legislature)
                           FROM ref_acteurs_photos r2
                           WHERE r2.acteur_uid = a.uid
                             AND r2.legislature <= ma.legislature
                       );

CREATE UNIQUE INDEX ON agg_deputes_cards (depute_uid, legislature);