# Report — Files ledger, leaf batch B (file-handle properties, appending, Read line)

Worktree `wt-leaves-filesb`, branch `feat/ledger-filesb-a`, base main `e43176f`.
Ledger `docs/ledger/files.md`, prefix `FIL`. Brief:
`brief-leaves-files-b.md` + the two common briefs (2026-08-28, 2026-08-29).

## Rows covered

Seven new leaves in `src/gen_files.vox`, covering nine row IDs (the brief's
"eight rows" bullets combine FIL-03 into FIL-04's leaf and FIL-05 into
FIL-06's, matching how the buffers batch A leaves already bundle several
row IDs into one open where they share a handle):

| kind | leaf | rows | asserts | line |
|---|---|---|---|---|
| 122 | `gen leaf file size` | FIL-01 | yes — size 0 before write, exact byte count after | `src/gen_files.vox:354` |
| 123 | `gen leaf file descriptor` | FIL-02 | yes — descriptor ≥ 3 | `src/gen_files.vox:387` |
| 124 | `gen leaf file readable writable` | FIL-03, FIL-04 | yes — readable/writable match the drawn mode (reading/writing/appending) | `src/gen_files.vox:415` |
| 125 | `gen leaf file times` | FIL-05, FIL-06 | yes — modified/accessed ≥ 1 and ≤ `current time's unix` | `src/gen_files.vox:468` |
| 126 | `gen leaf file permissions` | FIL-07 | yes — permissions is a Number within 0..511 (0..0777); see Review round 1 below | `src/gen_files.vox:502` |
| 127 | `gen leaf file appending` | FIL-40 | yes — size is N after the first write, N+M after appending M | `src/gen_files.vox:528` |
| 128 | `gen leaf read line replaces` | FIL-46 | yes — post-read size is exactly line-length+1, not seed+line+1 (also incidentally exercises FIL-53, newline retention, for free) | `src/gen_files.vox:573` |

Kind 129 (raw 97 of the reserved 90-97 span) is unused — seven leaves
covered the nine rows without needing an eighth. Free for the master to
use if a future row wants it.

Every leaf: the D16 guard (`gen_does_file_io` false, or `gen_scratch_flag`
empty → stand aside via `'gen leaf print'`, never build a path), targets
only a file it creates itself inside `{gen_scratch_flag}/...` (the run's
own scratch directory — never a path the generator assembled outside it,
never `/dev/stdout`), uses vocabulary names from `'gen buffer name'` /
`'gen buffer reference'` / `'gen buffer companion'` (no letter+counter
names), and asserts via `'gen assert number is'` / two new helpers this
batch adds (`'gen file assert at least'`, `'gen file assert range
quietly'`) reusing `'gen buffer slot of'` for the "got" value in failure
messages. On a failed assertion: `ASSERT <ID>: expected <x> got <y>` then
`Exit 95.`, the reserved ledger-assertion exit code.

## A real defect this batch found in itself: nondeterministic output

