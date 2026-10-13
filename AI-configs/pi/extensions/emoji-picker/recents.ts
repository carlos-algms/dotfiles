import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, isAbsolute, join } from 'node:path';

export const MAX_RECENTS = 30;

export function recentsPath(
  env: Record<string, string | undefined>,
  home: string,
): string {
  // XDG spec: a relative or empty XDG_STATE_HOME must be ignored.
  const configured = env.XDG_STATE_HOME;
  const stateHome =
    configured && isAbsolute(configured)
      ? configured
      : join(home, '.local', 'state');
  return join(stateHome, 'pi', 'emoji-picker', 'recent.json');
}

export function pushRecent(
  recents: readonly string[],
  emoji: string,
): string[] {
  return [emoji, ...recents.filter((entry) => entry !== emoji)].slice(
    0,
    MAX_RECENTS,
  );
}

export async function loadRecents(path: string): Promise<string[]> {
  try {
    const parsed: unknown = JSON.parse(await readFile(path, 'utf8'));
    return Array.isArray(parsed)
      ? parsed.filter((entry): entry is string => typeof entry === 'string')
      : [];
  } catch {
    // Missing or corrupt state is not worth failing the picker; start empty.
    return [];
  }
}

export async function recordRecent(
  path: string,
  emoji: string,
): Promise<string[]> {
  // Re-read so picks from other pi sessions are merged, not overwritten.
  const next = pushRecent(await loadRecents(path), emoji);
  await saveRecents(path, next);
  return next;
}

export async function saveRecents(
  path: string,
  recents: readonly string[],
): Promise<void> {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, JSON.stringify(recents));
}
