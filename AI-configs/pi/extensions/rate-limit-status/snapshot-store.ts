import {
  mkdirSync,
  readFileSync,
  renameSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

type Headers = Record<string, string>;

const HEADER_PREFIX = 'anthropic-ratelimit-unified-';
const STORE_PATH = join(homedir(), '.pi', 'rate-limits.json');

function pickUnifiedHeaders(raw: Headers): Headers {
  return Object.fromEntries(
    Object.entries(raw)
      .map(([key, value]) => [key.toLowerCase(), value] as const)
      .filter(([key]) => key.startsWith(HEADER_PREFIX)),
  );
}

/**
 * Shares the latest Anthropic snapshot across pi processes and subagent
 * children. Atomic rename: readers never see a partial file, and the last
 * writer wins (the data is account-wide). Best effort: errors are ignored.
 */
export function writeSnapshot(raw: Headers): void {
  const headers = pickUnifiedHeaders(raw);
  if (Object.keys(headers).length === 0) {
    return;
  }
  const tmpPath = `${STORE_PATH}.${process.pid}.tmp`;
  try {
    mkdirSync(dirname(STORE_PATH), { recursive: true });
    writeFileSync(tmpPath, JSON.stringify(headers));
    renameSync(tmpPath, STORE_PATH);
  } catch {
    // shortcut: footer simply stays stale if the write fails
  }
}

/** Returns undefined when missing, unreadable, or every window has reset. */
export function readSnapshot(): Headers | undefined {
  let headers: Headers;
  try {
    headers = JSON.parse(readFileSync(STORE_PATH, 'utf8')) as Headers;
  } catch {
    return undefined;
  }
  const resets = (['5h', '7d'] as const)
    .map((label) => Number(headers[`${HEADER_PREFIX}${label}-reset`]))
    .filter((reset) => Number.isFinite(reset));
  if (!resets.some((reset) => reset * 1000 > Date.now())) {
    return undefined;
  }
  return headers;
}

export function getSnapshotMtimeMs(): number {
  try {
    return statSync(STORE_PATH).mtimeMs;
  } catch {
    return 0;
  }
}
