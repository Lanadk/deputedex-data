CREATE MATERIALIZED VIEW IF NOT EXISTS agg_activity_calendar_mv AS

    -- =========================
-- GROUPE : SCRUTINS
-- =========================
SELECT
    'groupe'::varchar      AS entity_type,
    sg.groupe_id           AS entity_id,
    s.date_scrutin::date   AS activity_date,
    'scrutin'::varchar     AS domain,
    COUNT(*)::int          AS count,
    s.legislature_snapshot AS legislature
FROM scrutins s
         JOIN scrutins_groupes sg ON sg.scrutin_uid = s.uid
WHERE s.date_scrutin IS NOT NULL
GROUP BY sg.groupe_id, s.date_scrutin, s.legislature_snapshot

UNION ALL

-- =========================
-- GROUPE : VOTES
-- =========================
SELECT
    'groupe',
    vd.groupe_id,
    s.date_scrutin::date,
    'vote',
    COUNT(*),
    vd.legislature_snapshot
FROM votes_deputes vd
         JOIN scrutins s ON s.uid = vd.scrutin_uid
WHERE s.date_scrutin IS NOT NULL
  AND vd.groupe_id IS NOT NULL
GROUP BY vd.groupe_id, s.date_scrutin, vd.legislature_snapshot

UNION ALL

-- =========================
-- GROUPE : AMENDEMENTS
-- =========================
SELECT
    'groupe',
    a.groupe_politique_ref,
    a.date_depot::date,
    'amendement',
    COUNT(*),
    a.legislature_snapshot
FROM amendements a
WHERE a.date_depot IS NOT NULL
  AND a.groupe_politique_ref IS NOT NULL
GROUP BY a.groupe_politique_ref, a.date_depot, a.legislature_snapshot

UNION ALL

-- =========================
-- DEPUTE : VOTES
-- =========================
SELECT
    'depute',
    vd.depute_id,
    s.date_scrutin::date,
    'vote',
    COUNT(*),
    vd.legislature_snapshot
FROM votes_deputes vd
         JOIN scrutins s ON s.uid = vd.scrutin_uid
WHERE s.date_scrutin IS NOT NULL
GROUP BY vd.depute_id, s.date_scrutin, vd.legislature_snapshot

UNION ALL

-- =========================
-- DEPUTE : AMENDEMENTS (AUTEUR)
-- =========================
SELECT
    'depute',
    a.acteur_uid,
    a.date_depot::date,
    'amendement',
    COUNT(*),
    a.legislature_snapshot
FROM amendements a
WHERE a.date_depot IS NOT NULL
  AND a.acteur_uid IS NOT NULL
GROUP BY a.acteur_uid, a.date_depot, a.legislature_snapshot

UNION ALL

-- =========================
-- DEPUTE : AMENDEMENTS (CO-AUTEUR)
-- =========================
SELECT
    'depute',
    ca.acteur_uid,
    a.date_depot::date,
    'amendement_co',
    COUNT(*),
    a.legislature_snapshot
FROM amendements_co_auteurs ca
         JOIN amendements a ON a.uid = ca.amendement_uid
WHERE a.date_depot IS NOT NULL
GROUP BY ca.acteur_uid, a.date_depot, a.legislature_snapshot;



CREATE UNIQUE INDEX IF NOT EXISTS agg_activity_calendar_mv_uq
    ON agg_activity_calendar_mv (entity_type, entity_id, activity_date, domain, legislature);

CREATE INDEX IF NOT EXISTS agg_activity_calendar_mv_entity_idx
    ON agg_activity_calendar_mv (entity_id, entity_type, legislature);

CREATE INDEX IF NOT EXISTS agg_activity_calendar_mv_date_idx
    ON agg_activity_calendar_mv (activity_date);

CREATE INDEX IF NOT EXISTS agg_activity_calendar_mv_domain_idx
    ON agg_activity_calendar_mv (domain);