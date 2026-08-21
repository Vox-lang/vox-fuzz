# The ledger procedure — how LANGUAGE.md becomes the leaf library

**Standing order (Josj, 2026-08-20):** every statement the Vox manual makes
gets a leaf that puts it on trial. The leaf library becomes a one-to-one
mapping of the language rules, and the ledgers are the progress record of
that mapping — and of justifying every invariant the generated programs
show. Every ledger looks the same, is built the same way, and is accepted
by the same gates. `docs/ledger/buffers.md` is the reference instance;
`INDEX.md` lists every section of the manual and where its ledger stands.

This document is the procedure. `CLAUDE.md` is the philosophy it serves;
if the two disagree, `CLAUDE.md` wins and this file is wrong.

---

## 1. Units and files

One ledger per **section** of `../vox/LANGUAGE.md`, as partitioned in
`INDEX.md` (a big chapter is split into two or three ledgers; the line
ranges there are authoritative and are re-pinned whenever the manual's
version changes — a ledger header records the manual version it was
mapped against).

```
docs/ledger/INDEX.md                  every section, its prefix, line range, status, counts
docs/ledger/PROCEDURE.md              this file
docs/ledger/<slug>.md                 one ledger per section  (e.g. buffers.md)
docs/ledger/probes/<slug>/<ID>.vox    one retained probe per hand-verified row
docs/ledger/probes/<slug>/D<n>.vox    one runnable repro per discrepancy
docs/ledger/briefs/map-section.md     the brief a mapping worker is spawned with
docs/ledger/briefs/build-leaves.md    the brief a leaf-building worker is spawned with
```

Row IDs are `<PREFIX>-NN` with the prefix fixed per section in `INDEX.md`
(`BUF-17`, `LST-04`, `THG-22`). IDs are **never renumbered or reused**:
a claim that turns out to be a duplicate is marked `folded into X`, a
claim that disappears from the manual is marked `withdrawn (manual vN)`.
Leaves, findings, probes and the invariant report all cite these IDs, so
they have to stay stable.

## 2. What a claim is

A claim is any statement the manual makes that could be false:

- every row of every property/keyword table (each row claims what a
  property returns or what a keyword does);
- every bullet under a "Behavior:" / "Features:" heading;
- every sentence asserting what happens ("data is preserved up to…",
  "positions are 1-indexed", "the old buffer is freed");
- every code example — it claims that code compiles and does what the
  surrounding prose says; the worked example is a **composite** row
  whose sub-claims are also rows of their own;
