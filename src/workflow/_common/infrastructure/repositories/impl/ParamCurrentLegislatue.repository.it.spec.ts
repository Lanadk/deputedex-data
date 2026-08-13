import { ParamCurrentLegislatureRepository } from './ParamCurrentLegislatue.repository';
import { prisma } from '../../../../../../prisma/prisma';

/**
 * Integration test against the real Prisma-migrated schema (run `prisma
 * migrate deploy` + `prisma generate` first — see package.json test:integration
 * and .github/workflows/ci.yml's test-integration job).
 *
 * getCurrentLegislature()/getCurrentLegislatureNumber() read via a bare
 * findFirst() with no `where`, so the test can only assert a deterministic
 * result if `param_current_legislatures` holds exactly one row while it
 * runs. Rather than assuming a pristine DB (true in CI, not necessarily
 * true against a locally-seeded dev DB), this snapshots whatever is there,
 * replaces it with a single known fixture row for the duration of the
 * test, then restores the original rows exactly — safe to run against
 * either an empty CI DB or a populated local one.
 *
 * This file is the template for extending IT coverage to the other
 * repositories (MonitorDataDownloadRepository, ParamDataSourceRepository):
 * same snapshot/replace/restore shape, adapted to their tables.
 */
describe('ParamCurrentLegislatureRepository (integration)', () => {
    const repository = new ParamCurrentLegislatureRepository();
    const FIXTURE_LEGISLATURE_NUMBER = 999999;

    let fixtureLegislatureId: number;
    let originalCurrentRows: { legislatureId: number; number: number }[];

    beforeAll(async () => {
        originalCurrentRows = await prisma.paramCurrentLegislature.findMany({
            select: { legislatureId: true, number: true },
        });

        // Additive-only: create a brand new legislature row rather than
        // reusing/touching any existing one.
        const fixtureLegislature = await prisma.paramLegislature.create({
            data: { number: FIXTURE_LEGISLATURE_NUMBER },
        });
        fixtureLegislatureId = fixtureLegislature.id;

        await prisma.paramCurrentLegislature.deleteMany({});
        await prisma.paramCurrentLegislature.create({
            data: { legislatureId: fixtureLegislatureId, number: FIXTURE_LEGISLATURE_NUMBER },
        });
    });

    afterAll(async () => {
        await prisma.paramCurrentLegislature.deleteMany({});
        await prisma.paramLegislature.delete({ where: { id: fixtureLegislatureId } });

        for (const row of originalCurrentRows) {
            await prisma.paramCurrentLegislature.create({ data: row });
        }

        await prisma.$disconnect();
    });

    it('getCurrentLegislature returns the sole current row with its legislature relation', async () => {
        const current = await repository.getCurrentLegislature();

        expect(current).not.toBeNull();
        expect(current!.number).toBe(FIXTURE_LEGISLATURE_NUMBER);
        expect(current!.legislature.id).toBe(fixtureLegislatureId);
        expect(current!.legislature.number).toBe(FIXTURE_LEGISLATURE_NUMBER);
    });

    it('getCurrentLegislatureNumber returns just the number', async () => {
        await expect(repository.getCurrentLegislatureNumber()).resolves.toBe(FIXTURE_LEGISLATURE_NUMBER);
    });

    it('isCurrentLegislature compares against the stored current number', async () => {
        await expect(repository.isCurrentLegislature(FIXTURE_LEGISLATURE_NUMBER)).resolves.toBe(true);
        await expect(repository.isCurrentLegislature(FIXTURE_LEGISLATURE_NUMBER - 1)).resolves.toBe(false);
    });
});
