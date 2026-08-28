# Report: Defect 16 — a pool-name collision lets one leaf capture another's binding

Branch `fix/d16-scratch-name-reserved`. Worktree
`~/scr/english/worktrees/wt-fuzz-d16`. Not committed — staged
(`git add -A`) and parked for Josj to sign.

## Summary

Two leaves (`gen_files.vox`'s `'gen leaf file round trip'`,
`gen_buffers.vox`'s `'gen leaf buffer truncation'`) build a path from
`{gen_scratch_flag}` — the harness's guarantee that a scratch-role flag
exists and holds the confined scratch directory, whenever a program
does file I/O. Neither checked that the guarantee actually held; they
trusted a comment ("It is never empty here"). Both now check it
themselves: if `gen_does_file_io` is true but `gen_scratch_flag` is
empty, the leaf prints `PROBE g3` and falls back to the safe stand-in
leaf instead of ever emitting a path built on the unbound name.
`tests/230_units.vox` gained nine empirical rows proving the binding
holds across 1000 generated programs (pool-vs-FIXED-binding
disjointness, the way the file already proves pool-vs-pool). No pool
word removed, no draw added — seeds 900000–900199 at budget 40 are
byte-identical to `main`, 200/200. `make build` + `./test.sh`: 30/0.

**The four historical seeds do not reproduce a live finding on any
build tried, including the campaign's own vox 0.4.12 binary on the
unmodified `22e5479` generator.** This is reported plainly, not papered
over — see "The reproduction gap" below. The source-level collision the
ledger describes is real and confirmed on all four seeds; the fix
closes the hazard class regardless of what exactly triggered the
original four findings.

## What changed, per file

- **`src/gen_files.vox`** — `'gen leaf file round trip'`: added an
  `If gen_does_file_io ... gen_scratch_flag is empty` guard right after
  the existing `gen_does_file_io is false` guard, printing `PROBE g3`
  and falling back to `'gen leaf print'` (the same stand-in the
  existing guard already uses) rather than building
  `"{gen_scratch_flag}/out{n}"` on an empty name.
- **`src/gen_buffers.vox`** — `'gen leaf buffer truncation'`: the same
  guard, falling back to `'gen leaf buffer properties'` (its existing
  stand-in).
- **`tests/230_units.vox`** — new "Pool-vs-FIXED-binding disjointness"
  section, after the existing pool-vs-pool block: two small helpers
  (`'count number equal to'`, `'the scratch role written name'`) plus a
  1000-seed trial loop calling `'gen program'` (the real
  manifest+argv-building path) and checking, after each call:
  - `gen_scratch_flag` is never empty while `gen_does_file_io` is true;
  - exactly one flag ever carries role 1, and its written name always
    equals `gen_scratch_flag`;
  - the argv-stress builder (`gen_text_flag`/`gen_number_flag`/
    `gen_boolean_flag`, set by `'gen build argv'` via `'gen manifest
    pick a flag of kind'`) never resolves to that flag;
  - `gen_reader_name` never equals `gen_grid_sink_name`, and neither
    ever equals any ordinary function's or flag's written name.

  Nine `Print` rows, all reading 0. (`tests/230_units.expected`
  regenerated to match — only these nine lines were added; nothing
  upstream of them changed.)
- **`docs/FUZZER_DEFECTS.md`** — Defect 16 entry, marked fixed, with
  the reproduction gap recorded in full (house style: what was proven,
  what was not, handed to Josj explicitly).

## Enumerating the FIXED expectations (the brief's own instruction)

Grepped every `src/*.vox` for a leaf writing `{gen_<something>}` into
generated output — i.e. every name a leaf expects to find already
bound rather than drawing itself:

| Name | Drawn from | Threading | Needed a guard? |
|---|---|---|---|
| `gen_scratch_flag` | `gen_flag_words` (flag cycle) | once, in `'gen build one flag'`; read by 2 leaves | **yes — this defect** |
| `gen_reader_name` | `gen_function_words` (function cycle, same cycle as ordinary functions) | once, in `'gen build manifest extras'` | no — same-cycle distinctness already proven by the new empirical rows |
| `gen_grid_sink_name` | `gen_function_words`, same cycle | once, same function | no — ditto |
| `gen_grid_sink_local` | `gen_parameter_words` (the parameter/local cycle) | once, same function | no — function-LOCAL name; lives in the per-function local space (LANGUAGE.md:1692), the same space `gen_parameter_words` is already exempted from in the pool-vs-pool block above, so it was never a candidate for a top-level collision |

Every other `{gen_<counter>}` interpolation in the generator
(`{gen_texts}`, `u{gen_whiles}`, `fp{n}`, `{gen_buffer_names}`, …) is a
monotonically-incrementing NUMERIC suffix on a fixed letter, not a word
drawn from a pool — unique by construction, never a candidate for this
class of collision, and not enumerated further.

## Why the fix is a guard, not a pool change

The fix direction offered two options: reserve a fixed literal out of
every pool that shares its identifier space, or draw it once and
thread it. `gen_scratch_flag` already does the second — it is drawn
from `gen_flag_words` exactly like an ordinary flag, through the same
cycle, and stored in one variable that both leaves read. There was no
literal to reserve. What was missing was any code checking that the
threading actually held; the fix supplies that check, converting an
assumption (stated only in a comment) into an enforced invariant with
a regression test behind it.

## Distributions are untouched (rule 1)

Both guards are a single `is empty` check with no `'rng below'` call —
they consume nothing from the RNG stream, and in every trial run so far
the guarded branch is unreached (the invariant already held). The
byte-identity gate below is the proof, not just the reasoning: no pool
word was touched, so there was nothing to justify removing.

## The reproduction gap

Read in full before treating this defect as closed on the strength of
"the fix looks right" alone.

**Re-derived the source-level collision on all four proven seeds**
(`22e5479`, vox `0.4.12` rebuilt from the `v0.4.12` tag to match the
SEEDS.md row exactly) before writing any fix:

| Seed | Scratch flag drawn | Declaration (cleaned of layout whitespace) |
|---|---|---|
| 100103 | `caption` | `caption is "-p" or "--caption", it is a text.` — path `"{caption}/buffer2"` |
| 101434 | `layby` | `layby is "-u" or "--layby", it is a text.` |
| 101707 | `coupon` | `coupon is "-q" or "--coupon", ...` (program also has two unrelated ordinary flags — `voucher`, `legend` — confirming the collision is specifically with the scratch role, not "any flag") — path `"{coupon}/buffer4"` |
| 101964 | `subtitle` | `subtitle is "-h" or "--subtitle", ...` — paths `"{subtitle}/buffer1"`, `"{subtitle}/buffer2"`, `"{subtitle}/out3"` |

All four match the ledger's account of the pattern exactly.

**None of the four reproduce a live finding**, tried every way
available without a human-supplied detail of the original invocation:

- Solo, `--count 1`, budget 40, on unmodified `22e5479` against
  today's vox: 0 findings, all four.
- Same, against a freshly built vox `0.4.12` (the exact binary/coreasm
  the campaign's SEEDS.md row cites, ruling out a compiler-version
  difference): 0 findings, all four.
- Same, on today's HEAD (`git diff 22e5479..HEAD` is empty for
  `gen_manifest.vox`, `gen_files.vox` and `gen_buffers.vox` — those
  three are byte-identical. `loop_gen.vox` is NOT: it gained 8 lines in
  `7106bcc` (Defect 14) that capture `findings_argv` /
  `findings_scratch_flag` for `repro.sh`, placed BEFORE the scratch
  pair is prepended to `gen_argv` — a read, not a reorder, so the argv
  actually passed to the child is unchanged; this is not a case of the
  generator having since changed under the bug): 0 findings, all four.
