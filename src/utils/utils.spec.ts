import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { formatJsonForImport } from './utils';

describe('formatJsonForImport', () => {
    let workDir: string;

    beforeEach(() => {
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'format-json-spec-'));
    });

    afterEach(() => {
        fs.rmSync(workDir, { recursive: true, force: true });
    });

    // formatJsonForImport writes via a fire-and-forget stream and returns
    // before the data is flushed to disk. `fs.createWriteStream` can't be
    // spied on directly in this environment (non-configurable property), so
    // instead poll until the file's content stops changing between two
    // consecutive reads, up to a bounded timeout.
    async function readOnceFlushed(outputFile: string): Promise<string> {
        const deadline = Date.now() + 2000;
        let previous: string | null = null;

        while (Date.now() < deadline) {
            const current = fs.existsSync(outputFile) ? fs.readFileSync(outputFile, 'utf-8') : null;

            if (current !== null && current === previous) {
                return current;
            }

            previous = current;
            await new Promise(resolve => setTimeout(resolve, 20));
        }

        throw new Error(`Timed out waiting for ${outputFile} to be flushed`);
    }

    it('writes one JSON object per line (NDJSON)', async () => {
        const outputFile = path.join(workDir, 'out.ndjson');
        formatJsonForImport([{ a: 1 }, { b: 2 }], outputFile);

        const content = await readOnceFlushed(outputFile);
        const lines = content.trim().split('\n');
        expect(lines).toHaveLength(2);
        expect(JSON.parse(lines[0])).toEqual({ a: 1 });
        expect(JSON.parse(lines[1])).toEqual({ b: 2 });
    });

    it('escapes special characters (quotes, newlines) via JSON.stringify', async () => {
        const outputFile = path.join(workDir, 'special.ndjson');
        formatJsonForImport([{ text: 'a "quoted"\nvalue' }], outputFile);

        const content = await readOnceFlushed(outputFile);
        expect(JSON.parse(content.trim())).toEqual({ text: 'a "quoted"\nvalue' });
    });

    it('writes an empty file when given no data', async () => {
        const outputFile = path.join(workDir, 'empty.ndjson');
        formatJsonForImport([], outputFile);

        const content = await readOnceFlushed(outputFile);
        expect(content).toBe('');
    });
});
