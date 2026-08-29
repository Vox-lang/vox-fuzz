# Report — Things (part B), batch A

Worktree `wt-leaves-thingsb`, branch `feat/ledger-thingsb-a`, base main
`e43176f`. Ledger `docs/ledger/things-b.md`, prefix `THG2`. Environment:
`VOX=/usr/bin/vox`, `VOX_CORE_PATH=/usr/share/vox/coreasm` (installed
0.4.14, frozen tonight), `ulimit -c 0`.

## Rows covered

All eight leaves live in `src/gen_things.vox`, registered as kinds
185-192 under the comment `( ── things leaves, batch A, 2026-08-29 ── )`
in both files. Doc comments on every leaf name their row IDs; `grep <ID>
src/` finds each (checked for all nine IDs below).

| kind | leaf | rows | asserts |
|---|---|---|---|
| 185 | `gen leaf thing format whole` | THG2-06 | no — see "THG2-06: not assertable" below |
| 186 | `gen leaf thing equality` | THG2-08, THG2-09 | yes, `gen assert things equal`/`not equal` (Exit 95) |
| 187 | `gen leaf thing nested equality` | THG2-10 | yes, same helpers |
| 188 | `gen leaf thing free function` | THG2-21 | yes, `gen assert number is` (reused from gen_buffers.vox) |
| 189 | `gen leaf thing call prepositions` | THG2-27 | yes, same |
| 190 | `gen leaf thing extra argument` | THG2-30 | yes, same |
| 191 | `gen leaf thing field receiver` | THG2-32 | yes, same |
| 192 | `gen leaf thing type predicate` | THG2-70 | yes, `gen assert text is` (new helper) |

New shared prelude, unconditional and once per program (`gen build thing
predicate function`, `gen build thing functions`, both called from
`gen emit things block`, which already runs unconditionally as one of
the six ordered blocks):

