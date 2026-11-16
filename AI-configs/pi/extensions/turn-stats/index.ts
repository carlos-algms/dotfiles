import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent';
import { createTurnStats } from './stats.ts';

export default function turnStats(pi: ExtensionAPI): void {
  const stats = createTurnStats(Date.now);
  let timer: ReturnType<typeof setInterval> | undefined;

  function stop(ctx: ExtensionContext): void {
    clearInterval(timer);
    timer = undefined;
    ctx.ui.setWorkingMessage();
  }

  pi.on('agent_start', (_event, ctx) => {
    // Queued follow-ups start new runs before settling; keep one timer per user turn.
    if (ctx.mode !== 'tui' || timer !== undefined) {
      return;
    }
    stats.start();
    ctx.ui.setWorkingMessage(stats.workingMessage());
    timer = setInterval(
      () => ctx.ui.setWorkingMessage(stats.workingMessage()),
      1000,
    );
    timer.unref();
  });

  pi.on('message_start', (event) => {
    if (timer !== undefined && event.message.role === 'assistant') {
      stats.messageStart();
    }
  });

  pi.on('message_update', (event) => {
    const update = event.assistantMessageEvent;
    if (
      timer !== undefined &&
      (update.type === 'text_delta' ||
        update.type === 'thinking_delta' ||
        update.type === 'toolcall_delta')
    ) {
      stats.delta(update.delta.length);
    }
  });

  pi.on('message_end', (event) => {
    if (timer !== undefined && event.message.role === 'assistant') {
      stats.messageEnd(event.message.usage.output);
    }
  });

  pi.on('agent_settled', (_event, ctx) => {
    if (timer === undefined) {
      return;
    }
    stop(ctx);
    ctx.ui.notify(stats.summary(), 'info');
  });

  pi.on('session_shutdown', (_event, ctx) => {
    if (timer !== undefined) {
      stop(ctx);
    }
  });
}
