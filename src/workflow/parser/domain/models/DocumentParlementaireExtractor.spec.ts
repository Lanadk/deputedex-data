import { DocumentParlementaireExtractor } from './DocumentParlementaireExtractor';
import { writeTempJsonFile } from './test-helpers/tempJsonFile';

function baseDocument(overrides: Record<string, any> = {}): any {
    return {
        document: {
            uid: 'DOCANR5L17B0001',
            legislature: '17',
            denominationStructurelle: { '#text': 'PROJET DE LOI' },
            provenance: { '#text': 'AN' },
            titres: { titrePrincipal: { '#text': 'Titre principal' }, titrePrincipalCourt: { '#text': 'Titre court' } },
            dossierRef: { '#text': 'DLR5L17B1' },
            redacteur: { '#text': 'Bureau' },
            cycleDeVie: {
                chrono: {
                    dateCreation: { '#text': '2024-01-01' },
                    dateDepot: { '#text': '2024-01-02' },
                    datePublication: { '#text': '2024-01-03' },
                    datePublicationWeb: { '#text': '2024-01-03' },
                },
            },
            notice: { numNotice: { '#text': 'N1' }, formule: { '#text': 'F1' }, adoptionConforme: 'true' },
            ...overrides,
        },
    };
}

describe('DocumentParlementaireExtractor', () => {
    let cleanup: () => void;

    afterEach(() => cleanup?.());

    it('extracts the document core fields, resolving nilable values', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(baseDocument());
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.documents).toHaveLength(1);
        expect(tables.documents[0]).toMatchObject({
            uid: 'DOCANR5L17B0001',
            legislature: 17,
            denomination_structurelle: 'PROJET DE LOI',
            provenance: 'AN',
            titre_principal: 'Titre principal',
            titre_principal_court: 'Titre court',
            dossier_ref: 'DLR5L17B1',
            date_creation: '2024-01-01',
            num_notice: 'N1',
            adoption_conforme: true,
            legislature_snapshot: 17,
        });
        expect(extractor.getErrors()).toEqual([]);
    });

    it('sets adoption_conforme to null when the notice field is absent', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const data = baseDocument();
        delete data.document.notice.adoptionConforme;
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().documents[0].adoption_conforme).toBeNull();
    });

    it('extracts classification when present', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const data = baseDocument({
            classification: {
                famille: { depot: { code: 'D1', libelle: 'Dépôt' }, classe: { code: 'C1', libelle: 'Classe' } },
                type: { code: 'T1', libelle: 'Type' },
                sousType: { code: 'ST1', libelle: 'Sous-type', libelleEdition: 'Edition' },
                statutAdoption: { code: 'SA1', libelle: 'Statut' },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().documentsClassifications).toEqual([
            expect.objectContaining({
                document_uid: 'DOCANR5L17B0001',
                depot_code: 'D1',
                classe_code: 'C1',
                type_code: 'T1',
                sous_type_code: 'ST1',
                statut_adoption_code: 'SA1',
            }),
        ]);
    });

    it('extracts multiple auteurs and co-signataires', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const data = baseDocument({
            auteurs: {
                auteur: [
                    { acteur: { acteurRef: { '#text': 'PA1' }, qualite: { '#text': 'Rapporteur' } } },
                    { organe: { organeRef: { '#text': 'PO1' } } },
                ],
            },
            coSignataires: {
                coSignataire: { acteur: { acteurRef: { '#text': 'PA2' } } },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.documentsAuteurs).toHaveLength(2);
        expect(tables.documentsAuteurs[0]).toMatchObject({ acteur_uid: 'PA1', qualite: 'Rapporteur' });
        expect(tables.documentsAuteurs[1]).toMatchObject({ organe_uid: 'PO1' });

        expect(tables.documentsCoSignataires).toEqual([
            expect.objectContaining({ document_uid: 'DOCANR5L17B0001', acteur_uid: 'PA2' }),
        ]);
    });

    it('extracts organesReferents from an array of refs', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const data = baseDocument({ organesReferents: { organeRef: ['PO1', 'PO2'] } });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().documentsOrganesReferents.map(o => o.organe_uid)).toEqual(['PO1', 'PO2']);
    });

    it('extracts imprimerie fields, coercing nbPage to a number', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const data = baseDocument({
            imprimerie: { ISSN: { '#text': '1234' }, ISBN: null, DIAN: null, nbPage: '42', prix: { '#text': '5€' } },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().documentsImprimeries[0]).toMatchObject({
            document_uid: 'DOCANR5L17B0001',
            issn: '1234',
            nb_page: 42,
            prix: '5€',
        });
    });

    it('extracts SEANCE and COMMISSION amendement deposit rules', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const data = baseDocument({
            depotAmendements: {
                amendementsSeance: { amendable: 'true', dateLimiteDepot: { '#text': '2024-02-01' } },
                amendementsCommission: {
                    commission: [
                        { organeRef: { '#text': 'PO1' }, amendable: 'false', dateLimiteDepot: { '#text': '2024-02-02' } },
                    ],
                },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);
        const rows = extractor.getTables().documentsDepotsAmendements;

        expect(rows).toHaveLength(2);
        expect(rows[0]).toMatchObject({ type_depot: 'SEANCE', amendable: true, date_limite_depot: '2024-02-01' });
        expect(rows[1]).toMatchObject({ type_depot: 'COMMISSION', organe_uid: 'PO1', amendable: false });
    });

    it('records a parse error for malformed JSON without throwing', async () => {
        const extractor = new DocumentParlementaireExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile('{broken', { raw: true });
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getErrors()).toHaveLength(1);
        expect(extractor.getTables().documents).toEqual([]);
    });
});
