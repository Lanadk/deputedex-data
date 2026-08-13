// See ParamCurrentLegislature.service.spec.ts: stub the Prisma singleton so
// these repository-mocked unit tests stay DB-free.
jest.mock('../../../../../../prisma/prisma', () => ({ prisma: {} }));

import { MonitorDataDownloadService } from './MonitorDataDownload.service';
import {
    DownloadMonitorWithSource,
    IMonitorDataDownloadRepository,
} from '../../repositories/IMonitorDataDownload.repository';

function createMockRepository(): jest.Mocked<IMonitorDataDownloadRepository> {
    return {
        upsertDownloadStatus: jest.fn(),
        findBySourceId: jest.fn(),
        findMany: jest.fn(),
        markAsDownloaded: jest.fn(),
        markAsFailed: jest.fn(),
        resetDownloadStatus: jest.fn(),
    };
}

function makeMonitor(overrides: Partial<DownloadMonitorWithSource> = {}): DownloadMonitorWithSource {
    return {
        id: 1,
        sourceId: 10,
        fileName: 'acteurs.zip',
        downloaded: false,
        lastDownloadAt: null,
        checksum: null,
        fileSize: null,
        errorMessage: null,
        updatedAt: new Date('2024-01-01'),
        source: {
            id: 10,
            domainId: 1,
            legislatureId: 1,
            downloadUrl: 'https://x/a.zip',
            fileName: 'acteurs.zip',
            domain: { id: 1, code: 'acteurs', description: null },
            legislature: { id: 1, number: 17, startDate: null, endDate: null },
        },
        ...overrides,
    };
}

describe('MonitorDataDownloadService', () => {
    it('updateDownloadStatus upserts through the repository, defaulting a missing errorMessage to null', async () => {
        const repository = createMockRepository();
        const service = new MonitorDataDownloadService(repository);

        await service.updateDownloadStatus('a.zip', 10, { fileName: 'a.zip', downloaded: true, checksum: 'c', fileSize: BigInt(1) });

        expect(repository.upsertDownloadStatus).toHaveBeenCalledWith(10, {
            fileName: 'a.zip',
            downloaded: true,
            checksum: 'c',
            fileSize: BigInt(1),
            errorMessage: null,
        });
    });

    it('markAsDownloaded delegates to the repository', async () => {
        const repository = createMockRepository();
        const service = new MonitorDataDownloadService(repository);

        await service.markAsDownloaded('a.zip', 10, 'chk', BigInt(42));

        expect(repository.markAsDownloaded).toHaveBeenCalledWith('a.zip', 10, 'chk', BigInt(42));
    });

    it('markAsFailed delegates to the repository', async () => {
        const repository = createMockRepository();
        const service = new MonitorDataDownloadService(repository);

        await service.markAsFailed('a.zip', 10, 'timeout');

        expect(repository.markAsFailed).toHaveBeenCalledWith('a.zip', 10, 'timeout');
    });

    it('resetDownload delegates to the repository', async () => {
        const repository = createMockRepository();
        const service = new MonitorDataDownloadService(repository);

        await service.resetDownload(10);

        expect(repository.resetDownloadStatus).toHaveBeenCalledWith(10);
    });

    it('getAllDownloadedSources filters findMany by downloaded:true', async () => {
        const repository = createMockRepository();
        const service = new MonitorDataDownloadService(repository);

        await service.getAllDownloadedSources();

        expect(repository.findMany).toHaveBeenCalledWith({ downloaded: true });
    });

    it('getAllFailedSources filters findMany by downloaded:false', async () => {
        const repository = createMockRepository();
        const service = new MonitorDataDownloadService(repository);

        await service.getAllFailedSources();

        expect(repository.findMany).toHaveBeenCalledWith({ downloaded: false });
    });

    it('getDownloadStats computes totals, downloaded, failed, pending and successRate', async () => {
        const repository = createMockRepository();
        repository.findMany.mockResolvedValue([
            makeMonitor({ downloaded: true }),
            makeMonitor({ downloaded: true }),
            makeMonitor({ downloaded: false, errorMessage: 'boom' }),
            makeMonitor({ downloaded: false, errorMessage: null }),
        ]);
        const service = new MonitorDataDownloadService(repository);

        const stats = await service.getDownloadStats();

        expect(stats).toEqual({ total: 4, downloaded: 2, failed: 1, pending: 1, successRate: 50 });
    });

    it('getDownloadStats returns a 0% success rate for an empty dataset instead of dividing by zero', async () => {
        const repository = createMockRepository();
        repository.findMany.mockResolvedValue([]);
        const service = new MonitorDataDownloadService(repository);

        const stats = await service.getDownloadStats();

        expect(stats).toEqual({ total: 0, downloaded: 0, failed: 0, pending: 0, successRate: 0 });
    });
});