- every stated limit or diagnostic ("this is a compile error", "at most
  N", "reserved word").

A claim about an **implementation detail** that is not observable from a
Vox program (memory freed, "allocated in place") is still a row — status
`not assertable`, with the reason — so the ledger is complete against
the text even where the fuzzer cannot reach.

**This is a gap analysis, not a rewrite.** The `existing leaf` column
names what already emits the construct. Where a leaf covers a claim only
partially, the row says precisely what is missing.

## 3. The row — fixed columns, in this order

| column | meaning |
|---|---|
| `id` | `<PREFIX>-NN` |
| `line` | LANGUAGE.md line(s) at the manual version in the header |
| `claim` | the claim in one sentence, in the mapper's words |
| `leaf needed` | what a leaf must emit to put the claim on trial |
| `assertable?` | can the **generator** predict the result, and exactly what assertion it would emit (`If b's size is not 4 then, Exit 95.`). If not, why not. |
| `existing leaf` | the leaf(s) that already emit the construct, or `none` |
| `status` | `todo` / `exercised` / `verified` / `not assertable` / `folded into X` / `withdrawn` |
| `verified by` | blank until a campaign ticks the row — then `vox <version> · vox-fuzz <commit> · seeds <range>` |

Statuses, precisely:

| status | meaning |
|---|---|
| **todo** | nothing emits the construct |
| **exercised** | a leaf emits the construct; the program must not crash. This tests memory safety only. The floor. |
| **verified** | a leaf emits the construct **and** asserts its documented result, so a wrong answer is a finding |
| **not assertable** | unobservable from inside Vox; the row exists for completeness and says why |

A row is `exercised` or `verified` on the strength of a **leaf in
`main`**, not a leaf in a branch, and `verified by` is filled only after
a campaign has run it (see §7).

## 4. Hand-verification and retained probes — non-negotiable

Every row is run against the real compiler **before it is written**.
"The manual says X" is worth much less than "the manual says X, and here
is the five-line program proving the compiler agrees." The probe is
**kept**, not described:

```
docs/ledger/probes/<slug>/<ID>.vox
```

Probe format — a complete program, first lines a comment recording what
the compiler **actually** printed, and the command used:

```vox
(BUF-17 — shrinking below current length truncates the data.
 Also covers: BUF-16.
 Ran: VOX_CORE_PATH=../vox/coreasm ../vox/target/release/vox BUF-17.vox -o p && ./p
 expected output:
   4
   ABCD
)
a buffer called b is 8 bytes in size.
append "ABCDEFG" to b.
shrink b to 4 bytes.
Print b's size.
Print b.
```

Always with `VOX_CORE_PATH` pinned to the repo's `coreasm` — without it
the installed runtime is silently tested instead
(`docs/DECISIONS.md`). `docs/check-probes.sh` re-runs every probe under a
directory and diffs against the recorded output; a ledger whose probes do
not re-run clean is not accepted.

Why this is the rule: on 2026-08-20 the master made three confident
wrong claims about buffers in an hour (0-indexed; fixed `size` equals
capacity; `Set byte` works on a fresh buffer). Any of them written into a
leaf would have been a false-finding factory at scale. The probe is the
only thing that stops a misreading becoming an oracle.

## 5. Discrepancies — record, do not adjudicate

When the compiler disagrees with the row, or the manual is ambiguous,
or two parts of the manual disagree with each other, the mapper writes a
**Discrepancies** section at the end of the ledger: numbered, with a
minimal repro (also saved as `probes/<slug>/D<n>.vox`), the lines cited,
and **the strongest reading under which the compiler is correct**. The
mapper does not file bugs and does not decide the compiler is wrong.

Adjudication is a separate step, owned by the master and the human:

1. the master runs the `vox-language-lawyer` agent on every discrepancy
   (it reproduces, cites, argues for the compiler, and gives a verdict:
   `COMPILER BUG` / `MANUAL BUG` / `MISREADING` / `UNDOCUMENTED-BUT-CONSISTENT`);
2. the human blesses or overrules each verdict;
3. outcomes are routed: a compiler bug is filed in
   `vox/docs/BUGS_FOUND.md` (with the ledger ID in the entry); a manual
   bug becomes a LANGUAGE.md PR; a misreading fixes the ledger row;
   undocumented-but-consistent becomes a LANGUAGE.md PR *and* a row whose
   claim is the now-documented behaviour;
4. the discrepancy entry gets a `Resolution:` line naming the outcome and
   the bug number / PR.

A ledger with open discrepancies can still have leaves built for every
**other** row; rows that depend on an open discrepancy stay `todo` with
`blocked on D<n>` in `verified by`.

## 6. Building the leaves

One leaf-building batch is **at most eight rows** of one ledger, scoped
in a brief generated from `briefs/build-leaves.md`. The worker:

- writes each leaf in the section's own `src/gen_<surface>.vox` file;
- gives the leaf a doc comment that names the ledger IDs it covers
  (`(BUF-15, BUF-16, BUF-17: resize keywords, data preservation,
  truncation)`) — the comment is how the ledger is later tied back to
  code, and `grep` on an ID must find its leaf;
- makes every assertable row **assert**: the generator knows what it
  emitted, so it emits the check, and a failed check exits with the
  reserved code **95** after printing one line
  `ASSERT <ID>: expected <x> got <y>` — the runner classifies exit 95
  as a `wrong-value` finding and carries that line as the detail. 91–94
  remain the argv assertions; 95 is the ledger's; nothing generated may
  exit 90–99 for any other reason;
- hand-verifies the leaf's own output once (compile and run a few
  emitted programs by hand, in a `vf_scratch/` directory, before trusting
  the campaign) — the same rule as §4, because a leaf is a probe that
  writes probes;
- **Process-control and privileged syscalls: emit the ones the kernel
  refuses, constrain the ones that can take effect (Josj, 2026-08-20).**
  Two classes on the `PRC-*` surface (Directories/Mount/Process Control,
  LANGUAGE.md 3658–3999):
    - **Safe to emit as-is** because an unprivileged process cannot
      perform them — the kernel returns `EPERM` and nothing happens, which
      is itself a valuable thing to fuzz (the syscall codegen and the
      error-flag path, for free): `mount`, `unmount`, `pivot_root`,
      `reboot`, `shutdown`, `halt`, device-node creation (`mknod`), and
      the rest of the `CAP_SYS_ADMIN`/`CAP_SYS_BOOT` family. **Caveat that
      is load-bearing: these are safe ONLY because the fuzzer runs
      unprivileged.** The harness must never run a generated binary as
      root; a generated `reboot` under root reboots the machine.
    - **Need a constraint** because they CAN take effect for a normal
      user: `Execute` (runs an arbitrary program — think carefully:
      restrict to a harmless allowlist such as `/bin/true`, `/bin/false`,
      `echo`, and/or run inside the sandbox, never a random command line);
      `Send signal` / kill (can hit any same-uid process, including the
      fuzzer or the master's own sessions — target only the program's own
      children, its own pid, or a reserved-invalid pid, never an arbitrary
      one); and anything that creates/unlinks/symlinks in the filesystem
      (confine to the per-run sandbox, same rule as file opens above).
