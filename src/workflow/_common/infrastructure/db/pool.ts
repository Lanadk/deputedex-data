import { config } from "dotenv";
import { existsSync } from "fs";
import { resolve } from "path";
import { Pool } from "pg";

const rootDir = resolve(__dirname, "../../../../..");
const envPath = resolve(rootDir, ".env.local");

if (existsSync(envPath)) {
    config({ path: envPath });
} else {
    const fallbackEnvPath = resolve(rootDir, ".env");
    if (existsSync(fallbackEnvPath)) {
        config({ path: fallbackEnvPath });
    }
}

function requireEnv(name: string): string {
    const value = process.env[name];
    if (!value) {
        throw new Error(`❌ ${name} is not defined. Please check your .env.local file`);
    }
    return value;
}

// Pool ETL dédié au rôle writer (user_etl_writer), distinct du pool admin
// utilisé par prisma/prisma.ts (construit sur DB_URL). On préserve ainsi la
// séparation de privilèges writer/reader mise en place par local-db-init.ts.
const writerPool = new Pool({
    host: requireEnv("DB_HOST"),
    port: Number(requireEnv("DB_PORT")),
    database: requireEnv("DB_NAME"),
    user: requireEnv("DB_USER_WRITER"),
    password: requireEnv("DB_PASSWORD_WRITER"),
});

export { writerPool };
