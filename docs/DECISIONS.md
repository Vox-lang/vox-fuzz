# vox-fuzz — decisions and what we know

A durable record of the decisions behind vox-fuzz, the reasoning that
produced them, and what would justify revisiting them. Written so it
still makes sense to someone arriving cold, months from now, with none
of the conversation that produced it.

**Last updated:** 2026-08-17 · **Against:** vox v0.3.7

Each decision records what was chosen, why, and — most importantly —
**what would change it**, so a future reader can tell a settled decision
from a provisional one.

---

## D1. vox-fuzz is written in Vox, not Rust

**Decided:** 2026-08-17. **Status:** settled.

The fuzzer that attacks the Vox compiler is itself written in Vox.

**Why.** Three reasons, in order of weight:

1. *Findings are self-verifying.* A finding is a `.vox` file that
   segfaults when compiled and run. Anyone can reproduce it without
   trusting the tool that found it, so the fuzzer's own correctness is
   not load-bearing for the credibility of its results.
2. *Dogfooding is itself testing.* Writing a multi-thousand-line real
   program in a young language finds compiler bugs and ergonomic gaps
   during development, before the fuzzer runs at all. This has already
   paid: see `vox/docs/BUGS-FOUND-VOX-FUZZ.md`, whose headline finding
   was hit by hand-writing about ten lines of Vox.
3. *Credibility.* A language claiming memory safety and capability,
   whose author reached for another language to test it, argues against
   itself. Fuzzer in Vox, benchmarker in Vox, site served by Vox is the
   opposite argument.

**What was argued against it, and why it lost.** That an instrument
should not be built by the system it measures — a miscompiled fuzzer
could in principle hide the bugs it hunts. This is a real concern but a
weak one in practice: the field's precedent runs the other way (AFL and
AFL++ are C, libFuzzer is C++, and Csmith — which found hundreds of GCC
and LLVM bugs — was compiled by the compilers it tested), and a
miscompiled fuzzer fails loudly rather than conspiring silently. The
self-verifying repro artifact (reason 1) closes the remaining gap.

**What would change it.** Nothing short of discovering that Vox cannot
express the harness at all. That was checked and it can — see D2.

---

## D2. Child-death classification uses a shell wrapper, not native syscalls

**Decided:** 2026-08-17. **Status:** settled for v1, revisit if the
language gains native support.

The harness forks, `Execute`s `/bin/sh -c "timeout N <cmd> ; echo $? >
status"`, reaps, then reads and parses the status file.

**Why.** Vox's native `reap` discards the wait4 status — `REAP_CHILD` in
`coreasm/x86_64/file.asm` passes a NULL status pointer, so the kernel
never writes it — and there was no kill(2) at the time. The fuzzer's
entire job is "how did this child die?", so this looked like a blocker.
It is not: `$?` already encodes everything needed.

| Status | Meaning |
|---|---|
| `0` | clean exit |
| `1`–`100` | the program's own exit code (**not** a finding) |
| `124` | `timeout(1)` killed it — a hang |
| `>128` | died by signal `status − 128` |

**Verified**, not assumed: a proof-of-concept correctly classified a
clean exit, an exit code of 7, a SIGSEGV (139 → signal 11), and a hang
(124) against the 0.3.7 binary.

**Consequence that constrains the generator.** `$?` cannot distinguish a
program that legitimately exits 139 from one that segfaulted, so
**generated programs only ever emit exit codes 0–100**, reserving 124 and
128+ for the classifier. This is a hard invariant.

**Cost.** One extra `sh` spawn and a file round-trip per execution —
negligible beside the compile step. Adds `/bin/sh` and coreutils
`timeout` as runtime dependencies, which is acceptable for a development
tool.

**What would change it.** Native access to the reaped wait status (see
G1). The shell wrapper would then collapse to a direct read, and the
`/bin/sh` dependency would disappear.

**Method note worth preserving.** The original claim that this was a
blocker was wrong, and wrong in a specific way: a missing *native
feature* was promoted to a *blocker* without first attempting
composition from existing features. Verify capability claims with a
working proof-of-concept before letting them shape a plan.

---

## D3. No differential oracle in v1

**Decided:** 2026-08-17. **Status:** deferred by owner decision, not by
technical judgement.

v1 detects crashes, hangs, ICEs, toolchain rejections, and compile
nondeterminism. It does **not** check whether a program computed the
right answer.

**Why.** The project owner defers work whose concepts he has not yet
evaluated, rather than accepting machinery he would not be able to
review. This is a deliberate policy, not an oversight.

**What it costs.** Silent miscompiles — a program that runs cleanly and
prints the wrong number — are invisible to v1. Note that the headline
bug in `BUGS-FOUND-VOX-FUZZ.md` (a non-firing `On error` swallowing the
rest of its sentence) is exactly this class in its correctness form,
though its loop variant surfaces as a hang, which v1 *would* catch.

**The seam.** The generator is the plug-in point. Two designs were
sketched:

- *Generator-as-oracle* — the generator computes each program's expected
  output as it builds it. Cheap; works only on generated programs;
  shares the generator's blind spots.
- *Standalone interpreter* — a second implementation that reads any
  `.vox` file. Expensive (needs a parser for Vox's prose-like block
  rules); works on hand-written programs and existing tests too;
  genuinely independent, and can catch parser bugs the other cannot.