- **THG2-70's dispatch function** — a `value`-parameter function with a
  rotated, six-branch `is a <type>` chain over the builtins, reusing
  `gen tag predicate`/`gen bare tag name` from gen_collections.vox
  (VAL-03's own machinery) rather than re-deriving the six-way split.
  Built even in a program with zero things.
- **THG2-21/27/30/32's function pair** — an ordinary global function
  taking a thing (no manifest entry, per LANGUAGE.md:1466-1470): an
  arity-1 form (field squared) and an arity-2 form (field × a number
  argument), built around a nested thing's inner type when one exists
  (so THG2-32 can drive it through a field), a plain thing otherwise.
  Names come out of the same `gen_function_words` cycle
  `gen build manifest functions` spends from, so they never collide
  with a manifest function.

### THG2-06: not assertable from inside

The ledger row itself says so (`assertable? no from inside`), and the
manual backs it: `Print` is the only sink that can interpolate a whole
thing (LANGUAGE.md:1347-1348), and interpolating one into a *text*
initializer — the only other place a rendering could be captured into a
comparable value — is rejected outright, naming the field to interpolate
instead (LANGUAGE.md:1349-1362). There is no route to a value the
program itself can compare. The leaf emits a bare `Print i{n}.` and a
format-string `Print "…{i{n}}…".` of the *same* instance, varying the
type/field/literal/phrasing every time; the two lines agreeing is the
harness's check, not the program's. I considered hand-building a third
"predicted rendering" line from the fields the generator wrote (which
the brief invited), but doing that correctly for the general case needs
the exact quote/brace escaping the manual's own D1 discrepancy
(quoted single-word field names) is already unsettled about, and I did
not want to encode a possibly-wrong reading of that as a second oracle.
I judged the two-line, harness-checked design the safer read of the
row's own `assertable?` verdict and stopped there.

## Tests

`tests/370_gen_things_b.vox` + `.expected` (numbers 370-379 allotted,
370 used) — one group per leaf, each leaf called directly (both
`nested=false` and `nested=true` for THG2-06 and THG2-70) after a fixed
seed builds a manifest with both a plain and a nested thing. Two more
groups prove the reset fix below: seed 1 (has things) run immediately
before seed 4 (zero things) in the same process, checking
`gen_thing_fn_ready`/`gen_thing_fn_nested_ready` come back `false` and
that a dependent leaf correctly stands aside, and a check that THG2-70's
predicate stays built and callable even with zero things. `./test.sh`
green (see Gate below); `340_repin_citations` clean; `check-citations.sh
src tests` reports 0 stale for this file.

`tests/040_gen.expected` and `tests/060_loop_gen.expected` regenerated —
required by common-brief point 3 for the first (the widened draw shifts
every seed's output), and by the discrepancy below for the second (see
"Gate").

## Hand-verification

Generated `--seed 1 --count 200 --budget 12 --layout plain --keep
<dir>`, read several by hand, compiled and ran two:

**seed_106.vox** (THG2-08, THG2-09, THG2-21) — output up to the point a
later, unrelated leaf needs the harness's env sandboxing:
```
...
{'the margin': 0, 'the chain length': 0, depth: 0, 'the elevation': 1}
the arc reading: {'the margin': 0, 'the chain length': 0, depth: 0, 'the elevation': 1}
927369
927369
1
1
```
No `ASSERT` line: `i3 is not i4`/`i4 is not i3` held with zero explicit
Sets (both fresh, all-default), and both call forms of `'the opening
gambit'` agreed on 927369 (the field the generator set, squared). This
program is part of the 200/200-compiled, 0-finding run below, so its
full run (env vars sandboxed, argv/stdin supplied) is independently
verified by the real harness; run bare from a shell it hits an
`environment's count is 0` assertion later in the file (ENV-*, not
mine) because a bare shell has a real environment.

**seed_127.vox** (THG2-06, THG2-27), run to completion, exit 0:
```
240224744594075522
-42
reassigned1
0
0
sb1 empty
0
54
55
55
56
55
56
56
57
```
(THG2-27's four `ASSERT`-guarded lines never fired — `c1`..`c4` all
matched the expected product — and neither did THG2-06's, which has
none by design.)

**Broken-assertion proof**, twice, on two different assertion helpers:

1. THG2-70 (text equality, `gen assert text is`): took seed_10.vox from
   an earlier campaign, changed `is not "float"` to `is not
   "wrongvalue"` on its one THG2-70 line. Compiled clean; ran to
   `Exit 95` with `ASSERT THG2-70: expected float got float` as the
   last line (the "got" is what actually happened, which now
   disagrees with the intentionally-wrong left side of the check).
2. THG2-08 (thing equality, `gen assert things equal`): took
   seed_106.vox, inserted `Set i4's 'the chain length' to 5.` between
   the two fresh instance declarations and the `THG2-08` check (making
   them genuinely differ where the unmodified program leaves them
   equal). Compiled clean; ran to `Exit 95` with `ASSERT THG2-08:
   expected i3 to equal i4` as the last line.

Both confirm the runner's exit-95 → wrong-value classification path
(reused from `gen assert number is`, already proven elsewhere, is not
re-tested here).

## Bugs found and fixed while building this batch

1. **Stale cross-program state.** `gen_thing_fn_ready` /
   `gen_thing_fn_nested_ready` were reset only inside `gen build thing
   functions`, which `gen emit things block` never calls for a program
   with zero things (it returns first). One process generates many
   programs in a loop reusing every global, so a things-free program
   inherited `true` (and a stale owner/field pair) from whichever
   earlier program in the same run last set it — hand-caught: seed 111
   of an early 200-program run emitted `a  called i1.` (blank type
   name) and called a function taking it. Fixed by resetting both
   booleans unconditionally at the top of `gen emit things block`,
   before the zero-things return; covered by the reset-fix groups in
   `tests/370`.
2. **Doubled article.** THG2-06's wrapping phrase read `"the {word}
   shows …"`, and `gen_field_words` mixes bare words with phrases that
   already open on "the" ("the arc", "the gradient"), producing "the
   the arc shows …" for every phrase entry — caught by reading the
   corpus, not by a compile failure. Reworded to `"{word} reading:
   …"`, which reads aloud regardless of which kind of word is drawn.
3. **An invariant with no citation.** THG2-70's dispatch function's
   trailing `Otherwise` branch returned a fixed string, `"unrecognised"`
   — unreachable by any call this batch's leaves write (all six tags
   are covered and nothing passes `nothing`), but on the page in every
   program regardless, so it showed up in the invariants diff as a
   100%-present identical statement with no citation. Fixed by drawing
   the fallback label from `gen_field_words` instead — see "Invariants"
   below for the measurement.

