import * as path from "path";
import { Logger, LogLevel } from "../../../../utils/logger";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// ACTEURS AGGREGATION - CREATE JOB (ONE SHOT)
// Crée les materialized views d'agrégation des acteurs (CREATE ... IF NOT EXISTS,
// vues + index). Idempotent : peut être rejoué sans risque (ex. à chaque déploiement),
// les vues déjà existantes sont ignorées. Ne modifie PAS la définition d'une vue déjà
// créée si le .sql a changé depuis — pour ça il faut un DROP + recréation manuelle.
// Port TS de acteurs/aggregation-oneshot.sh
// ==============================================================================

const repoRoot = path.resolve(__dirname, "../../../../..");
const scriptsDir = path.join(repoRoot, "src", "sql", "scripts", "acteurs", "aggregations");

// Exportée pour être réutilisée par le registre de recreateView.ts (DROP +
// recréation à la demande d'une vue déjà créée) — ne pas dupliquer ailleurs.
export const VIEWS = [
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
    logger.info("  ACTEURS AGGREGATION - CREATE (ONE SHOT)");
    logger.info("==============================================");

    const steps: Step[] = VIEWS.map(viewName => ({
        kind: "createView",
        label: `[CREATE] ${viewName}`,
        viewName,
        path: path.join(scriptsDir, `${viewName}.sql`),
    }));

    await job.run(steps);

    logger.success("✅ ACTEURS AGGREGATION CREATED (idempotent, rejouable sans risque)");
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
