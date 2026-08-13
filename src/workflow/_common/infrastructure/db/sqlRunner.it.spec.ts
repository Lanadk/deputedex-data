import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { Pool } from 'pg';
import { refreshMaterializedView, runSqlFile } from './sqlRunner';
import { createTestPool, uniqueTestName } from './test-helpers/testDbPool';

describe('sqlRunner (integration)', () => {
    let pool: Pool;
    let workDir: string;

    beforeAll(() => {
        pool = createTestPool();
        workDir = fs.mkdtempSync(path.join(os.tmpdir(), 'sqlrunner-it-'));
    });

    afterAll(async () => {
        fs.rmSync(workDir, { recursive: true, force: true });
        await pool.end();
    });

    function writeSqlFile(sql: string): string {
        const filePath = path.join(workDir, `${uniqueTestName('script')}.sql`);
        fs.writeFileSync(filePath, sql, 'utf-8');
        return filePath;
    }

    describe('runSqlFile', () => {
        const table = uniqueTestName('it_sql_runner');

        afterAll(async () => {
            await pool.query(`DROP TABLE IF EXISTS ${table};`);
        });

        it('executes a multi-statement file and returns the last statement result (the final SELECT)', async () => {
            const sqlFile = writeSqlFile(`
                CREATE TABLE ${table} (id INT, label TEXT);
                INSERT INTO ${table} (id, label) VALUES (1, 'a'), (2, 'b');
                SELECT * FROM ${table} ORDER BY id;
            `);

            const result = await runSqlFile(pool, sqlFile);

            expect(result.rows).toEqual([
                { id: 1, label: 'a' },
                { id: 2, label: 'b' },
            ]);
        });

        it('returns the single QueryResult directly for a one-statement file', async () => {
            const sqlFile = writeSqlFile(`SELECT * FROM ${table} WHERE id = 1;`);

            const result = await runSqlFile(pool, sqlFile);

            expect(result.rows).toEqual([{ id: 1, label: 'a' }]);
        });

        it('propagates a SQL error instead of swallowing it', async () => {
            const sqlFile = writeSqlFile('SELECT * FROM this_table_does_not_exist;');

            await expect(runSqlFile(pool, sqlFile)).rejects.toThrow(/does not exist/);
        });

        it('works against a real PoolClient as well as a Pool', async () => {
            const client = await pool.connect();
            try {
                const sqlFile = writeSqlFile(`SELECT count(*)::int AS n FROM ${table};`);
                const result = await runSqlFile(client, sqlFile);
                expect(result.rows).toEqual([{ n: 2 }]);
            } finally {
                client.release();
            }
        });
    });

    describe('refreshMaterializedView', () => {
        const table = uniqueTestName('it_refresh_source');
        const view = uniqueTestName('it_refresh_view');

        beforeAll(async () => {
            await pool.query(`CREATE TABLE ${table} (id INT PRIMARY KEY, label TEXT);`);
            await pool.query(`INSERT INTO ${table} (id, label) VALUES (1, 'a');`);
            await pool.query(`CREATE MATERIALIZED VIEW ${view} AS SELECT id, label FROM ${table};`);
            // CONCURRENTLY requires a unique index on the materialized view.
            await pool.query(`CREATE UNIQUE INDEX ON ${view} (id);`);
        });

        afterAll(async () => {
            await pool.query(`DROP MATERIALIZED VIEW IF EXISTS ${view};`);
            await pool.query(`DROP TABLE IF EXISTS ${table};`);
        });

        it('refreshes the view to reflect changes made to the underlying table since creation', async () => {
            await pool.query(`INSERT INTO ${table} (id, label) VALUES (2, 'b');`);

            const before = await pool.query(`SELECT * FROM ${view} ORDER BY id;`);
            expect(before.rows).toEqual([{ id: 1, label: 'a' }]); // stale, not yet refreshed

            await refreshMaterializedView(pool, view);

            const after = await pool.query(`SELECT * FROM ${view} ORDER BY id;`);
            expect(after.rows).toEqual([
                { id: 1, label: 'a' },
                { id: 2, label: 'b' },
            ]);
        });
    });
});
