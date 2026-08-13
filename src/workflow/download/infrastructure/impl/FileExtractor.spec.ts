jest.mock('../../../../utils/unzip');

import { FileExtractor } from './FileExtractor';
import { unzipFile } from '../../../../utils/unzip';
import { Logger } from '../../../../utils/logger';

const mockedUnzipFile = unzipFile as jest.MockedFunction<typeof unzipFile>;

function createMockLogger(): jest.Mocked<Logger> {
    return { debug: jest.fn(), info: jest.fn(), success: jest.fn(), warn: jest.fn(), error: jest.fn() } as unknown as jest.Mocked<Logger>;
}

describe('FileExtractor', () => {
    afterEach(() => {
        jest.resetAllMocks();
    });

    it('delegates extraction to unzipFile with the given paths', async () => {
        mockedUnzipFile.mockResolvedValue(undefined);
        const logger = createMockLogger();
        const extractor = new FileExtractor(logger);

        await extractor.extract('/tmp/a.zip', '/tmp/out');

        expect(mockedUnzipFile).toHaveBeenCalledWith('/tmp/a.zip', '/tmp/out');
    });

    it('logs progress and success', async () => {
        mockedUnzipFile.mockResolvedValue(undefined);
        const logger = createMockLogger();
        const extractor = new FileExtractor(logger);

        await extractor.extract('/tmp/a.zip', '/tmp/out');

        expect(logger.info).toHaveBeenCalledWith(expect.stringContaining('/tmp/a.zip'));
        expect(logger.success).toHaveBeenCalledWith(expect.stringContaining('/tmp/out'));
    });

    it('propagates an unzip failure instead of swallowing it', async () => {
        mockedUnzipFile.mockRejectedValue(new Error('corrupt archive'));
        const logger = createMockLogger();
        const extractor = new FileExtractor(logger);

        await expect(extractor.extract('/tmp/a.zip', '/tmp/out')).rejects.toThrow('corrupt archive');
        expect(logger.success).not.toHaveBeenCalled();
    });
});
