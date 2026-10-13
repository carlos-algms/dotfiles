import { open } from 'node:fs/promises';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { formatCompletion } from './format.ts';
import type { JobResult } from './jobs.ts';

export const TAIL_LIMITS = { maxLines: 50, maxBytes: 8 * 1024 };

const NEWLINE = 0x0a;

interface NotifierOptions {
  send: ExtensionAPI['sendMessage'];
  /** Pi's `truncateTail`, injected so this module does not import Pi at runtime. */
  truncate: (content: string) => string;
}

async function readLastBytes(logPath: string, size: number) {
  const file = await open(logPath, 'r');
  try {
    const { size: fileSize } = await file.stat();
    const length = Math.min(fileSize, size);
    const buffer = Buffer.alloc(length);
    const { bytesRead } = await file.read(buffer, 0, length, fileSize - length);
    return { bytes: buffer.subarray(0, bytesRead), cut: fileSize > length };
  } finally {
    await file.close();
  }
}

/** Reads only the last `maxBytes` of the log, so memory stays flat for any log size. */
export async function readTail(logPath: string, truncate: NotifierOptions['truncate']): Promise<string> {
  const window = await readLastBytes(logPath, TAIL_LIMITS.maxBytes).catch(() => undefined);
  if (!window) {
    return '';
  }
  let { bytes } = window;
  if (window.cut) {
    // The window starts mid-line and may split a UTF-8 character. `\n` never occurs inside one.
    const newline = bytes.indexOf(NEWLINE);
    if (newline !== -1) {
      bytes = bytes.subarray(newline + 1);
    }
  }
  return truncate(bytes.toString('utf-8'));
}

export function createNotifier({ send, truncate }: NotifierOptions) {
  return async function notify(result: JobResult): Promise<void> {
    try {
      const content = formatCompletion(result, await readTail(result.logPath, truncate));
      send({ customType: 'bg-run', content, display: true }, { triggerTurn: true, deliverAs: 'followUp' });
    } catch {
      // After /reload or /new the captured `pi` is stale and `send` throws. Nobody is left to notify.
    }
  };
}
