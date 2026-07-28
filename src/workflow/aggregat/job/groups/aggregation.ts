import { Logger, LogLevel } from "../../../../utils/logger";
import { writerPool } from "../../../_common/infrastructure/db/pool";
import { PipelineJob, Step } from "../../../_common/job/PipelineJob";

// ==============================================================================
// GROUPES / ASSEMBLEE AGGREGATION - REFRESH JOB
// Rafraîchit les materialized views d'agrégation des groupes parlementaires
// Port TS de groups/aggregation.sh
// ==============================================================================

const VIEWS = [
    "agg_groupes_effectifs_current",
    "agg_groupes_effectifs_legislature",
    "agg_groupes_stats_cohesion_mensuelle",
    "agg_groupes_stats_cohesion_legislature",
    "agg_groupes_stats_couverture_scrutins",
    "agg_groupes_stats_participation_legislature",
    "agg_groupes_stats_participation_mensuelle",
    "agg_groupes_stats_expression_votes",
    "agg_groupes_stats_votes_positions_politiques",
    "agg_groupes_stats_votes_positions_comptables",
    "agg_groupes_stats_demographie_legislature",
    "agg_groupes_stats_stabilite",
    "agg_groupes_stats_proximite_votes_legislature",
    "agg_groupes_stats_proximite_votes_mensuelle",
    "agg_groupes_stats_professions",
    "agg_groupes_stats_professions_categories",
    "agg_groupes_stats_professions_familles",
    "mv_groupes_presidents",
    "agg_groupes_fiche_infos",
    "agg_groupes_stats_age",
    "agg_groupes_stats_parite",
    "agg_groupes_stats_cumul_mandats",
    "agg_groupes_stats_geographie_election",
    "agg_groupes_stats_geographie_dep_naissance",
    "agg_groupes_stats_geographie_pays_naissance",
    "agg_groupes_stats_tranche_age",
    "agg_assemblee_stats_participation_legislature",
    "mv_assemblee_presidents",
];

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const job = new PipelineJob(writerPool, logger);

    logger.info("==============================================");
    logger.info("  GROUPES AGGREGATION REFRESH JOB");
    logger.info("==============================================");

    const steps: Step[] = VIEWS.map(viewName => ({
        kind: "refreshView",
        label: `[REFRESH] ${viewName}`,
        viewName,
    }));

    await job.run(steps);

    logger.success("✅ GROUPES AGGREGATION REFRESHED");
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
