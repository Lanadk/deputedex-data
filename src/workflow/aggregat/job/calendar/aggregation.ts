import { Logger, LogLevel } from "../../../../utils/logger";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// CALENDAR ACTIVITY AGGREGATION - REFRESH JOB
// Rafraîchit les materialized views d'agrégation des calendriers d'activités
// Port TS de calendar/aggregation.sh
// ==============================================================================

const VIEWS = ["agg_activity_calendar_mv", "agg_activity_calendar_details_mv"];

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);

    logger.info("==============================================");
    logger.info("  CALENDAR ACTIVITY AGGREGATION REFRESH JOB");
    logger.info("==============================================");

    const steps: Step[] = VIEWS.map(viewName => ({
        kind: "refreshView",
        label: `[REFRESH] ${viewName}`,
        viewName,
    }));

    await job.run(steps);

    logger.success("✅ CALENDAR ACTIVITY AGGREGATION REFRESHED");
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
