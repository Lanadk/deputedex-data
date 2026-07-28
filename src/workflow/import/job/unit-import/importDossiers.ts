import * as fs from "fs";
import * as path from "path";
import { Logger, LogLevel } from "../../../../utils/logger";
import { confirm } from "../../../../utils/confirm";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// DOSSIERS PARLEMENTAIRES IMPORT JOB
// Import des JSON dossiers législatifs pour chaque législature
// Raw → Snapshot → Final avec cleanup optionnel
// Port TS de dossiers-import.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../../..");
const srcDir = path.join(repoRoot, "src");
const rootDataDir = path.resolve(repoRoot, "..");

const SCHEMA_DIR = path.join(srcDir, "sql", "schema");
const SCRIPTS_DIR = path.join(srcDir, "sql", "scripts", "dossiers");
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
    logger.info("  DOSSIERS PARLEMENTAIRES IMPORT JOB");
    logger.info("==============================================");

    const steps: Step[] = [
        { kind: "sqlFile", label: "[SCHEMA] Import schema", path: path.join(SCHEMA_DIR, "dossiers.schema.sql") },
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
                label: `[RAW ${legislature}] dossiers`,
                jsonFile: path.join(dir, "dossiersParlementaire.json"),
                rawTable: "dossier_parlementaire_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_dossiers.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] initiateurs`,
                jsonFile: path.join(dir, "dossiersInitiateur.json"),
                rawTable: "dossier_initiateur_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_initiateurs.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] actes`,
                jsonFile: path.join(dir, "acteLegislatif.json"),
                rawTable: "acte_legislatif_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_actes.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] rapporteurs`,
                jsonFile: path.join(dir, "acteRapporteur.json"),
                rawTable: "acte_rapporteur_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_rapporteurs.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] textes associés`,
                jsonFile: path.join(dir, "acteTexteAssocie.json"),
                rawTable: "acte_texte_associe_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_textes_associes.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] réunions`,
                jsonFile: path.join(dir, "acteReunion.json"),
                rawTable: "acte_reunion_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_reunions.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] décisions`,
                jsonFile: path.join(dir, "acteDecision.json"),
                rawTable: "acte_decision_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_decisions.sql"),
            },
            {
                kind: "importRaw",
                label: `[RAW ${legislature}] votes`,
                jsonFile: path.join(dir, "acteVote.json"),
                rawTable: "acte_vote_raw",
                projectionSqlFile: path.join(SCRIPTS_DIR, "projections/project_votes.sql"),
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
