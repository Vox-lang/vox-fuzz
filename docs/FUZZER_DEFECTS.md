# Fuzzer defects — bugs in vox-fuzz itself

Distinct from the Vox compiler's own register
([vox/docs/BUGS_FOUND.md](https://github.com/Vox-lang/vox/blob/main/docs/BUGS_FOUND.md)),
which records bugs the fuzzer *finds*. This file records bugs **in the
fuzzer** — cases where it would mis-classify, silently drop, or never
notice a real compiler defect.

A defect here is worse than an ordinary bug: it makes the tool lie
quietly. Every entry states how it was proven, because a claim about a
detector needs the same standard of evidence the detector itself is held
to.

---

### 1. Assembler and linker rejections are silently dropped — the whole `asm-reject` category is dead code

**Status:** **fixed** (plan 322, phase A). Found by the vox-fuzz red team
(2026-08-19, arena finding `01-asm-reject-dropped`); independently
confirmed by the master from the Vox compiler's source and from the
platform toolchain's real output before any fix was scoped.

**Severity: high.** "Vox emitted assembly that the assembler refuses" is
one of the most valuable bug classes a compiler fuzzer can catch — it is
bad codegen, caught before it becomes a runtime mystery. That category
has never been able to fire.

`src/loop_gen.vox` decides the `asm-reject` classification with:

```
a number called 'the toolchain check' is 'run shell' of "grep -q -e nasm -e 'ld:' ./vf_cerr" and 5000,
```

`grep` here is case-sensitive, and **neither pattern matches what the
toolchain actually writes** when it rejects Vox's output:

| What really happens | What lands in `./vf_cerr` | Matches `-e nasm`? | Matches `-e 'ld:'`? |
|---|---|---|---|
| nasm rejects the emitted assembly | `NASM assembly failed` (vox, `src/main.rs:728`) | no — capital `NASM` | no |
| nasm's own diagnostic, passed through | `vf_gen.asm:17: error: symbol ... not defined` | no — the string `nasm` never appears | no |
| the linker refuses | `Linking failed` (vox, `src/main.rs:911`) | no | no |
| the linker's own diagnostic | `/usr/bin/ld.bfd: ... undefined reference ...` | no | **no** — `ld.bfd:` is not `ld:` |

The one place a lowercase `nasm` *does* appear is
`Make sure NASM is installed: sudo apt install nasm` — and `src/main.rs`
prints that only on the `Err(e)` arm, when nasm **could not be run at
all**. The rejection case is the separate `Ok(_)` arm, which prints only
the capitalised line. So the classifier matches exactly the situation
that is *not* a compiler bug (a missing assembler), and misses exactly
the one that is.

The consequence, in `'fuzz gen once'`: the grep returns nonzero, the
`If 'the toolchain check' is 0` branch is skipped, and control reaches
`Return a number, 0` — **"compiled cleanly, nothing to see"**. No
finding directory, no counter increment, nothing in CI.

**How it was proven** (three independent legs, none of them "the red
team said so"):

1. **The compiler's source.** `src/main.rs:725-737` — the reject arm
   (`Ok(_)`) and the cannot-run arm (`Err(e)`) print different text, and
   only the latter contains lowercase `nasm`. Same shape at `:908-918`
   for the linker.
2. **The platform toolchain.** `readlink -f /usr/bin/ld` →
   `/usr/bin/ld.bfd`, and a forced undefined-symbol link prints
   `/usr/bin/ld.bfd: ...`. The substring `ld:` does not occur.
3. **A runnable PoC** (`poc.sh` in the arena finding) that drives the
   real fuzzer with a shimmed `nasm` which rejects every program, and
   exits 0 iff the fuzzer records zero findings.

**Why 2,400+ seeds at "100% compile-clean" did not catch it:** they
genuinely were clean. A dead detector and a working compiler are
indistinguishable from the summary line — which is precisely why a
fuzzer needs its own adversary.

**Fix applied (plan 322 A1):** `src/loop_gen.vox`'s toolchain check is now
`grep -q -F -e 'NASM assembly failed' -e 'Linking failed' -e nasm -e 'ld:'
./vf_cerr` — matching vox's own deliberate wrapper lines first (stable,
`-F` fixed-string, exact case), keeping the old `nasm`/`ld:` patterns as
additional alternatives for a toolchain that does print them. Regression
test `tests/100_asm_reject.vox` forces a *real* assembler rejection via a
`nasm` shim ahead of the real one on `PATH` (the model the red team's own
`poc.sh` used) and asserts an `asm-reject` finding directory is written.


---

### 2. `--out`/`--vox`/`--core` were spliced unquoted into shell commands

**Status:** **fixed in `a337c07`** (plan 322 Phase A). Found by the red
team (`02-out-command-injection`), reproduced by the master under
bubblewrap.

`main.vox` set `findings_dir`/`vox_binary`/`vox_core` straight from the
flags; `findings.vox` interpolated all three raw into `run shell`
strings. `--out './x$(touch PROOF)y'` executed the substitution while
the run reported `findings: 1`.

**The half that mattered more than the injection:** an `--out`
containing a **space** made `mkdir -p` create two directories and the
copies land elsewhere — while the tool still printed `findings: N`.
Evidence for N real compiler bugs, silently scattered, with a success
message on top. No attacker required.

**Fixed by removing the shell**, not by quoting: directory creation, the
program copy, `classification.txt` and `repro.sh` are written natively
in Vox. Only the two operations Vox cannot perform — capturing a child's
stdout, and `chmod` — remain shelled out, and both route every
outside-origin value through a single `'shell quote'` helper (POSIX
single-quoting, byte-wise, safe for arbitrary bytes), so there is one
place to audit. Tests: `110_out_injection`, `120_out_spaces`,
`130_repro_spaced_vox`.

---

### 3. Four constructs the generator could never emit

**Status:** **fixed in `9c6b2c6`** (plan 322 Phase B). Found by the red
team (findings 03–06), each proven twice — grep evidence that `gen.vox`
could not emit it, plus a compiling demo program.

Never emitted: **maps**, the dynamic **`value`** type, **floats** and
`divide`, **thing member functions**. Also absent and now added: mixed-type
lists, text as data the generated program handles (rather than only the
source it is written into), and **the chained loop expansion itself** —
the construct vox 0.4.5 shipped, which the fuzzer *used* in its own loop
but had never *emitted* into a test program.

**Why these were worth more than their LOW severity suggests:** every one
is a place where compiler bugs have already lived. The `value` round-trip
alone accounts for three entries in the compiler's own register (#2, #8,
#15); float interpolation was #1. The fuzzer had been hunting in the
rooms where nothing was hiding.

Verified: 1,000 seeds on a fresh range → 1,000 compiled, 0 findings.

---

### 4. The test suite has an unreproduced flake

**Status:** **open, unexplained.** Observed by the master 2026-08-19
while verifying plan 322 Phase B.

One run of `./test.sh` in an isolated extract reported `passed: 10
failed: 1`. Three immediately following runs in the same tree, and one
more in a fresh extract, all reported `passed: 11 failed: 0`. The failing
case was not captured before the run was lost.

**Suspicion, not a conclusion:** load-sensitivity in a deadline-bounded
test. `070_cli` passes a 120s deadline to `'run shell'` and `test.sh`
wraps each binary in `timeout 150`; the machine was running two worker
sessions and a 1,000-seed sweep at the time. Nothing in plan 322 Phase B
touches timing, so this is most likely pre-existing.

**Why it is recorded rather than dismissed:** a fuzzer whose own gate
fails intermittently will eventually produce a CI failure nobody can
explain, and the response to that is usually to distrust the gate — which
is the same disease as entries 1 and 2, arriving from the other
direction. If it recurs, capture `test.sh -v` output at the time; the
fix is likely to make the deadline generous or the test independent of
wall-clock time, not to retry it.

---

### 5. Two concurrent runs from the same directory fabricate findings

**Status:** **FIXED** (merged 2026-08-20). Per-run scratch isolation plus a pid-keyed writability probe — the probe itself had reintroduced the very collision D1 cures. Five concurrent pairs back to back, both sides clean.

**Original status:** open, partially fixed. Found and proven 2026-08-19.

Two `gen` runs started from the same working directory produced **1,260
`asm-reject` findings between them, every one false** — each finding's
`program.vox` compiles cleanly by hand (exit 0). Proof: killing one run
dropped the other's rate from 961-and-climbing to zero new in 40s.

The original cause was fixed scratch names in the current directory
(`./vf_gen.vox`, `./vf_gen_bin`, `./vf_cerr`) with no per-run isolation.
A partial fix (`fix/fuzzer-defects-worker`, unmerged) adds a per-run
scratch dir `vf_scratch/run_{pid}_{seed}` and cuts it to ~40 per
concurrent run — **but still fabricates ~1 finding even in a solo run**,
so a second cause remains. Concurrent compiles of identically-named
sources in separate directories do NOT collide (tested), so the residual
is elsewhere in the compile path — likely scratch-dir creation racing or
failing.

**Severity: high** — the obvious way to fuzz faster is several
instances, and doing so floods the findings directory with fabrications.
Fix and full acceptance in plan 325 Task 1.

---

### 6. A run reports `findings: 0` while every compile fails

**Status:** **open.** Found 2026-08-19.

A campaign whose working directory was deleted mid-flight ran to
completion through **2,817 `getcwd` errors**, compiled nothing, and
reported a clean sweep. "Could not compile anything" and "found nothing"
are indistinguishable in the output — the same disease as defect 1, from
the other side.

**Fix:** verify the scratch directory is writable at startup (write,
read back, delete) and abort non-zero on failure; treat an unreadable
compile-stderr as fatal, not as a finding. Plan 325 Task 2.



---

## Addendum 2026-08-20 — D1 reproduced at full strength, and it is worse than "open"

Running one extra `gen` command from the same directory as a running
campaign produced **28 findings from 40 programs**. The identical seed
range re-run in an isolated directory: **20/20 compiled, 0 findings.**
All 28 were fabricated.

The same collision, the same night:

- corrupted a 400-seed campaign's own arithmetic — it reported
  `compiled: 347` and `findings: 12` against `programs: 400`, which do
  not add up and cannot both be true;
- **poisoned a checked-in fixture**: regenerating `060_loop_gen.expected`
  while a campaign ran captured `programs: 5 / compiled: 0 / findings: 5`
  and wrote it into the repo as the expected output. It was caught only
  because the number was absurd on its face.

That third consequence is the reason to raise this defect's priority.
A fabrication that lands in a golden file stops being a transient lie
and becomes the definition of correct. **Plan 325 T1 should be done
before any further emitter work on this repo.**

Practical rule until it is fixed: **one fuzz process per directory, ever**
— including the test suite, which shells out to the binary and therefore
counts as a run. Copy `build/` to a scratch directory for parallel work.

### Defect 4 (the suite flake) — measured, and narrowed to two tests

Five consecutive full-suite runs on 2026-08-20, same tree, same binary,
nothing else running, all scratch leftovers deleted first:

| run | result |
|---|---|
| 1 | 19/19 |
| 2 | FAIL `210_scratch_sandbox` |
| 3 | FAIL `020_harness` |
| 4 | 19/19 |
| 5 | 19/19 |

**Roughly 2 in 5, and it moves between exactly two tests.** Both are
sandbox/process tests; no generator or determinism test has ever
flaked. Each passes when run alone.

That narrows it considerably from "unreproduced": it is not seed-
dependent (the generator tests are the seeded ones and they are rock
solid), and it is not my concurrent campaigns (the runs above had
none). It smells like a race in scratch-directory creation or teardown,
or a process the harness reaps while another test is still using its
path — the D1 shared-path family again, but within a single suite run
rather than between processes.

Suggested next step: run the two tests alone in a tight loop to get a
faster reproduction, then instrument the scratch path lifecycle.

**2026-08-20, hypotheses RULED OUT.** Recorded because a negative result
saves the next person the same afternoon:

- **CPU contention is not the cause.** `020_harness` bounds a spinning
  process with a 300ms deadline, which looks like the obvious suspect.
  It was run with four busy-loops saturating the machine and passed,
  producing the exact expected `sleep: hang 9`.
- **It is not deterministic given a state.** The same tree that failed
  it two runs in three then passed three full `-v` runs consecutively,
  with nothing changed in between.
- **It is not my generator changes.** The rate varied within a single
  unchanged tree, so any claim that a specific change worsened it is
  unsupported. (I made that claim mid-session and withdrew it.)

What still holds: it only ever strikes `020_harness` or
`210_scratch_sandbox` — both process/timing tests — and never a
generator or determinism test. Whatever it is, it lives in the
fork/reap/scratch-lifecycle path, not in generation.

---

### 7. `supervise` gives the child no stdin, so any stdin read is reported as a hang

**Status:** **FIXED** (2026-08-20). The child's stdin is now redirected
from a file before `Execute`, defaulting to `/dev/null` so a program
that reads gets a clean immediate EOF instead of the fuzzer's own stdin.
Mechanism: close the descriptor, then open — the open takes the lowest
free number, which is the one just freed, the same trick the stdout
capture already used. Verified in isolation with `/bin/cat` before being
wired in, then end to end: a generated program reading `/dev/stdin`
returns verdict `exit` (not `hang`) and reads the injected bytes.
Originally found 2026-08-20 while checking whether file I/O
could be emitted without waiting for the sandbox. Found BEFORE emitting
it, which is the only reason it is a note here rather than a flood of
false findings in a campaign.

`supervise` (harness.vox:48) forks and `Execute`s the generated program
with **no stdio redirection of any kind**. The child therefore inherits
whatever stdin the fuzzer itself has. Run from a terminal — or from any
parent whose stdin is an open-but-silent pipe — a generated program
that reads `/dev/stdin` blocks forever, is killed at the deadline, and
is classified `hang`.

**Proved, not assumed.** A program whose only interesting statement is
`Read from input into data` where `input` is `/dev/stdin`:

| stdin | result |
|---|---|
| `< /dev/null` | reads 0 bytes, no error, exits 0 |
| open pipe with no writer sending | **blocks until killed (rc 124)** |

The second row is what `supervise` produces today.

**Consequence, and why it matters now.** Plan 324 Part B puts
`/dev/stdin` on the read allowlist, and plan 324 T3 wants the harness to
feed seeded bytes to it. Emitting a stdin read before this is fixed
would make EVERY such program a false hang — a whole category of
fabricated findings, arriving with the plan's own blessing.

**Fix, and it is small:** the child must have its stdin explicitly
redirected before `Execute` — from `/dev/null` by default, and from the
seeded input file once plan 324 T3 lands. That single change turns the
row above from "blocks" into "reads 0 bytes", and is the actual
prerequisite for T3, which the plan does not currently name.

**Until then:** the write half of file I/O is safe to emit and is
emitted — `/dev/stdout` never blocks. The read half stays unemitted, and
the T1 guard should treat a generated `/dev/stdin` read as a build
failure so it cannot slip in ahead of the harness change.

---

### 8. A format string is never substituted where a string literal would go — so a whole class of type-tag bugs is unreachable

**Status:** **open**, identified by Josj 2026-08-20, immediately after
compiler bug #39 was found **by hand** rather than by the fuzzer.

The generator now has four format-string leaves — specifiers,
expressions, format-as-value, and every interpolated type. What it does
NOT have is the thing that would have caught #39: a format string
appearing **in a position where a string literal would otherwise go**.

Grep-confirmed: zero of the format emissions occur as a list element,
and every generated string literal is a plain literal.

**Why that is the gap that matters.** #39 is that a format string as the
FIRST element of an inline collection makes every element of that
collection print as a raw pointer — a silent wrong value plus an address
leak. It is not reachable by emitting format strings *somewhere*; it is
only reachable by emitting one *instead of a literal, in a collection*.

**Correction, and it matters — emission alone would NOT have caught it.**
Josj, on reading the above: *"I'm not sure if the fuzzer is able to test
if an address is printed when another valid type is expected."* He is
right, and the claim above was too optimistic on its own. A program
carrying #39 compiles, runs, and exits 0. The harness's oracle is signal
death, hang, ICE and assembler rejection — none of which fire. The
wrong output is invisible. That is equally true of #33, #34, #35, #36
and #39: **every compiler bug found this week is silent wrong data, and
the fuzzer cannot see any of them.** Emission is necessary and not
sufficient; see defect 9, which supplies the missing half.
The same is true of its family, #17 and #18, which are all the same
shape: a format string's TYPE TAG, not its payload, being got wrong at
some sink that infers element types statically.

**Josj's design, which is the right one:** when the generator is about
to emit a string literal, it should *occasionally and randomly* emit a
format string instead. That decision should hand off to a dedicated
subroutine that composes a random format string obeying the language's
own format rules — slots, specifiers, expressions inside slots, escaped
braces — rather than each call site inventing its own.

The payoff is combinatorial rather than additive: every existing site
that emits a literal becomes a format-string site for free, including
ones nobody thought to enumerate. List elements, buffer initialisers,
`treating` clauses, function arguments, thing fields, map keys and
values, `Write ... to` sinks — LANGUAGE.md §"Format Strings Everywhere"
claims all of them accept a format string, and that claim is exactly
what is currently untested.

**Two constraints the implementation must respect:**

1. **The known-broken shapes must stay out until the compiler is
   fixed**, or every program carrying one becomes a false finding. #39's
   collection-first-element case is the live example. When #39 is fixed,
   that exclusion is what should be lifted first — and the exclusion
   should be written so it is obvious it is temporary and tied to a bug
   number.
2. **Grouping does not work inside a slot.** `{{` is the literal-brace
   escape, so `"{{x add y} multiply z}"` renders `{13 multiply z}`, not
   `52`. Format-string expressions are flat by necessity — the existing
   `'gen deep expr'` already grew a `grouped` parameter for exactly this
   reason and should be reused rather than reinvented.

**Acceptance:** a campaign in which format strings appear at a
measurable rate in literal positions; every program still compiles;
zero findings. And a guard test in the spirit of `080_gen_rich.vox`, so
the surface cannot silently stop being generated later — which the
format worker flagged as the obvious missing guard and left out only
because its brief pinned the gate at 19 tests.


---

### 9. No oracle can see a wrong VALUE — but a cheap one can see a leaked ADDRESS

**Status:** **FIXED** (merged 2026-08-20) for the heap/stack half; the
static-address half is a known and recorded limitation, see below.
Designed 2026-08-20 from Josj's observation that
emitting a shape is useless if nothing can tell the output is wrong.
Feasibility and effectiveness both proven below before being written
down.

The harness classifies a run by signal death, hang, ICE, or assembler
rejection. A program that computes the wrong answer and exits 0 is
indistinguishable from a correct one. So the entire class this project
keeps finding — #33, #34, #35, #36, #39, all silent wrong data — is
invisible to the fuzzer that exists.

A general output oracle needs an expected value, which needs either a
reference implementation or generation-time knowledge of every result.
That is the deferred hard problem. **But one important sub-class needs
neither.**

**The mechanism: run the same binary twice and diff the output.**

A generated program is deterministic by construction — no input, no
randomness, and the one clock-reading leaf deliberately prints verdicts
(`ok`/`BAD`) rather than times. So its output must be byte-identical
across runs. If it is not, the program printed something that moves:
under ASLR, that means a **heap address**. Which is precisely what a
leaked pointer is.

**Proven, both directions, 2026-08-20:**

| Check | Result |
|---|---|
| 20 generated programs, each run twice | 20/20 byte-identical — the determinism premise holds |
| #39's repro (`["{base}", "plain"]`), run twice | `139780998905880` vs `140133082423320` — **caught** |
| the corrected form (`["plain", "{base}"]`), run twice | identical — **no false positive** |

Note the second column of #39's output is stable (`4206785`, static
rodata) while the first moves. The oracle needs no expected value: it
only needs the output to disagree with itself.

**Cost:** one extra execution per program, bounded by the same deadline.
Cheap enough to run on every program rather than as a special mode.

**What it catches — measured, not assumed (2026-08-20).** vox emits
NON-PIE executables (`readelf -h` reports `Type: EXEC`), which splits
leaked pointers into two classes:

| Address kind | Moves between runs? | Oracle sees it |
|---|---|---|
| heap (buffers, lists, allocations) | yes, under ASLR | **caught** |
| stack | yes, under ASLR | **caught** |
| static / rodata (string literals, globals) | **no** — fixed at link time | **MISSED** |

Bug #39's own output demonstrates both halves in one program. Its first
element printed `139780998905880` — a heap pointer that moved between
runs, and that movement is what the oracle detects. Its second printed
`4210945`, which is `0x40403`: a low, fixed address in static data,
identical on every run. **A bug that leaked only static pointers would
be entirely invisible to this oracle.**

That is not a reason to weaken the claim to nothing — the heap case is
the common one, and two of the five bugs in vox 0.4.7 leaked exactly
that. But the register should not say "catches leaked pointers" when it
catches most of them.

**Closing the static half, if it is ever worth it.** Two options, both
more expensive than the current check:

1. **Compile the same source twice with a padding difference** so static
   addresses shift, then compare. Real, but doubles compile cost — the
   expensive half of a campaign.
2. **A plausibility filter**: flag a printed integer that falls in the
   binary's own static range when the surrounding program has no
   business producing one. Cheap, but needs a notion of "no business",
   which is the expected-value problem this oracle exists to avoid.

Neither is worth doing until something demonstrates a static-pointer
leak actually happens. Recorded so the limitation is known rather than
discovered later.

**Also catches:** uninitialised memory that happens to vary, and
anything else ASLR-dependent. **What it does not catch:** a
deterministic wrong answer — `"{f:06}"` printing a float's bit pattern
(#36) is the same wrong number every time and stays invisible. That
half still needs the knowable-answer work in plan 325.

**Implementation notes:** `supervise` already returns a verdict per run;
this needs a second call and a byte comparison of captured stdout, which
the harness does not currently capture at all (generated programs write
straight to the fuzzer's own stdout — see defect 7's neighbourhood).
Capturing it is the prerequisite, and it is the same plumbing plan 324
T3 needs for seeded input. A finding of this class should record both
outputs, since the diff IS the evidence.


---

### 10. Generated programs are never given arguments, so the whole flag-PARSING surface is untested

**Status:** **open**, identified by Josj 2026-08-20: *"Do we actually
pass values to flags? valid and invalid?"* We do not.

`runner.vox`'s `run program` builds `a list called 'no arguments' is
[].` and passes it to every generated program, on every path — including
the oracle's second run. So a generated program has always run with an
empty argv.

**What that leaves untested.** The generator declares flags and reads
them, which is what found compiler bugs #31 and #32 — but those were
both on the DECLARATION side. Everything on the parsing side has no
coverage at all:

| Shape | Covered today |
|---|---|
| short form with a value (`-l hello`) | no |
| long form with a value (`--label world`) | no |
| boolean presence (`-v`) | no |
| a malformed value for a `number` flag | no |
| a value that overflows i64 | no |
| a flag given with its value missing at end of argv | no |
| an unknown flag falling through to positionals | no |
| `arguments's all` / `arguments's raw` with actual arguments | **no** — only ever the empty case |
| a `required` flag, supplied and unsupplied | no |

**The behaviour is worth knowing before emitting it**, and it was probed
by hand on 0.4.7 so the emitter does not have to discover it:

- `-l hello -r 42 -v` and `--label world --retries 7` both parse
  correctly, and recognised flags are removed from `arguments's all`.
- `-r notanumber` yields 0 **and sets the error flag**, so a program can
  tell it from a real `-r 0`, which does not raise. Good behaviour, and
  the reason this is a coverage gap rather than a compiler bug.
- `-r 99999999999999999999` also raises — that is compiler bug #35's fix
  reaching the flag path, though it still returns the wrapped value.
- `-l` with no following token leaves the flag empty and does not raise.
- `-z extra` consumes nothing: both tokens fall through as positionals.

**Why it matters.** The flag schema is the single richest surface the
generator touches and it has already produced three compiler bugs (#31,
#32, and #33 by way of the CLI rewrite that exposed it). Half of that
surface has never been executed.

**What the fix needs.** The harness must pass a seeded argument list to
the generated program, and the program must know what to expect so it
can be self-checking. That is the same plumbing as defect 7 (the child
needs a real stdin) and plan 324 T3 (seeded input bytes) — argv is
simply the third input channel, and the cheapest of the three, since
`supervise` already takes an argument list and it is only ever handed an
empty one.

**Design note for whoever builds it.** The generator knows what it
passed, so this is a rare case where the expected VALUE is known at
generation time — a program can assert `label` equals what was supplied
and `Exit` with a distinct code if not. That makes it one of the few
places the deferred output-oracle problem is already solved, and it is
worth exploiting rather than merely printing the values and hoping.