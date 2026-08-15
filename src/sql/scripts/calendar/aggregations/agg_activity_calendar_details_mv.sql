CREATE MATERIALIZED VIEW IF NOT EXISTS agg_activity_calendar_details_mv AS

-- =========================
-- DEPUTE : VOTES
-- =========================
SELECT
    'depute'::varchar       AS entity_type,
    vd.depute_id            AS entity_id,
    s.date_scrutin::date    AS activity_date,
    'vote'::varchar         AS domain,
    vd.legislature_snapshot AS legislature,
    s.uid                   AS ref_id,

    jsonb_build_object(
            'type', 'vote',
            'scrutin_uid', s.uid,
            'titre', s.titre,
            'date', s.date_scrutin,
            'position', vd.position,
            'resultat', s.resultat_libelle
    ) AS meta

FROM votes_deputes vd
         JOIN scrutins s ON s.uid = vd.scrutin_uid
WHERE s.date_scrutin IS NOT NULL

UNION ALL

-- =========================
-- GROUPE : SCRUTINS
-- =========================
SELECT
    'groupe',
    sg.groupe_id,
    s.date_scrutin::date,
    'scrutin',
    s.legislature_snapshot,
    s.uid,

    jsonb_build_object(
            'type', 'scrutin',
            'scrutin_uid', s.uid,
            'titre', s.titre,
            'date', s.date_scrutin,
            'position_majoritaire', sg.position_majoritaire,
            'resultat', s.resultat_libelle
    )

FROM scrutins s
         JOIN scrutins_groupes sg ON sg.scrutin_uid = s.uid
WHERE s.date_scrutin IS NOT NULL

UNION ALL

-- =========================
-- DEPUTE : AMENDEMENTS (AUTEUR)
-- =========================
SELECT
    'depute',
    a.acteur_uid,
    a.date_depot::date,
    'amendement',
    a.legislature_snapshot,
    a.uid,

    jsonb_build_object(
            'type', 'amendement',
            'amendement_uid', a.uid,
            'numero', a.numero_long,
            'date', a.date_depot,
            'sort', a.sort,
            'auteur', true
    )

FROM amendements a
WHERE a.date_depot IS NOT NULL
  AND a.acteur_uid IS NOT NULL

UNION ALL

-- =========================
-- DEPUTE : AMENDEMENTS (CO-AUTEUR)
-- =========================
SELECT
    'depute',
    ca.acteur_uid,
    a.date_depot::date,
    'amendement_co',
    a.legislature_snapshot,
    a.uid,

    jsonb_build_object(
            'type', 'amendement',
            'amendement_uid', a.uid,
            'numero', a.numero_long,
            'date', a.date_depot,
            'sort', a.sort,
            'auteur', false
    )

FROM amendements_co_auteurs ca
         JOIN amendements a ON a.uid = ca.amendement_uid
WHERE a.date_depot IS NOT NULL;

-- REFRESH CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS agg_activity_calendar_details_mv_uq
    ON agg_activity_calendar_details_mv (entity_type, entity_id, domain, ref_id);

-- PERFORMANCE DE LOOKUP
CREATE INDEX IF NOT EXISTS agg_activity_calendar_details_mv_lookup
    ON agg_activity_calendar_details_mv (entity_id, entity_type, activity_date, legislature);