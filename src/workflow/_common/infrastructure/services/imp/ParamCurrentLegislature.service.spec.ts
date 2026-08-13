// The real repository impl statically imports the Prisma client singleton,
// which throws at import time if DB_URL isn't configured. These are pure
// unit tests driven entirely through a mocked repository, so stub the
// prisma module out to keep them DB-free and fast.
jest.mock('../../../../../../prisma/prisma', () => ({ prisma: {} }));

import { ParamCurrentLegislatureService } from './ParamCurrentLegislature.service';
import {
    CurrentLegislatureWithRelation,
    IParamCurrentLegislatureRepository,
} from '../../repositories/IParamCurrentLegislature.repository';

function createMockRepository(): jest.Mocked<IParamCurrentLegislatureRepository> {
    return {
        getCurrentLegislature: jest.fn(),
        getCurrentLegislatureNumber: jest.fn(),
        isCurrentLegislature: jest.fn(),
    };
}

function makeCurrent(number: number): CurrentLegislatureWithRelation {
    return {
        legislatureId: 1,
        number,
        updatedAt: new Date('2024-01-01'),
        legislature: {
            id: 1,
            number,
            startDate: new Date('2024-07-08'),
            endDate: null,
            createdAt: new Date('2024-01-01'),
            updatedAt: new Date('2024-01-01'),
        },
    };
}

describe('ParamCurrentLegislatureService', () => {
    it('delegates getCurrentLegislature to the repository', async () => {
        const repository = createMockRepository();
        const current = makeCurrent(17);
        repository.getCurrentLegislature.mockResolvedValue(current);
        const service = new ParamCurrentLegislatureService(repository);

        await expect(service.getCurrentLegislature()).resolves.toBe(current);
    });

    it('delegates getCurrentLegislatureNumber to the repository', async () => {
        const repository = createMockRepository();
        repository.getCurrentLegislatureNumber.mockResolvedValue(17);
        const service = new ParamCurrentLegislatureService(repository);

        await expect(service.getCurrentLegislatureNumber()).resolves.toBe(17);
    });

    it('delegates isCurrentLegislature to the repository', async () => {
        const repository = createMockRepository();
        repository.isCurrentLegislature.mockResolvedValue(true);
        const service = new ParamCurrentLegislatureService(repository);

        await expect(service.isCurrentLegislature(17)).resolves.toBe(true);
        expect(repository.isCurrentLegislature).toHaveBeenCalledWith(17);
    });

    it('isArchiveLegislature is the negation of isCurrentLegislature', async () => {
        const repository = createMockRepository();
        repository.isCurrentLegislature.mockResolvedValue(true);
        const service = new ParamCurrentLegislatureService(repository);

        await expect(service.isArchiveLegislature(16)).resolves.toBe(false);

        repository.isCurrentLegislature.mockResolvedValue(false);
        await expect(service.isArchiveLegislature(15)).resolves.toBe(true);
    });
});
