# Report — Things ledger, batch A (worker)

Worktree `wt-leaves-things`, branch `feat/ledger-things-a`. Vox v0.4.14
(installed, `/usr/bin/vox`), `VOX_CORE_PATH=/usr/share/vox/coreasm`, per
the common brief. Manual pin per `docs/ledger/PINNED-MANUAL`: commit
`4995394`, 5756 lines, version 0.4.14 — the surface brief's line numbers
(921–1301 for the section, and each row's individual citation) were
hand-checked against `docs/ledger/pinned/LANGUAGE.md` and match exactly.

**Rows: THG-12, THG-25, THG-34, THG-37, THG-58, THG-64.**

## Design note, read first

Every existing thing leaf in `src/gen_things.vox` asks the shared
manifest (`gen_manifest.vox`) for a thing it already built. That does
not work for these six rows: each needs a field-default *shape* the
manifest cannot guarantee on request (a specific field undefaulted, or a
default the leaf must know in advance to assert against — the manifest
decides "has a default or not" with a fresh RNG draw at *emission* time
in `gen_things.vox`'s own `gen field default written`, and never records
which way it fell). So each new leaf builds and emits its **own** fresh
thing type(s) — and for THG-58/64, a fresh plain function — rather than
drawing one from the manifest.

Names are spent from the manifest's *existing* vocabularies
(`gen_type_words`/`gen_field_words`/`gen_function_words`) through their
already-once-per-program-reset `spent`/`offset`/`stride` state, exactly
the way `gen build manifest extras` spends two more function names after
the ordinary ones. `gen cycled word`'s own disambiguating-suffix-per-lap
behaviour is what makes this safe against repeat draws of the same new
leaf kind in one program — verified directly (see "names" test below),
not assumed.

A thing definition (and a plain function definition) is legal only at
the true top level (LANGUAGE.md:931, THG-03) — hand-verified against
0.4.14 that a fresh definition may sit *anywhere* among a program's
top-level statements, not only at the very start (`p6.vox` probe, not
retained). So all five new leaves are registered **top-level-only**:
`src/gen_core.vox`'s `gen dispatch leaf` gets five new entries (kinds
180–184, the "things" span the reservation table set aside), and
`gen statement`'s depth-3 draw widens from 65 to 70 with the tail
remapped onto 180–184, mirroring the existing 100–104/140–154 bands
exactly. Both edits are inside clearly marked
`( ── things leaves, batch A, 2026-08-28 ── )` blocks, as four other
workers are widening this same draw tonight for their own reserved
spans — the master reconciles the total by hand (noted in-line in the
diff, per `docs/ledger/PROCEDURE.md` §6).

## Rows covered

| row | leaf | asserts | doc comment cites |
|---|---|---|---|
| THG-12 | `gen leaf thing zero default` | yes | THG-12 |
| THG-37 | `gen leaf thing pinned defaults` | yes | THG-37 |
| THG-25, THG-34 | `gen leaf thing declaration forms` | yes | THG-25, THG-34 |
| THG-58 | `gen leaf thing param copy` | yes | THG-58 |
| THG-64 | `gen leaf thing nested param copy` | yes | THG-64 |

**THG-12** — a fresh thing gets one undefaulted field of each of the
four zero-having kinds (number, float, boolean, time), in a random
field order (a 24-entry permutation table, since nothing pins order);
each is read back before any write and asserted against the *rendered*
zero: `0`, `0.0`, `0`, `0` respectively — the float check compares
against the literal `0.0`, hand-verified against 0.4.14 that
`If sample's drift is not 0.0 then` both compiles and holds for a fresh
float field (a bare `0` would be the wrong literal for this type).

**THG-37** — a fresh thing gets exactly the row's own shape: a float
field and a boolean field, each *always* carrying a random declared
default, and a number field that *never* does, in one thing, random
order (a 6-entry permutation table). All three are asserted: the float
and boolean against their declared literal, the number against 0.

