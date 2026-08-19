# Plan 324 — vary the program's shape, and let it do I/O safely

**Status:** approved by TheJostler, 2026-08-19, from reading two
generated programs and asking why they looked alike.
**Follows:** plan 323 (total coverage). 323 asks *which constructs* are
emitted. This asks two different questions: **in what order**, and
**can a generated program talk to the outside world safely**.

---

## Part A — the program skeleton never varies

Measured across 40 generated programs (budget 22):

| | first occurrence |
|---|---|
| `A thing called ...` | line 1 |
| `To <function>` | line 18 |
| top-level declarations | line 39 |
| first statement | ~line 42 |

**Identical in all forty.** The *content* differs — all 40 preambles are
unique — but the *shape* is a fixed template: things, then functions,
then globals, then statements, always in that order, always at those
offsets.

### Why this is worth fixing, with evidence

**Declaration order changes behaviour, and we proved it tonight.**
Bug #28: a conditional declaration followed by a top-level one
segfaults; **the same two declarations in the opposite order are fine.**
A generator that only ever emits one ordering is structurally incapable
of finding that class of defect — the same "cannot look" problem that
hid #29.

Also never exercised today:
- **Forward references.** Can a function name a global declared *below*
  it? Real language semantics, zero coverage.
- **Interleaving.** A thing defined after a function; a global between
  two functions; a statement before any declaration.
- **Degenerate shapes.** A program with no things at all; with no
  functions; with only statements; with a function but no call to it.

### T1 — vary the skeleton

Emit the four sections in a **seeded random order**, and allow each to
be **absent**. Constraints that must survive:

- The program must remain **legal Vox that should compile and run** —
  the invariant is unchanged. If Vox requires a declaration before use
  in some position, respect it; where it does not, vary it.
- Where an ordering is *illegal*, that is a finding about the language
  worth reporting, not a program to emit.
- Determinism per seed is unchanged.

**Acceptance:** across 100 seeds, at least four distinct section
orderings appear, and at least one program of each degenerate shape
(no things / no functions / no globals) is produced. All compile.

---

## Part B — file I/O, constrained to an allowlist

File I/O is Tier CONFINE in plan 323 and has been blocked on the
sandbox. **An allowlist unblocks it without waiting**, because the paths
are then a fixed, known set rather than anything the generator invents.

### T2 — the allowlist

A generated program may open **only** these, and nothing else:

| Direction | Permitted |
|---|---|
| read | `/dev/stdin`, `0`, `<run-dir>/fuzz-input` |
| write | `/dev/stdout`, `1`, `<run-dir>/fuzz-output` |

**`<run-dir>` is per-run and supplied by the harness — never a fixed
path.** This is not a detail: fixed scratch names in a shared directory
are exactly the defect that made two concurrent campaigns fabricate
**1,260 false findings** on 2026-08-19. `src/sandbox.vox` (plan 323 T2)
already creates a per-run directory; use it rather than inventing
`/tmp/fuzz-input`.

The guard test (`tests/200_never_emitted`) gains the complement of this
list: a generated program containing any *other* path in an `open` is a
build failure, the same way Tier NEVER vocabulary is.

### T3 — feed the input

Once a program can read `/dev/stdin` or `<run-dir>/fuzz-input`, the
harness can put **seeded random bytes** there before running it. That is
**Task 12 (runtime-input fuzzing)** from the v1 plan, reached cheaply:
the same program under different input becomes a second axis of
coverage, and a crash that depends on input is a class the fuzzer has
never been able to find.

Input generation must be **seeded and recorded** — a finding is only
reproducible if `repro.sh` can recreate the input as well as the
program. Extend the finding directory with the input bytes, and the
seed ledger row with the input seed.

**Acceptance:** a generated program reads its input and behaves; a
deliberately corrupt input does not crash *the harness*; `repro.sh`
reproduces a finding including its input.

---

## What this does not change

The invariant stands: **a generated program must be legal Vox that
should compile and run.** A nonzero exit is normal and is not a finding;
a signal death, hang, ICE or assembler rejection is. Neither part of
this plan is licence to emit invalid programs — reading from a file that
does not exist is legal Vox and currently returns silently (see the
design gap recorded in the 2026-08-19 audit), so it is fair game; opening
a path outside the allowlist is not.
