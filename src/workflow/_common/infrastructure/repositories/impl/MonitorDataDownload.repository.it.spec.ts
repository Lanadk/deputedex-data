import { MonitorDataDownloadRepository } from './MonitorDataDownload.repository';
import { prisma } from '../../../../../../prisma/prisma';

/**
 * Integration test against the real Prisma-migrated schema (see
 * ParamCurrentLegislatue.repository.it.spec.ts for the general setup notes).
 *
 * monitor_data_download is unique on sourceId, so this walks one fixture
 * source through its download lifecycle (no row -> downloaded -> failed ->
 * reset) as a single ordered sequence rather than independent cases.
 */
describe('MonitorDataDownloadRepository (integration)', () => {
    const repository = new MonitorDataDownloadRepository();
    const DOMAIN_CODE = 'IT_TEST_DOMAIN_2';
    const LEGISLATURE_NUMBER = 999997;

    let domainId: number;
    let legislatureId: number;
    let sourceId: number;

    beforeAll(async () => {
        const domain = await prisma.refDataDomain.create({
            data: { code: DOMAIN_CODE, description: 'Fixture for MonitorDataDownloadRepository IT' },
        });
        domainId = domain.id;

        const legislature = await prisma.paramLegislature.create({ data: { number: LEGISLATURE_NUMBER } });
        legislatureId = legislature.id;

        const source = await prisma.paramDataSource.create({
            data: { domainId, legislatureId, downloadUrl: 'https://example.org/it-test-2.zip', fileName: 'it-test-2.zip' },
        });
        sourceId = source.id;
    });

    afterAll(async () => {
        await prisma.monitorDataDownload.deleteMany({ where: { sourceId } });
        await prisma.paramDataSource.deleteMany({ where: { id: sourceId } });
        await prisma.paramLegislature.deleteMany({ where: { id: legislatureId } });
        await prisma.refDataDomain.deleteMany({ where: { id: domainId } });
        await prisma.$disconnect();
    });

    it('findBySourceId returns null before any monitor row exists', async () => {
        await expect(repository.findBySourceId(sourceId)).resolves.toBeNull();
    });

    it('markAsDownloaded creates the monitor row (upsert: create path)', async () => {
        const result = await repository.markAsDownloaded('it-test-2.zip', sourceId, 'chk-1', BigInt(100));

        expect(result).toMatchObject({ sourceId, downloaded: true, checksum: 'chk-1', fileSize: BigInt(100), errorMessage: null });
        await expect(repository.findBySourceId(sourceId)).resolves.toMatchObject({ downloaded: true, checksum: 'chk-1' });
    });

    it('upsertDownloadStatus updates the existing row (upsert: update path)', async () => {
        const result = await repository.upsertDownloadStatus(sourceId, {
            fileName: 'it-test-2.zip',
            downloaded: true,
            checksum: 'chk-2',
            fileSize: BigInt(200),
        });

        expect(result).toMatchObject({ sourceId, checksum: 'chk-2', fileSize: BigInt(200) });
    });

    it('findMany({downloaded:true}) includes the fixture with its source/domain/legislature relations', async () => {
        const downloaded = await repository.findMany({ downloaded: true });
        const ours = downloaded.find(d => d.sourceId === sourceId);

        expect(ours).toMatchObject({
            checksum: 'chk-2',
            source: { domain: { code: DOMAIN_CODE }, legislature: { number: LEGISLATURE_NUMBER } },
        });
    });

    it('markAsFailed switches the row to downloaded:false with an error message', async () => {
        const result = await repository.markAsFailed('it-test-2.zip', sourceId, 'network timeout');

        expect(result).toMatchObject({ sourceId, downloaded: false, errorMessage: 'network timeout' });
    });

    it('findMany({downloaded:false}) now includes the fixture', async () => {
        const failed = await repository.findMany({ downloaded: false });

        expect(failed.map(d => d.sourceId)).toContain(sourceId);
    });

    it('resetDownloadStatus clears downloaded/lastDownloadAt/checksum/fileSize/errorMessage', async () => {
        const result = await repository.resetDownloadStatus(sourceId);

        expect(result).toMatchObject({
            sourceId,
            downloaded: false,
            lastDownloadAt: null,
            checksum: null,
            fileSize: null,
            errorMessage: null,
        });
    });
});
