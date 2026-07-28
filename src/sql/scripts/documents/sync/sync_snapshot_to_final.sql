BEGIN;

-- =============================================================================
-- DOCUMENTS PARLEMENTAIRES
-- =============================================================================

INSERT INTO documents_parlementaires (uid,
                                      legislature,
                                      denomination_structurelle,
                                      provenance,
                                      titre_principal,
                                      titre_principal_court,
                                      dossier_ref,
                                      redacteur,
                                      date_creation,
                                      date_depot,
                                      date_publication,
                                      date_publication_web,
                                      num_notice,
                                      formule,
                                      adoption_conforme,
                                      row_hash,
                                      legislature_snapshot)
SELECT uid,
       legislature,
       denomination_structurelle,
       provenance,
       titre_principal,
       titre_principal_court,
       dossier_ref,
       redacteur,
       date_creation,
       date_depot,
       date_publication,
       date_publication_web,
       num_notice,
       formule,
       adoption_conforme,
       row_hash,
       legislature_snapshot
FROM documents_snapshot
ON CONFLICT (uid) DO UPDATE
    SET legislature               = EXCLUDED.legislature,
        denomination_structurelle = EXCLUDED.denomination_structurelle,
        provenance                = EXCLUDED.provenance,
        titre_principal           = EXCLUDED.titre_principal,
        titre_principal_court     = EXCLUDED.titre_principal_court,
        dossier_ref               = EXCLUDED.dossier_ref,
        redacteur                 = EXCLUDED.redacteur,
        date_creation             = EXCLUDED.date_creation,
        date_depot                = EXCLUDED.date_depot,
        date_publication          = EXCLUDED.date_publication,
        date_publication_web      = EXCLUDED.date_publication_web,
        num_notice                = EXCLUDED.num_notice,
        formule                   = EXCLUDED.formule,
        adoption_conforme         = EXCLUDED.adoption_conforme,
        row_hash                  = EXCLUDED.row_hash,
        legislature_snapshot      = EXCLUDED.legislature_snapshot
WHERE documents_parlementaires.row_hash IS DISTINCT FROM EXCLUDED.row_hash;

-- Note : la suppression des documents disparus est faite plus bas dans ce
-- fichier (juste avant COMMIT), une fois que les 6 tables enfants ci-dessous
-- ont fini de purger leurs propres lignes obsolètes. Toutes référencent
-- documents_parlementaires.uid en ON DELETE RESTRICT : supprimer le document
-- ici, avant elles, ferait échouer la contrainte FK.


-- =============================================================================
-- DOCUMENTS CLASSIFICATIONS
-- =============================================================================

INSERT INTO documents_classifications (document_uid,
                                       depot_code,
                                       depot_libelle,
                                       classe_code,
                                       classe_libelle,
                                       type_code,
                                       type_libelle,
                                       sous_type_code,
                                       sous_type_libelle,
                                       sous_type_libelle_edition,
                                       statut_adoption_code,
                                       statut_adoption_libelle,
                                       row_hash,
                                       legislature_snapshot)
SELECT document_uid,
       depot_code,
       depot_libelle,
       classe_code,
       classe_libelle,
       type_code,
       type_libelle,
       sous_type_code,
       sous_type_libelle,
       sous_type_libelle_edition,
       statut_adoption_code,
       statut_adoption_libelle,
       row_hash,
       legislature_snapshot
FROM documents_classifications_snapshot
ON CONFLICT (document_uid) DO UPDATE
    SET depot_code                = EXCLUDED.depot_code,
        depot_libelle             = EXCLUDED.depot_libelle,
        classe_code               = EXCLUDED.classe_code,
        classe_libelle            = EXCLUDED.classe_libelle,
        type_code                 = EXCLUDED.type_code,
        type_libelle              = EXCLUDED.type_libelle,
        sous_type_code            = EXCLUDED.sous_type_code,
        sous_type_libelle         = EXCLUDED.sous_type_libelle,
        sous_type_libelle_edition = EXCLUDED.sous_type_libelle_edition,
        statut_adoption_code      = EXCLUDED.statut_adoption_code,
        statut_adoption_libelle   = EXCLUDED.statut_adoption_libelle,
        row_hash                  = EXCLUDED.row_hash,
        legislature_snapshot      = EXCLUDED.legislature_snapshot
WHERE documents_classifications.row_hash IS DISTINCT FROM EXCLUDED.row_hash;

-- DELETE MISSING CLASSIFICATIONS
CREATE TEMP TABLE tmp_classifications_to_delete AS
SELECT d.document_uid
FROM documents_classifications d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM documents_classifications_snapshot s
                  WHERE s.document_uid = d.document_uid);

DELETE
FROM documents_classifications d
    USING tmp_classifications_to_delete x
WHERE d.document_uid = x.document_uid;

DROP TABLE tmp_classifications_to_delete;


-- =============================================================================
-- DOCUMENTS AUTEURS
-- =============================================================================

INSERT INTO documents_auteurs (document_uid,
                               acteur_uid,
                               organe_uid,
                               qualite,
                               row_hash,
                               legislature_snapshot)
