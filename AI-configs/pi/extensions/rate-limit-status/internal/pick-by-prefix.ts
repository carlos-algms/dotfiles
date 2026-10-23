import type { HeaderMap } from './types.ts';

/** HTTP header names are case-insensitive; lowercase, then keep one prefix. */
export function pickByPrefix(raw: HeaderMap, prefix: string): HeaderMap {
  return Object.fromEntries(
    Object.entries(raw)
      .map(([key, value]) => [key.toLowerCase(), value] as const)
      .filter(([key]) => key.startsWith(prefix)),
  );
}
