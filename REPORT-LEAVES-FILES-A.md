# Report — files ledger, batch A (list & number properties)

Worktree `~/scr/english/worktrees/wt-leaves-files`, branch
`feat/ledger-files-a`. vox-fuzz main `e43176f`, manual pinned to Vox
0.4.14 (`4995394`, 5756 lines). Vox `/usr/bin/vox`, `v0.4.14`.

## Rows covered

| ID | claim | leaf | asserts |
|---|---|---|---|
| FIL-10 | `length` is the item count | `gen leaf list properties` | yes |
| FIL-11 | `size` equals `length`, both equal the known count | `gen leaf list properties` | yes |
| FIL-12 | `empty` is true iff no items | `gen leaf list properties` | yes |
| FIL-13 | `first` is the first item | `gen leaf list properties` | yes (populated list only — see caveat) |
| FIL-14 | `last` is the last item | `gen leaf list properties` | yes (populated list only — see caveat) |
| FIL-24 | `even` is true iff even | `gen leaf number properties` | yes |
| FIL-25 | `odd` is true iff odd, and disagrees with `even` | `gen leaf number properties` | yes |
| FIL-26 | `positive` is true iff > 0 | `gen leaf number properties` | yes |

Doc comment on both leaves names its rows (`grep FIL- src/gen_files.vox`
finds them).

## What each leaf emits