## Campaign

Gate/invariants campaign (plain layout, per common-brief point 6):
```
VOX=/usr/bin/vox VOX_CORE_PATH=/usr/share/vox/coreasm \
  vox-fuzz gen --seed 1 --count 200 --budget 12 --layout plain --keep <dir>
```
Run twice (before and after the "unrecognised" fix): **200/200
compiled, 0 findings** both times. All nine row IDs appear in the
corpus (THG2-06 in 21/200 after the sentence fix; THG2-08/09 in 20/200;
THG2-10 in 17/200; THG2-21 in 14/200; THG2-27 in 30/200; THG2-30 in
22/200; THG2-32 in 11/200; THG2-70 in 23/200 — from the pre-fix run,
counts are unaffected by that fix).

Baseline: `git archive e43176f | tar -x -C <dir>`, built, same seeds
(`--seed 1 --count 200 --budget 12 --layout plain`): 199/200 kept (one
transient "cannot stat" scratch-race on this shared machine, not
reproduced on retry, unrelated to this branch — main's own `vox-fuzz
gen` writes scratch under the invoking process's CWD and this was run
from inside the worktree). Not chased further since it does not touch
anything this batch owns.

## Invariants delta

`scripts/invariants` over both corpora (`--layout plain`), diffed by
key (category + finding text, percentage stripped):

**New, justified:**
- `fixed-vocabulary` — the identifier `THG2` (100%, same as pre-existing
  `ASSERT`/`expected`/`got`/`VAL`/`BUF`): the ledger-assertion message
  format `ASSERT <ID>: expected <x> got <y>` is a declared rule
  (PROCEDURE.md §6, cited already for VAL-* and BUF-*'s row-prefixes);
  THG2 is the same protocol, same citation, new prefix.

**New, fixed before this report** (see "Bugs found" #3): the
`Otherwise,Return a text,"unrecognised".` identical-statement and the
`unrecognised` fixed-vocabulary row are gone from the post-fix corpus.

**New, threshold noise from shared, pre-existing mechanisms** (not a
new kind of sameness — the underlying mechanism is unchanged and
already visible on main's own report, e.g. main shows `l1` at 51%; this
branch's extra per-program draws from the same cycles just shift which
specific token crosses the 50% suspicion line): `i1`, `c1`, `balance`,
`whole`, `q1s5`.

**Worth the master's attention, not mine to fix (out of surface):**
`decimal` at 62-63% (124-126/200) — `gen tag predicate`'s tag-2 branch
(gen_collections.vox, VAL-03's own code, reused here for THG2-70) draws
the decimal/float spelling with a bare `'rng below' of 2`. This
generator's own comments elsewhere (`gen leaf loop control`, `gen leaf
thing`'s draw, `gen build one method`) document that this LCG's low
bits are correlated and specifically avoid `'rng below' of 2` for a
coin flip because of it, using a prime modulus instead. THG2-70 draws
this coin exactly once, unconditionally, per program (via the shared
predicate-builder), so if the correlation is real it shows up directly
as a skewed split; I did not have a citation-worthy fix in scope
(gen_collections.vox is outside this batch's surface) so I am
flagging it rather than touching it.

## Candidates the leaves turned up

**A newline immediately before the call preposition, in the instance-
possessive extra-argument form, fails to parse — for all four
prepositions, only under random layout.** Not a THG2-30 wording issue;
reproduced with hand-written minimal programs below. `--layout plain`
never triggers it (plain layout never places whitespace inside one
rendered statement), which is why the 200/200-plain-compiled campaigns
above never saw it; a `--layout random` spot-check (`--seed 500 --count
200 --budget 12`) on this branch got 193/200 compiled against main's
200/200 on the identical seeds — 6 of the 7 gap programs hand-confirmed
below, all the same root cause, the 7th not chased further.

Minimal repro (hand-verified, `VOX_CORE_PATH=/usr/share/vox/coreasm
/usr/bin/vox r.vox -o p`):
```vox
A thing called point has
  a number called x is 0.

To 'scaled' with a point called corner and a number called factor.
  Return a number, corner's x multiply factor.

a point called origin.
Set origin's x to 3.
a number called c1 is origin's 'scaled'
    of 2.
Print c1.
```
compiles and prints `6` with a plain space before `of`; replace that
space with a newline (`origin's 'scaled'\n    of 2.`) and every one of
`of`/`to`/`with`/`on` fails, in two different ways depending on which
word follows:
- `of`, `to`, `with` → `error: Expected a statement, got <Of|To|With>`
- `on` → `error: Expected 'error' after 'on'` (`Syntax: On error
  <action>.`) — because `on` is *also* a valid statement-starter (the
  `On error` clause), so the parser's own error is more specific for
  that one spelling, not a different bug.

Actual campaign-generated instances (both branches confirmed
byte-identical across two independent runs of the same seed):
```
$ vox /tmp/vf_060_check/seed_3.vox
error: Expected a statement, got Of
  a number called c1 is i3's 'the final answer'
       of 7292.
```
```
$ vox seed_511.vox   (from the --seed 500 random-layout spot-check)
error: Expected 'error' after 'on'
  Syntax: On error <action>.
  a number called c1 is i1's 'gather the parts'
    on
       00052.
```
The strongest pro-compiler reading I can construct: `receiver's
'member'` alone is a grammatically complete statement (an arity-1
receiver call reached the same way THG2-21/32 already exercise, and
`gen leaf thing member` — on main, unaffected by this — never gives it
anything to continue with), and something about seeing a newline right
there, rather than a plain space, makes the parser commit to "this
sentence is finished" instead of keeping the clause open for a possible
trailing preposition. That would make it a genuine parser gap around a
construct this ledger's own THG2-30 is the first leaf anywhere in this
generator to emit (`gen leaf thing member`'s receiver call takes no
further arguments, and no existing leaf calls a member through the
instance possessive with an extra argument at all) — I did not have a
way to test whether the free-call form's `'name'\n    of arg` (which I
separately hand-verified still compiles fine) shares the same
"statement already complete" mechanism or a different one.

