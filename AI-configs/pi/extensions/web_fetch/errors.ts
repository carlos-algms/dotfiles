import type { CauseInfo, Phase } from './types';

export function enrichError(args: {
  err: unknown;
  url: string;
  phase: Phase;
  timeoutMs: number;
  elapsedMs: number;
  outerSignal: AbortSignal | undefined;
  timeoutSignal: AbortSignal;
  extraLines?: string[];
}): Error {
  const {
    err,
    url,
    phase,
    timeoutMs,
    elapsedMs,
    outerSignal,
    timeoutSignal,
    extraLines,
  } = args;

  let reason: string;
  if (timeoutSignal.aborted) {
    reason = `timed out after ${timeoutMs}ms`;
  } else if (outerSignal?.aborted) {
    reason = 'cancelled by host';
  } else if (err instanceof Error) {
    reason = err.message || err.name || 'unknown error';
  } else {
    reason = String(err);
  }

  const lines = [
    `web_fetch failed: ${reason}`,
    `url: ${url}`,
    `phase: ${phase}`,
    `elapsed: ${elapsedMs}ms (timeout: ${timeoutMs}ms)`,
  ];

  if (extraLines) {
    for (const extra of extraLines) {
      lines.push(extra);
    }
  }

  const cause = describeCause(err);
  if (cause) {
    const formatted = formatCause(cause);
    if (formatted && formatted !== reason) {
      lines.push(`cause: ${formatted}`);
    }
  }

  const wrapped = new Error(lines.join('\n'));
  if (err instanceof Error) {
    (wrapped as Error & { cause?: unknown }).cause = err;
  }
  return wrapped;
}

function describeCause(err: unknown): CauseInfo | undefined {
  const seen = new Set<unknown>();

  function visit(node: unknown): CauseInfo | undefined {
    if (!node || typeof node !== 'object' || seen.has(node)) {
      return undefined;
    }
    seen.add(node);

    const obj = node as {
      code?: unknown;
      cause?: unknown;
      message?: unknown;
      syscall?: unknown;
      hostname?: unknown;
      address?: unknown;
      port?: unknown;
      errors?: unknown;
    };

    if (typeof obj.code === 'string' && obj.code.length > 0) {
      return {
        code: obj.code,
        message: typeof obj.message === 'string' ? obj.message : undefined,
        syscall: typeof obj.syscall === 'string' ? obj.syscall : undefined,
        hostname: typeof obj.hostname === 'string' ? obj.hostname : undefined,
        address: typeof obj.address === 'string' ? obj.address : undefined,
        port:
          typeof obj.port === 'number' || typeof obj.port === 'string'
            ? obj.port
            : undefined,
      };
    }

    if (Array.isArray(obj.errors) && obj.errors.length > 0) {
      for (const child of obj.errors) {
        const info = visit(child);
        if (info) {
          return { ...info, aggregateCount: obj.errors.length };
        }
      }
    }

    return visit(obj.cause);
  }

  return visit(err);
}

function formatCause(info: CauseInfo): string {
  const head: string[] = [];
  if (info.code) {
    head.push(info.code);
  }
  if (info.message) {
    head.push(info.message);
  }
  const headStr = head.join(': ');

  const extras: string[] = [];
  if (info.syscall) {
    extras.push(`syscall=${info.syscall}`);
  }
  if (info.hostname) {
    extras.push(`host=${info.hostname}`);
  }
  if (info.address) {
    extras.push(
      info.port !== undefined
        ? `addr=${info.address}:${info.port}`
        : `addr=${info.address}`,
    );
  } else if (info.port !== undefined) {
    extras.push(`port=${info.port}`);
  }
  if (info.aggregateCount && info.aggregateCount > 1) {
    extras.push(`attempts=${info.aggregateCount}`);
  }

  return extras.length > 0 ? `${headStr} [${extras.join(' ')}]` : headStr;
}
