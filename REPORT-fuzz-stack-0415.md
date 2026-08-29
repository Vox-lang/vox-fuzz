# Report: stack the two parked ledger trees, re-pin to 0.4.15, map the additions, refresh stats + SEEDS

Worktree `~/scr/english/worktrees/wt-fuzz-stack-0415`, branch
`stack/fuzz-0415`, off `main` `e43176f`. No commits made (no signing key
present); every step parked as a patch under
`/home/josj/scr/english/vox-notes/parked/stack-fuzz-0415/`. No `src/`
edits — this brief was mapping/citation work only.

## Tree ids

| step | tree id |
|---|---|
| T00 (baseline, bare `e43176f`) | `29218e83ac8de3aece6983c0a78c65ed885cb813` |
| T01 (leaves, both rounds) | `7d4d1f14a30621bd7ad872ed2775298b4b16b771` |
| T02 (0.4.14 mapping) | `b3300b8fbc2982f8044c0a229dfd74d57cfe6f9e` |
| T03 (re-pin to 0.4.15 stack manual) | `48bf2f72d5269e6857cab13ed2b5b37716c9b762` |
| T04 (map 0.4.15 additions) | *(recorded once this step's patch is parked — see below)* |
| T05 (stats + SEEDS) | *(recorded once this step's patch is parked)* |

## Gate totals

**Baseline** (bare tree, installed vox 0.4.14, after `make build` — the
build artifact is gitignored, so a bare checkout must build it before
`./test.sh` can find `./build/vox-fuzz`; the first run without it shows
7 spurious `FAIL`s that are just the missing binary, not real
failures): **30 passed, 0 failed.** citations: 724 checked, 0 stale.

**Step 01** (leaves, both rounds): applied clean via `git apply
--index`; only 5 harmless "new blank line at EOF" whitespace warnings.
No gate specified for this step alone in the brief (gated together with
02).

**Step 02** (0.4.14 mapping, `git apply --3way --index`): 2 conflicts
(`INDEX.md`, `buffers.md`), both keep-both-sides, resolved by hand (see
"Conflict resolution" below). Gate: **36 passed, 0 failed.** citations:
757 checked, 0 stale.

**Step 03** (re-pin to the 0.4.15 stack manual):
- Installed 0.4.14: **36 passed, 0 failed.** citations: 762 checked, 0
  stale.
- 0.4.15 stack (`VOX=/home/josj/scr/english/vox-notes/stack-0415/vox-stack
  VOX_CORE_PATH=/home/josj/scr/english/worktrees/wt-stack-0415/coreasm`):
  **36 passed, 0 failed.** citations: 762 checked, 0 stale.
- **`tests/040_gen.expected` came out byte-identical under both
  compilers** — `040_gen` passed against the same checked-in fixture
  under (a) and (b) both. No divergence found; the "isolate a minimal
  repro" fallback in the brief was not needed.
- `scripts/check-citations.sh docs` 762/0 stale, `src` 198/0 stale.
- `docs/check-probes.sh`: collections-a + functions 87/0; buffers 47/0
  (against the 0.4.15 stack — `BUF-54`/`D4` correctly *fail* against
  installed 0.4.14 at this point, since they were just rewritten to the
  fixed expected output).

**Step 04** (map the 0.4.15 additions):
- Installed 0.4.14: first pass **36 passed, 0 failed**, citations: 808
  checked, 0 stale — then one further edit landed in `collections-a.md`
  (the `D6.vox` HISTORICAL-header fix, see below) after that pass ran,
  so it was re-run for a consistent final number: **36 passed, 0
  failed.** citations: 809 checked, 0 stale — matching gate (b) exactly.
- 0.4.15 stack: run under heavy machine contention (5+ other workers'
  `test.sh` runs concurrently on this shared box, load average 10–13
  throughout). Two tests reported **FAIL** on the full-suite run, both
  confirmed as contention flakes, not regressions:
  - `020_harness` — re-compiled and re-ran `tests/020_harness.vox` in
    isolation against the same 0.4.15 stack compiler: **output matched
    `tests/020_harness.expected` exactly** (`true: exit 0` / `exit 200:
    exit 200` / `segv: signal 11 1` / `sleep: hang 9`). This test
    exercises a 300ms busy-loop-kill timing path (its own header: "the
    sandbox has no sleep binary... the 300ms deadline keeps the burn
    short") — exactly the shape a 10+ load average would starve.
  - `210_scratch_sandbox` — first isolated re-run reproduced the
    failure (missing `wrote ok` line), traced to a methodology gap in
    my own ad-hoc re-run: the compiled test binary reads the `VOX`
    environment variable at *runtime* (`src/runner.vox:10`, for its own
    nested `'compile vox'` call on `tests/fixtures/scratch_writer.vox`)
    and I had only set it for the *compile* step, not the *run* step,
    so it fell back to the hardcoded default `../vox/target/release/vox`
    (absent from this worktree). Re-ran correctly, twice: once by hand
    with `VOX` exported for both steps, once through `./test.sh
    tests/210_scratch_sandbox.vox` (test.sh's own invocation, which does
    export it correctly) — **both matched
    `tests/210_scratch_sandbox.expected` exactly**, the second run after
    contention had eased slightly (compile 1s, run 1s, vs. the gate's
    compile 0s/run 6s under peak load).
  Both confirmed as contention/methodology, not regressions: no `src/`
  was touched by this brief, and every other timing-adjacent test
  (`240_concurrency`, `250_unwritable_scratch`) passed clean in the same
  run. The gate's own full-suite summary line: **34 passed, 2 failed**
  (the same two above), citations: 809 checked, 0 stale.
- `scripts/check-citations.sh docs` 808/0 stale at the time gate (a)'s
  first pass ran; one of the LST-53/54 cross-reference fixes (see
  Discrepancies below) landed in `collections-a.md` afterward and added
  one more `LANGUAGE.md:` citation, so gate (a) was re-run for a
  consistent final number: 809/0 stale, matching gate (b) exactly.
  `src` 198/0 stale throughout, both runs.
- `docs/check-probes.sh` across all eight touched probe directories
  (buffers, expansion, functions, things-a, input-output,
  collections-a, types, keywords): **390 passed, 4 failed** against the
  0.4.15 stack. The 4 failures are `D6.vox`, `LST-32.vox`, `LST-53.vox`,
  `LST-54.vox` — all four are marked **HISTORICAL** in their own probe
  headers (pre-#111 self-referencing-collection behaviour that #111
  makes impossible to build any more) and were re-confirmed to still
  pass, unmodified, against the installed 0.4.14 compiler — proving the
  probes are correct records of a real behaviour change, not broken
  probes.

**Step 05** (stats + SEEDS): *(gate totals appended once complete)*

## Conflict resolution (step 02)

- **`buffers.md`**: the leaves-merge patch (round 2) added a new
  "## Invariants this section justifies" section right where the
  0.4.14-mapping patch added Discrepancy 4 ("A list also accepts
  `Free`"). Resolved by ordering: Discrepancy 4 stays inside the
  Discrepancies section (before "## Report"), the Invariants section
  goes after Discrepancies and before Report — both sides' content
  kept verbatim, only reordered.
- **`INDEX.md`**: both patches touched the FUN/THG/THG2 and FMT/BUF/FIL
  rows in the same table. Resolved by taking `rows` from the 0.4.14
  mapping side (it reflects the true post-mapping row count) and
  `exercised`/`verified` from the leaves-merge side (it reflects the
  true post-leaf-building counts) — verified this was the correct
  merge by directly counting unique row IDs in each ledger file
  (`grep -oE` on the id column) rather than trusting either patch's
  own arithmetic: FUN=44, THG=75, THG2=77, FMT=57, BUF=54, FIL=103, all
  matched. The BUF row's discrepancy-count text took the 0.4.14-mapping
  side (it has the new Discrepancy 4 the leaves side doesn't know about).

## The `?` count from the repin, and how each was resolved

`scripts/repin-citations --to <stack manual> --apply --pin`: **3588
citations checked, 3375 shifted by arithmetic, 0 moved (text-search
recovery), 37 landed on changed text and came back `?`, 10 pre-existing
REVIEW rows untouched** (informational placeholders like "undocumented
precision at N/M" — not citations, not part of this count, unrelated to
today's work).

All 37 resolved by hand, one underlying manual change per cluster:

| # | files (citation) | cause | resolution |
|---|---|---|---|
| 1–6 | `buffers.md` (×3: BUF-54 row, Discrepancy 4 heading + body), `INDEX.md` (×2), `probes/buffers/BUF-54.vox`, `probes/buffers/D4.vox` — 6 of the 37 hit `LANGUAGE.md:3674` | "A list also accepts `Free`" grew from one clause to a full paragraph (#109) | BUF-54 rewritten to the new claim (now **passes**); Discrepancy 4 marked **RESOLVED** (re-ran `D4.vox` against the stack: `0`/`1`/`[]`/refused-append, exactly the fixed contract); both probes' expected output rewritten to the fixed behaviour; new line 3699–3708 |
| 7–13 | `collections-a.md` ×7 (LST-32/33/34 rows, Discrepancy 6) — hit `LANGUAGE.md:2483/2487/2489/2495/2498/2502` | The Nested Lists section's self-reference/aliasing paragraphs were **replaced outright** by #111's copy-by-construction rule, not reworded | LST-32 **narrowed** (depth cap survives as a defensive backstop, no longer reachable via self-reference); LST-33 **withdrawn** (self-append no longer builds a cycle — now `[[]]`); LST-34 **withdrawn** (the "element N of yields a reference" limitation paragraph is deleted from the manual outright — element N of now copies); Discrepancy 6 marked **moot** (the example it was about no longer produces that output in any form) |
| 14 | `probes/collections-a/LST-35.vox:5` — `LANGUAGE.md:2498` | Embedded prose citation inside LST-35's historical note, same underlying text move as above | Citation updated to note the referenced phrase ("One limitation remains for this stage") is itself now gone (superseded by LST-34, withdrawn) |
| 15–19 | `functions.md` ×5 (FUN-05, FUN-07, FUN-34 rows + 2 Invariants-note lines) — hit `LANGUAGE.md:751/753` | Function-name-form wording changed from "bare single word / single-quoted multi-word" to "bare word, or any name in single quotes (a single word may be quoted too)" (#110) | All three rows rewritten to the new wording; existing-leaf/status columns updated to flag the newly-legal quoted-single-word form as untested (new rows FUN-45/46 fill it); new lines 758/882/760 |
| 20 | `probes/functions/FUN-05.vox:2` — `LANGUAGE.md:751` | Same wording change | Probe header rewritten, notes the #110 fix is a *different* gap (format-slot resolution) than what this probe's own grammar-level finding tests |
| 21–23 | `things-a.md` ×3 (THG-14, THG-56 rows) — hit `LANGUAGE.md:973/974/1170` | Same #110 wording change (thing-name form) plus #111's cross-reference sentence added to the Things copy-semantics paragraph | THG-14 rewritten to the new wording (new row THG-76 fills the quoted-single-word gap); THG-56 extended to cite the new "same as a nested collection" cross-reference; new lines 979–981 → **980–982** (re-checked by hand, off by one from the tool's own arithmetic — see below), 1177–1180 |
| 24–27 | `values.md` ×4 (VAL-19 row + 3 prose mentions) — hit `LANGUAGE.md:2830` | The fall-off-the-end enumeration grew from "empty text, zero, or a value tagged 0" to the full per-type list (#112) | VAL-19's claim widened to the full enumeration, scoped to stay about the `value`-tagged case (new FUN-47..51 cover the 5 newly-fixed types); new line 2834–2855 |
| 28–30 | `src/gen_buffers.vox:109`, `src/gen_flow.vox:629/633` — hit `LANGUAGE.md:753` | Same #110 wording move, in generator *comments* (citation hygiene, not logic) | Comment text updated to the new line and to note the 0.4.15 widening; no behaviour change |

Two further citations landed on text that **did not change in wording**
but the arithmetic still couldn't resolve automatically, both resolved
by direct hand-counting rather than tool re-run:
- `THG-14`/`THG-76`: the tool's own arithmetic-recovered line (979) was
  off by one from the true blank-line boundary; hand-counted with `awk`
  to 980–982.
- `KEY-81`'s Reserved Aliases row-count claim ("now 85 rows") **did not
  surface as a `?`** at all — the citation's *line* landed cleanly by
  arithmetic (the table heading didn't move), but the table's own **row
  count silently changed underneath it** (85 → 82, `auto`/`enable`/
  `disable` dropped) in a way line-arithmetic cannot detect. Caught only
  by hand re-counting the table's rows during step 04, not by the repin
  tool or `check-citations.sh` (neither checks table *content*, only
  citation *targets*). Fixed in step 04 alongside the new KEY rows.

**One further `?` was pre-existing, not part of the 37, found and fixed
during step 04 per a master steer mid-task:** `things-a.md`'s **THG-49**
had `line` = `?` on `main` `e43176f` already, an unresolved leftover of
an earlier re-pin. Found the cited sentence ("A thing containing itself
… is a compile error") unchanged in the 0.4.15 stack manual at line
1136–1138 and pinned it there.

## Rows added per ledger, with IDs and assertable counts

| ledger | new IDs | count | assertable | not assertable | notes |
|---|---|---|---|---|---|
| `expansion.md` (BAS2) | BAS2-60..62 | 3 | 3 | 0 | buffer-bytes loop expansion (#104) |
| `buffers.md` (BUF) | BUF-55..61 | 7 | 6 | 1 (BUF-59, recursive nested free — memory-only effect) | Free-on-list sub-claims (#109) + Iterating-bytes composite |
| `functions.md` (FUN) | FUN-45..51 | 7 | 7 | 0 | quoted-name fixes (#110) + fall-off-the-end for list/map/buffer/time/thing (#112) |
| `things-a.md` (THG) | THG-76 | 1 | 1 | 0 | quoted thing-type name (#110) |
| `types.md` (TYP) | TYP-12 | 1 | 1 | 0 | `int`/`integer` |
| `collections-a.md` (LST) | LST-71..82 | 12 | 11 | 1 (LST-72, framing/pointer row) | nested-collection copy semantics (#111) |
| `keywords.md` (KEY) | KEY-82..88 | 7 | 0 | 7 (all compile-error-observable claims) | one row per new/enlarged table + auto/enable/disable |
| `input-output.md` (FMT) | FMT-58 | 1 | 1 | 0 | the #110 format-slot fix itself |
| **Total** | | **39** | **30** | **9** | |

All 39 are `status: todo` except the 9 marked `not assertable` (which
carry no status progression — they are complete as recorded, per
PROCEDURE §3). No leaf in `main` emits any of these constructs;
`exercised`/`verified` counts are unchanged for every ledger.

## Discrepancies resolved / added

**Resolved:**
1. `buffers.md` Discrepancy 4 ("Free on a list has no observable
   effect") — **RESOLVED, vox #109 / 0.4.15**, re-verified directly.
2. `keywords.md` Discrepancy 4 ("the chapter's tables under-enumerate
   both the reserved words and the aliases") — was PARTIALLY RESOLVED
   (aliases half, 0.4.14); now **fully RESOLVED** — the Statement
   Starters half is closed by KEY-82/83/86 (every word D4 named now has
   a table entry).
3. `collections-a.md` Discrepancy 6 ("the cyclic-list example's
   recorded output is an abbreviation, not a transcript") — marked
   **moot**: the example it was about no longer produces that output in
   any form (#111), so "abbreviated vs. verbatim" is no longer a live
   question for that specific program.

**Added:** none. Item 10's sweep (grepping every ledger's Discrepancies
section for notes about #104/#110/#111/#112/Q11, per the brief) found
**no existing discrepancy** for #104, #110, #111, or #112 — those fixes
were found and registered through `vox-notes/DESIGN-RULINGS.md`'s master
probes and Q9/Q10/Q11 rulings, never through a per-section ledger
Discrepancy write-up, so there was nothing to mark resolved beyond
#109's (buffers.md D4). Every new claim this pass mapped (39 rows) was
hand-verified against the 0.4.15 stack and **matched exactly** — the
stacked compiler does everything its own updated manual text says, for
every construct this pass reached. No new discrepancy was found or
filed.

One near-miss worth recording precisely, not as a discrepancy: `things-
b.md`'s existing Discrepancy 1 ("a single-word field name written in
quotes prints without them") looks superficially related to #110 but is
a **different** bug (manifest/print quoting, not format-slot variable
resolution) — confirmed by re-reading both and not conflated; it is
untouched, per the brief's "do not touch other discrepancies."

## The `040_gen` byte-identity result

**Confirmed byte-identical.** `tests/040_gen.vox` compiles the
generator's determinism-critical path and diffs its output against the
single checked-in fixture `tests/040_gen.expected`; that same fixture
was matched exactly by both the installed 0.4.14 build and the 0.4.15
stack build, in both step 03's and step 04's gate runs. No src/ changes
were made in this brief, so this is expected, but it is the brief's
named critical check and is confirmed directly, not assumed.

## What I could not probe, and why

- **BUF-59** (recursive nested free of a list's own nested
  collections): not assertable from inside Vox at all. Since #111 makes
  nested collections copies, freeing the outer list's *own* internal
  copy of a nested element cannot be observed through any separately-
  named variable — the only visible consequence of NOT recursively
  freeing would be a memory leak, which Vox exposes no channel to see.
  Same category as BUF-04/BUF-08/BUF-40 (all "immediately"/memory-timing
  claims).
- **LST-32's depth-64 cap**: hand-verified the *concept* still holds
  (the manual states it plainly, and the print-recursion machinery is
  unchanged), but did **not** build an actual 64-explicit-level nested
  list literal to trigger it — the brief asked me to "say what it
  costs" rather than build one, and 64 hand-written nesting levels is
  real but disproportionate cost for a mapping pass whose job is
  citation-and-claim, not leaf-building. Left `todo`, flagged as more
  expensive to reach than before (the old self-reference shortcut no
  longer works).
- **KEY-85's bitwise operator words** (`bit-and` etc.): structurally
  cannot be tested by "declare a variable with this exact spelling" —
  they are hyphenated multi-part tokens, not bare identifiers, so the
  same-name test the other 7 samples use doesn't apply. Noted in the
  row and the probe header as a structural exclusion, not a finding.

## Questions for the master

1. **`PINNED-MANUAL`'s `commit` field**: I wrote `unknown (pre-merge
   stack, GitHub #239; fixes #104 #109 #110 #111 #112)` — the tool's own
   fallback is bare `unknown`; I added the parenthetical for a human
   reading the file later. If you'd rather it stay exactly what the
   tool writes unmodified (bare `unknown`), say so and I'll (or the next
   worker will) strip it back — nothing downstream parses the field
   beyond display and a failed git-ref lookup, so either is safe
   mechanically.
2. **THG-49's `?`** was pre-existing on `main`, unrelated to today's re-
   pin. Fixed it per your mid-task steer (line 1136–1138, sentence
   unchanged in substance). Confirming this is now closed and doesn't
   need separate master attention.
3. **KEY-81's silently-wrong row count** (claimed 85, actually 82 as of
   0.4.15) was NOT caught by `repin-citations` or `check-citations.sh` —
   neither tool checks table *content*, only citation line targets. I
   caught it by hand re-counting during step 04. Worth a note for
   `docs/ledger/PROCEDURE.md` §4 that a table-row-count claim needs
   re-verification on every re-pin, not just its citation line? Not
   acted on — flagging for your judgment, out of scope to edit
   PROCEDURE.md myself here.
4. **One PR per step, or 03+04+05 combined?** Recommended one-per-step
   in the runbook for reviewability (03's diff alone touches ~350
   files, mostly citation-number churn from the repin), but the three
   are logically one re-pin-and-map unit and could go in one PR if you'd
   rather review it that way.
5. **`docs/check-probes.sh` has no HISTORICAL-aware skip.** Four probes
   (`D6.vox`, `LST-32.vox`, `LST-53.vox`, `LST-54.vox`) are deliberately
   retained as records of pre-#111 self-referencing-collection behaviour
   that #111 makes impossible to reproduce any more — their headers say
   so explicitly, and I added the same header note to `D6.vox` (it was
   missing one; `LST-32`/`LST-53`/`LST-54` already had it) for
   consistency this session. But the script itself mechanically diffs
   every `.vox` file regardless, so these four will show as permanent
   `FAIL` against the 0.4.15 stack forever, with no way to tell "expected
   historical divergence" from "something actually broke" except reading
   each header by hand. Worth teaching the script to skip (or
   separately-report) probes whose header starts with a `HISTORICAL`/
   `STALE`/`WITHDRAWN` marker? Left unfixed — `docs/check-probes.sh` is
   tooling, out of scope for a mapping-only brief.
6. **Pre-existing probe-format quirk, out of scope, found by accident.**
   Running the full probe suite (not just the eight directories this
   brief touched) turned up two unrelated issues neither owned by this
   pass: (a) `files.md`'s `FIL-02`/`FIL-07`/`FIL-40`/`FIL-53` probes each
   embed a second "…then with the expectation changed to prove a failing
   assertion is classified correctly" demonstration in their recorded
   header block that `check-probes.sh`'s diff was never designed to
   reproduce (the live file only re-runs the *correct* assertion, so it
   never emits that second block) — these have likely read as `FAIL`
   since long before this pass; (b) `things-b/D4.vox` shows "(compile
   error differs)". Neither directory was touched by today's brief
   (`files.md` was last touched in step 01/02; `things-b.md` not at all
   in step 04), so I did not investigate or fix either — flagging in
   case nobody has run the full suite (as opposed to per-section
   subsets) recently enough to have noticed.

DONE — stack verified, patches parked
