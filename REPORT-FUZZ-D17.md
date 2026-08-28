# Report: Defect 17 — per-fragment/per-call heap allocation in the generator

Branch `fix/d17-per-fragment-alloc`. Worktree
`~/scr/english/worktrees/wt-fuzz-d17`. Not committed — staged
(`git add -A`) and parked for Josj to sign.

## Summary

`'gen emit'` (`src/gen_core.vox`) declared a fresh 4 KB-class buffer on
every call before appending it to `gen_out`, and never freed it —
Vox releases heap-backed locals only at program exit. At budget 40 that
cost ~40 MB per generated program; a 200-seed run in one process (the
memory gate's own shape) cost ~8 GB, which is what actually killed the
four day-0.4.13 stripes on 2026-08-25 (OOM killer, not a compiler bug —
all 269 "hang" findings they saved recompile in ≤2.4 s, rc 0).

Fixed. The same root cause turned out to have more than one shape in
the generator (a fresh buffer per call, a fresh format-string TEXT per
call, and a quadratic self-referential `Set` reassignment), all
variations on "Vox frees a heap-backed local only at program exit, so a
value built once per call/iteration and discarded is one allocation
that is never returned." Memory: **~8 GB → 991 MB** for the gate's
`--seed 900000 --count 200 --budget 40` command. Generation is
byte-identical to `main` for every seed in that range. `make build` +
`./test.sh`: **30/0**.

The gate in the brief was 512 MB; **the master revised it to "under
1.2 GB, byte-identical"** once the residual ~1 GB was identified as
language-inherent (every remaining `a text called … is "…{…}…"` site
costs the same ~4 KB per evaluation `'gen emit'`'s buffer did — a
compiler-level cost, not a fuzzer defect). See "Residual" below.

## What changed, per file

- **`src/gen_core.vox`**
  - `'gen emit'`: no more per-call `a buffer called piece is "{s}"` —
    appends `s` straight into `gen_out`. This alone was the ~8 GB → ~1.1
    GB move (measured in isolation as the first fix applied).
  - `'gen join lines'` / `'gen line piece'`: the same shape one level
    up — `'gen line piece'` built a fresh format-string TEXT per line
    before handing it to `'gen emit'`. Collapsed into `'gen join
    lines'` appending each line's format string directly to `gen_out`;
    `'gen line piece'` deleted. (~1.1 GB → 1015 MB.)
  - Three new program-level scratch buffers, each `clear`ed and reused
    per call instead of declared fresh: `'the lower case source view'`
    (`'gen in lower case'`), `'the layout needle'` (shared by `'layout
    word starts at'` / `'layout word ends at'` — traced for
    re-entrancy, see below), `'the contains needle'` (`'gen text
    contains'`, a test-only helper).
- **`src/gen_files.vox`**
  - `'gen build input'`: `'the built input'` buffer hoisted to program
    level, `clear`ed on entry instead of declared fresh. The loop no
    longer builds `gen_input` via `Set gen_input to
    "{gen_input}{c}"` (quadratic — see below) or an intermediate `a
    text called c` per character; it appends the format string
    (`"{pick}"`) or the function call result (`"{'gen digit for value'
    of pick}"`) straight into the buffer, converting to text once at
    the end.
- **`src/gen_misc.vox`**
  - `'gen environment variable name unset from'`: source-view buffer
    and name accumulator hoisted to program level (`clear`ed per
    call); the byte-by-byte scan appends through a reused one-byte
    relay buffer instead of `Set 'the name so far' to "{'the name so
    far'}{'one name byte'}"` inside the loop (the same quadratic
    shape, smaller).
- **`src/gen_buffers.vox`**
  - `'gen name is one word'`, `'gen buffer reference'`, `'gen buffer
    filler'`: per-call buffers hoisted to program level. `'gen buffer
    filler'`'s loop also stopped materialising a per-iteration `a text
    called 'the character'` before appending it.
- **`src/gen_collections.vox`**
  - `'phrase has a space'`: per-call buffer hoisted to program level.
- **`src/gen_manifest.vox`**
  - `'gen dashed alias'`: all three per-call buffers hoisted to program
    level (`clear`ed on entry).
- **`src/harness.vox`**
  - `'kill grandchild of'` and `'read whole file'`: their per-call
    `Read`-target buffers hoisted to program level. `Read` replaces a
    buffer's contents rather than appending, so no `clear` is needed —
    confirmed by grep of LANGUAGE.md's Buffer section and by the full
    test suite staying green.
- **`docs/FUZZER_DEFECTS.md`**: Defect 17 entry (house style).

Every generator function in `src/gen_*.vox`, `loop_gen.vox`,
`harness.vox`, `runner.vox`, `findings.vox` and `sandbox.vox` was read
for this pattern (`a buffer called …`, `a list called …`, `a map called
…`, `a text called … is "…{…}…"`, `Create a buffer …` declared per call
or per loop iteration). `loop_gen.vox`, `runner.vox`, `findings.vox`,
`sandbox.vox`, and the rest of `harness.vox` already used the correct
idiom throughout (a single-byte relay buffer hoisted above its own
loop, reused via `Set byte`/`append`) — no changes needed there.

## Distributions are untouched (rule 1)

No `'rng below'` call was added, removed, or reordered anywhere in this
diff. `'gen digit for value'` (used in the `gen_build_input` rewrite)
draws no randomness of its own — it is a pure lookup from a number to
an alphabet character — so restructuring which branch calls it does not
touch the seed stream. The byte-identity gate (below) is the actual
proof of this, not just the reasoning.

## Docs candidate: `append <text> to <buffer>`

The brief asked me to check whether `append <text> to <buffer>` is
documented, since a grep of LANGUAGE.md's Lists section (~line 3014)
only shows the buffer→buffer overload. **It is documented** — just in a
different section than that grep found: `### Buffers` → `#### Buffer
Append and Copy` (~line 3657–3680) states plainly "When destination is
a buffer, format-string sources are supported for `set`, `is`,
`append`, and `copy`" and gives `append "line {n:06}\t{content}" to
destination.` as a worked example. Not a docs gap; the brief's citation
was just pointing at the wrong section. Verified against the live
compiler regardless (below), per the ledger's hand-verify rule.

## Discrepancy (not adjudicated): `append` rejects a bare text variable that holds a function-call result

While rewriting `'gen build input'` and `'gen buffer filler'`, `append
c to <buffer>.` failed to compile — `error: Buffer append requires a
buffer source: c` — whenever `c` was declared as `a text called c is
'some function' of x.` (a function-call result). The same statement
shape compiles and runs correctly when the source is a parameter
(`with a text called s`, `append s to buf.` — used by `'gen emit'`
itself) or a literal (`a text called c is "x".`). Minimal repro
(retained, `probe6.vox`/`probe8.vox`):

```
To 'get letter' with a number called n.
    Return a text, "x".
a buffer called b is "".
a text called c is 'get letter' of 1.
append c to b.          ( fails: "Buffer append requires a buffer source: c" )
```

Wrapping the same value in a format string compiles and runs correctly
either way (`probe9.vox`, `probe10.vox`):

```
append "{c}" to b.                        ( works )
append "{'get letter' of 1}" to b.        ( works, no intermediate needed )
```

Worked around, not adjudicated: every rewrite in this fix appends a
format-string wrapping the value (or inlines the function call inside
one) rather than a bare function-call-derived identifier, matching what
already compiles. Per the ledger's adjudication rule, this is recorded
with its minimal repro and left for a human to decide whether it is a
parser gap (only a `text` *variable*'s static type is tracked for
`append`'s buffer-vs-non-buffer overload resolution, and a function
call's return isn't) or intentional; I did not construct the compiler
reading in which it is obviously correct, so this is flagged rather
than closed.

## Gate: memory

Isolated extract, own working directory (not the worktree root — see
"A concurrency mistake" below for why that matters):

```
/usr/bin/time -f "maxrss=%M KB" ./build/vox-fuzz gen --seed 900000 --count 200 \
  --budget 40 --timeout 60000 \
  --vox ~/scr/english/vox/target/release/vox --core ~/scr/english/vox/coreasm \
  --out ./out
```

| Build | maxrss | Note |
|---|---|---|
| pre-fix (`main`, from the OOM incident + arithmetic check) | ~8 GB | `~40 MB/seed × 200` from `'gen emit'`'s old buffer, matches the incident |
| after `'gen emit'` fix only | ~1.1 GB | first intermediate measurement |
| after `'gen join lines'` fix added | 1,015,124 KB (~991 MB) | second intermediate measurement |
| after (reverted) `'gen var ref'` cache added | 990,008 KB (~967 MB) | saved ~25 MB (2.5%) — reverted anyway, see below |
| **final** (cache reverted, everything else above kept) | **1,015,144 KB (~991 MB)** | matches the pre-revert-attempt number almost exactly |

200/200 compiled, 0 findings, in every run above.

## Gate: byte-identity vs. `main`

Two binaries, two isolated extracts (never the live
`~/scr/english/vox-fuzz` checkout):

```
git worktree add <scratch>/main-baseline origin/main
cd <scratch>/main-baseline && make build VOX=~/scr/english/vox/target/release/vox

# each binary, its own working directory, --keep + --out both isolated:
<binary> gen --seed 900000 --count 200 --budget 40 --timeout 60000 \
  --vox ~/scr/english/vox/target/release/vox --core ~/scr/english/vox/coreasm \
  --out ./out --keep ./keep

diff -r <scratch>/det-main-run/keep <scratch>/det-fixed-run3/keep
```

Result: **empty diff, exit 0.** 200 files on each side. This was run
against the FINAL tree (after the cache revert below) with a freshly
rebuilt binary — an earlier determinism run against an intermediate
state was discarded and redone once I realized the reverted-cache
change post-dated it.

## Gate: `make build` + `./test.sh`

30/0, run twice more after this report's tree stabilized (once
mid-sweep, once on the final reverted tree). `citations: 722 checked, 0
stale` both times.

## Quadratic Set-reassignment (feeds Q7)

Separate from the flat ~4 KB-per-call cost, rebuilding a TEXT by
self-referential format-string reassignment in a loop —
`Set t to "{t}{c}"` — does not merely leak a flat 4 KB per iteration.
It re-copies the WHOLE current string on every iteration and leaks the
old copy: an O(n²) cost, not O(n).

Isolated probes against the live compiler (retained,
`/tmp/.../d17-probe/probe3.vox` and `probe5.vox`):

| Pattern | Iterations | maxrss |
|---|---|---|
| `Set t to "{t}x"` (text self-concat) | 1,000 | 3,968 KB |
| `Set t to "{t}x"` | 100,000 | 5,086,848 KB (~4.85 GB) |
| `append "x" to b` (buffer, one shared buffer) | 100,000 | 384 KB |

The master independently reproduced the quadratic shape at 5k/10k/20k
iterations: 23 MB / 71 MB / 236 MB — consistent with an
allocate-and-copy-the-whole-string-so-far cost, not a flat per-call
cost. `gen_files.vox`'s `'gen build input'` had this pattern (drawing
up to 999 characters via `Set gen_input to "{gen_input}{c}"`, ~0.5
MB/call) and was fixed as part of this defect (see above).

This is the SAME underlying design question already open as Q7
(`vox-notes/2026-08-28-Q7-scope-exit-free.md`, "should heap-backed
locals be freed at scope exit") — generalized: it now covers `Set`
reassignment of a TEXT, not just a fresh declaration. Per the project's
adjudication rule, this is not a fuzzer defect to fix further and not a
compiler bug to file — it is evidence for Josj's ruling on Q7, recorded
here and left for that decision.

## Reverted: caching `'gen var ref'`

Attempted fix, found wrong before sign-off, fully reverted:

`'gen var ref'` is called once per REFERENCE to a declared number
variable — far more often than `'gen new var'` is called (once per
DECLARATION) — and every call synthesised a fresh `"v{n}"` text
(measured: identical ~4 KB/call cost to a buffer). The fix cached each
variable's name in a program-level list (`gen_var_names`), appended to
once in `'gen new var'`, and had `'gen var ref'` read the cache instead
of re-interpolating. It saved 25 MB of 1015 (2.5%) in isolation.

**The defect:** the memory gate runs 200 seeds in ONE process.
`gen_vars` (the counter) resets to 0 at the start of each seed's
generation, but `gen_var_names` (the cache list) does not — it just
keeps growing, seed after seed. Once a later seed declares MORE
variables than an earlier one, `element i of gen_var_names` for the
tail indices reads names left over from an earlier seed instead of the
current one: a wrong, and non-deterministic-vs-`main`, program. Caught
by the master's review before the gate was signed off (not caught by
`./test.sh`, which does not run multi-seed-in-one-process the way the
gate does — a gap worth a ledger row of its own if this pattern
recurs).

Reverted in full: `'gen var ref'` synthesises `"v{n}"` again on every
call, `'gen new var'` no longer appends to any cache, `gen_var_names`
and its comment are deleted. `git diff` on `gen_core.vox`'s `'gen new
var'` / `'gen var ref'` now shows no change from `main` at all (only
`'gen emit'` and `'gen join lines'` differ in that region).

