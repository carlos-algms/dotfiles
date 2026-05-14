import { spawn } from 'node:child_process';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { SearchResult } from './types';

const HERE = dirname(fileURLToPath(import.meta.url));
const PROMPT_PATH = join(HERE, 'ai-summary-prompt.md');
const SYSTEM_PROMPT = readFileSync(PROMPT_PATH, 'utf8');

const PI_BIN = 'pi';
const MODEL = 'claude-haiku-4-5';
const PROVIDER = 'anthropic';
const TIMEOUT_MS = 60_000;

function serializeResults(query: string, results: SearchResult[]): string {
  const blocks = results.map((r) => {
    const provider = r.sources.join(', ');
    const title = r.title || r.url;
    const body = r.snippet?.trim() || '(no body)';
    return [
      `## ${title}`,
      `- URL: ${r.url}`,
      `- provider: ${provider}`,
      '',
      body,
    ].join('\n');
  });
  return [
    `# Query`,
    '',
    query,
    '',
    `# Raw results`,
    '',
    blocks.join('\n\n========\n\n'),
  ].join('\n');
}

export async function summarizeResults(
  query: string,
  results: SearchResult[],
  signal: AbortSignal,
): Promise<string | null> {
  if (results.length === 0) {
    return null;
  }

  const payload = serializeResults(query, results);
  const tmp = mkdtempSync(join(tmpdir(), 'web-search-ai-'));
  const payloadPath = join(tmp, 'results.md');
  writeFileSync(payloadPath, payload, 'utf8');

  try {
    const stdout = await runPi(
      [
        '--print',
        '--provider',
        PROVIDER,
        '--model',
        MODEL,
        '--no-tools',
        '--no-extensions',
        '--no-session',
        '--no-skills',
        '--thinking',
        'off',
        '--system-prompt',
        SYSTEM_PROMPT,
        `@${payloadPath}`,
      ],
      signal,
    );
    return stdout.trim() || null;
  } catch {
    return null;
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
}

function runPi(args: string[], signal: AbortSignal): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(PI_BIN, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    const timer = setTimeout(() => {
      child.kill('SIGTERM');
      reject(new Error(`ai-summary timeout after ${TIMEOUT_MS}ms`));
    }, TIMEOUT_MS);
    const onAbort = (): void => {
      child.kill('SIGTERM');
      reject(new Error('ai-summary aborted'));
    };
    if (signal.aborted) {
      onAbort();
      return;
    }
    signal.addEventListener('abort', onAbort, { once: true });
    child.stdout.on('data', (chunk: Buffer) => {
      stdout += chunk.toString('utf8');
    });
    child.stderr.on('data', (chunk: Buffer) => {
      stderr += chunk.toString('utf8');
    });
    child.on('error', (err) => {
      clearTimeout(timer);
      signal.removeEventListener('abort', onAbort);
      reject(err);
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      signal.removeEventListener('abort', onAbort);
      if (code === 0) {
        resolve(stdout);
      } else {
        reject(new Error(`pi exited ${code}: ${stderr.slice(0, 400)}`));
      }
    });
  });
}