I left THG2-30 emitting exactly what the row asks for (all four
prepositions are the row's own claim) rather than narrowing it to avoid
the fragile shape — the compile failure is deterministic per seed, not
a hang or a crash, and regenerating `tests/060_loop_gen.expected`
(`compiled: 5` → `compiled: 4`, its own `compiled at least 4 of 5: 1`
line unchanged) was enough to keep the gate green; see "Gate" below.

## Gate

`./test.sh` (with `LANGUAGE_MD=$PWD/docs/ledger/pinned/LANGUAGE.md`,
per common-brief 2026-08-29 point 5): **24-25 passed, 6-7 failed**,
run four times across this session. The failure count varies only in
one slot (`210_scratch_sandbox` or `060_loop_gen`, each timing-
sensitive under this shared machine's concurrent load — another
worker's own `test.sh` was running at the same time in
`wt-leaves-filesb`); both pass cleanly every time run in isolation.
The other six — `070_cli`, `100_asm_reject`, `110_out_injection`,
`120_out_spaces`, `130_repro_spaced_vox`, `240_concurrency` — fail
identically on a clean `e43176f` extract with the same environment,
confirmed by running each in isolation there; pre-existing, unrelated
to this batch. `check-citations.sh`: 724 checked, 0 stale.

`tests/370_gen_things_b` (new) and every pre-existing `gen_*` test
pass. `tests/040_gen.expected` and `tests/060_loop_gen.expected`
regenerated as described above (both from running the actual test
file, never hand-edited).

## My raw draw span and offset (gen_statement, gen_core.vox)

Raw span **82-89**, offset **+103**, giving kinds **185-192**. My local
widening (`'rng below' of 65` → `90`, plus one bounded remap) is
depth-3 only and is marked in a comment as discard-at-merge, per
common-brief 2026-08-29 point 2 — it also neutralises raw 65-81 to kind
1 (assign) rather than let it fall through the pre-existing "greater
than 49" remap, which was written assuming nothing above 64 was ever
drawn. The registration block in `gen dispatch leaf` (kinds 185-192)
is the part meant to survive the merge.

## Questions for the master

1. The `decimal` vocabulary skew (Invariants delta, above) — is
   `gen tag predicate`'s bare `'rng below' of 2` worth a prime-modulus
   fix on the collections surface, given the same LCG-correlation
   caveat is already documented (and worked around) three other places
   in this generator?
2. The newline-before-preposition parser gap (Candidates, above) — is
   this genuinely a parser limitation worth `vox-language-lawyer`'s
   attention, or is there a documented rule about statement completion
   after a receiver call that I did not find? I left THG2-30 emitting
   the construct as the row demands rather than guessing.

## What I could not do

Batch B's THG2-39 (member names belong to their owner) and THG2-49/50/
52 (cross-file via `see`) were explicitly deferred to a later batch by
my brief; not attempted here.

## Review round 1

Accepted in substance; two fixes applied, generator-local, no change to
any emitted fuzz-program text:

1. **Name collision at merge.** `gen assert text is` (mine) collided
   with the buffers batch's own `gen assert text is` (already ahead of
   me in the pending merge, a different two-element-list signature).
   Renamed mine to `gen assert text equals` — definition and its one
   caller in `gen leaf thing type predicate`.
