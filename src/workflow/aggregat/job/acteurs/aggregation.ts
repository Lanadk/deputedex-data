import { Logger, LogLevel } from "../../../../utils/logger";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// ACTEURS AGGREGATION - REFRESH JOB
// Rafraîchit les materialized views d'agrégation des acteurs
// Port TS de acteurs/aggregation.sh
// ==============================================================================

const VIEWS = [
    "agg_acteurs_stats_professions",
    "agg_acteurs_stats_genre",
    "agg_acteurs_stats_age",
    "agg_acteurs_stats_geographie_election",
    "agg_acteurs_stats_geographie_naissance",
];

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);

    logger.info("==============================================");
    logger.info("  ACTEURS AGGREGATION REFRESH JOB");
    logger.info("==============================================");

    const steps: Step[] = VIEWS.map(viewName => ({
        kind: "refreshView",
        label: `[REFRESH] ${viewName}`,
        viewName,
    }));

    await job.run(steps);

    logger.success("✅ ACTEURS AGGREGATION REFRESHED");
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
