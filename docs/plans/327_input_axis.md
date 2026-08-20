# Plan 327 — the input axis: argv and stdin

**Origin:** Josj, 2026-08-20, on learning that generated programs have
never received an argument: *"No wonder we're not finding anything... We
want a higher probability of passing valid flags to programs, but we
also want to randomly pass incorrect flags, and flags with unexpected
values and flags with expected values, as well as additional random
parameters... Then on stdin we want to ALSO hammer these random programs
with random bits, with `open "/dev/stdin"` / `0` along with read from
stdin into buffer being injected randomly."*

**Supersedes:** defect 7 and defect 10, which are the two halves of this.
Absorbs plan 324 T3.

---

## The problem, stated plainly

A generated program has three input channels: its source, its argv, and
its stdin. **Only the first has ever varied.** `runner.vox` builds
`a list called 'no arguments' is []` and passes it on every path, and
`supervise` forks and `Execute`s with no stdio redirection at all.

So every campaign runs thousands of different programs through one
identical, empty environment. The flag schema — the richest surface the
generator touches, and the source of compiler bugs #31, #32 and
indirectly #33 — is exercised only in its unsupplied case.

## Part A — argv

### A1. The harness must pass arguments

`supervise` already takes an argument list and is only ever handed an
empty one. `run program` and `run program capturing` gain an argument
list parameter, and the gen loop builds one per seed.

**Both runs of the oracle must receive the SAME argv**, or every program
becomes a false nondeterminism finding. This is the single easiest way
to break the oracle and must be tested explicitly.

### A2. What to generate, weighted

The generator knows what flags it declared, so it knows what a valid
invocation looks like. Weighted so that most programs are given
something sane and a minority are given something hostile:

| Shape | Weight | Why |
|---|---|---|
| valid flag with a valid value (`-l text`, `--retries 42`) | high | the common path, and the one that has never run |
| boolean flag present (`-v`) | high | presence semantics |
| long form vs short form | even split | two code paths, one schema |
| flag with a value of the WRONG type (`-r notanumber`) | medium | raises the error flag — verified 0.4.7 behaviour |
| flag with a value that overflows i64 | medium | #35's fix reaches this path; keep it exercised |
| flag with its value MISSING at end of argv (`-l`) | medium | leaves the flag empty, does not raise |
| unknown flag (`-z`) | medium | falls through to positionals, consumes nothing |
| extra positional arguments | medium | `arguments's all` / `raw` have only ever seen the empty case |
| duplicate flag (`-r 1 -r 2`) | low | last-wins? undocumented — find out, then assert |
| flag-looking positional (`--`, `-`) | low | boundary |

### A3. The part that makes this more than coverage

**The generator knows what it passed.** So a generated program can
assert: `If label is not "expected" then, Exit 91.` That is the deferred
output-oracle problem *already solved* in one corner — argv is the one
input channel where the expected value is known at generation time.

Use it. A distinct exit code per failed assertion turns a silent wrong
answer into a detectable one, without any reference implementation.
This is the single highest-value item in this plan.

## Part B — stdin

### B1. The harness must give the child a real stdin (defect 7)

**This is the prerequisite and it is not optional.** `supervise`
currently gives the child no stdio redirection, so it inherits the
fuzzer's own stdin. A generated `/dev/stdin` read therefore BLOCKS until
the deadline and is classified `hang` — a false finding on every program
carrying one. Proved: with `< /dev/null` the read returns 0 bytes and
exits 0; with an open-but-silent pipe it blocks until killed.

The child's stdin must be redirected from a per-run input file before
`Execute`. Nothing in Part B may be emitted until this is in place, and
the T1 guard should fail the build on a generated stdin read until then.

### B2. Seeded random bytes

Per seed, the harness writes an input file and points the child's stdin
at it. Content is seeded and recorded, because **a finding is only
reproducible if `repro.sh` can recreate the input as well as the
program** — extend the finding directory with the input bytes and the
seed ledger row with the input seed.

Worth generating: empty input; a few bytes; more bytes than the
program's buffer (the truncation path); embedded NULs; invalid UTF-8;
very long single lines; no trailing newline.

### B3. What the generator emits

Randomly injected, not on every program:

- `open a file for reading called h at "/dev/stdin"` and at fd `0` —
  LANGUAGE.md documents both spellings and they are different code paths
- `Read from h into <buffer>` into buffers of varying declared size,
  including one smaller than the input
- reading twice (second read at EOF)
- `h's size`, `h's readable` — the file-property surface, where #37 and
  #38 already live
- reading into a buffer that is then used: appended to, printed,
  compared

### B4. Do not write to /dev/stdout

Recorded because it has already bitten: a generated program writing to
`/dev/stdout` gets its own file offset, so when the harness's stdout is
a redirected file the child writes at offset 0 while the parent writes
further on, leaving a sparse hole that reads back as NUL bytes. It
turned a golden fixture binary. Write targets belong in the per-run
scratch directory.

## Ordering

1. **B1 first** — the stdio plumbing. It is the prerequisite for
   everything in Part B, and it is the same change argv needs, so do
   both channels' plumbing together.
2. **A1 + A2** — argv, weighted. Immediately valuable, and lower risk
   than stdin because there is no blocking failure mode.
3. **A3** — the self-checking assertions. The highest-value item, but it
   depends on A2 existing.
4. **B2 + B3** — stdin bytes and the reads that consume them.

## Acceptance

- **The oracle still reports zero false positives** across 300 seeds
  with argv and stdin both varying. Both of a program's two runs must
  get identical argv and identical stdin; if they do not, every program
  becomes a finding. Test this deliberately.
- Determinism per seed: same seed produces the same program, the same
  argv, and the same input bytes.
- A campaign of 300+ seeds: every program compiles and runs, zero
  findings. A new emitter that immediately "finds" bugs is far likelier
  to be emitting illegal Vox or an illegal invocation.
- A finding's directory contains the program, the argv, and the input
  bytes — and `repro.sh` replays all three.
- The self-checking assertions of A3 are shown to work by planting a
  deliberate mismatch and observing the distinct exit code.
