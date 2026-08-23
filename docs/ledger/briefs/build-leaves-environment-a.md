# Brief: build leaves for the Environment ledger — batch A (the properties, the lookup, the `exists` predicate)

You are the WORKER. Work in THIS worktree on the branch you are on
(`feat/ledger-environment-a`). Do NOT spawn agents. Do NOT commit and do
NOT push — stop and report; the master signs.

## Rule one — Josj's standing order, 2026-08-21, verbatim
> Make everything random unless there is a rule to say otherwise. When in
> doubt, just make it random. We can spot and fix errors later — rather
> that than have a useless fuzzer.

Read first, in this order:
1. `CLAUDE.md` — the generation standard.
2. `docs/ledger/PROCEDURE.md` §6 (leaf-building) and §4 (the probe format
   you will reuse for your hand-verification).
3. The ledger **rows only**: `docs/ledger/environment.md`, the table, and
   the probes in `docs/ledger/probes/environment/`. **Do not read the
   ledger's `## Discrepancies` section until your leaves are built and
   campaign-tested** — a leaf is built from the manual's claim, not from
   anyone's notes about what the compiler gets wrong; you compare against
   that section afterwards and report what your leaves did and did not
   find on their own.
4. `../vox/LANGUAGE.md` lines 4672–4746 (the section itself), plus the
   buffer and text declaration forms the section leans on (`a text called
   X is <expr>.`, `a buffer called X is <expr>.` — Variables 446–644,
   File I/O buffers 3139–3324), and `../vox/docs/STYLE.md`.
5. The existing leaves: `'gen leaf environment inrange'` / `'gen leaf
   environment oob'` in `src/gen_misc.vox` (~82–130) and their
   registration in `src/gen_core.vox` (~545–560, and the `'gen any leaf'`
   pool at ~652). The inrange leaf already reads `count`, `empty`, and a
   named variable — but asserts nothing. Your job is partly to replace
   that leaf with ones that do.

