import { mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';
import type { HeaderMap, Snapshot } from './types.ts';

type Store = Record<string, Snapshot>;

/** Lazy: re-reads `HOME` per call so tests can isolate the store path. */
function storePath(): string {
  return join(homedir(), '.pi', 'rate-limits.json');
}

function isSnapshot(value: unknown): value is Snapshot {
  return (
    typeof value === 'object' &&
    value !== null &&
    'at' in value &&
    typeof value.at === 'number' &&
    'headers' in value &&
    typeof value.headers === 'object' &&
    value.headers !== null
  );
}

/** Unreadable, corrupt, or legacy-shaped content yields `{}` / is dropped. */
function readStore(): Store {
  try {
    const parsed: unknown = JSON.parse(readFileSync(storePath(), 'utf8'));
    if (
      typeof parsed !== 'object' ||
      parsed === null ||
      Array.isArray(parsed)
    ) {
      return {};
    }
    return Object.fromEntries(
      Object.entries(parsed).filter(([, value]) => isSnapshot(value)),
    );
  } catch {
    return {};
  }
}

/**
 * Shares the latest snapshot across pi processes and subagent children, keyed
 * by provider id. Atomic rename: readers never see a partial file. Read-modify-
 * write is unlocked, so two simultaneous writers can drop one provider's
 * update; the next response rewrites it. Best effort: errors are ignored so the
 * footer simply stays stale. Returns the snapshot for immediate rendering.
 */
export function writeSnapshot(provider: string, headers: HeaderMap): Snapshot {
  const snapshot = { at: Date.now(), headers } satisfies Snapshot;
  const path = storePath();
  const tmpPath = `${path}.${process.pid}.tmp`;
  try {
    const store = readStore();
    store[provider] = snapshot;
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(tmpPath, JSON.stringify(store));
    renameSync(tmpPath, path);
  } catch {
    // footer simply stays stale if the write fails
  }
  return snapshot;
}

export function readSnapshot(provider: string): Snapshot | undefined {
  return readStore()[provider];
}
