import { ActeursExtractor } from './ActeursExtractor';
import { ROW_HASH_PATTERN, writeTempJsonFile } from './test-helpers/tempJsonFile';

function baseActeur(overrides: Record<string, any> = {}): any {
    return {
        acteur: {
            uid: 'PA1',
            etatCivil: {
                ident: { civ: 'M.', prenom: 'Jean', nom: 'Dupont', alpha: 'DUPONT', trigramme: 'JDU' },
                infoNaissance: {
                    dateNais: '1970-01-01',
                    villeNais: 'Paris',
                    depNais: '75',
                    paysNais: 'France',
                },
                dateDeces: { '@xsi:nil': 'true', '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance' },
            },
            profession: {
                libelleCourant: 'Avocat',
                socProcINSEE: { catSocPro: '31', famSocPro: '312' },
            },
            uri_hatvp: 'http://hatvp.example/1',
            ...overrides,
        },
    };
}

describe('ActeursExtractor', () => {
    let cleanup: () => void;

    afterEach(() => {
        cleanup?.();
    });

    it('extracts the acteur core fields and stamps the legislature snapshot + a row_hash', async () => {
        const extractor = new ActeursExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(baseActeur());
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.acteurs).toHaveLength(1);
        expect(tables.acteurs[0]).toMatchObject({
            uid: 'PA1',
            civilite: 'M.',
            prenom: 'Jean',
            nom: 'Dupont',
            nom_alpha: 'DUPONT',
            trigramme: 'JDU',
            date_naissance: '1970-01-01',
            ville_naissance: 'Paris',
            departement_naissance: '75',
            pays_naissance: 'France',
            date_deces: null, // xsi:nil marker normalized to null
            profession_libelle: 'Avocat',
            profession_categorie: '31',
            profession_famille: '312',
            uri_hatvp: 'http://hatvp.example/1',
            legislature_snapshot: 17,
        });
        expect(tables.acteurs[0].row_hash).toMatch(ROW_HASH_PATTERN);
        expect(extractor.getErrors()).toEqual([]);
    });

    it('unwraps a uid provided as {"#text": ...} instead of a plain string', async () => {
        const extractor = new ActeursExtractor(17);
        const data = baseActeur();
        data.acteur.uid = { '#text': 'PA1' };
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().acteurs[0].uid).toBe('PA1');
    });

    it('extracts all four address types with their type-specific fields', async () => {
        const extractor = new ActeursExtractor(17);
        const data = baseActeur({
            adresses: {
                adresse: [
                    {
                        '@xsi:type': 'AdressePostale_Type',
                        uid: 'AD1',
                        type: '1',
                        typeLibelle: 'Adresse',
                        intitule: 'Assemblée nationale',
                        numeroRue: '126',
                        nomRue: "Rue de l'Université",
                        codePostal: '75007',
                        ville: 'Paris',
                    },
                    {
                        '@xsi:type': 'AdresseMail_Type',
                        uid: 'AD2',
                        type: '2',
                        typeLibelle: 'Mail',
                        valElec: 'jean.dupont@an.fr',
                    },
                    {
                        '@xsi:type': 'AdresseSiteWeb_Type',
                        uid: 'AD3',
                        type: '3',
                        typeLibelle: 'Facebook',
                        valElec: 'jdupont.fb',
                    },
                    {
                        '@xsi:type': 'AdresseTelephonique_Type',
                        uid: 'AD4',
                        type: '4',
                        typeLibelle: 'Téléphone',
                        adresseDeRattachement: 'AD1',
                        valElec: '0140000000',
                    },
                    null, // defensive: extractor must skip null entries in the array
                ],
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.acteursAdressesPostales).toHaveLength(1);
        expect(tables.acteursAdressesPostales[0]).toMatchObject({
            acteur_uid: 'PA1',
            uid_adresse: 'AD1',
            numero_rue: '126',
            nom_rue: "Rue de l'Université",
            code_postal: '75007',
            ville: 'Paris',
        });

        expect(tables.acteursAdressesMails).toHaveLength(1);
        expect(tables.acteursAdressesMails[0]).toMatchObject({
            acteur_uid: 'PA1',
            email: 'jean.dupont@an.fr',
        });

        expect(tables.acteursReseauxSociaux).toHaveLength(1);
        expect(tables.acteursReseauxSociaux[0]).toMatchObject({
            acteur_uid: 'PA1',
            plateforme: 'facebook',
            identifiant: 'jdupont.fb',
        });

        expect(tables.acteursTelephones).toHaveLength(1);
        expect(tables.acteursTelephones[0]).toMatchObject({
            acteur_uid: 'PA1',
            adresse_rattachement: 'AD1',
            numero: '0140000000',
        });
    });

    it.each([
        ['facebook', 'facebook'],
        ['Twitter', 'twitter'],
        ['Instagram Officiel', 'instagram'],
        ['LinkedIn', 'linkedin'],
        ['Chaine YouTube', 'youtube'],
        ['Site personnel', 'site_web'],
    ])('detects the %s platform from the address typeLibelle as %s', async (typeLibelle, expected) => {
        const extractor = new ActeursExtractor(17);
        const data = baseActeur({
            adresses: {
                adresse: {
                    '@xsi:type': 'AdresseSiteWeb_Type',
                    uid: 'AD3',
                    typeLibelle,
                    valElec: 'handle',
                },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().acteursReseauxSociaux[0].plateforme).toBe(expected);
    });

    it('extracts mandats, deduplicates GP organeRefs, and links suppleants', async () => {
        const extractor = new ActeursExtractor(17);
        const data = baseActeur({
            mandats: {
                mandat: [
                    {
                        uid: 'MA1',
                        legislature: '17',
                        typeOrgane: 'GP',
                        dateDebut: '2024-07-08',
                        datePublication: '2024-07-09',
                        preseance: '5',
                        nominPrincipale: '1',
                        infosQualite: { codeQualite: 'MEMBR', libQualite: 'Membre', libQualiteSex: 'Membre' },
                        organes: { organeRef: 'PO1' },
                        election: { lieu: { region: 'IDF', numDepartement: '075', numCirco: '01' } },
                        mandature: { premiereElection: '1' },
                        suppleants: {
                            suppleant: { suppleantRef: 'PA2', dateDebut: '2024-07-08', dateFin: null },
                        },
                    },
                    {
                        // Second GP mandat referencing the same organe: must not duplicate the set entry.
                        uid: 'MA2',
                        legislature: '17',
                        typeOrgane: 'GP',
                        dateDebut: '2024-07-08',
                        organes: { organeRef: 'PO1' },
                    },
                    {
                        // Non-GP mandat: must not feed groupesVuDesMandats at all.
                        uid: 'MA3',
                        legislature: '17',
                        typeOrgane: 'COMPER',
                        dateDebut: '2024-07-08',
                        organes: { organeRef: 'PO2' },
                    },
                ],
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.mandats).toHaveLength(3);
        expect(tables.mandats[0]).toMatchObject({
            uid: 'MA1',
            acteur_uid: 'PA1',
            legislature: 17,
            type_organe: 'GP',
            organe_uid: 'PO1',
            election_region: 'IDF',
            mandature_premiere_election: true,
        });

        expect(tables.mandatsSuppleants).toHaveLength(1);
        expect(tables.mandatsSuppleants[0]).toMatchObject({
            mandat_uid: 'MA1',
            suppleant_uid: 'PA2',
        });

        expect(tables.groupesVuDesMandats.map(g => g.id)).toEqual(['PO1']);
    });

    it('records a parse error instead of throwing when uid is missing', async () => {
        const extractor = new ActeursExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile({ acteur: { etatCivil: {} } });
        cleanup = c;

        await expect(extractor.processFile(filePath)).resolves.toBeUndefined();

        expect(extractor.getTables().acteurs).toHaveLength(0);
        expect(extractor.getErrors()).toEqual([
            { file: expect.stringContaining('.json'), error: 'Missing uid' },
        ]);
    });

    it('records a parse error for malformed JSON without throwing', async () => {
        const extractor = new ActeursExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile('{not valid json', { raw: true });
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getErrors()).toHaveLength(1);
        expect(extractor.getErrors()[0].error).toMatch(/JSON/i);
    });

    it('accumulates rows across multiple processFile calls', async () => {
        const extractor = new ActeursExtractor(17);
        const first = writeTempJsonFile(baseActeur());
        const second = writeTempJsonFile(baseActeur({ uid: 'PA2' }));
        cleanup = () => {
            first.cleanup();
            second.cleanup();
        };

        await extractor.processFile(first.filePath);
        await extractor.processFile(second.filePath);

        expect(extractor.getTables().acteurs).toHaveLength(2);
    });
});
