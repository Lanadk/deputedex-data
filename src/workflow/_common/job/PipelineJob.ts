import { Pool } from "pg";
import { Logger } from "../../../utils/logger";
import { runSqlFile, refreshMaterializedView } from "../infrastructure/db/sqlRunner";
import { importJsonLinesToRaw } from "../infrastructure/db/copyJsonLinesToRaw";

export type Step =
    | { kind: "sqlFile"; label: string; path: string }
    | { kind: "createView"; label: string; viewName: string; path: string }
    | { kind: "refreshView"; label: string; viewName: string }
    | {
          kind: "importRaw";
          label: string;
          jsonFile: string;
          rawTable: string;
          projectionSqlFile: string;
          maxSizeMB?: number;
      };

/**
 * Job générique piloté par une liste de steps déclaratifs, sur le même moule
 * que DownloadJob/ParserJob.
 */
export class PipelineJob {
    constructor(
        private pool: Pool,
        private logger: Logger
    ) {}

    async run(steps: Step[]): Promise<void> {
        this.logger.info("======== Starting Pipeline Job ========");

        for (const step of steps) {
            this.logger.info(`▶ ${step.label}...`);
            await this.runStep(step);
            this.logger.success(`✓ ${step.label} done`);
        }

        this.logger.info("=".repeat(25));
        this.logger.success(`🎉 Pipeline completed (${steps.length} steps)`);
        this.logger.info("=".repeat(25));
    }

    private async runStep(step: Step): Promise<void> {
        switch (step.kind) {
            case "sqlFile":
            case "createView": {
                const result = await runSqlFile(this.pool, step.path);
                if (result.rows.length > 0) {
                    console.table(result.rows);
                }
                return;
            }
            case "refreshView":
                await refreshMaterializedView(this.pool, step.viewName);
                return;
            case "importRaw":
                await importJsonLinesToRaw(this.pool, step.jsonFile, step.rawTable, step.projectionSqlFile, {
                    maxSizeMB: step.maxSizeMB,
                });
                return;
        }
    }
}
