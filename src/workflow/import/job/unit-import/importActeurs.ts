import * as fs from "fs";
import * as path from "path";
import { Logger, LogLevel } from "../../../../utils/logger";
import { confirm } from "../../../../utils/confirm";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// ACTEURS IMPORT JOB
// Import des JSON acteurs pour chaque législature
// Raw → Snapshot → Final avec cleanup optionnel
// Port TS de acteurs-import.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../../..");
const srcDir = path.join(repoRoot, "src");
const rootDataDir = path.resolve(repoRoot, "..");

const SCHEMA_DIR = path.join(srcDir, "sql", "schema");
const SCRIPTS_DIR = path.join(srcDir, "sql", "scripts", "acteurs");
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
    logger.info("  ACTEURS IMPORT JOB");
    logger.info("==============================================");

    const steps: Step[] = [
        { kind: "sqlFile", label: "[SCHEMA] Import schema", path: path.join(SCHEMA_DIR, "acteurs.schema.sql") },
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
                label: `[RAW ${legislature}] acteurs`,
                jsonFile: path.join(dir, "acteurs.json"),
                rawTable: "acteurs_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_acteurs.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] adresses postales`,
                jsonFile: path.join(dir, "acteursAdressesPostales.json"),
                rawTable: "acteurs_adresses_postales_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_acteurs_adresses_postales.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] adresses mails`,
                jsonFile: path.join(dir, "acteursAdressesMails.json"),
                rawTable: "acteurs_adresses_mails_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_acteurs_adresses_mails.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] réseaux sociaux`,
                jsonFile: path.join(dir, "acteursReseauxSociaux.json"),
                rawTable: "acteurs_reseaux_sociaux_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_acteurs_reseaux_sociaux.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] téléphones`,
                jsonFile: path.join(dir, "acteursTelephones.json"),
                rawTable: "acteurs_telephones_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_acteurs_telephones.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] groupes vus des mandats`,
                jsonFile: path.join(dir, "groupesVuDesMandats.json"),
                rawTable: "groupes_parlementaires_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_groupes_parlementaires.sql"),
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
