import { Logger, LogLevel } from "../../../utils/logger";
import { writerPool } from "../../_common/infrastructure/db/pool";
import { main as aggregateActeurs } from "./acteurs/aggregation";
import { main as aggregateGroupes } from "./groups/aggregation";
import { main as aggregateCalendar } from "./calendar/aggregation";
import { main as aggregateDeputes } from "./deputes/aggregation";

// ==============================================================================
// AGGREGATION ALL - REFRESH JOB
// Rafraîchit toutes les materialized views d'agrégation, domaine par domaine
// Port TS de trtAggregatCollecte.sh
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
    logger.info("🚀 Starting ALL aggregations");
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
