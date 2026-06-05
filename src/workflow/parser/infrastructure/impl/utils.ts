export function asArray<T>(value: T | T[] | null | undefined): T[] {
    if (!value) {
        return [];
    }

    return Array.isArray(value)
        ? value
        : [value];
}