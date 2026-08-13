// FileManager resolves its base directory from a hardcoded path outside the
// repo (the sibling `data/` folder — see CLAUDE.md) and writes to it via
// fs.mkdirSync unconditionally. Since fs's exported functions are
// non-configurable in this environment (jest.spyOn fails on them, see
// utils.spec.ts), the whole module is replaced instead, so no test here
// ever touches the real shared data folder.
jest.mock('fs', () => ({
    existsSync: jest.fn(),
    mkdirSync: jest.fn(),
}));

import * as fs from 'fs';
import * as path from 'path';
import { FileManager } from './FileManager';

const mockedExistsSync = fs.existsSync as jest.Mock;
const mockedMkdirSync = fs.mkdirSync as jest.Mock;

// Mirrors FileManager's own path.resolve(__dirname, '../../../../../..') —
// this spec file is colocated next to FileManager.ts, so __dirname matches.
const DATA_ROOT = path.resolve(__dirname, '../../../../../..');
const ZIP_DIR = path.join(DATA_ROOT, 'data', 'download', 'zip');
const UNZIP_DIR = path.join(DATA_ROOT, 'data', 'download', 'unzip');

describe('FileManager', () => {
    let consoleLogSpy: jest.SpyInstance;

    beforeEach(() => {
        consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
        mockedExistsSync.mockReturnValue(false);
    });

    afterEach(() => {
        jest.restoreAllMocks();
        jest.clearAllMocks();
    });

    describe('prepareDownloadPaths', () => {
        it('computes the zip and unzip paths from legislature/domain/filename', () => {
            const manager = new FileManager();

            const paths = manager.prepareDownloadPaths('/tmp/session', 'acteurs.zip', 17, 'acteurs');

            expect(paths).toEqual({
                zipDir: '/tmp/session',
                zipFilePath: path.join('/tmp/session', '17', 'acteurs.zip'),
                unzipDir: path.join(UNZIP_DIR, '17', 'acteurs'),
            });
        });

        it('creates the zip and unzip directories when they do not exist', () => {
            const manager = new FileManager();

            manager.prepareDownloadPaths('/tmp/session', 'acteurs.zip', 17, 'acteurs');

            expect(mockedMkdirSync).toHaveBeenCalledWith(path.join('/tmp/session', '17'), { recursive: true });
            expect(mockedMkdirSync).toHaveBeenCalledWith(path.join(UNZIP_DIR, '17', 'acteurs'), { recursive: true });
        });

        it('does not create directories that already exist', () => {
            mockedExistsSync.mockReturnValue(true);
            const manager = new FileManager();

            manager.prepareDownloadPaths('/tmp/session', 'acteurs.zip', 17, 'acteurs');

            expect(mockedMkdirSync).not.toHaveBeenCalled();
        });
    });

    describe('createTimestampedZipDir', () => {
        it('returns a path under ZIP_DIR stamped as YYYY-MM-DD_HH-mm-ss and creates it', () => {
            jest.useFakeTimers().setSystemTime(new Date(2024, 6, 8, 9, 5, 3)); // 2024-07-08 09:05:03 local
            const manager = new FileManager();

            const dir = manager.createTimestampedZipDir();

            expect(dir).toBe(path.join(ZIP_DIR, '2024-07-08_09-05-03'));
            expect(mockedMkdirSync).toHaveBeenCalledWith(dir, { recursive: true });
            jest.useRealTimers();
        });
    });

    describe('fileExists', () => {
        it('delegates to fs.existsSync', async () => {
            mockedExistsSync.mockReturnValue(true);
            const manager = new FileManager();

            await expect(manager.fileExists('/tmp/a.zip')).resolves.toBe(true);
            expect(mockedExistsSync).toHaveBeenCalledWith('/tmp/a.zip');
        });
    });
});
