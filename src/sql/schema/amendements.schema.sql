-- ==============================================================================
-- RAW TABLES
-- ==============================================================================
DROP TABLE IF EXISTS amendements_raw CASCADE;
DROP TABLE IF EXISTS amendements_co_auteurs_raw CASCADE;

CREATE TABLE amendements_raw
(
    data JSONB NOT NULL
);
CREATE TABLE amendements_co_auteurs_raw
(
    data JSONB NOT NULL
);

-- ==============================================================================
-- SNAPSHOT TABLES
-- ==============================================================================
DROP TABLE IF EXISTS amendements_snapshot CASCADE;
DROP TABLE IF EXISTS amendements_co_auteurs_snapshot CASCADE;

CREATE TABLE amendements_snapshot
(
    uid                  TEXT PRIMARY KEY,
    chronotag            TEXT,
    legislature          TEXT,

    numero_long          TEXT,
    numero_ordre         TEXT,
    numero_rect          TEXT,
    organe_examen        TEXT,

    examen_ref           TEXT,
    texte_leg_ref        TEXT,

    acteur_uid           TEXT,
    groupe_politique_ref TEXT,
    type_auteur          TEXT,

    division_titre       TEXT,
    division_type        TEXT,
    division_avant_apres TEXT,
    alinea_numero        TEXT,

    dispositif           TEXT,
    expose_sommaire      TEXT,

    date_depot           DATE,
    date_publication     DATE,
    date_sort            TIMESTAMPTZ,
    sort                 TEXT,
    etat_code            TEXT,
    etat_libelle         TEXT,
    sous_etat_code       TEXT,
    sous_etat_libelle    TEXT,

    article99            BOOLEAN,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL
);

CREATE TABLE amendements_co_auteurs_snapshot
(
    amendement_uid       TEXT,
    acteur_uid           TEXT,
    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL,

    PRIMARY KEY (amendement_uid, acteur_uid)
);