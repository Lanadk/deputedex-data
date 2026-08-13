import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { DirectorySource } from './DirectorySource';

describe('DirectorySource', () => {
    let workDir: string;

    beforeEach(() => {
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'directory-source-spec-'));
    });

    afterEach(() => {
        fs.rmSync(workDir, { recursive: true, force: true });
    });

    it('returns an empty array for an empty directory', () => {
        expect(new DirectorySource(workDir).getFiles()).toEqual([]);
    });

    it('lists .json files directly in the directory', () => {
        fs.writeFileSync(path.join(workDir, 'a.json'), '{}');
        fs.writeFileSync(path.join(workDir, 'b.json'), '{}');

        const files = new DirectorySource(workDir).getFiles().sort();

        expect(files).toEqual([path.join(workDir, 'a.json'), path.join(workDir, 'b.json')].sort());
    });

    it('ignores non-.json files', () => {
        fs.writeFileSync(path.join(workDir, 'a.json'), '{}');
        fs.writeFileSync(path.join(workDir, 'notes.txt'), 'hello');
        fs.writeFileSync(path.join(workDir, 'archive.zip'), 'zip');

        const files = new DirectorySource(workDir).getFiles();

        expect(files).toEqual([path.join(workDir, 'a.json')]);
    });

    it('recurses into nested subdirectories', () => {
        const nested = path.join(workDir, 'sub', 'deeper');
        fs.mkdirSync(nested, { recursive: true });
        fs.writeFileSync(path.join(workDir, 'root.json'), '{}');
        fs.writeFileSync(path.join(workDir, 'sub', 'mid.json'), '{}');
        fs.writeFileSync(path.join(nested, 'leaf.json'), '{}');

        const files = new DirectorySource(workDir).getFiles().sort();

        expect(files).toEqual(
            [
                path.join(workDir, 'root.json'),
                path.join(workDir, 'sub', 'mid.json'),
                path.join(nested, 'leaf.json'),
            ].sort()
        );
    });
});
