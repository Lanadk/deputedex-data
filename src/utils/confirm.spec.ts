import * as readline from 'readline';
import { confirm } from './confirm';

jest.mock('readline');

describe('confirm', () => {
    afterEach(() => {
        jest.resetAllMocks();
    });

    function mockAnswer(answer: string) {
        const close = jest.fn();
        const question = jest.fn((_q: string, cb: (a: string) => void) => cb(answer));
        (readline.createInterface as jest.Mock).mockReturnValue({ question, close });
        return { question, close };
    }

    it.each(['y', 'Y'])('resolves true for a "%s" answer', async answer => {
        mockAnswer(answer);
        await expect(confirm('Continue?')).resolves.toBe(true);
    });

    it.each(['n', 'no', '', 'yes', 'maybe'])('resolves false for a "%s" answer', async answer => {
        mockAnswer(answer);
        await expect(confirm('Continue?')).resolves.toBe(false);
    });

    it('trims whitespace before matching the answer', async () => {
        mockAnswer('  y  ');
        await expect(confirm('Continue?')).resolves.toBe(true);
    });

    it('closes the readline interface after answering', async () => {
        const { close } = mockAnswer('y');
        await confirm('Continue?');
        expect(close).toHaveBeenCalledTimes(1);
    });
});
