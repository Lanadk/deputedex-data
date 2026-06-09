-- ==============================================================================
-- RAW TABLES
-- ==============================================================================
DROP TABLE IF EXISTS mandats_raw CASCADE;
DROP TABLE IF EXISTS mandats_suppleants_raw CASCADE;

CREATE TABLE mandats_raw
(
    data JSONB NOT NULL
);
CREATE TABLE mandats_suppleants_raw
(
    data JSONB NOT NULL
);

-- ==============================================================================
-- SNAPSHOT TABLES
-- ==============================================================================
DROP TABLE IF EXISTS mandats_snapshot CASCADE;
DROP TABLE IF EXISTS mandats_suppleants_snapshot CASCADE;

CREATE TABLE mandats_snapshot
(
    uid                           TEXT PRIMARY KEY,
    acteur_uid                    TEXT        NOT NULL,
    legislature                   INTEGER     NOT NULL,
    type_organe                   TEXT        NOT NULL,
    date_debut                    DATE        NOT NULL,
    date_fin                      DATE,
    date_publication              DATE,
    preseance                     INTEGER     NOT NULL,
    nomin_principale              INTEGER     NOT NULL,
    code_qualite                  TEXT        NOT NULL,
    lib_qualite                   TEXT        NOT NULL,
    lib_qualite_sex               TEXT        NOT NULL,
    organe_uid                    TEXT        NOT NULL,
    election_region               TEXT,
    election_region_type          TEXT,
    election_departement          TEXT,
    election_num_departement      TEXT,
    election_num_circo            TEXT,
    election_cause_mandat         TEXT,
    election_ref_circonscription  TEXT,
    mandature_date_prise_fonction DATE,
    mandature_cause_fin           TEXT,
    mandature_premiere_election   BOOLEAN,
    mandature_place_hemicycle     TEXT,
    mandature_mandat_remplace_ref TEXT,
    row_hash                      TEXT UNIQUE NOT NULL,
    legislature_snapshot          INTEGER     NOT NULL
);

CREATE TABLE mandats_suppleants_snapshot
(
    mandat_uid           TEXT        NOT NULL,
    suppleant_uid        TEXT        NOT NULL,
    date_debut           DATE        NOT NULL,
    date_fin             DATE,
    row_hash             TEXT UNIQUE NOT NULL,
    legislature_snapshot INTEGER     NOT NULL,
    PRIMARY KEY (mandat_uid, suppleant_uid)
);