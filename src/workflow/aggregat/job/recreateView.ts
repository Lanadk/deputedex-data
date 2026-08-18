import { Logger, LogLevel } from "../../../utils/logger";
import { writerPool } from "../../_common/infrastructure/db/pool";
import { runSqlFile } from "../../_common/infrastructure/db/sqlRunner";
import { VIEW_REGISTRY } from "../registry";

// ==============================================================================
// RECREATE VIEW(S) — DROP + CREATE À LA DEMANDE
// ==============================================================================
// aggregation-oneshot.ts (CREATE ... IF NOT EXISTS) ignore silencieusement une
// vue déjà créée, et aggregation.ts (REFRESH) ne fait que rejouer les données de
// la définition EXISTANTE : ni l'un ni l'autre ne propage un changement de
// définition SQL sur une vue déjà en prod. Voir aggregat/repo.md > "⚠️ Attention".
// Ce job fait le DROP + recréation manuelle documentée là-bas, pour une ou
// plusieurs vues nommées explicitement.
//
// ⚠️ DESTRUCTIF : DROP ... CASCADE peut emporter d'autres objets qui dépendent
// de la vue (une autre vue matérialisée, un index...). Sans --yes, le job liste
// ce qu'il ferait et s'arrête (dry-run) — il faut relancer avec --yes pour
// confirmer.
//
// Usage : npx ts-node src/workflow/aggregat/job/recreateView.ts <vue> [<vue> ...] --yes
// ==============================================================================

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);
    const args = process.argv.slice(2);
    const confirmed = args.includes("--yes");
    const viewNames = args.filter(arg => arg !== "--yes");

    if (viewNames.length === 0) {
        logger.error("Usage: recreateView.ts <viewName> [<viewName> ...] --yes");
        logger.info(`Vues connues : ${Object.keys(VIEW_REGISTRY).sort().join(", ")}`);
        process.exitCode = 1;
        return;
    }

    const unknown = viewNames.filter(viewName => !VIEW_REGISTRY[viewName]);
    if (unknown.length > 0) {
        logger.error(`Vue(s) inconnue(s) du registre : ${unknown.join(", ")}`);
        logger.info(`Vues connues : ${Object.keys(VIEW_REGISTRY).sort().join(", ")}`);
        process.exitCode = 1;
        return;
    }

    logger.info("==============================================");
    logger.info("⚠️  RECREATE VIEW(S) — DROP CASCADE + CREATE");
    logger.info("==============================================");
    viewNames.forEach(viewName => logger.info(`  - ${viewName} (domaine: ${VIEW_REGISTRY[viewName].domain})`));

    if (!confirmed) {
        logger.warn("Dry-run (pas de --yes) : aucune action effectuée. Relancer avec --yes pour confirmer le DROP.");
        return;
    }

    for (const viewName of viewNames) {
        const { sqlPath } = VIEW_REGISTRY[viewName];

        logger.info(`▶ DROP MATERIALIZED VIEW IF EXISTS ${viewName} CASCADE...`);
        await writerPool.query(`DROP MATERIALIZED VIEW IF EXISTS ${viewName} CASCADE;`);

        logger.info(`▶ Recreating ${viewName} from ${sqlPath}...`);
        await runSqlFile(writerPool, sqlPath);

        logger.success(`✓ ${viewName} recreated`);
    }

    logger.info("==============================================");
    logger.success("🎉 Recreate completed");
    logger.info("👉 Le prochain passage du refresh (aggregation.ts / cron) rafraîchira ses données normalement.");
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
