#!/usr/bin/env ts-node

import { config } from 'dotenv';
import { resolve } from 'path';
import {existsSync} from "fs";

import {LogLevel} from "../../../../utils/logger";
import {ParserJobFactory} from "../factory/ParserJobFactory";

// Load env
const rootDir = resolve(__dirname, '../../../../..');
const envPath = resolve(rootDir, '.env.local');
if (existsSync(envPath)) config({ path: envPath });

async function main() {
    try {
        await ParserJobFactory.runByDomain('amendements', LogLevel.INFO);
    } catch (error) {
        console.error('[ERROR  ❌ ]: Job failed:', error);
        process.exit(1);
    }
}

if (require.main === module) {
    main().catch(console.error);
}

export { main };