SELECT document_uid,
       acteur_uid,
       organe_uid,
       qualite,
       row_hash,
       legislature_snapshot
FROM documents_auteurs_snapshot
ON CONFLICT (row_hash) DO NOTHING;

-- DELETE MISSING AUTEURS
DELETE
FROM documents_auteurs d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM documents_auteurs_snapshot s
                  WHERE s.row_hash = d.row_hash);


-- =============================================================================
-- DOCUMENTS CO SIGNATAIRES
-- =============================================================================

INSERT INTO documents_co_signataires (document_uid,
                                      acteur_uid,
                                      organe_uid,
                                      row_hash,
                                      legislature_snapshot)
SELECT document_uid,
       acteur_uid,
       organe_uid,
       row_hash,
       legislature_snapshot
FROM documents_co_signataires_snapshot
ON CONFLICT (row_hash) DO NOTHING;

-- DELETE MISSING CO SIGNATAIRES
DELETE
FROM documents_co_signataires d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM documents_co_signataires_snapshot s
                  WHERE s.row_hash = d.row_hash);


-- =============================================================================
-- DOCUMENTS ORGANES REFERENTS
-- =============================================================================

INSERT INTO documents_organes_referents (document_uid,
                                         organe_uid,
                                         row_hash,
                                         legislature_snapshot)
SELECT document_uid,
       organe_uid,
       row_hash,
       legislature_snapshot
FROM documents_organes_referents_snapshot
ON CONFLICT (row_hash) DO NOTHING;

-- DELETE MISSING ORGANES REFERENTS
DELETE
FROM documents_organes_referents d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM documents_organes_referents_snapshot s
                  WHERE s.document_uid = d.document_uid
                    AND s.organe_uid = d.organe_uid);


-- =============================================================================
-- DOCUMENTS IMPRIMERIES
-- =============================================================================

INSERT INTO documents_imprimeries (document_uid,
                                  issn,
                                  isbn,
                                  dian,
                                  nb_page,
                                  prix,
                                  row_hash,
                                  legislature_snapshot)
SELECT document_uid,
       issn,
       isbn,
       dian,
       nb_page,
       prix,
       row_hash,
       legislature_snapshot
FROM documents_imprimeries_snapshot
ON CONFLICT (document_uid) DO UPDATE
    SET issn                 = EXCLUDED.issn,
        isbn                 = EXCLUDED.isbn,
        dian                 = EXCLUDED.dian,
        nb_page              = EXCLUDED.nb_page,
        prix                 = EXCLUDED.prix,
        row_hash             = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE documents_imprimeries.row_hash IS DISTINCT FROM EXCLUDED.row_hash;

-- DELETE MISSING IMPRIMERIES
CREATE TEMP TABLE tmp_imprimeries_to_delete AS
SELECT d.document_uid
FROM documents_imprimeries d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM documents_imprimeries_snapshot s
                  WHERE s.document_uid = d.document_uid);

DELETE
FROM documents_imprimeries d
    USING tmp_imprimeries_to_delete x
WHERE d.document_uid = x.document_uid;

DROP TABLE tmp_imprimeries_to_delete;


-- =============================================================================
-- DOCUMENTS DEPOTS AMENDEMENTS
-- =============================================================================

INSERT INTO documents_depot_amendements (document_uid,
                                         type_depot,
                                         organe_uid,
                                         amendable,
                                         date_limite_depot,
                                         row_hash,
                                         legislature_snapshot)
SELECT document_uid,
       type_depot,
       organe_uid,
       amendable,
       date_limite_depot,
       row_hash,
       legislature_snapshot
FROM documents_depots_amendements_snapshot
ON CONFLICT (row_hash) DO NOTHING;

-- DELETE MISSING DEPOTS AMENDEMENTS
DELETE
FROM documents_depot_amendements d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM documents_depots_amendements_snapshot s
                  WHERE s.row_hash = d.row_hash);


-- =============================================================================
-- DELETE MISSING DOCUMENTS
-- Tourne en dernier : les 6 tables enfants ci-dessus (documents_classifications,
-- documents_auteurs, documents_co_signataires, documents_organes_referents,
-- documents_imprimeries, documents_depot_amendements) référencent
-- documents_parlementaires.uid en ON DELETE RESTRICT sans être elles-mêmes
-- purgées automatiquement : leurs propres blocs "DELETE MISSING ..." ci-dessus
-- doivent avoir tourné avant, sinon cette suppression échoue sur la FK.
-- =============================================================================

CREATE TEMP TABLE tmp_documents_to_delete AS
SELECT d.uid
FROM documents_parlementaires d
WHERE d.legislature_snapshot IN (SELECT number FROM param_current_legislatures)
  AND NOT EXISTS (SELECT 1
                  FROM documents_snapshot s
                  WHERE s.uid = d.uid);

DELETE
FROM documents_parlementaires d
    USING tmp_documents_to_delete x
WHERE d.uid = x.uid;

DROP TABLE tmp_documents_to_delete;

COMMIT;