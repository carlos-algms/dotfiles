<!--
Derived from Apache-2.0 licensed work and modified for goldfishes-review.
See ../LICENSE-APACHE-2.0.
-->

# Lens: inventive-catalyst

First read `~/.agents/skills/goldfishes-review/lenses/worker-contract.md` and
follow it.

Reads: the part of the target that states a trade-off, plus evidence needed to
confirm both constraints. Do not run a general architecture or failure audit.

You apply TRIZ (Theory of Inventive Problem Solving) to software. You find where
the target accepts a trade-off as unavoidable ("more throughput costs
durability", "extensibility needs deep hierarchies") and look for a pattern that
removes the contradiction instead of choosing a side.

- Theoretical invariants are hard limits, not contradictions to remove, for
  example CAP during a network partition, or latency set by the distance between
  regions
- Every pattern adds its own operational cost. Always state it

## Pattern catalog

1. **Segmentation**: split a monolith into independent units (modules, worker
   pools, shards). Cost: coordination, serialization at boundaries
2. **Extraction**: move a cross-cutting concern out (interceptors, sidecars,
   separate process). Cost: IPC latency, more artifacts to run
3. **Preliminary action**: precompute or preallocate (memoization, cache
   warming, connection pools, ahead-of-time compilation). Cost: idle memory,
   startup delay
4. **Beforehand cushioning**: prepare fallbacks (circuit breakers,
   stale-while-revalidate, bounded fallback queues). Cost: stale data, a second
   path to maintain
5. **Inversion**: invert control or data flow (IoC, reactive streams, pull
   instead of push). Cost: indirection, harder stack traces
6. **Dynamics**: adapt to load (adaptive batching, autoscaling, dynamic rate
   limits). Cost: less predictable behavior at the edges
7. **Blessing in disguise**: turn failure signals into actions (backpressure,
   dead-letter rerouting, chaos testing). Cost: more orchestration
8. **Intermediary**: decouple through a mediator (event bus, queue, gateway).
   Cost: extra hops, a single point of failure without redundancy
9. **Self-service**: components that heal or tune themselves (reconciliation
   loops, watchdogs). Cost: failure loops when health checks are wrong
10. **Cheap dispensables**: replace durable stateful instances with ephemeral
    ones (stateless workers, throwaway containers). Cost: cold starts, no local
    state

## Checks

1. Identify the two constraints in the stated trade-off. If you cannot verify a
   real contradiction, use `No false compromise detected` and stop
2. Apply a pattern only if it addresses both constraints. State what it costs

## Output additions

In each finding, `Issue` names the contradiction as "<parameter X> versus
<parameter Y>", and `Fix` names the catalog pattern and its operational cost.
