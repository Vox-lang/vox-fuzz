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

**Status:** **FIXED** (2026-08-20). A run that compiled NOTHING now
writes a message to stderr saying the run proves nothing and that
`findings: 0` is meaningless, and exits **2**. A run that compiled less
than half warns loudly but keeps its normal exit status, because a low
compile rate is not necessarily broken — chaos mode will do it
deliberately. Verified both directions: a deliberately failing compiler
gives exit 2 with the message, a healthy run gives exit 0 unchanged.
Found 2026-08-19.

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

**Status:** **FIXED** (2026-08-20). Argv is generated per program and
weighted 60/40 between valid invocations (which the program then asserts
on — plan 327 A3) and hostile shapes. Stdin is generated too: seeded
bytes written to the per-run scratch directory, with reads emitted into
a share of programs. All three input channels now vary. Originally
identified by Josj 2026-08-20: *"Do we actually
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

### 11. A compile failure that is not an ICE and not a toolchain rejection vanishes — counted as "not compiled", never a finding

**Status:** **open**, found 2026-08-20 by the master while gating the
values batch A leaves. A 200-seed campaign on a loaded machine reported
`compiled: 186` with `findings: 0`; every one of the 200 kept programs
compiled cleanly by hand, and the same seeds re-run on a quieter machine
gave `compiled: 200`. The 14 were compile **timeouts** under load, and
the run reported a clean sweep over them.

Two defects in one:

1. **A compile that times out is dropped silently.** `'classify compile
   exit'` (`src/loop_gen.vox`) maps a negative code to `"hang"`, but the
   compile path only escalates `ice` and the nasm/ld `check-asm` cases;
   a compile that did not finish is neither, so it falls to "not
   compiled, no finding" and only the aggregate `unexplained > half`
   warning could ever notice. A campaign's `compiled:` number is
   therefore not trustworthy as a generator-quality signal.
2. **A compiler *rejection* is not a finding class at all.** With
   randomness as the default (no chaos mode — `docs/DECISIONS.md`), a
   program the compiler refuses is a `parser-reject` finding to triage: a
   rule the generator has not learned, or a compiler bug. Today it is the
   same silent "not compiled".

**How it was proven:** the 200 kept programs, compiled by hand with the
same binary and `VOX_CORE_PATH`, 0 failures; the identical campaign
re-run, `compiled: 200`; main's generator on the same seeds, 200/200.

**Fix direction:** a compile exit of "hang" (timeout) becomes a
`compile-timeout` finding (or at minimum a loud per-program line and a
non-zero exit when any occur); a compile exit with a diagnostic becomes a
`parser-reject` finding carrying the diagnostic, so the rule-layer gap
is triaged instead of averaged away. Until then, acceptance campaigns
for leaf batches are run twice or on a quiet machine, and `compiled:`
below the program count is investigated by hand.

---

### 12. `scripts/invariants` measures LINES, so the layout randomiser hides every sameness it is meant to report

**Status:** **fixed** (2026-08-21). Found by the master, 2026-08-21,
while gating leaf work: the same 150 seeds reported **118 rows at 100%
presence under `--layout plain` and 35 under the default random layout**.
Nothing about the programs had changed — only their whitespace.

**Severity: high, and of the quiet kind.** The invariant report is the
acceptance test for all generator work (CLAUDE.md, *Enforcement*), and
the honest measure of progress is that list shrinking. A detector that
reports 35 instead of 115 makes a batch look three times better than it
is, and it does it silently, on the layout a real campaign runs in.

**Reproduced** with the current generator, one corpus per layout from
the same seeds (`--seed 5000 --count 150 --budget 12`):

| detector | plain corpus | random corpus |
|---|---|---|
| line-based (before) | 115 rows at 100% | **35** |
| statement-based (after) | 110 | **110** |

(115, not the master's 118: the master measured a corpus generated
before defect 13's fix moved every seed's program. The number that
matters is the same either way — the same programs, two layouts, three
times the sameness reported in one of them.)

The line-based detector's loss, by category, was total rather than
partial: `identical-line` 30 → 2, `never-exceeded-bound` 41 → 0,
`fixed-ordering` 9 → 0, `identical-count` 2 → 0. Only
`fixed-vocabulary` (33) survived, because an identifier is spelled the
same however the line breaks fall.

