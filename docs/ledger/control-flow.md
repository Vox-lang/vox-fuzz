# Claim ledger: Control Flow

Source: `../vox/LANGUAGE.md` lines **2073–2240**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual) — Control Flow, through If Statement,
While Loop, For Each Loop, Repeat, Loop Control, Program Termination,
Increment/Decrement.

The 0.4.8→0.4.9 drift in this range is a uniform **+38 lines**, confirmed
at multiple anchors before applying it mechanically. All three
discrepancies (still unadjudicated — no prior lawyer verdict) re-verified
unchanged: the full `docs/check-probes.sh` sweep of this directory now
passes 45/45 (previously 37/45 — 8 false failures came from a
`check-probes.sh` bug, not compiler drift, fixed below).

**Found and fixed a `check-probes.sh` bug affecting probes across
several ledgers, not just this one.** The master's stricter PASS
condition (exit code match must also match stdout, unless empty or a
`Segmentation` line) only stripped the *parenthesized* exit annotation
(`(exit 42)`) from the recorded block before comparing — but many probes
across this repo (control-flow, expressions, functions, process-control,
time — 15 files found by grep) use the *bare* convention, a line reading
just `exit 42` with no parens, which the brief explicitly names as a
convention the script must accept. `check-probes.sh` now strips both
forms. This is a script fix, not a probe reword, per the brief's
instruction not to reword probes to fit the checker.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct, or `none`, and was found by
grepping the emitted keyword in `src/gen_*.vox` — never by leaf name.
That distinction earned its keep immediately here: `gen leaf butif print`
and `gen leaf butif append` do **not** cover FLW-03. They emit
`<action>, but if <cond> <action>`, the generic conditional-branch clause
of LANGUAGE.md:431–478 and :3014 (no `then`, attaches to a base action);
the If statement's `But if <condition> then, <statement>` at :2050 is a
different construct and **nothing in the generator emits it**.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` set to
the sibling `coreasm`) before being written.

As in `buffers.md`, **no existing leaf in this section asserts anything**
— every one prints for a human to eyeball — so nothing here is marked
`verified`. That gap is uniform and is a finding about the leaf library,
not about any one row.

## Probes

One retained probe per hand-verified row, in
`docs/ledger/probes/control-flow/`, named `FLW-NN.vox`. A probe covering
more than one row is named for the first and says so in its header:
`FLW-03` also covers FLW-07, `FLW-04` also covers FLW-05 and FLW-06,
`FLW-09` also covers FLW-10, `FLW-43` also covers FLW-44. Rows with no
probe file of their own are exactly those four followers (FLW-06, FLW-10,
FLW-44 — FLW-05 and FLW-07 have their own extra probes anyway).
`FLW-33` is a **compile-error** probe: it records the diagnostic rather
than output, and `check-probes.sh` passes it only if vox still refuses the
program. The three Discrepancies have dedicated minimal repros at
`D1.vox`, `D2.vox`, `D3.vox`.

**45 probe files, all re-run in one final pass: 45 passed, 0 failed, 0
skipped** (`docs/check-probes.sh docs/ledger/probes/control-flow`).

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FLW-01 | 2186–2188 | `If <condition> then, <statement>.` runs the statement only when the condition is true. | emit an If with a known-true and a known-false condition, assert only the true branch's marker was reached | yes — generator picks the condition, so it knows which branch fires: `If reached is not 1 then, Exit 95.` | `gen leaf rich condition` (gen_core.vox:488), `gen if` (gen_flow.vox, block form), argv assertions (gen_misc.vox:316–321), predicate leaves (gen_misc.vox:431–435) | exercised | |
| FLW-02 | 2191–2193 | `Otherwise,` is the else branch and is taken exactly when the condition is false. | emit both a false-condition and a true-condition If/Otherwise pair, assert which branch ran | yes — set a witness number in each branch and assert it | `gen leaf rich condition`, gen_files.vox:139, gen_text.vox:493, gen_misc.vox:217/220/222/431/433/434/435 | exercised | |
| FLW-03 | 2196–2198 | `But if <condition> then,` is an else-if arm; arms are tested in order, first match wins, `Otherwise` catches the rest. | emit a 2–4 arm chain and drive it with a value the generator chose, assert only the matching arm's witness | yes — the generator picks the discriminant, so it knows the arm | **none** — `gen leaf butif print`/`butif append` emit the *other* `but if` (LANGUAGE.md:431–478: `<action>, but if <cond> <action>`, no `then`). Nothing emits `But if ... then,`. | todo — real gap, hand-verified to work | |
| FLW-04 | 2201 | Each `then,` / `but if ... then,` / `otherwise,` branch consumes actions until the sentence ends. | emit multi-action arms in all three positions, assert every action in the taken arm ran and none from the others | yes — count the witnesses | `gen leaf rich condition` emits one action per arm only; nothing emits a multi-action arm | todo (multi-action arms) | |
| FLW-05 | 2202 | Several actions in one branch are separated by commas. | as FLW-04, specifically in the `Otherwise` arm | yes | none (all existing arms are single-action) | todo | |
| FLW-06 | 2203 | A period ends the full `if` sentence — what follows is unconditional. | emit an If whose condition is false, followed by a period and a marker, assert the marker ran | yes | every If-bearing leaf ends its sentence with a period via `gen join lines`, but none asserts that the following statement ran unconditionally | exercised (construct); todo (verification) | |
| FLW-07 | 2204 | A period before `but if`/`otherwise` does not end the chain when the chain continues — including across a newline. | emit an If whose `Otherwise` sits on its own line after the closing period, assert the else branch is still conditional | yes — drive it with a true condition and assert the else witness did **not** fire | none — every emitted `Otherwise` is on the same line as its `then,` arm | todo | |
| FLW-08 | 2206–2208 | Worked example: `If ready then, print "a", print "b", print "c".` prints a, b, c. | reproduce verbatim | yes — output is fixed | none (composite of FLW-01/04/05, all separately covered) | todo (as a composite) | |
| FLW-09 | 2211 | `When` can replace `If`. | draw the head keyword from {`If`, `When`} per emission | yes — semantics identical, so any FLW-01 assertion works under either spelling | **none** — `When` appears nowhere in any emitted string | todo — trivially cheap, and its absence is a fixed-vocabulary invariant | |
| FLW-10 | 2212 | `Else` can replace `Otherwise` (after `If` as well as after `When` — hand-verified both). | draw the else keyword from {`Otherwise`, `Else`} per emission | yes, same as FLW-02 | **none** — `Else` appears nowhere in any emitted string | todo — same fixed-vocabulary invariant | |
| FLW-11 | 2218–2220 | `While <condition>, <statements>.` repeats while the condition holds, and runs zero times when it is false at entry. | emit a bounded While with a generator-chosen trip count, assert the counter's final value; also emit one whose condition is false at entry and assert the body never ran | yes — the generator picks start and limit: `If u1 is not 10 then, Exit 95.` | `gen leaf while` (gen_flow.vox:272), `gen leaf loop break while`, `gen leaf loop continue while` — all print the counter, none asserts it | exercised | |
| FLW-12 | 2222–2225 | Manual example: `While the counter is less than 10, print the counter, increment the counter.` — the `the` article on the loop counter, lowercase keywords. | emit the article form, and vary the keyword case | yes (same assertion as FLW-11) | none — **no emitted statement uses `the` as an optional article on a variable reference** (the only `the` in any emitted string is the mandatory one in `To do the t4's 'made at'`, gen_things.vox:124), and every loop keyword is emitted in one fixed case | todo — a fixed-vocabulary invariant the manual's own examples contradict | |
| FLW-13 | 2227–2231 | A multi-action While body is comma-separated in one sentence and every action runs on every iteration. | emit a While with 2–4 body actions, assert per-action witness counts equal the trip count | yes | none — `gen leaf while`'s body is always exactly one `Increment`; the loop-control While leaves are a fixed 3-action shape | todo (variable-width body) | |
| FLW-14 | 2233–2240 | Worked example: a While inside a function body works — composite (`is less than or equal to`, bare `total is total add i` assignment as a loop action, `Return a number, total.` after the loop's own period). `sum of 4` is 10. | emit a `To` definition whose body contains a loop, then call it and assert the return | yes — closed-form sum, generator knows it | **none** — every emitted function body (`f1`–`f4`, `grid sink N`, `read flags N`, thing methods) is a fixed straight-line shape; no generated `To` body has ever contained a loop | todo — real gap, and the one that most changes what the compiler sees | |
| FLW-15 | 2246–2249 | `For each number from <start> to <end>,` — bounds may be literals or variables. | emit both literal- and variable-bounded ranges, assert the iteration count | yes — `If seen is not 3 then, Exit 95.` | `gen loop` (gen_flow.vox), gen_misc.vox:177 and :212, the four loop-control leaves — all literal bounds | exercised (literal bounds); todo (variable bounds — no leaf emits a range bound that is a runtime variable) | |
| FLW-16 | 2251–2254 | `For each number from 1 to 10, print the number.` — the range is inclusive of both bounds. | emit a range and assert the count is `end - start + 1` | yes | as FLW-15; nothing asserts inclusivity | exercised (construct); todo (verification) | |
| FLW-17 | 2256–2257 | Inside the loop `the number` is the current iteration value (bare `number` is the same value). | accumulate the loop variable and assert the closed-form sum | yes — `If total is not 18 then, Exit 95.` | `gen leaf loop break/continue foreach` print bare `number`; nothing sums or asserts it, and nothing emits the `the` form | exercised (bare form); todo (verification, and the article form) | |
| FLW-18 | 2259–2262 | `For each <variable> in <list>, <statement>.` binds the loop variable to each element in order. | emit a list of generator-chosen elements and assert the concatenation/sum matches | yes — the generator wrote the list | gen_collections.vox:73 (`For each w{n} in l{n}, Print w{n}`), gen_collections.vox:48 (over `m{n}'s keys`) | exercised | |
| FLW-19 | 2264–2268 | Manual example: `a list called nums is [1, 2, 3].` / `For each n in nums, print the n.` prints 1, 2, 3. | reproduce verbatim, including the `the` on the loop variable | yes | none uses the article form | todo (article form); exercised (bare form, via FLW-18's leaf) | |
| FLW-20 | 2248 (undocumented precision) | *(gap in the manual)* A range whose start exceeds its end runs the body **zero** times — not once, not an error. | emit an inverted range, assert the body never ran | yes | none — every emitted range is drawn so start ≤ end | todo — hand-verified | |
| FLW-21 | 2261 (undocumented precision) | *(gap)* The list form over an **empty** list runs the body zero times, no error. | emit `For each x in [], ...`, assert the body never ran | yes | `gen leaf treating print` iterates `arguments's all` (always empty in this generator), but over the *expansion* clause, not the `For each ... in` form, and asserts nothing | todo | |
| FLW-22 | 2256–2257 (undocumented precision) | *(gap — see **Discrepancy 3**)* The loop variable outlives the loop: after the range form it holds `end + 1`; after the list form it holds the last element. | read the loop variable after the loop and assert the value | yes, once adjudicated — the generator knows both `end` and the last element | none | todo — **blocked on D3** | |
| FLW-23 | 2272–2278 | `Repeat <count> times, <statements>.` runs the body exactly count times; the count may be a variable. | emit a Repeat with a generator-chosen count, assert the counter equals it | yes — `If r1 is not 7 then, Exit 95.` | `gen leaf repeat` (gen_flow.vox:286) — literal count only, prints without asserting | exercised (literal count); todo (variable count, verification) | |
| FLW-24 | 2280–2283 | `Repeat 3 times, print "hello".` prints hello three times. | reproduce | yes | `gen leaf repeat` | exercised | |
| FLW-25 | 2285–2292 | A multi-action Repeat is comma-separated exactly like While: `Repeat 2 times, print "a", print "b".` prints a, b, a, b — interleaved, not grouped. | emit a 2–4 action Repeat body, assert the interleaving order | yes — the output sequence is fully determined | none — `gen leaf repeat`'s body is always a single `Increment` | todo — real gap, and the exact shape that was a compile error before compiler bug #27 was fixed in v0.4.6 | |
| FLW-26 | 2294–2303 | A period ends the Repeat body and closes the construct; the statement after it belongs to the surrounding scope and runs once. | emit `Repeat N times, <action>.` then a following statement, assert the following statement ran exactly once | yes — witness count of 1 vs N is the whole test | **none, and the generator actively avoids this shape**: `gen leaf repeat` emits a blank line before its closing `Print`, working around compiler bug #27 — which was **fixed in v0.4.6** (FLW-26's probe is the regression guard). The workaround is now an unjustified invariant. | todo — see Report | |
| FLW-27 | 2296 | A blank line force-closes a Repeat (termination rule 2). | emit the blank-line form, assert the following statement ran once | yes | `gen leaf repeat` — this is the only Repeat closing form the generator emits | exercised | |
| FLW-28 | 2305–2315 | Periods stack: a Repeat nested in another loop takes two periods to close both. `For each n from 1 to 2,` + `Repeat 2 times, print "r"..` gives four `r`s then `after`. | emit a nested loop pair closed by stacked periods, assert the product count and that the following statement ran once | yes — count is `outer × inner` | none — no leaf nests a Repeat inside anything, and `gen leaf repeat` is reachable only at the true top level | todo | |
| FLW-29 | 2277 (undocumented precision) | *(gap)* A Repeat count of 0, or a negative count, runs the body zero times — no error, no wraparound, no hang. | emit a zero and a negative count, assert the body never ran | yes | none — the count is always drawn `'rng below' of 8 add 1`, i.e. 1–8, never 0 or negative | todo — hand-verified | |
| FLW-30 | 2319–2320 | `Break.` leaves the loop immediately: the rest of the body is skipped on the breaking iteration and no further iterations run. | emit a guarded Break at a generator-chosen iteration, assert the witness count equals the guard | yes — the generator picks the guard, so it knows exactly how many iterations ran | `gen leaf loop break foreach`, `gen leaf loop break while` (gen_flow.vox:426/444), gen_misc.vox:179 — all print, none asserts | exercised | |
| FLW-31 | 2319, 2321 | `Continue.` skips the rest of the body and goes to the next iteration; the loop still runs to completion. | emit a guarded Continue, assert the witness count is `trips - 1` | yes | `gen leaf loop continue foreach`, `gen leaf loop continue while` (gen_flow.vox:434/455) | exercised | |
| FLW-32 | 2317–2322 (undocumented precision) | *(gap)* `Break` and `Continue` work inside a `Repeat` as well as inside `For each`/`While`. The manual's Loop Control section names no construct at all. | emit Break and Continue inside a Repeat body | yes, same assertions as FLW-30/31 | none — `gen leaf loop control` covers exactly four combinations, all For-each or While; Repeat is not among them | todo — hand-verified to work | |
| FLW-33 | 2317–2322 (undocumented precision) | *(gap)* Outside any loop, `Break.`/`Continue.` are a **compile error** ("Break is only valid inside a loop"), not a runtime no-op. | — | **no, not by a generated program** — the generator's invariant is that everything it emits compiles; this is a claim about a *rejected* program, so it belongs to a negative-corpus harness, not a leaf | n/a | not assertable (by a leaf) — hand-verified, probe retained | |
| FLW-34 | 2324–2329 | `Exit <code>.` exits immediately with that code; statements after it never run. | emit an Exit with a chosen code, assert the harness saw that exit status | yes — but the assertion is the **harness's**, not the program's; the generator already records the expected code | `gen program` (gen_core.vox:1074) emits `Exit {code}.` as the tail of **every** program, code drawn 0–255 skipping the reserved 91–94; argv assertions (gen_misc.vox:316–321) emit `Exit 91`–`94` | exercised | |
| FLW-35 | 2334 | `Exit 0.` — success. | let the tail draw hit 0 | yes (harness-side) | `gen program`'s tail draw reaches 0 | exercised | |
| FLW-36 | 2335 | `Exit 1.` — general error. | as FLW-35 | yes (harness-side) | same | exercised | |
| FLW-37 | 2337–2339 | Worked example: an `arguments's empty` usage guard that prints usage and exits 1. | reproduce the example | yes — and it **does not behave as written**: see **Discrepancy 1** | none | todo — **blocked on D1**; do not build a leaf from this example until it is adjudicated, because a leaf copying it would emit a program that exits 1 unconditionally | |
| FLW-38 | 2343 | The exit code defaults to 0 when it is not specified — bare `Exit.` compiles and exits 0. | emit a bare `Exit.` sometimes instead of `Exit <code>.` | yes (harness-side: expect 0) | **none** — every emitted Exit carries an explicit code | todo — and this is the fix for the "every program ends with `Exit <code>.`" invariant | |
| FLW-39 | 2344 | All resources are automatically cleaned up before exit. | — | **no** — there is no observation point after `Exit` inside the exiting program. Hand-checked out of band: a file handle written to and never closed still has its bytes on disk after `Exit 3`. Probe retained; `check-probes.sh` can only confirm the status. | n/a | not assertable | |
| FLW-40 | 2345 | `quit` is an alternative keyword for `Exit`, and takes a code. | draw the termination keyword from {`Exit`, `quit`, `terminate`} | yes (harness-side) | **none** — `quit` appears nowhere in any emitted string | todo — fixed-vocabulary invariant | |
| FLW-41 | 2345 | `terminate` is an alternative keyword for `Exit`, and takes a code. | as FLW-40 | yes (harness-side) | **none** | todo | |
| FLW-42 | 2329 (undocumented precision) | *(gap)* The code is the POSIX process status and is therefore taken modulo 256: `Exit 300.` leaves status 44. The code may also be a variable, not only a literal. | emit codes above 255 and variable-valued codes, and have the harness expect `code modulo 256` | yes (harness-side) — but note the reserved 91–94 band must be computed **after** the modulo, or a drawn 347 would land on 91 | `gen program` draws below 256 and so never crosses the boundary; no emitted Exit takes a variable | todo — matters to the runner's exit-code classification, not just to coverage | |
| FLW-43 | 2349–2350 | `Increment the counter.` adds one to a number. | emit an Increment on a known value, assert the result | yes — `If counter is not 6 then, Exit 95.` | `gen leaf while`, `gen leaf repeat`, both loop-control While leaves (gen_flow.vox:272/286/444/455) — always as loop-progress, never asserted, and always the article-free spelling | exercised | |
| FLW-44 | 2351 | `Decrement the value.` subtracts one. | emit a Decrement on a known value, assert the result | yes | **none** — `Decrement` appears nowhere in any emitted string | todo — real gap, one keyword wide | |
| FLW-45 | 2347–2352 (undocumented precision) | *(gap — see **Discrepancy 2**)* `Increment`/`Decrement` are number-only, and the compiler says so two different ways: on a `text` it refuses the program ("Increment requires a number variable"); on a `float` it is a **silent no-op**. | assert a float is unchanged after an Increment (once adjudicated) | yes for the float half; the text half is a compile-error claim, not a leaf claim (as FLW-33) | none | todo — **blocked on D2** | |

## Discrepancies

### 1. The manual's usage-guard example does not guard — `Exit 1.` runs unconditionally

LANGUAGE.md:2337–2339, under **Program Termination → Examples**:

```
If arguments's empty then,
    Print "Usage: ./program <file>".
    Exit 1.
```

Read as written, this is the canonical "no arguments? print usage and
bail" idiom, and it is presented as a working example of `Exit`. It is
not one. `Print "Usage: ./program <file>".`'s period closes the `If`
(termination rule 1, LANGUAGE.md:192 — a period closes the innermost open
clause), so `Exit 1.` is a **top-level statement** and the program exits 1
no matter what the condition was. The indentation is doing no work.

Repro without argv (`D1.vox`), condition deliberately false:

```
a boolean called 'the arguments are empty' is false.
If 'the arguments are empty' then,
    Print "Usage: ./program <file>".
    Exit 1.
Print "reached the real work".
```

Output: **nothing at all**, exit status **1**. The guard body was
correctly skipped — no usage line — and the program still exited 1, and
`Print "reached the real work"` never ran.

Confirmed the same way with real argv (`FLW-37.vox` is the manual's text
verbatim): with no arguments it prints the usage line and exits 1, which
is why the example looks right; with `./p somefile.txt` it prints nothing
and still exits 1.

The comma form is the working guard, and differs by one character:

```
If arguments's empty then,
    Print "Usage: ./program <file>",
    Exit 1.
Print "reached the real work".
```
→ no arguments: usage line, exit 1. With an argument: `reached the real
work`, exit 0.

**The reading in which the compiler is right:** it plainly is right. Rule
1 is explicit, LANGUAGE.md:281 restates it for `Otherwise`, and the
Repeat section three subsections earlier (2141–2150) spends a paragraph
on exactly this — "the statements after a closing period belong to the
surrounding scope, not the loop". The compiler is applying the rule the
manual states. What is wrong is the **example**, which is written in an
indentation-scoped style Vox does not have, in the one section where the
consequence is invisible in the common case (no arguments) and silent in
the other. This is the same family as the `Repeat` bug #27 finding: wrong
behaviour with no diagnostic.

Two things follow for this ledger, both recorded rather than acted on:
FLW-37 must not have a leaf built from it until this is adjudicated, and
the same shape should be checked wherever else the manual uses a
multi-line indented If body with period-terminated statements.

Not filed. Not decided.

### 2. `Increment` on a `float` is a silent no-op; on a `text` it is a compile error

LANGUAGE.md:2350–2352 gives `Increment the counter.` / `Decrement the
value.` with no stated operand type. Repro (`D2.vox`):

```
a float called rate is 2.25.
Increment rate.
print rate.
```
Output: `2.25`. No warning, no error, no change. `Decrement` behaves the
same (`FLW-45.vox` runs both against 2.25 and prints 2.25 three times).

The contrast is what makes this a discrepancy rather than a
documentation gap. The same statement on a `text`:

```
a text called label is "hi".
Increment label.
```
```
error: Increment requires a number variable: label
  --> ...:2:11
```

So the compiler **does** have a rule — "Increment requires a number
variable" — and enforces it on `text`. A `float` is not a number variable
either, yet it passes the check and then does nothing.

**The reading in which the compiler is right:** `Increment` is documented
only for the `number` type; a `float` operand is outside the documented
domain, so its behaviour is unspecified, and doing nothing is at least a
safe choice — nothing is corrupted and no wrong number is produced. One
can also argue the type check is deliberately permissive across the
numeric types and the codegen for the float case is simply absent rather
than wrong.

That reading holds for memory safety and fails for usability: a silent
no-op on a statement whose entire purpose is a side effect is the bug #5
family (silently required or silently ignored syntax that changes meaning
without a diagnostic), and it is worse than the `text` case precisely
because the `text` case is caught. The narrow fix would be to extend the
existing diagnostic to cover `float`; the wide one would be to make
`Increment` work on floats. Either is a language decision.

Not filed. Not decided.

### 3. The loop variable outlives its loop, holding `end + 1` (range) or the last element (list)

LANGUAGE.md:2256–2257 introduces the loop variable under the heading
**"Inside the loop:"** — "`the number` refers to the current iteration
value". The section says nothing about the variable's existence outside
the loop. Repro (`D3.vox`):

```
For each number from 1 to 3, print the number.
print the number.
```
Output: `1 2 3 4`.

The list form leaks too, holding the last element (`FLW-22.vox`):

```
a list called nums is [10, 20, 30].
For each entry in nums, print the entry.
print the entry.
```
→ `10 20 30 30`.

**The reading in which the compiler is right:** the manual never says the
loop variable is scoped to the loop — it says what the name *means*
inside it, which is the thing a reader needs. Vox has no block scoping to
appeal to (declarations survive their enclosing clause; the only scoping
rule this manual states is the branch rule about declaring in some
branches and not others). Under that reading, `For each number from 1 to
3,` implicitly declares `number` in the enclosing scope, exactly as a
hand-written `While` counter would be, and `4` is the honest value of a
counter that has just failed its test — the same value the equivalent
`While` leaves behind. Nothing is undefined and nothing is unsafe.

What makes it worth a decision is that `end + 1` and "the last element"
are two different post-loop conventions in one construct, neither is
written down, and `4` is precisely the value a reader expecting `3` would
misread as an off-by-one. Either the manual should state it or the name
should not resolve outside the loop.

Not filed. Not decided.

## Invariants this section justifies

- `then,` follows every `If`/`When` condition — LANGUAGE.md:2187, FLW-01
- a comma follows every loop head (`While <cond>,`, `For each … ,`,
  `Repeat <count> times,`) — LANGUAGE.md:2219/2097/2124, FLW-11/15/23
- `times` follows every `Repeat` count — LANGUAGE.md:2277, FLW-23
- `Break`/`Continue` never appear outside a loop — FLW-33 (compile error;
  undocumented but hard-enforced)
- `Exit`'s code, when present, is a number — LANGUAGE.md:2329, FLW-34

Everything else this section's constructs show as invariant is **not**
justified by it. The ones the current corpus will show, with the row that
supplies the variation:

- a blank line after every `Repeat` — was justified by compiler bug #27,
  **fixed in v0.4.6**; FLW-26/27 show both closing forms work now
- every program ends with `Exit <code>.` — no rule requires a trailing
  `Exit` at all, and FLW-38 documents the bare `Exit.` form
- every `Repeat` body is one `Increment` — FLW-25
- every `While` body is one `Increment` (or one fixed 3-action shape) —
  FLW-13
- `Otherwise` always shares a line with its `then,` arm — FLW-07
- every branch arm holds exactly one action — FLW-04/05
- no emitted statement uses `the` as an optional article on a variable
  reference — FLW-12/17/19, whose manual examples all use it
- the fixed keyword vocabulary `If`/`Otherwise`/`Exit`: `When`, `Else`,
  `quit`, `terminate` are never emitted — FLW-09/10/40/41
- `Break`/`Continue` only ever appear in `For each`/`While` — FLW-32
- `Decrement` is never emitted — FLW-44
- no generated function body contains a loop — FLW-14

## Report

**45 rows** (FLW-01 … FLW-45), covering LANGUAGE.md 2035–2202. Two are
**not assertable by a leaf** — FLW-33 (a claim about a program the
compiler *rejects*, which a generator whose invariant is "everything it
emits compiles" cannot make) and FLW-39 (resource cleanup, no observation
point after `Exit`). The other **43 are assertable**, and unusually
cheaply: control flow is the section where the generator most obviously
knows the answer, because it chose the trip count, the guard, the branch
discriminant and the exit code itself. Eight of the 43 assert
**harness-side** rather than in-program (the `Exit` family, FLW-34–42):
the program cannot observe its own exit status, but the runner already
records the expected code.

**Current state: 18 exercised, 0 verified, 25 todo, 2 not assertable.**
The buffer ledger's headline finding repeats here exactly — *no leaf in
this section asserts anything*. `gen leaf while` prints its counter,
`gen leaf repeat` prints its counter, the four loop-control leaves print
markers, and not one of them checks a value. The next worker's job on
this section is mostly adding assertions to constructs already being
emitted, not new constructs.

**Biggest finding: `gen leaf repeat` is working around a compiler bug that
was fixed a release ago.** `src/gen_flow.vox`'s comment states that "a
period never closes a Repeat body, in any nesting, at any depth — only a
blank line does" and emits a blank line before the Repeat's closing
`Print` because of it. That was compiler bug #27, found against v0.4.5
and **fixed in v0.4.6** (`vox/docs/BUGS_FOUND.md:1223`); the manual's
Repeat → Termination subsection (2141–2162) was written to document the
fixed behaviour. FLW-26 and FLW-28 both reproduce cleanly against v0.4.8:
the period closes, and stacked periods close two levels. The
consequences: a blank line after every generated `Repeat` is now an
**unjustified invariant**; the entire period-closing path — which is what
a human writes — is **never generated**; and the multi-action Repeat
(FLW-25), which was a compile error before the fix and is now the
manual's own example, is still not emitted. Correcting this is a
comment-and-leaf change in one function, and it is the highest-value
single edit this ledger points at. *(I did not make it — the brief scopes
me to documents and probes, not `src/`.)*

**Three discrepancies**, all with repros, none filed:
1. The manual's usage-guard `Exit` example (2184–2186) exits 1
   unconditionally — its indentation implies a block Vox does not have,
   and the period closes the `If`. Silent, and invisible in the
   no-arguments case the example is about.
2. `Increment`/`Decrement` on a `float` is a silent no-op, while the same
   statement on a `text` is a compile error — the compiler has a rule and
   `float` slips past it.
3. The loop variable outlives its loop, holding `end + 1` after a range
   loop and the last element after a list loop. Undocumented, and the two
   halves are different conventions.

**Advice for the next mapper.**

*Grep the emitted construct, not the leaf name, and read what the leaf
actually emits.* `gen leaf butif print` and `gen leaf butif append` look
exactly like coverage of FLW-03, are named for it, and cover a different
language construct in a different chapter (`<action>, but if <cond>
<action>`, LANGUAGE.md:431). Had I trusted the names, the else-if chain —
which nothing emits — would have been marked `exercised` and never built.

*Check the compiler's bug list before believing a generator comment about
the compiler.* `gen_flow.vox` carries a long, careful, correct-when-
written comment about bug #27 that is now false. Any generator comment
asserting "the compiler cannot do X" should be re-run against the pinned
binary while mapping, and `BUGS_FOUND.md` grepped for a `fixed in vN`
line. Stale workarounds are undeclared rules with a paper trail — the
easiest kind to justify wrongly.

*Fixed keyword vocabulary is this manual's most common unjustified
invariant, and it is nearly free to fix.* Five rows here (FLW-09, 10, 40,
41, plus the article forms in 12/17/19) are single documented synonyms
that no leaf has ever emitted. Any section with an "Alternative keywords"
bullet will have the same shape. Grep the *synonym* as well as the
primary spelling before writing `exercised`.

*Separate compile-error claims from leaf claims early.* A claim that some
program is **rejected** (FLW-33, the `text` half of FLW-45) is not a leaf
claim at all — the generator's standing invariant is that what it emits
compiles. These need a negative corpus, or they need to be marked `not
assertable (by a leaf)` and left. Deciding that per row while mapping is
much cheaper than discovering it while building.

**Sidebar, noticed while running the gate, and not mine to act on.**
`docs/check-probes.sh` over *all* probe directories is
**103 passed, 4 failed** against v0.4.8. This section's 45 files all pass;
the four failures are pre-existing probes whose recorded output has
drifted, and every drift looks like a **fix**:

- `buffers/BUF-14.vox` and `buffers/D2.vox` — a sized buffer's `type` now
  reports `Buffer (static)`, not `Text (dynamic)`. That is buffer
  Discrepancy 2, apparently resolved.
- `values/D1.vox` — the conditional-value-return segfault repro now exits
  **0** instead of 139. That is values Discrepancy 1, apparently resolved.
- `values/VAL-19.vox` — now prints `fallback` / `Text (dynamic)` where
  `4210906` / `Number (dynamic)` was recorded.

Those two ledgers were mapped against a pre-0.4.8 compiler. Their rows
and open discrepancies need re-checking before the human adjudicates
them — three of the five open discrepancies in `INDEX.md` may already be
closed.
