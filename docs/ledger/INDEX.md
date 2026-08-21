# Ledger index — every section of LANGUAGE.md, and where its ledger stands

Manual version pinned here: **Vox 0.4.8** (`../vox/LANGUAGE.md`, 5112
lines). When the manual moves, re-pin the line ranges in this table first
and note the delta in each affected ledger's header; row IDs never move.

How to read the counts: `rows` is claims enumerated; `exercised` and
`verified` are rows with a leaf **in main** (see PROCEDURE.md §3);
`invariants` is unjustified invariants the section's leaves still
contribute to the corpus report (blank until a campaign has been run
against the section). Progress is `verified / rows` going up and
`invariants` going down — nothing else.

| prefix | ledger | LANGUAGE.md lines | section | mapped | rows | exercised | verified | open discrepancies | invariants |
|---|---|---|---|---|---|---|---|---|---|
| BAS | `basics-sentences.md` | 35–259 | Basics: statements, case, comments, paragraph breaks, sentence consumption, the termination rule, closing more than one level | **yes** | 65 | — | 0 |  |  |
| BAS2 | `basics-expansion.md` | 260–427 | Basics: ranges, loop expansion, `but if`, `treating` | **yes** | 59 | — | 0 |  |  |
| TYP | `types.md` | 428–445 | Types | no | | | | | |
| VAR | `variables.md` | 446–644 | Variables: declaration forms, set/create, canonical forms, assignment, type immutability, naming rules | **yes** | 66 | — | 0 | 9 (D1=#54 segfault fix in flight; reserved-word-as-loopvar; canonical-forms; Allocate-on-buffer) |  |
| NAM | `names-and-strings.md` | 645–670 | Names and strings | no | | | | | |
| FUN | `functions.md` | 671–786 | Functions: definition, scope, parameter/local types, calls, calling as statement | **yes** | 43 | — | 0 | 9 (D8=#53 segfault fix in flight; D1/D5 pointer-render dup #45; scope) |  |
| THG | `things-a.md` | 787–1167 | Things: defining, declarations and field access, nesting, value copy semantics | **yes** | 75 | — | 0 | 5 (things-a discrepancies; time field/var init, diagnostics) |  |
| THG2 | `things-b.md` | 1168–1788 | Things: printing, equality, manifest, the three call forms, one identifier space, top-level only, cross-file, `.lib`, sentence consumption, diagnostics, predicates | **yes** | 77 | — | 0 | 5 (things-b) |  |
| EXP | `expressions.md` | 1789–2025 | Expressions: literals, references, arithmetic, comparisons, property checks, logical operators, plural `are`, type casting | **yes** | 100 | — | 0 |  |  |
| FLW | `control-flow.md` | 2026–2193 | Control flow: if, while, for each, repeat, loop control, termination, increment/decrement | **yes** | 45 | — | 0 |  |  |
| LST | `collections-a.md` | 2194–2435 | Lists and collections: literals, mixed-type, nested, maps, type predicates | **yes** | 70 | — | 0 | 8 adjudicated: D1–D4,D6 manual; D5 manual + untyped-return defect; D7 compiler bug (`{list}` outside Print); D8 design decision (equality) | |
| VAL | `values.md` | 2436–2659 | Dynamic values (`value`) and `nothing` | **yes** | 31 | 1 | 0 | 1 open (D2 manual analogy to an unimplemented cast). **D1 RESOLVED — fixed by vox #43 in 0.4.8**; probes refreshed 2026-08-21 | |
| LST2 | `collections-b.md` | 2660–2994 | Collections: printing, properties, element access, appending, loop expansion with collections, `but if`, `treating` | **yes** | 96 | — | 0 | 10: **D2 (#50), D3+D4 (#49) RESOLVED in 0.4.8**; D7=#44 dup, D1/D5/D6/D8 manual, D9 `respectively` (Josj), **D10 new 2026-08-21** — the #49 diagnostic's caret can land in a comment | |
| FMT | `input-output.md` | 2995–3138 | Input/Output: print, format strings, conditional print | **yes** | 55 | — | 0 | 5 (D1=#52 fixed; D2/D3/D5 dup #44/#45/#46; D4 and-if chain) |  |
| BUF | `buffers.md` | 3139–3324 | File I/O: buffers, object properties, buffer properties, resizing, byte access, append/copy | **yes** | 39 | 6 | 0 | 3 (lawyer: D1 manual, D2 compiler, D3 doc gap — awaiting Josj) | |
| FIL | `files.md` | 3325–3657 | File I/O: file/list/number properties, opening, reading, seeking, writing, closing, file operations, error handling, resource safety | **yes** | 101 | — | 0 | 6: **D3 (#47), D4+D5 (#48), D6 (#40) RESOLVED in 0.4.8**; D1=#38 (Josj) and D2 (manual) still open. Probes refreshed 2026-08-21 | |
| PRC | `process-control.md` | 3658–3999 | Directories, mounting, device nodes, symlinks, pivot_root, executing programs, process control, system control | **yes** | 87 | — | 0 | 6 (doc-precision + Send-signal kill-safety note) |  |
| TIM | `time-and-timers.md` | 4000–4172 | Time and timers | **yes** | 60 | — | 0 |  |  |
| ARG | `arguments.md` | 4173–4342 | Command-line arguments, flag parsing | **yes** | 54 | — | 0 |  |  |
| ENV | `environment.md` | 4343–4417 | Environment variables | no | | | | | |
| OPR | `operators.md` | 4418–4482 | Operators: arithmetic, comparison, logical, bitwise | **yes** | 42 | — | 0 |  |  |
| KEY | `keywords.md` | 4483–4621 | Keywords: articles, starters, flag schema, connectors, `and`, reserved aliases, two classes of special word, contextual keywords | **yes** | 86 | — | 0 |  |  |
| EXA | `examples.md` | 4622–4662 | Examples chapter — each example is a composite claim | no | | | | | |
| LIB | `libraries.md` | 4663–5009 | Libraries and imports: `see`, shared libraries | no | | | | | |
| CLI | `compiler-usage.md` | 5010–5047 | Compiler usage — claims about the CLI, tested by the harness rather than by leaves | no | | | | | |
| GRM | `grammar-summary.md` | 5048–5112 | Grammar summary — each production is a claim that the forms it lists parse | no | | | | | |

**Refresh, 2026-08-21 (vox 0.4.8 + #40/#43/#47/#48/#49/#50/#52).** Seven
discrepancies across four ledgers were fixed in the compiler and their
probes re-recorded to the new truth: values D1, collections-b D2/D3/D4,
files D3/D4/D5/D6, input-output D1. `docs/check-probes.sh` is green across
every ledger (338 probes). Note that **this table is still pinned to manual
0.4.7** while `values.md`'s `value` section and `files.md`'s seeking rules
both moved in 0.4.8 — the re-pin is still owed, and `process-control.md`
(mapped against 0.4.8) says the same about its own range.

## Order of work

Memory safety first, then the surfaces where a wrong answer hides, then
the rest: **BUF → FIL → VAL → LST/LST2 → THG/THG2 → PRC → BAS/BAS2 → FLW
→ EXP → FMT → ARG → ENV → TIM → FUN → VAR → OPR → KEY → LIB → NAM → TYP →
EXA → GRM → CLI**. Two mapping workers at a time is the practical ceiling
while the master reviews each map before any leaf is built.

## Existing coverage to build on (do not re-map what already works)

Lists, maps, things, grid expansion, flags, format strings, timers, base
conversion, deep expressions, loop control, error handling, arguments,
environment, argv assertions, stdin, file I/O all have leaves and are
campaign-clean — but as the buffer ledger found, **almost none of them
assert**. Expect most rows in those sections to land as `exercised`
straight away and the work to be adding the assertion.
