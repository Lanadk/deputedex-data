/** @type {import('jest').Config} */
module.exports = {
    // The Prisma driver adapter used by IT tests wraps a manually-created pg
    // Pool (see prisma/prisma.ts) whose lifecycle prisma.$disconnect()
    // doesn't fully own, which otherwise leaves the process hanging after a
    // successful run against real Postgres. Harmless for the unit project,
    // which has no open handles to force-close in the first place.
    forceExit: true,
    projects: [
        {
            displayName: 'unit',
            preset: 'ts-jest',
            testEnvironment: 'node',
            rootDir: __dirname,
            testMatch: ['<rootDir>/src/**/*.spec.ts', '<rootDir>/local/**/*.spec.ts', '<rootDir>/prisma/**/*.spec.ts'],
            testPathIgnorePatterns: ['/node_modules/', '\\.it\\.spec\\.ts$'],
        },
        {
            displayName: 'integration',
            preset: 'ts-jest',
            testEnvironment: 'node',
            rootDir: __dirname,
            testMatch: ['<rootDir>/src/**/*.it.spec.ts', '<rootDir>/prisma/**/*.it.spec.ts'],
            testPathIgnorePatterns: ['/node_modules/'],
        },
    ],
};