- **File opens draw from a fixed allowlist — never a random path.** Josj,
  2026-08-20: the fuzzer must not open programs at random paths; instead a
  generated program may open ONLY one of a small, fixed set of safe
  targets, chosen at random from the set (the randomness is in *which*
  target and in the *bytes inside* it, never in the path string):
    1. one of the harness's **per-run sandboxed `/tmp` files**, created and
       pre-filled with **random binary data** before the run and removed
       after — these give a read something real (and non-blocking) to
       consume and a write somewhere safe;
    2. **file descriptors 1, 2, 3** (the harness sets up fd 3);
    3. a **safe device node**: `/dev/null`, `/dev/random` (and the like).
  This is what unblocks the read half of file I/O — reads now come from a
  sandboxed `/tmp` file or `/dev/random`/`/dev/null`, not the fuzzer's own
  inherited stdin (`docs/FUZZER_DEFECTS.md` defect 7). Never assemble a
  path from random bytes and never point outside this set. The FILES
  surface (`FIL-*`) is exercised against these targets — seek, read,
  write, the error flags, the properties. A row whose claim can only be
  shown by opening something outside the set stays `todo`/`not
  assertable` with that reason;
- **varies everything no rule pins**: counts, names, sizes, orderings,
  which spelling of a synonym, whether the optional form appears. A
  leaf that always emits four of something is asserting a rule nobody
  wrote (`CLAUDE.md` — undeclared rules are the real enemy);
- writes Vox that reads aloud as English (`vox/docs/STYLE.md`): names
  are the thing's true name; `i`, `tmp`, `buf`, `n` are banned at any
  length; generated programs are held to the same standard as the
  generator, since they are what the invariant report reads;
