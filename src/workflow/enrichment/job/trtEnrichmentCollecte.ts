import * as path from "path";
import { Logger, LogLevel } from "../../../utils/logger";
import { writerPool } from "../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../_common/job/PipelineJob";

// ==============================================================================
// ENRICHMENT JOB
// Port TS de trtEnrichmentCollecte.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../..");
const scriptsDir = path.join(repoRoot, "src", "sql", "scripts");

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);

    logger.info("==============================================");
    logger.info("🚀 Starting ALL Enrichment process");
    logger.info("==============================================");

    const steps: Step[] = [
        {
            kind: "sqlFile",
            label: "Enrichment of acteurs_groupes table",
            path: path.join(scriptsDir, "acteurs/enrichment/acteurs_groupes.sql"),
        },
        {
            kind: "sqlFile",
            label: "[VERIFY] Final row counts",
            path: path.join(scriptsDir, "_shared/verify_final_count_enrichment_tables.sql"),
        },
    ];

    await job.run(steps);

    logger.success("✅ ENRICHMENT DATA DONE");
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
