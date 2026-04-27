-- =====================================================
-- AMENDEMENTS SNAPSHOT → FINAL SYNC SCRIPT
-- =====================================================

BEGIN;

-- =====================================================
-- AMENDEMENTS
-- =====================================================

INSERT INTO amendements (
    uid,
    chronotag,
    legislature,

    numero_long,
    numero_ordre,
    numero_rect,
    organe_examen,

    examen_ref,
    texte_leg_ref,

    acteur_uid,
    groupe_politique_ref,
    type_auteur,

    division_titre,
    division_type,
    division_avant_apres,
    alinea_numero,

    dispositif,
    expose_sommaire,

    date_depot,
    date_publication,
    date_sort,
    sort,
    etat_code,
    etat_libelle,
    sous_etat_code,
    sous_etat_libelle,

    article99,

    row_hash,
    legislature_snapshot
)
SELECT
    uid,
    chronotag,
    legislature,

    numero_long,
    numero_ordre,
    numero_rect,
    organe_examen,

    examen_ref,
    texte_leg_ref,

    acteur_uid,
    groupe_politique_ref,
    type_auteur,

    division_titre,
    division_type,
    division_avant_apres,
    alinea_numero,

    dispositif,
    expose_sommaire,

    date_depot,
    date_publication,
    date_sort,
    sort,
    etat_code,
    etat_libelle,
    sous_etat_code,
    sous_etat_libelle,

    article99,

    row_hash,
    legislature_snapshot
FROM amendements_snapshot
ON CONFLICT (uid) DO UPDATE SET
                                chronotag = EXCLUDED.chronotag,
                                legislature = EXCLUDED.legislature,

                                numero_long = EXCLUDED.numero_long,
                                numero_ordre = EXCLUDED.numero_ordre,
                                numero_rect = EXCLUDED.numero_rect,
                                organe_examen = EXCLUDED.organe_examen,

                                examen_ref = EXCLUDED.examen_ref,
                                texte_leg_ref = EXCLUDED.texte_leg_ref,

                                acteur_uid = EXCLUDED.acteur_uid,
                                groupe_politique_ref = EXCLUDED.groupe_politique_ref,
                                type_auteur = EXCLUDED.type_auteur,

                                division_titre = EXCLUDED.division_titre,
                                division_type = EXCLUDED.division_type,
                                division_avant_apres = EXCLUDED.division_avant_apres,
                                alinea_numero = EXCLUDED.alinea_numero,

                                dispositif = EXCLUDED.dispositif,
                                expose_sommaire = EXCLUDED.expose_sommaire,

                                date_depot = EXCLUDED.date_depot,
                                date_publication = EXCLUDED.date_publication,
                                date_sort = EXCLUDED.date_sort,
                                sort = EXCLUDED.sort,

                                etat_code = EXCLUDED.etat_code,
                                etat_libelle = EXCLUDED.etat_libelle,
                                sous_etat_code = EXCLUDED.sous_etat_code,
                                sous_etat_libelle = EXCLUDED.sous_etat_libelle,

                                article99 = EXCLUDED.article99,

                                row_hash = EXCLUDED.row_hash,
                                legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE amendements.row_hash IS DISTINCT FROM EXCLUDED.row_hash;

-- =====================================================
-- CO-AUTEURS
-- =====================================================

INSERT INTO amendements_co_auteurs (
    amendement_uid,
    acteur_uid,
    row_hash,
    legislature_snapshot
)
SELECT
    amendement_uid,
    acteur_uid,
    row_hash,
    legislature_snapshot
FROM amendements_co_auteurs_snapshot
ON CONFLICT (amendement_uid, acteur_uid) DO UPDATE
    SET row_hash = EXCLUDED.row_hash
WHERE amendements_co_auteurs.row_hash IS DISTINCT FROM EXCLUDED.row_hash;

COMMIT;