- An instrumented `22e5479` build, printing `gen_scratch_flag` /
  `gen_scratch_argv` / final argv length immediately before each child
  exec's: confirms the scratch pair is threaded correctly (long or
  short alias, whichever was drawn) and prepended first on argv, for
  every one of the four, exactly as `loop_gen.vox`'s own comment says.

**A partial 8-way concurrent re-run**, mimicking the original stripe
layout (8 processes, contiguous 250-seed blocks from 100000, same
`22e5479`/`0.4.12` pair) got roughly a third of the way through with no
finding surfacing before it was stopped on a resource steer — the
`22e5479` binary predates Defect 17's per-fragment allocation fix and
leaks under sustained striping (an already-known, unrelated hazard).
Cleaned up (killed only the PIDs started here, no group/parent kills;
scratch directories removed) and re-derived the same four seeds'
`caption`-style lines afterward, sequentially and at small `--count`,
per the steer's own instruction — still 0 findings. Concurrency as the
trigger is therefore **neither confirmed nor ruled out**; a full
re-run was not attempted a second time given the memory risk.

**Constructed a targeted reproduction instead**, per the brief's own
fallback: compiled seed 100103's kept program and ran the binary
directly WITHOUT its `--caption` argument (bypassing the harness rather
than finding a harness bug in it). This reproduces the documented
failure exactly:

