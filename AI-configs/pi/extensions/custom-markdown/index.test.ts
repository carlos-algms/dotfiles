import assert from 'node:assert/strict';
import { test } from 'node:test';
import customMarkdown from './index.ts';
import { transformUserMarkdown } from './transform.ts';

test('registers only the display transformer', () => {
  let registrations = 0;
  customMarkdown({
    registerMarkdownTransformer(transformer) {
      registrations++;
      assert.equal(transformer, transformUserMarkdown);
    },
  });
  assert.equal(registrations, 1);
});
