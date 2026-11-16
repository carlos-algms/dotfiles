// Below this window a rate is mostly noise from the first chunk.
const MIN_RATE_WINDOW_MS = 250;

export function formatDuration(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  if (minutes === 0) {
    return `${seconds}s`;
  }
  return `${minutes}m ${String(seconds).padStart(2, '0')}s`;
}

function tokensPerSecond(tokens: number, ms: number): number | undefined {
  if (tokens === 0 || ms < MIN_RATE_WINDOW_MS) {
    return undefined;
  }
  return tokens / (ms / 1000);
}

// shortcut: chars/4 while streaming, providers send real usage only at message end
const estimateTokens = (chars: number): number => Math.round(chars / 4);

export function createTurnStats(now: () => number) {
  let startedAt = 0;
  let outputTokens = 0;
  // Perceived speed: time runs from the request, so the wait for the first token counts.
  let requestMs = 0;
  let messageStartedAt: number | undefined;
  let messageChars = 0;

  function averageTps(): number | undefined {
    return tokensPerSecond(outputTokens, requestMs);
  }

  function liveTps(): number | undefined {
    if (messageStartedAt === undefined) {
      return undefined;
    }
    return tokensPerSecond(
      estimateTokens(messageChars),
      now() - messageStartedAt,
    );
  }

  return {
    start(): void {
      startedAt = now();
      outputTokens = 0;
      requestMs = 0;
      messageStartedAt = undefined;
      messageChars = 0;
    },
    messageStart(): void {
      messageStartedAt = now();
      messageChars = 0;
    },
    delta(chars: number): void {
      messageChars += chars;
    },
    messageEnd(reportedOutput: number): void {
      if (messageStartedAt !== undefined) {
        requestMs += now() - messageStartedAt;
        outputTokens +=
          reportedOutput > 0 ? reportedOutput : estimateTokens(messageChars);
      }
      messageStartedAt = undefined;
      messageChars = 0;
    },
    workingMessage(): string {
      const tps = liveTps();
      const elapsed = formatDuration(now() - startedAt);
      return tps === undefined
        ? `Working · ${elapsed}`
        : `Working · ${elapsed} · ${Math.round(tps)} tok/s`;
    },
    summary(): string {
      const tps = averageTps();
      const took = `Turn took ${formatDuration(now() - startedAt)}`;
      return tps === undefined ? took : `${took} · TPS ~${Math.round(tps)}`;
    },
  };
}
