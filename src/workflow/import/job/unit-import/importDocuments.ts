import * as fs from "fs";
import * as path from "path";
import { Logger, LogLevel } from "../../../../utils/logger";
import { confirm } from "../../../../utils/confirm";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// DOCUMENTS PARLEMENTAIRES IMPORT JOB
// Import des JSON documents parlementaires pour chaque législature
// Raw → Snapshot → Final avec cleanup optionnel
// Port TS de documents-import.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../../..");
const srcDir = path.join(repoRoot, "src");
const rootDataDir = path.resolve(repoRoot, "..");

const SCHEMA_DIR = path.join(srcDir, "sql", "schema");
const SCRIPTS_DIR = path.join(srcDir, "sql", "scripts", "documents");
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
    logger.info("  DOCUMENTS PARLEMENTAIRES IMPORT JOB");
    logger.info("==============================================");

    const steps: Step[] = [
        { kind: "sqlFile", label: "[SCHEMA] Import schema", path: path.join(SCHEMA_DIR, "documents.schema.sql") },
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
                label: `[RAW ${legislature}] documents`,
                jsonFile: path.join(dir, "documents.json"),
                rawTable: "documents_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_documents.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] classifications`,
                jsonFile: path.join(dir, "documentsClassifications.json"),
                rawTable: "documents_classifications_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_documents_classifications.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] auteurs`,
                jsonFile: path.join(dir, "documentsAuteurs.json"),
                rawTable: "documents_auteurs_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_documents_auteurs.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] co-signataires`,
                jsonFile: path.join(dir, "documentsCoSignataires.json"),
                rawTable: "documents_co_signataires_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_documents_co_signataires.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] organes référents`,
                jsonFile: path.join(dir, "documentsOrganesReferents.json"),
                rawTable: "documents_organes_referents_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_documents_organes_referents.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] imprimeries`,
                jsonFile: path.join(dir, "documentsImprimeries.json"),
                rawTable: "documents_imprimeries_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_documents_imprimeries.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] dépôts amendements`,
                jsonFile: path.join(dir, "documentsDepotsAmendements.json"),
                rawTable: "documents_depots_amendements_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_documents_depots_amendements.sql"),
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
