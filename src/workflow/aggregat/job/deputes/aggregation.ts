import { Logger, LogLevel } from "../../../../utils/logger";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// DEPUTES AGGREGATION - REFRESH JOB
// Rafraîchit les materialized views d'agrégation des deputes
// Port TS de deputes/aggregation.sh
// ==============================================================================

const VIEWS = ["agg_deputes_cards", "agg_deputes_stats_votes", "agg_deputes_stats_age"];

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);

    logger.info("==============================================");
    logger.info("  DEPUTES AGGREGATION REFRESH JOB");
    logger.info("==============================================");

    const steps: Step[] = VIEWS.map(viewName => ({
        kind: "refreshView",
        label: `[REFRESH] ${viewName}`,
        viewName,
    }));

    await job.run(steps);

    logger.success("✅ DEPUTES AGGREGATION REFRESHED");
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
