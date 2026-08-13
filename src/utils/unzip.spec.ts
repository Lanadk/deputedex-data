import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import AdmZip from 'adm-zip';
import { unzipFile } from './unzip';

describe('unzipFile', () => {
    let workDir: string;

    beforeEach(() => {
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'unzip-spec-'));
    });

    afterEach(() => {
        fs.rmSync(workDir, { recursive: true, force: true });
    });

    it('throws when the zip file does not exist', async () => {
        const missing = path.join(workDir, 'missing.zip');

        await expect(unzipFile(missing, path.join(workDir, 'out'))).rejects.toThrow(
            /does not exist/
        );
    });

    it('creates the target directory when it is missing', async () => {
        const zip = new AdmZip();
        zip.addFile('data.json', Buffer.from('{"ok":true}'));
        const zipPath = path.join(workDir, 'archive.zip');
        zip.writeZip(zipPath);

        const targetDir = path.join(workDir, 'nested', 'out');
        expect(fs.existsSync(targetDir)).toBe(false);

        await unzipFile(zipPath, targetDir);

        expect(fs.existsSync(targetDir)).toBe(true);
    });

    it('extracts the archive content into the target directory', async () => {
        const zip = new AdmZip();
        zip.addFile('data.json', Buffer.from('{"ok":true}'));
        zip.addFile('sub/nested.txt', Buffer.from('hello'));
        const zipPath = path.join(workDir, 'archive.zip');
        zip.writeZip(zipPath);

        const targetDir = path.join(workDir, 'out');
        await unzipFile(zipPath, targetDir);

        expect(fs.readFileSync(path.join(targetDir, 'data.json'), 'utf-8')).toBe('{"ok":true}');
        expect(fs.readFileSync(path.join(targetDir, 'sub', 'nested.txt'), 'utf-8')).toBe('hello');
    });
});
