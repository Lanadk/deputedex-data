export interface Amendement {
    uid: string;
    chronotag: string | null;
    legislature: string | null;

    // identification{}
    numero_long: string | null;
    numero_ordre: string | null;
    numero_rect: string | null;
    organe_examen: string | null; // prefixeOrganeExamen

    // refs
    examen_ref: string | null;
    texte_leg_ref: string | null;

    // auteur principal (signataires.auteur)
    acteur_uid: string | null;
    groupe_politique_ref: string | null;
    type_auteur: string | null;

    // pointeurFragmentTexte
    division_titre: string | null;
    division_type: string | null;
    division_avant_apres: string | null;
    alinea_numero: string | null;

    // corps.contenuAuteur
    dispositif: string | null;
    expose_sommaire: string | null;

    // cycleDeVie
    date_depot: string | null;
    date_publication: string | null;
    date_sort: string | null;
    sort: string | null;
    etat_code: string | null;
    etat_libelle: string | null;
    sous_etat_code: string | null;
    sous_etat_libelle: string | null;

    // divers
    article99: boolean | null;
}

export interface AmendementCoAuteur {
    amendement_uid: string;
    acteur_uid: string;
}