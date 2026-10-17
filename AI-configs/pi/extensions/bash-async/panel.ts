/**
 * Overlay with the running jobs on the left and the log tail of the selected
 * job on the right. Layout follows pi-subagents' fleet inspector. Selection and
 * scroll logic lives in `panel-state.ts`; this file is rendering, key mapping
 * and the log polling timer.
 */

import {
  isKeyRelease,
  matchesKey,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from '@earendil-works/pi-tui';
import type { Component, TUI } from '@earendil-works/pi-tui';
import type { Theme } from '@earendil-works/pi-coding-agent';
import type { Jobs } from './jobs.ts';
import { cleanLog, createPanelState, formatDuration } from './panel-state.ts';
import type { PanelAction } from './panel-state.ts';

const REFRESH_MS = 500;
const MIN_WIDTH = 36;

interface PanelOptions {
  tui: TUI;
  theme: Theme;
  jobs: Pick<Jobs, 'list' | 'kill'>;
  readTail: (logPath: string) => Promise<string>;
  done: () => void;
}

export interface Panel {
  component: Component & { dispose(): void };
  /** Call when the job list changes. */
  sync(): void;
  close(): void;
}

function toAction(data: string): PanelAction | undefined {
  if (matchesKey(data, 'down') || matchesKey(data, 'j')) {
    return 'next';
  }
  if (matchesKey(data, 'up') || matchesKey(data, 'k')) {
    return 'prev';
  }
  if (matchesKey(data, 'shift+x')) {
    return 'kill';
  }
  if (matchesKey(data, 'shift+k')) {
    return 'scrollUp';
  }
  if (matchesKey(data, 'shift+j')) {
    return 'scrollDown';
  }
  if (
    matchesKey(data, 'escape') ||
    matchesKey(data, 'ctrl+c') ||
    matchesKey(data, 'q')
  ) {
    return 'close';
  }
  return undefined;
}

function fit(text: string, width: number): string {
  return truncateToWidth(text, width, '…', true);
}

function spread(left: string, right: string, width: number): string {
  const gap = width - visibleWidth(left) - visibleWidth(right);
  return gap >= 1 ? left + ' '.repeat(gap) + right : fit(left, width);
}

export function createPanel({
  tui,
  theme,
  jobs,
  readTail,
  done,
}: PanelOptions): Panel {
  let closed = false;
  let tailPath = '';
  let tailText = '';

  function close() {
    if (closed) {
      return;
    }
    closed = true;
    clearInterval(timer);
    done();
  }

  const state = createPanelState({
    list: () => jobs.list(),
    kill: (pid) => jobs.kill(pid),
    close,
  });

  async function refreshTail() {
    const logPath = state.view().selected?.logPath;
    if (!logPath) {
      return;
    }
    const text = cleanLog(await readTail(logPath));
    // The selection may have moved or the panel closed while the read ran.
    if (closed || state.view().selected?.logPath !== logPath) {
      return;
    }
    if (text !== tailText || logPath !== tailPath) {
      tailText = text;
      tailPath = logPath;
      tui.requestRender();
    }
  }

  const timer = setInterval(() => void refreshTail(), REFRESH_MS);
  timer.unref?.();
  void refreshTail();

  function render(width: number): string[] {
    if (width < MIN_WIDTH) {
      return [
        truncateToWidth(
          `Needs at least ${MIN_WIDTH} columns. Esc closes.`,
          width,
        ),
      ];
    }
    const { jobs: running, selected } = state.view();
    const inner = width - 2;
    const rows = tui.terminal?.rows ?? 32;
    const bodyHeight = Math.max(2, Math.floor(rows * 0.85) - 6);
    const listWidth = Math.max(
      22,
      Math.min(40, Math.floor((inner - 1) * 0.35)),
    );
    const detailWidth = Math.max(1, inner - listWidth - 1);
    const border = (text: string) => theme.fg('border', text);

    const now = Date.now();
    const index = selected ? running.indexOf(selected) : 0;
    const listStart = Math.max(0, index - bodyHeight + 1);
    const listLines = running
      .slice(listStart, listStart + bodyHeight)
      .map((job) => {
        const marker = job === selected ? '▸' : ' ';
        const command = job.command.replace(/\s+/g, ' ');
        const text = `${marker} ${job.pid} ${formatDuration(now - job.startedAt)} ${command}`;
        return job === selected ? theme.bold(text) : text;
      });

    const logLines =
      selected && tailPath === selected.logPath
        ? tailText
            .replace(/\n$/, '')
            .split('\n')
            .flatMap((line) => {
              const wrapped = wrapTextWithAnsi(line, detailWidth);
              return wrapped.length ? wrapped : [''];
            })
        : [];
    const maxScroll = Math.max(0, logLines.length - bodyHeight);
    state.clampScroll(maxScroll);
    const { scrollBack } = state.view();
    const detailStart = maxScroll - scrollBack;
    const detailLines = logLines.slice(detailStart, detailStart + bodyHeight);

    const title = ` ${theme.bold('Async jobs')} ${theme.fg('dim', `· ${running.length} running`)}`;
    const status = selected
      ? `pid ${selected.pid} · ${scrollBack === 0 ? 'following' : 'scrolled'} `
      : theme.fg('dim', 'no running jobs ');
    const position = running.length ? `${index + 1}/${running.length}` : '0/0';
    const footer = ` j/k select · X kill · J/K scroll · Esc close · ${position}`;

    const lines = [border(`╭${'─'.repeat(inner)}╮`)];
    lines.push(
      border('│') + fit(spread(title, status, inner), inner) + border('│'),
    );
    lines.push(border(`├${'─'.repeat(listWidth)}┬${'─'.repeat(detailWidth)}┤`));
    for (let row = 0; row < bodyHeight; row++) {
      lines.push(
        border('│') +
          fit(listLines[row] ?? '', listWidth) +
          border('│') +
          fit(detailLines[row] ?? '', detailWidth) +
          border('│'),
      );
    }
    lines.push(border(`├${'─'.repeat(listWidth)}┴${'─'.repeat(detailWidth)}┤`));
    lines.push(border('│') + fit(theme.fg('dim', footer), inner) + border('│'));
    lines.push(border(`╰${'─'.repeat(inner)}╯`));
    return lines.map((line) => truncateToWidth(line, width));
  }

  const component = {
    render,
    invalidate() {},
    handleInput(data: string) {
      if (isKeyRelease(data)) {
        return;
      }
      const action = toAction(data);
      if (!action) {
        return;
      }
      state.handle(action);
      void refreshTail();
      tui.requestRender();
    },
    dispose() {
      closed = true;
      clearInterval(timer);
    },
  };

  return { component, sync: () => state.sync(), close };
}
