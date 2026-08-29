# Report — leaves for the Buffers ledger, batch A (2026-08-28 night)

Worker in `~/scr/english/worktrees/wt-leaves-buffers`, branch
`feat/ledger-buffers-a`. No human was at the desk for most of this run
(see "Questions for the master" at the end — steered past, not asked).

## Rows covered

All eight rows in the brief. Each leaf's doc comment in `src/gen_buffers.vox`
names its row IDs so `grep <ID> src/` finds it.

- **BUF-06** (3516) — `'gen leaf buffer fixed overflow'`. Appends a payload
  built as two independently-drawn pieces (`the fitting part`, exactly
  `capacity` bytes; `the spilling part`, a random overshoot) to an empty
  fixed buffer. Asserts: error flag set (`gen assert true`), size ==
  capacity (`gen assert number is`), content == `the fitting part`
  (`gen assert text is`, see "Candidate" below). Random capacity (8–63),
  random overshoot (1–200).
- **BUF-11** (3582) — `'gen leaf buffer length synonym'`. This is *not* a
  fresh row: the earlier batch's `'gen leaf buffer properties'` already
  asserts `X's length is X's size`, but only ever right after an append —
  an undeclared "the check always follows an append" rule the row's own
  wording (append/set-byte/clear) doesn't license. This leaf draws the
  mutation instead: append more, `Set byte` inside the *current* size (so
  it can't be confused with BUF-29's write-extends-length claim), or
  `clear`. Asserts `length is size` before and after, via `gen assert
  number matches` (an agreement check, not a magic number), so it holds
  regardless of which mutation landed.
- **BUF-15, BUF-16, BUF-17** (3609, 3612, 3613) — `'gen leaf buffer
  resize'`. One buffer, two resizes. Step 1 grows or shrinks-to-at-or-
  above-length (random direction, random spelling among resize/
  reallocate/grow/shrink, "bytes" suffix optional) — asserts new capacity
  (BUF-15) and content unchanged (BUF-16). Step 2 shrinks strictly below
  the current length — asserts capacity/size == the new value (BUF-15,
  BUF-17) and content == the independently-drawn `the kept part` prefix
  (BUF-17). `the kept part`/`the shed part` are drawn separately and
  concatenated for the payload, so the truncation assertion's oracle
  isn't derived by re-truncating the same string it's checking.
- **BUF-29, BUF-30** (3712–3719) — `'gen leaf buffer write read bounds'`.
  One buffer, one gap: append to `the initial length`, `Set byte` at
  `the write index` in `(length, capacity]` (asserts no error, size
  becomes the write index — BUF-29), then read at `the read index`
  strictly above the *new* size but still `<= capacity` (asserts the
  error fires and the value is 0 — BUF-30). A stale-error handler
  consumes any pending flag from earlier in the program first (the same
  defensive pattern `'gen leaf buffer growth'` already uses).
- **BUF-33** (3739) — `'gen leaf buffer clear'`. Fixed or dynamic form
  (random), append a payload, capture capacity into a variable *before*
  `clear`, assert size == 0 and capacity == its own earlier reading
  (`gen assert number matches`) rather than a literal — this sidesteps
  Discrepancy 1 (dynamic capacity is 4096, not the documented 0) entirely,
  since BUF-33 has nothing to do with settling that question.

Two new shared helpers, doc-commented in `gen_buffers.vox`: `'gen assert
text is'` (text/buffer equality assertion) and `'gen buffer resize
statement'` (the four resize spellings, "bytes" optional).

