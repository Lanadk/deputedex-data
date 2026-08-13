import { DossiersParlementairesExtractor } from './DossierParlementaireExtractor';
import { writeTempJsonFile } from './test-helpers/tempJsonFile';

function baseDossier(overrides: Record<string, any> = {}): any {
    return {
        dossierParlementaire: {
            uid: 'DLR5L17B1',
            legislature: '17',
            titreDossier: { titre: 'Titre du dossier', titreChemin: null, senatChemin: null },
            procedureParlementaire: { code: 'PJL', libelle: 'Projet de loi' },
            ...overrides,
        },
    };
}

describe('DossiersParlementairesExtractor', () => {
    let cleanup: () => void;

    afterEach(() => cleanup?.());

    it('extracts the dossier core fields', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(baseDossier());
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.dossiersParlementaire).toHaveLength(1);
        expect(tables.dossiersParlementaire[0]).toMatchObject({
            uid: 'DLR5L17B1',
            legislature: 17,
            titre: 'Titre du dossier',
            procedure_code: 'PJL',
            procedure_libelle: 'Projet de loi',
            legislature_snapshot: 17,
        });
        expect(extractor.getErrors()).toEqual([]);
    });

    it('extracts the first initiateur acteur and organe', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const data = baseDossier({
            initiateur: {
                acteurs: { acteur: [{ acteurRef: 'PA1', mandatRef: 'MA1' }, { acteurRef: 'PA2', mandatRef: 'MA2' }] },
                organes: { organe: { organeRef: 'PO1' } },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().dossiersInitiateur).toHaveLength(1);
        expect(extractor.getTables().dossiersInitiateur[0]).toMatchObject({
            dossier_uid: 'DLR5L17B1',
            acteur_uid: 'PA1',
            mandat_uid: 'MA1',
            organe_uid: 'PO1',
        });
    });

    it('does not emit an initiateur row when initiateur is absent', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(baseDossier());
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().dossiersInitiateur).toEqual([]);
    });

    it('recursively extracts nested actesLegislatifs, tracking the parent acte uid', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const data = baseDossier({
            actesLegislatifs: {
                acteLegislatif: {
                    uid: 'ACT1',
                    '@xsi:type': 'DepotType',
                    codeActe: 'AN1',
                    libelleActe: { nomCanonique: 'Dépôt', libelleCourt: 'Dépôt' },
                    organeRef: 'PO2',
                    dateActe: '2024-01-01',
                    actesLegislatifs: {
                        acteLegislatif: { uid: 'ACT2', codeActe: 'AN2' },
                    },
                },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);
        const actes = extractor.getTables().acteLegislatif;

        expect(actes).toHaveLength(2);
        expect(actes[0]).toMatchObject({ uid: 'ACT1', dossier_uid: 'DLR5L17B1', parent_acte_uid: null, type_acte: 'DepotType' });
        expect(actes[1]).toMatchObject({ uid: 'ACT2', dossier_uid: 'DLR5L17B1', parent_acte_uid: 'ACT1', type_acte: 'UNKNOWN' });
    });

    it('extracts rapporteurs, textesAssocies (both single and array forms), reunion, votes and decision for an acte', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const data = baseDossier({
            actesLegislatifs: {
                acteLegislatif: {
                    uid: 'ACT1',
                    rapporteurs: { rapporteur: { acteurRef: 'PA2', typeRapporteur: 'RAPPORTEUR' } },
                    texteAssocie: 'TXT-simple',
                    textesAssocies: { texteAssocie: [{ refTexteAssocie: 'TXT1', typeTexte: 'PJL' }] },
                    reunionRef: 'REU1',
                    voteRefs: { voteRef: ['VOTE1', 'VOTE2'] },
                    statutConclusion: { fam_code: 'ADOPT', libelle: 'Adopté' },
                },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.acteRapporteur).toEqual([
            expect.objectContaining({ acte_uid: 'ACT1', acteur_uid: 'PA2', type_rapporteur: 'RAPPORTEUR' }),
        ]);

        expect(tables.acteTexteAssocie).toHaveLength(2);
        expect(tables.acteTexteAssocie[0]).toMatchObject({ acte_uid: 'ACT1', reference_texte: 'TXT-simple', type_texte: null });
        expect(tables.acteTexteAssocie[1]).toMatchObject({ acte_uid: 'ACT1', reference_texte: 'TXT1', type_texte: 'PJL' });

        expect(tables.acteReunion).toEqual([expect.objectContaining({ acte_uid: 'ACT1', reunion_ref: 'REU1' })]);

        expect(tables.acteVote).toHaveLength(2);
        expect(tables.acteVote.map(v => v.vote_ref)).toEqual(['VOTE1', 'VOTE2']);

        expect(tables.acteDecision).toEqual([
            expect.objectContaining({ acte_uid: 'ACT1', famille_code: 'ADOPT', libelle: 'Adopté' }),
        ]);
    });

    it('skips an acteLegislatif entry with no uid', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const data = baseDossier({ actesLegislatifs: { acteLegislatif: { codeActe: 'NO-UID' } } });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().acteLegislatif).toEqual([]);
    });

    it('records a parse error instead of throwing when uid is missing', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const data = baseDossier();
        delete data.dossierParlementaire.uid;
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().dossiersParlementaire).toHaveLength(0);
        expect(extractor.getErrors()).toEqual([
            { file: expect.stringContaining('.json'), error: 'Missing dossier uid' },
        ]);
    });

    it('records a parse error for malformed JSON without throwing', async () => {
        const extractor = new DossiersParlementairesExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile('nope', { raw: true });
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getErrors()).toHaveLength(1);
    });
});
