import * as fs from 'fs';
import * as path from 'path';
import { Amendement, AmendementCoAuteur } from './entities/Amendement.entity';
import { IExtractor } from '../../infrastructure/IExtractor';
import {extractNilableValue} from "../../infrastructure/impl/xml-nil.utils";

export class AmendementExtractor implements IExtractor {
    constructor(private readonly legislatureSnapshot: number) {}


    private amendements: Amendement[] = [];
    private coAuteurs: AmendementCoAuteur[] = [];
    private errors: Array<{ file: string; error: string }> = [];

    async processFile(filePath: string): Promise<void> {
        try {
            const content = fs.readFileSync(filePath, 'utf-8');
            const data = JSON.parse(content);
            this.extractData(data);
        } catch (error) {
            this.errors.push({
                file: path.basename(filePath),
                error: error instanceof Error ? error.message : String(error)
            });
        }
    }

    getTables(): Record<string, any[]> {
        return {
            amendements: this.amendements,
            amendementsCoAuteurs: this.coAuteurs
        };
    }

    getErrors(): Array<{ file: string; error: string }> {
        return this.errors;
    }


    private extractData(data: any): void {
        const amend = data.amendement || data;
        if (!amend.uid) throw new Error('Missing uid');

        // ── identification ──────────────────────────────────────
        const identification = amend.identification || {};

        // ── signataires.auteur ───────────────────────────────────
        const auteur = amend.signataires?.auteur || {};

        // ── pointeurFragmentTexte ────────────────────────────────
        const division = amend.pointeurFragmentTexte?.division || {};
        const alinea   = amend.pointeurFragmentTexte?.amendementStandard?.alinea || {};

        // ── cycleDeVie ───────────────────────────────────────────
        const cycle    = amend.cycleDeVie || {};
        const etat     = cycle.etatDesTraitements?.etat || {};
        const sousEtat = cycle.etatDesTraitements?.sousEtat || {};

        this.amendements.push({
            uid:                  amend.uid,
            chronotag:            amend.chronotag || null,
            legislature:          amend.legislature || null,

            numero_long:          identification.numeroLong || null,
            numero_ordre:         identification.numeroOrdreDepot || null,
            numero_rect:          identification.numeroRect || null,
            organe_examen:        identification.prefixeOrganeExamen || null,

            examen_ref:           amend.examenRef || null,
            texte_leg_ref:        amend.texteLegislatifRef || null,

            acteur_uid:           extractNilableValue(auteur.acteurRef),
            groupe_politique_ref: extractNilableValue(auteur.groupePolitiqueRef),
            type_auteur:          auteur.typeAuteur || null,

            division_titre:       division.titre || null,
            division_type:        division.type || null,
            division_avant_apres: division.avant_A_Apres || null,
            alinea_numero:        alinea.numero || null,

            dispositif:           amend.corps?.contenuAuteur?.dispositif || null,
            expose_sommaire:      amend.corps?.contenuAuteur?.exposeSommaire || null,

            date_depot:           extractNilableValue(cycle.dateDepot) || null,
            date_publication:     extractNilableValue(cycle.datePublication) || null,
            date_sort:            extractNilableValue(cycle.dateSort),
            sort:                 extractNilableValue(cycle.sort),
            etat_code:            etat.code || null,
            etat_libelle:         etat.libelle || null,
            sous_etat_code:       sousEtat.code || null,
            sous_etat_libelle:    sousEtat.libelle || null,

            article99:            amend.article99 === 'true' ? true
                : amend.article99 === 'false' ? false : null,
        });

        this.extractCoAuteurs(amend.uid, amend.signataires);
    }

    /**
     * cosignataires.acteurRef est un string[] direct (pas des objets).
     * Peut aussi être un string seul si un seul cosignataire.
     */
    private extractCoAuteurs(amendementUid: string, signataires: any): void {
        const raw = signataires?.cosignataires?.acteurRef;
        if (!raw) return;

        const list: string[] = Array.isArray(raw) ? raw : [raw];

        for (const acteurUid of list) {
            if (typeof acteurUid === 'string' && acteurUid.trim()) {
                this.coAuteurs.push({ amendement_uid: amendementUid, acteur_uid: acteurUid });
            }
        }
    }
}