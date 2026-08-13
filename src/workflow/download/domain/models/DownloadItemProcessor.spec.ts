import { DownloadItemProcessor } from './DownloadItemProcessor';
import { DownloadItem } from './entities/DownloadItem.entity';
import { IFileDownloader } from '../../infrastructure/IFileDownloader';
import { IFileExtractor } from '../../infrastructure/IFileExtrator';
import { IFileVerifier } from '../../infrastructure/IFileVerifier';
import { IFileManager } from '../../infrastructure/IFileManager';
import { IParamCurrentLegislatureService } from '../../../_common/infrastructure/services/IParamCurrentLegislature.service';
import { IMonitorDataDownloadService } from '../../../_common/infrastructure/services/IMonitorDataDownload.service';
import { Logger } from '../../../../utils/logger';

function createMockLogger(): jest.Mocked<Logger> {
    return { debug: jest.fn(), info: jest.fn(), success: jest.fn(), warn: jest.fn(), error: jest.fn() } as unknown as jest.Mocked<Logger>;
}

function makeItem(overrides: Partial<DownloadItem> = {}): DownloadItem {
    return {
        id: 1,
        sourceId: 10,
        legislature: 17,
        domain: 'acteurs',
        url: 'https://example.org/acteurs.zip',
        fileName: 'acteurs.zip',
        ...overrides,
    };
}

function createDeps() {
    const fileDownloader: jest.Mocked<IFileDownloader> = { downloadWithRetry: jest.fn().mockResolvedValue(undefined) };
    const fileExtractor: jest.Mocked<IFileExtractor> = { extract: jest.fn().mockResolvedValue(undefined) };
    const fileVerifier: jest.Mocked<IFileVerifier> = {
        calculateChecksum: jest.fn().mockResolvedValue('checksum-abc'),
        verifyChecksum: jest.fn().mockResolvedValue(true),
        getFileSize: jest.fn().mockResolvedValue(BigInt(1234)),
    };
    const fileManager: jest.Mocked<IFileManager> = {
        prepareDownloadPaths: jest.fn().mockReturnValue({
            zipDir: '/tmp/zip',
            zipFilePath: '/tmp/zip/acteurs.zip',
            unzipDir: '/tmp/unzip',
        }),
        fileExists: jest.fn().mockResolvedValue(false),
        createTimestampedZipDir: jest.fn().mockReturnValue('/tmp/session'),
    };
    const currentLegislatureService: jest.Mocked<IParamCurrentLegislatureService> = {
        getCurrentLegislature: jest.fn(),
        getCurrentLegislatureNumber: jest.fn(),
        isCurrentLegislature: jest.fn().mockResolvedValue(true),
        isArchiveLegislature: jest.fn(),
    };
    const monitorDataDownloadService: jest.Mocked<IMonitorDataDownloadService> = {
        updateDownloadStatus: jest.fn(),
        markAsDownloaded: jest.fn(),
        markAsFailed: jest.fn(),
        resetDownload: jest.fn(),
        getDownloadStatus: jest.fn().mockResolvedValue(null),
        getAllDownloadedSources: jest.fn(),
        getAllFailedSources: jest.fn(),
        getDownloadStats: jest.fn(),
    };
    const logger = createMockLogger();

    const processor = new DownloadItemProcessor(
        fileDownloader,
        fileExtractor,
        fileVerifier,
        fileManager,
        currentLegislatureService,
        monitorDataDownloadService,
        logger
    );

    return { processor, fileDownloader, fileExtractor, fileVerifier, fileManager, currentLegislatureService, monitorDataDownloadService, logger };
}

