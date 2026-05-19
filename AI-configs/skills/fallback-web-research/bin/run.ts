#!/usr/bin/env node

import { runCli } from '../src/cli.ts';

try {
  await runCli(process.argv.slice(2));
} catch (err) {
  const message = err instanceof Error ? err.message : String(err);
  console.error(message);
  process.exitCode = 1;
}
