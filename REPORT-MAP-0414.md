# Report — mapping the four pieces of 0.4.14 text (BUF/FUN/FMT/KEY)

Worker report for `docs/ledger/briefs/` task "map the claims Vox 0.4.14
added to the manual." Worktree `wt-map-0414`, branch
`docs/map-0414-additions`, off main `e43176f`. Vox `v0.4.14` (installed
`/usr/bin/vox`, `VOX_CORE_PATH=/usr/share/vox/coreasm`). No `src/`
touched. No commits made.

## Rows added, per ledger

### `buffers.md` — BUF-40 through BUF-54 (15 rows, "Releasing a Buffer," LANGUAGE.md:3618–3720)

| id | claim | assertable? | status |
|---|---|---|---|
| BUF-40 | `Free` releases memory immediately, not at exit | no (timing/implementation detail) | not assertable |
| BUF-41 | `Release`/`Deallocate` are the same statement as `Free` | yes | todo |
| BUF-42 | all three accept optional `the` | yes | todo |
| BUF-43 | after `Free`, size/length read 0 | yes | todo |
| BUF-44 | capacity 0, empty true, full true after `Free` | yes | todo |
| BUF-45 | `as text` reads back `""` after `Free` | yes | todo |
| BUF-46 | byte read on a freed buffer refused, returns 0 | yes | todo |
| BUF-47 | all five write forms refused on a freed buffer | yes | todo |
| BUF-48 | resize family also refused (under-enumerated by the manual, hand-verified anyway) | yes | todo |
| BUF-49 | `On error` catches the refusal | — | folded into BUF-46/47/48 |
| BUF-50 | worked example (declare/Free/print/append-refused) | yes | todo |
| BUF-51 | double-`Free` is a no-op that sets the flag | yes | todo |
| BUF-52 | `Free` through a function parameter frees the caller's buffer | yes | todo — real gap |
| BUF-53 | per-iteration loop idiom compiles and runs | yes (runs), no (memory-flat) | todo / not assertable |
| BUF-54 | "a list also accepts `Free`" | yes, and **fails** | todo — see Discrepancy 4 |

13 assertable, 1 not assertable (BUF-40), 1 folded (BUF-49). All `existing
leaf: none` — `grep` on `Free \|Release \|Deallocate ` across
`src/gen_*.vox` confirms no leaf emits any of the three spellings.
12 retained probes (some cover 2–3 rows): `BUF-41/43/46/47/48/50/51/52/53/54.vox`.

