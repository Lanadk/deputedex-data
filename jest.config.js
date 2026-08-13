/** @type {import('jest').Config} */
module.exports = {
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
