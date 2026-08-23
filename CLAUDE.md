# vox-fuzz — how this project generates programs

**Read this before touching the generator.** It is the standard all
generator work is held to, set by Josj on 2026-08-20 after reading forty
generated programs and finding they were all the same shape.

It is short on purpose. **If a decision about the generator is not
answered here, the answer is almost always "make it random".**

vox-fuzz is a fuzzer for the Vox compiler, written in Vox. It generates
programs, compiles them, runs them, and reports crashes, hangs, wrong
answers and nondeterminism.

---

## The mental model

> Start with a random token generator — literally noise, `cat
> /dev/random`. Then add language rules one at a time. A layer between
> the noise and the output enforces them. Gradually, as rule follows
> rule, the output starts to look like Vox and starts to compile.
>
> **Unless something is specified as a rule, it is random.**
> — Josj, 2026-08-20

Three parts, and the third is the one that gets forgotten:

1. **The default is noise.** Not "sensible code with some randomness
   sprinkled on".
2. **A rule layer sits between the noise and the output**, enforcing
   what the language actually requires.
3. **Anything no rule covers stays random.** Every dimension the rules
   do not pin down must vary.

### This is a specification, not an implementation strategy

We do not have to literally pipe `/dev/random` through a filter and wait
for the compile rate to climb from zero. We have to build something that
**behaves as if that is what it is.** From the outside — which is the
only place it matters — those are the same thing.

The practical consequence: every dimension not pinned by a declared rule
must vary. How you achieve that is an implementation detail. Whether you
achieved it is measurable, and is measured (see *Enforcement*).

---

## The principle that follows from it

> **There are no repeatable patterns that are not specified as hard
> language rules in the book.** If a non-random repeatable pattern
> emerges, there must be an example in the rule book that justifies it.
> — Josj, 2026-08-20

The burden of proof is inverted from the usual. **Variation is the
default; SAMENESS is what needs a citation.**

Worked examples:

| Pattern | Verdict |
|---|---|
| a blank line after every function definition | **justified** — LANGUAGE.md requires it |
| exactly four flags in every program | **defect** — no rule says four, or any number |
| `Parse flags.` in every program | **defect** — the manual says it is optional (§3) |
| flags always contiguous | **defect** — the manual explicitly permits code between schema declarations (§4), and the compiler accepts it |
| buffer index starts at 1 | **justified** — LANGUAGE.md:3591 says 1-indexed |

A pattern with no citation is not a tuning opportunity. It is a bug in
the rule layer: something is being enforced that nobody declared.

### Undeclared rules are the real enemy

Today's leaves have rules baked into them **invisibly**. A leaf that
emits three flags is silently asserting a rule — *"programs have three
flags"* — that nobody wrote down and the manual does not contain. There
are dozens of these, hidden in the shape of each leaf.

The work is dragging every one into the open, checking it against the
manual, and either declaring it as a real rule or deleting it.

---

## What the generator is FOR

Vox promises **memory safety**: no program, however stupid, and no
input, however hostile, should segfault or corrupt memory.

That reorders everything:

- **Every signal death is a top-severity finding.** Not one category
  among four — a broken promise about the language's headline property.
- **Nonsensical code is the point, not a compromise.** A fuzzer that
  only writes sensible buffer code tests the part of the language that
  was never in danger. Read past the end, write to a closed handle,
  index with a negative, resize to zero and then read: all legal Vox,
  all must not crash.
- **Arithmetic is nearly worthless to us.** Integers cannot violate
  memory safety. A campaign full of integer statements is a campaign
  that cannot find the thing we care most about — and for a long time,
  that is exactly what our campaigns were.
- **Buffers, files, `.lib`, process control and the `value` type are
  where the promise lives**, so that is where generation effort goes.

The invariant is unchanged: a generated program must be **legal Vox that
should compile and run**. "Legal" and "sensible" are different bars, and
we want the first without the second.

---

## What counts as covering a claim

The leaf library must become a one-to-one representation of
LANGUAGE.md: **every claim the manual makes needs a leaf that puts it on
trial.** Two distinct levels, and the ledger tracks them separately:

| Level | Meaning |
|---|---|
| **exercised** | the construct is emitted and the program must not crash. Tests memory safety. The floor. |
| **verified** | the construct is emitted AND its documented result is asserted, so a wrong answer is caught |

Verification is possible more often than it looks, because **the
generator controls the inputs and therefore knows the answer.** It
appended 11 bytes and shrank the buffer to 4; the manual says shrinking
truncates; so it can emit `If b's size is not 4 then, Exit 71.` That is
an oracle with no reference implementation, and it works for buffer
sizes, list lengths, map lengths, capacities, `empty`/`full`, bytes it
just wrote, and conversions it can compute itself.

This is the same trick as the argv assertions, which are already live: a
program asserts its flags parsed to what the generator passed, and exits
with a distinct code when they did not.

### The danger, stated plainly

An assertion encodes **our reading of the manual**. A misreading becomes
a false-finding factory that looks exactly like a real bug. On
2026-08-20 the master made three confident wrong claims in about an
hour — that buffer indexing was 0-based, that a fixed buffer's `size`
was its capacity, and that `Set byte` worked on a fresh buffer. All
three were wrong, and any of them written into a leaf would have
generated convincing nonsense at scale.