First version of FIL-05/FIL-06 used the generic `'gen assert number is'`
family, whose success path prints the raw subject value — fine for a
deterministic subject (a size, a descriptor), wrong for a wall-clock
timestamp. A 200-program campaign (seed 5001) caught it within 20
programs as a `nondeterministic` finding: the file's `modified`/`accessed`
legitimately ticked a wall-clock second between the oracle's two
back-to-back runs of the identical binary, so the two runs' stdout
differed by one second on that one line. Not a compiler bug — a bug in
this leaf, found by the exact process CLAUDE.md describes ("we can spot
and fix errors later").

Fix: a new helper, `'gen file assert range quietly'` (`src/gen_files.vox`,
next to `'gen file assert at least'`), checks both bounds but prints a
fixed marker (`"FIL-05 in range"`) on success instead of the timestamp —
the same tradeoff `'gen leaf timer and clock'` (`src/gen_misc.vox`)
already makes for the identical reason. Re-ran the same seed after the
fix: 0 findings, and hand-verified the emitted lines twice back-to-back
(1.2s apart, enough to cross a second boundary) with identical output
both times. `docs/ledger/probes/files/FIL-06.vox`'s header records both
the failure and the fix.

## Tests

`tests/380_gen_files_b.vox` + `.expected` (test numbers 380-389 allotted;
only 380 used). Calls each leaf directly off a pinned rng seed, dumps the
rendered source (both `nested` forms), and checks the file-io-not-
committed stand-aside path for all seven leaves, the same shape as
`tests/300_gen_buffers_a.vox`.

`tests/040_gen.expected` regenerated (per common-brief item 3) — the
local depth-3 draw widening (below) shifts the rng stream for every
seeded program in that golden. No output difference attributable to my
leaves' own logic; diffed clean against the driver before and after the
citation/naming cleanup passes.

## Registration in `src/gen_core.vox`

One contiguous block in `'gen dispatch leaf'`, kinds 122-128, right after
the existing buffer-band registrations (104) and before the values band
(140), matching where the pending merge's own files-batch-A comment
already said batch B would continue from. `git diff src/gen_core.vox`:

```
+    ( ── files leaves, batch B, 2026-08-29 ── )
+    (FIL-01, FIL-02, FIL-03, FIL-04, FIL-05, FIL-06, FIL-07, FIL-40,
+     FIL-46, in the 120-139 span the reservation above set aside for
+     this surface - continuing from 122, since 120-121 belong to batch A.
+     Drawn only at depth 3 ...)
+    If kind is 122 then,
+        'gen leaf file size' of indent and nested.
     ... (through 128) ...
```

Separately, a **local-only** widening of `'gen statement'`'s depth-3 draw
(to reach these kinds for my own campaign): raw span **90-96**, offset
**+32**, landing on kinds **122-128**. Bounded on both sides against the
raw value (per the common brief's warning: an unbounded lower bound on
the pre-existing 50-64→+90 remap would silently re-remap 90-96 too and
empty the values band). Marked in a comment as discardable — the master
throws this hunk away at merge and keeps only the registration block
above, combining it with the other three batches' own spans the same way
the pending `leaves-merge-2026-08-29.patch` already does for buffers/
things/flow batch A.

## Two hand-verified samples (real campaign programs, not synthetic)

Both compiled from the 200-program campaign corpus (seed 5001,
`--layout plain`), run under `timeout 20`, with the program's own
required flags reconstructed from its embedded `Exit 91/92` argv
assertions.

**seed_5015.vox** (FIL-40, scratch flag `callsign`):
```
$ echo "some stdin bytes" | timeout 20 ./prog5015 --callsign /tmp/scratch
...
184
339
339
...
EXIT=6
```
`184` (first write's size), `339` twice (size after appending, then size
on reopen for reading) — no `ASSERT` line, exit 6 is the program's own
`Terminate 6.`, not a ledger exit code.

**seed_5032.vox** (FIL-46, scratch flag `depot`, required `--legend
"cairn 5" --coupon 4`):
```
$ timeout 20 ./prog5032 --depot /tmp/scratch --legend "cairn 5" --coupon 4
...
11
12
...
EXIT=0
```
`11` (pre-seeded buffer size), `12` (post-`Read line` size — the seed
line was `ajn82702sht\n`, 12 bytes with the newline; had `Read line`
appended instead of replaced, this would have read 23) — no `ASSERT`
line, clean exit 0.

## Broken-assertion proof (exit 95 path)

Done individually for every row via the retained probes (each has a
"then deliberately broken" section in its own header, run and confirmed):
`FIL-02.vox` (FIL-01's before-check), `FIL-04.vox` (FIL-04's writable
check), `FIL-06.vox` (FIL-06's lower bound, post-nondeterminism-fix
shape), `FIL-07.vox` (permissions), `FIL-40.vox` (final size check),
`FIL-53.vox` (FIL-46's replace-not-append check). Every one printed
`ASSERT <ID>: expected <x> got <y>` and exited 95.

## Campaign, seeds, invariants delta

```
mkdir -p vf_scratch/filesb_campaign
systemd-run --user --scope -q -p MemoryMax=3G timeout 300 \
  ./build/vox-fuzz gen --seed 5001 --count 200 --layout plain \
  --keep vf_scratch/filesb_campaign \
  --vox /usr/bin/vox --core /usr/share/vox/coreasm --out /tmp/filesb_findings
```
`programs: 200, compiled: 200, findings: 0` (after the nondeterminism
fix — see above for the one finding the first run turned up and how it
was resolved).

Coverage in the 200-program corpus: FIL-01×9, FIL-02×10, FIL-03/04×6,
FIL-05/06×11, FIL-07×10, FIL-40×9, FIL-46×10 programs.

Baseline: `git archive e43176f | tar -x -C <extract>`, built there, same
`--seed 5001 --count 200 --layout plain`, `findings: 0`. `scripts/
invariants` over both corpora, diffed by key (category + finding text,
percentages and per-corpus occurrence counts stripped):

- **No new invariant traces to this batch's own constructs.** Grepped
  the branch report for every distinguishing word this batch introduces
  (`descriptor`, `permission`, `appending`, `modified`, `accessed`,
  `in range`, and the specific vocabulary words these leaves drew —
  `toolbox`, `waybill`, `notebook`, `dispatch note`, `pantry`,
  `greeting`) — zero hits at the 50% threshold.
- Every line that differs between the two reports is one of: (a) the
  same pre-existing `sin#`/`sb#`/`sc#` `never-exceeded-bound` template
  from `gen leaf stdin read` (predates this batch) with its observed
  bound off by one (7 vs 6) — an artifact of the **local, discardable**
  depth-3 widening shifting the rng stream downstream for every program,
  not a new finding; or (b) a handful of pre-existing fixed-vocabulary
  identifiers (`BUF`, `l1`, `n`, `minus`, `payload`, `q1s5`, `v3`, `x`)
  dropping fractionally below the 50% line in this 200-sample, same
  cause.
- **This diff is against my own local draw-widening, not the real
  merged one**, per the common brief's own caveat — the master's actual
  merge (combining all four parallel batches' spans into one widened
  draw) will shift the rng stream differently again, and the diff that
  matters for acceptance is the one run after that merge. I'm reporting
  what my batch's own leaves contribute in isolation, which is nothing
  at the 50% threshold.

## Candidates the leaves turned up

None that look like a compiler bug or manual ambiguity. One thing worth
recording for whoever writes the next Files rows: reading a **property**
(not just `Read`ing bytes) on a **closed** handle does not crash — it
sets the error flag (catchable with `On error`) and the property reads
`-1`:
```
open a file for writing called handle at "...".
Write "abcde" to handle.
Close handle.
a number called after_close is handle's size.
On error print "closed-handle size read set the error flag".
Print after_close.
```
prints `closed-handle size read set the error flag` then `-1`. FIL-101
already covers the *read*-after-close half (safe, error flag, 0 bytes);
this is the analogous *property*-after-close half, undocumented and
currently uncited by any row. Not mine to add (outside my eight rows) —
flagging it as a gap for the next files batch. Also the reason every
assertion in this batch reads its subject **before** `Close`, never
after (see the batch's own header comment in `src/gen_files.vox`).

## Questions for the master

(Per the 2026-08-29 common brief: no dialog opened, defaults taken,
recorded here.)

1. **The brief's sandbox-file premise doesn't match what's on `main`.**
   The brief says "the harness creates per-run sandboxed `/tmp` files
   pre-filled with random bytes and hands their paths in through the
   generated program's flags." What's actually on `main` (and in the
   pending merge — I checked `leaves-merge-2026-08-29.patch`, it doesn't
   touch `sandbox.vox` either): one scratch **directory** path, handed
   through one flag when `gen_does_file_io` is true, empty until the
   program itself writes into it (`gen leaf file round trip`'s existing
   pattern) — and separately, one pre-seeded input file (`vf_input`) fed
   only via **stdin**, never by path a program could `open`. I took the
   default reading closest to existing precedent: every leaf here
   creates its own file inside `{gen_scratch_flag}/...` with content the
   generator itself drew (matching `'gen leaf buffer truncation'`'s
   established shape) rather than reading a harness-prefilled-by-path
   file, since no such thing exists to read from yet. If genuine
   harness-prefilled-by-path sandbox files are coming, FIL-46 in
   particular would be a good candidate to rebuild against real
   unpredictable content once they exist.
2. Kind 129 (raw 97) in my reserved span is unused — available if a
   future files row wants it without a renumber.
3. The nondeterminism-from-wall-clock lesson (above) is generic enough
   that it might be worth a line in PROCEDURE.md §6a alongside the
   existing "never print a raw host value" rule — a live file's own
   `modified`/`accessed`/`current time` reads are host-derived the same
   way environment/argv are, just less obviously so.

## What I could not do

Nothing in my eight rows was skipped or left `todo` for lack of a
reading — all nine row IDs (FIL-01/02/03/04/05/06/07/40/46) got a leaf,
an assertion, a hand-verified probe, and a broken-assertion proof.

`docs/check-probes.sh` still does not exist (noted as a known gap in the
ledger's own `## Report` section already, predates this batch) — I
re-ran every new/changed probe by hand instead (see each probe's own
header for the exact command and output).

## Gate

`./test.sh` green (31 passed, 0 failed, `LANGUAGE_MD` set, `VOX_CORE_PATH=
/usr/share/vox/coreasm`). `scripts/check-citations.sh --show src/gen_files.vox`:
9 checked, 0 stale (fixed two heading-line false positives by re-pointing
at the nearest real prose line, matching how `docs/ledger/files.md`'s own
header phrases a scope-level citation to avoid the same false positive).
Reviewed by the `vox-style-auditor` agent: two abbreviated local names
flagged (`'the sink decl'` → `'the sink line'`, `'the read line stmt'` →
`'the read statement'`) and fixed; no correctness issues, comments and
naming otherwise passed.

## Review round 1

Master caught a real problem before merge: FIL-07 asserted `permissions`
is exactly `420`. LANGUAGE.md:3772's table entry, "File permission bits
(e.g., 0644)", is an example, not a promise — a fresh file's mode is
umask-dependent (420/0644 under umask 022, this machine's; 384/0600
under a stricter 077), so the leaf would have filed a false
wrong-value finding on any machine or container with a different
umask. Fixed to assert the shape the manual does promise instead: a
Number within `0..511` (`0..0777`), via `'gen file assert range
quietly'` (the same two-sided-bound-plus-fixed-marker helper FIL-05/
FIL-06 already use, reused here because the value is
environment-dependent rather than wall-clock-dependent — same shape,
different reason). `docs/ledger/probes/files/FIL-07.vox` rewritten to
match: the header now records `420` as the value *observed* on this
run under this machine's umask, not the claim, and both the clean and
deliberately-broken (`is greater than 100`) runs were re-verified by
hand against the real compiler before the leaf changed. A follow-up
style-audit addendum also renamed the leaf's local `'the check'` to
`'the permissions check'`, matching the sibling naming already used in
`'gen leaf file descriptor'`/`'gen leaf file times'` (`'the descriptor
check'`/`'the modified check'`).

Re-verified after both fixes: `make build && ./test.sh` — 31 passed, 0
failed, `scripts/check-citations.sh --show src/gen_files.vox` — 9
checked, 0 stale, `tests/380_gen_files_b.expected` regenerated from the
driver (`tests/040_gen.expected` diffed clean, no regeneration needed —
the change is internal to one leaf's assertion shape, not the rng
stream). A fresh 200-program campaign (same seed 5001, same command as
above) after both fixes: `findings: 0`, FIL-07's new shape reached by
10 of the 200 programs.

DONE — stopped staged, patch parked
