import { AmendementExtractor } from './AmendementExtractor';
import { writeTempJsonFile } from './test-helpers/tempJsonFile';

function baseAmendement(overrides: Record<string, any> = {}): any {
    return {
        amendement: {
            uid: 'AMANR5L17PO59021B1',
            chronotag: 'chrono-1',
            legislature: '17',
            identification: { numeroLong: '1', numeroOrdreDepot: '1', numeroRect: null, prefixeOrganeExamen: 'AN' },
            examenRef: 'EXAM1',
            texteLegislatifRef: 'TXT1',
            signataires: {
                auteur: { acteurRef: { '#text': 'PA1' }, groupePolitiqueRef: { '#text': 'PO1' }, typeAuteur: 'DEPUTE' },
            },
            pointeurFragmentTexte: {
                division: { titre: 'Article 1', type: 'ARTICLE', avant_A_Apres: 'A' },
                amendementStandard: { alinea: { numero: '3' } },
            },
            corps: { contenuAuteur: { dispositif: 'Le dispositif', exposeSommaire: "L'exposé" } },
            cycleDeVie: {
                dateDepot: { '#text': '2024-09-01' },
                datePublication: { '#text': '2024-09-02' },
                dateSort: { '#text': '2024-09-10' },
                sort: { '#text': 'adopte' },
                etatDesTraitements: {
                    etat: { code: 'AC', libelle: 'Amendement caduc' },
                    sousEtat: { code: 'SC', libelle: 'sous-etat' },
                },
            },
            article99: 'false',
            ...overrides,
        },
    };
}

describe('AmendementExtractor', () => {
    let cleanup: () => void;

    afterEach(() => cleanup?.());

    it('extracts the amendement core fields, resolving nilable auteur refs', async () => {
        const extractor = new AmendementExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(baseAmendement());
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.amendements).toHaveLength(1);
        expect(tables.amendements[0]).toMatchObject({
            uid: 'AMANR5L17PO59021B1',
            numero_long: '1',
            organe_examen: 'AN',
            acteur_uid: 'PA1',
            groupe_politique_ref: 'PO1',
            type_auteur: 'DEPUTE',
            division_titre: 'Article 1',
            alinea_numero: '3',
            dispositif: 'Le dispositif',
            expose_sommaire: "L'exposé",
            date_depot: '2024-09-01',
            sort: 'adopte',
            etat_code: 'AC',
            sous_etat_code: 'SC',
            article99: false,
            legislature_snapshot: 17,
        });
        expect(extractor.getErrors()).toEqual([]);
    });

    it('normalizes article99 to true/false/null based on the raw string value', async () => {
        const extractor = new AmendementExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(
            baseAmendement({ uid: 'AM2', article99: undefined })
        );
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().amendements[0].article99).toBeNull();
    });

    it('extracts co-auteurs from an array of acteurRef', async () => {
        const extractor = new AmendementExtractor(17);
        const data = baseAmendement();
        data.amendement.signataires.cosignataires = { acteurRef: ['PA2', 'PA3'] };
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().amendementsCoAuteurs).toHaveLength(2);
        expect(extractor.getTables().amendementsCoAuteurs.map(a => a.acteur_uid)).toEqual(['PA2', 'PA3']);
    });

    it('extracts a single co-auteur when acteurRef is not an array', async () => {
        const extractor = new AmendementExtractor(17);
        const data = baseAmendement();
        data.amendement.signataires.cosignataires = { acteurRef: 'PA2' };
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().amendementsCoAuteurs).toHaveLength(1);
        expect(extractor.getTables().amendementsCoAuteurs[0]).toMatchObject({
            amendement_uid: 'AMANR5L17PO59021B1',
            acteur_uid: 'PA2',
        });
    });

    it('ignores blank co-auteur entries', async () => {
        const extractor = new AmendementExtractor(17);
        const data = baseAmendement();
        data.amendement.signataires.cosignataires = { acteurRef: ['PA2', '  ', 42] };
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().amendementsCoAuteurs.map(a => a.acteur_uid)).toEqual(['PA2']);
    });

    it('records a parse error instead of throwing when uid is missing', async () => {
        const extractor = new AmendementExtractor(17);
        const data = baseAmendement();
        delete data.amendement.uid;
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().amendements).toHaveLength(0);
        expect(extractor.getErrors()).toEqual([{ file: expect.stringContaining('.json'), error: 'Missing uid' }]);
    });

    it('records a parse error for malformed JSON without throwing', async () => {
        const extractor = new AmendementExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile('{{{', { raw: true });
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getErrors()).toHaveLength(1);
    });
});
