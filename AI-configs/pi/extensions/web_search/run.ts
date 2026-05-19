#!/usr/bin/env node

import { parseArgs } from 'node:util';
import { summarizeResults } from './ai-summary.ts';
import { formatFooter, formatResults } from './format.ts';
import { orchestrate } from './orchestrator.ts';
import { BACKEND_NAMES, isBackendName } from './types.ts';
import type { BackendName } from './types.ts';

const DEFAULT_TIMEOUT_MS = 30_000;
const DEFAULT_NUM_RESULTS = 10;
const MIN_TIMEOUT_MS = 1_000;
const MAX_TIMEOUT_MS = 300_000;
const MIN_NUM_RESULTS = 1;
const MAX_NUM_RESULTS = 20;

try {
  await runCli(process.argv.slice(2));
} catch (err) {
  const message = err instanceof Error ? err.message : String(err);
  console.error(message);
  process.exitCode = 1;
}

async function runCli(args: string[]): Promise<void> {
  if (args.includes('--help') || args.includes('-h')) {
    console.log(usage());
    return;
  }

  const parsed = parseCliArgs(args);
  const timeoutSignal = AbortSignal.timeout(parsed.timeoutMs);
  const startedAt = Date.now();
  const outcome = await orchestrate({
    query: parsed.query,
    numResults: parsed.numResults,
    provider: parsed.provider,
    signal: timeoutSignal,
  });
  const aiBody = await summarizeResults(
    parsed.query,
    outcome.results,
    timeoutSignal,
  );
  const body = aiBody ?? formatResults(outcome.results);
  const durationMs = Date.now() - startedAt;
  const footer = formatFooter(
    parsed.query,
    outcome.outcomes,
    durationMs,
    outcome.results.length,
    outcome.providerBypassed,
    aiBody !== null,
  );
  console.log(`${body}\n\n${footer}`);
}

interface CliOptions {
  query: string;
  numResults: number;
  provider?: BackendName;
  timeoutMs: number;
}

function parseCliArgs(args: string[]): CliOptions {
  const parsed = parseArgs({
    args,
    allowPositionals: true,
    options: {
      help: { type: 'boolean', short: 'h' },
      provider: { type: 'string' },
      'num-results': { type: 'string' },
      numResults: { type: 'string' },
      'timeout-ms': { type: 'string' },
      timeoutMs: { type: 'string' },
    },
  });

  const query = parsed.positionals.join(' ').trim();
  if (!query) {
    throw new Error(usage());
  }

  return {
    query,
    numResults: parseBoundedInt(
      parsed.values['num-results'] ?? parsed.values.numResults,
      DEFAULT_NUM_RESULTS,
      MIN_NUM_RESULTS,
      MAX_NUM_RESULTS,
      'num-results',
    ),
    provider: parseProvider(parsed.values.provider),
    timeoutMs: parseBoundedInt(
      parsed.values['timeout-ms'] ?? parsed.values.timeoutMs,
      DEFAULT_TIMEOUT_MS,
      MIN_TIMEOUT_MS,
      MAX_TIMEOUT_MS,
      'timeout-ms',
    ),
  };
}

function parseProvider(value: string | undefined): BackendName | undefined {
  if (value == null || value === '') {
    return undefined;
  }
  if (isBackendName(value)) {
    return value;
  }
  throw new Error(`provider must be one of: ${BACKEND_NAMES.join(', ')}`);
}

function parseBoundedInt(
  value: string | undefined,
  fallback: number,
  min: number,
  max: number,
  label: string,
): number {
  if (value == null || value === '') {
    return fallback;
  }
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
    throw new Error(`${label} must be an integer from ${min} to ${max}`);
  }
  return parsed;
}

function usage(): string {
  return [
    'Usage:',
    '  web-search-ai-summary "<query>"',
    '',
    'Options:',
    `  --provider ${BACKEND_NAMES.join('|')}`,
    `  --num-results ${MIN_NUM_RESULTS}-${MAX_NUM_RESULTS}`,
    `  --timeout-ms ${MIN_TIMEOUT_MS}-${MAX_TIMEOUT_MS}`,
  ].join('\n');
}
