import { ParamDataSourceRepository } from './ParamDataSource.repository';
import { prisma } from '../../../../../../prisma/prisma';

/**
 * Integration test against the real Prisma-migrated schema (see
 * ParamCurrentLegislatue.repository.it.spec.ts for the general setup notes).
 *
 * Unlike ParamCurrentLegislatureRepository, every method here is filtered by
 * an id/code/legislature `where` clause, so the fixtures below are purely
 * additive — no snapshot/restore dance needed, just create-then-delete.
 */
describe('ParamDataSourceRepository (integration)', () => {
    const repository = new ParamDataSourceRepository();
    const DOMAIN_CODE = 'IT_TEST_DOMAIN';
    const LEGISLATURE_NUMBER = 999998;

    let domainId: number;
    let legislatureId: number;
    let sourceId: number;

    beforeAll(async () => {
        const domain = await prisma.refDataDomain.create({
            data: { code: DOMAIN_CODE, description: 'Fixture for ParamDataSourceRepository IT' },
        });
        domainId = domain.id;

        const legislature = await prisma.paramLegislature.create({ data: { number: LEGISLATURE_NUMBER } });
        legislatureId = legislature.id;

        const source = await prisma.paramDataSource.create({
            data: {
                domainId,
                legislatureId,
                downloadUrl: 'https://example.org/it-test.zip',
                fileName: 'it-test.zip',
            },
        });
        sourceId = source.id;

        await prisma.monitorDataDownload.create({
            data: { sourceId, fileName: 'it-test.zip', downloaded: true, checksum: 'chk', fileSize: BigInt(42) },
        });
    });

    afterAll(async () => {
        await prisma.monitorDataDownload.deleteMany({ where: { sourceId } });
        await prisma.paramDataSource.deleteMany({ where: { id: sourceId } });
        await prisma.paramLegislature.deleteMany({ where: { id: legislatureId } });
        await prisma.refDataDomain.deleteMany({ where: { id: domainId } });
        await prisma.$disconnect();
    });

    it('findManyWithRelations filters by legislature and includes domain/legislature/downloads', async () => {
        const sources = await repository.findManyWithRelations({ legislature: legislatureId });

        expect(sources).toHaveLength(1);
        expect(sources[0]).toMatchObject({
            id: sourceId,
            fileName: 'it-test.zip',
            domain: { code: DOMAIN_CODE },
            legislature: { number: LEGISLATURE_NUMBER },
        });
        expect(sources[0].downloads).toHaveLength(1);
        expect(sources[0].downloads[0]).toMatchObject({ downloaded: true, checksum: 'chk' });
    });

    it('findManyWithRelations filters by domain code', async () => {
        const sources = await repository.findManyWithRelations({ domain: DOMAIN_CODE });

        expect(sources.map(s => s.id)).toEqual([sourceId]);
    });

    it('findManyWithRelations filters by sourceIds', async () => {
        const sources = await repository.findManyWithRelations({ sourceIds: [sourceId] });

        expect(sources.map(s => s.id)).toEqual([sourceId]);
    });

    it('findById returns the source with relations', async () => {
        const source = await repository.findById(sourceId);

        expect(source).toMatchObject({ id: sourceId, domain: { code: DOMAIN_CODE } });
    });

    it('findById returns null for an id that does not exist', async () => {
        await expect(repository.findById(-1)).resolves.toBeNull();
    });

    it('findByLegislature returns sources for that legislature', async () => {
        const sources = await repository.findByLegislature(legislatureId);

        expect(sources.map(s => s.id)).toEqual([sourceId]);
    });

    it('findByDomain returns sources for that domain code', async () => {
        const sources = await repository.findByDomain(DOMAIN_CODE);

        expect(sources.map(s => s.id)).toEqual([sourceId]);
    });
});
