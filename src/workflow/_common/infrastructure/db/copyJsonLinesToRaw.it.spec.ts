import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { Pool } from 'pg';
import { importJsonLinesToRaw } from './copyJsonLinesToRaw';
import { createTestPool, uniqueTestName } from './test-helpers/testDbPool';

describe('importJsonLinesToRaw (integration)', () => {
    let pool: Pool;
    let workDir: string;
    let rawTable: string;
    let finalTable: string;
    let projectionSqlFile: string;

    beforeAll(() => {
        pool = createTestPool();
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'copy-json-it-'));
    });

    afterAll(async () => {
        fs.rmSync(workDir, { recursive: true, force: true });
        await pool.end();
    });

    beforeEach(async () => {
        rawTable = uniqueTestName('it_raw');
        finalTable = uniqueTestName('it_final');
        await pool.query(`CREATE TABLE ${rawTable} (data JSONB);`);
        await pool.query(`CREATE TABLE ${finalTable} (id TEXT, value INT);`);

        projectionSqlFile = path.join(workDir, `${uniqueTestName('projection')}.sql`);
        fs.writeFileSync(
            projectionSqlFile,
            `INSERT INTO ${finalTable} (id, value) SELECT data->>'id', (data->>'value')::int FROM ${rawTable};`,
            'utf-8'
        );
    });

    afterEach(async () => {
        await pool.query(`DROP TABLE IF EXISTS ${rawTable};`);
        await pool.query(`DROP TABLE IF EXISTS ${finalTable};`);
    });

    function writeJsonLinesFile(lines: string[]): string {
        const filePath = path.join(workDir, `${uniqueTestName('data')}.jsonl`);
        fs.writeFileSync(filePath, lines.join('\n') + '\n', 'utf-8');
        return filePath;
    }

    it('copies each JSON line through the raw table, runs the projection, and truncates the raw table', async () => {
        const jsonFile = writeJsonLinesFile([
            JSON.stringify({ id: 'a', value: 1 }),
            JSON.stringify({ id: 'b', value: 2 }),
            JSON.stringify({ id: 'c', value: 3 }),
        ]);

        await importJsonLinesToRaw(pool, jsonFile, rawTable, projectionSqlFile);

        const final = await pool.query(`SELECT id, value FROM ${finalTable} ORDER BY id;`);
        expect(final.rows).toEqual([
            { id: 'a', value: 1 },
            { id: 'b', value: 2 },
            { id: 'c', value: 3 },
        ]);

        const rawCount = await pool.query(`SELECT count(*)::int AS n FROM ${rawTable};`);
        expect(rawCount.rows[0].n).toBe(0); // truncated after the projection runs
    });

    it('skips blank lines in the source file', async () => {
        const jsonFile = writeJsonLinesFile([JSON.stringify({ id: 'a', value: 1 }), '', '   ', JSON.stringify({ id: 'b', value: 2 })]);

        await importJsonLinesToRaw(pool, jsonFile, rawTable, projectionSqlFile);

        const final = await pool.query(`SELECT id, value FROM ${finalTable} ORDER BY id;`);
        expect(final.rows).toEqual([
            { id: 'a', value: 1 },
            { id: 'b', value: 2 },
        ]);
    });

    it('preserves JSON content that contains characters used internally as CSV quote/delimiter markers', async () => {
        // Regression guard for the exotic \x01/\x02 quote/delimiter trick in
        // copyFromSql: text values containing commas, quotes and unicode must
        // survive the COPY round-trip unscathed.
        const jsonFile = writeJsonLinesFile([JSON.stringify({ id: 'weird', value: 42, note: 'a "quoted", café \n value' })]);
        // extend the final table for this one test's extra column
        await pool.query(`ALTER TABLE ${finalTable} ADD COLUMN note TEXT;`);
        fs.writeFileSync(
            projectionSqlFile,
            `INSERT INTO ${finalTable} (id, value, note) SELECT data->>'id', (data->>'value')::int, data->>'note' FROM ${rawTable};`,
            'utf-8'
        );

        await importJsonLinesToRaw(pool, jsonFile, rawTable, projectionSqlFile);

        const final = await pool.query(`SELECT id, value, note FROM ${finalTable};`);
        expect(final.rows).toEqual([{ id: 'weird', value: 42, note: 'a "quoted", café \n value' }]);
    });

    it('processes the file in multiple chunks when it exceeds maxSizeMB, truncating raw between each chunk', async () => {
        const rows = Array.from({ length: 20 }, (_, i) => JSON.stringify({ id: `row-${i}`, value: i }));
        const jsonFile = writeJsonLinesFile(rows);

        // Force several small chunks (each row is a few dozen bytes) so the
        // flush/truncate cycle runs more than once.
        await importJsonLinesToRaw(pool, jsonFile, rawTable, projectionSqlFile, { maxSizeMB: 0.0002 });

        const final = await pool.query(`SELECT count(*)::int AS n FROM ${finalTable};`);
        expect(final.rows[0].n).toBe(20);

        const rawCount = await pool.query(`SELECT count(*)::int AS n FROM ${rawTable};`);
        expect(rawCount.rows[0].n).toBe(0);
    });

    it('still runs the projection once for an empty file (no rows to copy)', async () => {
        const jsonFile = writeJsonLinesFile([]);

        await importJsonLinesToRaw(pool, jsonFile, rawTable, projectionSqlFile);

        const final = await pool.query(`SELECT count(*)::int AS n FROM ${finalTable};`);
        expect(final.rows[0].n).toBe(0);
    });
});
