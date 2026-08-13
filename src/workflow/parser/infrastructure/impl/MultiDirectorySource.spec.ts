import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { MultiDirectorySource } from './MultiDirectorySource';

describe('MultiDirectorySource', () => {
    let workDir: string;

    beforeEach(() => {
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'multi-directory-source-spec-'));
    });

    afterEach(() => {
        fs.rmSync(workDir, { recursive: true, force: true });
    });

    it('concatenates files found across multiple subdirectories, in the given order', () => {
        fs.mkdirSync(path.join(workDir, 'acteurs'));
        fs.mkdirSync(path.join(workDir, 'scrutins'));
        fs.writeFileSync(path.join(workDir, 'acteurs', 'a1.json'), '{}');
        fs.writeFileSync(path.join(workDir, 'scrutins', 's1.json'), '{}');
        fs.writeFileSync(path.join(workDir, 'scrutins', 's2.json'), '{}');

        const files = new MultiDirectorySource(workDir, ['acteurs', 'scrutins']).getFiles();

        expect(files).toEqual([
            path.join(workDir, 'acteurs', 'a1.json'),
            path.join(workDir, 'scrutins', 's1.json'),
            path.join(workDir, 'scrutins', 's2.json'),
        ]);
    });

    it('silently skips a subdir that does not exist', () => {
        fs.mkdirSync(path.join(workDir, 'acteurs'));
        fs.writeFileSync(path.join(workDir, 'acteurs', 'a1.json'), '{}');

        const files = new MultiDirectorySource(workDir, ['acteurs', 'missing-domain']).getFiles();

        expect(files).toEqual([path.join(workDir, 'acteurs', 'a1.json')]);
    });

    it('skips an entry that exists but is a file, not a directory', () => {
        fs.writeFileSync(path.join(workDir, 'not-a-dir'), 'oops');

        const files = new MultiDirectorySource(workDir, ['not-a-dir']).getFiles();

        expect(files).toEqual([]);
    });

    it('returns an empty array when given no subdirs', () => {
        expect(new MultiDirectorySource(workDir, []).getFiles()).toEqual([]);
    });
});
