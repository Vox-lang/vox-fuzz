# Brief: build leaves for {LEDGER} rows {ROWS}

You are the WORKER. Work in THIS worktree on the branch you are on. Do
NOT spawn agents. Do NOT commit and do NOT push — stop and report.

Read `CLAUDE.md`, `docs/ledger/PROCEDURE.md` §6, and
`docs/ledger/{SLUG}.md`. Your rows are **{ROWS}** (at most eight). The
section's probes in `docs/ledger/probes/{SLUG}/` show, for each row, a
program that the compiler has actually run and what it printed — start
from them.

## Where the code goes

Leaves for this section live in **`src/gen_{SURFACE}.vox`** and nowhere
else. Register each new leaf in the dispatch (`'gen dispatch leaf'` /
`'gen any leaf'` in `src/gen_core.vox`) so it can actually be drawn; a
leaf that is never drawn covers nothing. Add a `tests/NNN_*.vox` +
`.expected` unit for every leaf (see existing `tests/040_gen.vox` for the
shape), and keep `./test.sh` green (`VOX=… VOX_CORE_PATH=… ./test.sh`).

## Rule one — Josj's standing order, 2026-08-21, verbatim
> Make everything random unless there is a rule to say otherwise. When in
> doubt, just make it random. We can spot and fix errors later — rather
> that than have a useless fuzzer.

Read `PROCEDURE.md` §6a before the first line of generator code: it is
the list of places this work has already bitten a builder (a `text` has
no size property; one period closes one level; assert agreement when the
generator does not control the input; reuse the assert helpers and the
name allocator; register through the surface's existing kind; measure
sameness on `--layout plain`; never print a raw host value; probe the
rendered line, not the idea).

## The rules that make a leaf worth having

1. **Every assertable row asserts.** The generator chose the inputs, so
   it knows the answer: emit the check. On failure the generated program
   prints one line `ASSERT {PREFIX}-NN: expected <x> got <y>` and then
   `Exit 95.` (95 is reserved for ledger assertions; 91–94 are argv's;
   nothing else generated may exit 90–99). {ASSERT_HOOK_NOTE}
2. **Vary everything no rule pins.** Counts, names, sizes, which synonym
   (`resize`/`reallocate`/`grow`/`shrink`), whether an optional form
   appears, ordering relative to other statements. A leaf that always
   emits the same count or the same name is asserting a rule nobody
   wrote. Cite LANGUAGE.md in a comment for any sameness you keep.
3. **The doc comment names the rows**: `(BUF-15, BUF-16: resize spellings
   and data preservation)` — `grep BUF-15 src/` must find your leaf.
4. **Hand-verify the emitted programs.** Before trusting a test, generate a
   handful (`./build/vox-fuzz gen --seed 1 --count 20 --keep vf_scratch/c`),
   read them, compile and run two by hand. Then break one assertion on
   purpose and confirm it becomes a `wrong-value` finding.
5. **Read aloud.** Generated programs are held to `vox/docs/STYLE.md` as
   strictly as the generator is: names are the thing's true name; no
   `i`, `tmp`, `buf`, `b1`. Use quoted multi-word names freely.
6. **Legal but not sensible.** Out-of-range indices, resize to zero then
   read, append past a fixed capacity, clear then read — all legal Vox,
   all must not crash, all wanted. Arithmetic leaves are nearly worthless.

## Out of scope

Other ledgers' rows; other `src/gen_*.vox` files except the dispatch
registration; the harness; anything in `../vox`. If a row's claim turns
out wrong when you probe it, do NOT encode your reading — add it to the
ledger's Discrepancies section with a repro and leave the row `todo`.

## Report

List each row with what you emitted and whether it asserts; the test
you added; the seeds you hand-checked; anything you could not do and why.
