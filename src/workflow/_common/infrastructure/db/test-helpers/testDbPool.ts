import { Pool } from 'pg';
import { config } from 'dotenv';
import { existsSync } from 'fs';
import { resolve } from 'path';

// Integration tests open their own short-lived Pool (rather than importing
// the shared `writerPool` singleton from ../pool) so each spec file can
// safely `.end()` it in afterAll without tearing down a pool other IT spec
// files still rely on when Jest runs the integration project --runInBand.
const rootDir = resolve(__dirname, '../../../../../..');
const envPath = resolve(rootDir, '.env.local');

if (existsSync(envPath)) {
    config({ path: envPath });
}

function requireEnv(name: string): string {
    const value = process.env[name];
    if (!value) {
        throw new Error(
            `Integration tests require ${name} to be set (via .env.local locally, or CI job env). ` +
            `Run against the local Postgres (npm run docker:db) or the CI postgres service.`
        );
    }
    return value;
}

export function createTestPool(): Pool {
    return new Pool({
        host: requireEnv('DB_HOST'),
        port: Number(requireEnv('DB_PORT')),
        database: requireEnv('DB_NAME'),
        user: requireEnv('DB_USER_WRITER'),
        password: requireEnv('DB_PASSWORD_WRITER'),
    });
}

export function uniqueTestName(prefix: string): string {
    return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 1e6)}`;
}
