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
