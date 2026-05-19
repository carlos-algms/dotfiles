import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';
import { asObject } from './http.ts';
import type { BackendName } from './types.ts';

const USAGE_PATH = join(xdgStateHome(), 'fallback-web-research', 'usage.json');

export interface BackendQuota {
  dailyCap?: number;
  monthlyCap?: number;
  perMinuteCap?: number;
}

export const QUOTAS: Record<BackendName, BackendQuota> = {
  langsearch: { dailyCap: 1000, perMinuteCap: 60 },
  tavily: { monthlyCap: 500, perMinuteCap: 100 },
  exa: { monthlyCap: 1000, perMinuteCap: 600 },
  brave: { monthlyCap: 1000, perMinuteCap: 60 },
  marginalia: { perMinuteCap: 60 },
};

interface PersistedEntry {
  day: string;
  monthKey: string;
  today: number;
  month: number;
}

type PersistedShape = Partial<Record<BackendName, PersistedEntry>>;

const minuteWindow = new Map<BackendName, number[]>();
// Serialize commits per backend so parallel runs don't lose increments via
// read-modify-write race on the shared usage file.
const commitChain = new Map<BackendName, Promise<unknown>>();

function xdgStateHome(): string {
  return process.env.XDG_STATE_HOME || join(homedir(), '.local', 'state');
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

function monthKey(): string {
  return new Date().toISOString().slice(0, 7);
}

function freshEntry(): PersistedEntry {
  return { day: today(), monthKey: monthKey(), today: 0, month: 0 };
}

function readEntry(raw: unknown): PersistedEntry {
  const obj = asObject(raw);
  const day = typeof obj.day === 'string' ? obj.day : '';
  const month = typeof obj.monthKey === 'string' ? obj.monthKey : '';
  const todayCount = typeof obj.today === 'number' ? obj.today : 0;
  const monthCount = typeof obj.month === 'number' ? obj.month : 0;
  return {
    day,
    monthKey: month,
    today: day === today() ? todayCount : 0,
    month: month === monthKey() ? monthCount : 0,
  };
}

async function loadPersisted(): Promise<PersistedShape> {
  try {
    const raw = await readFile(USAGE_PATH, 'utf8');
    const root = asObject(JSON.parse(raw));
    const out: PersistedShape = {};
    for (const name of Object.keys(QUOTAS) as BackendName[]) {
      out[name] = readEntry(root[name]);
    }
    return out;
  } catch {
    return {};
  }
}

async function writePersisted(shape: PersistedShape): Promise<void> {
  await mkdir(dirname(USAGE_PATH), { recursive: true });
  await writeFile(USAGE_PATH, JSON.stringify(shape, null, 2), 'utf8');
}

function pruneMinute(window: number[], nowMs: number): number[] {
  const cutoff = nowMs - 60_000;
  return window.filter((t) => t > cutoff);
}

export interface UsageGate {
  ok: true;
  commit: () => Promise<void>;
}

export interface UsageBlock {
  ok: false;
  reason: 'daily' | 'monthly' | 'rate';
  message: string;
}

export async function reserve(
  backend: BackendName,
): Promise<UsageGate | UsageBlock> {
  const quota = QUOTAS[backend];
  const persisted = await loadPersisted();
  const entry = persisted[backend] ?? freshEntry();

  if (quota.dailyCap != null && entry.today >= quota.dailyCap) {
    return {
      ok: false,
      reason: 'daily',
      message: `${backend} daily cap reached (${entry.today}/${quota.dailyCap})`,
    };
  }
  if (quota.monthlyCap != null && entry.month >= quota.monthlyCap) {
    return {
      ok: false,
      reason: 'monthly',
      message: `${backend} monthly cap reached (${entry.month}/${quota.monthlyCap})`,
    };
  }

  const pruned = pruneMinute(minuteWindow.get(backend) ?? [], Date.now());
  if (quota.perMinuteCap != null && pruned.length >= quota.perMinuteCap) {
    minuteWindow.set(backend, pruned);
    return {
      ok: false,
      reason: 'rate',
      message: `${backend} per-minute cap reached (${pruned.length}/${quota.perMinuteCap})`,
    };
  }

  return { ok: true, commit: () => commit(backend) };
}

async function commit(backend: BackendName): Promise<void> {
  const prev = commitChain.get(backend) ?? Promise.resolve();
  const next = prev.then(() => writeCommit(backend));
  commitChain.set(
    backend,
    next.catch(() => {}),
  );
  await next;
}

async function writeCommit(backend: BackendName): Promise<void> {
  const fresh = await loadPersisted();
  const current = fresh[backend] ?? freshEntry();
  fresh[backend] = {
    day: today(),
    monthKey: monthKey(),
    today: current.today + 1,
    month: current.month + 1,
  };
  await writePersisted(fresh);

  const now = Date.now();
  const window = pruneMinute(minuteWindow.get(backend) ?? [], now);
  window.push(now);
  minuteWindow.set(backend, window);
}
