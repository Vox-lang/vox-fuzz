# Plan 322 — repairing what the red team found

**Status:** approved by TheJostler, 2026-08-19 ("Fix them all").
**Source:** red-team run against `c99e734`, six findings, **all six
reproduced by the master** under bubblewrap before any work was scoped.
Zero fabrications in the run.

Severity order, and the phase each belongs to:

| # | Sev | Defect | Phase |
|---|-----|--------|-------|
| 01 | **HIGH** | Assembler/linker rejections silently dropped — the `asm-reject` class is dead code | A |
| 02 | **MEDIUM** | Shell injection via `--out`/`--vox`/`--core`; benign metacharacters silently misplace evidence | A |
| 05 | LOW | `gen.vox` never emits **maps** | B |
| 06 | LOW | never emits the dynamic **`value`** type | B |
| 04 | LOW | never emits **floats** or `divide` | B |
| 03 | LOW | never emits **thing member functions** | B |

The two phases touch disjoint files and run in parallel worktrees:
**A** owns `src/loop_gen.vox`, `src/findings.vox`, `src/main.vox`.
**B** owns `src/gen.vox`. Neither may edit the other's files.

---

## Phase A — the fuzzer's judgment

### A1. Finding 01 (HIGH) — the classifier matches text that never appears

`src/loop_gen.vox` decides `asm-reject` with
`grep -q -e nasm -e 'ld:' ./vf_cerr`. Reproduced: 8 forced assembler
rejections produced **0 findings**. Full evidence in
[FUZZER_DEFECTS.md](../FUZZER_DEFECTS.md) entry 1 — briefly, vox prints
`NASM assembly failed` (capital) on the reject arm, nasm's own diagnostic
never contains `nasm`, `Linking failed` carries no `ld:`, and this
platform's linker prefixes `/usr/bin/ld.bfd:`. Lowercase `nasm` appears
only in the *install hint*, printed when nasm cannot be run — the one
case that is **not** a compiler bug.

**Fix direction.** Stop pattern-matching prose written for humans. Match
the compiler's own deliberate wrapper lines with `grep -F` —
`NASM assembly failed` and `Linking failed` are stable strings vox emits
on exactly these paths — and treat the toolchain's free-form diagnostics
as unreliable corroboration, never as the signal. Keep the existing
`ld:`/`nasm` patterns as *additional* alternatives so a platform that
does print them still matches; the bug is that they were the only ones.

**Regression test (required).** Force a **real** assembler rejection —
a `nasm` shim earlier in `PATH` that exits nonzero — and assert a
finding directory appears. Simulating vf_cerr's contents by hand is not
acceptable: that tests the grep against a fixture written by the same
person who wrote the grep. The red team's `poc.sh` is the model.

### A2. Finding 02 (MEDIUM) — user-controlled values spliced into shell strings

`main.vox` sets `findings_dir`/`vox_binary`/`vox_core` straight from
`--out`/`--vox`/`--core`; `findings.vox` interpolates all three unquoted
into `run shell` strings (`mkdir -p {dir}`, `cp {src} {dir}/…`, the
`printf` redirections, `chmod`, `test -d`). Reproduced:
`--out './vfinj$(touch PROOF)z'` executed the substitution while the run
reported `findings: 1`.

**The half that matters more than the injection:** an `--out` containing
a **space** makes `mkdir -p` create two directories and the copies land
elsewhere, while the tool still prints `findings: N`. Evidence for N real
compiler bugs, silently scattered, with a success message on top. No
attacker required — the same disease as A1, the fuzzer reporting work it
has not done.

**Fix direction, in preference order.** (a) Do the filesystem work in
Vox rather than through `/bin/sh` wherever the language can —
directory creation, file writes — so no shell parses these values at
all. (b) Where a shell is genuinely required, single-quote every
interpolated value and escape embedded quotes, once, in one helper, so
there is a single place to audit. Do **not** merely reject
metacharacters and call it fixed: a path with a space is legitimate and
must work.