- adds or extends a `tests/NNN_*.vox` unit for each leaf (the
  generator's own gate, `./test.sh`);
- does not commit when the signing key is away; reports what it could
  **not** do rather than narrowing the scope silently.

### 6a. Lessons from building a batch by hand (master, environment batch A, 2026-08-21)

The master built one batch under its own brief, as a worker, to feel
where the procedure bites. These are the places it bit; each is now a
rule, so the next worker does not pay for it twice.

- **When the generator does not control the input, assert agreement.**
  A program cannot know what `environment's "HOME"` holds, but it can
  know that two readings of one value agree: the same property read
  into a `text` and into a `buffer` must have the same size and
  emptiness, `count` cannot say "none" while `empty` says "some", a
  predicate read twice cannot flip. Agreement between the receiving
  types the manual allows is a real oracle, and it is exactly the one
  that finds a copy path that lies (environment D1 was found by this
  assertion from the manual alone, before the discrepancy was read).
- **A `text` has no size property.** `'s size`/`'s length` are for
  buffers, lists, maps and files. To measure a text, declare a buffer
  from it (`a buffer called 'the copy' is 'the text'`) and read the
  buffer's `size`. Budget for the extra declaration in every assertion
  that compares text values.
- **One period closes one level — never nest an `If` inside an `If` on a
  single leaf line.** `If a then, If b then, X.` leaves the outer `If`
  open and swallows everything after it; in a generator function it
  turns a loop into a hang (it did). Write flat conditions with `and`,
  one `If` per line, each closed by its own period and followed by a
  plain statement that takes the join's punctuation — the shape
  `gen_buffers.vox`'s `gen assert number` uses.
- **A boolean cannot be declared from a comparison.** `a boolean called
  x is n is 0.` does not parse. Declare it `false` and set it in an
  `If`, or put the comparison in the `If` that uses it.
- **Assertion helpers and name allocators are generic — reuse, do not
  copy.** `gen assert number` / `… matches` / `… true` / `… false` and
  the word-vocabulary allocator in `gen_buffers.vox` are plain text
  helpers despite their names; call them from any surface. (Moving them
  into `gen_core.vox` under surface-neutral names is owed.)
- **Register through the surface's existing kind where one exists.** If
  the surface already has a drawn kind (environment had 22 and 27), make
  that kind a dispatcher over the new leaves instead of touching the
  band/remap machinery in `gen statement` — the closer-safe leaves
  behind the closer-safe kind, the loop/handler-bearing ones behind the
  top-level-only kind. New kinds are for new surfaces.
- **Loops inside a leaf are one line, top level only.** A `For each`/
  `While` split across lines takes a period from `gen join lines` on its
  first line and closes with an empty body. One line, internal period
  closing only the inner clause, and the leaf goes behind a
  top-level-only kind.
- **Measure sameness on `--layout plain`.** `scripts/invariants` compares
  raw lines and the layout randomiser hides sameness from it; a campaign
  run for the invariant report uses `--layout plain`.
- **Never print a raw host value.** Environment contents, paths, argv
  beyond what the generator chose: print sizes, `empty`, `as a boolean`.
  A raw value printed once landed in a checked-in fixture.
- **Probe the exact line shape you will render, not the idea of it.**
  The probe that pays is the one-line rendering with its comma/period
  punctuation, run under both `gen join lines` modes — the hang above
  and the period-count slip (`add 1..` rendered as `add 1...`) both
  passed the "idea" probe and failed the rendered one.

## 7. Campaign, invariant report, and ticking rows

After a batch lands on a branch, the master (not the worker):

1. builds the branch in an isolated extract and runs `./test.sh`;
2. runs a campaign that can reach the new leaves (`vox-fuzz gen --seed
   … --count ≥ 200 --keep <corpus>`), and records it in `SEEDS.md`;
3. runs `scripts/invariants` over the kept corpus and diffs against the
   report from `main`: **the batch must contribute no new unjustified
   invariant**. Every new entry is either cited (LANGUAGE.md line + the
   ledger ID that justifies the sameness) or is a generator defect to
   fix before acceptance;
4. triages findings: generator bugs are fixed; anything that may be a
   compiler bug or a manual ambiguity goes into the ledger's
   Discrepancies section with a minimal repro and the exact claim it
   contradicts, for §5;
5. after merge to `main`, flips each row's `status` to `exercised` or
   `verified` and fills `verified by` with the campaign reference;
   updates the counts in `INDEX.md`.

The honest measure of progress is two numbers per ledger, both in
`INDEX.md`: rows verified / rows total, and unjustified invariants
remaining. A clean campaign with two hundred unjustified invariants
means very little.

## 8. Justified invariants

The invariant report (`scripts/invariants <corpus>`) is the proof that
no rule is hidden. Each ledger ends with a section **Invariants this
section justifies**: one line per sameness the report shows that the
manual actually requires, with the LANGUAGE.md line and the row ID:

```
- blank line after every function definition — LANGUAGE.md:76, FUN-03
- buffer byte index never 0 — LANGUAGE.md:3251, BUF-19
```

The report's `citation` column is filled from these lines. An invariant
that no ledger justifies is a defect, tracked in `docs/FUZZER_DEFECTS.md`
until the generator stops producing it.

## 9. Acceptance gates — what the master checks, in order

**A ledger is accepted when**
- [ ] every claim in the line range has a row (walk the manual text
      alongside the table; the master spot-checks ten lines at random);
- [ ] every hand-verified row has a probe file and `docs/check-probes.sh`
      re-runs the directory clean;
- [ ] every discrepancy has a `D<n>.vox` repro and a pro-compiler reading;
- [ ] the `assertable?` column names a concrete assertion or a concrete
      reason;
- [ ] `existing leaf` was checked by `grep` on the accessor/keyword, not by
      leaf name;
- [ ] the ledger header records the manual version and line range.

**A leaf batch is accepted when**
- [ ] `./test.sh` is green in an isolated extract;
- [ ] the campaign ran and is in `SEEDS.md`;
- [ ] the invariant diff shows no new unjustified invariant;
- [ ] every assertable row in the batch asserts (exit 95 path proven
      once by hand — break a probe and watch it become a finding);
- [ ] `vox-style-auditor` passes the diff (names, read-aloud, comments);
- [ ] the master has read the diff, including the edge cases the tests
      do not reach;
- [ ] the rows are flipped and `INDEX.md` counts updated in the same PR.

## 10. Roles

| who | does | never does |
|---|---|---|
| **mapping worker** | enumerates claims, runs probes, writes the ledger and probes | modifies `src/`; decides a discrepancy; commits unsigned |
| **leaf worker** | builds ≤ 8 rows' leaves with assertions and tests; hand-verifies emitted programs | adjudicates the language; touches other surfaces' files; widens or narrows scope silently |
| **master** | reviews the map before any code; writes briefs; verifies in isolation; runs campaigns and the invariant diff; triages; runs the lawyer; flips rows | trusts a report it has not re-run; files a compiler bug without the lawyer and the human |
| **vox-language-lawyer** | adjudicates discrepancies with repro + citation + pro-compiler reading | edits either repo |
| **human (Josj)** | blesses verdicts; decides anything that changes the language or the manual | — |