**What would change it.** The owner deciding he wants it. Do not
re-propose unprompted.

---

## D4. The invariant under test

**Decided:** 2026-08-17. **Status:** settled.

For any Vox program and any runtime input:

1. The compiler must not panic (no ICE).
2. Emitted assembly must be accepted by nasm and ld.
3. The emitted binary must never die by signal.
4. The emitted binary must terminate within the timeout.
5. Compiling the same source twice must produce identical assembly.

**Why this is the right invariant.** Vox's documented safety model is
*error flags, not traps*: out-of-bounds access sets a flag and returns 0,
writes past a fixed buffer are refused, "buffer overflow is impossible".
So a signal death is a contradiction of the language's own claims — no
oracle required to know it is a bug.

**The critical exclusion.** A **nonzero exit code is not a finding**.
Vox programs exit nonzero legitimately. Confusing this would turn the
fuzzer into a noise generator.

---

## D5. Process is a library concern, not a language builtin

**Decided:** 2026-08-17. **Status:** open — direction agreed, mechanism
undecided.

The question arose whether Vox should gain a `process` type exposing
`reaped's exit code` and similar as properties.

**The owner's position**, which should govern similar questions: in C,
`pid_t` is an `int` and `WEXITSTATUS` is a macro in `sys/wait.h`; in
Rust, `Process` and `ExitStatus` are library structs in `std`. Languages
provide primitives plus a *composition mechanism*, and things like
Process are built from those. Adding a `process` builtin to Vox would be
the un-Rust-like move precisely because users cannot build their own.

**The obstacle.** Vox has eleven builtin types and **no user-defined
structs or records** (`src/parser/ast.rs:5`), so "Process is a library
type" is not currently expressible. See G2.

**The interim shape, if one is wanted before records exist:** the C
model — the compiler exposes the raw wait status as a plain number, and
a pure-Vox library decodes it. Vox has `divide`, `modulo`, and bitwise
operators, so the decode is ordinary arithmetic needing no compiler
support. This does not have to be unwound later; when records arrive,
the library is rewritten to return one.

---

## Known gaps in Vox, as they affect this project

Recorded here because they shape vox-fuzz's design. None currently block
it.

### G1. `reap` discards the wait status; no native way to read it

`REAP_CHILD` passes wait4 a NULL status pointer. Worked around by D2.
Closing it would simplify the harness and drop the `/bin/sh` dependency.

### G2. No user-defined types

Eleven builtin types, no structs/records/classes. Property access
(`buffer's size`) is a fixed per-type enum (`ObjectProperty`,
`src/parser/ast.rs:243`). This is what forces D5's interim shape.

Worth noting for whoever designs it: Vox's builtins are already
compiler-blessed structs — a buffer is
`[capacity:8][length:8][flags:8][data...]` and `'s` already reads fields
at fixed offsets — so records would expose a mechanism the compiler
already has, with no runtime component. That fits Vox's no-resident-
runtime constraint, whereas classes with virtual dispatch would not.

### G3. No parenthesised grouping for call arguments

`f of n minus 1` means `(f of n) minus 1`. Correct precedence, but it
reads the other way in English, and written recursively it produces
silent infinite recursion. vox-fuzz's own code must precompute call
arguments into locals, and its generator must emit them that way.

---

## Closed gaps

- **`times` as a multiplication alias** — LANGUAGE.md had promised it
  while the parser rejected it (documentation drift). Fixed:
  `e37ee7e` on `feature/process-status-and-aliases`.
- **No kill(2)** — added as `Send signal N to process/child P.`
  Fixed: `5e20d77` on the same branch. Review caught that `send` was
  initially claimed as a keyword unconditionally, breaking any
  user-defined `send` function; fixed with one-token lookahead following
  the 0.3.7 precedent for `begin`/`stop`/`finish`.
- **Installed coreasm shadows the repo's** — documented in
  `vox/docs/INSTALL.md` (`59fa464`). vox-fuzz pins `VOX_CORE_PATH`
  everywhere it invokes vox; without it the fuzzer would silently test
  the packaged runtime instead of the development one.

---

## Verified Vox language notes

Behaviours confirmed by running code against 0.3.7, not read from docs.
The implementation plan carries the full list; these are the ones that
cost the most time when forgotten.

1. Function definitions end at a **blank line**; a period does not close
   the body. Without it, following statements are absorbed and the
   program silently does nothing.
2. `Return a <type>, <expr>.` goes at the **end** of the body, not on
   the signature line.
3. Call arguments must be precomputed (G3).
4. A blank line inside a loop body **closes the loop** — never insert
   one for visual spacing.
5. Some words are reserved and fail as loop variables (`arg`), with a
   misleading "Missing loop variable" diagnostic.
6. Text accumulation: `Create a buffer called out.` then
   `a buffer called piece is "text {var}\n".` then `append piece to out.`
7. Recursion is depth-limited and overflow is caught cleanly
   (`Error: stack overflow`, exit 1) rather than crashing.
8. Out-of-bounds byte reads return 0 and set the error flag — useful as
   a parse-loop terminator.
9. `see "./other.vox".` splits a program across files; paths resolve
   relative to the including file.
10. `arguments's count` includes argv[0]; `arguments's all` yields
    argv[1..].
