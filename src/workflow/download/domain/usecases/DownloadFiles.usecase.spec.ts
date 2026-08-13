import { DownloadFilesUsecase } from './DownloadFiles.usecase';
import { DownloadItemProcessor } from '../models/DownloadItemProcessor';
import { IFileManager } from '../../infrastructure/IFileManager';
import { IParamDataSourceService } from '../../../_common/infrastructure/services/IParamDataSources.service';
import { IMonitorDataDownloadService } from '../../../_common/infrastructure/services/IMonitorDataDownload.service';
import { IParamCurrentLegislatureService } from '../../../_common/infrastructure/services/IParamCurrentLegislature.service';
import { Logger } from '../../../../utils/logger';
import { DownloadItem } from '../models/entities/DownloadItem.entity';
import { DownloadResult } from '../../types/types';

function createMockLogger(): jest.Mocked<Logger> {
    return { debug: jest.fn(), info: jest.fn(), success: jest.fn(), warn: jest.fn(), error: jest.fn() } as unknown as jest.Mocked<Logger>;
}

function makeItem(overrides: Partial<DownloadItem> = {}): DownloadItem {
    return { id: 1, sourceId: 10, legislature: 17, domain: 'acteurs', url: 'https://x/a.zip', fileName: 'a.zip', ...overrides };
}

function createDeps() {
    const paramDataSourceService: jest.Mocked<IParamDataSourceService> = {
        getDownloadItems: jest.fn().mockResolvedValue([]),
        getSourceById: jest.fn(),
        getSourcesByLegislature: jest.fn(),
        getSourcesByDomain: jest.fn(),
        getSourcesCount: jest.fn(),
    };
    const monitorDataDownloadService: jest.Mocked<IMonitorDataDownloadService> = {
        updateDownloadStatus: jest.fn(),
        markAsDownloaded: jest.fn(),
        markAsFailed: jest.fn(),
        resetDownload: jest.fn(),
        getDownloadStatus: jest.fn(),
        getAllDownloadedSources: jest.fn(),
        getAllFailedSources: jest.fn(),
        getDownloadStats: jest.fn(),
    };
    const currentLegislatureService: jest.Mocked<IParamCurrentLegislatureService> = {
        getCurrentLegislature: jest.fn(),
        getCurrentLegislatureNumber: jest.fn().mockResolvedValue(17),
        isCurrentLegislature: jest.fn(),
        isArchiveLegislature: jest.fn(),
    };
    const processor = { process: jest.fn() } as unknown as jest.Mocked<DownloadItemProcessor>;
    const fileManager: jest.Mocked<IFileManager> = {
        prepareDownloadPaths: jest.fn(),
        fileExists: jest.fn(),
        createTimestampedZipDir: jest.fn().mockReturnValue('/tmp/session'),
    };
    const logger = createMockLogger();

    const usecase = new DownloadFilesUsecase(
        paramDataSourceService,
        monitorDataDownloadService,
        currentLegislatureService,
        processor,
        fileManager,
        logger
    );

    return { usecase, paramDataSourceService, monitorDataDownloadService, currentLegislatureService, processor, fileManager, logger };
}

describe('DownloadFilesUsecase', () => {
    it('returns an empty array and warns when there is nothing to download', async () => {
        const { usecase, processor, logger } = createDeps();

        const results = await usecase.execute();

        expect(results).toEqual([]);
        expect(processor.process).not.toHaveBeenCalled();
        expect(logger.warn).toHaveBeenCalledWith('No items to download');
    });

    it('processes every item sequentially and records a successful download in the monitor', async () => {
        const { usecase, paramDataSourceService, processor, monitorDataDownloadService, fileManager } = createDeps();
        const items = [makeItem({ id: 1, sourceId: 10 }), makeItem({ id: 2, sourceId: 20, fileName: 'b.zip' })];
        paramDataSourceService.getDownloadItems.mockResolvedValue(items);
        processor.process.mockImplementation(async (item: DownloadItem): Promise<DownloadResult> => ({
            success: true,
            item,
            path: `/tmp/${item.fileName}`,
            checksum: 'chk',
            fileSize: BigInt(100),
        }));

        const results = await usecase.execute();

        expect(fileManager.createTimestampedZipDir).toHaveBeenCalledTimes(1);
        expect(processor.process).toHaveBeenCalledTimes(2);
        expect(processor.process).toHaveBeenNthCalledWith(1, items[0], '/tmp/session', { force: false, maxRetries: 3 });
        expect(processor.process).toHaveBeenNthCalledWith(2, items[1], '/tmp/session', { force: false, maxRetries: 3 });

        expect(monitorDataDownloadService.markAsDownloaded).toHaveBeenCalledTimes(2);
        expect(monitorDataDownloadService.markAsDownloaded).toHaveBeenCalledWith('a.zip', 10, 'chk', BigInt(100));
        expect(results).toHaveLength(2);
    });

    it('forwards force/maxRetries options to the processor', async () => {
        const { usecase, paramDataSourceService, processor } = createDeps();
        paramDataSourceService.getDownloadItems.mockResolvedValue([makeItem()]);
        processor.process.mockResolvedValue({ success: true, item: makeItem(), skipped: true });

        await usecase.execute(undefined, { force: true, maxRetries: 7 });

        expect(processor.process).toHaveBeenCalledWith(expect.anything(), '/tmp/session', { force: true, maxRetries: 7 });
    });

    it('does not mark a skipped item as downloaded', async () => {
        const { usecase, paramDataSourceService, processor, monitorDataDownloadService } = createDeps();
        paramDataSourceService.getDownloadItems.mockResolvedValue([makeItem()]);
        processor.process.mockResolvedValue({ success: true, item: makeItem(), skipped: true, reason: 'already there' });

        await usecase.execute();

        expect(monitorDataDownloadService.markAsDownloaded).not.toHaveBeenCalled();
    });

    it('catches a processor failure, marks the item as failed, and continues with the remaining items', async () => {
        const { usecase, paramDataSourceService, processor, monitorDataDownloadService } = createDeps();
        const items = [makeItem({ id: 1, sourceId: 10, fileName: 'bad.zip' }), makeItem({ id: 2, sourceId: 20, fileName: 'ok.zip' })];
        paramDataSourceService.getDownloadItems.mockResolvedValue(items);
        processor.process
            .mockRejectedValueOnce(new Error('network down'))
            .mockResolvedValueOnce({ success: true, item: items[1], path: '/tmp/ok.zip', checksum: 'c', fileSize: BigInt(1) });

        const results = await usecase.execute();

        expect(monitorDataDownloadService.markAsFailed).toHaveBeenCalledWith('bad.zip', 10, 'network down');
        expect(results[0]).toMatchObject({ success: false, item: items[0], error: expect.any(Error) });
        expect(results[1]).toMatchObject({ success: true, item: items[1] });
        expect(processor.process).toHaveBeenCalledTimes(2); // the failure did not stop the loop
    });
});