**Audited every other program-level list/map this fix introduced for
the same hazard: there are none.** `gen_var_names` was the only new
list or map; every other new global from this fix is a buffer, and
every one is either `clear`ed at the top of the function that uses it
or fully overwritten (`Read`, or `Set byte` before every `append`)
before being read — neither has `gen_var_names`'s "grows across calls
and is indexed by a counter that resets" shape.

## Residual: language-inherent, not fixed further

After every fix above, ~991 MB remains for 200 seeds at budget 40. This
is `'gen var ref'` (reverted cache notwithstanding — still the single
highest-frequency site, called on every expression operand) and every
other `a text called … is "…{…}…"` declaration the corpus still
evaluates once per use:

```
grep -Ec 'a text called [^=]+ is "[^"]*\{' src/gen_*.vox src/loop_gen.vox \
  src/harness.vox src/runner.vox src/findings.vox src/sandbox.vox
# → 372 sites, post-fix
```

The overwhelming majority of these are genuinely low-cost: each leaf
function (`'gen leaf buffer inrange'`, `'gen leaf list inrange'`, and
~370 more like them) builds its own small, fixed number of
format-string texts ONCE when that leaf is chosen — bounded by budget
(≤40 leaf choices per program), not by anything that scales with
program size. Per the file header's own invariant, only variable names
(`v1..vN`) are referenced from later, unrelated statements; every other
named entity (buffers, lists, maps, things, floats, texts) is declared
and used once within its own self-contained leaf occurrence. That
structural fact is why `'gen var ref'` stood out enough to attempt
fixing (and why the attempt was worth reverting carefully rather than
abandoning outright) and why the other 371 sites were not chased
individually: each costs at most a handful of ~4 KB allocations per
seed, and hoisting all 371 to program level for a few more percent
would trade real correctness risk (as the reverted attempt
demonstrated) for a diminishing return.