describe('DownloadItemProcessor', () => {
    it('downloads, extracts and verifies a file, returning checksum/size/path', async () => {
        const { processor, fileDownloader, fileExtractor, fileVerifier, fileManager } = createDeps();
        const item = makeItem();

        const result = await processor.process(item, '/tmp/session', { force: false, maxRetries: 3 });

        expect(fileManager.prepareDownloadPaths).toHaveBeenCalledWith('/tmp/session', 'acteurs.zip', 17, 'acteurs');
        expect(fileDownloader.downloadWithRetry).toHaveBeenCalledWith(item.url, '/tmp/zip/acteurs.zip', 3);
        expect(fileExtractor.extract).toHaveBeenCalledWith('/tmp/zip/acteurs.zip', '/tmp/unzip');
        expect(fileVerifier.calculateChecksum).toHaveBeenCalledWith('/tmp/zip/acteurs.zip');
        expect(result).toEqual({
            success: true,
            item,
            path: '/tmp/zip/acteurs.zip',
            checksum: 'checksum-abc',
            fileSize: BigInt(1234),
        });
    });

    it('never skips when force is true, even for an archived and already-downloaded legislature', async () => {
        const { processor, currentLegislatureService, monitorDataDownloadService, fileDownloader } = createDeps();
        currentLegislatureService.isCurrentLegislature.mockResolvedValue(false);
        monitorDataDownloadService.getDownloadStatus.mockResolvedValue({
            id: 1,
            sourceId: 10,
            fileName: 'acteurs.zip',
            downloaded: true,
            lastDownloadAt: new Date('2024-01-01'),
            checksum: 'old',
            fileSize: BigInt(1),
            errorMessage: null,
            updatedAt: new Date('2024-01-01'),
        });

        const result = await processor.process(makeItem(), '/tmp/session', { force: true, maxRetries: 3 });

        expect(result.skipped).toBeUndefined();
        expect(fileDownloader.downloadWithRetry).toHaveBeenCalled();
    });

    it('never skips a current legislature', async () => {
        const { processor, currentLegislatureService, fileDownloader } = createDeps();
        currentLegislatureService.isCurrentLegislature.mockResolvedValue(true);

        const result = await processor.process(makeItem(), '/tmp/session', { force: false, maxRetries: 3 });

        expect(result.skipped).toBeUndefined();
        expect(fileDownloader.downloadWithRetry).toHaveBeenCalled();
    });

    it('skips an archive legislature already marked as downloaded', async () => {
        const { processor, currentLegislatureService, monitorDataDownloadService, fileDownloader } = createDeps();
        currentLegislatureService.isCurrentLegislature.mockResolvedValue(false);
        monitorDataDownloadService.getDownloadStatus.mockResolvedValue({
            id: 1,
            sourceId: 10,
            fileName: 'acteurs.zip',
            downloaded: true,
            lastDownloadAt: new Date('2024-01-01'),
            checksum: 'old',
            fileSize: BigInt(1),
            errorMessage: null,
            updatedAt: new Date('2024-01-01'),
        });

        const result = await processor.process(makeItem(), '/tmp/session', { force: false, maxRetries: 3 });

        expect(result).toMatchObject({
            success: true,
            skipped: true,
            reason: 'Already downloaded (archive legislature)',
            path: undefined,
        });
        expect(fileDownloader.downloadWithRetry).not.toHaveBeenCalled();
    });

    it('does not skip an archive legislature that has not been downloaded yet', async () => {
        const { processor, currentLegislatureService, monitorDataDownloadService, fileDownloader } = createDeps();
        currentLegislatureService.isCurrentLegislature.mockResolvedValue(false);
        monitorDataDownloadService.getDownloadStatus.mockResolvedValue(null);

        const result = await processor.process(makeItem(), '/tmp/session', { force: false, maxRetries: 3 });

        expect(result.skipped).toBeUndefined();
        expect(fileDownloader.downloadWithRetry).toHaveBeenCalled();
    });

    it('propagates a download failure instead of swallowing it', async () => {
        const { processor, fileDownloader } = createDeps();
        fileDownloader.downloadWithRetry.mockRejectedValue(new Error('network down'));

        await expect(processor.process(makeItem(), '/tmp/session', { force: false, maxRetries: 3 })).rejects.toThrow(
            'network down'
        );
    });
});
