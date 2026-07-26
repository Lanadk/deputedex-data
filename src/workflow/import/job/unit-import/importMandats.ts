import * as fs from "fs";
import * as path from "path";
import { Logger, LogLevel } from "../../../../utils/logger";
import { confirm } from "../../../../utils/confirm";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// MANDATS IMPORT JOB
// Import des JSON mandats pour chaque législature
// Raw → Snapshot → Final avec cleanup optionnel
// Port TS de mandats-import.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../../..");
const srcDir = path.join(repoRoot, "src");
const rootDataDir = path.resolve(repoRoot, "..");

const SCHEMA_DIR = path.join(srcDir, "sql", "schema");
const SCRIPTS_DIR = path.join(srcDir, "sql", "scripts", "mandats");
const TABLES_DIR = path.join(rootDataDir, "data", "parser", "tables");

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);
    const autoCleanup = process.argv.includes("--auto-cleanup");

    if (!fs.existsSync(SCHEMA_DIR) || !fs.existsSync(TABLES_DIR)) {
        logger.error(`Missing directory: ${!fs.existsSync(SCHEMA_DIR) ? SCHEMA_DIR : TABLES_DIR}`);
        process.exit(1);
    }

    logger.info("==============================================");
    logger.info("  MANDATS IMPORT JOB");
    logger.info("==============================================");

    const steps: Step[] = [
        { kind: "sqlFile", label: "[SCHEMA] Import schema", path: path.join(SCHEMA_DIR, "mandats.schema.sql") },
    ];

    const legislatures = fs
        .readdirSync(TABLES_DIR)
        .filter(name => /^\d+$/.test(name))
        .sort();

    for (const legislature of legislatures) {
        const dir = path.join(TABLES_DIR, legislature);

        steps.push(
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] mandats`,
                jsonFile: path.join(dir, "mandats.json"),
                rawTable: "mandats_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_mandats.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] suppléants`,
                jsonFile: path.join(dir, "mandatsSuppleants.json"),
                rawTable: "mandats_suppleants_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_mandats_suppleants.sql"),
            }
        );
    }

    steps.push({
        kind: "sqlFile",
        label: "[SYNC] Snapshot → Final",
        path: path.join(SCRIPTS_DIR, "sync/sync_snapshot_to_final.sql"),
    });

    await job.run(steps);

    await job.run([
        {
            kind: "sqlFile",
            label: "[CLEANUP] Drop snapshots",
            path: path.join(SCRIPTS_DIR, "cleanup/drop_snapshots_tables.sql"),
        },
    ]);

    const dropRaw = autoCleanup || (await confirm("Drop raw tables? (y/n) "));
    if (dropRaw) {
        await job.run([
            {
                kind: "sqlFile",
                label: "[CLEANUP] Drop raw tables",
                path: path.join(SCRIPTS_DIR, "cleanup/drop_raw_tables.sql"),
            },
        ]);
    } else {
        logger.info("⏭️  [CLEANUP] Raw tables kept");
    }

    await job.run([
        { kind: "sqlFile", label: "[VERIFY] Final row counts", path: path.join(SCRIPTS_DIR, "verify/final_counts.sql") },
    ]);

    logger.success("✅ IMPORT COMPLETED");
}

export { main };

if (require.main === module) {
    main()
        .catch(error => {
            console.error("[ERROR  ❌ ]:", error);
            process.exitCode = 1;
        })
        .finally(() => writerPool.end());
}