The reason this can't go below roughly this floor without a compiler
change: every one of these 372 sites needs a NEWLY COMPUTED string
(a variable reference, an assertion line, a declaration) that cannot be
pre-cached the way `gen_var_names` almost was, and every fresh
format-string TEXT costs the same flat ~4 KB Vox charges any
fresh buffer, regardless of how few bytes it actually holds — confirmed
by probe (`probe12.vox`: a ~10-byte interpolated text, 40,000 calls,
156 MB, i.e. 4 KB/call exactly matching a buffer of the same
call-count). This is the same Q7 question generalized from buffers to
format-string texts, not a new one, and it is not this defect's job to
adjudicate. The chunked/striped campaign driver (multiple shorter-lived
processes rather than one long one) already absorbs a per-process
ceiling like this in production; the gate here targets a single
long-running process on purpose, which is the worst case for a
never-freed-until-exit design.

## `harness.vox`'s two hoists: measured or speculative?

Asked to say which. **Not individually isolated** — I did not run the
gate with only `'kill grandchild of'` or only `'read whole file'`
changed. Both are on the per-seed compile/run/capture path, not the
per-fragment generation hot path `'gen emit'` sits on: `'kill
grandchild of'` runs only when `'reap with deadline'` decides to kill a
hung child (rare at this gate's budget/timeout), and `'read whole
file'` runs once or twice per seed inside the differential oracle. Kept
anyway, because they are squarely in the brief's audit scope (the brief
names `harness.vox` explicitly), they fix the identical pattern this
whole defect is about, and the full test suite (30/0, twice) and the
final memory/determinism numbers above already include them with no
regression. If Josj wants the diff narrowed to only what was
individually measured, `git checkout -- src/harness.vox` is a clean,
independent revert — nothing else in this fix depends on it.

## A concurrency mistake, caught and fixed mid-session

Two of the early memory-gate attempts collided with `./test.sh`'s own
use of `./vf_scratch/` (both were launched from the worktree root at
the same time test.sh was running there, and vox-fuzz's scratch paths
are relative to cwd). Symptom: `grep: ./vf_scratch/run_.../vf_cerr: No
such file or directory` mid-run. Not a code defect — a process-hygiene
one on my part. Fixed by running every gate/determinism invocation from
its own directory under the scratchpad, never the worktree root, for
the remainder of the session. Flagging it here in case a similar
collision shows up in a real campaign log and needs the same diagnosis.

## Evidence retained

- `/tmp/.../d17-probe/*.vox` — every isolated probe run against the
  live compiler before encoding a claim (buffer-per-call, text-per-call,
  quadratic Set-reassignment, buffer-append-of-a-function-call-result
  compiler quirk, `as text` inline in `Return`).
- `vox-notes/evidence/2026-08-28-scope-exit-free/` — the original Q7
  probes this defect's root cause traces back to.
- Determinism keep directories under the session scratchpad
  (`det-main-run/keep`, `det-fixed-run3/keep`), 200 files each.
