-- ==============================================================================
-- RAW TABLES
-- ==============================================================================
DROP TABLE IF EXISTS deputes_raw CASCADE;
DROP TABLE IF EXISTS groupes_parlementaires_raw CASCADE;
DROP TABLE IF EXISTS scrutins_raw CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_raw CASCADE;
DROP TABLE IF EXISTS votes_deputes_raw CASCADE;
DROP TABLE IF EXISTS scrutins_agregats_raw CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_agregats_raw CASCADE;

CREATE TABLE IF NOT EXISTS deputes_raw
(
    data JSONB NOT NULL
);
CREATE TABLE IF NOT EXISTS groupes_parlementaires_raw
(
    data JSONB NOT NULL
);
CREATE TABLE IF NOT EXISTS scrutins_raw
(
    data JSONB NOT NULL
);
CREATE TABLE IF NOT EXISTS scrutins_groupes_raw
(
    data JSONB NOT NULL
);
CREATE TABLE IF NOT EXISTS votes_deputes_raw
(
    data JSONB NOT NULL
);
CREATE TABLE IF NOT EXISTS scrutins_agregats_raw
(
    data JSONB NOT NULL
);
CREATE TABLE IF NOT EXISTS scrutins_groupes_agregats_raw
(
    data JSONB NOT NULL
);

-- ==============================================================================
-- SNAPSHOT TABLES
-- ==============================================================================
DROP TABLE IF EXISTS deputes_snapshot CASCADE;
DROP TABLE IF EXISTS scrutins_snapshot CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_snapshot CASCADE;
DROP TABLE IF EXISTS votes_deputes_snapshot CASCADE;
DROP TABLE IF EXISTS scrutins_agregats_snapshot CASCADE;
DROP TABLE IF EXISTS scrutins_groupes_agregats_snapshot CASCADE;
DROP TABLE IF EXISTS groupes_parlementaires_snapshot CASCADE;

CREATE TABLE IF NOT EXISTS deputes_snapshot
(
    id                   TEXT PRIMARY KEY,
    row_hash             TEXT UNIQUE NOT NULL,
    legislature_snapshot INTEGER     NOT NULL
);

CREATE TABLE IF NOT EXISTS scrutins_snapshot
(
    uid                  TEXT PRIMARY KEY,
    numero               TEXT,
    legislature          TEXT,
    date_scrutin         DATE,
    titre                TEXT,
    type_scrutin_code    TEXT,
    type_scrutin_libelle TEXT,
    type_majorite        TEXT,
    resultat_code        TEXT,
    resultat_libelle     TEXT,
    row_hash             TEXT UNIQUE NOT NULL,
    legislature_snapshot INTEGER     NOT NULL
);

CREATE TABLE IF NOT EXISTS scrutins_groupes_snapshot
(
    scrutin_uid          TEXT        NOT NULL,
    groupe_id            TEXT        NOT NULL,
    groupe_legislature   INTEGER     NOT NULL,
    nombre_membres       INTEGER,
    position_majoritaire TEXT,
    row_hash             TEXT UNIQUE NOT NULL,
    legislature_snapshot INTEGER     NOT NULL,
    PRIMARY KEY (scrutin_uid, groupe_id)
);

CREATE TABLE IF NOT EXISTS votes_deputes_snapshot
(
    scrutin_uid          TEXT        NOT NULL,
    depute_id            TEXT        NOT NULL,
    groupe_id            TEXT,
    groupe_legislature   INTEGER,
    mandat_ref           TEXT,
    position             TEXT        NOT NULL,
    cause_position       TEXT,
    par_delegation       BOOLEAN,
    row_hash             TEXT UNIQUE NOT NULL,
    legislature_snapshot INTEGER     NOT NULL,
    PRIMARY KEY (scrutin_uid, depute_id)
);

CREATE TABLE IF NOT EXISTS scrutins_agregats_snapshot
(
    scrutin_uid                   TEXT PRIMARY KEY,
    nombre_votants                INTEGER,
    suffrages_exprimes            INTEGER,
    suffrages_requis              INTEGER,
    total_pour                    INTEGER,
    total_contre                  INTEGER,
    total_abstentions             INTEGER,
    total_non_votants             INTEGER,
    total_non_votants_volontaires INTEGER,
    row_hash                      TEXT UNIQUE NOT NULL,
    legislature_snapshot          INTEGER     NOT NULL
);

CREATE TABLE IF NOT EXISTS scrutins_groupes_agregats_snapshot
(
    scrutin_uid             TEXT        NOT NULL,
    groupe_id               TEXT        NOT NULL,
    groupe_legislature      INTEGER     NOT NULL,
    pour                    INTEGER,
    contre                  INTEGER,
    abstentions             INTEGER,
    non_votants             INTEGER,
    non_votants_volontaires INTEGER,
    row_hash                TEXT UNIQUE NOT NULL,
    legislature_snapshot    INTEGER     NOT NULL,
    PRIMARY KEY (scrutin_uid, groupe_id)
);

CREATE TABLE IF NOT EXISTS groupes_parlementaires_snapshot
(
    id                   TEXT        NOT NULL,
    legislature_snapshot INTEGER     NOT NULL,
    row_hash             TEXT UNIQUE NOT NULL,
    PRIMARY KEY (id)
);