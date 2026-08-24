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
| 2026-08-24 | 0.4.12 | `937f12a` | 90000–90806 (stopped early; rest unrun) | 40 | ~807 | ~801 | 6 | value-band celebration; 6 findings, all fuzzer Defects 14/15 (see FUZZER_DEFECTS.md), zero compiler bugs |

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
