BEGIN;

-- =============================================================================
-- DOSSIER PARLEMENTAIRE
-- =============================================================================

INSERT INTO dossier_parlementaire (
    uid,
    legislature,
    titre,
    titre_chemin,
    senat_chemin,
    procedure_code,
    procedure_libelle,
    row_hash,
    legislature_snapshot
)
SELECT
    uid,
    legislature,
    titre,
    titre_chemin,
    senat_chemin,
    procedure_code,
    procedure_libelle,
    row_hash,
    legislature_snapshot
FROM dossier_parlementaire_snapshot
ON CONFLICT (uid) DO UPDATE
    SET
        legislature = EXCLUDED.legislature,
        titre = EXCLUDED.titre,
        titre_chemin = EXCLUDED.titre_chemin,
        senat_chemin = EXCLUDED.senat_chemin,
        procedure_code = EXCLUDED.procedure_code,
        procedure_libelle = EXCLUDED.procedure_libelle,
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE dossier_parlementaire.row_hash IS DISTINCT FROM EXCLUDED.row_hash;


-- DELETE MISSING DOSSIERS
CREATE TEMP TABLE tmp_dossiers_to_delete AS
SELECT d.uid
FROM dossier_parlementaire d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (
    SELECT 1
    FROM dossier_parlementaire_snapshot s
    WHERE s.uid = d.uid
);

DELETE FROM dossier_parlementaire d
    USING tmp_dossiers_to_delete x
WHERE d.uid = x.uid;

DROP TABLE tmp_dossiers_to_delete;


-- =============================================================================
-- DOSSIER INITIATEUR
-- =============================================================================

INSERT INTO dossier_initiateur (
    dossier_uid,
    acteur_uid,
    mandat_uid,
    organe_uid,
    row_hash,
    legislature_snapshot
)
SELECT
    dossier_uid,
    acteur_uid,
    mandat_uid,
    organe_uid,
    row_hash,
    legislature_snapshot
FROM dossier_initiateur_snapshot
ON CONFLICT (row_hash) DO UPDATE
    SET
        dossier_uid = EXCLUDED.dossier_uid,
        acteur_uid = EXCLUDED.acteur_uid,
        mandat_uid = EXCLUDED.mandat_uid,
        organe_uid = EXCLUDED.organe_uid,
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE dossier_initiateur.row_hash IS DISTINCT FROM EXCLUDED.row_hash;


-- =============================================================================
-- ACTE LEGISLATIF
-- =============================================================================

INSERT INTO acte_legislatif (
    uid,
    dossier_uid,
    parent_acte_uid,
    type_acte,
    code_acte,
    nom_canonique,
    libelle_court,
    organe_uid,
    date_acte,
    row_hash,
    legislature_snapshot
)
SELECT
    uid,
    dossier_uid,
    parent_acte_uid,
    type_acte,
    code_acte,
    nom_canonique,
    libelle_court,
    organe_uid,
    date_acte,
    row_hash,
    legislature_snapshot
FROM acte_legislatif_snapshot
ON CONFLICT (uid) DO UPDATE
    SET
        dossier_uid = EXCLUDED.dossier_uid,
        parent_acte_uid = EXCLUDED.parent_acte_uid,
        type_acte = EXCLUDED.type_acte,
        code_acte = EXCLUDED.code_acte,
        nom_canonique = EXCLUDED.nom_canonique,
        libelle_court = EXCLUDED.libelle_court,
        organe_uid = EXCLUDED.organe_uid,
        date_acte = EXCLUDED.date_acte,
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE acte_legislatif.row_hash IS DISTINCT FROM EXCLUDED.row_hash;


-- DELETE MISSING ACTES
CREATE TEMP TABLE tmp_actes_to_delete AS
SELECT a.uid
FROM acte_legislatif a
WHERE a.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (
    SELECT 1
    FROM acte_legislatif_snapshot s
    WHERE s.uid = a.uid
);

DELETE FROM acte_legislatif a
    USING tmp_actes_to_delete x
WHERE a.uid = x.uid;

DROP TABLE tmp_actes_to_delete;


-- =============================================================================
-- ACTE RAPPORTEUR
-- =============================================================================

INSERT INTO acte_rapporteur (
    acte_uid,
    acteur_uid,
    type_rapporteur,
    row_hash,
    legislature_snapshot
)
SELECT
    acte_uid,
    acteur_uid,
    type_rapporteur,
    row_hash,
    legislature_snapshot
FROM acte_rapporteur_snapshot
ON CONFLICT (acte_uid, acteur_uid) DO UPDATE
    SET
        type_rapporteur = EXCLUDED.type_rapporteur,
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE acte_rapporteur.row_hash IS DISTINCT FROM EXCLUDED.row_hash;


-- =============================================================================
-- ACTE TEXTE ASSOCIE
-- =============================================================================

INSERT INTO acte_texte_associe (
    acte_uid,
    reference_texte,
    type_texte,
    row_hash,
    legislature_snapshot
)
SELECT
    acte_uid,
    reference_texte,
    type_texte,
    row_hash,
    legislature_snapshot
FROM acte_texte_associe_snapshot
ON CONFLICT (acte_uid, reference_texte) DO UPDATE
    SET
        type_texte = EXCLUDED.type_texte,
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE acte_texte_associe.row_hash IS DISTINCT FROM EXCLUDED.row_hash;


-- =============================================================================
-- ACTE REUNION
-- =============================================================================

INSERT INTO acte_reunion (
    acte_uid,
    reunion_ref,
    odj_ref,
    row_hash,
    legislature_snapshot
)
SELECT
    acte_uid,
    reunion_ref,
    odj_ref,
    row_hash,
    legislature_snapshot
FROM acte_reunion_snapshot
ON CONFLICT (acte_uid) DO UPDATE
    SET
        reunion_ref = EXCLUDED.reunion_ref,
        odj_ref = EXCLUDED.odj_ref,
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE acte_reunion.row_hash IS DISTINCT FROM EXCLUDED.row_hash;


-- =============================================================================
-- ACTE VOTE
-- =============================================================================

INSERT INTO acte_vote (
    acte_uid,
    vote_ref,
    row_hash,
    legislature_snapshot
)
SELECT
    acte_uid,
    vote_ref,
    row_hash,
    legislature_snapshot
FROM acte_vote_snapshot
ON CONFLICT (acte_uid, vote_ref) DO UPDATE
    SET
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE acte_vote.row_hash IS DISTINCT FROM EXCLUDED.row_hash;


-- =============================================================================
-- ACTE DECISION
-- =============================================================================

INSERT INTO acte_decision (
    acte_uid,
    famille_code,
    libelle,
    row_hash,
    legislature_snapshot
)
SELECT
    acte_uid,
    famille_code,
    libelle,
    row_hash,
    legislature_snapshot
FROM acte_decision_snapshot
ON CONFLICT (acte_uid) DO UPDATE
    SET
        famille_code = EXCLUDED.famille_code,
        libelle = EXCLUDED.libelle,
        row_hash = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE acte_decision.row_hash IS DISTINCT FROM EXCLUDED.row_hash;

COMMIT;