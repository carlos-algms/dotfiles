import { readFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { asObject, asString } from './http';
import type { BackendName } from './types';

const DEFAULT_AUTH_PATH = join(
  homedir(),
  'OneDrive',
  'work',
  'mac-pro',
  'dotfiles',
  'web-search-auth.json',
);

const ENV_OVERRIDE = 'WEB_SEARCH_AUTH_PATH';

export interface AuthConfig {
  langsearch: { apiKey: string };
  tavily: { apiKey: string };
  exa: { apiKey: string };
  brave: { apiKey: string };
  marginalia: { apiKey: string };
}

let cached: AuthConfig | null = null;

export async function loadAuth(): Promise<AuthConfig> {
  if (cached) {
    return cached;
  }

  const path = process.env[ENV_OVERRIDE] ?? DEFAULT_AUTH_PATH;
  let raw: string;
  try {
    raw = await readFile(path, 'utf8');
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(
      `web-search auth file not found at ${path}: ${message}. ` +
        `Create it with shape {"langsearch":{"apiKey":""}, ...} or set ${ENV_OVERRIDE}.`,
    );
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    throw new Error(`web-search auth file at ${path} is not valid JSON: ${message}`);
  }

  const root = asObject(parsed);
  cached = {
    langsearch: { apiKey: asString(asObject(root.langsearch).apiKey) },
    tavily: { apiKey: asString(asObject(root.tavily).apiKey) },
    exa: { apiKey: asString(asObject(root.exa).apiKey) },
    brave: { apiKey: asString(asObject(root.brave).apiKey) },
    marginalia: { apiKey: asString(asObject(root.marginalia).apiKey, 'public') },
  };
  return cached;
}

export function keyFor(auth: AuthConfig, backend: BackendName): string {
  return auth[backend].apiKey;
}
