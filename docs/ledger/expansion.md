# Claim ledger: Basics → Ranges, Loop Expansion, `but if`, `treating`

Source: `../vox/LANGUAGE.md` lines **260–438** (Basics § Ranges, Loop
Expansion, Chained `each` clauses — a grid, Conditional Branching with
`but if`, Inline Substitution with `treating`), through to the `## Types`
heading at 439.

Manual version, re-pinned 2026-08-23: **Vox 0.4.10** (5545 lines, vox
`527cb89`). The **zero line drift** streak that held from the pre-0.4.9
commit through 0.4.9 (`### Ranges` at 260, `## Types` at 428) **ended at
0.4.10**: `## Types` moved to 439 (+11 net), from two additions late in
the `treating` subsection — a new worked example (`append each ... to
...` with `treating`, resolving what `grammar-summary.md` Discrepancy 3
found, vox #70) and a new paragraph documenting match/replacement
type-equality (closing BAS2-59's former "undocumented precision", vox
#55/#69). Every row citation before that insertion point (everything
through BAS2-57) is unaffected; BAS2-58 and BAS2-59, which anchor to the
`treating` subsection's tail, needed updates — see their rows.

**Three of this ledger's four discrepancies are now resolved,
re-verified directly against vox 0.4.9 (not just re-read):**
- **D1** (loop expansion doesn't work with "any action") — the
  buffer-append arm now compiles and works (vox #54/#55 side effect,
  confirmed against `vox-notes/REPORT-CANDIDATES-0.4.10.md` candidate
  F). The other two arms are unchanged.
- **D3** (`treating` type mismatch segfaults) — now a clean compile
  error. Vox #55.
- **D4** (same confusion over a mixed list leaks an address) — now
  renders correctly. Fixed, uncredited to a specific numbered entry.
- **D2** (`otherwise` displaces the base action) — unadjudicated
  manual-wording question, re-probed, unchanged.

`d974da0` (the commit this ledger was originally mapped against, just
before the 0.4.9 release) had already fixed compiler bug **#50**
("`otherwise` after any base action"), which BAS2-45's row already
accounts for below — nothing new there.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct, or `none`, and was determined
by `grep`ping the emitted text (`each`, `from`, `treating`, `but if`,
`otherwise`, `arguments's all`) across `src/gen_*.vox`, never by leaf
name. As in `buffers.md`: **no leaf on this surface emits an assertion**.
Every one of them prints for a human to eyeball, so nothing here is
`verified`, and that uniform gap is a finding about the whole surface
rather than a per-row surprise.

Every row below was hand-run against the real compiler before it was
written.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/expansion/`, one file per row named `BAS2-NN.vox`
(a probe covering more than one row is named for the first and says so in
its `Also covers:` line). Each file opens with a `(...)` comment naming
the claim, the exact `Ran:` command, and an `expected output:` block
recording what the compiler **actually** printed. Compile-error rows
record the diagnostic; the crash row records `exit 139`.

`fixtures/alpha.txt` and `fixtures/beta.txt` are the on-disk inputs the
two file-expansion probes (BAS2-13, BAS2-53) read; both hold their word
with **no trailing newline**, and both probes assume a working directory
at the repo root, the same convention `probes/buffers/BUF-07` uses.

32 probe files, plus `D1.vox`–`D4.vox` for the four discrepancies:
**36 files**. All 36 were re-run in one final pass through
`docs/check-probes.sh docs/ledger/probes/expansion` — **36 passed, 0
failed, 0 skipped**.

The other 27 rows have no probe file of their own because a sibling's
probe covers them, and that sibling's `Also covers:` line names them.
**Every row from BAS2-01 to BAS2-59 is covered by a probe except
BAS2-35**, which is a cross-reference to another section rather than a
claim about behaviour.

Two probes could not be made self-contained, and say so in their headers:
BAS2-13 and BAS2-23 both need real command-line arguments to exercise the
`arguments's all` collection, and `check-probes.sh` runs every binary with
none. Both retained probes therefore record the zero-argument run (the
body runs zero times, which is itself the documented empty-collection
behaviour), and their headers record the separate hand-run **with**
arguments and exactly what it printed.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| BAS2-01 | 294 | A range denotes the sequence of numbers from a start value to an end value. | a `For each <var> from A to B` whose iteration count is observable | yes — count iterations into a variable, then `If runs is not 10 then, Exit 95.` (the generator picked A and B) | `gen loop` (gen_flow.vox:463), `gen leaf loop break foreach`/`loop continue foreach` (:426, :434), `gen leaf cast and break` (gen_misc.vox:177), `gen leaf timer and clock` (gen_misc.vox:212) | exercised | |
| BAS2-02 | 294, 311 | A range is **not** allocated as a list — it compiles to a counter, a bounds check and an increment. | a range far larger than addressable memory, left early | yes, **by proxy** — `For each n from 1 to 1000000000, … Break` must reach 3 and finish immediately; an 8 GB list allocation could not. No direct in-language observation of "was nothing allocated" exists | none — every range any leaf emits is at most ~45 wide | todo | |
| BAS2-03 | 298 | The worked example `For each number from 1 to 10, print the number.` compiles and prints 1 through 10. | reproduce verbatim | yes | as BAS2-01 | folded into BAS2-01 (probe `BAS2-01.vox` is the example verbatim) | |
| BAS2-04 | 301–303 | Range bounds may be variables, not just literals (`from start to end`). | a range whose bounds are runtime Vox variables, not numbers baked into the generated text | yes — `If runs is not 5 then, Exit 95.` | **none** — every emitted bound is interpolated as a compile-time literal before the program is written (`{'the ceiling'}`, `{'the limit'}`, `{'range start'}` are all generator-side numbers). The variable-bound code path is never taken, exactly as BUF-21 found for byte indices | todo — real gap, hand-verified to work | |
| BAS2-05 | 306 | A range is a legal loop-expansion collection: `print each number from 1 to 10.` | a bare `print each <var> from A to B` | yes — the generator knows the printed lines; assert a companion counter | `gen leaf treating print` (gen_flow.vox:200) — but only ever with a `treating` clause attached, and only over a list or `arguments's all`, never over a range | todo for the range source and for the no-`treating` form; the `print each` construct itself is exercised | |
| BAS2-06 | 310 | Ranges are inclusive of both endpoints — `1 to 5` yields 1, 2, 3, 4 and 5. | a range whose first and last values are both printed or counted | yes — `If runs is not 5 then, Exit 95.`, and assert the first and last values | as BAS2-01 (emitted, never asserted, so inclusivity is never actually pinned) | exercised — verification is the gap | |
| BAS2-07 | 312 | The loop variable is available inside the loop body, under both spellings (`the number` and bare `number`). | a body that reads the loop variable both ways | yes — assert the two reads are equal | `gen loop` reads bare `number`; `gen leaf loop break foreach` reads bare `number`; **no leaf emits the `the <var>` spelling** the manual's own examples use | exercised (bare form only) — the `the` spelling is a todo | |
| BAS2-08 | undocumented precision at 265/281 (re-confirmed unchanged, 0.4.10) | *(gap in the manual)* A descending range (start greater than end) runs **zero** times — it neither counts down nor raises. A one-element range (`3 to 3`) runs once. | emit a range with start > end and assert nothing ran | yes — `If runs is not 0 then, Exit 95.` | none — every emitted range has start ≤ end by construction | todo | see Discrepancy-adjacent note below the table |
| BAS2-09 | 316 | `each … from …` is a loop expansion: it turns a single action into a loop that runs once per item. | any expansion form | yes | `gen leaf treating print`, `gen call grid`, `gen leaf deep grid`, `gen leaf treating grid` | folded into BAS2-10 (probe `BAS2-10.vox`) | |
| BAS2-10 | 320 | A list literal is a legal expansion collection: `print each number from [1, 2, 3].` | a `print each` over a list literal | yes — assert an iteration counter equals the list's length | `gen leaf treating print` (list branch, gen_flow.vox:195), `gen call grid`, `gen leaf treating grid` — all two-element lists | exercised | |
| BAS2-11 | 323 | `print each number from 1 to 15.` — a range under `print each`. | — | yes | as BAS2-05 | folded into BAS2-05 | |
| BAS2-12 | 326 | A user function may be the expanded action, with a further comma-separated action after it: `process of each item from mylist, print "done".` | a single-clause `f of each x from Y` plus a trailing action | yes — assert the callee saw each element once | **none for the single-clause form** — every function expansion the generator emits is a *grid* of two or more `each` clauses (`gen call grid`, `gen leaf deep grid`, `gen leaf treating grid`). The one-clause form in the manual's example is never generated | todo — real gap, hand-verified to work | |
| BAS2-13 | 329–333 | The worked example opens one file per element and runs the whole comma-separated body (read, print, close) once per file. | an `open a file … at each <var> from <collection>` with a multi-action body | yes — the generator writes the fixture files, so it knows the bytes and can assert the buffer's size and contents per iteration | **none** — no leaf emits `at each` in any form; `gen_files.vox` opens exactly one file per statement | todo — real gap, hand-verified to work | |
| BAS2-14 | 336 | The syntax is `<action> each <variable> from <collection>, <additional actions>`. | — | yes | as BAS2-12 | folded into BAS2-12 (probe `BAS2-12.vox`) | |
| BAS2-15 | 338 | The action executes exactly once per item, with the loop variable bound to that item. | an expansion whose per-item output is checked | yes — assert the count and the values | as BAS2-10 | folded into BAS2-10 | |
| BAS2-16 | 338 | Additional comma-separated actions execute **inside** the loop, after the main action. | an expansion with a trailing action, distinguishable by interleaving | yes — the interleaved order (7, done, 8, done) is fully known at generation time | `gen leaf treating print` and the grid leaves all emit a **single** action with no trailing clause; the interleaving is never generated | folded into BAS2-12 for verification; **todo** as a construct | |
| BAS2-17 | 341 | `print each X from Y` is supported. | — | yes | `gen leaf treating print` | folded into BAS2-05 | |
| BAS2-18 | 342 | `function of each X from Y` is supported. | — | yes | `gen call grid`, `gen leaf deep grid`, `gen leaf treating grid` (two clauses or more only) | exercised (grid form); single-clause form is BAS2-12 | |
| BAS2-19 | 343 | `open … at each X from Y` is supported. | — | yes | none | folded into BAS2-13 | |
| BAS2-20 | 344 | **Any** action that takes an argument supports `each` expansion. | — | the claim is **false as written**: `write each … to <file>`, `Set … to each …` and `append each <text> to <buffer>` are all rejected, while the shape-identical `append each … to <list>` compiles | n/a | **contradicted** — see Discrepancy 1 | |
| BAS2-21 | 347 | Ranges are a supported collection, both literal (`1 to 10`) and variable-bounded (`start to end`). | — | yes | literal form exercised; variable form none | folded into BAS2-04 (variable half) and BAS2-05 (literal half) | |
| BAS2-22 | 348 | Lists are a supported collection: a literal and any list variable. | expansion over a list **variable** as well as a literal | yes | `gen leaf treating print` uses a literal; `gen call grid`/`gen leaf treating grid` use literals. **No leaf expands over a list variable** | exercised (literal); todo (variable) | |
| BAS2-23 | 354 | `arguments's all` is a supported collection and is argv[1..] — the program name is excluded. | expansion over `arguments's all` in a program the harness passes arguments to | yes — the harness already builds argv (`gen build argv`) and already asserts against it at exits 91–94, so the expected element list is known | `gen leaf treating print` (argv branch, gen_flow.vox:189) — but the leaf's own comment records that it runs over an **always-empty** collection, so the loop body has never executed in any campaign | exercised only in the degenerate empty case — todo for a non-empty one | |
| BAS2-24 | 358–359 | More than one `each … from …` clause may appear in one sentence, joined by `and`. | a call with two or more `each` clauses | yes | `gen call grid` (two clauses), `gen leaf deep grid` (3–17, drawn at gen_core.vox:1003), `gen leaf treating grid` (two) | exercised | |
| BAS2-25 | 359–362 | The action runs once per element of the Cartesian product, in row-major order — the leftmost clause is the outermost loop. | a grid whose emitted order is checked | yes — the generator chose both collections, so the whole product sequence is known; assert the callee's running total, or assert the first and last pair | as BAS2-24 — `gen leaf deep grid`'s sink prints a sum, but the sum is order-independent, so **order is never actually checked** | exercised; order is the verification gap | |
| BAS2-26 | 365–368 | The `'pair' of each x from [1, 2] and each y from [10, 20].` example runs four times: (1,10), (1,20), (2,10), (2,20). | reproduce verbatim | yes | as BAS2-24 | folded into BAS2-24 (probe `BAS2-24.vox` is the example verbatim) | |
| BAS2-27 | 370–374 | The grid form is identical to the equivalent nested `For each` loops written left to right. | both forms in one program, producing the same sequence | yes — assert the two halves produce identical output (accumulate each into a list and compare) | none emits the two forms together; `For each <var> from <list>` (the `from` spelling over a list, as the manual writes it here) is emitted by **no** leaf — `gen_collections.vox` uses the `in` spelling | todo | |
| BAS2-28 | 376 | There is no limit on the number of chained clauses. | a grid deeper than two | yes | `gen leaf deep grid` reaches depth 17 | exercised | |
| BAS2-29 | 376–377, 380 | A fixed (non-`each`) argument may sit among the clauses and is evaluated once per call — here, first. | a grid call mixing a fixed argument with `each` clauses | yes | **none** — every grid call the generator emits has `each` in *every* argument position | todo | |
| BAS2-30 | 381 | The same, with the fixed argument last. | — | yes | none | folded into BAS2-29 | |
| BAS2-31 | 384–388 | An inner clause's collection may use a variable bound by an outer clause, giving triangle iteration. | a grid whose inner range bound is the outer loop variable | yes — the triangular count is arithmetic the generator can do (`If runs is not 6 then, Exit 95.`) | **none** — every emitted clause's bounds are independent literals | todo — real gap, hand-verified to work | |
| BAS2-32 | 391–392 | A range bound in an `each` clause takes a primary, not an expression: `each col from row add 1 to 4` is a parse error. | a generated compile-failure fixture, not a fuzz leaf | not by a leaf — the fuzzer's contract is that generated programs compile (`CLAUDE.md`); this belongs in the compiler's own compile-fail fixtures | n/a | not a leaf need — probe retained, claim confirmed | |
| BAS2-33 | 393 | Bracing the arithmetic fixes it: `each col from {row add 1} to 4`. | a braced arithmetic bound in an `each` clause | yes — the bound is arithmetic the generator can evaluate | **none** — no emitted bound is braced | todo — real gap, hand-verified to work | |
| BAS2-34 | undocumented precision at 357 (re-confirmed unchanged, 0.4.10) | *(gap in the manual)* The primary-only restriction is neither specific to `each` clauses nor to the start bound: a plain `For each` range rejects an arithmetic **end** bound with the same diagnostic, and so does `print each`. | — | not by a leaf, same reason as BAS2-32 | n/a | not a leaf need — probe retained | |
| BAS2-35 | 395–396 | The arity rule, the empty-collection rule, duplicate loop variables and after-loop values are specified under **Loop Expansion with Collections**. | — | n/a — a cross-reference, not a claim about behaviour | n/a | not a claim — the target exists (LANGUAGE.md:3023) and is `collections-b.md`'s range, not this ledger's | |
| BAS2-36 | 400 | `but if` is a generic conditional branch over a base action, available in both `for each` loops and loop expansion. | a `but if` chain hung off a loop-expansion base **and** off a `For each` body | yes — the branch taken per iteration is fully determined by the generator's own condition and data | **none for either documented context** — `gen leaf butif print` and `gen leaf butif append` both hang their chain off a *plain* statement (`Print <expr>` / `append <expr> to <list>`), never off a loop. The construct the manual documents is not the construct the generator emits | todo — real gap | |
| BAS2-37 | 404–407 | The FizzBuzz example prints the stated sequence for 1..15. | reproduce verbatim | yes — every line is computable at generation time | none (no `but if` over a loop at all) | todo | |
| BAS2-38 | 410–411 | The even/odd example: matching iterations print `even`, the rest fall through to the base action. | reproduce verbatim | yes | none | todo | |
| BAS2-39 | 414–415 | The append example: `append each number from 1 to 5 to out, but if … append 0.` yields `[1, 0, 3, 0, 5]`. | an `append each … to <list>` carrying a `but if` | yes — the resulting list is fully known; assert `out's length` and its elements | `gen leaf butif append` emits the `but if` and the append, but never the `each` expansion; **`append each` appears in no leaf** | todo | |
| BAS2-40 | 418–420 | The `For each` + `but if` example, with a user predicate (`divisible of the number and 3 is true`) in the condition. | a `but if` inside a `For each` body whose condition calls a user function | yes | none — `gen condition` never calls a user function | todo | |
| BAS2-41 | 423 | The syntax is `<base action>, but if <cond> <alt>, …[, otherwise <alt>].` | — | yes | partially: the chain shape is emitted, the `otherwise` only after `append` | folded into BAS2-45 | |
| BAS2-42 | 426, 429 | The base statement is the default action, and it runs when no `but if` condition matches. | a chain where at least one iteration matches nothing | yes | `gen leaf butif print`/`butif append` reach this case, unasserted | folded into BAS2-38 for verification; exercised as a construct | |
| BAS2-43 | 427, 433 | Clauses are checked in written order and the first match wins. | a chain with two conditions that can both be true on the same item | yes — the generator picks the data, so it knows which clause should win | `gen leaf butif print`/`butif append` emit 1–3 branches, but the conditions come from `gen condition` and overlap only by accident; nothing asserts which branch ran | exercised; first-match-wins is never actually pinned | |
| BAS2-44 | 428 | A matching clause's action runs **instead of** the default, not in addition to it. | a chain where the base and the branch print distinguishable values | yes | as BAS2-43 | folded into BAS2-38 | |
| BAS2-45 | 430, 436 | An optional trailing `otherwise` provides a final, catch-all alternative. | an `otherwise` on a print chain as well as an append chain | yes — the generator knows which iterations reach the catch-all | `gen leaf butif append` **always** emits one; `gen leaf butif print` **never** does, on the strength of a 0.4.5-era hand-verification recorded at gen_flow.vox:113–120 that the compiler no longer justifies — bug #50 (`d974da0`) made `otherwise` legal after any base action, and the probe confirms it | exercised (append); todo (print) — and see **Discrepancy 2**: `otherwise` *displaces* the base action, which rule 4 at :392 says should still run | |
| BAS2-46 | 434 | Multiple `but if` clauses can be chained. | — | yes | `gen leaf butif print`/`butif append` emit 1–3 | folded into BAS2-37; exercised as a construct | |
| BAS2-47 | 435 | The alternative action can be any valid Vox statement, not only a print. | branches that are a `Set` and a user function call | yes — assert the accumulated effect (`If tally is not 2 then, Exit 95.`) | **none** — every emitted branch is a `print <expr>` or an `append <expr>`; the "any statement" half of the claim is untested | todo | |
| BAS2-48 | 437 | `but if` works with both ranges and collections. | chains over both a range and a list | yes | none (no `but if` over any loop) | folded into BAS2-36 | |
| BAS2-49 | 438 | The loop variable is available in the conditions. | a condition that reads the loop variable | yes | none | folded into BAS2-36 | |
| BAS2-50 | 439 | In an `append` branch the `to <target>` may be omitted and is inherited from the base append; retargeting to a different list or buffer is not allowed. | the omitted form in a leaf; the retargeting form as a compile-fail fixture | the omitted half: yes. The rejected half is not a leaf need — a generated program must compile | `gen leaf butif append` omits the target in every branch (it has no `each` expansion, but the inheritance rule applies to its chain too) | exercised (omitted form, via `gen leaf butif append`); the retargeting rejection was hand-run and is recorded in the note below the table | |
| BAS2-51 | undocumented precision at 366 (re-confirmed unchanged, 0.4.10) | *(gap in the manual)* `but if` also attaches to a plain, non-loop base statement. The manual names only `for each` loops and loop expansion. | — | yes | `gen leaf butif print`, `gen leaf butif append` — this undocumented form is the **only** one the generator emits | exercised — and it is the whole of the generator's `but if` coverage | |
| BAS2-52 | 443 | `treating X as Y` performs inline value substitution on the loop variable. | an expansion with a `treating` clause where at least one item matches and one does not | yes — the generator chose the collection and the match, so it knows exactly which iterations substitute | `gen leaf treating print` (gen_flow.vox:200), `gen leaf treating grid` (:218) | exercised | |
| BAS2-53 | 447–450 | The worked example substitutes the sentinel filename before the file is opened, per iteration. | `open … at each … treating …` with a multi-action body | yes — the generator writes the fixtures | none (`at each` appears in no leaf) | todo | |
| BAS2-54 | 453 | `print each name from names treating "" as "Anonymous".` — substitution over a list variable. | a `treating` expansion over a list **variable** | yes | `gen leaf treating print` uses a list *literal* or `arguments's all`, never a named list variable | folded into BAS2-52 for verification; the list-variable source is a todo | |
| BAS2-55 | 456 | `process of each filename from files treating "-" as "/dev/stdin".` — substitution on a function-call expansion. | a single-clause function expansion carrying a `treating` | yes | `gen leaf treating grid` carries `treating` on a function call, but only in the two-clause grid form | exercised (grid form); single-clause form todo | |
| BAS2-56 | 463 | The syntax is `… each <var> from <collection> treating <match> as <replacement>, …` — the clause attaches to its own `each` clause. | a grid where only one of two clauses carries a `treating` | yes | `gen leaf treating grid` gives **both** clauses one, always | folded into BAS2-58; the one-of-two shape is a todo | |
| BAS2-57 | 465 | If the loop variable equals `<match>` it is replaced by `<replacement>` for that iteration — and only then. | a collection containing both a matching and a non-matching item | yes — assert the substituted and the pass-through values | `gen leaf treating print`'s match is drawn independently of its two list elements, so it usually matches nothing; nothing asserts either way | exercised; substitution itself is never actually observed | |
| BAS2-58 | undocumented precision at 429 (was 426 at the 0.4.10 pin and 422 at 0.4.9 — shifted first by the new append-with-substitution example inserted before it, then by the spec diet's three new header lines; no text change) | *(gap in the manual)* A `treating` clause may attach to each clause of a grid independently, and a **range** accepts one as readily as a list. Neither is stated. | — | yes | `gen leaf treating grid` does exactly this (both clauses, one a range) | exercised | |
| BAS2-59 | 467–471 (was: undocumented precision at 424) | **Claim resolved as a manual gap, 2026-08-22 (0.4.10) — no longer undocumented.** The compiler checks that `<match>` and `<replacement>` agree with **each other** — `treating 98 as "z"` is a compile error — and, as of 0.4.10, the manual now *also* states the element-type check this row used to say was missing entirely: "Equality is by type as well as by value: a `<match>` whose type differs from the element's never fires, and that element comes through unchanged — and where the compiler can prove the mismatch, it says so at compile time instead." This is exactly the fix behind **Discrepancy 3** (RESOLVED, vox #55) and **Discrepancy 4** (RESOLVED) below, now written up in LANGUAGE.md itself rather than left as an undocumented precision. | emit a provably-mismatched `treating` (expect a compile error) and an unprovable one over a mixed list (assert the mismatched element passes through unchanged) | for the provable half: no, compile-error claim. For the unprovable half: yes — `If element 2 of result is not "a" then, Exit 95.` | none | todo — **hand-verified against 0.4.10**: `print each item from ["a"] treating 98 as 31.` now names the mismatch at compile time with a hint ("'item' holds text here, so it can never equal a number"); `print each item from [1, "a"] treating 98 as 31.` (unprovable, mixed list) leaves both elements unchanged, since neither matches 98 by type-and-value | |
| BAS2-60 | 349–353 | **New row, 2026-08-29 (0.4.15, #104).** A buffer is a supported loop-expansion collection: any buffer variable — each iteration binds the loop variable to one byte's value (0–255), in order 1..size, the same value `byte N of <buffer>` yields. | emit `print each X from <buffer>` and `For each X from <buffer>,` over a buffer built from a known string, assert each yielded value matches `byte N of` | yes — the generator wrote the bytes, so every value is known: `If b1 is not 65 then, Exit 95.` | none — `grep` for `each.*from.*<buffer>` across `src/gen_*.vox` finds nothing | todo — hand-verified (`a buffer called data is "AB". For each byte from data, print byte.` → `65`, `66`, matching `byte 1 of data`/`byte 2 of data`) | |
| BAS2-61 | 352–353 | `byte` is itself a legal loop-variable name in this one position (and, by consequence, as a bare reference to the bound variable inside the loop body). | emit `byte` as the loop variable and read it back inside the body (e.g. in an arithmetic expression) | yes | none | todo — hand-verified (`For each byte from data, print byte add 1000.` → `1065`, `1066`) | |
| BAS2-62 | *(gap — extends the general empty-collection rule, LANGUAGE.md:3145–3146, "print each n from \[\]." does nothing, to the new buffer collection; not restated for buffers by name)* | An empty (size-0) buffer iterates zero times, the same as an empty list. | declare a fixed buffer with no initial content (size 0), run the loop, assert the body never executed and the following statement still ran | yes | none | todo — hand-verified (`a buffer called blank is 8 bytes. For each byte from blank, print byte. print "after".` → only `after`, confirming a fresh fixed buffer starts at size 0 and the loop body never ran) | |

**Note on BAS2-08 (descending ranges).** This is recorded as an
undocumented behaviour, not a discrepancy: nothing in the manual says what
`5 to 1` should do, so the compiler cannot contradict it. Zero iterations
is also the only choice consistent with "ranges compile to a counter, a
bounds check and an increment" at :262 — the bounds check fails on the
first test. It is written down because a leaf that emits ranges must know
which side of it is safe to generate, and because the manual should
probably say so.

**Note on BAS2-50.** The retargeting rejection was hand-run and produces
a first-class diagnostic naming both targets — `'but if' append branch
targets 'other', but the base statement targets 'out' — a conditional
append branch cannot retarget to a different list/buffer`. It is not kept
as a probe file because a compile-fail fixture for it belongs in the
compiler's own suite, not in a fuzzer ledger whose probes are all programs
that must compile; the diagnostic is recorded here instead.

## Discrepancies

### 1. Loop expansion does not work with "any action that takes an argument" — the buffer-append arm RESOLVED (works now, vox #54/#55 side effect)

**Resolution confirmed, 2026-08-22.** Re-run `D1.vox` against vox 0.4.9:
`append each word from ["ab", "cd"] to sink.` (a buffer) now **compiles
and appends correctly** — `print sink.` prints `abcd`, where it used to
be refused with `Buffer append requires a buffer source: word`. This
matches `vox-notes/REPORT-CANDIDATES-0.4.10.md` candidate F exactly
("`append each word from [...] to <buffer>` was refuted, now compiles —
misread, it works, no defect") and `ROUND-2.md`'s bisect crediting it to
`#54` (named-list arm) and `#55` (inline-literal arm) landing as a side
effect, not a dedicated fix. **This arm of the discrepancy is closed.**
The other two refuted arms (`write each ... to output.`, `Set total to
each ...`) are untouched — re-verified separately, still refused
identically — and the manual-wording question ("any action" overshoots
the enumeration) stands for those two.

LANGUAGE.md:316 says the `each…from` syntax "works with **any** action",
and :312 lists "Any action that takes an argument" as a supported form,
after enumerating four specific ones at :309–311. It is not true of any
action outside that enumeration. Three arms, all hand-run:

| form | result |
|---|---|
| `write each word from ["ab\n", "cd\n"] to output.` | compile error: `Expected value to write` (`BAS2-20.vox`) |
| `append each word from ["ab", "cd"] to sink.` (sink a buffer) | compile error: `Buffer append requires a buffer source: word` (`D1.vox`) |
| `Set total to each number from 1 to 3.` | compile error: `Expected a statement, got Each` |

The second is the sharpest, because both halves are independently legal:
`append "ab" to sink` compiles on a buffer, and `append each number from 1
to 5 to out` compiles on a list (`BAS2-39.vox`). Only the combination
fails, so the expansion path is narrower than the plain path for the same
verb.

**The reading in which the compiler is correct:** the bullet list at
:309–311 is the normative specification and :312 is a summary sentence
that overshoots — "any action" means "any of the action forms above, over
any collection", not "every statement in the language". Under that reading
nothing is broken and the manual needs one word changed. `Set` supports
this reading well: `Set x to each …` would have to mean something the
language has no semantics for (which of the three values?), so its
rejection is clearly right rather than a missing feature. The two `to
<target>` forms are the awkward part for it — `write … to <file>` and
`append … to <list>` are the same shape, and only one expands — but even
there the honest verdict is "the enumeration is the spec", not "the
compiler is wrong". Recorded, not filed.

### 2. A trailing `otherwise` displaces the base action, which rule 4 says should still run

LANGUAGE.md:426–430 gives five numbered rules. Rule 1: "The default action
is the base statement." Rule 4: "If no conditions match, the default
action runs." Rule 5: "An optional trailing `otherwise` clause provides a
final alternative." The rules do not say what happens when 4 and 5 both
apply, and the compiler resolves it by making 5 win outright. `D2.vox`:

```
a list called out is [].
append each number from 1 to 3 to out,
    but if the number modulo 2 is equal to 0 append 0,
    otherwise append 99.
print out.
```

prints `[99, 0, 99]`. On 1 and 3 no condition matched, and the base
statement — `append <the number> to out` — did not run; the `otherwise`
ran instead. Read strictly, rule 4 predicts `[1, 0, 3]`.

**The reading in which the compiler is correct:** rule 5's "final
alternative" means the last branch of the chain, and rule 4 is describing
the chain *without* an `otherwise` — a base action with no catch-all is
the default; a base action with a catch-all has been given an explicit
one. That is also the only reading under which `otherwise` is worth
having: an `otherwise` that ran *in addition to* the base action would
duplicate output, and one that never ran at all would be dead code. So the
compiler is almost certainly right and rule 4 needs the qualifier "and no
`otherwise` clause is present". A manual that contradicts itself is a
discrepancy in its own right, which is why this is recorded rather than
waved through. Not filed.

### 3. A `treating` clause whose types do not match the collection compiles cleanly and segfaults — RESOLVED (vox #55)

**Further confirmed, 2026-08-22 (0.4.10): the manual now documents the
fixed rule directly**, closing what BAS2-59 used to record as an
undocumented precision — LANGUAGE.md:467–471, "Equality is by type as
well as by value... where the compiler can prove the mismatch, it says
so at compile time instead." Re-verified `D3.vox` against 0.4.10:
byte-identical diagnostic to the 0.4.9 finding below.

**Resolution confirmed, 2026-08-22.** Re-run `D3.vox` against vox 0.4.9:
`print each item from ["a"] treating 98 as 31.` no longer segfaults —
it is now a compile error, `Treating value and match must be the same
type (got text vs number).` This is `vox/docs/BUGS_FOUND.md` #55 ("A
`treating` clause whose types do not match the collection segfaults"),
fixed. The account below is the finding as it stood on the pre-release
compiler this ledger was originally mapped against.

LANGUAGE.md:465 says only "If the loop variable equals `<match>`, it's
replaced with `<replacement>` for that iteration." Nothing constrains the
types. `D3.vox`, one line:

```
print each item from ["a"] treating 98 as 31.
```

compiles with no diagnostic and dies with SIGSEGV — deterministic, 6 of 6
runs, exit 139. The same one-liner over a list *variable* crashes
identically, and so does the function-call expansion form (`'display' of
each item from ["a"] treating 98 as 31.`), so this is the `treating`
machinery rather than anything about `print`.

The check is not simply missing: the compiler **does** reject `treating 98
as "z"` and `treating "a" as 31` with `Treating match and replacement must
be the same type` (`BAS2-59.vox`). It compares the match to the
replacement and never to the collection.

**The reading in which the compiler is correct:** there isn't one that
survives `CLAUDE.md`'s framing. Vox promises that no program, however
stupid, segfaults; this program is stupid and legal, the type information
needed to reject it is present at compile time (the collection is a list
literal of text), and the analyzer already performs the adjacent check.
The nearest defensible position is that the element type of a collection
is not always statically known — true for `arguments's all` and for a
`value`-typed list — so a *complete* check is impossible and a partial one
was skipped. That argues for a diagnostic where the type is known and a
runtime guard where it is not; it does not argue for a segfault. Adjacent
data point: the same construct over `arguments's all` does not crash — it
fails in the assembler with `symbol '_str_eq' not defined`, leaking NASM
diagnostics to the user (already noted in the generator at
gen_flow.vox:181–188). Recorded with a minimal repro; **not filed, and not
adjudicated here** — this is precisely the class of finding `CLAUDE.md`
says a worker hands to a human.

### 4. The same unchecked confusion over a mixed list prints a raw pointer instead of crashing — RESOLVED

**Resolution confirmed, 2026-08-22.** Re-run `D4.vox` against vox 0.4.9:
`print each item from [1, "a"] treating 98 as 31.` now prints `1` then
`a` — the text element renders correctly instead of leaking the string
constant's address (`4198536`) as a decimal integer. Likely the same
fix family as D3 (#55) or the mixed-list tag-dispatch work around it;
no separate BUGS_FOUND entry was found naming this exact case, but the
behaviour is unambiguously fixed, re-verified twice. The account below
is the finding as it stood on the pre-release compiler this ledger was
originally mapped against.

`D4.vox`, also one line:

```
print each item from [1, "a"] treating 98 as 31.
```

prints `1` and then `4198536`. The second element is the text `"a"`; the
`treating` clause makes the loop read it as a number, and what comes out
is the address of the string constant rendered in decimal. Deterministic
and independent of where the binary is built — three runs from two
different output directories all printed the same value.

This is listed separately from Discrepancy 3 because the *observable* is
different in a way that matters to the fuzzer: no signal, exit 0, and a
plausible-looking number in the output. A campaign would score this as a
clean run. If the root cause is shared with D3 the fix is one fix, but a
harness that only looks for signals cannot see this one, and an oracle
that only compares exit codes cannot either.

**The reading in which the compiler is correct:** none beyond D3's — with
a mixed list the element type genuinely is not statically uniform, so the
"can't always know" defence is at its strongest here. It still leaks a
memory address into program output. Recorded, not filed.

## Invariants this section justifies

- `each` clause word order is fixed — `each <var> from <collection>`, in
  that order, never permuted — LANGUAGE.md:336, BAS2-14.
- chained `each` clauses are joined by `and`, never by a comma —
  LANGUAGE.md:358–359, BAS2-24.
- a grid's iteration order is always row-major, leftmost clause outermost
  — LANGUAGE.md:359–362, BAS2-25.
- a range always ascends and always includes both endpoints; it never
  counts down — LANGUAGE.md:310, BAS2-06, BAS2-08.
- a `treating` clause always follows its own `each` clause and never
  precedes it — LANGUAGE.md:463, BAS2-56.
- `but if` clauses are always evaluated in written order, so a corpus in
  which an earlier clause always wins over a later one is required, not
  suspicious — LANGUAGE.md:427, 433, BAS2-43.
- a `but if` append branch never names a target — omitting it is the only
  legal form when the base statement has one — LANGUAGE.md:439, BAS2-50.
- an `each` clause's range bounds are always primaries or braced groups,
  never bare arithmetic — LANGUAGE.md:391–393, BAS2-32, BAS2-33.

## Invariants this section does **not** justify

Eight samenesses this surface's leaves currently put in every corpus, none
of which the manual asks for. They are listed here so the next invariant
report has something to diff against, and because each one is a rule
nobody declared:

- **every `print each` carries a `treating` clause.** `gen leaf treating
  print` is the only leaf that emits `print each` at all, and it always
  appends a `treating`. The manual's own `print each number from [1, 2,
  3].` shape has never been generated. (BAS2-05)
- **every `For each` statement range starts at 1.** `from 1 to {…}` at
  gen_flow.vox:426, :434, :463 and gen_misc.vox:177, :212 — five leaves,
  one start value. Grid clauses do vary their start; `For each` never
  does. (BAS2-01)
- **every range bound is a literal in the generated text.** No emitted
  program contains a range bounded by one of its own variables, so the
  variable-bound code path has never been compiled by a campaign.
  (BAS2-04)
- **every function expansion is a grid of two or more clauses.** The
  single-clause `f of each x from Y` — the manual's own example — is never
  emitted. (BAS2-12)
- **every grid argument is an `each` clause.** A fixed argument among the
  clauses is never emitted, in any position. (BAS2-29)
- **every `but if` base is a plain statement**, never a `For each` body
  and never a loop expansion — the inverse of what the manual documents.
  (BAS2-36)
- **`otherwise` follows only `append` chains**, never `print` chains,
  because of a 0.4.5 limitation fixed by bug #50 in `d974da0`. (BAS2-45)
- **every `treating` match/replacement pair is drawn from two shapes** —
  a pair of independent random numbers, or literally `"-"` → `"none"` —
  and the argv branch's pair never varies at all. (BAS2-52, BAS2-57)

## Report

**59 rows** (BAS2-01 through BAS2-59). Nineteen fold into a sibling
(BAS2-03, 09, 11, 14, 15, 16, 17, 19, 21, 26, 30, 41, 42, 44, 46, 48, 49,
54, 56 — six of them only in half, keeping a residual `todo` of their
own), and BAS2-35 is a cross-reference to `collections-b`'s range rather
than a claim. That leaves **39 rows** carrying distinct work.

**How many are assertable: 34 of 39 outright, plus BAS2-02 by proxy.**
The four that a leaf cannot assert at all are claims *about rejection* —
BAS2-20, BAS2-32, BAS2-34, BAS2-59 (and BAS2-50's retargeting half, whose
other half is assertable). A generated program is required to compile, so
a compile error can never be a leaf's business; those belong in the
compiler's own compile-fail fixtures, and are recorded here with their
exact diagnostics instead. BAS2-02 is assertable only by proxy — a
billion-element range that starts iterating instantly. Everything else
the generator can predict exactly, because it chose the collection, the
bounds and the data.

**Where the section stands: 21 rows exercised, 0 verified, 25 carrying a
`todo`.** Zero verified is not a per-row surprise — it is the same
uniform gap `buffers.md` found, confirmed one section over: the only
assertions any generated program makes are the argv flag checks at exits
91–94 (`gen emit argv assertions`), and nothing on this surface asserts
anything at all.

**The biggest finding is that the generator emits the *undocumented* form
of `but if` and none of the documented ones.** LANGUAGE.md:400 scopes
`but if` to `for each` loops and loop expansion. Both existing leaves hang
their chain off a plain `Print`/`append` statement — a context the manual
never mentions, which works (BAS2-51), and which is the only `but if`
shape any campaign has ever compiled. Every worked example in the section
— FizzBuzz, even/odd, the append override, the `For each` + predicate form
— is therefore untested, and so is the whole interaction between `but if`
and a loop variable. That is a bigger hole than any individual `todo`
row, because it means the four examples the manual leads with have never
been near the compiler in this project.

Close behind it: **`append each`, `open … at each`, and the single-clause
`f of each x from Y` appear in no leaf at all.** The generator's function
expansion is *only* ever a two-or-more-clause grid, which is the advanced
form; the basic one in the manual's own example has never been generated.
And every range bound in every emitted program is a compile-time literal —
the same trap BUF-21 found for byte indices, one section over and
independently.

**Four discrepancies**, all with minimal repros, none filed and none
adjudicated:

1. "Any action that takes an argument" is false — three arms, all compile
   errors, one of them (`append each <text> to <buffer>`) a case where
   both halves are separately legal.
2. A trailing `otherwise` displaces the base action, contradicting the
   manual's own rule 4 two lines above it. The manual contradicts itself
   here rather than contradicting the compiler.
3. **A one-line program compiles cleanly and segfaults**: `print each item
   from ["a"] treating 98 as 31.` The compiler checks the `treating`
   match against the replacement but never against the collection.
   Deterministic, 6/6, exit 139. Under `CLAUDE.md` this is a broken
   memory-safety promise and top severity.
4. The same confusion over a mixed list does not crash — it prints a raw
   pointer (`4198536`, stably) and exits 0. Worth separating because no
   signal-based harness can see it.

**For the master, one thing that needs a decision before any leaf is
built:** `gen leaf butif print`'s comment at gen_flow.vox:113–125 records a
hand-verification that is now wrong. `otherwise` after a `print` chain was
rejected under the 0.4.5 binary and is accepted under this one — bug #50,
fixed in `d974da0`, which the comment predates. The comment is careful and
well-argued, which is exactly why it will be believed by the next worker.
It needs deleting along with the restriction it justifies, and BAS2-45's
print half becomes free coverage.

**Three things the brief got wrong, mapped as found rather than as
written** (per its own instruction to say so):

- It names the section **Variables**. Lines 260–427 are not Variables —
  they are the tail of **Basics**: Ranges, Loop Expansion, chained `each`
  clauses, `but if` and `treating`. `INDEX.md`'s own BAS2 entry describes
  the range correctly; Variables is VAR at 446–644. The line range is
  right and this ledger maps what is actually there.
- It calls for probes named `THG-NN.vox`. `THG` is the Things prefix;
  this section's prefix is `BAS2`, and PROCEDURE.md §4 names a probe for
  the row it proves. The probes are `BAS2-NN.vox`.
- It calls for the ledger at `docs/ledger/expansion.md`, which is where
  it is. `INDEX.md` reserves the name **`basics-expansion.md`** for BAS2.
  Renaming is the master's call, not a worker's — but the two names need
  reconciling, and if the file moves, `docs/ledger/probes/expansion/`
  should move with it so the slug still matches.

**For the next mapper**, three things this section taught:

- **A leaf's own comment is evidence about the compiler *at the time it
  was written*, not about the compiler you are running.** gen_flow.vox:113
  cost nothing here only because the probe was run anyway. Re-run the
  hand-verifications a leaf claims, especially the ones that justify *not*
  emitting something — a stale restriction is invisible in a campaign,
  because the construct it forbids simply never appears.
- **When the manual enumerates and then generalises, probe the
  generalisation.** "Works with: [four bullets]" followed by "Any action
  that takes an argument" is the shape of Discrepancy 1, and it is a shape
  that recurs — a bullet list is testable, and the sentence after it is
  where the overreach lives.
- **Probe the type mismatches, not just the happy path.** Discrepancies 3
  and 4 came from feeding a construct two arguments of the wrong type,
  which took one line each and found a segfault and a pointer leak. Every
  clause in this section that takes two values — `treating`'s match and
  replacement, a range's two bounds, `but if`'s condition and action — is
  a place to try that, and the manual almost never says what the types
  must be.
