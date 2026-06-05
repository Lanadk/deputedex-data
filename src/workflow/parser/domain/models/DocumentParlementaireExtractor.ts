import {
    DocumentAuteur,
    DocumentClassification,
    DocumentCoSignataire, DocumentDepotAmendement, DocumentImprimerie, DocumentOrganeReferent,
    DocumentParlementaire
} from "./entities/Document.entity";
import {extractNilableValue} from "../../infrastructure/impl/xml-nil.utils";
import {computeRowHash} from "../../../../utils/hash";
import {IExtractor} from "../../infrastructure/IExtractor";
import fs from "fs";
import path from "path";
import {asArray} from "../../infrastructure/impl/utils";

export class DocumentParlementaireExtractor implements IExtractor{

    public documents: DocumentParlementaire[] = [];
    public classifications: DocumentClassification[] = [];
    public auteurs: DocumentAuteur[] = [];
    public coSignataires: DocumentCoSignataire[] = [];
    public organesReferents: DocumentOrganeReferent[] = [];
    public imprimeries: DocumentImprimerie[] = [];
    public depotsAmendements: DocumentDepotAmendement[] = [];


    private errors: Array<{ file: string; error: string }> = [];

    constructor(
        private readonly legislatureSnapshot: number
    ) {
    }

    async processFile(filePath: string): Promise<void> {
        try {
            const content = fs.readFileSync(filePath, "utf-8");
            const data = JSON.parse(content);

            this.extractData(data);

        } catch (error) {
            this.errors.push({
                file: path.basename(filePath),
                error: error instanceof Error
                    ? error.message
                    : String(error)
            });
        }
    }

    getErrors(): Array<{ file: string; error: string }> {
        return this.errors;
    }

    getTables(): Record<string, any[]> {
        return {
            documents: this.documents,
            documentsClassifications: this.classifications,
            documentsAuteurs: this.auteurs,
            documentsCoSignataires: this.coSignataires,
            documentsOrganesReferents: this.organesReferents,
            documentsImprimeries: this.imprimeries,
            documentsDepotsAmendements: this.depotsAmendements,
        };
    }


    private extractData(data: any): void {
        const document = data.document ?? data;

        const uid = document.uid;

        this.extractDocument(document);
        this.extractClassification(uid, document);
        this.extractAuteurs(uid, document);
        this.extractCoSignataires(uid, document);
        this.extractOrganesReferents(uid, document);
        this.extractImprimerie(uid, document);
        this.extractDepotAmendements(uid, document);
    }

    private extractDocument(document: any): void {
        const obj = {
            uid: document.uid,

            legislature: Number(document.legislature),
            xsi_type: document["@xsi:type"],
            denomination_structurelle: extractNilableValue(document.denominationStructurelle),
            provenance:extractNilableValue(document.provenance),
            titre_principal: extractNilableValue(document.titres?.titrePrincipal),
            titre_principal_court: extractNilableValue(document.titres?.titrePrincipalCourt),
            dossier_ref: extractNilableValue(document.dossierRef),
            redacteur: extractNilableValue(document.redacteur),
            date_creation: extractNilableValue(document.cycleDeVie?.chrono?.dateCreation),
            date_depot: extractNilableValue(document.cycleDeVie?.chrono?.dateDepot),
            date_publication: extractNilableValue(document.cycleDeVie?.chrono?.datePublication),
            date_publication_web: extractNilableValue(document.cycleDeVie?.chrono?.datePublicationWeb),
            num_notice: extractNilableValue(document.notice?.numNotice),
            formule: extractNilableValue(document.notice?.formule),
            adoption_conforme: document.notice?.adoptionConforme === undefined
                    ? null
                    : document.notice.adoptionConforme === "true",
            legislature_snapshot: this.legislatureSnapshot
        };

        this.documents.push({
            ...obj,
            row_hash: computeRowHash(obj)
        });
    }

