import { Logger, LogLevel } from "../../../utils/logger";
import { writerPool } from "../../_common/infrastructure/db/pool";
import { main as aggregateActeurs } from "./acteurs/aggregation-oneshot";
import { main as aggregateGroupes } from "./groups/aggregation-oneshot";
import { main as aggregateCalendar } from "./calendar/aggregation-oneshot";
import { main as aggregateDeputes } from "./deputes/aggregation-oneshot";

// ==============================================================================
// AGGREGATION ALL - CREATE JOB (ONE SHOT)
// Création initiale de toutes les materialized views d'agrégation
// À lancer une seule fois lors du premier déploiement
// Port TS de trtAggregatCollecte-oneshot.sh
// ==============================================================================

const DOMAINS: Array<{ label: string; run: () => Promise<void> }> = [
    { label: "acteurs", run: aggregateActeurs },
    { label: "groupes", run: aggregateGroupes },
    { label: "calendar", run: aggregateCalendar },
    { label: "deputes", run: aggregateDeputes },
];

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);

    logger.info("==============================================");
    logger.info("🚀 Starting ALL aggregations ONE SHOT");
    logger.info("==============================================");

    for (const domain of DOMAINS) {
        logger.info("");
        logger.info("==============================================");
        logger.info(`Running ${domain.label} aggregation`);
        logger.info("==============================================");
        await domain.run();
    }

    logger.info("");
    logger.info("==============================================");
    logger.success("🎉 All aggregations completed");
    logger.info("==============================================");
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
