import { ScrutinsExtractor } from './ScrutinsExtractor';
import { writeTempJsonFile } from './test-helpers/tempJsonFile';

function baseScrutin(overrides: Record<string, any> = {}): any {
    return {
        scrutin: {
            uid: 'VTANR1L17V1',
            numero: '1',
            legislature: '17',
            dateScrutin: '2024-07-20',
            titre: "Adoption de la motion de censure",
            typeVote: { codeTypeVote: '1', libelleTypeVote: 'scrutin public solennel', typeMajorite: 'absolue' },
            sort: { code: 'adopte', libelle: 'Adopté' },
            ...overrides,
        },
    };
}

describe('ScrutinsExtractor', () => {
    let cleanup: () => void;

    afterEach(() => cleanup?.());

    it('extracts the scrutin core fields', async () => {
        const extractor = new ScrutinsExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(baseScrutin());
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.scrutins).toHaveLength(1);
        expect(tables.scrutins[0]).toMatchObject({
            uid: 'VTANR1L17V1',
            numero: '1',
            date_scrutin: '2024-07-20',
            titre: 'Adoption de la motion de censure',
            type_scrutin_code: '1',
            type_majorite: 'absolue',
            resultat_code: 'adopte',
            legislature_snapshot: 17,
        });
        expect(extractor.getErrors()).toEqual([]);
    });

    it('falls back to objet.libelle for titre when titre is absent', async () => {
        const extractor = new ScrutinsExtractor(17);
        const data = baseScrutin({ titre: undefined, objet: { libelle: 'Libellé objet' } });
        delete data.scrutin.titre;
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().scrutins[0].titre).toBe('Libellé objet');
    });

    it('extracts the vote synthesis aggregate when syntheseVote is present', async () => {
        const extractor = new ScrutinsExtractor(17);
        const data = baseScrutin({
            syntheseVote: {
                nombreVotants: '577',
                suffragesExprimes: '570',
                nbrSuffragesRequis: '286',
                decompte: { pour: '100', contre: '450', abstentions: '20', nonVotants: '7', nonVotantsVolontaires: '0' },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().scrutinsAgregats).toHaveLength(1);
        expect(extractor.getTables().scrutinsAgregats[0]).toMatchObject({
            scrutin_uid: 'VTANR1L17V1',
            nombre_votants: 577,
            suffrages_exprimes: 570,
            suffrages_requis: 286,
            total_pour: 100,
            total_contre: 450,
            total_abstentions: 20,
            total_non_votants: 7,
        });
    });

    it('does not emit a scrutinsAgregats row when syntheseVote is absent', async () => {
        const extractor = new ScrutinsExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile(baseScrutin());
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().scrutinsAgregats).toEqual([]);
    });

    it('extracts groupes, per-groupe vote counts, and nominative votes, deduplicating deputes/groupes sets', async () => {
        const extractor = new ScrutinsExtractor(17);
        const data = baseScrutin({
            ventilationVotes: {
                organe: {
                    groupes: {
                        groupe: [
                            {
                                organeRef: 'PO1',
                                nombreMembresGroupe: '50',
                                vote: {
                                    positionMajoritaire: 'pour',
                                    decompteVoix: { pour: '48', contre: '1', abstentions: '1', nonVotants: '0', nonVotantsVolontaires: '0' },
                                    decompteNominatif: {
                                        pours: { votant: [{ acteurRef: 'PA1', mandatRef: 'MA1' }, { acteurRef: 'PA2', mandatRef: 'MA2' }] },
                                        contres: { votant: { acteurRef: 'PA3', mandatRef: 'MA3', causePositionVote: 'nonInscrit' } },
                                        abstentions: { votant: { acteurRef: 'PA4', mandatRef: 'MA4' } },
                                        nonVotants: null,
                                    },
                                },
                            },
                            {
                                // second group referencing an already-seen depute must not duplicate the deputes set
                                organeRef: 'PO2',
                                nombreMembresGroupe: '10',
                                vote: {
                                    positionMajoritaire: 'contre',
                                    decompteNominatif: {
                                        pours: { votant: { acteurRef: 'PA1', mandatRef: 'MA1-bis', parDelegation: 'true' } },
                                    },
                                },
                            },
                        ],
                    },
                },
            },
        });
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);
        const tables = extractor.getTables();

        expect(tables.scrutinsGroupes).toHaveLength(2);
        expect(tables.scrutinsGroupes[0]).toMatchObject({
            scrutin_uid: 'VTANR1L17V1',
            groupe_id: 'PO1',
            nombre_membres: 50,
            position_majoritaire: 'pour',
        });

        expect(tables.scrutinsGroupesAgregats).toHaveLength(1); // only PO1 has decompteVoix
        expect(tables.scrutinsGroupesAgregats[0]).toMatchObject({ groupe_id: 'PO1', pour: 48, contre: 1 });

        expect(tables.votesDeputes).toHaveLength(5); // 2 pour + 1 contre + 1 abstention (PO1) + 1 pour (PO2)
        const pa1Votes = tables.votesDeputes.filter(v => v.depute_id === 'PA1');
        expect(pa1Votes).toHaveLength(2);
        expect(pa1Votes.map(v => v.position)).toEqual(['pour', 'pour']);

        const contreVote = tables.votesDeputes.find(v => v.depute_id === 'PA3');
        expect(contreVote).toMatchObject({ position: 'contre', cause_position: 'nonInscrit' });

        const delegatedVote = tables.votesDeputes.find(v => v.groupe_id === 'PO2');
        expect(delegatedVote).toMatchObject({ par_delegation: true });

        expect(tables.groupesVuDesScrutins.map(g => g.id).sort()).toEqual(['PO1', 'PO2']);
        expect(tables.deputes.map(d => d.id).sort()).toEqual(['PA1', 'PA2', 'PA3', 'PA4']); // deduplicated
    });

    it('records a parse error instead of throwing when uid is missing', async () => {
        const extractor = new ScrutinsExtractor(17);
        const data = baseScrutin();
        delete data.scrutin.uid;
        const { filePath, cleanup: c } = writeTempJsonFile(data);
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getTables().scrutins).toHaveLength(0);
        expect(extractor.getErrors()).toEqual([{ file: expect.stringContaining('.json'), error: 'Missing uid' }]);
    });

    it('records a parse error for malformed JSON without throwing', async () => {
        const extractor = new ScrutinsExtractor(17);
        const { filePath, cleanup: c } = writeTempJsonFile('not json at all', { raw: true });
        cleanup = c;

        await extractor.processFile(filePath);

        expect(extractor.getErrors()).toHaveLength(1);
    });
});