**THG-25 / THG-34** — a fresh thing gets 1–3 fields of random kind
(number/float/boolean), each with a random declared default; one of the
three declaration forms is drawn at random (bare `a T called N.`,
`Create a T called N.`, or `a T called N.` followed by
`Set a T called N2 to N.`) and every field of the resulting instance is
asserted against its declared default. Over a campaign this exercises
all three forms; any one draw hits `Create` about a third of the time
(THG-34's row). I considered a dedicated always-`Create` leaf for
THG-34 alone but folded it into the same leaf instead, on the same
precedent the ledger already uses for sibling rows sharing one leaf
(e.g. THG-58's probe also covers THG-59–63) — flagging this choice
explicitly since the brief separates the two rows.

**THG-58** — a fresh function takes a fresh thing type by value, writes
its parameter's one number field (`add` a random 1–50 delta, itself
holding a random signed base value), and returns it. The caller's own
instance is asserted **unchanged**; the returned instance is asserted
**mutated** — the write cannot escape the call, and `Return` is the only
way a change reaches the caller (THG-59, exercised for free).

**THG-64** — a fresh outer thing nests a fresh inner thing; the same
mutate-and-return shape as THG-58 is called with the **chained
possessive** `segment's inner-field` as its argument — hand-verified
against 0.4.14 that this compiles and copies exactly like a flat
argument does (`p8.vox`/`p9.vox` probes, not retained — the retained
`docs/ledger/probes/things-a/THG-64.vox` already covers the underlying
claim by hand). The segment's own field is asserted untouched afterward;
the call's returned copy is asserted mutated.

All five reuse `gen_buffers.vox`'s generic assert helpers
(`gen assert number`, `gen assert true`, `gen assert false`) rather than
writing new ones, per `docs/ledger/PROCEDURE.md` §6a — despite the name,
`gen assert number` is a plain "compare this expression against this
literal" helper and works unchanged for a thing-field subject.

## Tests

`tests/350_gen_things_a.vox` + `.expected` — one file for the whole
batch, modelled on `tests/300_gen_buffers_a.vox`: each leaf called
directly off a pinned `rng seed` (`gen reset manifest cycles` standing
in for `gen buffer names reset`) with its emitted source printed
verbatim as the golden, plus a final section calling all five leaves
back-to-back in one program to prove no name repeats across them. Only
`350` was used of the allotted 350–359.

`tests/040_gen.expected` was regenerated: widening `gen statement`'s
depth-3 draw from 65 to 70 shifts the RNG-to-kind mapping for *every*
seed, including 42, so the existing golden dump was stale through no
fault of its own content — confirmed by diffing before/after and seeing
only the expected wholesale reordering of the tail of the program, not
a semantic break. (The master will need to do this reconciliation again
once all four parallel batches' widenings are merged together.)

`./test.sh` is green: 31 passed, 0 failed (includes `200_never_emitted`
at budget up to 300, `270_layout` re-running the corpus through every
layout, and `230_units`'s disjointness check, all unaffected by this
batch except through the reproducibility-shifted `040_gen`).

## Hand-verification

Generated `--seed 5001 --count 200 --budget 12 --layout plain --keep
vf_scratch/things-a-batch-a` (below). Two samples, read and run by hand
under `timeout 20`, both clean (no `ASSERT` line, i.e. every check held):

**`seed_5002.vox`** (THG-37, THG-64) — compiles clean; runs to
`exit 40.` (a plain, unrelated exit the generator drew elsewhere in the
same program) after printing values matching every field it wrote,
including a `beacon` thing with an undefaulted `span` reading back `0`,
a defaulted `fall` reading back its float literal, and a
`i2's 'the datum'` chained possessive left untouched (`-112`) after
`'add them together' on i2's 'the datum'` returned a copy reading `-81`.

**`seed_5097.vox`** (THG-58) — compiles clean; runs to `exit 68.`
(likewise unrelated). Relevant lines:
```
a coordinate called i1.
a coordinate called i2 is 'the summed parts' with i1.
If i1's 'the drop' is not 245 then, Print "ASSERT THG-58: expected 245 got {i1's 'the drop'}", Exit 95. Print i1's 'the drop'.
If i2's 'the drop' is not 258 then, Print "ASSERT THG-58: expected 258 got {i2's 'the drop'}", Exit 95. Print i2's 'the drop'.
```
`i1`'s field stayed 245 (the caller's copy, untouched); `i2`'s reads 258
(245 + the drawn delta of 13) — the mutation reached only the returned
copy.

**Broken-assertion proof (exit 95):** patched `seed_5097.vox`'s first
`THG-58` condition from `is not 245` to `is not 246` (message text left
alone, so the mismatch shows):
```
$ ./broken
ASSERT THG-58: expected 245 got 245
$ echo $?
95
```
`src/loop_gen.vox:381` (`If 'the exit code' is 95 then, ...`) is exactly
the branch that classifies this as the ledger's wrong-value finding
class — confirmed by reading the runner, not just by the raw exit code.

THG-12 and THG-25/34 were additionally hand-verified directly off pinned
seeds via the driver used to build `tests/350_gen_things_a.expected`
(seeds 1–7), all clean; e.g. seed 1's `sounding` thing (undefaulted
number/float/boolean/time fields, random order) read back `0`, `0.0`,
`0`, `0` exactly as THG-12 claims.

