import * as path from "path";
import { Logger, LogLevel } from "../../../../utils/logger";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// CALENDAR ACTIVITY AGGREGATION - CREATE JOB (ONE SHOT)
// Crée les materialized views d'agrégation des activités (CREATE ... IF NOT EXISTS,
// vues + index). Idempotent : peut être rejoué sans risque (ex. à chaque déploiement),
// les vues déjà existantes sont ignorées. Ne modifie PAS la définition d'une vue déjà
// créée si le .sql a changé depuis — pour ça il faut un DROP + recréation manuelle.
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

    logger.success("✅ CALENDAR ACTIVITY AGGREGATION CREATED (idempotent, rejouable sans risque)");
    logger.info("👉 Pour rafraîchir les données d'une vue déjà créée : aggregation.ts");
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
