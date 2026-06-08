-- ==============================================================================
-- RAW TABLES
-- ==============================================================================
DROP TABLE IF EXISTS dossier_parlementaire_raw CASCADE;
DROP TABLE IF EXISTS dossier_initiateur_raw CASCADE;
DROP TABLE IF EXISTS acte_legislatif_raw CASCADE;
DROP TABLE IF EXISTS acte_rapporteur_raw CASCADE;
DROP TABLE IF EXISTS acte_texte_associe_raw CASCADE;
DROP TABLE IF EXISTS acte_reunion_raw CASCADE;
DROP TABLE IF EXISTS acte_vote_raw CASCADE;
DROP TABLE IF EXISTS acte_decision_raw CASCADE;


CREATE TABLE dossier_parlementaire_raw
(
    data JSONB NOT NULL
);

CREATE TABLE dossier_initiateur_raw
(
    data JSONB NOT NULL
);

CREATE TABLE acte_legislatif_raw
(
    data JSONB NOT NULL
);

CREATE TABLE acte_rapporteur_raw
(
    data JSONB NOT NULL
);

CREATE TABLE acte_texte_associe_raw
(
    data JSONB NOT NULL
);

CREATE TABLE acte_reunion_raw
(
    data JSONB NOT NULL
);

CREATE TABLE acte_vote_raw
(
    data JSONB NOT NULL
);

CREATE TABLE acte_decision_raw
(
    data JSONB NOT NULL
);


-- ==============================================================================
-- SNAPSHOT TABLES
-- ==============================================================================
DROP TABLE IF EXISTS dossier_parlementaire_snapshot CASCADE;
DROP TABLE IF EXISTS dossier_initiateur_snapshot CASCADE;
DROP TABLE IF EXISTS acte_legislatif_snapshot CASCADE;
DROP TABLE IF EXISTS acte_rapporteur_snapshot CASCADE;
DROP TABLE IF EXISTS acte_texte_associe_snapshot CASCADE;
DROP TABLE IF EXISTS acte_reunion_snapshot CASCADE;
DROP TABLE IF EXISTS acte_vote_snapshot CASCADE;
DROP TABLE IF EXISTS acte_decision_snapshot CASCADE;

CREATE TABLE dossier_parlementaire_snapshot
(
    uid                  TEXT PRIMARY KEY,
    legislature          INTEGER,

    titre                TEXT,
    titre_chemin         TEXT,
    senat_chemin         TEXT,
    procedure_code       TEXT,
    procedure_libelle    TEXT,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL
);

CREATE TABLE dossier_initiateur_snapshot
(
    dossier_uid   TEXT,
    acteur_uid    TEXT,
    mandat_uid    TEXT,
    organe_uid    TEXT,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL,
    UNIQUE (row_hash)
);

CREATE TABLE acte_legislatif_snapshot
(
    uid               TEXT PRIMARY KEY,
    dossier_uid       TEXT,
    parent_acte_uid   TEXT,

    type_acte         TEXT,
    code_acte         TEXT,
    nom_canonique     TEXT,
    libelle_court     TEXT,
    organe_uid        TEXT,
    date_acte         TIMESTAMPTZ,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL
);

CREATE TABLE acte_rapporteur_snapshot
(
    acte_uid        TEXT NOT NULL,
    acteur_uid      TEXT NOT NULL,
    type_rapporteur TEXT,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL,

    PRIMARY KEY (acte_uid, acteur_uid)
);

CREATE TABLE acte_texte_associe_snapshot
(
    acte_uid        TEXT,
    reference_texte TEXT,
    type_texte      TEXT,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL,

    UNIQUE (acte_uid, reference_texte)
);

CREATE TABLE acte_reunion_snapshot
(
    acte_uid    TEXT PRIMARY KEY,
    reunion_ref TEXT,

    odj_ref     TEXT,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL
);

CREATE TABLE acte_vote_snapshot
(
    acte_uid  TEXT,
    vote_ref  TEXT,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL,

    PRIMARY KEY (acte_uid, vote_ref)
);

CREATE TABLE acte_decision_snapshot
(
    acte_uid     TEXT PRIMARY KEY,
    famille_code TEXT,
    libelle      TEXT,

    row_hash             TEXT,
    legislature_snapshot INTEGER NOT NULL
);