**Cause.** `'process program'` read each program with `Read line` and
made the raw line the unit of comparison, for identical lines, for the
skeleton/bounds pass, for the identifier pass and for the construct
counts (which recognised `a flag called `, `To `, `While ` and friends
only at a line start, so an indented declaration was invisible and an
unindented one was not). `gen_core.vox`'s layout pass rewrites every
whitespace run: where the line breaks, how deep the indent, how wide
each gap and whether a gap beside punctuation exists at all. Those are
the exact bytes the comparison was keyed on. The sameness never moved;
the ruler did.

**Fix.** The unit of comparison is now the **statement** — LANGUAGE.md
"Basics": a sentence ending in a period — and each program is normalised
before it is measured:

- a whitespace run becomes one space, or nothing when the byte on either
  side is punctuation the layout pass may close a gap beside
  (`. , ( ) " [ ] { } :` — `'layout byte is punctuation'`, matched
  exactly, which is what makes the normal form layout-invariant instead
  of merely tidier);
- a period ends the statement unless it has a digit on both sides, where
  it is a decimal point (`3.14`; `3.` and `.5` are both parse errors —
  LANGUAGE.md:1910 and `gen_literals.vox`), and a run of periods closing
  several clauses stays with the statement it ends;
- string literals, parenthesised comments and quoted multi-word names
  are copied through untouched, by scanners that mirror `layout copy
  string` / `layout copy comment` / `layout copy quoted name` /
  `layout apostrophe opens a name` byte for byte.

Nothing was added to the keyword or ignore list.

**How it was proven** (four legs):

1. **The premise, checked**: strip all whitespace from the plain and the
   random program of the same seed and the bytes are identical
   (`tr -d ' \t\n\r' | md5sum`, spot-checked on seeds 5000, 5007, 5042,
   5100) — so any residual difference the detector reports is the
   detector's, not the generator's.
2. **The two reports now agree**: `./build/invariants` over the plain
   corpus and over the random corpus of the same 150 seeds produce
   byte-identical output apart from the corpus path in the header line —
   110 rows at 100%, 181 findings, same rows in the same order.
3. **Cross-checked against an independent implementation**: the same
   normalisation written separately in Python picks out exactly the same
   23 statements as 100%-present across the 150 programs — same count,
   same set, no difference either way.
4. **The rows that changed are accounted for**: 115 → 110 under plain is
   multi-line constructs collapsing into the single statement they
   always were. The eleven `identical-line` rows for `A thing called t1
   has` and its field lines become four `identical-statement` rows, one
   per thing; `never-exceeded-bound` rises 41 → 45 as the
   merged statements form new templates; `fixed-ordering` falls 9 → 7
   as adjacent keys merge into one block.

**Two consequences worth knowing.** The report's category is now
`identical-statement`, and the construct-count row that said `globals:
always exactly N top-level variable declarations` now says
`declarations: always exactly N variable declarations` — with the
indentation gone there is no honest way to tell a top-level declaration
from a nested one, and claiming otherwise was the line-based reading's
accident, not a measurement. The rendering is also slightly harder to
read where a gap sat beside punctuation (`a flag called fl1count
is"-b"or"--beta1",it is a number.`); that is the price of a normal form
the randomiser cannot move, and it is paid identically by both layouts.

### 13. `src/rng.vox`'s low bit alternates, so every coin flip in the generator is anti-correlated with the one before it

**Status:** **fixed** (2026-08-21). Found by the literals worker,
2026-08-21, and recorded in `gen_literals.vox` before it was fixed at
the source: `'rng below' of 2` returned 0, 1, 0, 1 for ever.

**Cause.** The generator is an LCG modulo 2^31 with an odd multiplier
and an odd increment, so bit 0 of the state has period 2 — and
`'rng below'` was `r modulo nn`, which is a function of the LOW bits.
Every two-way draw in every leaf therefore alternated, and any helper
spending a fixed number of draws per construct locked onto the
alternation and stopped varying at all (`literal boolean` emitted
`false` on all eight sample literals — an invariant with no citation
anywhere, which is what the whole rule layer exists to prevent).

**Reproduced**, 10 000 draws per bound, seed 12345:

| bound | histogram | longest run | lag-1 autocorrelation |
|---|---|---|---|
| 2 | 5000 / 5000 | **1** | **-0.999** |
| 3 | 3331 / 3381 / 3288 | 10 | -0.006 |
| 10 | 990…1013, flat | **1** | -0.035 |

