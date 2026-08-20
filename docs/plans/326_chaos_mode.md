# Plan 326 — chaos mode: overshoot into invalid Vox, then whittle back

> **SUPERSEDED — 2026-08-20 (Josj): "I want to scrap chaos mode… I want it to be the
> default."** There is no separate mode and no knob. The generator is the
> noise-plus-rules model all the time (`CLAUDE.md`); a program the compiler
> rejects is a `parser-reject` finding to triage — a rule not yet written, or a
> compiler bug — and "chaos then whittle" is the permanent way of working,
> measured by `scripts/invariants` shrinking. What survives from this plan is
> the oracle rule in §"The oracle changes with the mode", re-homed as a **tag**:
> a program the generator deliberately broke must carry its expected verdict
> (`expected: reject`) in its metadata, so a rejection is the happy path and a
> crash is the finding. A "beautiful" (pretty-printed) layout is not planned;
> `--layout plain` from the layout randomizer covers the reading-aid case.


**Origin:** Josj, 2026-08-20: *"I want to add so much randomness and
awareness of all language functions that we end up with tons of
instances where invalid vox is being produced. We then slowly whittle
it back so that we have valid vox again, but catching real bugs. At the
moment we only produce very sensible, very uniform vox code."*

**Follows:** 323 (what constructs), 324 (what order, what I/O),
325 (what shapes). This plan is orthogonal to all three: **how far from
legal** a generated program is allowed to stray.

---

## Why the current fuzzer cannot find half the compiler's bugs

Every emitter today produces sensible, uniform, always-valid Vox. Two
structural consequences:

1. **The compiler's error paths are never executed.** Parser recovery,
   analyzer diagnostics, "expected X, got Y" — an entire half of the
   compiler has zero fuzz coverage, because the invariant forbids
   feeding it anything that would reach those paths.
2. **The explored valid space is a thin corridor.** Templated emission
   means the same few sentence shapes with different names. The
   bug-dense region is the *boundary* — nearly-valid programs, one
   token from legal — and a generator that never crosses the boundary
   also never walks along it.

The night of #31/#32/#33 is the evidence: three bugs sat in documented,
sensible, *valid* Vox that was merely **unusual** — a flag without a
default, a flag read inside a function, `is empty` on a text. Uniform
generation finds nothing unusual by construction.

## The oracle changes with the mode — this is the load-bearing rule

The existing invariant is not wrong; it is the *oracle for valid mode*,
and it stands unchanged there. Chaos mode gets its own:

| Mode | Program contract | What counts as a finding |
|---|---|---|
| valid (today) | must compile and run | signal death, ICE, hang, assembler rejection |
| **chaos (new)** | none — may be illegal | (1) the **compiler** panics, ICEs, or dies by signal on ANY input — a compiler must never crash on bad input, it must diagnose; (2) the **assembler rejects** what the compiler accepted; (3) the compiled program **dies by signal** — invalid code was accepted and crashes at runtime; (4) a program the whittling classifies as *legal per LANGUAGE.md* is rejected — a spec/implementation gap, in either direction |

A diagnostic plus a nonzero compiler exit is the **happy path** in
chaos mode and is never a finding. This one rule is what keeps chaos
mode from drowning us in noise.

## Mechanism — one seeded knob

- **`chaos`, 0.0–1.0, per run, recorded in the seed ledger.** At 0.0,
  today's generator, byte for byte. Determinism becomes per
  (seed, chaos) pair.
- Rising chaos unlocks **mutations over legal output**: swap/duplicate/
  delete tokens; wrong punctuation (periods and commas are load-bearing
  in Vox — mutating them is a whole bug class by itself); wrong-typed
  initialisers; references to undeclared names; truncation
  mid-sentence; splicing two generated programs; the illegal orderings
  plan 324 already wants reported.
- **"Awareness of all language functions":** the mutation vocabulary
  is drawn from the full LANGUAGE.md construct inventory — 323 T8's
  coverage ledger doubles as the vocabulary source — so chaos reaches
  words the valid emitters do not use yet.
- **Whittling is two dials, not one.** Per campaign: walk the chaos
  knob down until the valid/invalid ratio is healthy again. Per
  finding: reduce the program to a minimal reproducer, then classify —
  legal Vox (a compiler bug for the register) or illegal (an error-path
  bug). Reduction is manual first, automated delta-debugging later.

## What does NOT bend

- **Tier NEVER is absolute.** Mutations must not manufacture banned
  vocabulary; the T1 guard runs on chaos output too, and a mutation
  that would produce a banned word is discarded, not emitted.
- **Confinement tightens.** A binary compiled from invalid source is
  the most likely of all to scribble — chaos-mode runs are
  bwrap-confined without exception, and the plan-324 allowlist applies.
- **Findings carry (seed, chaos, input-seed)** or they do not exist.

## Ordering

Requires 323 T1 (the guard) and the confinement sandbox before any
chaos program *runs*. Compile-only chaos (oracle findings 1 and 2) can
land earlier — the compiler itself needs no sandbox to be crashed.

## Acceptance

- `chaos 0.0` reproduces today's output byte-for-byte on the same seed.
- A campaign at `chaos 0.3` produces both valid and invalid programs,
  and the run report says the ratio.
- A deliberately planted compiler panic (test-only) is caught by
  oracle rule 1; a plain diagnostic is not reported.
- The T1 guard passes on chaos output across 1,000 seeds.