Environment for every compile:
```
export VOX=/home/josj/scr/english/vox/target/release/vox
export VOX_CORE_PATH=/home/josj/scr/english/vox/coreasm
ulimit -c 0
make build && ./test.sh
```
The exit-95 ledger-assertion hook is in `src/loop_gen.vox` (PR #46): a
generated program prints `ASSERT ENV-NN: expected <x> got <y>` then
`Exit 95.`, and the runner files a `wrong-value` finding carrying that
line. Nothing generated may exit 90–99 for any other reason.

## Your rows (all in `src/gen_misc.vox`; register new kinds in `src/gen_core.vox`'s dispatch and the `'gen any leaf'` pool)

| row | claim (LANGUAGE.md) | what to emit and ASSERT |
|---|---|---|
| ENV-02 + ENV-05 | `environment's count` is the total number of variables (4477–4479); `environment's empty` is true iff there are none (4482) | read both on the same process and assert they agree: `count is 0` exactly when `empty` is true. Use both spellings the manual gives for reading a property into a variable and for printing it directly; vary which you assert from (a declared name vs the property inline). |
| ENV-03 + ENV-04 | `first` / `last` are the first/last variable as the full `"NAME=value"` string (4480–4481) | read each; assert the documented shape — it contains an `=` — using only constructs the manual gives (a byte scan of a buffer, or the text/`contains` forms if the manual has them — cite what you use); and assert the two reads of the same property agree with each other (read `first` twice into two differently-typed receivers and compare). On an empty environment the claim has no first/last; the generator runs under the harness's environment, which is never empty — but do not hard-code that: branch on `empty` and assert only on the populated side. |
| ENV-06 (+ ENV-07, ENV-09 folded) | `environment's "NAME"` is the value of the named variable (4483); worked example reads `HOME`/`USER`/`SHELL` (4485–4494) | The generator does not control the child's environment today (there is an argv oracle `gen_argv` in `gen_misc.vox:7–25`; there is no env companion — say so in the report as a harness gap, do not build it here). So the oracle is **consistency**: the same name read into *each* receiving type the manual allows for a text value (`text`, `buffer`, `value` — check which declaration forms accept a text-valued expression, cite the lines) must agree with itself — same `length`/`size`, same bytes where the manual gives you a way to compare, same `empty`-ness. Choose names at random from a list the generator holds (the manual's own `HOME`/`USER`/`SHELL`/`PATH` and others likely to be set), AND names guaranteed unset (the `VOXFUZZ_UNSET_<random>` convention the oob leaf already uses) — and for those assert whatever the manual documents as the unset result (find it; if the manual is silent, exercise only and say so). |
| ENV-10 | `If the environment variable "NAME" exists then,` is a predicate, true iff set (4512–4517) | emit the predicate against a likely-set name and a guaranteed-unset name; assert the branch taken agrees with a by-name read's emptiness where the manual lets you compare (a name that `exists` with an empty value is legal — so compare `exists` against `count`/a second `exists`, and only use the read where the manual defines the unset result). Both branches of the `If`, with `otherwise`, chosen at random. |
| ENV-11 | the "Complete Example" composite (4519–4540) | reproduce the example's *shape* — not its literal text — once: an `arguments's` count check, an `exists`-and-lookup fallback, a plain lookup; every name and string drawn at random; assert entry-wise using the rows above. |

NOT yours: ENV-01 (framing), ENV-08 (folded), ENV-12 (binary size — not
observable from inside Vox).

## Rules that make the leaves worth having
- **Assert.** Every row above asserts something the manual states.
  Expected values the generator knows are printed in the ASSERT line.
- **Vary everything no rule pins** — and write the rule's line at each
  place you keep something fixed. Which property; which receiving type;
  how many reads; the order of reads; the names (real words, quoted
  multi-word names included — never `e1`, `env1`; draw from a vocabulary
  list ≥ 24 entries); whether the read sits at top level or inside a
  block; whether other statements sit between declaration and use; which
  of the manual's synonyms (`size`/`length`) you compare with.
- **Doc comment names the rows**: `(ENV-02, ENV-05: count and empty agree)`.
  `grep ENV-06 src/` must find your leaf.
- **Hand-verify**: `./build/vox-fuzz gen --seed 1 --count 30 --budget 14
  --layout plain --out vf_scratch/out --keep vf_scratch/corpus`; read five
  programs; compile and run two by hand; then deliberately break one
  assertion in the generator, rebuild, and confirm the run produces a
  `wrong-value` finding with your ASSERT line; restore it.
- `./test.sh` stays green; add `tests/NNN_gen_environment_a.vox`
  (+ `.expected`) exercising each new leaf deterministically (see
  `tests/280_gen_buffers_a.vox` for the shape).
- **Reach**: after registering, a 300-seed **plain-layout** campaign must
  contain each new construct (`grep -l "environment's" vf_scratch/corpus/*
  | wc -l`), and `./build/invariants vf_scratch/corpus` must show NO new
  100%-presence row from your leaves (paste the rows that mention
  `environment`, with a citation or a fix for each).

## Out of scope
Other rows; other `src/gen_*.vox` files except the registration in
`gen_core.vox`; the harness (an env oracle is a later, separate task);
anything in `../vox`. If a claim turns out wrong when you probe it, do NOT
encode your reading — write the repro into your report under
"Discrepancies found by the leaves" and leave the assertion out of that
row (keep the construct as exercised).

## Report
For each row: leaf name, what it emits, the assertion text, its
citation. Seeds you hand-checked and the break-one-assertion proof. The
campaign line, the finding count, and — THEN — read the ledger's
`## Discrepancies` and say which of them your leaves found unaided, which
they could not have found and why. A worker's diary: every place the
procedure or this brief made you stop, and every helper you wanted and
did not have. Do not commit.
