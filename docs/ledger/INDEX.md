# Ledger index — every section of LANGUAGE.md, and where its ledger stands

Manual version pinned here: **Vox 0.4.9** (`../vox/LANGUAGE.md`, 5327
lines, vox `4b77934`), confirmed 2026-08-22. When the manual moves,
re-pin the line ranges in this table first and note the delta in each
affected ledger's header; row IDs never move.

How to read the counts: `rows` is claims enumerated; `exercised` and
`verified` are rows with a leaf **in main** (see PROCEDURE.md §3);
`invariants` is unjustified invariants the section's leaves still
contribute to the corpus report (blank until a campaign has been run
against the section). Progress is `verified / rows` going up and
`invariants` going down — nothing else.

| prefix | ledger | LANGUAGE.md lines | section | mapped | rows | exercised | verified | open discrepancies | invariants |
|---|---|---|---|---|---|---|---|---|---|
| BAS | `basics.md` | 35–259 | Basics: statements, case, comments, paragraph breaks, sentence consumption, the termination rule, closing more than one level | **yes** | 61 | 15 | 0 | 3 (D1 period not required, closes `If` but not `While`; D2 blank line doesn't end an `if` chain across an `Otherwise`; D3 unterminated comment swallows the rest of the file) | |
| BAS2 | `expansion.md` | 260–427 | Basics: ranges, loop expansion, `but if`, `treating` | **yes** | 59 | 18 | 0 | 1 open, 3 resolved: **D1 RESOLVED** (works now, #54/#55 side effect); **D3 RESOLVED** (vox #55); **D4 RESOLVED**; D2 open (a trailing `otherwise` displaces the base action) | |
| TYP | `types.md` | 428–445 | Types | **yes** | 11 | 1 | 0 | 1 (D1: `number` silently holds fractional values; `is a` predicate disagrees with `'s type` — re-verified still open against 0.4.9) | |
| VAR | `variables.md` | 446–644 | Variables: declaration forms, set/create, canonical forms, assignment, type immutability, naming rules | **yes** | 66 | 17 | 0 | 8 open, 1 resolved: **D1 RESOLVED** (vox #54, list-element read segfault); D2 still open (rebinding not type-checked, symptom changed by #54's side effect); D3 `Allocate N for X` zeroes buffer capacity; D4 reserved keywords accepted as loop vars; D5 single-quoted `see`/`version`; D6 diagnostic caret by text search; D7 undocumented 3rd canonical form; D8 `timer` supports only 1 of 2 forms; D9 leading underscore | |
| NAM | `names-and-strings.md` | 645–670 | Names and strings | **yes** | 7 | 0 | 0 | 0 open — **D1 RESOLVED, vox #65** (initial-declaration form's type-check gap; `a number called n is "get five".` used to print a garbage pointer, now a compile error) | |
| FUN | `functions.md` | 671–813 | Functions: definition, scope, parameter/local types, calls, calling as statement, reading a result | **yes** | 43 | 14 | 0 | 7 open, 2 resolved: **D7/D8 RESOLVED, vox #53** (`Return a buffer` from a text literal — silent empty buffer / segfault); D1 forward global read (candidate **#66**, in flight); D5 float/map direct-print (candidate **#67**, in flight); D2 map-param size/length routed to file-size code; D3 timer param `'s elapsed` compile error; D4 file param readable/writable always false; D6 file return can't be received via `a file called X is <call>.`; D9 diagnostic caret placement | |
| THG | `things-a.md` | 814–1194 | Things: defining, declarations and field access, nesting, value copy semantics | **yes** | 75 | 19 | 0 | 5 (D1 `time` field vs. variable init contradiction; D2 abbreviated transcripts read as verbatim; D3 caret on declaration, not the offending statement; D4 "all three lines" precedes one line; D5 out-of-scope diagnostic hints at a nonexistent `if`) | |
| THG2 | `things-b.md` | 1195–1815 | Things: printing, equality, manifest, the three call forms, one identifier space, top-level only, cross-file, `.lib`, sentence consumption, diagnostics, predicates | **yes** | 77 | 11 | 0 | 4 open, 1 resolved: **D5 RESOLVED** (`--shared` thing-crossing caret now correct); D1 quoted single-word field name loses quotes when printed; D2 "a variable" conflates parameter/loop-var/inferred; D3 caret on declaration, not the comparison; D4 unsupported field type also reported as default-type mismatch | |
| EXP | `expressions.md` | 1816–2072 | Expressions: literals, references, arithmetic, comparisons, property checks, logical operators, plural `are`, type casting | **yes** | 100 | 42 | 0 | 5, all adjudicated compiler-correct, not filed: D1 a call argument binds tighter than arithmetic than the manual's own example assumes; D2 the two error-flag bullets for text-to-number are each wrong in the opposite direction; D3 `comparison` only parses in condition position (shared with GRM D1); D4 a Property Checks example uses the reserved word `list`; D5 parentheses don't group — `{...}` does (shared with GRM D2) | |
| FLW | `control-flow.md` | 2073–2240 | Control flow: if, while, for each, repeat, loop control, termination, increment/decrement | **yes** | 45 | 17 | 0 | 3 (D1 the manual's usage-guard example doesn't guard; D2 `Increment` is a no-op on `float`, a compile error on `text`; D3 the loop variable outlives its loop) | |
| LST | `collections-a.md` | 2241–2540 | Lists and collections: literals, mixed-type, nested, maps, type predicates | **yes** | 70 | 18 | 0 | 2 open, 6 resolved: D1–D4 and D6 **RESOLVED** (manual corrected to match the compiler); D5 **RESOLVED, vox #45** (opaque text silently reinterpreted); D7 variable-form **RESOLVED, vox #44** — expression-form **STILL OPEN** (dup with LST2 D7, candidate **#68**); D8 open (`is equal to` on two collections always answers "not equal") | |
| VAL | `values.md` | 2541–2790 | Dynamic values (`value`) and `nothing` | **yes** | 32 | 1 | 0 | 0 open — **D1 RESOLVED, vox #43** (conditional `value` return used to segfault); **D2 RESOLVED** (manual corrected, no compiler change needed) | |
| LST2 | `collections-b.md` | 2791–3127 | Collections: printing, properties, element access, appending, loop expansion with collections, `but if`, `treating` | **yes** | 96 | 35 | 0 | 3 open, 7 resolved: D3/D4 **RESOLVED, vox #49**; D1, D5, D6, D8, D10 **RESOLVED**; D7 variable-form **RESOLVED, vox #44** — expression-form **STILL OPEN** (candidate **#68**, dup with LST D7); D2 open (`otherwise` rejected after `print`, accepted after `append`); D9 open (`respectively` documented as reserved, usable as an identifier) | |
| FMT | `input-output.md` | 3128–3283 | Input/Output: print, format strings, conditional print | **yes** | 55 | 33 | 0 | 4 open, 1 resolved: D2 **RESOLVED, vox #44** (list-in-format-string raw pointer); D1 open — top severity (`{arguments's first}` into a buffer segfaults); D3 open (text global printed from a function defined earlier renders its pointer); D4 open (`and if` can't open a conditional-print chain); D5 open (diagnostic points at the first textual occurrence, comments included) | |
| BUF | `buffers.md` | 3285–3480 | File I/O: buffers, object properties, buffer properties, resizing, byte access, append/copy | **yes** | 39 | 6 | 0 | 1 open, 2 resolved: D1 dynamic capacity 4096 vs. documented "zero" — **still awaiting Josj**, no fix number exists (design question, checked against `candidates-round-4.md` as of 2026-08-22); D2 **RESOLVED, vox #42 / PR #189** (`type` now correctly reports `Buffer (static)`); D3 **RESOLVED** (manual documented the bounds rule, PR #189) | |
| FIL | `files.md` | 3481–3872 | File I/O: file/list/number properties, opening, reading, seeking, writing, closing, file operations, error handling, resource safety | **yes** | 103 | 20 | 0 | 1 open, 5 resolved: D1 **RESOLVED** (withdrawn — vox #38 closed by removing the `exists` property, manual now documents the `On error`-around-`open` idiom); D3 **RESOLVED, vox #47**; D4/D5 **RESOLVED, vox #48**; D6 **RESOLVED, vox #40**; D2 open (`Read from … into …` replaces the buffer; the manual said "appends" — claim since corrected to match) | |
| PRC | `process-control.md` | 3873–4214 | Directories, mounting, device nodes, symlinks, pivot_root, executing programs, process control, system control | **yes** | 87 | 0 | 0 | 6 (D1 device-node type set larger than documented, extra one needs no privilege; D2 invalid device type is a compile error, manual only documents a runtime flag; D3 non-text `Execute` argument list element fails the exec; D4 `examples/supervisor.vox` isn't the loop the manual prints; D5 `Send signal` passes the pid to `kill(2)` unfiltered; D6 `examples/initramfs.vox` doesn't exercise "all of them") | |
| TIM | `time.md` | 4215–4387 | Time and timers | **yes** | 60 | 12 | 0 | 5 (D1 `end` is not reserved, not an exit keyword, used as a name elsewhere; D2 `duration`/`elapsed` marked "requires cast" and don't; D3 a negative-millisecond wait never returns, the same in seconds returns at once; D4 the section's own reserved aliases aren't in the Reserved Aliases table; D5 time components are UTC, undocumented) | |
| ARG | `arguments.md` | 4388–4557 | Command-line arguments, flag parsing | **yes** | 54 | 15 | 4 | 5 (D1 `arguments's count` isn't "the total number of arguments"; D2 `last` reaches a place `first` refuses to go; D3 `and is required` makes `with default` unreachable and aborts silently; D4 an over-range number flag raises *and* hands back a wrapped value; D5 the one-alias diagnostic states a rule the compiler doesn't enforce) | |
| ENV | `environment.md` | 4558–4632 | Environment variables | **yes** | 12 | 1 | 6 | 0 open — **D1 RESOLVED, vox #58** (a buffer declared directly from an `environment's <property>` expression never received the string's bytes) | |
| OPR | `operators.md` | 4633–4696 | Operators: arithmetic, comparison, logical, bitwise | **yes** | 42 | 17 | 0 | 3 (D1 `isn't`/`aren't` are documented spellings of `not` and don't lex; D2 the Operators section's only worked example doesn't compile; D3 bitwise operators silently return `0.0` for a float operand) | |
| KEY | `keywords.md` | 4698–4836 | Keywords: articles, starters, flag schema, connectors, `and`, reserved aliases, two classes of special word, contextual keywords | **yes** | 86 | 36 | 0 | 5 open, 3 resolved: D5/D6/D7 **RESOLVED, vox #56** (`all the numbers from A to B` bugs — dropped end bound, segfault, wrong-format print); D1 thirteen Statement-Starters words aren't reserved as names; D2 `fork` is declarable and reading it forks the process; D3 `reap` is refused, but not with the documented diagnostic; D4 the chapter's tables under-enumerate reserved words and aliases; D8 a missing required flag exits 1 silently — **STILL OPEN, design question for Josj**, no fix number exists | |
| EXA | `examples.md` | 4837–4877 | Examples chapter — each example is a composite claim | **yes** | 5 | 0 | 0 | 0 |  |
| LIB | `libraries.md` | 4878–5224 | Libraries and imports: `see`, shared libraries, `.lib` interface, mangling, `--link` | **yes** | 64 | 5 | 0 | 3 open, 1 resolved: D4 **RESOLVED, vox #62** (a `.lib` entry with no `, returning` clause is now type-checked as "returns nothing" at the call site); D1 a repeat `--shared` build silently overwrites an existing `.lib`; D2 the manual's second retired-syntax example doesn't parse; D3 the `.lib` worked example's zero-parameter entry omits `To` | |
| CLI | `compiler-usage.md` | 5225–5262 | Compiler usage — claims about the CLI, tested by the harness rather than by leaves | **yes** | 8 | 2 | 0 | 1 (D1: `--link` hand-verified as a no-op in every case tried — re-verified against 0.4.9, still open, awaiting Josj) | |
| GRM | `grammar-summary.md` | 5263–5327 | Grammar summary — each production is a claim that the forms it lists parse | **yes** | 23 | 10 | 0 | 3, none filed: D1/D2 already adjudicated (identical to expressions.md D3/D5, compiler-correct reading — recorded here because the line numbers fall inside this ledger's own range); D3 open (`append_stmt`'s `treating` clause: wrong position in the manual's own grammar, and a silent no-op once moved to where it parses) | |

**Refresh, 2026-08-22 (vox 0.4.9, `4b77934`) — full re-pin, all 26
ledgers.** Every `LANGUAGE.md:N` citation across all 26 ledgers (1378
rows at the start of this pass, 1380 now — `values.md` gained VAL-32 and
`files.md`'s net is +1 after adding FIL-102/FIL-103 and withdrawing
FIL-08) was re-derived by hand against the 0.4.9 manual (5327
lines, up from 0.4.8's 5238) — not by a fixed-offset script, though a
*verified* uniform per-section offset (checked at multiple anchors
before applying it) was used to move faster in a handful of
end-of-manual sections that share one clean **+87** shift:
`libraries.md`, `examples.md`, `grammar-summary.md`, and (with the
Options-table caveat below) `compiler-usage.md`. Retained discrepancy
probes were re-run against the live 0.4.9 binary; **11 more
discrepancies resolved since the 2026-08-21 refresh** (on top of that
refresh's own 7): `names-and-strings.md` D1 (vox #65), `functions.md`
D7/D8 (vox #53) and row FUN-41 (vox #45, same fix as `collections-a.md`
LST-18/19), `libraries.md` D4 (vox #62), `keywords.md` D5/D6/D7 (vox
#56), `environment.md` D1 (vox #58), `collections-b.md` D10, `buffers.md`
D2/D3 (vox #42/PR #189). `docs/check-probes.sh` and the new
`scripts/check-citations.sh docs` both report clean across every ledger
after the pass (see `docs/ledger/PROCEDURE.md` for what each checks).

Two things worth flagging for future re-pins, both found only by
cross-checking every `## ` section boundary end-to-end rather than
trusting each ledger's own stated range in isolation:
- **`functions.md`'s stated end boundary (786) was already wrong**,
  independent of any version drift — `## Things` opens at 814, not
  immediately after 786, leaving 27 real lines (the back half of
  "Reading a result") outside the stated range even though several rows
  already address that content with imprecise `*(gap)*` citations.
  Fixed to 671–813; re-deriving FUN-40 through FUN-43's exact line
  numbers is a follow-up, not done in this pass.
- **`compiler-usage.md`'s Options-table row citations (CLI-02 through
  CLI-08) were also already wrong** at the commit the ledger claimed to
  pin (`b26f66e`) — off by 2–3 lines each, for reasons unrelated to the
  0.4.8→0.4.9 bump. Re-derived directly from the current table rather
  than shifted from the old numbers.

Both errors were invisible to `scripts/check-citations.sh` (both old
line numbers landed on real, just wrong, content) — a reminder that the
tool is a mechanical-sanity floor, not a substitute for reading the
cited text.

**Refresh, 2026-08-21 (vox 0.4.8 + #40/#43/#47/#48/#49/#50/#52).** Seven
discrepancies across four ledgers were fixed in the compiler and their
probes re-recorded to the new truth: values D1, collections-b D2/D3/D4,
files D3/D4/D5/D6, input-output D1. `docs/check-probes.sh` is green across
every ledger (338 probes).

## Order of work

The original mapping pass went memory safety first, then the surfaces
where a wrong answer hides, then the rest: **BUF → FIL → VAL → LST/LST2
→ THG/THG2 → PRC → BAS/BAS2 → FLW → EXP → FMT → ARG → ENV → TIM → FUN →
VAR → OPR → KEY → LIB → NAM → TYP → EXA → GRM → CLI**. All 26 sections
are now mapped; the order above is retained as a record of how the work
was sequenced, not as a remaining to-do list. For the next full re-pin
(the next manual version bump), work section-by-section in `LANGUAGE.md`
order — end-to-end boundary cross-checking is what caught this pass's
two real errors, and that only works reading forward through the whole
manual once, not ledger-by-ledger in priority order.

## Existing coverage to build on (do not re-map what already works)

Lists, maps, things, grid expansion, flags, format strings, timers, base
conversion, deep expressions, loop control, error handling, arguments,
environment, argv assertions, stdin, file I/O all have leaves and are
campaign-clean — but as the buffer ledger found, **almost none of them
assert**. Expect most rows in those sections to land as `exercised`
straight away and the work to be adding the assertion. `verified` is
still 10/1378 rows project-wide (arguments 4, environment 6) — closing
that gap, not finding more discrepancies, is where the next phase of
work should go.
