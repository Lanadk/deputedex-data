import * as fs from "fs";
import * as path from "path";

import {
    ActeDecision,
    ActeLegislatif,
    ActeRapporteur,
    ActeReunion,
    ActeTexteAssocie,
    ActeVote,
    DossierInitiateur,
    DossierParlementaire
} from "./entities/DossierParlementaire.entity";

import {IExtractor} from "../../infrastructure/IExtractor";
import {computeRowHash} from "../../../../utils/hash";
import {extractNilableValue} from "../../infrastructure/impl/xml-nil.utils";
import {asArray} from "../../infrastructure/impl/utils";

export class DossiersParlementairesExtractor implements IExtractor {

    private dossiers: DossierParlementaire[] = [];
    private initiateurs: DossierInitiateur[] = [];
    private actes: ActeLegislatif[] = [];
    private rapporteurs: ActeRapporteur[] = [];
    private textesAssocies: ActeTexteAssocie[] = [];
    private reunions: ActeReunion[] = [];
    private votes: ActeVote[] = [];
    private decisions: ActeDecision[] = [];

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
            dossiersParlementaire: this.dossiers,
            dossiersInitiateur: this.initiateurs,
            acteLegislatif: this.actes,
            acteRapporteur: this.rapporteurs,
            acteTexteAssocie: this.textesAssocies,
            acteReunion: this.reunions,
            acteVote: this.votes,
            acteDecision: this.decisions
        };
    }

    private extractData(data: any): void {
        const dossier = data.dossierParlementaire || data;

        if (!dossier.uid) {
            throw new Error("Missing dossier uid");
        }

        const dossierObj = {
            uid: dossier.uid,
            legislature: parseInt(dossier.legislature) || 0,
            titre: dossier.titreDossier?.titre ?? "",
            titre_chemin: extractNilableValue(dossier.titreDossier?.titreChemin),
            senat_chemin: extractNilableValue(dossier.titreDossier?.senatChemin),
            procedure_code: extractNilableValue(dossier.procedureParlementaire?.code),
            procedure_libelle: extractNilableValue(dossier.procedureParlementaire?.libelle),
            legislature_snapshot: this.legislatureSnapshot
        };

        this.dossiers.push({
            ...dossierObj,
            row_hash: computeRowHash(dossierObj)
        });

        this.extractInitiateurs(dossier.uid, dossier.initiateur);
        const actes = asArray(dossier.actesLegislatifs?.acteLegislatif);

        for (const acte of actes) {
            this.extractActe(
                dossier.uid,
                null,
                acte
            );
        }
    }

    private extractInitiateurs(
        dossierUid: string,
        initiateur: any
    ): void {
        if (!initiateur) return;

        const acteurs = asArray(initiateur.acteurs?.acteur);
        const organes = asArray(initiateur.organes?.organe);
        const acteur = acteurs.length > 0
                ? acteurs[0]
                : null;
        const organe = organes.length > 0
                ? organes[0]
                : null;

        const obj = {
            dossier_uid: dossierUid,
            acteur_uid: acteur?.acteurRef ?? null,
            mandat_uid: acteur?.mandatRef ?? null,
            organe_uid: organe?.organeRef?.uid ?? organe?.organeRef ?? null,
            legislature_snapshot: this.legislatureSnapshot
        };

        this.initiateurs.push({
            ...obj,
            row_hash: computeRowHash(obj)
        });
    }

    private extractActe(
        dossierUid: string,
        parentActeUid: string | null,
        acte: any
    ): void {
        if (!acte?.uid) return;

        const uid = acte.uid;

        const acteObj = {
            uid,
            dossier_uid: dossierUid,
            parent_acte_uid: parentActeUid,
            type_acte: acte["@xsi:type"] ?? "UNKNOWN",
            code_acte: extractNilableValue(acte.codeActe),
            nom_canonique: extractNilableValue(acte.libelleActe?.nomCanonique),
            libelle_court: extractNilableValue(acte.libelleActe?.libelleCourt),
            organe_uid: extractNilableValue(acte.organeRef),
            date_acte: extractNilableValue(acte.dateActe),
            legislature_snapshot: this.legislatureSnapshot
        };

        this.actes.push({
            ...acteObj,
            row_hash: computeRowHash(acteObj)
        });

        this.extractRapporteurs(uid, acte);
        this.extractTextesAssocies(uid, acte);
        this.extractReunion(uid, acte);
        this.extractDecision(uid, acte);
        this.extractVotes(uid, acte);
        const enfants = asArray(acte.actesLegislatifs?.acteLegislatif);

        for (const enfant of enfants) {
            this.extractActe(
                dossierUid,
                uid,
                enfant
            );
        }
    }

    private extractRapporteurs(
        acteUid: string,
        acte: any
    ): void {
        const rapporteurs = asArray(acte.rapporteurs?.rapporteur);

        for (const rapporteur of rapporteurs) {
            const obj = {
                acte_uid: acteUid,
                acteur_uid: rapporteur.acteurRef,
                type_rapporteur: extractNilableValue(rapporteur.typeRapporteur),
                legislature_snapshot: this.legislatureSnapshot
            };

            this.rapporteurs.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }
    }

    private extractTextesAssocies(
        acteUid: string,
        acte: any
    ): void {
        if (acte.texteAssocie) {
            const obj = {
                acte_uid: acteUid,
                reference_texte: acte.texteAssocie,
                type_texte: null,
                legislature_snapshot: this.legislatureSnapshot
            };

            this.textesAssocies.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }

        const textes = asArray(acte.textesAssocies?.texteAssocie);

        for (const texte of textes) {
            const obj = {
                acte_uid: acteUid,
                reference_texte: texte.refTexteAssocie,
                type_texte: extractNilableValue(texte.typeTexte),
                legislature_snapshot: this.legislatureSnapshot
            };

            this.textesAssocies.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }
    }

    private extractReunion(
        acteUid: string,
        acte: any
    ): void {
        if (
            !acte.reunionRef &&
            !acte.odjRef
        ) {
            return;
        }

        const obj = {
            acte_uid: acteUid,
            reunion_ref: extractNilableValue(acte.reunionRef),
            odj_ref: extractNilableValue(acte.odjRef),
            legislature_snapshot: this.legislatureSnapshot
        };

        this.reunions.push({
            ...obj,
            row_hash: computeRowHash(obj)
        });
    }

    private extractVotes(
        acteUid: string,
        acte: any
    ): void {
        const votes = asArray(acte.voteRefs?.voteRef);

        for (const vote of votes) {

            const obj = {
                acte_uid: acteUid,
                vote_ref: vote,
                legislature_snapshot:
                this.legislatureSnapshot
            };

            this.votes.push({
                ...obj,
                row_hash: computeRowHash(obj)
            });
        }
    }

    private extractDecision(
        acteUid: string,
        acte: any
    ): void {
        if (!acte.statutConclusion) {
            return;
        }

        const obj = {
            acte_uid: acteUid,
            famille_code: extractNilableValue(acte.statutConclusion?.fam_code),
            libelle: extractNilableValue(acte.statutConclusion?.libelle),
            legislature_snapshot: this.legislatureSnapshot
        };

        this.decisions.push({
            ...obj,
            row_hash: computeRowHash(obj)
        });
    }
}