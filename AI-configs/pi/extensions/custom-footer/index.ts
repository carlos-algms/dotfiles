import {
  FooterComponent,
  type ExtensionAPI,
  type ExtensionContext,
} from '@earendil-works/pi-coding-agent';
import { replaceFooterStats } from './render.ts';
import { createSessionCacheHitRate } from './usage.ts';

export default function customFooter(pi: ExtensionAPI): void {
  let context: ExtensionContext | undefined;
  const sessionCacheHitRate = createSessionCacheHitRate();
  const originalRender = FooterComponent.prototype.render;

  // shortcut: wraps Pi's renderer internals; revisit if its output format changes.
  function render(this: FooterComponent, width: number): string[] {
    const lines = originalRender.call(this, width);
    const stats = lines[1];
    if (!context || stats === undefined) {
      return lines;
    }

    lines[1] = replaceFooterStats(
      stats,
      width,
      sessionCacheHitRate(context.sessionManager),
      context.getContextUsage()?.tokens,
    );
    return lines;
  }

  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode !== 'tui') {
      return;
    }
    context = ctx;
    FooterComponent.prototype.render = render;
  });

  pi.on('session_shutdown', () => {
    if (FooterComponent.prototype.render === render) {
      FooterComponent.prototype.render = originalRender;
    }
    context = undefined;
  });
}