```
$ ./seed_100103_bin < /dev/null
...
ASSERT BUF-07: expected 12 got 0
$ ls /buffer2 /buffer3
ls: cannot access '/buffer2': No such file or directory
ls: cannot access '/buffer3': No such file or directory
```

`caption`'s default (no `with default` clause was drawn — LANGUAGE.md:
a flag with no default holds its type's empty value) is `""`, so
`"{caption}/buffer2"` becomes the bare `/buffer2` — refused only by
`/`'s write permission. This is real, hand-verified evidence of the
hazard the fix direction names, even though it was not possible to
make the HARNESS itself produce that missing argument.

**What this means for "before/after."** The fix operates at
*generation* time (whether the generator ever emits a path built on an
unbound name); the hand-reproduction above bypasses generation
entirely (an already-generated `program.vox`, invoked outside the
harness). No generator-side change can make an already-compiled
program behave differently when a human runs it wrong on purpose — so
there is no "the same repro no longer reproduces on the fixed binary"
demonstration to show for the historical seeds, honestly. What the fix
demonstrably does is close the class of bug: 1000 fresh generations
prove the generator itself never reaches the state that would produce
that program, and if a future change ever broke that, `PROBE g3` would
say so on stdout instead of the confinement breach happening silently.

**Handed to Josj: the trigger for the original four findings is still
open.** Either it needs the original 8-way concurrent layout to
reproduce (a supervised, memory-bounded re-run under Defect 17's fix
would be the next step — striped at or under core count, per the same
campaign's own note about 19 oversubscription-artifact findings), or
something about the original invocation (timeout, working directory,
an intermediate generator state before `22e5479` that was never
committed) differed from what could be reconstructed here.

## Gate: `make build` + `./test.sh`

30/0, including the two local-only soak tests
(`200_never_emitted`, `270_layout`) run standalone. New `230_units`
rows all read 0; no `PROBE g3` printed in 1000 trials.

## Gate: byte-identity vs. `main`

Two binaries, two isolated extracts (`origin/main` `ef9dee2` vs. this
branch), seeds 900000–900199, budget 40, `--keep`:

```
diff -rq <scratch>/keep-main-900k <scratch>/keep-mine-900k
```

Result: **empty diff.** 200/200 files identical, 0/0 findings both
sides.

## Evidence retained

- `<scratch>/d16-keep-old/seed_100103.vox`,
  `<scratch>/d16-keep-neigh/seed_{101434,101707,101964}.vox` — the
  re-derived kept programs for all four proven seeds, `22e5479` +
  `0.4.12`.
- `<scratch>/manual-run-noargs.out` — the hand-constructed
  no-`--caption` repro's captured output (`ASSERT BUF-07: expected 12
  got 0`).
- `<scratch>/vox-0412/` — isolated worktree + build of vox `v0.4.12`,
  used only for the reproduction attempts above.
