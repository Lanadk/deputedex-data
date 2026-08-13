import { asArray } from './utils';

describe('asArray', () => {
    it('returns an empty array for null/undefined', () => {
        expect(asArray(null)).toEqual([]);
        expect(asArray(undefined)).toEqual([]);
    });

    it('wraps a single value into an array', () => {
        expect(asArray('a')).toEqual(['a']);
        expect(asArray({ id: 1 })).toEqual([{ id: 1 }]);
    });

    it('returns the array unchanged when already an array', () => {
        expect(asArray(['a', 'b'])).toEqual(['a', 'b']);
    });

    it('returns an empty array for falsy primitives (matches implementation, not just nullish)', () => {
        expect(asArray(0 as unknown as number)).toEqual([]);
        expect(asArray('' as unknown as string)).toEqual([]);
    });
});
