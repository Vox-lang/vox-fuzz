# Claim ledger: Basics — statements, case, comments, paragraph breaks, sentence consumption, the termination rule

Source: `../vox/LANGUAGE.md` lines **35–259**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), confirmed 2026-08-22 (previously
pinned to a 5611-line 0.4.10 manual): the whole of `## Basics` from `###
Statements` down to the end of `#### This is how you choose which if an
Otherwise belongs to`, stopping immediately before `### Ranges` at line
260. Row prefix **`BAS`**.

**Zero line drift in this range between 0.4.8 and 0.4.9** — `### Ranges`
is still exactly line 260, so every citation below needed no shift; the
few that were stale (landing on a code fence) were pre-existing
imprecisions from the original mapping pass, fixed in this pass. The
full `docs/check-probes.sh` sweep of this directory (47 probes,
including all discrepancy repros) reproduces every recorded output
byte-for-byte on vox 0.4.9 — no manual or compiler change found.

The brief that commissioned this map named the section **"Variables"**.
That is a slip in the brief: lines 35–259 of the 0.4.8 manual are
**Basics**, exactly as `INDEX.md` already records for the `BAS` prefix
(Variables is `VAR`, lines 446–644). The line range is right and the
prefix is right, so this maps what is really there. See the Report for
the other two brief/index mismatches.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
what already emits the construct — checked by reading the generator's own
emission path and by grepping a 40-program corpus, never by leaf name —
or `none`. `status` follows PROCEDURE.md §3.

**This section is different from every ledger so far, and the difference
changes what "a leaf" means.** Buffers and values are about *values*: a
leaf emits an operation and asserts the number it gets back. Basics is
about *program shape* — which statement belongs to which clause. The
oracle is therefore not a returned value but an **execution count**: the
generator knows how many times each statement it emitted should run, so
it can emit a counter and check it (`If ticks is not 3 then, Exit 95.`).
Every row whose `assertable?` cell says "yes" says so on that basis, and
names the counter check it would emit.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` pinned
to the sibling `coreasm`) before being written. Three discrepancies came
out of it, all with minimal repros; one of them (D1) contradicts the very
first sentence of the section.

Every `existing leaf` claim about what generated programs *contain* was
measured, not guessed, against a 40-program corpus reproduced with:

```
make build VOX=/home/josj/scr/english/vox/target/release/vox
./build/vox-fuzz gen --seed 7001 --count 40 --keep <corpus> \
    --vox /home/josj/scr/english/vox/target/release/vox \
    --core /home/josj/scr/english/vox/coreasm
```

The headline measurement from it: **the corpus contains zero `(` and zero
`)` characters — not one parenthesis in forty programs**, so no comment,
and no string literal that would test BAS-14 either.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/basics/`, one file per row named `BAS-NN.vox`. A probe
covering more than one row is named for the first and says so in its
header. Each file opens with a `(...)` comment naming the claim, the
`Ran:` command, and an `expected output:` block recording what the
compiler actually printed.

Rows with no probe file, and why:

| row | why no probe |
|---|---|
| BAS-04, BAS-05 | the `Print`/`print`/`PRINT` and `If`/`if`/`IF` cases are all inside `BAS-03.vox` |
| BAS-08 | the manual's comment block is `BAS-07.vox` |
| BAS-20, BAS-23 | both are observed in `BAS-21.vox` (BAS-23 is a compile-time warning, quoted in that probe's header since compiler stderr is not part of the recorded runtime output) |
| BAS-26, BAS-32, BAS-33 | all three are the same sentence shape as `BAS-25.vox` |
| BAS-36, BAS-37 | both are what `BAS-35.vox` demonstrates |
| BAS-40 | the stacked periods in `BAS-39.vox` are the claim |
| BAS-47 | the stacked periods in `BAS-48.vox` are the claim |
| BAS-54 | the empty `Otherwise,.` in `BAS-55.vox` is the claim |

That is **44 `BAS-NN.vox` probe files** plus **`D1.vox`, `D2.vox`,
`D3.vox`** — 47 files, plus `fixtures/lines.txt` for BAS-38. All 47 were
re-run in one final pass with `docs/check-probes.sh
docs/ledger/probes/basics`: **47 passed, 0 failed, 0 skipped.** The four
probes whose recorded outcome is an exit status (BAS-21 exit 0, BAS-30
exit 1, BAS-45 exit 124, BAS-49 exit 0) were additionally run by hand and
their stdout checked, because this worktree's `check-probes.sh` compares
only the status for those.

`BAS-38.vox` reads `fixtures/lines.txt` by a repo-root-relative path, so
it must be run from the repository root — which is what `check-probes.sh`
does.

## The table

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| BAS-01 | 42 | Every statement ends with a period (`.`). | emit statements whose terminator varies — period, and (per D1) the period omitted — and assert the following statement ran the number of times its position implies | yes, but only as an execution count: `If ticks is not 1 then, Exit 95.` after a statement that must run once. The period itself is not observable; what it *does* is. | `'gen line piece'` (src/gen_core.vox:217) is the single emission point for every generated statement, and it appends `.` or `,` unconditionally — so every statement in every program is period-terminated, and the missing-period case is never generated | exercised (period form only; the terminator never varies) | |
| BAS-02 | 44–46 | The Statements example `Print "Hello, World!".` compiles and prints `Hello, World!`. | a single top-level `Print` of a literal, asserted | yes — the generator wrote the literal, so it knows the expected line | `gen leaf print` (src/gen_core.vox:318) emits top-level `Print`s of generated expressions | exercised (never asserted — the leaf prints for a human to read) | |
| BAS-03 | 50 | Keywords are **case-insensitive**. | draw each keyword's casing at random per emission and assert the program still behaves identically | yes — casing cannot change behaviour, so any existing per-leaf assertion doubles as the check; the leaf asserts what it already asserts, with the keyword randomly cased | **none** — no leaf draws a casing. Every keyword's case is hardcoded in the leaf that writes it (`Print` 1415×, `print` 75× across a 40-program corpus, and never the same statement shape in two casings). Grep for `upper`/`lower` in `src/gen_*.vox` finds no casing logic at all. | todo — a whole documented degree of freedom the generator never uses | |
| BAS-04 | 51 | `Print`, `print`, `PRINT` are equivalent. | folded into BAS-03 | yes (same mechanism) | none | todo | |
| BAS-05 | 52 | `If`, `if`, `IF` are equivalent. | folded into BAS-03 | yes (same mechanism) | none | todo | |
| BAS-06 | 50 (undocumented precision) | *(gap)* Only **keywords** are case-insensitive. **Identifiers are case-sensitive** — `COUNTER` does not resolve to `counter`, and the compiler reports `Unknown identifier`. | not a leaf need — a generated program must compile, so it must never mis-case an identifier | no — the claim is a **compile error**, outside the generator's "legal Vox that should compile and run" contract | n/a (correctly, by construction: names are generated once and reused verbatim) | not assertable (compile-error claim) — hand-verified, `BAS-06.vox` | |
| BAS-07 | 56 | Comments use **parentheses** `( )`. | emit comments into generated programs at random positions and assert the program behaves exactly as it would without them | yes — a comment must not change anything, so every assertion the surrounding leaf already emits is the oracle | **none. Not one comment is emitted into any generated program** — 0 comment lines across 40 programs, and no `"(` literal anywhere in `src/gen_*.vox`. The manual gives comments a whole subsection and the generator has never written one. | todo — the largest single gap in this section | |
| BAS-08 | 58–71 | The Comments example block compiles and runs (`Hello`, `World`, `5`, `done`). | reproduce the block | yes | none | todo — hand-verified, `BAS-07.vox` | |
| BAS-09 | 74 | A comment can appear on its own line. | emit a standalone `(...)` line between two statements | yes (BAS-07's mechanism) | none | todo — hand-verified, `BAS-09.vox` | |
| BAS-10 | 75 | A comment can appear at the end of a statement. | append `(...)` after a statement's period | yes | none | todo — hand-verified, `BAS-10.vox` | |
| BAS-11 | 76 | A comment can appear in the **middle** of a statement, between tokens. | splice `(...)` between two tokens of a declaration, an expression, and an `If` condition | yes | none | todo — hand-verified, `BAS-11.vox` (all three positions) | |
| BAS-12 | 77 | A comment can span multiple lines. | emit a `(...)` spanning two or more physical lines between statements | yes — and it is worth doing precisely because the spanned lines are **not** paragraph breaks (BAS-24) | none | todo — hand-verified, `BAS-12.vox` | |
| BAS-13 | 70 | Nested parentheses inside a comment are supported. | emit a comment with random nesting depth | yes | none | todo — hand-verified to six levels, `BAS-13.vox` | |
| BAS-14 | 56 (undocumented precision) | *(gap)* Parentheses inside a **string literal** are ordinary text, not a comment. | a `Print` of a literal containing balanced parentheses, asserting the parentheses survive | yes — the generator wrote the literal | **none** — no generated string literal contains a parenthesis (every literal is `"wordN"`, `"tagN"`, `"-a"`, a format string, or a digit run) | todo — hand-verified, `BAS-14.vox` | |
| BAS-15 | 56 (undocumented precision) | *(gap)* An **unterminated** comment silently swallows the rest of the file: no error, no warning, exit 0, only the statements before the stray open-paren run. | not a leaf need — a generated program must never emit one | no — generating this would emit a program that silently does nothing, which is indistinguishable from a real "no output" finding | n/a | not assertable — hand-verified, `BAS-15.vox`; **see Discrepancy 3** | |
| BAS-16 | 81 | Blank lines are optional and have no effect between two fully-terminated top-level constructs. | vary the number of blank lines (0, 1, several) between top-level statements and assert unchanged behaviour | yes — blank lines between closed constructs cannot change anything, so the leaf's existing assertions are the oracle | **partial** — blank lines are emitted, but only in the prelude, only after a `To`/`A thing called` definition, and always exactly one. The top-level statement stream never contains a blank line and never contains two. | todo (the varying part) | |
| BAS-17 | 83 | Inside an **open clause** a blank line is not cosmetic: it force-closes every clause still open, including an enclosing function definition. | emit a nested block, close it with a blank line, and assert the statement after the blank line ran once rather than once per iteration | yes — `If ticks is not 1 then, Exit 95.` | **none** — no leaf ever puts a blank line inside an open clause; `'gen join lines'` (src/gen_core.vox:224) closes every block with a period on its last action instead | todo — hand-verified, `BAS-17.vox` | |
| BAS-18 | 85–89 | The Paragraph Breaks example prints `Section 1` then `Section 2`. | reproduce | yes | `gen leaf print` emits the shape; the blank line between two top-level prints is never emitted | todo — hand-verified, `BAS-18.vox` | |
| BAS-19 | 91 | A function definition is closed by a **blank line**, and this is *required*, not a style convention. | emit `To … / body / blank line / call`, assert the call ran | yes — `If ticks is not 1 then, Exit 95.` | `'gen emit prelude functions'` (src/gen_core.vox:843–860) and `'gen emit prelude grid sinks'` (src/gen_flow.vox:503) close every definition with `\n\n` | **exercised** — every program relies on it; nothing asserts it | |
| BAS-20 | 91 | A period closes only the innermost open clause, so the period ending a body statement does **not** close the function. | folded into BAS-21's shape | yes — same counter | none (the generator only ever writes the closing blank line, so the contrast is never emitted) | todo — hand-verified inside `BAS-21.vox` | |
| BAS-21 | 91 | Without a blank line after the body, every following statement is absorbed into the function body; the program then silently does nothing — exit 0, no output. | not a leaf need — this is the shape a generated program must never have | **no** — a generated program that silently does nothing is exactly what a "no output" finding looks like; emitting it deliberately would poison the runner's triage | n/a | not assertable (must-not-generate) — hand-verified, `BAS-21.vox` | |
| BAS-22 | 91 | A following `To` or `Library` does begin a new top-level construct and so ends an open function body. | emit two adjacent `To` definitions with no blank line between them and assert both are callable | yes — call both, assert both ran | **none** — every definition the prelude emits is followed by a blank line, so the `To`-ends-`To` path is never taken. `Library` never appears in a generated program at all. | todo — hand-verified for both `To` and `Library`, `BAS-22.vox` | |
| BAS-23 | 91 | The compiler warns when a function definition is still open at end of file. | not a leaf need (compile-time diagnostic) | no — a warning is compiler stderr, not program behaviour; the fuzzer's oracle is the compiled program | n/a | not assertable — hand-verified; warning text recorded in `BAS-21.vox`'s header | |
| BAS-24 | 79–83 (undocumented precision) | *(gap)* "Blank line" means whitespace: a line of nothing but **spaces** is a paragraph break and closes a definition; a **comment-only** line is not and does not. | if comments are ever emitted (BAS-07), never emit one where a paragraph break is meant; and vary blank lines between empty and whitespace-only | yes — the same counter as BAS-19 | none (neither form is emitted) | todo — hand-verified, `BAS-24.vox` | |
| BAS-25 | 95 | Action-consuming constructs (loops, conditionals, error handlers) consume the **entire sentence** they appear in. | emit a multi-action construct and assert each action ran once per iteration and the statement after the period ran once | yes — two counters: `If inside is not 3 then, Exit 95.` and `If after is not 1 then, Exit 95.` | `'gen line piece'` (src/gen_core.vox:217) builds exactly this shape for every nested leaf: every body line but the last ends `,`, the last ends `.`. `gen leaf loop break while`, `gen leaf loop continue while`, `gen leaf butif append`, `gen leaf while`, `gen leaf repeat` all emit multi-action sentences. | **exercised** (heavily) — no leaf asserts the placement | |
| BAS-26 | 95 | Multiple actions within that sentence are separated by **commas**. | folded into BAS-25 | yes | `'gen line piece'` — the `,` branch | exercised | |
| BAS-27 | 99 | `While x is less than 10, increment x.` | reproduce | yes — assert the final counter value | `gen leaf while` (src/gen_flow.vox:268) emits exactly this shape | exercised — hand-verified, `BAS-27.vox` | |
| BAS-28 | 102 | `While x is less than 10, print x, increment x.` | reproduce | yes — the generator knows the iteration count and every printed value | `gen leaf while`, `gen leaf loop break while` | exercised — hand-verified, `BAS-28.vox` | |
| BAS-29 | 105 | `For each number from 1 to 10, print the number, print " ".` | reproduce | yes | `gen loop` (src/gen_flow.vox:460) plus `gen body` emit `For each number from 1 to N,` with comma-chained actions | exercised — hand-verified, `BAS-29.vox` (note: `print` adds its own newline, so the manual's separator lands on its own line) | |
| BAS-30 | 108 | `On error print "Something went wrong", exit 1.` | reproduce: a failing operation, then a two-action handler | yes — the generator chose the out-of-range index, so it knows the handler must fire; assert by exiting with a distinct code from the handler | `gen leaf buffer oob`, `gen leaf list oob`, `gen leaf map oob`, `gen leaf environment oob` all emit `On error print "…".` — but every one is **single-action**; no leaf emits a comma-chained handler | todo (multi-action handler); exercised (single-action) — hand-verified, `BAS-30.vox` | |
| BAS-31 | 111 | `If … then, print "big", set y to 1. Otherwise, print "small", set y to 0.` — both branches take multiple comma-separated actions. | reproduce, asserting the assigned variable in both directions | yes — the generator picks the condition, so it knows which branch fires | `gen leaf rich condition` (src/gen_core.vox:484) emits `If … then, Print … . Otherwise, Print … .` — **one action per branch**; the multi-action branch is never emitted | todo (multi-action branches) — hand-verified, `BAS-31.vox` | |
| BAS-32 | 115 | A **period** ends the entire construct, including all its actions. | folded into BAS-25 | yes | `'gen line piece'` — the `.` branch | exercised | |
| BAS-33 | 116 | A **comma** separates multiple actions within the same construct. | folded into BAS-25 | yes | `'gen line piece'` — the `,` branch | exercised | |
| BAS-34 | 117 | Only **function definitions** can span multiple sentences (using paragraph breaks). | emit a loop whose sentence ends, then a following statement, and assert that statement ran once and not once per iteration | yes — `If after is not 1 then, Exit 95.` | the shape is emitted constantly (every nested leaf ends its block with a period and the stream continues) but the count is never checked | exercised — hand-verified, `BAS-34.vox` | |
| BAS-35 | 120 | A nested construct (especially `if … then`) owns its **own trailing period**. | emit a nested `if` inside a loop body, with more loop actions after it | yes — assert both the guarded count and the loop count | `gen leaf loop break while` / `… continue while` (src/gen_flow.vox:438, 449) emit `While …, Print …, If … then, Break. Increment …` — exactly the shape; `gen_core.vox:669` documents the trap in the generator's own words | **exercised** — the generator depends on this rule and never checks it | |
| BAS-36 | 121 | Outer constructs (`while`, `for each`, `repeat`) do **not** steal that inner period. | folded into BAS-35 | yes | same | exercised | |
| BAS-37 | 122 | After an inner `if` ends, the outer sentence may continue with more actions. | folded into BAS-35 | yes | same (`Increment u{n}` follows the inner `Break.`) | exercised | |
| BAS-38 | 124–132 | The worked sentence-ownership example: the period after the inner `if` closes only that `if`; the `while` body continues with `write` and `read`. | reproduce the shape with real operations after the inner `if` | yes — assert the number of lines processed | none — no leaf combines file reads with a nested `if` inside the same loop sentence | todo. **The manual's snippet is a fragment**: `content`, `number_lines`, `output` and `source` are never declared and no file is opened, so it cannot be compiled as printed. `BAS-38.vox` is the faithful runnable form. | |
| BAS-39 | 138 | Rule 1: a period closes the **most recently opened** clause — the innermost one currently open — and only that one. | emit three nested clauses, close only the innermost with one period, assert the next statement still ran at the inner depth | yes — a counter per depth | the rule is depended on everywhere (see `gen_core.vox:669`, `gen_flow.vox:469`) but no generated program ever *tests* it: `'gen body'` always ends a block with a plain leaf so exactly one period is ever needed | exercised (implicitly); never asserted — hand-verified, `BAS-39.vox` | |
| BAS-40 | 138 | One period closes one level; to close more than one, write more than one. | folded into BAS-39 | yes | **none** — no generated program contains stacked periods (`..`); grep over 40 programs finds zero | todo | |
| BAS-41 | 139 | Rule 2: a blank line force-closes **every** open clause at once, including an enclosing function definition. | emit a function containing a loop containing an `if`, close all three with one blank line, assert the statement after it ran once | yes — `If after is not 1 then, Exit 95.` | the prelude uses it (one blank line closes a `To` body) but never with a clause open inside the body — every prelude body is a flat statement list | todo (the multi-level case) — hand-verified, `BAS-41.vox` | |
| BAS-42 | 141–151 | The `retries` worked example prints `retrying` once, then `done` once, after the loop runs its full three iterations. | reproduce | yes | none | todo — hand-verified verbatim, `BAS-42.vox`. Note: the manual's prose says the blank line closes the `while`, but the period on `the retries is retries add 1.` has already closed it under rule 1; both readings give the documented output, so the imprecision is not observable. `BAS-44` is where the blank line is genuinely load-bearing. | |
| BAS-43 | 153 | This applies uniformly — `while`, `for each`, `repeat` and `on error` all terminate their body on a blank line, regardless of what the last body statement was. | one blank-line-closed block of each of the four kinds in one program | yes — a counter after each | none — no leaf closes any block with a blank line | todo — hand-verified for all four, `BAS-43.vox` | |
| BAS-44 | 155–168 | The Caution example: a blank line after a nested `for each` closes the enclosing `while` early, so `print "batch done"` runs once, after the loop — `1 2 1 2 batch done`, not `1 2 batch done 1 2 batch done`. | reproduce | yes | none | todo — hand-verified, `BAS-44.vox` (`batch` is undeclared in the manual's copy; `[1, 2]` is what makes the documented output reachable) | |
| BAS-45 | 170–183 | The same blank line can eject a loop's own increment, hanging the program forever with **no error message and no diagnostic**. | not a leaf need — the generator must never emit it | **no** — a generated program that hangs is exactly what the runner classifies as a hang finding; emitting one deliberately would manufacture false findings | n/a | not assertable (must-not-generate) — hand-verified, `BAS-45.vox` (records the bounded timeout; the manual's verbatim copy prints `inner 1`/`inner 2` on repeat until killed) | |
| BAS-46 | 185–193 | The one exception: a blank line placed **after a comma** (mid-sentence) is still just visual spacing. | emit a blank line after a comma inside a multi-action sentence and assert the sentence still completes | yes — the loop's own counter | none — `'gen line piece'` emits `,\n` with no possibility of a blank line after it | todo — hand-verified, `BAS-46.vox` | |
| BAS-47 | 197 | Periods stack: write one period per level you want to close. | vary how many levels a block closes at once and emit that many periods | yes — a counter at each depth | **none** — zero stacked periods in the corpus | todo | |
| BAS-48 | 199–208 | The three-nested-ifs example: three periods get back to the top level, and `print "back at the top"` runs. | reproduce | yes | none | todo — hand-verified verbatim, `BAS-48.vox` | |
| BAS-49 | 208 | Written with one period or two, the same program prints **nothing at all** — with no error. | not a leaf need — this is a miscount, the thing the generator must never do | **no** — a program that prints nothing is indistinguishable from a real no-output finding | n/a | not assertable (must-not-generate) — hand-verified for both counts, `BAS-49.vox` | |
| BAS-50 | 210 | Indentation is **not** what decides this. Vox ignores leading whitespace entirely, so a program can be minified without changing its meaning. | vary the indent width per line, including zero and absurd depths, and assert unchanged behaviour | yes — every existing assertion doubles as the oracle | **none** — indentation is fixed: exactly two widths exist across the whole corpus (2 spaces per nesting level from `gen loop`/`gen if`, 4 spaces for prelude definition bodies), never 0, never varied | todo — a documented degree of freedom the generator never uses; hand-verified, `BAS-50.vox` | |
| BAS-51 | 214 | An `Otherwise` (or `But if`) continues the innermost `if` that is still open. | emit a nested if-chain and assert which branch fired | yes — the generator picks the conditions | `gen leaf rich condition` and the predicate/timer leaves emit `If … then, … . Otherwise, … .` — always **single-line, single-level**, so "innermost" is never in question. `gen leaf butif print`/`butif append` emit the *collection* `but if` (LANGUAGE.md §Loop expansion), a different construct from the if-chain `But if`. | todo (nested chains) — hand-verified, `BAS-51.vox` | |
| BAS-52 | 216–228 | ONE period: the `Otherwise` belongs to the **inner** `if`; the whole construct sits inside a false outer `if` and prints only `done`. | reproduce | yes | none | todo — hand-verified verbatim, `BAS-52.vox` | |
| BAS-53 | 230–242 | TWO periods: the inner `if` is closed, so the `Otherwise` belongs to the **outer** one; prints `outer else` then `done`. | reproduce | yes | none | todo — hand-verified verbatim, `BAS-53.vox`; `But if` in the same position behaves identically (hand-verified) | |
| BAS-54 | 244 | An empty `Otherwise,.` closes an inner chain the same way a stacked period does, and is easier to read. | emit `Otherwise,.` as an alternative to a stacked period | yes — same assertion as BAS-53 | **none** — `Otherwise,.` never appears in the corpus | todo | |
| BAS-55 | 246–259 | The `Otherwise,.` example prints `outer else` then `done`. | reproduce | yes | none | todo — hand-verified verbatim, `BAS-55.vox` | |
| BAS-56 | 261 | Get the period count wrong and **nothing tells you**: too few and following statements are absorbed into a clause you thought you had left; too many and they escape one you meant to stay in. Either way the program still compiles and still runs. | not a leaf need — it is the failure mode the generator must avoid | **no** — both halves are silent, so neither is distinguishable from correct output | n/a | not assertable (must-not-generate) — hand-verified for both directions, `BAS-56.vox` | |
| BAS-57 | 214 (undocumented precision) | *(gap)* `Otherwise` / `But if` continue the innermost `if` **across a blank line** — including the blank line that closes a function definition, which the `Otherwise` then re-enters. Any intervening **statement** ends the chain and makes the `Otherwise` a compile error. | if blank-line block closing is ever generated (BAS-41/BAS-43), never place an `Otherwise` after one by accident | yes, in the negative sense: assert which branch fired after an intervening blank line | none | todo — hand-verified, `BAS-57.vox`; **see Discrepancy 2** | |

## Discrepancies

### 1. The compiler does not require the period that line 39 says every statement ends with — and a missing one closes an `If` but not a `While`

LANGUAGE.md:42, the first sentence of the section: "Every statement ends
with a **period** (`.`)." The compiler accepts statements with no period
at all, including two run together on one line, and produces a working
binary with no error and no warning. Repro (`probes/basics/D1.vox`):

```
Print "one" Print "two".
a number called x is 0.
While x is less than 3, Increment x
Print "in loop".
a number called y is 1.
If y is equal to 2 then, Print "then branch"
Print "after if".
Print "end".
```
Output:
```
one
two
in loop
in loop
in loop
after if
end
```

Two separate things are in there:

**(a)** A period is not required to end a statement. `Print "one" Print
"two".` runs both.

**(b)** When a period *is* omitted at the end of a clause body, the two
kinds of clause disagree about what happens next. After `While x is less
than 3, Increment x` with no period, `Print "in loop".` is **absorbed**
into the loop body — it prints three times, and with the loop condition
false from the start it does not print at all (verified separately). After
`If y is equal to 2 then, Print "then branch"` with no period, `Print
"after if".` is **not** absorbed — it prints once even though the
condition is false, so the newline ended the `If` where it did not end
the `While`. The same asymmetry holds for the multi-line form
(`If … then,` / newline / indented body / newline).

Nothing in the section states either behaviour. Rule 1 (135) names the
period as what closes a clause and rule 2 (136) names the blank line; a
bare newline is a third terminator, and it applies to exactly one of the
clause kinds.

**The strongest reading in which the compiler is correct:** line 39 is a
statement about the *language*, i.e. the form a well-written Vox statement
takes, not a claim about the parser's tolerance — Vox is "sentence based
code" and the period is the sentence's full stop, in the same way English
prose requires one without a reader being unable to parse the sentence
without it. Under that reading the parser is simply lenient, and (b) is an
error-recovery detail: an `If … then,` clause with a body and no
continuation is unambiguously complete at the line's end, whereas a loop
body is not, since a loop is the one construct whose body a reader
routinely expects to continue. That reading holds for (a) and is
defensible for (b), but it means the manual never tells anyone that the
period is optional, nor that omitting it changes meaning inside a loop and
not inside an `If`. For the generator this is a large unexplored surface —
every statement it has ever emitted is period-terminated — but the
asymmetry has to be adjudicated before any leaf may omit a period, or the
generator would silently start writing programs whose shape it has
mispredicted. Not filed.

### 2. A blank line does not end an `if` chain: an `Otherwise` after one still continues the `if`, even across the blank line that closes a function definition

LANGUAGE.md:139 (rule 2): "A blank line (paragraph break) force-closes
**every open clause at once** — including an enclosing function
definition." LANGUAGE.md:91: a function definition "is closed by a blank
line (paragraph break) — this is *required*". LANGUAGE.md:214: "An
`Otherwise` (or `But if`) continues the innermost `if` that is still
open."

Repro (`probes/basics/D2.vox`):

```
To check with a number called n.
    If n is equal to 1 then,
        print "one".

Otherwise,
    print "other {n}".

check of 2.
Print "done".
```
Output:
```
other 2
done
```

The `Otherwise` block is executing **inside `check`'s body** — it prints
`n`, the function's parameter, which does not exist anywhere else. So the
blank line that line 88 says closes the definition did not stop the
`Otherwise` from continuing the `if` inside it, and by line 136's account
there was no open clause left for it to continue.

An intervening statement *does* end the chain: put `Print "between".`
between the blank line and the `Otherwise` and the compiler rejects it
with `error: Expected a statement, got Otherwise` — the same error it
gives for an `Otherwise` with no `if` anywhere. So the chain is ended by a
statement but not by a paragraph break.

**The strongest reading in which the compiler is correct:** rule 2 is
about **clause bodies** — where the *statements* go — and an if-chain's
continuability is a separate, adjacency-based notion: the chain stays open
across anything that is not a statement (whitespace, comments, paragraph
breaks) and closes at the first statement. That reading is not only
coherent, it is *required* by the manual's own two-period example
(227–239), where `print "inner then"..` closes the inner `if` under rule 1
and the following `Otherwise` still attaches to the outer one — an
`Otherwise` continuing an `if` whose clause a period already closed. Line
211's "still open" is then loose wording for "most recently begun and not
yet superseded", and the gap is that no line states the adjacency rule or
its interaction with rule 2. The function-body case is the alarming
corner: a blank line the manual calls *required* and *closing* is silently
not closing, and the resulting program compiles, runs, and is wrong in a
way nothing points at. Not filed.

### 3. An unterminated comment silently swallows the rest of the file

LANGUAGE.md:56–77 documents comments, multi-line comments and nested
parentheses, and says nothing about an unbalanced open-paren. Repro
(`probes/basics/D3.vox`):

```
print "a".
(unterminated comment starts here
print "b".
print "c".
```
Output:
```
a
```

No error, no warning; a binary is produced and exits 0 having run only
the statements before the stray `(`. The contrast that makes this a
discrepancy rather than a mere gap is one line away in the same section:
LANGUAGE.md:91's comparable "construct still open at end of file" case —
an unclosed **function definition** — *does* get a warning, and a
detailed one ("Function 'greet' is still open at end of file…"). The
compiler already has the concept and the diagnostic machinery; it just
does not apply them to comments.

**The strongest reading in which the compiler is correct:** a comment is
lexical, not syntactic — the lexer's job is to discard it, and discarding
"to end of input" is the natural degenerate case, with nothing left for
the parser to complain about. The unclosed-function warning is emitted by
the parser, which still has an open construct on its stack at EOF; the
lexer has no stack to be left holding. Under that reading nothing is
wrong, and the fix is a lexer warning plus a sentence in the Comments
section, not a behaviour change. Worth documenting either way: this is a
silent-wrong-program trap of exactly the kind line 258 warns about for
periods, and the section that would warn about it is the one that
introduces multi-line comments. Not filed.

## Invariants this section justifies

The manual actually requires very little sameness here, which is why this
list is short and the defect list below it is long.

- blank line after every function definition — LANGUAGE.md:91, BAS-19
- every statement in a block body but the last ends with `,`, and the last
  ends with `.` — LANGUAGE.md:115–116, BAS-25/BAS-26/BAS-32/BAS-33
- a nested construct inside a loop body ends with its own period, and the
  loop's remaining actions follow it comma-separated —
  LANGUAGE.md:120–122, BAS-35/BAS-36/BAS-37

Everything else this section touches is a **degree of freedom the
generator has never used**, and each is an unjustified invariant that
`scripts/invariants` either already reports or cannot yet see:

| invariant | why it is unjustified |
|---|---|
| no generated program contains a comment (0 in 40) | LANGUAGE.md:56–77 documents four comment positions and nesting; nothing requires their absence — BAS-07..BAS-14 |
| every keyword is written in one fixed case per leaf | LANGUAGE.md:50 says case is free — BAS-03 |
| indentation is always 2 spaces per nesting level, or 4 in a prelude body | LANGUAGE.md:210 says leading whitespace is ignored entirely — BAS-50 |
| every statement is period-terminated | LANGUAGE.md:42 justifies the period as the *canonical* form, so this one is **cited but soft** — D1 shows the compiler does not require it, and until D1 is adjudicated this invariant should stay |
| no program contains stacked periods (`..`) | LANGUAGE.md:197 documents them — BAS-40/BAS-47 |
| no program contains `Otherwise,.` | LANGUAGE.md:244 documents it — BAS-54 |
| no `On error` handler has more than one action; no `If`/`Otherwise` branch has more than one action | LANGUAGE.md:108, 111 show both with two — BAS-30/BAS-31 |
| no block is ever closed by a blank line | LANGUAGE.md:139, 153 — BAS-41/BAS-43 |
| exactly one blank line between prelude constructs, never zero and never two | LANGUAGE.md:81 says the count is free between terminated constructs — BAS-16 |
| no `Library` line ever appears | LANGUAGE.md:91 — BAS-22 |

**A note the invariant report cannot give you:** `scripts/invariants`
reports sameness in what the corpus *contains*. Most of the table above is
sameness in what it **omits** — a construct that appears zero times has no
line to be identical to. The comment gap (zero comments in forty programs,
against a subsection of the manual that documents four positions plus
nesting) is the largest finding in this ledger and the report would never
have surfaced it. That is worth a category in the tool, or at minimum a
per-ledger checklist of constructs whose count is zero.

## Report

**57 rows** (BAS-01 through BAS-57). Thirteen of them are cross-references
folded into a sibling row rather than fresh leaf needs (BAS-04, BAS-05,
BAS-08, BAS-20, BAS-23, BAS-26, BAS-32, BAS-33, BAS-36, BAS-37, BAS-40,
BAS-47, BAS-54), leaving **44 distinct claims**.

**Assertable: 50 of 57.** The seven that are not divide into two kinds,
and the second kind is new to this ledger:

- **compile-time or diagnostic** (BAS-06, BAS-23) — a compile error or a
  warning, outside the generator's "legal Vox that should compile and
  run" contract;
- **must-not-generate** (BAS-15, BAS-21, BAS-45, BAS-49, BAS-56) — five
  claims whose documented behaviour is *silence*: a program that prints
  nothing, or hangs, or swallows its own tail. These are not merely
  unassertable, they are **actively dangerous to emit**, because the
  runner's finding classifier reads no-output and hang as findings. A leaf
  worker on this section needs that stated plainly: five of the manual's
  own examples in this range must never appear in a generated program.

**Exercised: 15 rows.** All of them are constructs the generator already
depends on structurally — `'gen line piece'`'s comma/period discipline,
the prelude's blank-line-closed definitions, the nested-`if`-inside-a-loop
shape in `gen leaf loop break while`. **Verified: 0**, the same uniform
gap the buffers and values ledgers found.

**The biggest finding is an absence: not one generated program has ever
contained a comment.** LANGUAGE.md gives comments a subsection with four
documented positions, multi-line spans and nesting; the generator emits
zero, across every seed, and has since it was written. Two more of the
same kind sit beside it: keyword case is documented as free and is
hardcoded in every leaf, and indentation is documented as *entirely
ignored* and is a fixed two-space ladder. Those three are the cheapest
high-value leaf work in this section — a comment injected at a random
position into an existing leaf's output, a randomly-cased keyword, and a
randomised indent all cost nothing to emit and cannot change any
assertion the leaf already makes, so **every existing assertion in the
generator becomes their oracle for free.** That is a rare shape: coverage
that piggybacks on work already done rather than needing its own.

**Three discrepancies**, all with minimal repros, none filed. D1 is the
serious one: the first sentence of the section says every statement ends
with a period, the compiler does not require it, and omitting it changes
which clause the *next* statement belongs to — differently for `If` than
for `While`. D2 is narrower but nastier in the way CLAUDE.md means:
a blank line that LANGUAGE.md:91 calls *required* and *closing* does not
stop an `Otherwise` from re-entering a function body, and the resulting
program compiles and runs and is wrong with nothing pointing at it. D3 is
a documentation gap with a diagnostic already sitting next to it.

**What I could not do:** nothing in this range needed root, a device or a
second process, so every row is either probed or explicitly
not-assertable with a reason. Three mismatches between the brief and
`INDEX.md` are recorded rather than guessed at: the brief calls the
section "Variables" (it is Basics — the line range is right, the name is
not); the brief says to write `docs/ledger/basics.md` while `INDEX.md`
lists the `BAS` ledger as `basics-sentences.md`; and the brief's probe
naming example says `probes/basics/THG-NN.vox` while the row prefix it
assigns is `BAS`. I followed the brief for the filename and the ledger's
own prefix for the probes (`BAS-NN.vox`). `INDEX.md` also still pins the
manual at **0.4.7 / 5112 lines**; the manual is now **0.4.8 / 5240
lines**, so every line range below this section has moved and needs
re-pinning before the next mapper starts. Lines 35–259 are unaffected —
they are still exactly the Basics section.

**Advice for the next mapper.** Three things this section taught that
generalise:

1. **For a syntax section, the oracle is an execution count, not a
   value.** The generator knows how many times each statement it emitted
   should run. `If ticks is not 3 then, Exit 95.` turns every structural
   claim in this range into a verifiable one. Do not mark a shape claim
   "not assertable" just because it returns nothing.
2. **Check what the corpus does not contain, not just what repeats.**
   `scripts/invariants` cannot see a zero. Before writing the table, list
   every construct the section documents and grep the corpus for each one;
   the comment gap here was found that way and nothing else would have
   found it.
3. **Put the probe's own header through the language's rules.** A `(` in
   prose inside a probe's header comment opens a nested comment level and
   silently swallows the program (BAS-13, D3). Two probes were written
   that way here and one of them ran, printed nothing, and looked like a
   real finding until `check-probes.sh` caught it. Write "open-paren",
   not the character.