**New Discrepancy 4**: `Free` on a `list` compiles and runs but has
**zero observable effect** — length, emptiness and contents unchanged,
and a subsequent `append` is not refused. Strengthened by a citation I
found while re-checking `keywords.md`'s Statement Starters table for
the D4 task below: LANGUAGE.md:5019 (that table's own `Free` row) reads
"Release a buffer **or list's** memory immediately" — a second, more
direct assertion of the same behavior the "Releasing a Buffer"
subsection's closing sentence makes. Recorded with a minimal repro
(`D4.vox`), strongest pro-compiler reading given, not filed, not
adjudicated.

### `functions.md` — FUN-44 (1 row, LANGUAGE.md:878, vox #105)

Compile-error claim: writing an argument right after a function name
with none of `of`/`to`/`with`/`on` now names the missing preposition.
Hand-verified with both a quoted multi-word function name and a bare
single-word one; both produce the diagnostic `'<token>' follows the
call with no preposition — arguments are introduced with 'of', 'to',
'with', or 'on'.`, caret on the token. Not assertable by a leaf (same
category as FUN-41/FUN-42). 1 probe (`FUN-44.vox`).

### `input-output.md` — FMT-57 (1 row, LANGUAGE.md:3418, vox #108)

"A text variable reassigned from a format string releases the string it
no longer holds" — the leak fix behind `Set acc to "{acc}x"` no longer
being quadratic. **Not assertable**: memory release has no observation
channel from inside Vox (same category as FMT-23). The retained probe
(`FMT-57.vox`) instead hand-verifies the one observable proxy — the
accumulate idiom named in the CHANGELOG still produces the correct
value after five reassignments — confirming the fix didn't corrupt the
assignment path. No discrepancy found.

Also found and fixed in passing: this ledger's own row/probe counts
were already one stale before I started (FMT-56 existed in the table
and probe directory but was never folded into the "55 rows"/"53 probe
files" summary text). Corrected to the true counts (57 rows, 55 probe
files) as part of touching this file, noted inline as pre-existing
drift, not something 0.4.14 caused.

### `keywords.md` — KEY-81 (1 new row) + KEY-48–53 correction + Discrepancy 4

- Re-read KEY-48 (`ms`), KEY-49 (`message`), KEY-50 (`string`), KEY-53
  (`length`) against the new 85-row Reserved Aliases table
  (LANGUAGE.md:5072–5158): all four already cited the correct 0.4.14
  line (the mechanical re-pin in `c7dd9eb` had already landed them
  right) — **no change needed**.
- KEY-51 and KEY-52 carried a `?` line placeholder. Both now pin to
  LANGUAGE.md:5160 (the "These cannot be used as variable names... The
  diagnostic names the spelling you wrote..." paragraph) — **corrected**.
- **KEY-81** (new): every alias in the table is refused as a variable
  name, diagnostic naming the spelling and its canonical keyword.
  Hand-verified across 8 aliases from different parts of the table —
  `abs`→absolute (top), `push`→append, `mod`→modulo, `nil`→nothing,
  `show`→print, `grow`→resize, `stopwatch`→timer, `years`→year (last
  row) — all 8 follow the exact diagnostic template. Not assertable by
  a leaf (compile-error claim). One retained probe (`KEY-81.vox`);
  since a compile error halts the program at the first offending
  declaration, the probe mechanically exercises only the first (`abs`)
  and records all eight hand-run outputs verbatim in its header, per
  PROCEDURE.md §4.
- **Discrepancy 4** ("the chapter's tables under-enumerate reserved
  words and aliases") — see "Questions for the master" below; marked
  **PARTIALLY RESOLVED**, not flatly RESOLVED as the brief described it.

## Assertable counts

| ledger | new rows | assertable | not assertable | folded |
|---|---|---|---|---|
| BUF | 15 | 13 | 1 | 1 |
| FUN | 1 | 0 | 1 | 0 |
| FMT | 1 | 0 | 1 | 0 |
| KEY | 1 | 0 | 1 | 0 |

All new rows are `todo` or `not assertable` — none `exercised` or
`verified`, since 0.4.14's `Free` statement, the #105 diagnostic, the
#108 sentence and the alias table all have zero leaf coverage today.
`exercised`/`verified` counts in `INDEX.md` are unchanged, per the brief.

## Discrepancies found

1. **buffers.md Discrepancy 4** (new): `Free` on a `list` is a silent
   no-op — compiles, runs, changes nothing. Strengthened by a second
   citation (LANGUAGE.md:5019) found via the keywords.md cross-check.
   Not filed, not adjudicated — repro at `docs/ledger/probes/buffers/D4.vox`.
2. **keywords.md Discrepancy 4**, re-examined: the brief asked me to
   mark it "RESOLVED by vox #106 / 0.4.14." Hand-verification shows
   this is only half true — the Reserved Aliases table half is
   genuinely resolved (now machine-generated, 85 rows, exhaustive by
   construction); the Statement Starters table half (missing `read`,
   `write`, `open`, `close`, `wait`, `input`, `standard`, `byte`,
   `each`, `elapsed`, `without`, `error`, `arguments`, `environment`) is
   untouched by 0.4.14 — `D4.vox` reproduces identically. Recorded as
   **PARTIALLY RESOLVED**, not flatly resolved. See "Questions for the
   master."

## What I could not probe, and why

- **BUF-40** ("`Free` releases memory immediately, not at exit"): the
  *timing* half of this claim has no observation channel from inside
  Vox — same category as BUF-04/BUF-08 (freed-on-exit). Its observable
  consequence (the freed state being visible to the very next
  statement) is what BUF-43 onward test instead.
- **BUF-53**'s "keeps memory flat" half: implementation detail, no
  observation channel. The compiles-and-runs half of the same row *is*
  probed.
- **FMT-57**: memory release itself is not observable; only its
  functional side-effect (the value stays correct) could be probed.
- **KEY-81**: the general "every alias is refused" claim cannot be
  probed as one compiled program (the compiler halts at the first
  reserved-word error), so only a sample of 8, individually compiled,
  could be retained as hand-verified evidence rather than one
  mechanically-reproducible probe.
- Nothing was blocked for want of privileges, a device, or a second
  process — everything in scope for this pass ran as an ordinary user.

## Questions for the master

1. **keywords.md Discrepancy 4**: the brief said "mark D4 ... RESOLVED
   by vox #106 / 0.4.14." I found and hand-verified that this is only
   true for the Reserved Aliases table half; the Statement Starters
   table half (missing `read`/`write`/`open`/`close`/`wait`/etc.) is
   unchanged and its repro (`D4.vox`) still reproduces byte-identical
   under 0.4.14. I recorded it as **PARTIALLY RESOLVED** rather than
   following the brief's wording verbatim. Please confirm this reading
   is what was intended, or correct me if there's a fix I'm missing
   that also covers the Statement Starters table.
2. **buffers.md Discrepancy 4** (new, `Free` on a `list` is a no-op):
   is this worth routing to the lawyer / filing, given it now has two
   independent manual citations (3674 and the Statement Starters
   table's own 5019) both promising an effect the compiler doesn't
   produce? I did not adjudicate per PROCEDURE §5, but the "strongest
   pro-compiler reading" I could construct (a narrow "accepts" =
   "doesn't reject the grammar" reading) is weaker than the readings
   this ledger's other three discrepancies settled on, given the second
   citation.
3. **Pre-existing INDEX.md drift, unrelated to 0.4.14**: I found and
   corrected two stale counts while touching these ledgers —
   `input-output.md`'s row count was already one row short (FMT-56
   existed but was never folded into the summary), and `keywords.md`'s
   INDEX.md row count was recorded as 86 when the table has only ever
   run to KEY-80 (now 81) — a 6-row overcount of unknown origin, present
   before this pass and not investigated further (out of this pass's
   scope). Worth a look next time someone is in either ledger.
4. **BUF-48** (resize family refused on a freed buffer): hand-verified
   to hold for all four spellings, but the manual's "Releasing a
   Buffer" subsection never names the resize keywords by name — it says
   only "every read or write." Worth a one-line addition to the manual
   naming resize explicitly, or leave as an under-enumeration a reader
   has to infer? Not filed, just flagging the gap.

## Gate

- `docs/check-probes.sh docs/ledger/probes/buffers docs/ledger/probes/functions docs/ledger/probes/input-output docs/ledger/probes/keywords`:
  **228 passed, 0 failed, 0 skipped.**
- `LANGUAGE_MD=$PWD/docs/ledger/pinned/LANGUAGE.md scripts/check-citations.sh docs`:
  **748 checked, 0 stale.**
- `docs/ledger/INDEX.md` `rows` columns updated for BUF (39→54), FUN
  (43→44), FMT (55→57, includes the pre-existing +1 correction), KEY
  (86→81, corrects a pre-existing overcount plus +1 for KEY-81).
  `exercised`/`verified` columns unchanged for all four, per the brief.
- Full-repo `docs/check-probes.sh` (all 26 probe directories, 972
  probes) was also run as a final sanity pass: **964 passed, 1 failed,
  7 skipped.** All of my own new/touched probes are among the passes.
  The one failure and all seven skips are in ledgers I never touched
  (`git status` confirms no changes to `things-b.md` or its probes,
  `compiler-usage.md`, `files.md`, `variables.md`):
  - `probes/things-b/D4.vox` — recorded diagnostic no longer matches;
    the compiler now additionally names `plan 310 §6` and gives a
    longer explanation for why a thing field can't be `text` yet. Not
    mine to fix (things-b.md's Discrepancy 4, PROCEDURE §5 territory —
    a mapping worker records, doesn't adjudicate, and this ledger isn't
    even in scope for this pass), flagging it here the same way prior
    passes have flagged similar drift for the master.
  - The 7 skips (`compiler-usage/CLI-04/05/06`, `compiler-usage/D1`,
    `files/FIL-103`, `things-b/THG2-18`, `variables/D5`) are all
    "no recorded output" probes, pre-existing and unrelated to this
    pass.

## Park

`git add -A && git diff --cached > /home/josj/scr/english/vox-notes/parked/map-0414-additions.patch`,
copy of this report to `/home/josj/scr/english/vox-notes/`. Stopped
staged, not committed, not pushed.

DONE — stopped staged, patch parked