The histograms are the point: below 2 is *perfectly* flat and below 10
is flat to ±4%, so a frequency check could never have caught this. What
catches it is the run length — a fair coin's longest run in 10 000
flips is about log2 10000 ≈ 13, and this had 1 — and the
autocorrelation, which is as close to -1 as an estimator gets. Below 10
never repeated a value either, for the same reason: consecutive draws
always disagreed in parity.

**Fix.** Take the draw from the HIGH bits by multiply-high:
`'rng below' of nn` is now `{r multiply nn} divide 2147483648`, so the
result is r's position below nn scaled by its top bits and bit 0 never
reaches the answer. The generator itself is untouched, so `--seed`
reproducibility is exactly as before; `nn` is at most 1000000 anywhere
it is called, so the product stays far below the 64-bit ceiling, and
`'rng below' of 0` still yields 0 as `r modulo 0` did.

**Proven** on the same 10 000 draws, and pinned in
`tests/230_units.vox` so a future change to the draw has to move a
golden:

| bound | histogram | longest run | lag-1 |
|---|---|---|---|
| 2 | 4996 / 5004 | **12** | **-0.014** |
| 3 | 3328 / 3307 / 3365 | 9 | -0.006 |
| 10 | 943…1043 | **4** | -0.004 |

log2 10000 ≈ 13 and log10 10000 = 4: the runs are now what fair draws
give. Every number in both tables was reproduced by an independent
implementation of the same LCG and the same estimator before it was
written down. `tests/220_determinism.vox` stays green — the same seed
still reproduces the same program — and the goldens that pin generated
text were regenerated and read (see the branch's report).

### 14. An ASSERT line on the far side of a NUL hole is not seen, and the finding says there was none

**Status:** **fixed** (2026-08-21). Found in a real campaign, retained
repro `vox-notes/env-a-seed-40252` (seed 40252, `classification.txt`:
`ledger assertion failed (exit 95) but no ASSERT line was found on
stdout`).

**Severity: high.** Exit 95 means a generated program caught the
compiler giving a documented result the manual says is wrong. The line
it printed names the ledger row and both numbers; without it the finding
is a shrug, and the row it contradicts has to be found by hand.

**Cause — not the one the comment already warned about.** The scan
already read the capture as BYTES rather than through a text, so every
byte was there. What it did not do was treat a **NUL as a line
boundary**. The capture in the repro is 205 bytes: `fmt4 hello4 0\n`,
then 158 NULs, then `ASSERT ENV-06: expected 9 got -1\n`. The hole holds
no newline, so the last line start the scan knew about was byte 15 — the
first NUL — and the marker test at byte 15 failed against a NUL every
time. The line was in the buffer, read, and never looked at.

The hole itself is nobody's bug: the harness captures a run by pointing
the child's fd 1 at a file, so a generated program that opens
`/dev/stdout` for writing reopens *that file* at offset 0 and truncates
it, while the Prints keep going through a descriptor with its own
offset. Everything between the two offsets reads back as NULs. The
generator emits `/dev/stdout` writes on purpose (`gen_files.vox`), so
this is a shape campaigns will keep producing.

**Reproduced** by running `'the assert line in file'` over the retained
capture: it returned the "no ASSERT line" stand-in. Swapping **one** NUL
of that capture (the byte before the `A`) for a newline made the same
scan return `ASSERT ENV-06: expected 9 got -1`, which pins the mechanism
to the line-boundary rule and nothing else.

**Fix.** In `'the assert line in bytes'`, a NUL ends a line exactly as a
newline does — it is the hole, not something a program printed, and the
line after it starts where it ends. The scan still runs one past the
last byte so an unterminated final line is considered, still requires
the marker to START a line, and still reports the LAST match.

**Proven**, three ways:

1. the retained repro now yields `detail: ASSERT ENV-06: expected 9 got
   -1` — the leaf's row and its claim, which is what the classification
   was missing;
2. `tests/290_ledger_assertion.vox` gains the byte shape of that capture
   (a 14-byte line, 158 NULs, then the ASSERT line), a hole *after* the
   last ASSERT line, and an end-to-end leg: a new fixture,
   `tests/fixtures/ledger_assertion_hole.vox`, punches the hole through
   its own captured stdout the same way seed 40252 did, exits 95, and is
   compiled, run under capture and scanned through the same three calls
   the gen loop makes — the test asserts the capture really is holed
   before it asserts the line was found;
3. those new legs were run against the **pre-fix** scanner and fail
   there (`detail across the hole` and the end-to-end `detail` both come
   back as the stand-in), so they are a regression guard rather than a
   restatement.

## Defect 14 — float leaves assert one parse route against the other (found by the 90000 campaign, 2026-08-24)

VAL-12's retype-tracking leaf declares its payload **via text**
(`a value called 'the sample' is "469046.3893743563967901442".`),
retypes to float, then asserts the payload equals the bare 25-digit
literal. LANGUAGE.md:2066-2072 gives the two routes different
readings: a source literal parses to the nearest double of all its
digits, a text read to "the nearest float those eighteen digits
describe". Whenever a drawn payload exceeds 18 significant digits and
the prefix rounds differently, the two doubles differ and the
assertion is unwinnable — the leaf reports a compiler defect that is
actually the manual's own documented behaviour.

**Proven:** seed 90320 rederived with --keep; the firing line compares
the text-declared sample against the full literal. Python/IEEE check:
the compiler's literal route is 0.0 ulps from the nearest double of
all 25 digits, its text route 0.0 ulps from the nearest double of the
18-digit prefix, the two exactly 1 ulp apart — the compiler is
bit-exact on both routes. Minimal probes: literal-declared no-op
retype and no-retype control both hold the payload; the text-route
probe reproduces the split. Fix direction: clamp drawn float payload
literals to 17 significant digits (round-trippable), or assert within
one route.

## Defect 15 — campaign-scale finding save reads an already-swept scratch (found by the 90000 campaign, 2026-08-24)

All four findings of the 90000 campaign (seeds 90320/90330/90345/90348,
class wrong-value) were recorded with an EMPTY program.vox and the
detail "ledger assertion failed (exit 95) but no ASSERT line was found
on stdout" — program and capture lost together, so the finding
directory breaks its own self-contained-repro promise. Single-seed
reruns of the same seeds (with and without --keep) record perfectly: a
28073-byte program.vox and the real ASSERT detail. So the loss happens
only at campaign scale, on the exit-95-without-ASSERT classification
path — consistent with the finding save reading source and capture
after the pid+seed scratch sweep, against loop_gen.vox's own
save-then-sweep comment; "no ASSERT line" is also what the
capture-open error path returns, so one swept directory explains both
symptoms. Findings remain rederivable from their seeds.

**CORRECTED 2026-08-24, and this entry was wrong.** Defect 15 is not a
defect of its own: it is a symptom of Defect 14. The ordering blamed
above is correct and always was — the exit-95 branch reads the capture
and the source BEFORE the sweep, unchanged since the branch was
introduced (`git blame` on loop_gen.vox), and two probes denied the
only competing theory (a sticky error flag from a failed capture open
emptying the following source read; a read after a failed open returned
full bytes both times). The four empty findings were Defect 14's false
positives — VAL-12's unwinnable cross-route float assertion firing exit
95 — so clamping the drawn float payload removes the trigger and the
symptom with it. Verified at campaign scale: with the exit-95 path
forced over 120 seeds, all 50 findings carried a non-empty program.vox.
A PROBE in `finding save` now prints on stdout if an empty program.vox
is ever written again, so the symptom cannot hide even if some unknown
path revives it. Fixed in the same commit as Defect 14.

**Also noted here:** repro.sh does not recreate the harness
environment, so a program with environment leaves can take a different
path under it (seed 90320 exits 92 via an env-guarded exit in a plain
shell, and asserts VAL-12 under the harness).

## Defect 16 — a pool-name collision lets one leaf capture another's binding (found by the 100000 stripe campaign, 2026-08-24)

The flag-schema leaf drew the pool word `caption` as a flag name
(`caption is "-p" or "--caption", ...`); the file round-trip leaf in the
same program built its path from `{caption}`, expecting the variable
that binds the scratch directory. The name cycle's guarantee — two
names in one program are distinct by construction — does not extend to
the FIXED names a leaf expects to find already bound, so the flag
claimed the word and the file leaf inherited a flag's value. With no
`--caption` argument the path became `<default>/buffer2` outside the
confined scratch: the write failed, the read returned 0, and BUF-07
asserted — a confinement breach stopped only by kernel permissions,
which docs/PROCEDURE and the generation policy say must never be the
backstop.

**Proven:** seeds 100103, 101434, 101707, 101964 (8-way stripe,
100000–101999) all carry the signature; solo rerun with scratch argv
reproduces `ASSERT BUF-07: expected N got 0` and `ls` shows the write
never landed in scratch. Fix direction: the scratch binding's name must
be reserved out of every draw pool (or drawn once and threaded), and
`tests/230_units.vox` should prove pool-vs-fixed-binding disjointness
the way it proves pool-vs-pool.

## Defect 17 — the generator allocates a fresh heap buffer per emitted fragment (found by the day-0.4.13 stripes' OOM, 2026-08-25)

Vox releases heap-backed locals (buffers, lists, format-string texts)
only at program exit — a variable declared inside a function or loop
body is allocated on every entry and never returned, at a flat cost per
declaration (≈4 KB, page-granular, independent of the content's actual
size — confirmed for both dynamic and fixed-size buffers). `'gen emit'`
(`src/gen_core.vox`), the single chokepoint every rendered fragment of
every generated program passes through (167 call sites across five
files), declared `a buffer called piece is "{s}"` on every call before
appending `piece` to `gen_out` — one throwaway 4 KB allocation per
fragment, never freed, for the life of the process. At budget 40 that
measured **~40 MB per generated program**; the four day-0.4.13 stripes
launched 2026-08-25 11:00 ran long enough to reach 20 GB / 15 GB / 10 GB
anon RSS each and were killed by the kernel OOM killer, then killed
again after their auto-restarts — all 269 "hang" findings they had saved
were compile-timeout artifacts of a machine with no free memory, zero
compiler bugs (recompile in ≤2.4 s, rc 0, all 269; findings parked at
`vox-fuzz/findings/day-0.4.13-oom-artifacts/`).

The same root cause hid in more than one shape. A second, independent
one: rebuilding a text by self-referential format-string reassignment
(`Set t to "{t}{c}"` in a loop) does not merely leak a flat 4 KB per
iteration — it re-copies the WHOLE current string on every iteration and
leaks the old copy, an O(n²) cost. `'gen build input'`
(`src/gen_files.vox`) did this while drawing up to 999 characters,
measured at roughly 0.5 MB per call — real, if two orders of magnitude
smaller than `'gen emit'`'s. See REPORT-FUZZ-D17.md's "Quadratic
Set-reassignment" section for the isolated measurements (5k/10k/20k/100k
iterations); this is the same design question already open as Q7
(`vox-notes/2026-08-28-Q7-scope-exit-free.md` — should a heap-backed
local be freed at scope exit) and is not something a fuzzer defect entry
adjudicates.

