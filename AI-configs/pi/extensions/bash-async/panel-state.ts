import type { RunningJob } from './jobs.ts';

export type PanelAction =
  'next' | 'prev' | 'kill' | 'scrollUp' | 'scrollDown' | 'close';

export const SCROLL_STEP = 5;

interface PanelStateOptions {
  list: () => RunningJob[];
  kill: (pid: number) => boolean;
  close: () => void;
}

/**
 * Selection and scroll logic of the jobs panel, with no Pi or terminal code.
 * The selection follows the pid, so it survives other jobs ending. `scrollBack`
 * counts lines scrolled up from the end of the log; 0 follows the tail.
 */
export function createPanelState({ list, kill, close }: PanelStateOptions) {
  let selectedPid: number | undefined;
  let scrollBack = 0;

  function view() {
    const jobs = list();
    let selected = jobs.find((job) => job.pid === selectedPid);
    if (!selected) {
      selected = jobs[0];
      selectedPid = selected?.pid;
      scrollBack = 0;
    }
    return { jobs, selected, scrollBack };
  }

  function move(step: number) {
    const { jobs, selected } = view();
    if (!selected) {
      return;
    }
    const index = jobs.indexOf(selected) + step;
    const target = jobs[Math.max(0, Math.min(jobs.length - 1, index))];
    if (target && target.pid !== selected.pid) {
      selectedPid = target.pid;
      scrollBack = 0;
    }
  }

  function handle(action: PanelAction) {
    // Settle the selection first: a fallback to the first job resets the scroll.
    view();
    switch (action) {
      case 'next':
        move(1);
        return;
      case 'prev':
        move(-1);
        return;
      case 'kill': {
        const { selected } = view();
        if (selected) {
          kill(selected.pid);
        }
        return;
      }
      case 'scrollUp':
        scrollBack += SCROLL_STEP;
        return;
      case 'scrollDown':
        scrollBack = Math.max(0, scrollBack - SCROLL_STEP);
        return;
      case 'close':
        close();
        return;
      default:
        action satisfies never;
    }
  }

  /** The renderer knows the log length, so it caps the scroll here. */
  function clampScroll(max: number) {
    view();
    scrollBack = Math.min(scrollBack, max);
  }

  /** Call when the job list changes: closes the panel once no job is left. */
  function sync() {
    if (list().length === 0) {
      close();
    }
  }

  return { view, handle, clampScroll, sync };
}

const ANSI =
  // eslint-disable-next-line no-control-regex
  /\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)/g;

/** Drops colors, cursor codes and carriage-return redraws, so the log fits a plain pane. */
export function cleanLog(text: string): string {
  return text
    .replace(ANSI, '')
    .split('\n')
    .map((line) => line.replace(/\r+$/, '').split('\r').pop() ?? '')
    .join('\n')
    .replace(/\t/g, '    ')
    .replace(
      // eslint-disable-next-line no-control-regex
      /[\x00-\x08\x0b-\x1f\x7f]/g,
      '',
    );
}

export function formatDuration(ms: number): string {
  const seconds = Math.max(0, Math.floor(ms / 1000));
  if (seconds < 60) {
    return `${seconds}s`;
  }
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) {
    return `${minutes}m`;
  }
  return `${Math.floor(minutes / 60)}h`;
}
