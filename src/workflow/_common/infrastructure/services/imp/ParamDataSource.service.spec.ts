// See ParamCurrentLegislature.service.spec.ts: stub the Prisma singleton so
// these repository-mocked unit tests stay DB-free.
jest.mock('../../../../../../prisma/prisma', () => ({ prisma: {} }));

import { ParamDataSourceService } from './ParamDataSource.service';
import { DataSourceWithRelations, IParamDataSourceRepository } from '../../repositories/IParamDataSource.repository';

function createMockRepository(): jest.Mocked<IParamDataSourceRepository> {
    return {
        findManyWithRelations: jest.fn(),
        findById: jest.fn(),
        findByLegislature: jest.fn(),
        findByDomain: jest.fn(),
    };
}

function makeSource(overrides: Partial<DataSourceWithRelations> = {}): DataSourceWithRelations {
    return {
        id: 10,
        domainId: 1,
        legislatureId: 1,
        downloadUrl: 'https://x/acteurs.zip',
        fileName: 'acteurs.zip',
        createdAt: new Date('2024-01-01'),
        domain: { id: 1, code: 'acteurs', description: null },
        legislature: { id: 1, number: 17, startDate: null, endDate: null, createdAt: new Date('2024-01-01'), updatedAt: new Date('2024-01-01') },
        downloads: [],
        ...overrides,
    };
}

describe('ParamDataSourceService', () => {
    it('getDownloadItems maps sources with relations into flat DownloadItem entities', async () => {
        const repository = createMockRepository();
        repository.findManyWithRelations.mockResolvedValue([
            makeSource({
                downloads: [
                    { id: 99, sourceId: 10, fileName: 'acteurs.zip', downloaded: true, lastDownloadAt: new Date('2024-02-01'), checksum: 'chk', fileSize: BigInt(123), errorMessage: null, updatedAt: new Date('2024-02-01') },
                ],
            }),
        ]);
        const service = new ParamDataSourceService(repository);

        const items = await service.getDownloadItems({ legislature: 17 });

        expect(repository.findManyWithRelations).toHaveBeenCalledWith({ legislature: 17 });
        expect(items).toEqual([
            {
                id: 99,
                fileName: 'acteurs.zip',
                sourceId: 10,
                legislature: 17,
                domain: 'acteurs',
                url: 'https://x/acteurs.zip',
                filename: 'acteurs.zip',
                checksum: 'chk',
                fileSize: BigInt(123),
                lastDownloadAt: new Date('2024-02-01'),
            },
        ]);
    });

    it('getDownloadItems defaults id/checksum/fileSize/lastDownloadAt when there is no prior download record', async () => {
        const repository = createMockRepository();
        repository.findManyWithRelations.mockResolvedValue([makeSource({ downloads: [] })]);
        const service = new ParamDataSourceService(repository);

        const [item] = await service.getDownloadItems();

        expect(item.id).toBe(0);
        expect(item.checksum).toBeUndefined();
        expect(item.fileSize).toBeUndefined();
        expect(item.lastDownloadAt).toBeUndefined();
    });

    it('getSourceById delegates to the repository', async () => {
        const repository = createMockRepository();
        const source = makeSource();
        repository.findById.mockResolvedValue(source);
        const service = new ParamDataSourceService(repository);

        await expect(service.getSourceById(10)).resolves.toBe(source);
        expect(repository.findById).toHaveBeenCalledWith(10);
    });

    it('getSourcesByLegislature delegates to the repository', async () => {
        const repository = createMockRepository();
        repository.findByLegislature.mockResolvedValue([makeSource()]);
        const service = new ParamDataSourceService(repository);

        await service.getSourcesByLegislature(17);

        expect(repository.findByLegislature).toHaveBeenCalledWith(17);
    });

    it('getSourcesByDomain delegates to the repository', async () => {
        const repository = createMockRepository();
        repository.findByDomain.mockResolvedValue([makeSource()]);
        const service = new ParamDataSourceService(repository);

        await service.getSourcesByDomain('acteurs');

        expect(repository.findByDomain).toHaveBeenCalledWith('acteurs');
    });

    it('getSourcesCount counts the results of findManyWithRelations', async () => {
        const repository = createMockRepository();
        repository.findManyWithRelations.mockResolvedValue([makeSource(), makeSource({ id: 11 })]);
        const service = new ParamDataSourceService(repository);

        await expect(service.getSourcesCount({ domain: 'acteurs' })).resolves.toBe(2);
        expect(repository.findManyWithRelations).toHaveBeenCalledWith({ domain: 'acteurs' });
    });
});