## Campaign and invariants

```
systemd-run --user --scope -q -p MemoryMax=3G timeout 300 \
  ./build/vox-fuzz gen --seed 5001 --count 200 --budget 12 \
  --vox /usr/bin/vox --core /usr/share/vox/coreasm \
  --keep vf_scratch/things-a-batch-a --layout plain \
  --out vf_scratch/things-a-findings
```
`programs: 200, compiled: 199, findings: 0.`

`scripts/invariants` over the kept corpus: 45 findings at or above the
50% threshold. None trace to a specific name or shape my five leaves
fixed — no field/type/function word my leaves draw (e.g. "the opening
gambit", "the boundary stone") appears in the report at all, consistent
with spending from the shared, cycled vocabulary rather than a fixed
choice. The one new *category* item, `THG` at 62% (124/200 programs)
under `fixed-vocabulary`, is the ledger ID embedded in
`ASSERT THG-NN: ...` text — justified the same way the pre-existing
`BUF` (57%) and `VAL` (95%) rows already in the same report are: the
convention every ledger's leaves share (`docs/ledger/PROCEDURE.md` §6),
not a pattern this batch invented. Every other finding (`v1`, `i1`,
`q1s1`–`q1s9`, the `sb#`/`sc#` buffer-read templates, `Parse flags.` at
65%, common field words like `bearing`/`offset`/`depth`/`height` at
50–51%) belongs to leaves outside `gen_things.vox` or to the shared,
finite `gen_field_words`/`gen_type_words` pools every thing leaf (mine
and pre-existing) draws from — not something this batch's five leaves
newly caused. I did not build a `main`-branch baseline campaign to
produce a literal before/after diff — `docs/ledger/PROCEDURE.md` §7
assigns that reconciliation to the master after all four parallel
batches land, and duplicating a full second build/campaign here would
not change the finding above.

## Candidates — none found (no compiler/manual surprise)

## Generator defect found — not mine, not touched, reported instead

One of 200 kept programs, `seed_5159.vox`, failed to compile:
```
error: A thing is defined at the top level, like a function
  ...
  --> vf_scratch/things-a-batch-a/seed_5159.vox:151:3
```
Root cause, confirmed by reading the surrounding source (line ~148):
```
For each ce4 from 1 to 24,
    a number called cs4 is ce4 multiply 2,
    If cs4 is greater than 24 then, Break.
A thing called 'the boundary stone' has
    ...
```
This is `gen_misc.vox`'s pre-existing `gen leaf cast and break` (kind
35, on `main` at `c7dd9eb`, untouched by this branch —
`git diff main -- src/gen_misc.vox` is empty). Its own doc comment
says outright: *"The guard's period closes only the If (LANGUAGE.md
rule 1), so the loop body continues to the comma-joined line after it,
which is why the print sits inside the loop rather than after it."* —
but the leaf's actual `'the lines'` list has no trailing plain statement
after the `Break.` guard the way `gen leaf loop control`'s sibling shape
does (a `Print "x"` after its own `Break.`, which is exactly what lets
`gen join lines`'s trailing period close the `For each`). Here nothing
follows, so the `For each` is left open by design and swallows
whichever statement the generator draws next — silently, for any
ordinary statement (which stays legal nested one level deeper than
intended, a semantic bug invisible to a compile check), and loudly for
a thing/function definition, which cannot legally appear nested at all.
This is why it took a definition-emitting leaf — the first of that kind
in the generator — to expose a defect that has apparently been latent
since `gen leaf cast and break` was written on 2026-08-20.

I have not touched `gen_misc.vox` (out of scope for this batch) and have
not filed this anywhere — flagging it here for the master. The fix
looks like a one-line addition of a trailing statement after the guard
line (e.g. `Print cs{n}.`), the same shape `gen leaf loop control`
already uses for the identical situation.

## What I could not do / scope notes

- No row was left `todo`; all six are asserted.
- I did not produce a literal `main`-vs-branch invariants diff (see
  "Campaign and invariants" above) — deferred to the master per
  PROCEDURE §7, with my own read of the report included instead.
- The THG-25/THG-34 shared-leaf choice (one leaf, random form) is
  flagged above for the master's judgement rather than decided
  unilaterally.
- Per the master's mid-flight note, no `AskUserQuestion` was used at
  any point; both open judgement calls above (the shared leaf, and
  deferring the full invariants diff) were made from the brief's stated
  defaults and PROCEDURE's own division of labour, and are stated here
  rather than asked.

## Review round 1

Applied the master's four generator-local renames (bare `decl` →
`'the instance declaration'` in the two leaves that had it; the five
number-holding `'... name'` locals → `'... instance number'`; `'gen
things a boolean literal of'` → `'gen things a boolean literal'`; `'the
check'` → `'the field checked so far'`). Confirmed `tests/350_gen_things_a`'s
golden is byte-identical (no emitted-output change), then `make build &&
./test.sh` green at 31/31.

