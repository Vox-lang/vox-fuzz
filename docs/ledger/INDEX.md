# Ledger index — every section of LANGUAGE.md, and where its ledger stands

Manual version pinned here: **Vox 0.4.7** (`../vox/LANGUAGE.md`, 5112
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
| BAS | `basics-sentences.md` | 35–259 | Basics: statements, case, comments, paragraph breaks, sentence consumption, the termination rule, closing more than one level | no | | | | | |
| BAS2 | `basics-expansion.md` | 260–427 | Basics: ranges, loop expansion, `but if`, `treating` | no | | | | | |
| TYP | `types.md` | 428–445 | Types | no | | | | | |
| VAR | `variables.md` | 446–644 | Variables: declaration forms, set/create, canonical forms, assignment, type immutability, naming rules | no | | | | | |
| NAM | `names-and-strings.md` | 645–670 | Names and strings | no | | | | | |
| FUN | `functions.md` | 671–786 | Functions: definition, scope, parameter/local types, calls, calling as statement | no | | | | | |
| THG | `things-a.md` | 787–1167 | Things: defining, declarations and field access, nesting, value copy semantics | no | | | | | |
| THG2 | `things-b.md` | 1168–1788 | Things: printing, equality, manifest, the three call forms, one identifier space, top-level only, cross-file, `.lib`, sentence consumption, diagnostics, predicates | no | | | | | |
| EXP | `expressions.md` | 1789–2025 | Expressions: literals, references, arithmetic, comparisons, property checks, logical operators, plural `are`, type casting | no | | | | | |
| FLW | `control-flow.md` | 2026–2193 | Control flow: if, while, for each, repeat, loop control, termination, increment/decrement | no | | | | | |
| LST | `collections-a.md` | 2194–2435 | Lists and collections: literals, mixed-type, nested, maps, type predicates | no | | | | | |
| VAL | `values.md` | 2436–2659 | Dynamic values (`value`) and `nothing` | **yes** | 31 | 1 | 0 | 2 (D1 conditional value return SEGFAULTS — lawyer running; D2 manual analogy to an unimplemented cast) | |
| LST2 | `collections-b.md` | 2660–2994 | Collections: printing, properties, element access, appending, loop expansion with collections, `but if`, `treating` | no | | | | | |
| FMT | `input-output.md` | 2995–3138 | Input/Output: print, format strings, conditional print | no | | | | | |
| BUF | `buffers.md` | 3139–3324 | File I/O: buffers, object properties, buffer properties, resizing, byte access, append/copy | **yes** | 39 | 6 | 0 | 3 (lawyer: D1 manual, D2 compiler, D3 doc gap — awaiting Josj) | |
| FIL | `files.md` | 3325–3657 | File I/O: file properties, opening, reading, seeking, writing, closing, file operations, error handling, resource safety | no | | | | | |
| PRC | `process-control.md` | 3658–3999 | Directories, mounting, device nodes, symlinks, pivot_root, executing programs, process control, system control | no | | | | | |
| TIM | `time-and-timers.md` | 4000–4172 | Time and timers | no | | | | | |
| ARG | `arguments.md` | 4173–4342 | Command-line arguments, flag parsing | no | | | | | |
| ENV | `environment.md` | 4343–4417 | Environment variables | no | | | | | |
| OPR | `operators.md` | 4418–4482 | Operators: arithmetic, comparison, logical, bitwise | no | | | | | |
| KEY | `keywords.md` | 4483–4621 | Keywords: articles, starters, flag schema, connectors, `and`, reserved aliases, two classes of special word, contextual keywords | no | | | | | |
| EXA | `examples.md` | 4622–4662 | Examples chapter — each example is a composite claim | no | | | | | |
| LIB | `libraries.md` | 4663–5009 | Libraries and imports: `see`, shared libraries | no | | | | | |
| CLI | `compiler-usage.md` | 5010–5047 | Compiler usage — claims about the CLI, tested by the harness rather than by leaves | no | | | | | |
| GRM | `grammar-summary.md` | 5048–5112 | Grammar summary — each production is a claim that the forms it lists parse | no | | | | | |

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
