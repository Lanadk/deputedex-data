import * as path from "path";
import { Logger, LogLevel } from "../../../../utils/logger";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// CALENDAR ACTIVITY AGGREGATION - CREATE JOB (ONE SHOT)
// Création initiale des materialized views d'agrégation des activités
// À lancer une seule fois lors du premier déploiement
// Port TS de calendar/aggregation-oneshot.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../../..");
const scriptsDir = path.join(repoRoot, "src", "sql", "scripts", "calendar", "aggregations");

const VIEWS = ["agg_activity_calendar_mv", "agg_activity_calendar_details_mv"];

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);

    logger.info("==============================================");
    logger.info("  CALENDAR ACTIVITY AGGREGATION - CREATE (ONE SHOT)");
    logger.info("==============================================");

    const steps: Step[] = VIEWS.map(viewName => ({
        kind: "createView",
        label: `[CREATE] ${viewName}`,
        viewName,
        path: path.join(scriptsDir, `${viewName}.sql`),
    }));

    await job.run(steps);

    logger.success("✅ CALENDAR ACTIVITY AGGREGATION CREATED");
    logger.warn("⚠️  NE PAS RELANCER CE JOB");
    logger.info("👉 Pour mettre à jour : aggregation.ts");
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
