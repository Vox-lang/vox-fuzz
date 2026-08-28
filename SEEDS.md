# Seed ledger

What has actually been fuzzed, against which compiler, with which
generator. Public on purpose: a fuzzer's claim to have found nothing is
worth exactly as much as the record of what it looked at.

## A seed is not a program

**A seed only names a program when you also name the generator.**
`src/gen.vox` decides what seed 500 produces; change the generator and
seed 500 becomes a different program entirely. So every row below pins
**both** the vox version under test *and* the vox-fuzz commit that
generated the programs, and **ranges are not comparable across
generator versions**. Seeds 1–1000 run against an older `gen.vox` tell
you nothing about seeds 1–1000 today.

This is not pedantry: `gen.vox` changed substantially on 2026-08-19
(maps, floats, `value`, member functions, mixed lists, chained
expansion, `While`/`Repeat`, `but if`, `treating`, `environment's`).
Every seed record from before that is void as coverage.

## Ledger

| Date | vox | vox-fuzz | Seeds | Budget | Programs | Compiled | Findings | Notes |
|---|---|---|---|---|---|---|---|---|
| 2026-08-19 | 0.4.5 | `c99e734` | 1–1000 | 12 | 1000 | 1000 | 0 | post-modernization baseline |
| 2026-08-19 | 0.4.5 | `c99e734` | 7000–7999 | 16 | 1000 | 1000 | 0 | independent range, master-run |
| 2026-08-19 | 0.4.5 | `f20eb77` | 1–2000 ×4 budgets | 12/40/100/300 | 8000 | n/a | n/a | guard sweep — **generation only**, no compile or run |
| 2026-08-23 | 0.4.11 | `4a8de95` | 41000–41219 | 40 | 220 | 220 | 0 | worker three-tree differential, value band (plain layout) |
| 2026-08-23 | 0.4.11 | `4a8de95` | 77777–77788 | 40 | 12 | 12 | 0 | master keep-run: 15 VAL rows assert, all exit 0 |
| 2026-08-24 | 0.4.12 | `937f12a` | 90000–90999 | 40 | 1000 | ~994 | 6 | value-band celebration; 6 findings, all fuzzer Defects 14/15 (see FUZZER_DEFECTS.md), zero compiler bugs |
| 2026-08-24 | 0.4.12 | `22e5479` | 100000–101999 (8-way stripe, 8×250) | 40 | 2000 | 1977 | 23 | first striped campaign: 19 findings were oversubscription deadline artifacts (8 stripes on 8 cores; scale deadlines or stripe under core count), 4 exposed Defect 16 (pool-name collision, see FUZZER_DEFECTS.md); zero compiler bugs |
| 2026-08-25 | 0.4.13 | `ef9dee2` | 200000–200428, 300000–300429, 400000–400544, 500000–500686 (4 stripes) | 40/40/24/12 | ~2000 | ~2000 | 269 | all 269 "compile exceeded 60 s" findings are artifacts of an OOM-starved box (vox-fuzz at 20/15/10 GB — Defect 17; every one recompiles in ≤ 2.4 s idle); 0 compiler bugs; parked as findings/day-0.4.13-oom-artifacts |
| 2026-08-28 | 0.4.13 | `ef9dee2` | 200429–214999 (stripe-1, chunked ×200) | 40 | 14571 | 14571 | 0 | resumed the 25th's run under a chunked, memory-capped driver (fresh process per chunk, systemd MemoryMax); 73 chunks, 0 failed |
| 2026-08-28 | 0.4.13 | `ef9dee2` | 300430–314999 (stripe-2, chunked ×200) | 40 | 14570 | 14570 | 0 | as stripe-1 |
| 2026-08-28 | 0.4.13 | `ef9dee2` | 400545–408944 (stripe-3, chunked ×300; 402945–408944 after a Josj-directed pause) | 24 | 8100 | 8100 | 0 | chunked, memory-capped driver; the compiler under test was rebuilt to 0.4.14 by the release at 21:19, so seeds from 408945 on belong to the next row |
| 2026-08-28 | 0.4.14 | `ef9dee2` | 408945– (stripe-3 continued on the 0.4.14 binary) | 24 | (running) | | 0 so far | row closes with the campaign |
| 2026-08-28 | 0.4.13 | `ef9dee2` | 500687–509186 (stripe-4, chunked ×500; 503187–509186 after the pause) | 12 | 8000 | 8000 | 0 | as stripe-3; seeds from 509187 (chunk started 21:20) ran on 0.4.14 |
| 2026-08-28 | 0.4.14 | `ef9dee2` | 509187– (stripe-4 continued on the 0.4.14 binary) | 12 | (running) | | 0 so far | row closes with the campaign |

`n/a` in Compiled/Findings marks a generation-only sweep: the
never-emitted guard scans source text and deliberately does not compile,
so it contributes no execution coverage.

## The gap this file exists to expose

**CI has been running `--seed 1 --count 100` on every push since the
smoke-fuzz landed.** Generation is deterministic, so that job has
re-tested the *same hundred programs* every time and has never once
reached a hundred and first. It is a regression check wearing a
fuzzer's clothes: it will catch a regression that breaks one of those
hundred, and nothing else.

The same habit crept into manual runs — `--seed 1 --count 1000`, over
and over, re-walking ground already walked and calling it coverage.

**Intended fix** (not yet applied): CI derives its starting seed from
something that moves — the run number, the commit, the date — so every
push explores new ground, and appends the range it burned to this
ledger. Until that lands, treat the CI row as a regression gate rather
than as coverage.

## Adding a row

Record a run here when it is a *campaign* run — a deliberate sweep
whose result you would cite. Do not record every incidental invocation.
State the vox version (`vox --version`), the vox-fuzz commit
(`git rev-parse --short HEAD`), the exact seed range, the budget, and
the outcome. **If a run found something, say so and link the finding**;
a ledger that only ever records zeros is the same failure this project
spent 2026-08-19 fixing.
