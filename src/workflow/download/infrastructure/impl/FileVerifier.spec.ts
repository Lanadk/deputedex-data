import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { createHash } from 'crypto';
import { FileVerifier } from './FileVerifier';

describe('FileVerifier', () => {
    let workDir: string;
    let verifier: FileVerifier;

    beforeEach(() => {
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'file-verifier-spec-'));
        verifier = new FileVerifier();
    });

    afterEach(() => {
        fs.rmSync(workDir, { recursive: true, force: true });
    });

    it('computes the sha256 checksum of a file, matching a reference computed independently', async () => {
        const filePath = path.join(workDir, 'file.bin');
        const content = Buffer.from('hello deputydex');
        fs.writeFileSync(filePath, content);
        const expected = createHash('sha256').update(content).digest('hex');

        await expect(verifier.calculateChecksum(filePath)).resolves.toBe(expected);
    });

    it('produces different checksums for different content', async () => {
        const fileA = path.join(workDir, 'a.bin');
        const fileB = path.join(workDir, 'b.bin');
        fs.writeFileSync(fileA, 'content A');
        fs.writeFileSync(fileB, 'content B');

        const [checksumA, checksumB] = await Promise.all([
            verifier.calculateChecksum(fileA),
            verifier.calculateChecksum(fileB),
        ]);

        expect(checksumA).not.toBe(checksumB);
    });

    it('rejects when the file does not exist', async () => {
        await expect(verifier.calculateChecksum(path.join(workDir, 'missing.bin'))).rejects.toThrow();
    });

    it('verifyChecksum resolves true when the checksum matches', async () => {
        const filePath = path.join(workDir, 'file.bin');
        fs.writeFileSync(filePath, 'content');
        const checksum = await verifier.calculateChecksum(filePath);

        await expect(verifier.verifyChecksum(filePath, checksum)).resolves.toBe(true);
    });

    it('verifyChecksum resolves false when the checksum does not match', async () => {
        const filePath = path.join(workDir, 'file.bin');
        fs.writeFileSync(filePath, 'content');

        await expect(verifier.verifyChecksum(filePath, 'deadbeef')).resolves.toBe(false);
    });

    it('getFileSize returns the exact byte size as a bigint', async () => {
        const filePath = path.join(workDir, 'file.bin');
        fs.writeFileSync(filePath, Buffer.alloc(1234));

        await expect(verifier.getFileSize(filePath)).resolves.toBe(BigInt(1234));
    });
});