    private extractClassification(
        documentUid: string,
        document: any
    ): void {
        const classification = document.classification;

        if (!classification) {
            return;
        }

        const obj = {
            document_uid: documentUid,
            depot_code: extractNilableValue(classification.famille?.depot?.code),
            depot_libelle: extractNilableValue(classification.famille?.depot?.libelle),
            classe_code: extractNilableValue(classification.famille?.classe?.code),
            classe_libelle: extractNilableValue(classification.famille?.classe?.libelle),
            type_code: extractNilableValue(classification.type?.code),
            type_libelle: extractNilableValue(classification.type?.libelle),
            sous_type_code: extractNilableValue(classification.sousType?.code),
            sous_type_libelle: extractNilableValue(classification.sousType?.libelle),
            sous_type_libelle_edition: extractNilableValue(classification.sousType?.libelleEdition),
            statut_adoption_code: extractNilableValue(classification.statutAdoption?.code),
            statut_adoption_libelle: extractNilableValue(classification.statutAdoption?.libelle),
            legislature_snapshot: this.legislatureSnapshot
        };

        this.classifications.push({
            ...obj,
            row_hash: computeRowHash(obj)
        });
    }

    private extractAuteurs(
        documentUid: string,
        document: any
    ): void {
        const auteurs = asArray(document.auteurs?.auteur);

        for (const auteur of auteurs) {
            const obj = {
                document_uid: documentUid,
                acteur_uid: extractNilableValue(auteur.acteur?.acteurRef),
                organe_uid: extractNilableValue(auteur.organe?.organeRef),
                qualite: extractNilableValue(auteur.acteur?.qualite),
                legislature_snapshot: this.legislatureSnapshot
            };

            this.auteurs.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }
    }

    private extractCoSignataires(
        documentUid: string,
        document: any
    ): void {
        const cosignataires = asArray(document.coSignataires?.coSignataire);

        for (const cosignataire of cosignataires) {
            const obj = {
                document_uid: documentUid,
                acteur_uid: extractNilableValue(cosignataire.acteur?.acteurRef),
                organe_uid: extractNilableValue(cosignataire.organe?.organeRef),
                legislature_snapshot: this.legislatureSnapshot
            };

            this.coSignataires.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }
    }

    private extractOrganesReferents(
        documentUid: string,
        document: any
    ): void {
        const refs = asArray(document.organesReferents?.organeRef);

        for (const ref of refs) {
            const obj = {
                document_uid: documentUid,
                organe_uid: ref,
                legislature_snapshot: this.legislatureSnapshot
            };

            this.organesReferents.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }
    }

    private extractImprimerie(
        documentUid: string,
        document: any
    ): void {
        const imprimerie = document.imprimerie;

        if (!imprimerie) {
            return;
        }

        const obj = {
            document_uid: documentUid,
            issn: extractNilableValue(imprimerie.ISSN),
            isbn: extractNilableValue(imprimerie.ISBN),
            dian: extractNilableValue(imprimerie.DIAN),
            nb_page: imprimerie.nbPage
                    ? Number(imprimerie.nbPage)
                    : null,
            prix: extractNilableValue(imprimerie.prix),
            legislature_snapshot: this.legislatureSnapshot
        };

        this.imprimeries.push({
            ...obj,
            row_hash: computeRowHash(obj)
        });
    }

    private extractDepotAmendements(
        documentUid: string,
        document: any
    ): void {
        const depot = document.depotAmendements;

        if (!depot) {
            return;
        }

        if (depot.amendementsSeance) {
            const obj = {
                document_uid: documentUid,
                type_depot: "SEANCE" as const,
                organe_uid: null,
                amendable: depot.amendementsSeance.amendable === undefined
                        ? null
                        : depot.amendementsSeance.amendable === "true",
                date_limite_depot: extractNilableValue(depot.amendementsSeance.dateLimiteDepot),
                legislature_snapshot: this.legislatureSnapshot
            };

            this.depotsAmendements.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }

        const commissions = asArray(depot.amendementsCommission?.commission);

        for (const commission of commissions) {
            const obj = {
                document_uid: documentUid,
                type_depot: "COMMISSION" as const,
                organe_uid: extractNilableValue(commission.organeRef),
                amendable: commission.amendable === undefined
                        ? null
                        : commission.amendable === "true",
                date_limite_depot: extractNilableValue(commission.dateLimiteDepot),
                legislature_snapshot: this.legislatureSnapshot
            };

            this.depotsAmendements.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }
    }


}