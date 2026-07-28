import { readFileSync } from "fs";
import { Pool, PoolClient, QueryResult } from "pg";

export type SqlExecutor = Pool | PoolClient;

export async function runSqlFile(executor: SqlExecutor, filePath: string): Promise<QueryResult> {
    const sql = readFileSync(filePath, "utf-8");
    const result = await executor.query(sql);
    // Un fichier à plusieurs statements résout en tableau de QueryResult (un par
    // statement) plutôt qu'un seul objet : on ne garde que le dernier, celui
    // susceptible de porter les lignes d'un éventuel SELECT final (verify).
    return Array.isArray(result) ? result[result.length - 1] : result;
}

export async function refreshMaterializedView(executor: SqlExecutor, viewName: string): Promise<void> {
    await executor.query(`REFRESH MATERIALIZED VIEW CONCURRENTLY ${viewName};`);
}
