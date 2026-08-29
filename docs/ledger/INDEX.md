# Ledger index — every section of LANGUAGE.md, and where its ledger stands

Manual version pinned here: **Vox 0.4.15** (`../vox/LANGUAGE.md`, 5882
lines, vox commit **unknown — pre-merge stack, GitHub #239**), re-pinned
2026-08-29 (previously `4995394`, 5756 lines, 0.4.14). **This pin is
PROVISIONAL**: it points at the unmerged `wt-stack-0415` working tree
(fixes #104, #109, #110, #111, #112, plus the completed Keywords
chapter — GitHub #239), not a commit on vox `main`. `docs/ledger/
PINNED-MANUAL`'s `commit` field must be updated to the real merge
commit (and `quality-stats.json`'s `voxCommit`) once the vox PRs land —
see `RUNBOOK-0.4.15-signing-vox-fuzz.md`. 0.4.15 added: a buffer's bytes
as a loop-expansion collection and an "Iterating bytes" paragraph
(#104); quoted single-word names for functions/parameters/things,
resolving inside a `{...}` format slot (#110); `Free` on a list actually
releases it (#109); nested list/map elements copy instead of sharing
(#111); fall-off-the-end returns a real empty value for every declared
type (#112); the Keywords chapter's Statement Starters (+14 rows) and
Connectors (+8 rows) tables, four brand-new tables (Types, Operators,
Reserved Nouns and Properties, File/Buffer/List/Time Properties), and
the Reserved Aliases table losing its `auto`/`enable`/`disable` rows;
`int`/`integer` documented as accepted spellings of `number`. 37
citations changed text (not just position) and needed hand resolution
(`scripts/repin-citations --to <this manual> --apply --pin`: 3588
checked, 3375 shifted, 0 moved, 37 changed, 10 pre-existing REVIEW
rows); see each affected ledger's own "2026-08-29" notes. When the manual
moves, re-pin the line ranges in this table first
(`scripts/repin-citations --to <new manual> --apply --pin`) and note
the delta in each affected ledger's header; row IDs never move.

How to read the counts: `rows` is claims enumerated; `exercised` counts
every row with a leaf **in main** that emits the construct, and
`verified` is the subset of those whose leaf also asserts the documented
result, so `verified` never exceeds `exercised` (see PROCEDURE.md §3);
`invariants` is unjustified invariants the section's leaves still
contribute to the corpus report (blank until a campaign has been run
against the section). Progress is `verified / rows` going up and
`invariants` going down — nothing else.

| prefix | ledger | LANGUAGE.md lines | section | mapped | rows | exercised | verified | open discrepancies | invariants |
|---|---|---|---|---|---|---|---|---|---|
| BAS | `basics.md` | 38–291 | Basics: statements, case, comments, paragraph breaks, sentence consumption, the termination rule, closing more than one level | **yes** | 61 | 15 | 0 | 3 (D1 period not required, closes `If` but not `While`; D2 blank line doesn't end an `if` chain across an `Otherwise`; D3 unterminated comment swallows the rest of the file) | |
| BAS2 | `expansion.md` | 292–475 | Basics: ranges, loop expansion, `but if`, `treating` | **yes** | 62 | 18 | 0 | 1 open, 3 resolved: **D1 RESOLVED** (works now, #54/#55 side effect); **D3 RESOLVED** (vox #55); **D4 RESOLVED**; D2 open (a trailing `otherwise` displaces the base action) | |
| TYP | `types.md` | 476–495 | Types | **yes** | 12 | 1 | 0 | 1 (D1: `number` silently holds fractional values; `is a` predicate disagrees with `'s type` — re-verified still open against 0.4.9) | |
| VAR | `variables.md` | 496–714 | Variables: declaration forms, set/create, canonical forms, assignment, type immutability, naming rules | **yes** | 66 | 17 | 0 | 8 open, 1 resolved: **D1 RESOLVED** (vox #54, list-element read segfault); D2 still open (rebinding not type-checked, symptom changed by #54's side effect); D3 `Allocate N for X` zeroes buffer capacity; D4 reserved keywords accepted as loop vars; D5 single-quoted `see`/`version`; D6 diagnostic caret by text search; D7 undocumented 3rd canonical form; D8 `timer` supports only 1 of 2 forms; D9 leading underscore | |
| NAM | `names-and-strings.md` | 715–731 | Names and strings | **yes** | 7 | 0 | 0 | 0 open — **D1 RESOLVED, vox #65** (initial-declaration form's type-check gap; `a number called n is "get five".` used to print a garbage pointer, now a compile error) | |
| FUN | `functions.md` | 732–927 | Functions: definition, scope, parameter/local types, calls, calling as statement, reading a result | **yes** | 51 | 14 | 0 | 7 open, 2 resolved: **D7/D8 RESOLVED, vox #53** (`Return a buffer` from a text literal — silent empty buffer / segfault); D1 forward global read (candidate **#66**, in flight); D5 float/map direct-print (candidate **#67**, in flight); D2 map-param size/length routed to file-size code; D3 timer param `'s elapsed` compile error; D4 file param readable/writable always false; D6 file return can't be received via `a file called X is <call>.`; D9 diagnostic caret placement | |
| THG | `things-a.md` | 928–1311 | Things: defining, declarations and field access, nesting, value copy semantics | **yes** | 76 | 25 | 6 | 5 (D1 `time` field vs. variable init contradiction; D2 abbreviated transcripts read as verbatim; D3 caret on declaration, not the offending statement; D4 "all three lines" precedes one line; D5 out-of-scope diagnostic hints at a nonexistent `if`) | |
| THG2 | `things-b.md` | 1312–1905 | Things: printing, equality, manifest, the three call forms, one identifier space, top-level only, cross-file, `.lib`, sentence consumption, diagnostics, predicates | **yes** | 77 | 20 | 8 | 4 open, 1 resolved: **D5 RESOLVED** (`--shared` thing-crossing caret now correct); D1 quoted single-word field name loses quotes when printed; D2 "a variable" conflates parameter/loop-var/inferred; D3 caret on declaration, not the comparison; D4 unsupported field type also reported as default-type mismatch | |
| EXP | `expressions.md` | 1906–2197 | Expressions: literals, references, arithmetic, comparisons, property checks, logical operators, plural `are`, type casting | **yes** | 100 | 42 | 0 | 5, all adjudicated compiler-correct, not filed: D1 a call argument binds tighter than arithmetic than the manual's own example assumes; D2 the two error-flag bullets for text-to-number are each wrong in the opposite direction; D3 `comparison` only parses in condition position (shared with GRM D1); D4 a Property Checks example uses the reserved word `list`; D5 parentheses don't group — `{...}` does (shared with GRM D2) | |
| FLW | `control-flow.md` | 2198–2371 | Control flow: if, while, for each, repeat, loop control, termination, increment/decrement | **yes** | 45 | 22 | 4 | 3 (D1 the manual's usage-guard example doesn't guard; D2 `Increment` is a no-op on `float`, a compile error on `text`; D3 the loop variable outlives its loop) | |
| LST | `collections-a.md` | 2372–2694 | Lists and collections: literals, mixed-type, nested, maps, type predicates | **yes** | 82 | 18 | 0 | 2 open, 6 resolved: D1–D4 and D6 **RESOLVED** (manual corrected to match the compiler); D5 **RESOLVED, vox #45** (opaque text silently reinterpreted); D7 variable-form **RESOLVED, vox #44** — expression-form **STILL OPEN** (dup with LST2 D7, candidate **#68**); D8 open (`is equal to` on two collections always answers "not equal") | |
| VAL | `values.md` | 2695–2946 | Dynamic values (`value`) and `nothing` | **yes** | 32 | 15 | 15 | 0 open — **D1 RESOLVED, vox #43** (conditional `value` return used to segfault); **D2 RESOLVED** (manual corrected, no compiler change needed) | |
| LST2 | `collections-b.md` | 2947–3312 | Collections: printing, properties, element access, appending, loop expansion with collections, `but if`, `treating` | **yes** | 96 | 35 | 0 | 3 open, 7 resolved: D3/D4 **RESOLVED, vox #49**; D1, D5, D6, D8, D10 **RESOLVED**; D7 variable-form **RESOLVED, vox #44** — expression-form **STILL OPEN** (candidate **#68**, dup with LST D7); D2 open (`otherwise` rejected after `print`, accepted after `append`); D9 open (`respectively` documented as reserved, usable as an identifier) | |
| FMT | `input-output.md` | 3313–3511 | Input/Output: print, format strings, conditional print | **yes** | 58 | 33 | 0 | 4 open, 1 resolved: D2 **RESOLVED, vox #44** (list-in-format-string raw pointer); D1 open — top severity (`{arguments's first}` into a buffer segfaults); D3 open (text global printed from a function defined earlier renders its pointer); D4 open (`and if` can't open a conditional-print chain); D5 open (diagnostic points at the first textual occurrence, comments included) | |
| BUF | `buffers.md` | 3513–3801 | File I/O: buffers, object properties, buffer properties, resizing, byte access, append/copy | **yes** | 61 | 14 | 8 | 1 open, 3 resolved: D1 dynamic capacity 4096 vs. documented "zero" — **still awaiting Josj**, no fix number exists (design question, checked against `candidates-round-4.md` as of 2026-08-22); D2 **RESOLVED, vox #42 / PR #189** (`type` now correctly reports `Buffer (static)`); D3 **RESOLVED** (manual documented the bounds rule, PR #189); D4 **RESOLVED, vox #109 / 0.4.15** (`Free` on a `list` now empties it and refuses further writes, exactly as LANGUAGE.md:3699–3708 and the Statement Starters table's `Free` row both say) | |
| FIL | `files.md` | 3802–4198 | File I/O: file/list/number properties, opening, reading, seeking, writing, closing, file operations, error handling, resource safety | **yes** | 103 | 36 | 17 | 1 open, 5 resolved: D1 **RESOLVED** (withdrawn — vox #38 closed by removing the `exists` property, manual now documents the `On error`-around-`open` idiom); D3 **RESOLVED, vox #47**; D4/D5 **RESOLVED, vox #48**; D6 **RESOLVED, vox #40**; D2 open (`Read from … into …` replaces the buffer; the manual said "appends" — claim since corrected to match) | |
| PRC | `process-control.md` | 4199–4540 | Directories, mounting, device nodes, symlinks, pivot_root, executing programs, process control, system control | **yes** | 87 | 0 | 0 | 6 (D1 device-node type set larger than documented, extra one needs no privilege; D2 invalid device type is a compile error, manual only documents a runtime flag; D3 non-text `Execute` argument list element fails the exec; D4 `examples/supervisor.vox` isn't the loop the manual prints; D5 `Send signal` passes the pid to `kill(2)` unfiltered; D6 `examples/initramfs.vox` doesn't exercise "all of them") | |
| TIM | `time.md` | 4541–4713 | Time and timers | **yes** | 60 | 12 | 0 | 5 (D1 `end` is not reserved, not an exit keyword, used as a name elsewhere; D2 `duration`/`elapsed` marked "requires cast" and don't; D3 a negative-millisecond wait never returns, the same in seconds returns at once; D4 the section's own reserved aliases aren't in the Reserved Aliases table; D5 time components are UTC, undocumented) | |
| ARG | `arguments.md` | 4714–4883 | Command-line arguments, flag parsing | **yes** | 54 | 19 | 4 | 5 (D1 `arguments's count` isn't "the total number of arguments"; D2 `last` reaches a place `first` refuses to go; D3 `and is required` makes `with default` unreachable and aborts silently; D4 an over-range number flag raises *and* hands back a wrapped value; D5 the one-alias diagnostic states a rule the compiler doesn't enforce) | |
| ENV | `environment.md` | 4884–4958 | Environment variables | **yes** | 12 | 7 | 6 | 0 open — **D1 RESOLVED, vox #58** (a buffer declared directly from an `environment's <property>` expression never received the string's bytes) | |
| OPR | `operators.md` | 4959–5031 | Operators: arithmetic, comparison, logical, bitwise | **yes** | 42 | 17 | 0 | 3 (D1 `isn't`/`aren't` are documented spellings of `not` and don't lex; D2 the Operators section's only worked example doesn't compile; D3 bitwise operators silently return `0.0` for a float operand) | |
| KEY | `keywords.md` | 5033–5341 | Keywords: articles, starters, flag schema, connectors, `and`, reserved aliases, two classes of special word, contextual keywords | **yes** | 88 (was 81 pre-0.4.15; before that recorded as 86 — corrected 2026-08-29, the table has always run KEY-01…KEY-80/81, never 86) | 36 | 0 | 4 open, 4 resolved: D4 **RESOLVED, vox #106, 0.4.14 aliases half + 0.4.15 Statement Starters half**; D5/D6/D7 **RESOLVED, vox #56** (`all the numbers from A to B` bugs — dropped end bound, segfault, wrong-format print); D1 thirteen Statement-Starters words aren't reserved as names; D2 `fork` is declarable and reading it forks the process; D3 `reap` is refused, but not with the documented diagnostic; D8 a missing required flag exits 1 silently — **STILL OPEN, design question for Josj**, no fix number exists | |
| EXA | `examples.md` | 5342–5382 | Examples chapter — each example is a composite claim | **yes** | 5 | 0 | 0 | 0 |  |
| LIB | `libraries.md` | 5383–5774 | Libraries and imports: `see`, shared libraries, `.lib` interface, mangling, `--link` | **yes** | 64 | 5 | 0 | 1 open, 3 resolved: D4 RESOLVED, vox #62 (return-type-checking); D1 RESOLVED 2026-08-22 (manual corrected to document the `.lib` overwrite); D3 RESOLVED 2026-08-22 (manual corrected to `To greet.`); D2 the manual's second retired-syntax example doesn't parse — **still open** | |
| CLI | `compiler-usage.md` | 5775–5815 | Compiler usage — claims about the CLI, tested by the harness rather than by leaves | **yes** | 8 | 2 | 0 | 1 (D1: `--link` hand-verified as a no-op in every case tried — manual reworded 2026-08-22 to scope `--link` to `.lib`-free/foreign linking only, consistent with D1's own reading, but the section's own worked example still pairs it with a `see`-based consumer; still open, awaiting Josj) | |
| GRM | `grammar-summary.md` | 5816–5882 | Grammar summary — each production is a claim that the forms it lists parse | **yes** | 23 | 10 | 0 | 3, none filed: D1/D2 already adjudicated (identical to expressions.md D3/D5, compiler-correct reading — recorded here because the line numbers fall inside this ledger's own range); D3 open (`append_stmt`'s `treating` clause: wrong position in the manual's own grammar, and a silent no-op once moved to where it parses) | |

**Addition, 2026-08-29 (Vox 0.4.14, `4995394`) — mapped the four pieces
of text 0.4.14 added that the `c7dd9eb` re-pin moved lines under but
did not enumerate rows for.** BUF gains 15 rows (BUF-40–54, "Releasing a
Buffer," LANGUAGE.md:3645–3754) and a new discrepancy, **D4**
(`Free` on a `list` compiled but had no observable effect, contradicting
both LANGUAGE.md:3699–3708 and the Statement Starters table's own `Free`
row at 5019) — **RESOLVED 2026-08-29 by vox #109 (0.4.15)**, see
`buffers.md`. FUN gains 1 row (FUN-44, the #105 missing-preposition
diagnostic, LANGUAGE.md:885). FMT gains 1 row (FMT-57, the #108
text-reassignment-releases-its-string sentence, LANGUAGE.md:3443) — and
this pass also caught that FMT's own row count was already one stale
before it started (FMT-56 existed but had never been folded into the
55-row count), so FMT's `rows` here is 57, not 56. KEY gains 1 row
(KEY-81, sampling eight aliases across the now-85-row Reserved Aliases
table) and two `?`-citation corrections (KEY-51/KEY-52, now pinned to
LANGUAGE.md:5252); it also gains a **PARTIALLY RESOLVED** verdict on D4,
and this pass found `keywords.md`'s own row count had been overstated
as 86 for at least one prior refresh — the table has only ever run
KEY-01 through KEY-80 (now 81), never 86; corrected here, not
investigated further (out of scope for this pass). `exercised`/`verified`
columns are unchanged for all four rows — every new row is `todo` or
`not assertable`, since `grep` on `Free \|Release \|Deallocate ` across
`src/gen_*.vox` confirms 0.4.14's `Free` statement has no leaf yet.
`docs/check-probes.sh` (228 probes across the four touched directories)
and `scripts/check-citations.sh docs` both report clean. Full account:
`REPORT-MAP-0414.md`.

**Addition, 2026-08-29 (Vox 0.4.15, GitHub #239, PROVISIONAL pre-merge
pin) — mapped the sentences 0.4.15 adds: #104 (buffer bytes as a loop
collection), #110 (quoted single-word names + the format-slot fix),
#109 (Free on a list), #111 (nested-collection copy semantics), #112
(fall-off-the-end for every type), and the completed Keywords chapter.**
BAS2 gains 3 rows (BAS2-60–62, buffer-bytes loop expansion,
LANGUAGE.md:349–353). BUF gains 7 rows (BUF-55–61: the Free-on-list
sub-claims split out of the rewritten BUF-54, plus the "Iterating
bytes" composite). FUN gains 7 rows (FUN-45/46, quoted-name #110 fixes;
FUN-47–51, the five newly-fixed fall-off-the-end types — `number`/
`float`/`boolean`/`text`/`value` were already correct and are `values.md`
VAL-19's territory, not duplicated). THG gains 1 row (THG-76, quoted
thing-type names) and THG-49's pre-existing (pre-0.4.15) `?` citation is
fixed as a courtesy (master steer, not one of the 37). TYP gains 1 row
(TYP-12, `int`/`integer`). LST gains 12 rows (LST-71–82, the nested-
collection copy-semantics sub-claims and the two worked examples) and
LST-32/53 are **narrowed** while LST-33/34/54 are **withdrawn** — #111
changed what their cited text actually says, not just where it sits;
`collections-a.md`'s Discrepancy 6 is marked moot for the same reason.
KEY gains 7 rows (KEY-82–88: one row per new/changed table, per the
0.4.14 KEY rule, plus the auto/enable/disable un-reservation) and
Discrepancy 4 moves from PARTIALLY RESOLVED to fully **RESOLVED** — every
word it named now has a table entry. FMT gains 1 row (FMT-58, the
format-slot fix itself). `exercised`/`verified` columns are unchanged
for every ledger — every new row is `todo` or `not assertable`; no leaf
in `main` emits any of these constructs yet. `docs/check-probes.sh`
(394 probes across the eight touched directories — buffers, expansion,
functions, things-a, input-output, collections-a, types, keywords)
passes 390/394 against the 0.4.15 stack compiler; the 4 that fail on
purpose (`D6`, `LST-32`, `LST-53`, `LST-54`) are marked HISTORICAL in
their own headers — they record pre-#111 behaviour and still pass
against the installed 0.4.14 compiler, confirming the construct
genuinely changed rather than the probe being wrong.
`scripts/check-citations.sh docs`/`src` both 0 stale. Full account:
`REPORT-fuzz-stack-0415.md`.

**Refresh, 2026-08-22 (vox 0.4.9, `bb406de`, same day as the pass
below) — first real run of `scripts/repin-citations`.** Two docs-only
vox commits (3c6c484 hygiene, 70ca1c2 the Libraries rewrite) moved the
manual from 5327 to 5372 lines after the full hand re-pin below had
already landed. `scripts/repin-citations --to <manual> --apply --pin`
mechanically shifted 205 citations across every ledger and flagged 25
as CHANGED (text under the citation actually edited) plus 5 REVIEW
(non-citation digit cells worth a human glance); all 25 were hand-fixed
by reading the claim and finding it in the new manual, and all 5 REVIEW
cells were confirmed unaffected (identical text at those lines before
and after). Two discrepancies in `libraries.md` were resolved as a
byproduct: **D1** (a repeat `--shared` build silently overwriting a
`.lib`) and **D3** (the `.lib`-format worked example's zero-parameter
entry missing `To`) — the manual was corrected in place to document the
compiler's actual behavior for both, so LIB-30/LIB-31 and both
discrepancy entries were updated to match rather than left describing a
now-fictional bug. `LIB-43` gained a note that the manual now documents
a **seventh** stale-`.lib` diagnostic (reading a no-`, returning`
entry's result) with no row yet. `check-citations.sh` reports `docs/ 0
stale` (`src/ 33`, unchanged from before this pass) and
`scripts/repin-citations --to <manual>` reports 0 CHANGED/REVIEW
afterward. Full account: `vox-notes/REPORT-REPIN-APPLY-1.md`.

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
