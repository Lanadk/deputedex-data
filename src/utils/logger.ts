export enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}

export class Logger {
    constructor(private level: LogLevel = LogLevel.INFO) {}

    debug(message: string, ...args: any[]) {
        if (this.level <= LogLevel.DEBUG) console.log(`[DEBUG  🔍]: ${message}`, ...args);
    }

    info(message: string, ...args: any[]) {
        if (this.level <= LogLevel.INFO) console.log(`[INFO   ℹ️]: ${message}`, ...args);
    }

    success(message: string, ...args: any[]) {
        if (this.level <= LogLevel.INFO) console.log(`[SUCCESS ✅]: ${message}`, ...args);
    }

    warn(message: string, ...args: any[]) {
        if (this.level <= LogLevel.WARN) console.warn(`[WARN   ⚠️]: ${message}`, ...args);
    }

    error(message: string, ...args: any[]) {
        if (this.level <= LogLevel.ERROR) console.error(`[ERROR   ❌]: ${message}`, ...args);
    }
}