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
