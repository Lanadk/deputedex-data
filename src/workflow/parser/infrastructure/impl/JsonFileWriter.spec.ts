import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { JsonFileWriter } from './JsonFileWriter';

describe('JsonFileWriter', () => {
    let workDir: string;
    let writer: JsonFileWriter;

    beforeEach(() => {
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'json-file-writer-spec-'));
        writer = new JsonFileWriter();
    });

    afterEach(() => {
        fs.rmSync(workDir, { recursive: true, force: true });
    });

    // writeToSeparateFiles delegates to formatJsonForImport, a fire-and-forget
    // stream writer (see utils.spec.ts): poll until the file content settles
    // instead of assuming it's flushed synchronously.
    async function readOnceFlushed(filePath: string): Promise<string> {
        const deadline = Date.now() + 2000;
        let previous: string | null = null;

        while (Date.now() < deadline) {
            const current = fs.existsSync(filePath) ? fs.readFileSync(filePath, 'utf-8') : null;
            if (current !== null && current === previous) return current;
            previous = current;
            await new Promise(resolve => setTimeout(resolve, 20));
        }

        throw new Error(`Timed out waiting for ${filePath} to be flushed`);
    }

    describe('writeToSingleFile', () => {
        it('writes the full dataset as pretty-printed JSON', () => {
            const outputPath = path.join(workDir, 'complete.json');

            writer.writeToSingleFile({ acteurs: [{ id: 1 }], scrutins: [] }, outputPath);

            expect(JSON.parse(fs.readFileSync(outputPath, 'utf-8'))).toEqual({ acteurs: [{ id: 1 }], scrutins: [] });
        });

        it('updates the summary with table/record counts', () => {
            writer.writeToSingleFile({ acteurs: [{ id: 1 }, { id: 2 }], scrutins: [{ id: 1 }] }, path.join(workDir, 'complete.json'));

            expect(writer.getSummary()).toEqual({
                totalTables: 2,
                totalRecords: 3,
                tables: { acteurs: 2, scrutins: 1 },
                errors: 0,
            });
        });
    });

    describe('writeToSeparateFiles', () => {
        it('creates the output directory and writes one NDJSON file per table', async () => {
            const outputDir = path.join(workDir, 'nested', 'out');
            writer.writeToSeparateFiles({ acteurs: [{ id: 1 }, { id: 2 }] }, outputDir);

            const content = await readOnceFlushed(path.join(outputDir, 'acteurs.json'));
            expect(content.trim().split('\n').map(l => JSON.parse(l))).toEqual([{ id: 1 }, { id: 2 }]);
        });

        it('updates the summary from the written tables', async () => {
            const outputDir = path.join(workDir, 'out');
            writer.writeToSeparateFiles({ acteurs: [{ id: 1 }], mandats: [{ id: 1 }, { id: 2 }] }, outputDir);

            // Wait for both fire-and-forget writes to settle before the
            // surrounding afterEach removes workDir, otherwise the stream
            // can still be opening the file once its directory is gone.
            await Promise.all([
                readOnceFlushed(path.join(outputDir, 'acteurs.json')),
                readOnceFlushed(path.join(outputDir, 'mandats.json')),
            ]);

            expect(writer.getSummary()).toMatchObject({
                totalTables: 2,
                totalRecords: 3,
                tables: { acteurs: 1, mandats: 2 },
            });
        });
    });

    describe('writeErrors', () => {
        it('does nothing when there are no errors', () => {
            writer.writeErrors([], path.join(workDir, 'out'));

            expect(fs.existsSync(path.join(workDir, 'out'))).toBe(false);
            expect(writer.getSummary().errors).toBe(0);
        });

        it('writes to <dir>/errors.json when outputPath has no .json extension', () => {
            fs.mkdirSync(path.join(workDir, 'out'));
            writer.writeErrors([{ file: 'a.json', error: 'boom' }], path.join(workDir, 'out'));

            const written = JSON.parse(fs.readFileSync(path.join(workDir, 'out', 'errors.json'), 'utf-8'));
            expect(written).toEqual([{ file: 'a.json', error: 'boom' }]);
            expect(writer.getSummary().errors).toBe(1);
        });

        it('writes to <name>-errors.json when outputPath already ends in .json', () => {
            const outputPath = path.join(workDir, 'complete.json');
            writer.writeErrors([{ file: 'a.json', error: 'boom' }], outputPath);

            expect(fs.existsSync(path.join(workDir, 'complete-errors.json'))).toBe(true);
        });
    });

    describe('getSummary', () => {
        it('returns a defensive copy, not the live internal object', () => {
            writer.writeToSingleFile({ acteurs: [{ id: 1 }] }, path.join(workDir, 'complete.json'));

            const summary = writer.getSummary();
            summary.totalTables = 999;

            expect(writer.getSummary().totalTables).toBe(1);
        });
    });
});
