-- CreateTable
CREATE TABLE "param_legislatures" (
    "id" SERIAL NOT NULL,
    "number" INTEGER NOT NULL,
    "start_date" DATE,
    "end_date" DATE,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "param_legislatures_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "param_current_legislatures" (
    "legislature_id" INTEGER NOT NULL,
    "number" INTEGER NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "param_current_legislatures_pkey" PRIMARY KEY ("legislature_id")
);

-- CreateTable
CREATE TABLE "ref_data_domains" (
    "id" SERIAL NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,

    CONSTRAINT "ref_data_domains_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "param_data_sources" (
    "id" SERIAL NOT NULL,
    "domain_id" INTEGER NOT NULL,
    "legislature_id" INTEGER NOT NULL,
    "download_url" TEXT NOT NULL,
    "file_name" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "param_data_sources_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "monitor_data_download" (
    "id" SERIAL NOT NULL,
    "source_id" INTEGER NOT NULL,
    "file_name" TEXT,
    "downloaded" BOOLEAN NOT NULL DEFAULT false,
    "last_download_at" TIMESTAMP(3),
    "checksum" TEXT,
    "file_size" BIGINT,
    "error_message" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "monitor_data_download_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "monitor_data_set_update" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "monitor_data_set_update_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "acteurs" (
    "uid" VARCHAR(50) NOT NULL,
    "civilite" VARCHAR(10),
    "prenom" VARCHAR(100),
    "nom" VARCHAR(255),
    "nom_alpha" VARCHAR(255),
    "trigramme" VARCHAR(10),
    "date_naissance" DATE,
    "ville_naissance" VARCHAR(255),
    "departement_naissance" VARCHAR(255),
    "pays_naissance" VARCHAR(255),
    "date_deces" DATE,
    "profession_libelle" VARCHAR(255),
    "profession_categorie" VARCHAR(255),
    "profession_famille" VARCHAR(255),
    "uri_hatvp" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acteurs_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "acteurs_adresses_postales" (
    "id" SERIAL NOT NULL,
    "acteur_uid" VARCHAR(50) NOT NULL,
    "uid_adresse" VARCHAR(50) NOT NULL,
    "type_code" VARCHAR(10),
    "type_libelle" VARCHAR(255),
    "intitule" VARCHAR(255),
    "numero_rue" VARCHAR(50),
    "nom_rue" VARCHAR(255),
    "complement_adresse" VARCHAR(255),
    "code_postal" VARCHAR(10),
    "ville" VARCHAR(255),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acteurs_adresses_postales_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "acteurs_adresses_mails" (
    "id" SERIAL NOT NULL,
    "acteur_uid" VARCHAR(50) NOT NULL,
    "uid_adresse" VARCHAR(50) NOT NULL,
    "type_code" VARCHAR(10),
    "type_libelle" VARCHAR(255),
    "email" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acteurs_adresses_mails_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "acteurs_reseaux_sociaux" (
    "id" SERIAL NOT NULL,
    "acteur_uid" VARCHAR(50) NOT NULL,
    "uid_adresse" VARCHAR(50) NOT NULL,
    "type_code" VARCHAR(10),
    "type_libelle" VARCHAR(255),
    "plateforme" VARCHAR(50),
    "identifiant" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acteurs_reseaux_sociaux_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "acteurs_telephones" (
    "id" SERIAL NOT NULL,
    "acteur_uid" VARCHAR(50) NOT NULL,
    "uid_adresse" VARCHAR(50) NOT NULL,
    "type_code" VARCHAR(10),
    "type_libelle" VARCHAR(255),
    "adresse_rattachement" VARCHAR(50),
    "numero" VARCHAR(100),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acteurs_telephones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "acteurs_groupes" (
    "id" SERIAL NOT NULL,
    "acteur_uid" VARCHAR(50) NOT NULL,
    "groupe_id" VARCHAR(50) NOT NULL,
    "groupe_legislature" INTEGER NOT NULL,
    "date_debut" DATE NOT NULL,
    "date_fin" DATE,
    "legislature_snapshot" INTEGER NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,

    CONSTRAINT "acteurs_groupes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "deputes" (
    "id" VARCHAR(50) NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "deputes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scrutins" (
    "uid" VARCHAR(50) NOT NULL,
    "numero" VARCHAR(10),
    "legislature" VARCHAR(10),
    "date_scrutin" DATE,
    "titre" TEXT,
    "type_scrutin_code" VARCHAR(10),
    "type_scrutin_libelle" VARCHAR(255),
    "type_majorite" TEXT,
    "resultat_code" VARCHAR(50),
    "resultat_libelle" TEXT,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "scrutins_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "scrutins_groupes" (
    "id" SERIAL NOT NULL,
    "scrutin_uid" VARCHAR(50) NOT NULL,
    "groupe_id" VARCHAR(50) NOT NULL,
    "groupe_legislature" INTEGER NOT NULL,
    "nombre_membres" INTEGER,
    "position_majoritaire" VARCHAR(50),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "scrutins_groupes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "votes_deputes" (
    "id" SERIAL NOT NULL,
    "scrutin_uid" VARCHAR(50) NOT NULL,
    "depute_id" VARCHAR(50) NOT NULL,
    "groupe_id" VARCHAR(50),
    "groupe_legislature" INTEGER,
    "mandat_ref" VARCHAR(50),
    "position" VARCHAR(20) NOT NULL,
    "cause_position" VARCHAR(10),
    "par_delegation" BOOLEAN,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "votes_deputes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scrutins_agregats" (
    "scrutin_uid" VARCHAR(50) NOT NULL,
    "nombre_votants" INTEGER,
    "suffrages_exprimes" INTEGER,
    "suffrages_requis" INTEGER,
    "total_pour" INTEGER,
    "total_contre" INTEGER,
    "total_abstentions" INTEGER,
    "total_non_votants" INTEGER,
    "total_non_votants_volontaires" INTEGER,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "scrutins_agregats_pkey" PRIMARY KEY ("scrutin_uid")
);

-- CreateTable
CREATE TABLE "scrutins_groupes_agregats" (
    "id" SERIAL NOT NULL,
    "scrutin_uid" VARCHAR(50) NOT NULL,
    "groupe_id" VARCHAR(50) NOT NULL,
    "groupe_legislature" INTEGER NOT NULL,
    "pour" INTEGER,
    "contre" INTEGER,
    "abstentions" INTEGER,
    "non_votants" INTEGER,
    "non_votants_volontaires" INTEGER,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "scrutins_groupes_agregats_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mandats" (
    "uid" VARCHAR(50) NOT NULL,
    "acteur_uid" VARCHAR(50) NOT NULL,
    "legislature" INTEGER NOT NULL,
    "type_organe" VARCHAR(50) NOT NULL,
    "date_debut" DATE NOT NULL,
    "date_fin" DATE,
    "date_publication" DATE,
    "preseance" INTEGER NOT NULL,
    "nomin_principale" INTEGER NOT NULL,
    "code_qualite" VARCHAR(100) NOT NULL,
    "lib_qualite" VARCHAR(255) NOT NULL,
    "lib_qualite_sex" VARCHAR(255) NOT NULL,
    "organe_uid" VARCHAR(100) NOT NULL,
    "election_region" VARCHAR(255),
    "election_region_type" VARCHAR(100),
    "election_departement" VARCHAR(255),
    "election_num_departement" VARCHAR(10),
    "election_num_circo" VARCHAR(10),
    "election_cause_mandat" VARCHAR(255),
    "election_ref_circonscription" VARCHAR(255),
    "mandature_date_prise_fonction" DATE,
    "mandature_cause_fin" VARCHAR(255),
    "mandature_premiere_election" BOOLEAN,
    "mandature_place_hemicycle" VARCHAR(10),
    "mandature_mandat_remplace_ref" VARCHAR(100),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "mandats_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "mandats_suppleants" (
    "id" SERIAL NOT NULL,
    "mandat_uid" VARCHAR(50) NOT NULL,
    "suppleant_uid" VARCHAR(50) NOT NULL,
    "date_debut" DATE NOT NULL,
    "date_fin" DATE,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "mandats_suppleants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "groupes_parlementaires" (
    "id" VARCHAR(50) NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "row_hash" TEXT NOT NULL,

    CONSTRAINT "groupes_parlementaires_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ref_groupes" (
    "groupe_id" VARCHAR(50) NOT NULL,
    "groupe_legislature" INTEGER NOT NULL,
    "libelle" VARCHAR(100),
    "code" VARCHAR(20),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ref_groupes_pkey" PRIMARY KEY ("groupe_id")
);

-- CreateTable
CREATE TABLE "ref_scrutin_type" (
    "id" SERIAL NOT NULL,
    "type_scrutin_code" VARCHAR(10),
    "type_scrutin_libelle" VARCHAR(100) NOT NULL,

    CONSTRAINT "ref_scrutin_type_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ref_organe_type" (
    "id" SERIAL NOT NULL,
    "type_organe" VARCHAR(50),

    CONSTRAINT "ref_organe_type_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ref_acteurs_photos" (
    "id" SERIAL NOT NULL,
    "acteur_uid" VARCHAR(50) NOT NULL,
    "legislature" INTEGER NOT NULL,
    "photo_path" TEXT NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ref_acteurs_photos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "amendements" (
    "uid" TEXT NOT NULL,
    "chronotag" TEXT,
    "legislature" TEXT,
    "numero_long" TEXT,
    "numero_ordre" TEXT,
    "numero_rect" TEXT,
    "organe_examen" TEXT,
    "examen_ref" TEXT,
    "texte_leg_ref" TEXT,
    "acteur_uid" TEXT,
    "groupe_politique_ref" TEXT,
    "type_auteur" TEXT,
    "division_titre" TEXT,
    "division_type" TEXT,
    "division_avant_apres" TEXT,
    "alinea_numero" TEXT,
    "dispositif" TEXT,
    "expose_sommaire" TEXT,
    "date_depot" DATE,
    "date_publication" DATE,
    "date_sort" TIMESTAMPTZ,
    "sort" TEXT,
    "etat_code" TEXT,
    "etat_libelle" TEXT,
    "sous_etat_code" TEXT,
    "sous_etat_libelle" TEXT,
    "article99" BOOLEAN,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "amendements_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "amendements_co_auteurs" (
    "id" SERIAL NOT NULL,
    "amendement_uid" TEXT NOT NULL,
    "acteur_uid" TEXT NOT NULL,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "amendements_co_auteurs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dossier_parlementaire" (
    "uid" TEXT NOT NULL,
    "legislature" INTEGER NOT NULL,
    "titre" TEXT NOT NULL,
    "titre_chemin" TEXT,
    "senat_chemin" TEXT,
    "procedure_code" TEXT,
    "procedure_libelle" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "dossier_parlementaire_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "dossier_initiateur" (
    "id" SERIAL NOT NULL,
    "dossier_uid" TEXT NOT NULL,
    "acteur_uid" TEXT,
    "mandat_uid" TEXT,
    "organe_uid" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "dossier_initiateur_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "acte_legislatif" (
    "uid" TEXT NOT NULL,
    "dossier_uid" TEXT NOT NULL,
    "parent_acte_uid" TEXT,
    "type_acte" TEXT NOT NULL,
    "code_acte" TEXT,
    "nom_canonique" TEXT,
    "libelle_court" TEXT,
    "organe_uid" TEXT,
    "date_acte" TIMESTAMP(3),
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acte_legislatif_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "acte_rapporteur" (
    "acte_uid" TEXT NOT NULL,
    "acteur_uid" TEXT NOT NULL,
    "type_rapporteur" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acte_rapporteur_pkey" PRIMARY KEY ("acte_uid","acteur_uid")
);

-- CreateTable
CREATE TABLE "acte_texte_associe" (
    "acte_uid" TEXT NOT NULL,
    "reference_texte" TEXT NOT NULL,
    "type_texte" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acte_texte_associe_pkey" PRIMARY KEY ("acte_uid","reference_texte")
);

-- CreateTable
CREATE TABLE "acte_reunion" (
    "acte_uid" TEXT NOT NULL,
    "reunion_ref" TEXT,
    "odj_ref" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acte_reunion_pkey" PRIMARY KEY ("acte_uid")
);

-- CreateTable
CREATE TABLE "acte_vote" (
    "acte_uid" TEXT NOT NULL,
    "vote_ref" TEXT NOT NULL,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acte_vote_pkey" PRIMARY KEY ("acte_uid","vote_ref")
);

-- CreateTable
CREATE TABLE "acte_decision" (
    "acte_uid" TEXT NOT NULL,
    "famille_code" TEXT,
    "libelle" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "acte_decision_pkey" PRIMARY KEY ("acte_uid")
);

-- CreateTable
CREATE TABLE "documents_parlementaires" (
    "uid" TEXT NOT NULL,
    "legislature" INTEGER,
    "denomination_structurelle" TEXT,
    "provenance" TEXT,
    "titre_principal" TEXT,
    "titre_principal_court" TEXT,
    "dossier_ref" TEXT,
    "redacteur" TEXT,
    "date_creation" DATE,
    "date_depot" DATE,
    "date_publication" DATE,
    "date_publication_web" DATE,
    "num_notice" TEXT,
    "formule" TEXT,
    "adoption_conforme" BOOLEAN,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "documents_parlementaires_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "documents_classifications" (
    "document_uid" TEXT NOT NULL,
    "depot_code" TEXT,
    "depot_libelle" TEXT,
    "classe_code" TEXT,
    "classe_libelle" TEXT,
    "type_code" TEXT,
    "type_libelle" TEXT,
    "sous_type_code" TEXT,
    "sous_type_libelle" TEXT,
    "sous_type_libelle_edition" TEXT,
    "statut_adoption_code" TEXT,
    "statut_adoption_libelle" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "documents_classifications_pkey" PRIMARY KEY ("document_uid")
);

-- CreateTable
CREATE TABLE "documents_auteurs" (
    "id" SERIAL NOT NULL,
    "document_uid" TEXT NOT NULL,
    "acteur_uid" TEXT,
    "organe_uid" TEXT,
    "qualite" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "documents_auteurs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents_co_signataires" (
    "id" SERIAL NOT NULL,
    "document_uid" TEXT NOT NULL,
    "acteur_uid" TEXT,
    "organe_uid" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "documents_co_signataires_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents_organes_referents" (
    "id" SERIAL NOT NULL,
    "document_uid" TEXT NOT NULL,
    "organe_uid" TEXT NOT NULL,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "documents_organes_referents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents_imprimeries" (
    "document_uid" TEXT NOT NULL,
    "issn" TEXT,
    "isbn" TEXT,
    "dian" TEXT,
    "nb_page" INTEGER,
    "prix" TEXT,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "documents_imprimeries_pkey" PRIMARY KEY ("document_uid")
);

-- CreateTable
CREATE TABLE "documents_depot_amendements" (
    "id" SERIAL NOT NULL,
    "document_uid" TEXT NOT NULL,
    "type_depot" TEXT NOT NULL,
    "organe_uid" TEXT,
    "amendable" BOOLEAN,
    "date_limite_depot" DATE,
    "row_hash" TEXT NOT NULL,
    "legislature_snapshot" INTEGER NOT NULL,

    CONSTRAINT "documents_depot_amendements_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "param_legislatures_number_key" ON "param_legislatures"("number");

-- CreateIndex
CREATE UNIQUE INDEX "ref_data_domains_code_key" ON "ref_data_domains"("code");

-- CreateIndex
CREATE UNIQUE INDEX "param_data_sources_domain_id_legislature_id_key" ON "param_data_sources"("domain_id", "legislature_id");

-- CreateIndex
CREATE UNIQUE INDEX "monitor_data_download_source_id_key" ON "monitor_data_download"("source_id");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_row_hash_key" ON "acteurs"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_adresses_postales_row_hash_key" ON "acteurs_adresses_postales"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_adresses_postales_uid_adresse_key" ON "acteurs_adresses_postales"("uid_adresse");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_adresses_mails_row_hash_key" ON "acteurs_adresses_mails"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_adresses_mails_uid_adresse_key" ON "acteurs_adresses_mails"("uid_adresse");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_reseaux_sociaux_row_hash_key" ON "acteurs_reseaux_sociaux"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_reseaux_sociaux_uid_adresse_key" ON "acteurs_reseaux_sociaux"("uid_adresse");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_telephones_row_hash_key" ON "acteurs_telephones"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_telephones_uid_adresse_key" ON "acteurs_telephones"("uid_adresse");

-- CreateIndex
CREATE INDEX "acteurs_groupes_acteur_uid_idx" ON "acteurs_groupes"("acteur_uid");

-- CreateIndex
CREATE INDEX "acteurs_groupes_groupe_id_idx" ON "acteurs_groupes"("groupe_id");

-- CreateIndex
CREATE INDEX "acteurs_groupes_legislature_snapshot_idx" ON "acteurs_groupes"("legislature_snapshot");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_groupes_row_hash_key" ON "acteurs_groupes"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acteurs_groupes_acteur_uid_groupe_id_date_debut_key" ON "acteurs_groupes"("acteur_uid", "groupe_id", "date_debut");

-- CreateIndex
CREATE UNIQUE INDEX "deputes_row_hash_key" ON "deputes"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "deputes_id_key" ON "deputes"("id");

-- CreateIndex
CREATE INDEX "scrutins_legislature_snapshot_idx" ON "scrutins"("legislature_snapshot");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_row_hash_key" ON "scrutins"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_uid_key" ON "scrutins"("uid");

-- CreateIndex
CREATE INDEX "scrutins_groupes_scrutin_uid_idx" ON "scrutins_groupes"("scrutin_uid");

-- CreateIndex
CREATE INDEX "scrutins_groupes_legislature_snapshot_idx" ON "scrutins_groupes"("legislature_snapshot");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_groupes_row_hash_key" ON "scrutins_groupes"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_groupes_scrutin_uid_groupe_id_key" ON "scrutins_groupes"("scrutin_uid", "groupe_id");

-- CreateIndex
CREATE INDEX "votes_deputes_scrutin_uid_idx" ON "votes_deputes"("scrutin_uid");

-- CreateIndex
CREATE INDEX "votes_deputes_depute_id_idx" ON "votes_deputes"("depute_id");

-- CreateIndex
CREATE INDEX "votes_deputes_legislature_snapshot_idx" ON "votes_deputes"("legislature_snapshot");

-- CreateIndex
CREATE INDEX "votes_deputes_groupe_id_idx" ON "votes_deputes"("groupe_id");

-- CreateIndex
CREATE UNIQUE INDEX "votes_deputes_row_hash_key" ON "votes_deputes"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "votes_deputes_scrutin_uid_depute_id_key" ON "votes_deputes"("scrutin_uid", "depute_id");

-- CreateIndex
CREATE INDEX "scrutins_agregats_legislature_snapshot_idx" ON "scrutins_agregats"("legislature_snapshot");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_agregats_row_hash_key" ON "scrutins_agregats"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_agregats_scrutin_uid_key" ON "scrutins_agregats"("scrutin_uid");

-- CreateIndex
CREATE INDEX "scrutins_groupes_agregats_scrutin_uid_idx" ON "scrutins_groupes_agregats"("scrutin_uid");

-- CreateIndex
CREATE INDEX "scrutins_groupes_agregats_legislature_snapshot_idx" ON "scrutins_groupes_agregats"("legislature_snapshot");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_groupes_agregats_row_hash_key" ON "scrutins_groupes_agregats"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "scrutins_groupes_agregats_scrutin_uid_groupe_id_key" ON "scrutins_groupes_agregats"("scrutin_uid", "groupe_id");

-- CreateIndex
CREATE INDEX "mandats_acteur_uid_idx" ON "mandats"("acteur_uid");

-- CreateIndex
CREATE INDEX "mandats_legislature_snapshot_idx" ON "mandats"("legislature_snapshot");

-- CreateIndex
CREATE UNIQUE INDEX "mandats_row_hash_key" ON "mandats"("row_hash");

-- CreateIndex
CREATE INDEX "mandats_suppleants_legislature_snapshot_idx" ON "mandats_suppleants"("legislature_snapshot");

-- CreateIndex
CREATE UNIQUE INDEX "mandats_suppleants_mandat_uid_suppleant_uid_key" ON "mandats_suppleants"("mandat_uid", "suppleant_uid");

-- CreateIndex
CREATE UNIQUE INDEX "mandats_suppleants_row_hash_key" ON "mandats_suppleants"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "groupes_parlementaires_row_hash_key" ON "groupes_parlementaires"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "ref_scrutin_type_type_scrutin_code_type_scrutin_libelle_key" ON "ref_scrutin_type"("type_scrutin_code", "type_scrutin_libelle");

-- CreateIndex
CREATE UNIQUE INDEX "ref_organe_type_type_organe_key" ON "ref_organe_type"("type_organe");

-- CreateIndex
CREATE INDEX "ref_acteurs_photos_acteur_uid_idx" ON "ref_acteurs_photos"("acteur_uid");

-- CreateIndex
CREATE INDEX "ref_acteurs_photos_legislature_idx" ON "ref_acteurs_photos"("legislature");

-- CreateIndex
CREATE UNIQUE INDEX "ref_acteurs_photos_acteur_uid_legislature_key" ON "ref_acteurs_photos"("acteur_uid", "legislature");

-- CreateIndex
CREATE UNIQUE INDEX "amendements_co_auteurs_row_hash_key" ON "amendements_co_auteurs"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "dossier_parlementaire_row_hash_key" ON "dossier_parlementaire"("row_hash");

-- CreateIndex
CREATE INDEX "dossier_initiateur_dossier_uid_idx" ON "dossier_initiateur"("dossier_uid");

-- CreateIndex
CREATE UNIQUE INDEX "dossier_initiateur_row_hash_key" ON "dossier_initiateur"("row_hash");

-- CreateIndex
CREATE INDEX "acte_legislatif_dossier_uid_idx" ON "acte_legislatif"("dossier_uid");

-- CreateIndex
CREATE INDEX "acte_legislatif_parent_acte_uid_idx" ON "acte_legislatif"("parent_acte_uid");

-- CreateIndex
CREATE UNIQUE INDEX "acte_legislatif_row_hash_key" ON "acte_legislatif"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acte_rapporteur_row_hash_key" ON "acte_rapporteur"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acte_texte_associe_row_hash_key" ON "acte_texte_associe"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acte_reunion_row_hash_key" ON "acte_reunion"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acte_vote_row_hash_key" ON "acte_vote"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "acte_decision_row_hash_key" ON "acte_decision"("row_hash");

-- CreateIndex
CREATE INDEX "documents_parlementaires_uid_idx" ON "documents_parlementaires"("uid");

-- CreateIndex
CREATE UNIQUE INDEX "documents_parlementaires_row_hash_key" ON "documents_parlementaires"("row_hash");

-- CreateIndex
CREATE INDEX "documents_classifications_document_uid_idx" ON "documents_classifications"("document_uid");

-- CreateIndex
CREATE UNIQUE INDEX "documents_classifications_row_hash_key" ON "documents_classifications"("row_hash");

-- CreateIndex
CREATE INDEX "documents_auteurs_document_uid_idx" ON "documents_auteurs"("document_uid");

-- CreateIndex
CREATE UNIQUE INDEX "documents_auteurs_row_hash_key" ON "documents_auteurs"("row_hash");

-- CreateIndex
CREATE INDEX "documents_co_signataires_document_uid_idx" ON "documents_co_signataires"("document_uid");

-- CreateIndex
CREATE UNIQUE INDEX "documents_co_signataires_row_hash_key" ON "documents_co_signataires"("row_hash");

-- CreateIndex
CREATE UNIQUE INDEX "documents_organes_referents_row_hash_key" ON "documents_organes_referents"("row_hash");

-- CreateIndex
CREATE INDEX "documents_imprimeries_document_uid_idx" ON "documents_imprimeries"("document_uid");

-- CreateIndex
CREATE UNIQUE INDEX "documents_imprimeries_row_hash_key" ON "documents_imprimeries"("row_hash");

-- CreateIndex
CREATE INDEX "documents_depot_amendements_document_uid_idx" ON "documents_depot_amendements"("document_uid");

-- CreateIndex
CREATE UNIQUE INDEX "documents_depot_amendements_row_hash_key" ON "documents_depot_amendements"("row_hash");

-- AddForeignKey
ALTER TABLE "param_current_legislatures" ADD CONSTRAINT "param_current_legislatures_legislature_id_fkey" FOREIGN KEY ("legislature_id") REFERENCES "param_legislatures"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "param_data_sources" ADD CONSTRAINT "param_data_sources_domain_id_fkey" FOREIGN KEY ("domain_id") REFERENCES "ref_data_domains"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "param_data_sources" ADD CONSTRAINT "param_data_sources_legislature_id_fkey" FOREIGN KEY ("legislature_id") REFERENCES "param_legislatures"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "monitor_data_download" ADD CONSTRAINT "monitor_data_download_source_id_fkey" FOREIGN KEY ("source_id") REFERENCES "param_data_sources"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acteurs_adresses_postales" ADD CONSTRAINT "acteurs_adresses_postales_acteur_uid_fkey" FOREIGN KEY ("acteur_uid") REFERENCES "acteurs"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acteurs_adresses_mails" ADD CONSTRAINT "acteurs_adresses_mails_acteur_uid_fkey" FOREIGN KEY ("acteur_uid") REFERENCES "acteurs"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acteurs_reseaux_sociaux" ADD CONSTRAINT "acteurs_reseaux_sociaux_acteur_uid_fkey" FOREIGN KEY ("acteur_uid") REFERENCES "acteurs"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acteurs_telephones" ADD CONSTRAINT "acteurs_telephones_acteur_uid_fkey" FOREIGN KEY ("acteur_uid") REFERENCES "acteurs"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acteurs_groupes" ADD CONSTRAINT "acteurs_groupes_acteur_uid_fkey" FOREIGN KEY ("acteur_uid") REFERENCES "acteurs"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acteurs_groupes" ADD CONSTRAINT "acteurs_groupes_groupe_id_fkey" FOREIGN KEY ("groupe_id") REFERENCES "groupes_parlementaires"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scrutins_groupes" ADD CONSTRAINT "scrutins_groupes_scrutin_uid_fkey" FOREIGN KEY ("scrutin_uid") REFERENCES "scrutins"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scrutins_groupes" ADD CONSTRAINT "scrutins_groupes_groupe_id_fkey" FOREIGN KEY ("groupe_id") REFERENCES "groupes_parlementaires"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "votes_deputes" ADD CONSTRAINT "votes_deputes_scrutin_uid_fkey" FOREIGN KEY ("scrutin_uid") REFERENCES "scrutins"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "votes_deputes" ADD CONSTRAINT "votes_deputes_depute_id_fkey" FOREIGN KEY ("depute_id") REFERENCES "deputes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "votes_deputes" ADD CONSTRAINT "votes_deputes_groupe_id_fkey" FOREIGN KEY ("groupe_id") REFERENCES "groupes_parlementaires"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scrutins_agregats" ADD CONSTRAINT "scrutins_agregats_scrutin_uid_fkey" FOREIGN KEY ("scrutin_uid") REFERENCES "scrutins"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scrutins_groupes_agregats" ADD CONSTRAINT "scrutins_groupes_agregats_scrutin_uid_fkey" FOREIGN KEY ("scrutin_uid") REFERENCES "scrutins"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scrutins_groupes_agregats" ADD CONSTRAINT "scrutins_groupes_agregats_groupe_id_fkey" FOREIGN KEY ("groupe_id") REFERENCES "groupes_parlementaires"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mandats" ADD CONSTRAINT "mandats_acteur_uid_fkey" FOREIGN KEY ("acteur_uid") REFERENCES "acteurs"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mandats_suppleants" ADD CONSTRAINT "mandats_suppleants_mandat_uid_fkey" FOREIGN KEY ("mandat_uid") REFERENCES "mandats"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ref_groupes" ADD CONSTRAINT "ref_groupes_groupe_id_fkey" FOREIGN KEY ("groupe_id") REFERENCES "groupes_parlementaires"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ref_acteurs_photos" ADD CONSTRAINT "ref_acteurs_photos_acteur_uid_fkey" FOREIGN KEY ("acteur_uid") REFERENCES "acteurs"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "amendements_co_auteurs" ADD CONSTRAINT "amendements_co_auteurs_amendement_uid_fkey" FOREIGN KEY ("amendement_uid") REFERENCES "amendements"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dossier_initiateur" ADD CONSTRAINT "dossier_initiateur_dossier_uid_fkey" FOREIGN KEY ("dossier_uid") REFERENCES "dossier_parlementaire"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acte_legislatif" ADD CONSTRAINT "acte_legislatif_parent_acte_uid_fkey" FOREIGN KEY ("parent_acte_uid") REFERENCES "acte_legislatif"("uid") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acte_legislatif" ADD CONSTRAINT "acte_legislatif_dossier_uid_fkey" FOREIGN KEY ("dossier_uid") REFERENCES "dossier_parlementaire"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acte_rapporteur" ADD CONSTRAINT "acte_rapporteur_acte_uid_fkey" FOREIGN KEY ("acte_uid") REFERENCES "acte_legislatif"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acte_texte_associe" ADD CONSTRAINT "acte_texte_associe_acte_uid_fkey" FOREIGN KEY ("acte_uid") REFERENCES "acte_legislatif"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acte_reunion" ADD CONSTRAINT "acte_reunion_acte_uid_fkey" FOREIGN KEY ("acte_uid") REFERENCES "acte_legislatif"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acte_vote" ADD CONSTRAINT "acte_vote_acte_uid_fkey" FOREIGN KEY ("acte_uid") REFERENCES "acte_legislatif"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "acte_decision" ADD CONSTRAINT "acte_decision_acte_uid_fkey" FOREIGN KEY ("acte_uid") REFERENCES "acte_legislatif"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents_classifications" ADD CONSTRAINT "documents_classifications_document_uid_fkey" FOREIGN KEY ("document_uid") REFERENCES "documents_parlementaires"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents_auteurs" ADD CONSTRAINT "documents_auteurs_document_uid_fkey" FOREIGN KEY ("document_uid") REFERENCES "documents_parlementaires"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents_co_signataires" ADD CONSTRAINT "documents_co_signataires_document_uid_fkey" FOREIGN KEY ("document_uid") REFERENCES "documents_parlementaires"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents_organes_referents" ADD CONSTRAINT "documents_organes_referents_document_uid_fkey" FOREIGN KEY ("document_uid") REFERENCES "documents_parlementaires"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents_imprimeries" ADD CONSTRAINT "documents_imprimeries_document_uid_fkey" FOREIGN KEY ("document_uid") REFERENCES "documents_parlementaires"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "documents_depot_amendements" ADD CONSTRAINT "documents_depot_amendements_document_uid_fkey" FOREIGN KEY ("document_uid") REFERENCES "documents_parlementaires"("uid") ON DELETE RESTRICT ON UPDATE CASCADE;
