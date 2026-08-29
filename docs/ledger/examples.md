# Claim ledger: Examples

Source: `../vox/LANGUAGE.md` lines 5342–5382, Vox 0.4.10 (5545 lines, vox
527cb89), confirmed 2026-08-22 (Examples chapter: Hello World, Variables
and Arithmetic, Function Definition and Call, Counting Loop, FizzBuzz).
Uniform +87 drift from the 0.4.8 pinned range (4750–4790), confirmed at
all five example headings plus the section boundary (`## Examples` now
at 4837, next `##` — Libraries and Imports — now at 4878). All five
source blocks are byte-for-byte unchanged since 0.4.8.

This is a **gap analysis**, not a from-scratch map — but this section had
never been mapped at all (`INDEX.md` said `no`), so every row here is
new.

Each of the five examples is a single **composite claim**: the manual
shows only source code, no output block, for any of them — so the claim
is narrower than "matches the printed output" (there is none to match)
and reads instead as "this program compiles and its behavior is exactly
what the code's own semantics predict." The generator can compute that
prediction for every one of these (all five are pure, input-free
arithmetic/control-flow — no stdin, no argv, nothing to feed), so all
five are independently `assertable` in the sense that a leaf emitting the
equivalent construct could assert its own known result; whether that
leaf exists already is the `existing leaf` column.

## Probes

Every row's probe is retained, runnable, in
`docs/ledger/probes/examples/`, one file per row named `EXA-NN.vox`,
copied **verbatim** from the manual (no adaptation — these are the
manual's own source blocks, character for character). Each file's header
records the compiler's actual run as the `expected output:` block, since
the manual prints none. All five were compiled and run against
`/home/josj/scr/english/vox/target/release/vox` with `VOX_CORE_PATH` set
to the sibling `coreasm` before being written.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| EXA-01 | 5344–5349 | "Hello World": `Print "Hello, World!".` compiles and prints `Hello, World!`. | reproduce verbatim | yes — the string is a literal, trivially self-predicting | none — no leaf in `src/gen_*.vox` reproduces this exact composite program; `Print` of a string literal alone is exercised constantly but never as a whole standalone program matching this example | todo — hand-verified to reproduce exactly (`EXA-01.vox`) | |
| EXA-02 | 5350–5357 | "Variables and Arithmetic": two number declarations and `Print the x add the y.` compiles and prints `8`. | reproduce verbatim | yes — 3+5=8, generator-computable | none as a whole; `a number called X is N.` and `X add Y` are both individually exercised constantly by every arithmetic leaf, but never in this specific two-variable, one-`Print` shape | todo — hand-verified to reproduce exactly (`EXA-02.vox`) | |
| EXA-03 | 5358–5364 | "Function Definition and Call": a two-parameter function definition (`'add numbers' with a number called x and a number called y`) called with `of`, compiles and prints `8`. | reproduce verbatim | yes — 3+5=8, generator-computable | none as a whole; `To '<name>' with ...` function definitions and `of`-form calls are both exercised constantly (cross-ref FUN, functions.md), but not this exact program | todo — hand-verified to reproduce exactly (`EXA-03.vox`) | |
| EXA-04 | 5366–5371 | "Counting Loop": `Set the number called counter to 1.` (a var_decl, not a plain assignment — see GRM-03/D1 in grammar-summary.md for the general form) followed by a `While` loop, compiles and prints `1` through `9`. | reproduce verbatim | yes — the loop bound and increment are both literal, generator-computable | none as a whole; `Set the ... to ...` as a declaration form and `While ... increment ...` are both individually exercised (cross-ref VAR, FLW), but not composed this way | todo — hand-verified to reproduce exactly (`EXA-04.vox`) | |
| EXA-05 | 5373–5382 | "FizzBuzz": a divisibility-checking function plus a `For each ... but if ... but if ... but if` chain over 1–15, using divisors 6/2/3 (not the classic 15/3/5), compiles and produces the expected 15-line FizzBuzz sequence for those divisors. | reproduce verbatim | yes — every divisor and every input 1–15 is a literal, generator-computable | none as a whole; `For each number from A to B`, `but if <cond> print <expr>` chains (print_stmt's own form, cross-ref GRM-15 in grammar-summary.md), and `modulo` are all individually exercised, but this exact composite program is not | todo — hand-verified to reproduce exactly (`EXA-05.vox`) | |

## Discrepancies

None. All five examples compiled and ran clean, exactly matching what
their own code predicts — no example is stale, no output contradicts the
surrounding prose (there is no stated output to contradict), and no
construct behaved unexpectedly. One thing worth recording even though it
is not a discrepancy: EXA-05's FizzBuzz uses divisors 6, 2, 3 (not the
conventional 3, 5, 15) and its `but if` chain fires in that order — the
manual's own FizzBuzz is simply a different, non-canonical divisibility
puzzle, not a botched rendition of the classic one, and reading it as
the classic one first would make the output look wrong when it is not.

## Invariants this section justifies

None. Every construct in this chapter is a composite of forms mapped and
justified elsewhere (var_decl, assignment, func_def, func_call, if/but-if,
while, for-each, arithmetic) — see grammar-summary.md, variables.md,
functions.md, control-flow.md, expressions.md, operators.md for the
per-construct citations. This ledger's five rows contribute no invariant
of their own; they are a correctness check on the manual's chosen
illustrations, not a new source of generator constraints.

## Report

**5 rows** (EXA-01 through EXA-05), all independently assertable, all
hand-verified, all `todo` (no leaf reproduces any of the five composite
programs as a whole, though every part of each is separately exercised
elsewhere). **Zero discrepancies** — this is the cleanest section mapped
so far; every example the manual chose to illustrate the language with
is itself correct and stable at 0.4.8+#49–#54.

The main finding is negative and unremarkable: the Examples chapter is
low-risk by construction (it is deliberately simple, sensible code — the
opposite of what `CLAUDE.md` says vox-fuzz should spend its own
generation effort on) and needs no leaf work beyond "someday, compose
these five programs from parts the generator already emits, and assert
their known outputs" — a nice-to-have regression check, not a coverage
gap in the memory-safety sense.

**For the next mapper (compiler-usage.md, then grammar-summary.md, in
this same worker's batch):** the "manual shows no expected-output block"
pattern recurs for the CLI's own worked examples (5245–5262) — same
treatment applies: the compiler's actual run becomes the recorded
ground truth. It does not recur for the Grammar Summary, whose "claim" is
parsing, not printing — a different `assertable?` shape entirely (does
the form parse, not does it produce X).
