export interface DocumentParlementaire {
    uid: string;
    legislature: number;

    xsi_type: string;

    denomination_structurelle: string | null;
    provenance: string | null;

    titre_principal: string | null;
    titre_principal_court: string | null;

    dossier_ref: string | null;

    redacteur: string | null;

    date_creation: string | null;
    date_depot: string | null;
    date_publication: string | null;
    date_publication_web: string | null;

    num_notice: string | null;
    formule: string | null;
    adoption_conforme: boolean | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface DocumentClassification {
    document_uid: string;

    depot_code: string | null;
    depot_libelle: string | null;

    classe_code: string | null;
    classe_libelle: string | null;

    type_code: string | null;
    type_libelle: string | null;

    sous_type_code: string | null;
    sous_type_libelle: string | null;
    sous_type_libelle_edition: string | null;

    statut_adoption_code: string | null;
    statut_adoption_libelle: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface DocumentAuteur {
    document_uid: string;

    acteur_uid: string | null;
    organe_uid: string | null;

    qualite: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface DocumentCoSignataire {
    document_uid: string;

    acteur_uid: string | null;
    organe_uid: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface DocumentOrganeReferent {
    document_uid: string;
    organe_uid: string;

    row_hash: string;
    legislature_snapshot: number;
}

export interface DocumentImprimerie {
    document_uid: string;

    issn: string | null;
    isbn: string | null;
    dian: string | null;

    nb_page: number | null;
    prix: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface DocumentDepotAmendement {
    document_uid: string;

    type_depot: 'SEANCE' | 'COMMISSION';

    organe_uid: string | null;

    amendable: boolean | null;

    date_limite_depot: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