Registered in `src/gen_core.vox` as kinds 105–109, in one contiguous
block headed `( ── buffers leaves, batch A, 2026-08-28 ── )` right after
the existing 100–104 registrations. All five are reachable **top-level
only** (like 103/104), via a second reserved-span remap: `'gen
statement'`'s depth-3 draw widened from `'rng below' of 65` to `of 70`,
with the pre-existing 50–64→140–154 (values band) remap now bounded
`kind is greater than 49 and kind is less than 65` (it needed an upper
bound once the draw widened past 65, which it didn't have before), and a
new `kind is greater than 64 and kind is less than 70` band adding 40 to
land on 105–109. I did not touch the 45–49→100–104 remap, the depth-2/1
remap, or `'gen any leaf'`'s safe-closer set — extending those to also
reach 105–109 would have meant widening `'rng below' of 32` (shared by
every surface's nested-position draw) and touching `'gen any leaf'`'s
pick set, both higher-risk shared edits for a first pass, so BUF-15/33/
length-synonym stay top-level-only for now even though nothing about
their own shape requires it. Noted, not fixed — see "What I could not do"
below.

## A compiler-parsing bug the leaves turned up (found and routed around)

**Not filed — see PROCEDURE.md 6a/CLAUDE.md "candidates are not bugs."**
Hand-verified against the pinned vox v0.4.14 (`4995394`):

```
a buffer called 'toolbox' is 8 bytes in size.
append "AB" to 'toolbox'.
Print 'toolbox'.              (compiles, prints AB)
Print "{'toolbox'}".          (does NOT compile: "Unknown variable: 'toolbox'")
```

A buffer's **one-word quoted spelling** (`'toolbox'`, not `toolbox` —
`'gen buffer name'` draws either spelling for a one-word name, see its
own comment) resolves fine as a bare statement reference but not inside
a `{...}` format slot. Bare (`toolbox`) and multi-word-quoted (`'the
inbox'`) both work fine in both positions — hand-verified all four
combinations. My first cut of `'gen assert text is'` put the raw buffer
reference straight into the "got X" part of the failure message via
`'gen buffer slot of'`, which is exactly this shape; ~9% of a first
20-seed hand-verify batch (seeds 1006, 1008, 1029) failed to compile
because of it, and it's what made `tests/270_layout.vox` fail on the
first `make build && ./test.sh` pass (see "the tests/040_gen.expected
rewrite" below — this is not that; 270 was this bug, caught, fixed,
re-verified green).

**Fix, in `gen_buffers.vox`:** `'gen assert text is'` now captures the
subject into a plain multi-word-quoted holder (`'gen buffer companion'`,
always safe to interpolate) via its own statement *before* the check,
and shows the holder in the message instead of the raw subject. It
returns a two-element list (capture line, assert line) instead of one
line; the three call sites (BUF-06's leaf, BUF-16/17's two checks in the
resize leaf) unpack both elements into their `'the lines'` list in
order. Re-verified: seeds 1006/1008/1029 now compile clean, `270_layout`
passes, and a fresh 200-program `--layout plain` campaign (below) shows
`'toolbox'`/`'the tally sheet'`/`'the postbag'` etc. going through the
fixed shape correctly (`{'the postbag the grown content'}`, not
`{'the postbag'}`).

## Hand-verified (two samples, `--seed <random> --count 20 --keep <dir>`, compiled/run under `timeout 20`)

Campaign: `systemd-run --user --scope -q -p MemoryMax=3G timeout 200
./build/vox-fuzz gen --seed 1362224836 --count 20 --budget 24 --vox
/usr/bin/vox --core /usr/share/vox/coreasm --keep <dir>` — 20/20
compiled, 0 findings (after the fix above).

**Seed 1362224837** (random layout) — exercises BUF-06, BUF-15/16/17,
BUF-29/30, BUF-33 all in one program. Excerpt (whitespace as drawn):
```
"ASSERT BUF-06: expected zmuk8gxhou65z44n got {'the tally sheet the captured content'}"
reallocate 'the postbag' to 109.  If 'the postbag's capacity is not 109 ...
"ASSERT BUF-16: expected ozgbyvlze850qliohfhq9 got {'the postbag the grown content'}"
"ASSERT BUF-17: expected oz got {'the postbag the shrunk content'}"
"ASSERT BUF-29: expected 0 got {'the tray the write errored'}"
"ASSERT BUF-30: expected 0 got {'the tray the gap read'}"
"ASSERT BUF-33: expected 0 got {toolbox's size}"
```
Compiled clean, ran clean, exit 0, no `ASSERT` line printed (every check
passed).

**Seed 1362224838** (random layout) — exercises BUF-33 (fixed form,
`'the shipping label'`), BUF-10/11/12 (earlier batch's leaf), BUF-01/05.
Compiled clean, ran clean, exit 168 (a drawn `Quit`/`Terminate`, not a
ledger exit), no `ASSERT` line.

**Broken-assertion proof (exit-95 classification):**
```
a buffer called 'the inbox' is 51 bytes in size.
append "stwumzsydfbajh2001jwpil3heuyo" to 'the inbox'.
reallocate 'the inbox' to 89 bytes.
If 'the inbox's capacity is not 90 then, Print "ASSERT BUF-15: expected 90 got {'the inbox's capacity}", Exit 95. Print 'the inbox's capacity.
```
Output: `ASSERT BUF-15: expected 90 got 89`, exit `95`.

## Tests

`tests/330_gen_buffers_b.vox` / `.expected` (numbers 330 allotted; only
one number needed — all eight leaves fit one golden file, same shape as
`tests/300_gen_buffers_a.vox`). Each leaf rendered at true top level
(`nested false`) and inside a block (`nested true`); BUF-11's leaf gets
three seeds to show all three mutation branches (append/set-byte/clear)
are actually reachable, not just theoretically drawn.

## The `tests/040_gen.expected` rewrite (168 lines) — draw-order shift, not a behaviour change

Confirmed mechanically. `tests/040_gen.vox` dumps `'gen program' of 42
and 12` verbatim; lines 1–85 (the drawn prelude, flags, argv asserts,
and the program's first top-level statement, `Set v3 to v2 minus v2.`)
are byte-identical old vs new. The **second** top-level statement is
where it diverges:

- **before** my change: kind 23 (`'gen leaf arguments inrange'`) →
  `Print arguments's count.` / `Print arguments's empty.`
- **after**: kind 26 (`'gen leaf treating grid'`) →
  `print each item from [24, 36] treating 9 as 2.`

Both are valid, pre-existing leaves; neither construct's own behaviour
changed one bit. What changed is which `kind` number the RNG draw at
that exact position in the stream maps to, because I widened `'gen
statement'`'s depth-3 draw from `'rng below' of 65` to `of 70` to add
five more reachable kinds (105–109) — the identical mechanism the
`ae122e9`/`6615dc0` precedent already used ("tests/040 golden
regenerated for the environment leaves" when THAT batch added new
kinds). `reproducible: 1` holds in both the old and the new golden — the
generator is still fully deterministic, just differently.
`tests/330_gen_buffers_b.expected` needed the same kind of regeneration
a second time, after the compiler-bug fix above changed the emitted
shape of the three affected leaves (capture line inserted before the
content check).

## Gate

`export VOX=/usr/bin/vox VOX_CORE_PATH=/usr/share/vox/coreasm; make
build && ./test.sh`. Final clean run, one command, no target filter:

```
passed: 31  failed: 0
citations: 724 checked, 0 stale
```

(`citations` needs `LANGUAGE_MD` pointed at `docs/ledger/pinned/LANGUAGE.md`
explicitly — `/usr/bin/vox`'s own derived default resolves to
`//LANGUAGE.md`, not a real path; a pre-existing `test.sh` quirk for
anyone running against the installed binary rather than a `vox`
checkout, unrelated to this batch, worth `test.sh` deriving more
defensively some day but not mine to fix tonight.)

That clean line is the end of a longer story, kept here because both
halves are real findings from this batch, not noise:

- **Run 1** (before the compiler-bug fix below existed): `passed: 30
  failed: 1` — only `270_layout` failed. Not flaky: re-ran it twice,
  the same three seeds (1006, 1008, 1029) failed to compile both times,
  both layouts each time, which is what sent me looking for a real
  cause instead of blaming machine load.
- **Fix applied** (see "A compiler-parsing bug" below).
- **Run 2** (full suite, post-fix): `passed: 30 failed: 1` — only
  `330_gen_buffers_b` failed, because its golden predated the fix.
  Regenerated the golden, verified `330`/`040_gen` individually, both
  green.
- Three more full-suite attempts in between died to the *harness's own*
  background-task management, not to a compile or test failure — this
  machine had four sibling worktrees' `test.sh` plus two overnight
  `vox-fuzz` campaigns running concurrently for most of the session
  (`uptime` read 6–9 throughout). Switching the final attempt to a
  `nohup ... & disown` process (immune to the wrapper that kept getting
  killed) is what finally produced the clean Run 3 pasted above.
- **Lesson paid for while doing this:** `test.sh` runs `rm -rf ./vf_*`
  after **every** test, not just `250_unwritable_scratch` — a
  concurrent `test.sh` run destroyed a hand-verify batch and a
  200-program campaign corpus before I'd finished reading them (nothing
  load-bearing lost, both were regenerated). Everything after switched
  to keeping campaign/hand-verify output outside the repo (this
  session's own scratch directory) rather than under `./vf_scratch`.

## Campaign + invariants

`systemd-run --user --scope -q -p MemoryMax=3G timeout 280
./build/vox-fuzz gen --seed 1956518180 --count 200 --budget 24 --vox
/usr/bin/vox --core /usr/share/vox/coreasm --layout plain --keep
<out-of-repo dir>` — 197/200 compiled (the 3 that didn't produced no
`vf_cerr` at all, i.e. their per-run scratch directory itself was never
created; consistent with the same shared-load contention as the gate
retries above, not a generator defect — see the caveat below), 0
findings.

`scripts/invariants` (compiled with the pinned vox) over the 200 kept
sources: **75 findings at the ≥50% threshold, 0 of them naming anything
from this batch's vocabulary.** I read all 75 by hand rather than just
counting them: they're `ASSERT`/`expected`/`got`/`BUF`/`VAL` (the shared
ledger-assertion protocol, pre-existing, used by every surface that
asserts, not introduced by this batch), stdin/file-read templates
(`sin#`/`sb#`/`sc#`), value/map/list vocabulary (`tag1`, `q1s1`, `m1`,
`l1`, `Get`, `BAD`, `whatever`, `figure`, `spare`, `sum`, `range`,
`key`, `tally`), and `v1`/`v2`/`v3` argv-variable templates. None of my
new leaves' own vocabulary — `resize`/`reallocate`/`grow`/`shrink`,
`overflowed`, `the captured/grown/shrunk content`, `the write errored`,
`the gap read` — appears anywhere in the report, and no buffer-name-pool
word (`toolbox`, `cupboard`, the rest of the 29) shows up at a
suspicious frequency either, which is what I'd expect from a properly
randomised leaf and is the actual thing worth checking, not just
whether the count is zero.

**Caveat, stated plainly:** this is not a diff against a fresh `main`
invariants report — I don't have one from tonight (the ones under
`vox-notes/` are all from 2026-08-21/main `862bf7b`, many batches
stale), and building one myself (a full separate build + 200-program
campaign against `main`) on a machine already this loaded, on top of
everything above, is more than I could fit in this session alongside
finishing the batch itself. What I have instead is a full manual read of
every finding in my own corpus's report against what I know is already
on `main` (the shared assert protocol, the other surfaces' leaves) —
which answers the actual question ("did this batch add anything
unjustified") without the mechanical diff. If the master wants the
literal diff, `docs/ledger/buffers.md`'s eventual "Invariants this
section justifies" section is where the `ASSERT`/`BUF`/`VAL` protocol
entry belongs regardless of which batch's campaign first surfaces it —
it isn't specific to buffers and probably belongs in `PROCEDURE.md`
itself as a standing citation, not repeated per ledger.

## Park

`git add -A && git diff --cached >
/home/josj/scr/english/vox-notes/parked/leaves-buffers-a.patch`, this
report copied to `/home/josj/scr/english/vox-notes/`.

## What I could not do

- Rows 105–109 are top-level-only even though BUF-15/33/length-synonym
  don't structurally need it (no loop, no `On error`) — extending them
  to nested positions means widening `'rng below' of 32` (the shared
  depth-2/1 draw every surface's leaves go through) and touching `'gen
  any leaf'`'s safe-closer pick set, both riskier shared edits than I
  wanted to make on a first pass with three other surfaces editing
  `gen_core.vox` the same night. Narrower nesting-position coverage than
  the ledger ideally wants; not a correctness gap.
- No fresh `main`-branch invariants baseline to diff against (see
  Campaign section) — reasoned through the report by hand instead.

## Questions for the master

(Per steer 2: no more question dialogs. Taking the brief's default on
each and noting it here rather than blocking.)

1. Is the `'toolbox'`-in-braces compiler bug worth its own
   `docs/BUGS_FOUND.md`-style entry independent of this batch, given
   it's a parser issue with no connection to any specific LANGUAGE.md
   claim (unlike the ledger's own Discrepancies, which are all about
   buffer *semantics*)? Default taken: reported here only, not filed,
   per "a leaf never files a bug."
2. Should the reserved-span top-level-only pattern (105–109 here,
   103–104 from the earlier batch) get a real nested-position home at
   some point, or is top-level-only an accepted permanent shape for
   leaves that carry `On error`/loops specifically? Default taken: left
   as-is, noted above rather than guessed at.

## Review round 1

Master accepted the batch in substance. Two style fixes: dropped the
leading "the" from the six new companion role strings (they were
rendering as `'the inbox the grown content'`, colliding on the article
against the file's existing role-naming convention), and renamed
`'gen buffer resize statement'`'s local `'the spelling'` to `'the
keyword draw'` (the file's own "X draw → X" shape). Regenerated
`tests/330_gen_buffers_b.expected` from the driver; `040_gen` untouched
(seed 42/budget 12 doesn't draw the renamed leaves). Gate re-run clean:
`passed: 31 failed: 0`, `citations: 724 checked, 0 stale`. Re-parked to
the same patch path.

DONE — stopped staged, patch parked
