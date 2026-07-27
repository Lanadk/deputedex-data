import { Logger, LogLevel } from "../../../utils/logger";
import { writerPool } from "../../_common/infrastructure/db/pool";
import { main as importActeurs } from "./unit-import/importActeurs";
import { main as importScrutins } from "./unit-import/importScrutins";
import { main as importMandats } from "./unit-import/importMandats";
import { main as importAmendements } from "./unit-import/importAmendements";
import { main as importDossiers } from "./unit-import/importDossiers";
import { main as importDocuments } from "./unit-import/importDocuments";

// ==============================================================================
// IMPORT ALL JOB
// Importe toutes les données dans la DB, domaine par domaine
// Port TS de trtImportCollecte.sh
// ==============================================================================

const DOMAINS: Array<{ label: string; run: () => Promise<void> }> = [
    { label: "acteurs", run: importActeurs },
    { label: "scrutins", run: importScrutins },
    { label: "mandats", run: importMandats },
    { label: "amendements", run: importAmendements },
    { label: "dossiers", run: importDossiers },
    { label: "documents", run: importDocuments },
];

async function main(): Promise<void> {
    const logger = new Logger(LogLevel.INFO);

    if (process.argv.includes("--auto-cleanup")) {
        logger.info("ℹ️  Auto cleanup mode enabled");
    }

    logger.info("==============================================");
    logger.info("🚀 Starting ALL imports");
    logger.info("==============================================");

    for (const domain of DOMAINS) {
        logger.info("");
        logger.info("==============================================");
        logger.info(`Running ${domain.label} import`);
        logger.info("==============================================");
        await domain.run();
    }

    logger.info("");
    logger.info("==============================================");
    logger.success("🎉 All imports completed");
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
