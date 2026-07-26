import { createReadStream } from "fs";
import { createInterface } from "readline";
import { Readable } from "stream";
import { pipeline } from "stream/promises";
import { from as copyFrom } from "pg-copy-streams";
import { Pool } from "pg";
import { runSqlFile } from "./sqlRunner";

// Octets improbables dans un flux JSON UTF-8 : utilisés comme quote/delimiter
// CSV pour faire passer chaque ligne JSON telle quelle, sans avoir à échapper
// les backslashes qu'un COPY en format texte interpréterait.
const RAW_LINE_QUOTE = "\\x01";
const RAW_LINE_DELIMITER = "\\x02";

function copyFromSql(rawTable: string): string {
    return `COPY ${rawTable}(data) FROM STDIN WITH (FORMAT csv, QUOTE E'${RAW_LINE_QUOTE}', DELIMITER E'${RAW_LINE_DELIMITER}')`;
}

export interface ImportJsonLinesOptions {
    maxSizeMB?: number;
}

const DEFAULT_MAX_SIZE_MB = 125;

/**
 * Importe un fichier JSON-lines dans une table raw(data JSONB) par chunks
 * streamés via COPY, en appliquant la projection SQL et un TRUNCATE entre
 * chaque chunk. Équivalent TS de json-import-utils.sh + json-splitter.ts,
 * sans fichiers intermédiaires sur disque.
 */
export async function importJsonLinesToRaw(
    pool: Pool,
    jsonFilePath: string,
    rawTable: string,
    projectionSqlFile: string,
    options: ImportJsonLinesOptions = {}
): Promise<void> {
    const maxSizeBytes = (options.maxSizeMB ?? DEFAULT_MAX_SIZE_MB) * 1024 * 1024;
    const client = await pool.connect();

    try {
        const rl = createInterface({
            input: createReadStream(jsonFilePath, { encoding: "utf-8" }),
            crlfDelay: Infinity,
        });

        let chunk: Buffer[] = [];
        let chunkSize = 0;

        const flushChunk = async (): Promise<void> => {
            // Toujours exécuter COPY + projection, même sans ligne (fichier vide) :
            // la projection doit tourner une fois par fichier, comme dans le bash d'origine.
            await pipeline(Readable.from(chunk), client.query(copyFrom(copyFromSql(rawTable))));
            await runSqlFile(client, projectionSqlFile);
            await client.query(`TRUNCATE TABLE ${rawTable};`);

            chunk = [];
            chunkSize = 0;
        };

        for await (const line of rl) {
            if (!line.trim()) continue;
            const buf = Buffer.from(line + "\n", "utf-8");

            if (chunkSize > 0 && chunkSize + buf.byteLength > maxSizeBytes) {
                await flushChunk();
            }

            chunk.push(buf);
            chunkSize += buf.byteLength;
        }

        await flushChunk();
    } finally {
        client.release();
    }
}