## Answers to the master

The failing seed was **5159** (from `--seed 5001 --count 200`, i.e.
seeds 5001–5200). Recompiling it alone reproduces deterministically —
`./build/vox-fuzz gen --seed 5159 --count 1 --budget 12 --vox
/usr/bin/vox --core /usr/share/vox/coreasm --keep
vf_scratch/things-a-repro --layout plain` regenerates the identical
`seed_5159.vox`, and `vox seed_5159.vox -o p` fails with `error: A thing
is defined at the top level, like a function ... --> :151:3`, the exact
diagnostic quoted above (root cause: `gen_misc.vox`'s pre-existing `gen
leaf cast and break` leaves a `For each` clause open, and my new
top-level-only leaf's definition is what it swallows). It was not saved
as a finding because of how `src/loop_gen.vox`'s own classification
works, not because I filtered anything: `classify compile exit`
(`loop_gen.vox:27-32`) maps a compiler exit code to exactly four
buckets — `hang` (negative), `ice` (>128 or 101, a crash/panic),
`ok` (0), and everything else, including this ordinary exit code 1, into
one `check-asm` bucket. That bucket only becomes a `finding` if the
captured stderr matches a specific NASM/linker-toolchain failure
signature (`loop_gen.vox:312-328`); mine is a plain semantic diagnostic
with none of those strings, so the check falls through, the program is
counted in neither `compiled` nor `findings`, and its scratch directory
is swept immediately (`'scratch dir sweep'`, same branch) — which is
also why the campaign's own stdout showed transient `grep:
.../vf_cerr: No such file or directory` lines for a few seeds even in
the first, contention-corrupted run: the runner deletes that directory
right after using it. I found seed 5159 the only way the harness makes
possible right now — diffing `programs: 200` against `compiled: 199`
and recompiling every kept file myself — not from any finding record,
because none was written; a plain compile-error diagnostic on a
malformed generated program is presently invisible to
`src/loop_gen.vox`'s finding system by design (it only watches for
compiler crashes, hangs, and toolchain-stage failures), which is a gap
in the harness worth the master's attention alongside the
`gen_misc.vox` root cause itself.

The kept corpus (`vf_scratch/things-a-batch-a/`, 200 files) is gone — I
deleted it myself after finishing the report, on the reflex that
`vf_*` is gitignored and ephemeral, without weighing that the master
would want to inspect the actual repro; that was a mistake, noted so it
isn't repeated. I have since regenerated the one file that matters,
deterministically, at `vf_scratch/things-a-repro/seed_5159.vox` in this
worktree, with the command above; it reproduces the identical failure
and is left in place for inspection rather than swept again.

DONE — stopped staged, patch parked
