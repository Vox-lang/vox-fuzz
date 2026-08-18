# vox-fuzz

![Open issues](https://img.shields.io/github/issues/Vox-lang/vox-fuzz?style=flat-square)
![Repo size](https://img.shields.io/github/repo-size/Vox-lang/vox-fuzz?style=flat-square)
![Last commit](https://img.shields.io/github/last-commit/Vox-lang/vox-fuzz?style=flat-square)
![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)
[![crates.io](https://img.shields.io/crates/v/vox-fuzz?style=flat-square)](https://crates.io/crates/vox-fuzz)

A fuzzer for the [Vox](https://github.com/Vox-lang/vox) compiler —
**written in Vox**. It generates random valid Vox programs, compiles
them with the real compiler, runs the binaries under its own native
process supervision, and records every case where the toolchain breaks
its promises.

## The invariant under test

A binary the Vox compiler produces must never:

- **die by signal** — segfaults are what the language's memory-safety
  story exists to prevent;
- **hang** — past its deadline, it is killed and recorded;
- have made the **compiler itself crash** (an ICE: a signal death or a
  Rust panic), or emit assembly that **nasm/ld refuse**.

A nonzero exit code is *not* a finding — programs are allowed to fail;
they are not allowed to fail unsafely.

## Why it's written in Vox

The same reason the compiler has no runtime: the claim should carry its
own evidence. A multi-thousand-line systems tool in a young language
finds bugs by existing — building this project surfaced five real
compiler findings before the fuzzer ran a single seed, and its first
generation session led directly to
[bug #25](https://github.com/Vox-lang/vox/blob/main/docs/BUGS_FOUND.md)
(uninitialised conditional-path declarations: stack garbage, segfaults).
Findings are also **self-verifying**: each one is a `.vox` file plus a
`repro.sh` — you reproduce it without trusting the tool that found it.

## How it works

| Module | Job |
|---|---|
| `src/rng.vox` | seeded LCG — every finding reproducible from its seed alone |
| `src/gen.vox` | emits valid-by-construction programs: arithmetic, control flow, buffers (with deliberately out-of-range access), lists, `On error`, functions, and user-defined **things** |
| `src/harness.vox` | pure-Vox supervision: fork, `Execute`, non-blocking reap against a deadline, `Send signal 9`, verdicts from the raw wait status — `exit 139` and SIGSEGV can never be confused |
| `src/runner.vox` | compile via shell (stderr captured), run via native supervise |
| `src/findings.vox` | one self-contained repro directory per finding |
| `src/loop_gen.vox` | the classification loop: ice / asm-reject / crash / hang |

## Building and running

Requires a Vox compiler (0.4.2+) and nasm/ld:

```sh
export VOX=/path/to/vox                 # defaults to ../vox/target/release/vox
export VOX_CORE_PATH=/path/to/coreasm   # pin the runtime; test.sh refuses a bad one
./test.sh                               # the project gate — 9 tests
```

A fuzzing session is currently a small Vox program (the CLI is the next
milestone — see the plan):

```vox
see "./src/rng.vox".
see "./src/harness.vox".
see "./src/runner.vox".
see "./src/gen.vox".
see "./src/findings.vox".
see "./src/loop_gen.vox".

'fuzz gen run' of 1000 and 200 and 12 and 10000.
```

— first seed, how many programs, statements per program, per-program
deadline in milliseconds. ~24 programs/second end to end on modest
hardware: generated, compiled, linked, run, classified.

## Findings

Each finding lands in `findings/<category>/<seed>/` with the generated
`program.vox`, a `classification.txt`, and a `repro.sh` that stands
alone. Curated findings that led to filed compiler bugs are preserved
with their full adjudication under [`docs/findings/`](docs/findings/) —
including the pair whose investigation uncovered bug #25.

## Status

Foundation, generator, findings store, and the fuzzing loop are on
`main` behind CI and branch protection; 2,400+ seeds have run at 100%
compile-clean. Remaining per the
[v1 plan](docs/superpowers/plans/2026-08-17-vox-fuzz-v1.md): the CLI,
test-case reduction, the compile-determinism check, and runtime-input
fuzzing. The [release pipeline](docs/plans/317_release_pipeline.md) is
staged behind the CLI.

## Licence

GPLv3 — see [LICENSE](LICENSE).
