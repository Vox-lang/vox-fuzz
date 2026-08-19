# Plan 323 — total coverage: everything in the language, fuzzed

**Status:** approved by TheJostler, 2026-08-19 — *"EVERYTHING in the
language should be fuzzed."*
**Follows:** plan 322, which closed the red team's six formalized
findings. This plan closes the **rest** of that report's coverage sweep,
and then goes past it: the target is no longer a list of gaps someone
noticed, but **LANGUAGE.md's own inventory of constructs**.

## The goal, stated so it can be checked

> Every construct in LANGUAGE.md is either **fuzzed**, or **explicitly
> excluded here with a reason**. No third category. A construct that is
> neither is a hole, and holes are what plan 322 taught us cost the most
> — the fuzzer reported "all clear" for months on a check it was never
> performing.

## FIRST — the constructs that must NEVER be emitted

**This section governs everything below it, and it is not a style
preference.** Vox reached Milestone 4: it can shut down the machine,
mount and unmount filesystems, create device nodes, and replace the root
filesystem. A generator told to "emit everything" will, given enough
seeds, emit `poweroff`. The fuzzer runs on Josj's workstation, and the
3am cron already owns the only legitimate shutdown
(`/tmp/poweroff_lock`).

**Tier NEVER — must not appear in a generated program, at any budget,
under any seed:**

| Construct | LANGUAGE.md | Why not |
|---|---|---|
| `shutdown`/`poweroff`, `reboot`/`restart`, `halt` | §System Control | turns off the host mid-run |
| `Mount`/`unmount`/`umount` | §Mounting Filesystems | corrupts or detaches real filesystems |
| `pivot_root` / switching the root filesystem | §Switching the Root | unrecoverable on a live machine |
| device-node creation | §Device Nodes | writes into `/dev` |
| `Create/Remove a directory` at an unconstrained path | §Directories | deletes real data |
| `Execute` of anything but a known-harmless binary | §Executing Programs | arbitrary program execution |
| `Send signal` to any pid the program did not fork | §Process Control | kills unrelated processes, including the fuzzer |

**How the exclusion is enforced, and it must be both:**
1. The generator never emits them (obvious, insufficient — a bug in the
   generator is exactly what we are hunting).
2. **A guard test asserts it.** `tests/2xx_never_emitted.vox` generates
   a large seed sweep and greps every produced source for the banned
   vocabulary, failing loudly on a hit. This is the real safeguard: it
   survives someone later "improving" the generator.

**Tier CONFINE — safe only inside a sandbox the harness controls:**

| Construct | Confinement required |
|---|---|
| file I/O (open/read/write/append/close) | paths under a per-run scratch dir, created and swept by the harness; never absolute, never `..` |
| directory create/remove | same scratch dir only |
| `fork` / `reap` / `the reaped status` | child must be the program's own; bounded count |
| `Execute` | only `/bin/true`-equivalents — and note test 020 was already made hermetic because `/bin/true` is absent in the Nix sandbox, so use a shell builtin |
| `Send signal` | only to a pid this program forked |
| `Wait` / `Sleep` | bounded well under the per-program deadline, or hangs become indistinguishable from real ones |

**Tier FUZZ — no constraint beyond legality:** everything else.

## Current coverage — audited 2026-08-19 against main

Generated programs today declare **number, float, text, list, map,
buffer, value** and exercise: arithmetic (`add`/`minus`/`multiply`/
`times`/`divide`), buffer byte read/write including deliberate OOB, list
literal/append/element including OOB, mixed-type lists, map create/read/
write/length/key-iteration, `value` round-trip, thing fields and member
functions, function calls, `On error` handlers, `For each` loops, `If`,
chained loop expansion, text declarations with interpolation, `Exit`.

**Still dark — every one grep-confirmed absent from `src/gen.vox`:**

| Gap | Tier | Why it matters |
|---|---|---|
| **`but if` chains** | FUZZ | bugs #3 and #14 were both `but if` |
| **`treating ... as`** | FUZZ | per-clause substitution, interacts with expansion |
| **environment access** (`environment's`) | FUZZ | bug #24 was exactly this, and #26 its positional siblings |
| **`While` / `Repeat` loops** | FUZZ | only `For each` is emitted today |
| **file I/O in generated programs** | CONFINE | the whole §File I/O surface |
| **`fork`/`Execute`/`reap`/signals** | CONFINE | shipped 0.4.0, never once fuzzed |
| **times / timers** | CONFINE | `Wait` needs a bound |
| **`.lib` shared libraries** | FUZZ (build-time) | bug #18 was `.lib` element-type inference |
| **`arguments's`** | FUZZ | bugs #23 and #26 lived here |
| **nested/deep expressions, operator matrix** | FUZZ | coverage is shallow, not absent |

Note the pattern, which is the argument for this plan: **almost every
dark construct has already produced a compiler bug.** #3, #14, #18, #23,
#24, #26 all sit in areas the fuzzer cannot currently reach.

## Tasks

**T1 — the guard first.** `tests/2xx_never_emitted.vox` and the banned
vocabulary list, before any new emission lands. Nothing else in this
plan may merge ahead of it.

**T2 — the harness scratch sandbox.** A per-run directory the generated
program is confined to, created and swept by the harness, with the path
handed to the program. Prerequisite for every CONFINE construct.

**T3 — FUZZ-tier constructs** (no confinement needed): `but if` chains,
`treating ... as`, `While`, `Repeat`, `environment's`, `arguments's`,
deeper expression nesting and the full operator matrix.

**T4 — CONFINE-tier: file I/O**, inside T2's sandbox.

**T5 — CONFINE-tier: process control** — `fork`, `reap`, `the reaped
status`, `Execute` of a harmless builtin, `Send signal` to own child.

**T6 — timers and `Wait`**, bounded.

**T7 — `.lib`**: generate a library and a consumer, compile both, run
the consumer.

**T8 — the coverage ledger.** A checked-in document mapping every
LANGUAGE.md section to *fuzzed / excluded-with-reason*, and a test that
fails when LANGUAGE.md grows a section the ledger does not mention. This
is what stops the hole reopening silently — the same reasoning as T1.

## Acceptance, for every task

- The construct appears in a seeded generated program (dump it).
- `./test.sh` green.
- **1,000 seeds, zero findings** — a new emitter that immediately
  "finds" bugs is far likelier to be emitting illegal Vox. Any genuine
  finding is reported with its seed, never tuned away.
- The T1 guard still passes.
- Determinism intact: same seed, identical source.
