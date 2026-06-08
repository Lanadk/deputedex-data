-- ==============================================================================
-- RAW TABLES
-- ==============================================================================
DROP TABLE IF EXISTS documents_raw CASCADE;
DROP TABLE IF EXISTS documents_classifications_raw CASCADE;
DROP TABLE IF EXISTS documents_auteurs_raw CASCADE;
DROP TABLE IF EXISTS documents_co_signataires_raw CASCADE;
DROP TABLE IF EXISTS documents_organes_referents_raw CASCADE;
DROP TABLE IF EXISTS documents_imprimeries_raw CASCADE;
DROP TABLE IF EXISTS documents_depots_amendements_raw CASCADE;


CREATE TABLE documents_raw
(
    data JSONB NOT NULL
);

CREATE TABLE documents_classifications_raw
(
    data JSONB NOT NULL
);

CREATE TABLE documents_auteurs_raw
(
    data JSONB NOT NULL
);

CREATE TABLE documents_co_signataires_raw
(
    data JSONB NOT NULL
);

CREATE TABLE documents_organes_referents_raw
(
    data JSONB NOT NULL
);

CREATE TABLE documents_imprimeries_raw
(
    data JSONB NOT NULL
);

CREATE TABLE documents_depots_amendements_raw
(
    data JSONB NOT NULL
);

-- ==============================================================================
-- SNAPSHOT TABLES
-- ==============================================================================
DROP TABLE IF EXISTS documents_snapshot CASCADE;
DROP TABLE IF EXISTS documents_classifications_snapshot CASCADE;
DROP TABLE IF EXISTS documents_auteurs_snapshot CASCADE;
DROP TABLE IF EXISTS documents_co_signataires_snapshot CASCADE;
DROP TABLE IF EXISTS documents_organes_referents_snapshot CASCADE;
DROP TABLE IF EXISTS documents_imprimeries_snapshot CASCADE;
DROP TABLE IF EXISTS documents_depots_amendements_snapshot CASCADE;

CREATE TABLE documents_snapshot
(
    uid                        TEXT PRIMARY KEY,
    legislature                INTEGER,

    denomination_structurelle  TEXT,
    provenance                 TEXT,
    titre_principal            TEXT,
    titre_principal_court      TEXT,

    dossier_ref                TEXT,
    redacteur                  TEXT,

    date_creation              DATE,
    date_depot                 DATE,
    date_publication           DATE,
    date_publication_web       DATE,

    num_notice                 TEXT,
    formule                    TEXT,
    adoption_conforme          BOOLEAN,

    row_hash                   TEXT UNIQUE,
    legislature_snapshot       INTEGER NOT NULL
);

CREATE TABLE documents_classifications_snapshot
(
    document_uid               TEXT PRIMARY KEY,

    depot_code                 TEXT,
    depot_libelle              TEXT,

    classe_code                TEXT,
    classe_libelle             TEXT,

    type_code                  TEXT,
    type_libelle               TEXT,

    sous_type_code             TEXT,
    sous_type_libelle          TEXT,
    sous_type_libelle_edition  TEXT,

    statut_adoption_code       TEXT,
    statut_adoption_libelle    TEXT,

    row_hash                   TEXT UNIQUE,
    legislature_snapshot       INTEGER NOT NULL
);

CREATE TABLE documents_auteurs_snapshot
(
    document_uid               TEXT,

    acteur_uid                 TEXT,
    organe_uid                 TEXT,
    qualite                    TEXT,

    row_hash                   TEXT UNIQUE,
    legislature_snapshot       INTEGER NOT NULL
);

CREATE TABLE documents_co_signataires_snapshot
(
    document_uid               TEXT,

    acteur_uid                 TEXT,
    organe_uid                 TEXT,

    row_hash                   TEXT UNIQUE,
    legislature_snapshot       INTEGER NOT NULL
);

CREATE TABLE documents_organes_referents_snapshot
(
    document_uid               TEXT,
    organe_uid                 TEXT,

    row_hash                   TEXT UNIQUE,
    legislature_snapshot       INTEGER NOT NULL,

    PRIMARY KEY (document_uid, organe_uid)
);

CREATE TABLE documents_imprimeries_snapshot
(
    document_uid               TEXT PRIMARY KEY,

    issn                       TEXT,
    isbn                       TEXT,
    dian                       TEXT,

    nb_page                    INTEGER,
    prix                       TEXT,

    row_hash                   TEXT UNIQUE,
    legislature_snapshot       INTEGER NOT NULL
);

CREATE TABLE documents_depots_amendements_snapshot
(
    document_uid               TEXT,

    type_depot                 TEXT,
    organe_uid                 TEXT,
    amendable                  BOOLEAN,

    date_limite_depot          DATE,

    row_hash                   TEXT UNIQUE,
    legislature_snapshot       INTEGER NOT NULL
);