**Regression tests (required).** One for injection (a substitution in
`--out` must not execute), and one for the benign case (an `--out`
containing a space must place `program.vox`, `classification.txt`, and
`repro.sh` exactly where the summary claims).

### A3. While you are in there — two cheap precision fixes

Both from the red team's "unproven suspicions", both real on reading:

- A compile that exceeds the **hardcoded 60s** budget returns `-1` and is
  filed as `ice / "compiler run did not exit"`. It *is* recorded, so no
  bug is lost — but the label is wrong, and the 60s is independent of
  `--timeout` (which governs only the run). Give the compile budget its
  own honest name and label the outcome a compile hang.
- On compile timeout `supervise` SIGKILLs `/bin/sh`, not the `vox`
  grandchild, so a hung compiler lingers. Fix if it is cheap in-language;
  if it is not, record it in FUZZER_DEFECTS.md rather than leaving it in
  a report nobody re-reads.

---

## Phase B — what the generator can never say

Each gap is proven twice: grep evidence that `gen.vox` cannot emit it,
plus a `demo.vox` that compiles and runs on vox 0.4.5. The demos are in
the red-team finding directories and are the acceptance targets — the
generator must be able to produce programs of that shape.

The ranking is by crash-likelihood, and it is not arbitrary: **every one
of these is a construct where compiler bugs have already lived.**
`value` tag handling produced bugs #2, #8 and #15; float interpolation
produced #1. The fuzzer has been unable to look at any of it.

- **B1 — maps (Finding 05).** Creation with literals, string-key read
  and write, `'s length`, `For each key in … 's keys`. Memory-adjacent:
  heap growth and hashing.
- **B2 — the `value` type (Finding 06).** Declaration, and the
  round-trip that has historically broken: assign a number, print,
  reassign to text, print. Runtime-tag ABI.
- **B3 — floats (Finding 04).** `a float called …`, float arithmetic
  including `divide`, and int↔float interaction. The entire float
  codegen path is unfuzzed.
- **B4 — thing member functions (Finding 03).** The manifest entry
  (`a function called m`) and `To do the T's m`, plus calling one.
  Today only data fields are generated.

**Also grep-proven by the report, worth adding while the file is open**
(no separate finding, same evidence standard): **mixed-type lists**
(`[1, "two", 3.5]` — per-slot tag machinery, memory-adjacent), **text as
a value the generated program manipulates** (today text is only ever the
source the fuzzer writes), and **the chained expansion itself** — the
fuzzer now *uses* grid expansion but never *emits* it, so the construct
0.4.5 shipped is self-hostingly unfuzzed.

**Constraint that governs all of Phase B.** The generator's invariant is
unchanged: a generated program must be **legal Vox that should compile
and run**. A nonzero exit is normal and is not a finding; a signal death,
hang, ICE, or assembler rejection is. Do not emit programs that are
merely invalid — that tests the error path, not the compiler. Deliberate
out-of-bounds access stays as it is (it is defined behaviour under test),
but new constructs must be *correct* uses.

**Acceptance for Phase B.** For each of B1–B4: the generator can emit it
(shown by a seeded run whose output contains it), `./test.sh` stays
green, and a **1,000-seed run reports zero findings** — because a new
generator that immediately "finds" bugs is far more likely to be emitting
illegal Vox than to have found four compiler defects on its first
outing. Any genuine finding is reported to the master with its seed, not
tuned away.

---

## Verification, and the thing that must be true at the end

Every `poc.sh` from the red-team run must **flip to non-zero** against
the fixed tree. That flip is the proof, not a green suite — the suite was
green while all six defects were present. The master re-runs all six
personally, sandboxed, as it did to confirm them.

Findings 03–06's PoCs assert a *gap*, so they flip when the generator
gains the construct. Findings 01–02's PoCs build the fuzzer from `src/`,
so they exercise the patched code directly.
