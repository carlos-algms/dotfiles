/**
 * Bash Background Run - `bash_bg_run` starts a bash command in the background
 * without blocking the agent, `bash_bg_kill` stops it. Output goes to a log file
 * the agent reads with its own tools. When the command ends, a follow-up message
 * wakes the agent.
 */

import { createLocalBashOperations, truncateTail } from '@earendil-works/pi-coding-agent';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { createJobs } from './jobs.ts';
import { TAIL_LIMITS, createNotifier } from './notify.ts';
import { createToolHandlers } from './tools.ts';

const LOG_DIR = '/tmp/pi-bash-bg-logs';

const RUN_PARAMS = Type.Object({
  command: Type.String({ description: 'Bash command to run in the background' }),
  timeout: Type.Optional(Type.Number({ description: 'Kill the command after this many seconds' })),
});

const KILL_PARAMS = Type.Object({
  pid: Type.Number({ description: 'Job id (the pid) returned by bash_bg_run' }),
});

export default function (pi: ExtensionAPI) {
  const notify = createNotifier({
    send: (message, options) => pi.sendMessage(message, options),
    truncate: (content) => truncateTail(content, TAIL_LIMITS).content,
  });

  const jobs = createJobs({
    ops: createLocalBashOperations(),
    logDir: LOG_DIR,
    onExit: (result) => void notify(result),
  });
  const handlers = createToolHandlers(jobs);

  pi.on('session_shutdown', () => jobs.killAll());

  pi.registerTool({
    name: 'bash_bg_run',
    label: 'Bash background run',
    description:
      'Run a bash command in the background. Returns at once with a job id (the pid) and a log file path. ' +
      'Do not wait or poll for it: when the command ends, the result (exit code and end of the output) arrives on its own. ' +
      'While it runs, read the log file with tail, head, rg or read.',
    promptSnippet: 'Run a long-running bash command in the background',
    promptGuidelines: [
      'Use bash_bg_run instead of bash for commands that run longer than about 30 seconds (servers, watchers, full test suites). Do not wait for it; the result arrives when the command ends.',
    ],
    parameters: RUN_PARAMS,
    execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      return handlers.run(params, ctx.cwd);
    },
  });

  pi.registerTool({
    name: 'bash_bg_kill',
    label: 'Bash background kill',
    description: 'Stop a bash command running in the background, started with bash_bg_run.',
    parameters: KILL_PARAMS,
    execute(_toolCallId, params) {
      return handlers.kill(params);
    },
  });
}
