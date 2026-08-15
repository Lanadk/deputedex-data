CREATE MATERIALIZED VIEW IF NOT EXISTS agg_deputes_cards AS
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
     -- Groupe parlementaire actif à la date de référence (photo "à jour").
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
     ),
     -- Fallback : dernier groupe parlementaire connu du député pour cette
     -- législature (date_debut la plus récente), même si son mandat GP
     -- s'est terminé avant la date de référence. Couvre les fins de mandat
     -- GP anticipées (reprise de siège par un ministre revenant de fonction,
     -- nomination au Gouvernement, démission, annulation d'élection...) :
     -- sans ce fallback, un député dans ce cas ressort avec un groupe NULL
     -- alors qu'il a bien appartenu à un groupe pendant la législature.
     -- N'est utilisé que quand groupes_actifs ne trouve rien (cf. LEFT JOIN
     -- ci-dessous), donc n'affecte jamais un député dont le groupe est actif.
     groupes_derniers_connus AS (
         SELECT DISTINCT ON (ag.acteur_uid, ag.groupe_legislature)
             ag.acteur_uid,
             ag.groupe_legislature AS legislature,
             ag.groupe_id,
             ag.date_fin
         FROM acteurs_groupes ag
                  INNER JOIN legislature_ref lr ON lr.legislature = ag.groupe_legislature
         ORDER BY ag.acteur_uid, ag.groupe_legislature, ag.date_debut DESC
     )
SELECT
    a.uid                                 AS depute_uid,
    CONCAT(a.prenom, ' ', a.nom)          AS depute_full_name,
    COALESCE(rg.code, rg_last.code)       AS depute_groupe_code,
    COALESCE(rap.photo_path, '')          AS depute_image,
    NULLIF(ma.role, 'Député')             AS depute_role,
    ma.legislature,
    -- true  : depute_groupe_code reflète l'appartenance active à la date de
    --         référence (comportement historique de la vue).
    -- false : aucun mandat GP actif à la date de référence n'a été trouvé ;
    --         depute_groupe_code (s'il est renseigné) provient du dernier
    --         mandat GP connu du député, qui est donc terminé.
    (ga.groupe_id IS NOT NULL)            AS depute_groupe_actif,
    -- Date de fin du mandat GP utilisé, uniquement quand depute_groupe_actif
    -- est false (NULL sinon, y compris quand aucun groupe n'a pu être trouvé).
    CASE WHEN ga.groupe_id IS NULL THEN gd.date_fin END AS depute_groupe_fin_mandat
FROM mandats_actifs ma
         INNER JOIN acteurs a ON a.uid = ma.acteur_uid
         LEFT JOIN groupes_actifs ga
                   ON ga.acteur_uid = ma.acteur_uid
                       AND ga.legislature = ma.legislature
         LEFT JOIN groupes_derniers_connus gd
                   ON gd.acteur_uid = ma.acteur_uid
                       AND gd.legislature = ma.legislature
                       AND ga.groupe_id IS NULL
         LEFT JOIN ref_groupes rg
                   ON rg.groupe_id = ga.groupe_id
                       AND rg.groupe_legislature = ga.legislature
         LEFT JOIN ref_groupes rg_last
                   ON rg_last.groupe_id = gd.groupe_id
                       AND rg_last.groupe_legislature = gd.legislature
         LEFT JOIN ref_acteurs_photos rap
                   ON rap.acteur_uid = a.uid
                       AND rap.legislature = (
                           SELECT MAX(r2.legislature)
                           FROM ref_acteurs_photos r2
                           WHERE r2.acteur_uid = a.uid
                             AND r2.legislature <= ma.legislature
                       );

CREATE UNIQUE INDEX IF NOT EXISTS agg_deputes_cards_uq ON agg_deputes_cards (depute_uid, legislature);