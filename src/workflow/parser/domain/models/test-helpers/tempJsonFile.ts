import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

/**
 * Writes `data` (or a raw string, for malformed-JSON test cases) to a fresh
 * temp file and returns its path plus a cleanup callback. Extractors read
 * files via fs.readFileSync(filePath), so exercising them through a real
 * temp file is simpler and more robust than mocking fs (fs's exported
 * functions are non-configurable in this environment and can't be spied on).
 */
export function writeTempJsonFile(data: unknown, options: { raw?: boolean } = {}): {
    filePath: string;
    cleanup: () => void;
} {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'extractor-spec-'));
    const filePath = path.join(dir, 'fixture.json');
    const content = options.raw ? (data as string) : JSON.stringify(data);
    fs.writeFileSync(filePath, content, 'utf-8');

    return {
        filePath,
        cleanup: () => fs.rmSync(dir, { recursive: true, force: true }),
    };
}

export const ROW_HASH_PATTERN = /^[0-9a-f]{32}$/;
