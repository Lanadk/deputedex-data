import { ParseFilesUseCase } from './ParseFilesUseCase';
import { BatchProcessor } from '../models/BatchProcessor';
import { ExportSummary, IJsonFileWriter } from '../../infrastructure/IJsonFileWriter';
import { Logger } from '../../../../utils/logger';

function createMockLogger(): jest.Mocked<Logger> {
    return { debug: jest.fn(), info: jest.fn(), success: jest.fn(), warn: jest.fn(), error: jest.fn() } as unknown as jest.Mocked<Logger>;
}

function createMockProcessor(overrides: Partial<Record<keyof BatchProcessor, any>> = {}): jest.Mocked<BatchProcessor> {
    const tables = { foo: [{ id: 1 }] };
    const errors: { file: string; error: string }[] = [];
    return {
        process: jest.fn().mockResolvedValue(undefined),
        getTables: jest.fn().mockReturnValue(tables),
        getErrors: jest.fn().mockReturnValue(errors),
        getProcessedFilesCount: jest.fn().mockReturnValue(5),
        ...overrides,
    } as unknown as jest.Mocked<BatchProcessor>;
}

function createMockWriter(summary: Partial<ExportSummary> = {}): jest.Mocked<IJsonFileWriter> {
    return {
        writeToSingleFile: jest.fn(),
        writeToSeparateFiles: jest.fn(),
        writeErrors: jest.fn(),
        getSummary: jest.fn().mockReturnValue({
            totalTables: 1,
            totalRecords: 1,
            tables: { foo: 1 },
            errors: 0,
            ...summary,
        }),
    };
}

describe('ParseFilesUseCase', () => {
    it('runs the processor before exporting anything', async () => {
        const processor = createMockProcessor();
        const writer = createMockWriter();
        const useCase = new ParseFilesUseCase(processor, writer, createMockLogger());

        await useCase.execute('/out');

        expect(processor.process).toHaveBeenCalledTimes(1);
    });

    it('defaults to exporting separate files when no options are passed', async () => {
        const processor = createMockProcessor();
        const writer = createMockWriter();
        const useCase = new ParseFilesUseCase(processor, writer, createMockLogger());

        await useCase.execute('/out');

        expect(writer.writeToSeparateFiles).toHaveBeenCalledWith(processor.getTables(), '/out');
        expect(writer.writeToSingleFile).not.toHaveBeenCalled();
    });

    it('does NOT default exportSeparateFiles when an explicit empty options object is passed', async () => {
        // Documents an existing footgun: the ParseOptions default value only
        // applies when `options` itself is omitted, not when {} is passed.
        const processor = createMockProcessor();
        const writer = createMockWriter();
        const useCase = new ParseFilesUseCase(processor, writer, createMockLogger());

        await useCase.execute('/out', {});

        expect(writer.writeToSeparateFiles).not.toHaveBeenCalled();
        expect(writer.writeToSingleFile).not.toHaveBeenCalled();
    });

    it('writes a single combined file to <outputDir>/complete.json when requested', async () => {
        const processor = createMockProcessor();
        const writer = createMockWriter();
        const useCase = new ParseFilesUseCase(processor, writer, createMockLogger());

        await useCase.execute('/out', { exportSingleFile: true });

        expect(writer.writeToSingleFile).toHaveBeenCalledWith(processor.getTables(), '/out/complete.json');
    });

    it('always writes errors, regardless of export options', async () => {
        const processor = createMockProcessor();
        const writer = createMockWriter();
        const useCase = new ParseFilesUseCase(processor, writer, createMockLogger());

        await useCase.execute('/out', {});

        expect(writer.writeErrors).toHaveBeenCalledWith(processor.getErrors(), '/out');
    });

    it('returns a summary combining the processor count and the writer summary', async () => {
        const processor = createMockProcessor({ getProcessedFilesCount: jest.fn().mockReturnValue(7) });
        const writer = createMockWriter({ totalTables: 3, totalRecords: 42, errors: 2 });
        const useCase = new ParseFilesUseCase(processor, writer, createMockLogger());

        const result = await useCase.execute('/out');

        expect(result).toEqual({ totalFiles: 7, totalTables: 3, totalRecords: 42, errors: 2 });
    });

    it('falls back to 0 total files when the processor reports a falsy count', async () => {
        const processor = createMockProcessor({ getProcessedFilesCount: jest.fn().mockReturnValue(0) });
        const writer = createMockWriter();
        const useCase = new ParseFilesUseCase(processor, writer, createMockLogger());

        const result = await useCase.execute('/out');

        expect(result.totalFiles).toBe(0);
    });
});
