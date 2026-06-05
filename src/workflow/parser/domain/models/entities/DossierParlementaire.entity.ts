export interface DossierParlementaire {
    uid: string;
    legislature: number;

    titre: string;
    titre_chemin: string | null;
    senat_chemin: string | null;

    procedure_code: string | null;
    procedure_libelle: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface DossierInitiateur {
    dossier_uid: string;

    acteur_uid: string | null;
    mandat_uid: string | null;
    organe_uid: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface ActeLegislatif {
    uid: string;

    dossier_uid: string;
    parent_acte_uid: string | null;

    type_acte: string;
    code_acte: string | null;
    nom_canonique: string | null;
    libelle_court: string | null;
    organe_uid: string | null;
    date_acte: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface ActeRapporteur {
    acte_uid: string;

    acteur_uid: string;

    type_rapporteur: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface ActeTexteAssocie {
    acte_uid: string;

    reference_texte: string;

    type_texte: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface ActeReunion {
    acte_uid: string;

    reunion_ref: string | null;

    odj_ref: string | null;

    row_hash: string;
    legislature_snapshot: number;
}

export interface ActeVote {
    acte_uid: string;

    vote_ref: string;

    row_hash: string;
    legislature_snapshot: number;
}

export interface ActeDecision {
    acte_uid: string;

    famille_code: string | null;

    libelle: string | null;

    row_hash: string;
    legislature_snapshot: number;
}