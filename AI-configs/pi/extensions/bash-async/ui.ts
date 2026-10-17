/**
 * Interactive UI of the extension: the running-job count above the footer, the `→` key that opens the
 * jobs panel, and the panel's lifecycle. Does nothing without a UI (print, RPC).
 */

import { isKeyRelease, matchesKey } from '@earendil-works/pi-tui';
import type { TUI } from '@earendil-works/pi-tui';
import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { footerLines } from './footer.ts';
import { isEditorFocused, shouldOpenPanel } from './input.ts';
import type { Jobs } from './jobs.ts';
import { createPanel } from './panel.ts';
import type { Panel } from './panel.ts';

const WIDGET_KEY = 'bash-async';

interface UiOptions {
  jobs: Pick<Jobs, 'list' | 'kill'>;
  readTail: (logPath: string) => Promise<string>;
}

export function createUi({ jobs, readTail }: UiOptions) {
  let ui: ExtensionContext['ui'] | undefined;
  let tui: TUI | undefined;
  let panel: Panel | undefined;
  let panelOpen = false;
  let unsubscribeInput: (() => void) | undefined;

  /** Call when the job list changes. */
  function refresh() {
    tui?.requestRender();
    panel?.sync();
  }

  async function openPanel(target: ExtensionContext['ui']) {
    panelOpen = true;
    try {
      await target.custom<void>(
        (panelTui, theme, _keybindings, done) => {
          panel = createPanel({
            tui: panelTui,
            theme,
            jobs,
            readTail,
            done: () => done(),
          });
          return panel.component;
        },
        {
          overlay: true,
          overlayOptions: {
            anchor: 'center',
            width: '95%',
            minWidth: 60,
            maxHeight: '85%',
            margin: 1,
          },
        },
      );
    } finally {
      panel = undefined;
      panelOpen = false;
    }
  }

  function onInput(data: string) {
    if (!ui || isKeyRelease(data) || !matchesKey(data, 'right')) {
      return undefined;
    }
    const target = ui;
    const focused = (tui as unknown as { focusedComponent?: unknown })
      ?.focusedComponent;
    const open = shouldOpenPanel({
      panelOpen,
      editorText: target.getEditorText(),
      editorFocused: isEditorFocused(focused),
      jobCount: jobs.list().length,
    });
    if (!open) {
      return undefined;
    }
    openPanel(target).catch((error: unknown) => {
      target.notify(
        error instanceof Error ? error.message : String(error),
        'error',
      );
    });
    return { consume: true };
  }

  function start(ctx: ExtensionContext) {
    if (!ctx.hasUI) {
      return;
    }
    ui = ctx.ui;
    // Like pi-subagents' roster: a belowEditor widget renders just above the footer.
    // It also hands over the TUI, the only place pi-tui exposes the focused component.
    ui.setWidget(
      WIDGET_KEY,
      (widgetTui, theme) => {
        tui = widgetTui;
        return {
          render: (width) =>
            // Two columns of padding around the text, kept inside the width.
            footerLines(jobs.list().length, Math.max(0, width - 2)).map(
              (line) => theme.bg('selectedBg', ` ${line} `),
            ),
          invalidate() {},
          dispose() {
            if (tui === widgetTui) {
              tui = undefined;
            }
          },
        };
      },
      { placement: 'belowEditor' },
    );
    unsubscribeInput = ui.onTerminalInput(onInput);
  }

  function stop() {
    panel?.close();
    panel = undefined;
    ui?.setWidget(WIDGET_KEY, undefined);
    unsubscribeInput?.();
    unsubscribeInput = undefined;
    ui = undefined;
    tui = undefined;
  }

  return { start, stop, refresh };
}
