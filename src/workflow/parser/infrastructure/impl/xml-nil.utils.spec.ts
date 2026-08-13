import { extractNilableValue } from './xml-nil.utils';

describe('extractNilableValue', () => {
    it('returns null for null/undefined input', () => {
        expect(extractNilableValue(null)).toBeNull();
        expect(extractNilableValue(undefined)).toBeNull();
    });

    it('returns null for the AN xsi:nil marker object', () => {
        expect(
            extractNilableValue({
                '@xsi:nil': 'true',
                '@xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
            })
        ).toBeNull();
    });

    it('returns the plain string when given a raw string', () => {
        expect(extractNilableValue('hello')).toBe('hello');
    });

    it('extracts the #text field from a wrapped value object', () => {
        expect(extractNilableValue({ '#text': 'wrapped value' })).toBe('wrapped value');
    });

    it('returns null when the object has neither #text nor xsi:nil', () => {
        expect(extractNilableValue({ '@xsi:type': 'Something' })).toBeNull();
    });
});
