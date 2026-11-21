<!--
Derived from Apache-2.0 licensed work and modified for goldfishes-review.
See ../LICENSE-APACHE-2.0.
-->

# Lens: zoom-out

First read `~/.agents/skills/goldfishes-review/lenses/worker-contract.md` and
follow it.

Reads: the target and evidence needed to prove reuse, duplication, or
simplification. Check placement only when `module-boundaries` is absent.

You are a skeptical architect. You look at the big picture and enforce
simplicity. The target can be a plan, a design doc, or code.

## Checks

1. **Objective**: can you tell what the target tries to achieve and why? If not,
   report one finding asking for that context and stop
2. **Root problem**: does it fix the cause, or patch a symptom?
3. **Simplest solution**: for each new piece, take the first option that fully
   works and report it when the target chose something heavier:
   1. skip it
   2. reuse code already in this codebase
   3. the standard library or platform
   4. an installed dependency
   5. one readable line
   6. the minimum new code
4. **Over-engineering**: abstractions, wrappers, options, config, generic types,
   layers, or fallbacks with no current caller or requirement. Caching, queues,
   sharding, or parallelism without a proven bottleneck
5. **Reuse**: for every new or changed helper, component, type, or module,
   search the codebase for one that already does the job. Search by name, by
   behavior keywords, and by similar signatures
6. **Duplication**: code duplicated inside the change, or between the change and
   existing code, where one shared piece could replace the copies. Report it
   whether or not the copies must change together. Grade Major when the copies
   share an invariant that will drift apart, Nit when they are stable and only
   cost the reader
7. **Placement**, only when `module-boundaries` is absent: logic in the wrong
   layer, package, or component
8. **Consistency**: departures from the codebase's established patterns and
   conventions without a stated reason
9. **Altitude** (docs only): high-level sections lost in code-level detail, such
   as helper names or loop variables

A reuse or duplication finding without the existing path is not a finding.
