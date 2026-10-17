/**
 * Bash Async - `bash_async_run` starts a bash command in the background without
 * blocking the agent, `bash_async_kill` stops it. Output goes to a log file the
 * agent reads with its own tools. When the command ends, a follow-up message wakes
 * the agent. Nothing waits for or polls the job in between. In the interactive UI,
 * the footer counts running jobs and `→` on an empty prompt opens a panel with
 * their output, where `X` kills the selected job.
 */

import {
  createLocalBashOperations,
  truncateTail,
} from '@earendil-works/pi-coding-agent';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { createJobs } from './jobs.ts';
import { TAIL_LIMITS, createNotifier, readTail } from './notify.ts';
import { createToolHandlers } from './tools.ts';
import { createUi } from './ui.ts';

const LOG_DIR = '/tmp/pi-bash-async-logs';

const RUN_PARAMS = Type.Object({
  command: Type.String({
    description: 'Bash command to run in the background',
  }),
  timeout: Type.Optional(
    Type.Number({ description: 'Kill the command after this many seconds' }),
  ),
});

const KILL_PARAMS = Type.Object({
  pid: Type.Number({
    description:
      'Job id returned by bash_async_run ("Started job <id>"), not the pid of a child or daemon',
  }),
});

export default function (pi: ExtensionAPI) {
  const truncate = (content: string) =>
    truncateTail(content, TAIL_LIMITS).content;
  const notify = createNotifier({
    send: (message, options) => pi.sendMessage(message, options),
    truncate,
  });

  const jobs = createJobs({
    ops: createLocalBashOperations(),
    logDir: LOG_DIR,
    onExit: (result) => void notify(result),
    onChange: () => ui.refresh(),
  });
  const ui = createUi({
    jobs,
    readTail: (logPath) => readTail(logPath, truncate),
  });
  const handlers = createToolHandlers(jobs);

  pi.on('session_start', (_event, ctx) => ui.start(ctx));
  pi.on('session_shutdown', () => {
    jobs.killAll();
    ui.stop();
  });

  pi.registerTool({
    name: 'bash_async_run',
    label: 'Bash async run',
    description:
      'Start a bash command in the background. Returns at once with a job id (the shell pid) and a log file path. ' +
      'All output stays in that log file. Do not redirect it in the command (`>`, `>>`, `2>`, `&>`): a redirected stream leaves the log and never reaches the completion message. ' +
      'When the command ends, its exit code and the end of its output arrive as a separate follow-up message. That message is the only result channel: no tool waits for this job. ' +
      'Never sleep, poll, or run a second command to collect the result. bg_wait is a pi-subagents tool for subagent runs and cannot wait for this job. ' +
      'If nothing else is left to do, end the turn and report the job id; the result wakes you. ' +
      'To stop the job early, pass the job id to bash_async_kill. ' +
      'Use it only for commands that would otherwise block the turn (servers, watchers, full test suites). When the job ends, the processes it started are stopped too.',
    promptSnippet:
      'Start a bash command in the background; its result arrives later as a follow-up message, so the turn is never blocked',
    promptGuidelines: [
      'Use bash_async_run instead of bash for commands that run longer than about 30 seconds (servers, watchers, full test suites). The result arrives as a follow-up message when the command ends.',
      'After starting a job, do other work or end the turn. Never sleep, wait, poll, or run a second command to collect its result, and never pass the job id to bg_wait: that tool belongs to pi-subagents and cannot see these jobs.',
    ],
    parameters: RUN_PARAMS,
    execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      return handlers.run(params, ctx.cwd);
    },
  });

  pi.registerTool({
    name: 'bash_async_kill',
    label: 'Bash async kill',
    description:
      'Stop a job started by bash_async_run before it ends on its own. Pass the job id that bash_async_run returned. ' +
      'Also stops the processes the job started, including detached daemons. ' +
      'After stopping, check that nothing is left (for example with pgrep). A process that clears its environment, or a macOS system binary, can survive: stop it with its own stop command or by pid.',
    parameters: KILL_PARAMS,
    execute(_toolCallId, params) {
      return handlers.kill(params);
    },
  });
}