2. **Style.** The bare locals `decl`/`decl1`/`decl2` across all eight
   leaves → `'the instance declaration'` / `'the first declaration'` /
   `'the second declaration'` (THG2-70's, which declares a call result
   rather than a thing instance, → `'the result declaration'`); the
   `gen_thing_fn_*` globals → `gen_thing_function_*` (`fn` is a banned
   abbreviation); the squaring/scaling function pair's letter-named
   locals (`'the a phrase'`/`'the b phrase'`, `gen_thing_fn_a_written`/
   `…_b_…`, `'the a param'`/`'the b param'`) → named by role
   (`'the squaring phrase'`/`'the scaling phrase'`,
   `gen_thing_function_squaring_written`/`…_scaling_…`,
   `'the squaring parameter'`/`'the scaling parameter'`, and `param` →
   `parameter` throughout that block to match the spelled-out
   convention `gen fresh parameter phrase` already uses everywhere
   else). `tests/370_gen_things_b.vox` updated to reference the renamed
   globals in its own reset-fix assertions; its one `Print` line that
   names the globals as a header string was left reading `gen_thing_fn_
   *` so the golden stays byte-identical (confirmed by diff), per the
   "no golden regeneration" instruction — the doc comment two lines
   above it uses the new name, so that one line is now the odd one out
   cosmetically, not functionally.

Rebuilt, diffed `tests/370_gen_things_b.expected` and
`tests/040_gen.expected` against fresh runs (both byte-identical, no
regeneration needed), then `./test.sh` (`LANGUAGE_MD` set as before):
**25 passed, 6 failed** — the same six pre-existing failures as the
original submission (`070_cli`, `100_asm_reject`, `110_out_injection`,
`120_out_spaces`, `130_repro_spaced_vox`, `240_concurrency`), both
`210_scratch_sandbox` and `060_loop_gen` clean this run; `check-
citations.sh`: 724 checked, 0 stale. Re-parked to the same patch path.

DONE — stopped staged, patch parked