**`gen leaf list properties`** (kind 120) — declares two lists every
call: one forced to `[]`, one forced to 1-5 elements of a randomly
drawn type (number, float, text or boolean, via `gen typed literal`,
which delegates to `gen_literals.vox`'s unbounded random spellings).
Which of the two is written first is drawn (`the order draw`). Both
get `length` (FIL-10, against the known count), `size` (FIL-11, against
both `length` and the known count), and `empty` (FIL-12, against the
known true/false). Only the populated one gets `first`/`last` asserted
(FIL-13/FIL-14, against the exact literal text the generator wrote for
that slot); the empty one gets `first`/`last` READ but not asserted
(see the caveat above). All checks reuse the SAME `If … then, Print
"ASSERT …", Exit 95. Print …` shape `gen assert number` / `… true` /
`… false` / `… matches` already establish for buffers.

**`gen leaf number properties`** (kind 121) — declares three numbers
every call: one positive (random magnitude 1..1,000,000), one negative
(same magnitude range, negated), one exactly 0. Which order the three
blocks are written in is drawn, six explicit orderings (the same choice
`gen emit ordered blocks` makes for its own six blocks). Each number
gets `positive` asserted against its known sign (FIL-26), `even`/`odd`
asserted against a `modulo 2 is 0` check computed in the generator
(FIL-24/FIL-25), and a fourth line asserting `odd` disagrees with
`even` on that same reading (FIL-25's own "assert agreement" half).

Both leaves are drawn only at depth 3 (top level), reached at kind 120
and 121 through `gen dispatch leaf` — see `src/gen_core.vox`'s
`( ── files leaves, batch A, 2026-08-28 ── )` block and the depth-3
widening in `gen statement` right above the buffer/value remaps.

## Caveat: first/last on an empty list

LANGUAGE.md's List Properties table (3808-3826, mirrored 2948-2967)
promises `first`/`last` for a populated list; it says nothing about an
empty one, unlike element-by-index access, which the Bounds Checking
paragraph covers explicitly. Hand-verified against 0.4.14: reading
`first`/`last` on `[]` sets the error flag and returns 0 (the same
default-value shape the documented index-out-of-bounds case uses), but
since no line of the manual documents this for these two properties,
`gen leaf list properties` emits the read (crash-safety only) and does
NOT assert a value.

## Hand-verification

`./build/vox-fuzz gen --seed 8283 --count 20 --budget 12 --layout plain
--keep vf_scratch/files/handverify --vox /usr/bin/vox --core
/usr/share/vox/coreasm --out vf_scratch/files/handverify_findings`
(under `systemd-run --user --scope -q -p MemoryMax=3G timeout 300`) —
20/20 compiled, 0 findings; 6 of the 20 programs drew a files leaf.
Read all six; compiled and ran two by hand:

**`seed_8291.vox`** (list properties, one-element list — first and
last coincide):
```
a list called 'the sketchpad' is [-0051.8].
If 'the sketchpad's length is not 1 then, Print "ASSERT FIL-10: expected 1 got {'the sketchpad's length}", Exit 95. Print 'the sketchpad's length.
If 'the sketchpad's size is not 'the sketchpad's length then, Print "ASSERT FIL-11: expected {'the sketchpad's length} got {'the sketchpad's size}", Exit 95. Print 'the sketchpad's size.
If 'the sketchpad's size is not 1 then, Print "ASSERT FIL-11: expected 1 got {'the sketchpad's size}", Exit 95. Print 'the sketchpad's size.
If 'the sketchpad's empty then, Print "ASSERT FIL-12: expected 0 got {'the sketchpad's empty}", Exit 95. Print 'the sketchpad's empty.
If 'the sketchpad's first is not -0051.8 then, Print "ASSERT FIL-13: expected the literal the generator wrote first got {'the sketchpad's first}", Exit 95. Print 'the sketchpad's first.
If 'the sketchpad's last is not -0051.8 then, Print "ASSERT FIL-14: expected the literal the generator wrote last got {'the sketchpad's last}", Exit 95. Print 'the sketchpad's last.
a list called 'the pigeonhole' is [].
If 'the pigeonhole's length is not 0 then, Print "ASSERT FIL-10: expected 0 got {'the pigeonhole's length}", Exit 95. Print 'the pigeonhole's length.
If 'the pigeonhole's size is not 'the pigeonhole's length then, Print "ASSERT FIL-11: expected {'the pigeonhole's length} got {'the pigeonhole's size}", Exit 95. Print 'the pigeonhole's size.
If 'the pigeonhole's size is not 0 then, Print "ASSERT FIL-11: expected 0 got {'the pigeonhole's size}", Exit 95. Print 'the pigeonhole's size.
If 'the pigeonhole's empty is false then, Print "ASSERT FIL-12: expected 1 got {'the pigeonhole's empty}", Exit 95. Print 'the pigeonhole's empty.
```
(NOTE: this generated program declares its `-g "sounding 4"` flag
first, drawn by the manifest — irrelevant to this leaf, run with that
flag to satisfy the argv assertion.) Compiled clean; run with the
required `-g "sounding 4"` argv: no `ASSERT` line printed, program ran
to completion, exit 125 (a drawn `terminate`, not 90-99). Every FIL-10
through FIL-14 line held, including the coincide case (`-0051.8` both
first and last).

**`seed_8285.vox`** (number properties, three signed numbers):
```
a number called satchel is -3699004.
If satchel's positive then, Print "ASSERT FIL-26: expected 0 got {satchel's positive}", Exit 95. Print satchel's positive.
If satchel's even is false then, Print "ASSERT FIL-24: expected 1 got {satchel's even}", Exit 95. Print satchel's even.
If satchel's odd then, Print "ASSERT FIL-25: expected 0 got {satchel's odd}", Exit 95. Print satchel's odd.
If satchel's odd is satchel's even then, Print "ASSERT FIL-25: odd equalled even for satchel", Exit 95. Print satchel's odd.
a number called 'the crate' is 0.
If 'the crate's positive then, Print "ASSERT FIL-26: expected 0 got {'the crate's positive}", Exit 95. Print 'the crate's positive.
If 'the crate's even is false then, Print "ASSERT FIL-24: expected 1 got {'the crate's even}", Exit 95. Print 'the crate's even.
If 'the crate's odd then, Print "ASSERT FIL-25: expected 0 got {'the crate's odd}", Exit 95. Print 'the crate's odd.
If 'the crate's odd is 'the crate's even then, Print "ASSERT FIL-25: odd equalled even for 'the crate'", Exit 95. Print 'the crate's odd.
a number called 'the tally sheet' is 255814.
If 'the tally sheet's positive is false then, Print "ASSERT FIL-26: expected 1 got {'the tally sheet's positive}", Exit 95. Print 'the tally sheet's positive.
If 'the tally sheet's even is false then, Print "ASSERT FIL-24: expected 1 got {'the tally sheet's even}", Exit 95. Print 'the tally sheet's even.
If 'the tally sheet's odd then, Print "ASSERT FIL-25: expected 0 got {'the tally sheet's odd}", Exit 95. Print 'the tally sheet's odd.
If 'the tally sheet's odd is 'the tally sheet's even then, Print "ASSERT FIL-25: odd equalled even for 'the tally sheet'", Exit 95. Print 'the tally sheet's odd.
```
Compiled clean; run with no argv needed for this program: no `ASSERT`
line, ran to completion, exit 233 (a drawn `terminate`). Zero (`the
crate`, exactly 0) read `positive` false and `even` true, matching the
manual's `zero` case for both properties.

## Broken-assertion proof

Same shape as `tests/290_ledger_assertion.vox`: a fixture with a
deliberately wrong FIL-13 expectation
(`vf_scratch/files/broken_fil13.vox`):

```vox
a list called 'the crate' is [42, 7].
If 'the crate's first is not 99 then, Print "ASSERT FIL-13: expected the literal the generator wrote first got {'the crate's first}", Exit 95. Print 'the crate's first.
```

Compiled, run under capture, and pushed through the same three calls
`fuzz gen once` makes on the exit-95 path (`compile vox`, `run program
capturing`, `the assert line in`, `finding save`):

```
compiled: 1
verdict: exit
exit code: 95
detail: ASSERT FIL-13: expected the literal the generator wrote first got 42
finding saved: 1
saved under wrong-value: 1
classification carries the assert line: 1
```

Exit 95, the exact `ASSERT FIL-13: …` line, saved under
`wrong-value/900120/classification.txt` with the detail line intact —
confirms the runner classifies a broken FIL leaf assertion exactly as
PROCEDURE §6 says it must.

## Campaign

```
systemd-run --user --scope -q -p MemoryMax=3G timeout 300 \
  ./build/vox-fuzz gen --seed 13153 --count 200 --budget 12 \
  --layout plain --keep vf_scratch/files/campaign \
  --vox /usr/bin/vox --core /usr/share/vox/coreasm \
  --out vf_scratch/files/campaign_findings
```
`programs: 200  compiled: 200  findings: 0`. 30/200 programs drew
`gen leaf list properties` (kind 120, `FIL-1[0-4]` present); 46/200
drew `gen leaf number properties` (kind 121, `FIL-2[456]` present) —
solid exercise of both new kinds at their 2-in-67 top-level draw odds.

## Invariants delta

`scripts/invariants.vox` has no checked-in wrapper in this repo (only
the `.vox` source), so it was compiled directly:
`VOX_CORE_PATH=/usr/share/vox/coreasm /usr/bin/vox scripts/invariants.vox
-o /tmp/invariants_bin && /tmp/invariants_bin vf_scratch/files/campaign`.

I could not produce a literal diff against a `main` invariants report:
the common brief forbids building or running anything in
`~/scr/english/vox-fuzz` (main, two live campaigns tonight), which is
the only checkout of `main` on this machine, and there is no
checked-in baseline report to diff against either. Best-effort
equivalent instead: the full report (below in full, since it is short)
was read end to end and checked for anything traceable to this batch's
leaves — the FIL-10..14/FIL-24..26 identifiers themselves, `positive`/
`even`/`odd`, and every buffer-pool word the leaves' names came from
(`cupboard`, `workbench`, `pigeonhole`, `satchel`, `the crate`, `the
tally sheet`, …). **None appear.** All 41 findings (threshold 50%) are
pre-existing surfaces this batch never touches - `ASSERT`/`expected`/
`got`/`VAL`/`v1`/`reading` (the value leaves' own vocabulary), `BUF`,
`Parse flags.`, the stdin-read buffer-size template bounds, and so on:

```
invariants: 200 programs in vf_scratch/files/campaign

suspicion  category              finding                                                        citation
100%	fixed-vocabulary	100% (200/200 programs) use the identifier `s`
99%	fixed-vocabulary	99% (199/200 programs) use the identifier `ASSERT`
99%	fixed-vocabulary	99% (199/200 programs) use the identifier `expected`
99%	fixed-vocabulary	99% (199/200 programs) use the identifier `got`
95%	fixed-vocabulary	95% (190/200 programs) use the identifier `VAL`
94%	fixed-vocabulary	94% (189/200 programs) use the identifier `it`
89%	fixed-vocabulary	89% (178/200 programs) use the identifier `v1`
89%	never-exceeded-bound	89% (178/200 programs) template "a number called v# is #." slot 1: never above 7
89%	never-exceeded-bound	89% (178/200 programs) template "a number called v# is #." slot 2: never above 9223372036854775807
80%	fixed-vocabulary	80% (161/200 programs) use the identifier `reading`
78%	fixed-vocabulary	78% (156/200 programs) use the identifier `file`
68%	fixed-vocabulary	68% (136/200 programs) use the identifier `v2`
66%	fixed-vocabulary	66% (133/200 programs) use the identifier `label`
62%	fixed-vocabulary	62% (124/200 programs) use the identifier `out`
58%	fixed-vocabulary	58% (116/200 programs) use the identifier `filled`
57%	fixed-vocabulary	57% (114/200 programs) use the identifier `BUF`
56%	identical-statement	56% (112/200 programs, 112 occurrences): "Parse flags."
56%	fixed-vocabulary	56% (112/200 programs) use the identifier `minus`
55%	fixed-vocabulary	55% (110/200 programs) use the identifier `writing`
54%	fixed-vocabulary	54% (108/200 programs) use the identifier `n`
54%	fixed-vocabulary	54% (109/200 programs) use the identifier `q1s1`
54%	fixed-vocabulary	54% (109/200 programs) use the identifier `q1s2`
54%	fixed-vocabulary	54% (109/200 programs) use the identifier `q1s3`
54%	fixed-vocabulary	54% (108/200 programs) use the identifier `l1`
53%	never-exceeded-bound	53% (107/200 programs) template "a buffer called sb# is # bytes." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "a buffer called sb# is # bytes." slot 2: never above 63
53%	never-exceeded-bound	53% (107/200 programs) template "Read from sin# into sb#." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "Read from sin# into sb#." slot 2: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "Print sb#'s size." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "If sb# is empty then,Print"sb# empty"." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "If sb# is empty then,Print"sb# empty"." slot 2: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "Otherwise,Print"sb# filled"." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "a buffer called sc# is # bytes." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "a buffer called sc# is # bytes." slot 2: never above 8
53%	never-exceeded-bound	53% (107/200 programs) template "Read from sin# into sc#." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "Read from sin# into sc#." slot 2: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "Print sc#'s size." slot 1: never above 7
53%	never-exceeded-bound	53% (107/200 programs) template "Close sin#." slot 1: never above 7
52%	fixed-vocabulary	52% (104/200 programs) use the identifier `be`
50%	fixed-vocabulary	50% (101/200 programs) use the identifier `x`
50%	fixed-vocabulary	50% (101/200 programs) use the identifier `q1s4`

total findings: 41 (threshold 50%, showing top 300)
```

Every one of these is either an existing surface's fixed diagnostic
vocabulary (`ASSERT`/`expected`/`got`, `VAL`, `BUF`) or a pre-existing
bound this batch does not touch (the stdin-read buffer templates, `v1`/
`v2`, `Parse flags.`). This batch's own diagnostic vocabulary (`FIL`)
does not even reach the 41-finding list, let alone the 50% threshold -
consistent with `l1`/`q1s1..4` also sitting well under 100% despite
being genuinely fixed IDENTIFIER SPELLINGS: at a 200-seed, budget-12
campaign, no single leaf's own name or word draws often enough to be
suspicious on its own. **This batch adds no unjustified invariant.**

## Not a candidate: a punctuation error in my own generator code

While designing this batch's block-ordering I hit what looked like a
compiler segfault and wrote it up as a candidate. The master reproduced
it and proved the compiler right, against LANGUAGE.md:154 ("A period
closes the most recently opened clause … and only that one") and
:211-224 ("Closing more than one level: stack periods"). Recorded here
so the mistake, and the rule, both stay visible.

Original (wrong) repro:

```vox
To 'try order' with a boolean called 'first goes first'.
    a list called out is [].
    If 'first goes first' then,
        For each x in [1, 2], append x to out.
    If 'first goes first' is false then,
        For each x in [9, 8], append x to out.
    print "after ifs, before return".
    Return a list, out.

a list called r2 is 'try order' of false.
print r2's length.
```

`For each x in [1, 2], append x to out.` opens two clauses (the outer
`If`, then the `For each`) and my single trailing period closes only
the innermost one — the `For each` — exactly the "one period closes
one level" rule PROCEDURE.md §6a already documents. The outer `If`
stays open, so the *next* `If` line, the `print`, and the `Return` all
get swallowed into its body instead of running as siblings. With
`'first goes first'` true that swallowed body still runs (its own
condition was true), so the first call looked fine by accident. With
it false, the outer `If`'s condition is false, its whole swallowed body
including the `Return` never runs, and the function falls off its end
— which is what actually crashed, not the compiler.

Fixed by stacking a second period (`..`) to close both the `For each`
and the `If` in one place, per LANGUAGE.md:211-224:

```vox
To 'try order' with a boolean called 'first goes first'.
    a list called out is [].
    If 'first goes first' then,
        For each x in [1, 2], append x to out..
    If 'first goes first' is false then,
        For each x in [9, 8], append x to out..
    print "after ifs, before return".
    Return a list, out.

a list called r1 is 'try order' of true.
print r1's length.
print element 1 of r1.
print element 2 of r1.
a list called r2 is 'try order' of false.
print r2's length.
print element 1 of r2.
print element 2 of r2.
```

Compiles clean and runs clean with `..`, both branches, hand-verified
(`vf_scratch/files/probe_double_period.vox`,
`VOX_CORE_PATH=/usr/share/vox/coreasm /usr/bin/vox ... && ./probe_double_period`):

```
after ifs, before return
2
1
2
after ifs, before return
2
9
8
```

`gen_files.vox` still uses the two unconditional helper functions
(`'gen concat two blocks'` / `'gen concat three blocks'`) rather than
switching every call site to `..` — not as a workaround for a compiler
bug (there is none), but because composing several leaf-blocks by
choosing an argument ORDER to a plain function is less fragile to get
right than counting stacked periods across nested clauses by hand, and
it keeps every `If` in this leaf wrapping exactly one plain statement.
The header comment on those two functions has been corrected to say
so — see `src/gen_files.vox`.

## What I could not do

- **first/last on an empty list stays `exercised`, not `verified`, for
  that specific case.** See the caveat above — the manual's List
  Properties table promises a value for `first`/`last` on a populated
  list and says nothing for an empty one. The leaf reads both anyway
  (must not crash) but does not assert, per the brief's own instruction
  for exactly this situation. Recorded here rather than narrowed
  silently: FIL-13/FIL-14 ARE asserted (and `verified`-worthy) on their
  documented case, the populated list.
- **No literal `main` invariants diff.** Explained under Invariants
  delta above — the common brief forbids touching
  `~/scr/english/vox-fuzz` (the only `main` checkout on this machine,
  running two live campaigns tonight), and no checked-in baseline
  report exists to diff against instead. Read the full report by hand
  and confirmed nothing in it traces to this batch (see above) as the
  best available substitute.
- **Both new leaves are depth-3 (top-level) only**, not reachable at
  depth 2/1/0 the way the buffer declaration/properties/fullness leaves
  (100-102) are. Every row this batch covers is nesting-safe by
  construction (the same `If … Exit 95. Print …` shape as 100-102), so
  there is no correctness reason for the restriction — it was a scope
  choice to keep tonight's edit to `gen statement`'s shared depth-3
  draw small (widen one `rng below` bound, add one remap block) rather
  than touch the depth-2/1/0 remaps too, since four workers are editing
  that function in parallel tonight and a smaller diff there is a
  smaller collision surface for the master to merge. Widening the other
  depths is a cheap follow-up, not a defect in what shipped.
- **Reused `gen_buffer_words` rather than a new pool.** Both leaves'
  names come from the existing container-word pool (`gen buffer name` /
  `… reference` / `… property`) rather than a files-specific noun list.
  This reads naturally for a list, less so but still legibly for a
  number (`a number called 'the crate' is 5.`); a dedicated
  number-flavoured pool would read better but needs its own
  disjointness rows in `tests/230_units.vox`, which felt like more
  ceremony than an 8-row batch warranted. Flagged here as a real (if
  small) style compromise rather than left unmentioned.
- **A punctuation bug in my own generator code, not a compiler
  candidate** — see "Not a candidate" above. Caught before it shipped;
  no leaf output was ever affected, so no correction to a row or an
  assertion was needed, only to the block-ordering helper's own
  comment.

## Review round 1

Master accepted the batch in substance; style audit asked for two
renames (`piece` → `'the drawn literal'` in `gen leaf list properties`,
`For each entry` → `For each line` in the two concat helpers, matching
the callers' own `'the lines'` naming). Applied, no emitted output
changes (no golden touched), `./test.sh` re-run green (31/31, citations
0 stale), re-parked to the same patch path.

---
DONE — stopped staged, patch parked