A third shape of the same cause: `'gen join lines'` — one of `'gen
emit'`'s own hottest paths, called once per rendered line of every leaf
in the corpus — routed each line through `'gen line piece'`, a helper
whose entire body was `a text called piece is "{indent}{content},\n".`
A fresh format-string TEXT, not a buffer, but the same page-granular
allocation applies: measured at ~4 KB per call, identical to a buffer.

**Fix applied:** `'gen emit'` now appends its text argument directly
into `gen_out` (`append s to gen_out.` — buffer `append` takes a
format-string/text source directly, LANGUAGE.md's "Buffer Append and
Copy" section, not just the buffer→buffer form indexed near the Lists
section; verified against the live compiler before use), with no
per-call buffer at all. `'gen join lines'` now appends each line's
format string straight into `gen_out` too, and the now-empty `'gen line
piece'` helper was removed. Every other heap-backed local found
declared per call or per loop iteration across `src/gen_*.vox`,
`loop_gen.vox`, `harness.vox`, `runner.vox`, `findings.vox` and
`sandbox.vox` was audited; the ones with material cost were hoisted to
program level and reused via `clear` + `append` (or, where `Read`
already replaces a buffer's contents, reused with no `clear` needed),
converting to a `text` once at the end rather than mid-loop.
`gen_files.vox`'s quadratic `Set gen_input to "{gen_input}{c}"` became a
per-character `append` into a program-level buffer; the per-iteration
`a text called c is 'gen digit for value' of pick` that fed it was also
removed in favour of appending its source expression directly (a format
string for the `pick > 35` branch, the function call itself for the
other), since buffer `append` takes either as a source without an
intermediate. Distributions are untouched: no `'rng below'` call was
added, removed, or reordered, and `'gen digit for value'` draws no
randomness of its own, so the fix changes only how a program is
buffered while it is built, not what is generated.

One attempted fix was reverted: caching each variable's `"v{n}"` name at
declaration (in a program-level list) so `'gen var ref'` could return
the cached text instead of re-synthesising it on every reference. It
worked within a single generated program but was wrong across a
multi-seed run in one process — `gen_vars` resets to 0 per seed but the
cache list does not, so seed 2's names land at the wrong list index once
it declares more variables than seed 1 did, producing a program that
diverges from `main`. Caught by review before the gate was signed off;
reverted in full (see REPORT-FUZZ-D17.md's "Reverted" section). No other
program-level list or map was introduced by this fix — every other new
global is a buffer, `clear`ed or fully overwritten on every call, which
does not have this per-seed accumulation hazard.

The residual ~1 GB after this fix is `'gen var ref'` and every other
`a text called … is "…{…}…"` site the corpus still evaluates once per
use — the same ~4 KB-per-allocation cost, just not funneled through one
chokepoint the way `'gen emit'` was. See REPORT-FUZZ-D17.md's "Residual"
section for why this is treated as language-inherent (the same Q7
question, generalised from buffers to format-string texts) rather than
fixed further here.

**Proven:** isolated probes against the live compiler before each fix
was written (`/tmp/.../d17-probe/`, evidence retained with the report):
a fresh 4 KB-class buffer declared per call, 40,000 calls, measured 160
MB RSS; the same 40,000 appends into one `clear`-and-reuse buffer
measured 384 KB. A fresh format-string TEXT (not a buffer) declared per
call, 40,000 calls, measured ~156 MB — the same ~4 KB/call as a buffer.
`Set t to "{t}x"` 100,000 times measured ~5 GB (master independently
reproduced 23/71/236 MB at 5k/10k/20k, confirming the quadratic shape);
the same 100,000 appends into one buffer measured 384 KB. Gate results
(full commands, both binaries, and the diff output are in
REPORT-FUZZ-D17.md): `make build` + `./test.sh` 30/0 on the fixed tree;
memory gate `gen --seed 900000 --count 200 --budget 40` maxrss before
~8 GB (matches `~40 MB × 200 seeds` from the `'gen emit'` measurement
above) / after **991 MB** (gate revised from the brief's 512 MB to
"under 1.2 GB, byte-identical" once the residual above was identified as
language-inherent, not a fuzzer defect); byte-identical `program.vox`
for every seed 900000–900199 between a binary built from this fix and
one built from `origin/main` in a separate extract (`diff -r`, empty,
exit 0).
**FIXED 2026-08-28, with an open re-derivation gap — read the
discrepancy note below before treating this as fully closed.**

**Re-derived the source-level collision on all four proven seeds**
before touching any code, both on `vox-fuzz` `22e5479` built against the
vox `0.4.12` binary the campaign's own SEEDS.md row records: 100103
draws `caption` (`caption is "-p" or "--caption", ...`, path
`"{caption}/buffer2"`), 101434 draws `layby`, 101707 draws `coupon`
(among two other ordinary flags in the same program — `voucher`,
`legend` — proving the collision is with the SCRATCH role specifically,
not just "any flag"), 101964 draws `subtitle`. All four match the
ledger's account exactly.

**The four seeds no longer reproduce a live finding, on any binary
tried.** Solo reruns at budget 40 — on the unmodified `22e5479` build
against both today's vox and the campaign's own `0.4.12` binary/coreasm
(rebuilt from the `v0.4.12` tag to rule out a compiler-version
difference), and on today's HEAD — all report 0 findings for all four
seeds. An instrumented `22e5479` build (tracing `gen_scratch_argv` /
`gen_scratch_flag` immediately before the child is exec'd) confirms the
harness threads the scratch pair first on argv exactly as
`loop_gen.vox`'s own comment says it should, for every one of the four.
A partial 8-way concurrent re-run, mimicking the original stripe layout
on the same `22e5479`/`0.4.12` pair, got roughly a third of the way
through with no finding surfacing before it was stopped on a resource
steer (the `22e5479` binary predates Defect 17's per-fragment
allocation fix and leaks under sustained striping — an unrelated,
already-known hazard, not this defect) — so concurrency as the trigger
is neither confirmed nor ruled out; it was not re-attempted. The exact
conditions that produced the original four findings were not recovered.
Everything the current code does around the scratch binding was
re-checked by hand against this outcome and found sound: the manifest
excludes the scratch-role flag from the argv-stress builder's
candidates (`gen_manifest.vox`'s `'gen manifest pick a flag of kind'`,
present since the prelude was drawn, 2026-08-21 — predates this
defect), the scratch pair is prepended to argv before any drawn shape
can reach it (`loop_gen.vox`, also 2026-08-21), and every pool the
scratch flag's word can come from is prime-length, so the per-program
cycle's no-repeat guarantee actually holds (`gen_flag_words` is 29,
`gen_function_words` is 37 — checked because the cycle's own comment
says the guarantee depends on it and nothing had verified it).

**Constructed a targeted reproduction instead** (PROCEDURE's fallback
when a historical seed will not reproduce): compiled seed 100103's
kept program and ran the binary directly WITHOUT its `--caption`
argument, bypassing the harness rather than finding a harness bug.
That reproduces the documented failure exactly — `ASSERT BUF-07:
expected 12 got 0`, and no file lands anywhere because the interpolated
path is the bare `/buffer2`, refused only by `/`'s write permission
(confirmed absent afterward). This is real, hand-verified evidence of
the hazard class the fix direction names: the confinement guarantee for
both file leaves rests entirely on `gen_scratch_flag` being bound by
the time they run, with nothing on the generator's own side checking
that it held — an accidental backstop (kernel permissions) standing in
for a guarantee that was never actually enforced anywhere in code, only
asserted in a comment ("It is never empty here").

**Fixed the enforcement gap, not a re-derivation of the trigger.**
`gen_files.vox`'s `'gen leaf file round trip'` and `gen_buffers.vox`'s
`'gen leaf buffer truncation'` — the only two leaves that interpolate
`{gen_scratch_flag}` into a path — now check it themselves: if
`gen_does_file_io` is true but `gen_scratch_flag` is empty, the leaf
prints `PROBE g3` and falls back to the safe stand-in leaf instead of
ever emitting a path built on the unbound name, converting "kernel
permissions caught it by luck" into "the generator refuses to emit it."
The other two FIXED-binding leaves in the codebase (`gen_reader_name`,
`gen_grid_sink_name`, both `gen_manifest.vox`/drawn from
`gen_function_words`) were already provably safe by construction
(same-cycle, same-pool as ordinary functions) and needed no code
change; `gen_grid_sink_local` is a function-LOCAL name (drawn from the
parameter cycle, LANGUAGE.md:1692's separate member/local space), so it
was never a candidate for this class of bug, matching how
`gen_parameter_words` is already exempted from the pool-vs-pool checks
above.

`tests/230_units.vox` gained the pool-vs-FIXED-binding proof the fix
direction asked for, generalised from the existing pool-vs-pool rows:
since these names are not static lists, the proof runs 1000 seeds
through `'gen program'` (the real manifest+argv path) and checks what
it actually produced. Nine new rows, all reading 0: `gen_scratch_flag`
is never empty while `gen_does_file_io` is true; exactly one flag ever
carries role 1 and its written name always equals `gen_scratch_flag`;
the argv-stress builder (`gen_text_flag`/`gen_number_flag`/
`gen_boolean_flag`) never resolves to that flag; `gen_reader_name` never
equals `gen_grid_sink_name`, and neither ever equals any ordinary
function's or flag's written name. None of the 1000 trials printed
`PROBE g3` either.

**No pool word was removed and no draw was added or reordered** — the
guards are plain `is empty` checks with no `'rng below'` call, so they
consume nothing from the RNG stream. Seeds 900000–900199 at budget 40,
`--keep`, generated on `origin/main` (`ef9dee2`) and on this branch:
200/200 programs byte-identical, 0/0 findings both sides.

`make build` + `./test.sh` (this worktree): 30/0, including the two
local-only soak tests (`200_never_emitted`, `270_layout`).

**Handed to Josj: the trigger for the original four findings is still
open.** Either it needs the original 8-way concurrent layout to
reproduce (untested past the partial, resource-stopped run above — a
supervised, memory-bounded re-run under Defect 17's fix would be the
next step, striped at or under core count per the SEEDS.md note on the
19 oversubscription artifacts from the same campaign), or something
about the original invocation — timeout, working directory, an
intermediate generator state that predates `22e5479` and was never
committed — differed from what could be reconstructed here. The fix
above closes the hazard class regardless of which it turns out to be:
even if the true trigger is still out there, the generator can no
longer emit a path built on an unbound scratch name, and the new tests
would catch a regression in the binding itself.

## Defect 18 — `'gen leaf cast and break'` leaves its `For each` open, so every later statement nests inside the loop (found by the things batch A campaign, 2026-08-29)

`'gen leaf cast and break'` (`src/gen_misc.vox`) ends its loop with

```
For each ce4 from 1 to 24,
    a number called cs4 is ce4 multiply 2,
    If cs4 is greater than 24 then, Break.
```

One period closes one level (LANGUAGE.md:154 — "A period closes the most
recently opened clause … and only that one"), so that period closes the
`If` and leaves the `For each` open. Everything the generator emits after
the leaf, at whatever level the leaf sat, is inside that loop:

- an ordinary statement runs once per remaining iteration instead of
  once — `Break` fires only when `cs > ceiling`, i.e. after about half the
  iterations, so the tail of the program is executed ~`ceiling / 2` times
  (the ceiling is drawn), silently; a wrong-value or hang finding from
  such a program is an artifact of the generator's own punctuation;
- a top-level-only construct emitted next — a thing definition or a
  function definition, which the things batch A leaves emit at top level —
  is now inside a loop body and the program does not compile ("A thing is
  defined at the top level, like a function … Move the definition above
  the block it is written in", things batch A campaign seed 5159); the
  runner buckets a plain compile error as a generator defect, not a
  finding, so the campaign reported `compiled: 199 findings: 0` and the
  loss was only visible in the count.

LANGUAGE.md:769 states the fix in the sentence right after that very
diagnostic: "A period stacks with the one that closes the `if` to close
the `For each` too, in the same step: `Break..` compiles and runs exactly
like a blank line ahead of the `To`". The guard line becomes
`If cs{n} is greater than {'the ceiling'} then, Break..` — one character.

Reach: in the 200-program `main` baseline corpus for this merge
(`--seed 20260829 --count 200 --layout plain`), the leaf appears at top
level in **22 of 200 programs (11%)** — kind 35 is top-level-only — each of
which ran its whole tail inside the loop (`evidence/2026-08-29-leaves-merge/`).

**Status:** fixed in the leaves merge of 2026-08-29 (one character in
`src/gen_misc.vox`); no golden pinned the faulty shape, so only
`tests/040_gen.expected` moved, and that file was regenerated for the
merged draw anyway. A unit row proving the closed clause (a `230_units`
trial: the statement after the leaf is emitted at the leaf's own level)
is owed by the misc sweep — the same sweep that owns the open-clause
review of the rest of `gen_misc.vox`.

## Defect 19 — counter-suffixed instance names (`i<N>`, `l<N>`) and the manifest's small word pools show up as fixed-vocabulary invariants (found by the leaves merge diff, 2026-08-29) — OPEN, tracked

The merged 200-program campaign for the 2026-08-28 leaf batches, diffed by
finding key against the same-seed `main` baseline, crossed the report's
50 % line on identifiers no ledger can justify because LANGUAGE.md pins
none of them:

- `i1` (63 % after the night's four batches; 77 % with things-b, which also lifts `i2` to 59 % and the call-result names `c<gen_args>` — `c1` — to 51 %): every generated thing instance is named `i<gen_instances>`
  (things surface convention, `gen_things.vox`); the six new things leaves
  emit instances too, so the share rose above the threshold. Every list
  the collections surface declares is `l<gen_lists>` the same way, and the
  flow surface's FLW-21 leaf inherited it. Both shapes are the banned
  letter-plus-counter names of `vox/docs/STYLE.md` and read badly in the
  emitted programs.
- `bearing` (53 %), `run` (52 %): words from the manifest's type/field/
  function pools (`gen_type_words` / `gen_field_words` /
  `gen_function_words`, `gen_manifest.vox`); the pools are small enough
  that with more definitions per program a given word is in more than
  half the corpus. Baseline shares were 46 % / 46 %; nothing new is
  emitted, the pools are simply too small for the number of names now
  drawn from them.

None of these is a template a leaf asserts; they are naming, and the fix
is the same in each case: draw the name from a vocabulary large enough
that no single word crosses the threshold (the buffers/files leaves'
`'gen buffer name'` pool is the working precedent), and widen the manifest
pools. That is a whole-surface change with its own golden regenerations
(things: 300-series thing goldens, 350; collections; flow 360; 040), so it
is queued as one brief rather than patched per batch.

**Status:** open. Not introduced by the 2026-08-28 batches — they raised
existing shapes over the line — but recorded here because §8 says an
invariant no ledger justifies is a defect until the generator stops
producing it.