Therefore: **hand-verify every claim against the real compiler before
you encode it.** Write the five-line program, compile it, run it, and
record what actually happened. The ledger records the probe, not just
the citation. A row saying "the manual says X" is worth much less than one
saying "the manual says X, and here is the five-line program proving the
compiler agrees."

### When an assertion fails, there are three possibilities

All three are useful, and **none of them is decided by a worker**:

1. the compiler is wrong — a bug
2. the manual is ambiguous — also a bug, and a nastier one, because it
   is invisible until two readers disagree
3. we misread it — cheap to fix, and it improves the ledger

**Record discrepancies with a minimal repro and stop.** Do not file
compiler bugs and do not decide the compiler is wrong — construct the
reading in which it is right, see whether that holds, and hand both to a
human. Adjudicating the language is not a worker's job.

---

## Enforcement

Undeclared rules can hide in source. They cannot hide in a corpus.

`scripts/invariants` takes a directory of generated programs and reports
everything that does **not** vary: identical lines, identical counts,
fixed orderings, never-exceeded bounds, fixed vocabulary. Every entry
demands either a LANGUAGE.md citation or a fix.

That report is the acceptance test for generator work: **your surface
contributes no unjustified invariant.**

It will be long at first, and most entries will be real defects rather
than noise. That is the point. For the foreseeable future the honest
measure of progress is **the invariant list shrinking** — not campaigns
coming back clean. A clean campaign with two hundred unjustified
invariants means very little, which is roughly where this project sat
for its first months.

---

## The working loop

The procedure in full — files, the fixed row schema, the status ladder,
retained probes, discrepancy adjudication, the leaf-building rules, the
campaign-and-invariant gate, and the acceptance checklists — is
`docs/ledger/PROCEDURE.md`. `docs/ledger/INDEX.md` lists every section of
the manual and where its ledger stands. Every ledger looks like
`docs/ledger/buffers.md`; every section is mapped the same way. In brief:

1. A worker maps one LANGUAGE.md section to a ledger of claims — as a
   **gap analysis**, marking what existing leaves already cover.
2. The master reviews the map before any code. A wrong map poisons
   everything downstream.
3. A small batch of leaves, each hand-verified against the compiler as
   it is written.
4. A campaign, plus the invariant report.
5. The master triages: generator bugs get fixed; anything that might be
   a compiler bug or a manual ambiguity goes to the human with a minimal
   repro and the exact claim it contradicts.
6. The human adjudicates. Rows are ticked off. Next batch.

### Build on what exists

There is already real coverage — lists, maps, things, grid expansion,
flags, format strings, timers, base conversion, deep expressions, loop
control, error handling, arguments, environment, argv, stdin, file I/O.
All of it campaign-clean and hand-verified.

**This is a gap analysis, not a rewrite.** Skip claims that existing
leaves already cover. Where a leaf covers a claim partially, say
precisely what is missing rather than starting again.

---

## Snapshot — 2026-08-22

*This section dates quickly and is not an instruction. Everything above
it is.*

All 26 sections of LANGUAGE.md are now mapped (`docs/ledger/INDEX.md`
has the full table): **1380 claims, 365 exercised, 10 verified**.
Verified is the number that matters and it is still barely off the
ground — ten rows, all in `arguments.md` (4) and `environment.md` (6).
Almost everything else that compiles is `exercised` only: a leaf emits
the construct and the program must not crash, but nothing checks the
construct produced the *right* answer. Closing that gap — not finding
more sections to map — is where the next phase of work belongs.

The ledgers are pinned to **Vox 0.4.9** (5327 lines, vox `4b77934`), as
of a full hand re-derivation of every citation on 2026-08-22. That pass
also re-ran every retained discrepancy probe against the live 0.4.9
binary; a substantial fraction of the discrepancies recorded since
project start have since been resolved, by compiler fixes and by manual
corrections both — the compiler and the manual each moved while this
project wasn't looking, and neither direction can be assumed without
re-running the probe. Buffers itself, the section this file's first
snapshot singled out as mattering most, now stands at **2 of its 3
original discrepancies resolved**:

- **dynamic buffer capacity is still open** — the manual says zero, the
  compiler's own warning says zero, `capacity` still reports 4096, and
  no fix number exists as of today. This is a design question for
  Josj (eager allocation vs. lazy), not a bug either side can just fix.
- **`type` on a buffer is resolved** (vox #42, PR #189) — a sized
  buffer now correctly reports `Buffer (static)`, matching a
  string-initialised one; `BufferDecl` simply never registered
  `declared_types` before.
- **the byte read/write bounds-check split is resolved** — not by a
  compiler change, but by the manual: PR #189 documented the rule
  (writes 1..capacity extend size, reads 1..size, 0 is always out of
  bounds) instead of leaving it to be reverse-engineered from a worked
  example.

The pattern worth carrying forward: most discrepancies this project
finds are not permanent. Re-probe them before treating an old "not
filed, awaiting Josj" note as still true — `docs/ledger/INDEX.md`'s
per-section "open discrepancies" column is the fast way to see what's
still actually open today, and each ledger's own Discrepancies section
has the full resolution history for the ones that aren't.
