import * as path from "path";
import { Logger, LogLevel } from "../../../utils/logger";
import { writerPool } from "../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../_common/job/PipelineJob";

// ==============================================================================
// REFERENTIALS JOB
// Création/mise à jour de toutes les tables référentielles
// Port TS de trtUpdateReferentials.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../..");
const scriptsDir = path.join(repoRoot, "src", "sql", "scripts");

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);

    logger.info("==============================================");
    logger.info("🚀 Starting ALL REFERENTIALS creation");
    logger.info("==============================================");

    const steps: Step[] = [
        {
            kind: "sqlFile",
            label: "Creating organe type referentials table",
            path: path.join(scriptsDir, "mandats/referentials/ref_organe_type.sql"),
        },
        {
            kind: "sqlFile",
            label: "Creating scrutin type referentials table",
            path: path.join(scriptsDir, "scrutins/referentials/ref_scrutin_type.sql"),
        },
        {
            kind: "sqlFile",
            label: "Creating groups referentials table",
            path: path.join(scriptsDir, "groups/referentials/ref_groupes.sql"),
        },
        {
            kind: "sqlFile",
            label: "Creating acteurs photos referentials table",
            path: path.join(scriptsDir, "acteurs/referentials/ref_acteurs_photos.sql"),
        },
        {
            kind: "sqlFile",
            label: "[VERIFY] Final row counts",
            path: path.join(scriptsDir, "_shared/verify_final_count_ref_tables.sql"),
        },
    ];

    await job.run(steps);

    logger.success("✅ REFERENTIALS DATA TABLES CREATED");
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
