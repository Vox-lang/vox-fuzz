# Claim ledger: Dynamic Values (`value`) and `nothing`

Source: `../vox/LANGUAGE.md` lines **2436–2659** (manual version **0.4.7**):
the `value` type (§Dynamic Values) and `nothing` (§Nothing, the absent
value). Row prefix **`VAL`**.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct (checked by `grep` on the
accessor/keyword, never by leaf name), or `none`. `status` follows
PROCEDURE.md §3.

**No existing leaf in this section asserts anything** — the same uniform
gap the buffers ledger found. The two leaves that touch `value` at all
(`gen leaf value roundtrip`, `gen leaf text value`) declare a value local,
print it, and (the roundtrip leaf) reassign it across the type boundary —
all `Print`-and-eyeball, no `If … is not … then, Exit 95.`. No leaf emits
a `value` parameter or return, an `is a <type>` predicate, an in-place
retype, the `type` property, a `nothing` literal, or `is nothing`. So
nothing here is marked `verified` under the brief's definition, and most
rows are `todo`.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` pinned to
the sibling `coreasm`) before being written. The Discrepancies section
gives minimal repros for the two that matter — one of them a deterministic
segfault on a valid, compiling program.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/values/`, one file per row named `VAL-NN.vox`. A probe
covering more than one row is named for the first and says so in its header
(`VAL-21.vox` also covers VAL-22; `VAL-25.vox` also covers VAL-31). Each
file opens with a `(...)` comment naming the claim, the `Ran:` command, and
an `expected output:` block recording what the compiler actually printed.

Rows with no probe file: VAL-01 (the tag-carries-across-the-call claim is
exercised through VAL-03/VAL-05, which are the observable forms of it),
VAL-02 (a declaration-forms index; each form is probed on the row that uses
it — local on VAL-07, param on VAL-03, return on VAL-05), VAL-04 (folded
into VAL-03/VAL-05 — a value param's predicate dispatch and tag-preserving
forward are those two probes), VAL-16 (a usage recommendation folded into
VAL-14), VAL-20 (a documentation pointer, not a behavior), and the four
compile-error rows VAL-08, VAL-17, VAL-24, VAL-28 whose probes ARE retained
but which produce no binary. That is **24 `VAL-NN.vox` probe files** for the
24 independently hand-verified rows, plus **`D1.vox`** and **`D2.vox`** for
the two discrepancies — 26 files total. All 24 runnable probes were
recompiled and re-run in one final pass after being written; every one
reproduced its recorded `expected output:` exactly (24 clean, 0 mismatches,
0 compile failures). The four compile-error probes reproduce their recorded
compiler errors. `D1.vox` reproduces its segfault deterministically (exit
139, 6/6 runs).

## The table

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| VAL-01 | 2438–2444 | A `value` carries its runtime tag alongside its payload across a call, so one function can accept "whatever this slot holds" and ask `is a …` inside to find out which. | declare a `value` parameter, dispatch on `is a <type>` inside, print a per-branch label | yes — generator controls the argument, knows which branch must fire, asserts the label | none — no leaf emits `with a value` or any `is a <type>` predicate | todo | |
| VAL-02 | 2446–2448 | Three declaration forms: `with a value called x` (parameter), `Return a value, <expr>` (return), `a value called r` (local). | emit all three forms in one program | yes — local form asserted on VAL-07, param on VAL-03, return on VAL-05 | `gen leaf value roundtrip`, `gen leaf text value` (local form only — `a value called y{n} is …`) | todo (param + return forms) | |
| VAL-03 | 2450–2460 | Worked `describe` example: a `value` parameter dispatches `is a number` / `is a text` / Otherwise and prints `number` / `text` / `decimal` for `[1, "two", 3.5]`. | reproduce the example, assert the three labels | yes | none | todo — hand-verified (`VAL-03.vox`) | |
| VAL-04 | 2462–2477 | Inside the callee a `value` parameter's `is a …` predicates read its tag, printing dispatches on it, and it can be forwarded or appended back into a list with the tag preserved; a `value` return carries its tag back out. | value param + predicate dispatch + append-back of a value return | yes | none | folded into VAL-03 (predicate dispatch) and VAL-05 (return round-trip) | |
| VAL-05 | 2465–2477 | A function returning `a value` carries its tag back out, so the `echo` round-trip leaves `out` as `[1, "two", 3.5]` with the original tags intact. | reproduce the echo round-trip, assert `out`'s content and tags | yes — generator knows the input list | none | todo — hand-verified (`VAL-05.vox`) | |
| VAL-06 | 2479–2482 | `value` is not a reserved word; recognized only where a type is expected, so `a value is 5.` declares a variable named `value`. | declare a variable named `value`, print it | yes | none | todo — hand-verified (`VAL-06.vox`) | |
| VAL-07 | 2484–2494 | A `value` local keeps its tag through reassignment: `set r to 7.` retags a text-holding value as a number, so `If r is a number` then fires. | declare value from text, `set` to number, assert `is a number` | yes | `gen leaf value roundtrip` — reassigns a value across the type boundary (`Set y{n} to "reassigned{n}"`), so the reassignment-retag **construct** is exercised, but the tag is never asserted | exercised (construct, no assertion); todo (assertion + the number direction specifically) — hand-verified (`VAL-07.vox`) | |
| VAL-08 | 2496–2505 | Bare arithmetic on a `value` is a compile error (its type is only known at runtime). | emit `v add 1` inside a `value`-parameter function → expect a compile error | **no, from a runtime leaf** — the generator's contract is "legal Vox that should compile and run"; emitting a known compile error is outside it. The compile-rejection itself is hand-verified. | none | not assertable (compile-error claim) — hand-verified (`VAL-08.vox`) | |
| VAL-09 | 2507–2513 | A `value` can be retyped in place: `<valuevar> is a <type>.` reads the runtime tag, performs the conversion, stores the result back with the new tag. Works for `number`, `float`/`decimal`, `text`, and `boolean` targets. | emit a retype to each of the four targets, assert the post-retype value/behavior | yes | none | todo — hand-verified all four targets (`VAL-09.vox`). See **Discrepancy 2** for the `as`-cast-on-value the manual's analogy references. | |
| VAL-10 | 2516–2519 | Worked retype example: `numstr` is `"357"`; `numstr is a number.`; `print numstr add 1` prints `358` (arithmetic works because the variable is now tracked as a number). | reproduce, assert `358` | yes — exact value known at generation time | none | todo — hand-verified (`VAL-10.vox`) | |
| VAL-11 | 2521–2531 | The same phrase in **condition** position is a type predicate, not a cast: `If numstr is a number then` tests the tag and is false while `numstr` still holds the text `"357"`, so Otherwise fires. | emit the predicate on a text-holding value, assert the Otherwise branch | yes | none | todo — hand-verified (`VAL-11.vox`) | |
| VAL-12 | 2533–2535 | After a successful in-place retype the variable is tracked with the new type for the rest of its lifetime; retyping to the type it already holds is a no-op. | retype then do arithmetic (proves the new type is tracked); retype to the same type, assert unchanged and no error | yes | none | todo — hand-verified no-op (`VAL-12.vox`); post-retype tracking covered by `VAL-10.vox` | |
| VAL-13 | 2537–2547 | A failed conversion sets `_last_error` and leaves the variable as `0`; `On error` catches it. | retype `"abc"` to number wrapped in `On error`, assert handler fired and value `0` | yes | none | todo — hand-verified (`VAL-13.vox`) | |
| VAL-14 | 2549 | The `type` property on a `value` returns a text description with a `(dynamic)` suffix for each runtime tag: `Text`, `Number`, `Float`, `Boolean`, `List`, `Map`, `Nothing` (all `(dynamic)`). | declare a value of each tag, assert each `'s type` | yes | none — no leaf reads `'s type` on a value | todo — hand-verified all seven tags (`VAL-14.vox`) | |
| VAL-15 | 2553–2556 | The type reported by `type` changes with reassignment (`Text (dynamic)` → `Number (dynamic)` after `set v to 42`). | print `type` before and after reassignment | yes | none | todo — hand-verified (`VAL-15.vox`) | |
| VAL-16 | 2558 | `type` is a display helper for debugging/logging; type tests belong in the `is a <type>` predicate. | — | not a behavior — a usage recommendation | n/a | folded into VAL-14 (the property) and VAL-11 (the predicate) | |
| VAL-17 | 2560–2563 | Retyping a statically-typed variable is a compile error; the compiler reports the declared type and points at the explicit cast (`a text called t is n as text.`) as the correct rewrite. | emit `n is a text.` for a `number` var → expect the compile error; the rewrite itself is valid | **no, from a runtime leaf** for the compile-error half (same reason as VAL-08); the rewrite half is assertable and hand-verified to produce `Text (static)` | none | not assertable (compile-error claim) — hand-verified (`VAL-17.vox`; rewrite verified separately) | |
| VAL-18 | 2565–2568 | Recursion with `value` works: a `value` parameter threads its tag through every frame, so a walker over mixed data classifies correctly at any depth; `value` parameters compose (a value passed straight to another value function round-trips its tag). | a recursive/by-tag classifier over mixed data; two value functions composing | yes | none | todo — hand-verified (`VAL-18.vox`) | |
| VAL-19 | 2570–2578 | **Limitation:** a *conditional* `value` return (the factorial pattern, `If … return a value, <expr>. Otherwise …`, in a function whose `To` line has no `Return`) does not track the return type, so the value would print as a number; use the single-expression `Return a value, <expr>.` form. Conditional `value` *parameters* (the factorial pattern with a void return) work fine. | emit the conditional-return factorial pattern returning a non-number; emit the void-return conditional-parameter pattern | yes — but the *observed* behavior is the discrepancy: the manual says "prints as a number" and the compiler segfaults in one direction — see **Discrepancy 1** | none | todo, **blocked on D1** — hand-verified the param half works and the return half mis-behaves (`VAL-19.vox`) | |
| VAL-20 | 2576–2578 | The internal ABI that carries the tag is documented in `docs/abi_value.md`; roadmap context in `docs/COLLECTIONS_ROADMAP.md` stage 1d. | — | not assertable — a documentation pointer, not a language behavior | n/a | not assertable | |
| VAL-21 | 2582–2594 | `nothing` is the absent value (null equivalent); it can sit in a list slot, a map value, or a `value` parameter/return, and it prints as the word `nothing`. | put `nothing` in a list slot and a map value, print, assert the word `nothing` appears | yes | none — no leaf emits `nothing`/`null`/`nil` anywhere | todo — hand-verified (`VAL-21.vox`, also covers VAL-22) | |
| VAL-22 | 2586–2594 | `nothing` prints inside aggregates as `[1, nothing, "x"]` and `{"found": 4, "absent": nothing}`. | reproduce both, assert the exact printed text | yes | none | folded into VAL-21 — hand-verified in `VAL-21.vox` | |
| VAL-23 | 2596–2598 | `null` and `nil` are accepted spellings of the same literal as `nothing`; all three produce the identical value. | emit all three, assert identical printed form | yes | none | todo — hand-verified (`VAL-23.vox`) | |
| VAL-24 | 2597–2598 | `nothing` is a reserved word; it cannot be used as a variable name. | declare a variable named `nothing` → expect a compile error | **no, from a runtime leaf** (compile-error claim, same reason as VAL-08) | none | not assertable (compile-error claim) — hand-verified (`VAL-24.vox`) | |
| VAL-25 | 2600–2606 | Test for `nothing` with `is nothing` / `is not nothing` — an equality (like `is true`), not a type predicate; there is no `is a nothing`. | emit `is nothing` / `is not nothing` on present and `nothing`-valued map entries, assert the branch | yes | none | todo — hand-verified (`VAL-25.vox`, also covers VAL-31) | |
| VAL-26 | 2608–2616 | `nothing` is not zero: `0 is nothing` is false and `nothing is 0` is false; `is nothing` compares the runtime type tag, so the two never collide. | emit both comparisons, assert neither "never" branch fires | yes | none | todo — hand-verified (`VAL-26.vox`) | |
| VAL-27 | 2618–2627 | A missing map key is an error, not `nothing`: reading a never-set key sets the error flag (does not silently hand back `nothing`); "key absent" and "key holds nothing" stay distinguishable. | read a never-set key in `On error`, assert handler fires and value `0`; contrast with a key set to `nothing` | yes | none | todo — hand-verified (`VAL-27.vox`) | |
| VAL-28 | 2629–2636 | Arithmetic on `nothing` written literally is a compile error. | emit `nothing add 1` literally → expect a compile error | **no, from a runtime leaf** (compile-error claim, same reason as VAL-08) | none | not assertable (compile-error claim) — hand-verified (`VAL-28.vox`) | |
| VAL-29 | 2638–2646 | When a value turns out to be `nothing` at run time (read out of a map or mixed list), arithmetic on it sets the error flag (not a compile error); `On error` catches it. | read `nothing` from a map, add `1`, wrap in `On error`, assert the handler fires | yes | none | todo — hand-verified (`VAL-29.vox`) | |
| VAL-30 | 2648–2655 | The stored payload of `nothing` really is `0`, so unguarded `total add missing_field` quietly evaluates to `total` (a plausible wrong answer); guard with `is not nothing` first. | show `m's "absent" add 1` evaluates to `1` (0 + 1) unguarded; show the guarded form | yes — generator knows the payload is `0` | none | todo — hand-verified (`VAL-30.vox`) | |
| VAL-31 | 2657–2658 | Comparisons are not arithmetic, so `is nothing`, `is not nothing`, and ordinary equality keep working on a `nothing` without raising the flag. | run comparisons on a `nothing` with no `On error`, assert no flag | yes | none | folded into VAL-25 — hand-verified in `VAL-25.vox` (no `On error`, runs clean) | |

## Discrepancies

### 1. The conditional `value` return does not just "print as a number" — it segfaults in one direction

LANGUAGE.md:2570–2574 describes the limitation mildly:

> A *conditional* `value` return — using the *factorial pattern* (`If ...
> return a value, <expr>. Otherwise ...`) inside a function whose `To` line
> has no `Return` — does not track the return type, so the value would
> print as a number.

The compiler does worse than "print as a number." When the taken branch
returns an expression whose tag **differs from the parameter's runtime
tag**, the return value is mis-tagged, and the failure mode depends on the
direction:

- **text returned from a number-tagged frame** → a stable garbage number
  (`4210906`), mis-tagged `Number (dynamic)`. (`VAL-19.vox`, exit 0,
  deterministic.)
- **number returned from a text-tagged frame** → **segmentation fault**,
  exit 139, core dumped. (`D1.vox`, deterministic, 6/6 runs.)

Minimal repro (`D1.vox`):

```
To label with a value called v.
  If v is a number, return a value, v.
  Otherwise, return a value, 99.

a value called r is label of "hello".
print r.
```

This is a valid, compiling Vox program. The single-expression form
(`To label with a value called v. Return a value, v.`) works correctly,
exactly as the manual advises.

**Strongest reading under which the compiler is correct:** the manual
itself flags this exact pattern as a known limitation and tells the user
not to write it ("Use the single-expression `Return a value, <expr>.` form
on the `To` line for `value` returns"). Under that reading the conditional
return is a documented "don't do this," and the mis-tagging is the
limitation the manual warned about — just understated. What that reading
does **not** cover is the segfault: Vox's headline promise is that *no
valid program, however stupid, should segfault or corrupt memory*
(`CLAUDE.md`, and `vox/docs/segfault-safety-test-plan.md` per the ROADMAP),
and this is a valid program. So even accepting the documented limitation,
the crash is a memory-safety violation, not a cosmetic print issue. The
manual's wording ("would print as a number") undersells a crash. Recorded
and stopped — not filed; adjudication is the master's and the human's.

### 2. The in-place retype analogy references a conversion the compiler does not implement for `value`

LANGUAGE.md:2510–2512 explains the in-place retype as performing "the
conversion that the corresponding static cast would use." But the
corresponding static cast on a `value` (`v as a number`) is itself a
compile error:

```
a value called v is "357".
a number called n is v as a number.
```

```
error: Cannot cast v to a number: v's type is only known at runtime, and
casting a dynamically-tagged value is not currently supported by the
compiler (a known gap, not yet resolvable from within the language).
```

This is ROADMAP **finding 21** ("casting a dynamically-tagged `value` still
can't convert — currently a compile error instead of a silent wrong
answer, which is the safe state, but the conversion itself isn't
implemented"). The in-place *statement* form the manual is actually
documenting (`v is a number.`, VAL-09/VAL-10) works perfectly; the
`as`-cast-on-`value` form the analogy appeals to does not.

**Strongest reading under which the compiler is correct:** the manual is
documenting the in-place statement, which works, and using the static cast
only as an explanatory analogy for *what conversion is performed* — not
promising that `v as a number` itself compiles on a value. Under that
reading no claim in this line range is false (VAL-09/VAL-10 are true), and
finding-21 openly tracks the `as`-on-`value` gap. The imprecision is in
the manual's phrasing ("the corresponding static cast would use" implies
that cast exists for values), not in the compiler. A documentation-clarity
note more than a bug. Recorded and stopped — not filed.

## Invariants this section justifies

Every sameness the manual *requires* of generated programs in this area,
with the line and the row ID that justifies it. (The invariant report
fills its `citation` column from these lines.)

- `nothing` always prints as the literal word `nothing` (never `null`,
  `nil`, empty, or `0`) — LANGUAGE.md:2584, VAL-21 / VAL-22
- `null`, `nil`, and `nothing` are interchangeable as the absent-value
  literal — **not** an invariant the generator should enforce: the manual
  lists all three as valid (LANGUAGE.md:2596), so a leaf that *always*
  picks one spelling would be asserting an undeclared rule. Variation here
  is the default (CLAUDE.md); the row that justifies allowing all three is
  VAL-23
- `nothing` is a reserved word — a generated name must never collide with
  it — LANGUAGE.md:2597, VAL-24
- `value` is **not** a reserved word, so `value` *may* appear as an
  ordinary identifier (e.g. a variable named `value`) — LANGUAGE.md:2479,
  VAL-06; the generator's name-pool must not blacklist it
- a value's `type` is always reported with the `(dynamic)` suffix
  (`Text (dynamic)`, `Number (dynamic)`, …) — LANGUAGE.md:2549, VAL-14
- in-place retype works only on variables declared `value`; a
  statically-typed variable retyped in place is a compile error, so a
  generated program must never emit `<staticvar> is a <type>.` —
  LANGUAGE.md:2560, VAL-17
- arithmetic on a literal `nothing` is a compile error, so a generated
  program must never emit `nothing` directly inside an arithmetic
  expression — LANGUAGE.md:2629, VAL-28
- bare arithmetic on a `value` is a compile error, so a generated program
  must never use a `value` directly in arithmetic without first retyping
  it (`v is a number.`) — LANGUAGE.md:2496, VAL-08 / VAL-09
- the conditional `value` return (factorial pattern, no `Return` on the
  `To` line) is a documented *don't*; generated `value`-returning
  functions must use the single-expression `Return a value, <expr>.` form
  on the `To` line — LANGUAGE.md:2574, VAL-19 (blocked on D1)

No other sameness is required by this section. In particular the manual
does **not** pin: how many `is a <type>` branches a dispatcher uses, which
retype target a leaf picks, whether a `value` holds a number/text/float/
boolean/list/map/nothing, or whether `is nothing` is tested — all of those
must vary (CLAUDE.md: variation is the default; sameness needs a citation).

## Report

**31 rows** (VAL-01 through VAL-31). Five are explicit cross-references
folded into a sibling row rather than fresh leaf needs (VAL-04 → VAL-03/05;
VAL-16 → VAL-14; VAL-22 → VAL-21; VAL-31 → VAL-25; and VAL-02 is an index
whose forms are probed on the rows that use them), and one is a
documentation pointer (VAL-20), leaving **25 distinct behavioral claims**.

Of those, **21 are assertable from a runtime leaf** — the generator
controls the value's tag, the input list/map, and the retype target, so it
can predict the exact result and emit a failing-exit assertion. **4 are
compile-error claims** (VAL-08 bare-value arithmetic, VAL-17 static
retype, VAL-24 `nothing` reserved, VAL-28 literal-nothing arithmetic) that
are hand-verified but **not assertable from a runtime leaf**, because
emitting a deliberate compile error breaks the generator's "legal Vox that
should compile and run" contract; they're recorded for completeness, the
way PROCEDURE §2 asks. **1** (VAL-20) is a documentation pointer, not
assertable.

**Existing coverage is real but shallow and assertion-free.** Two leaves
touch `value` (`gen leaf value roundtrip` in `gen_things.vox`, `gen leaf
text value` in `gen_text.vox`); between them they exercise a value-local
declaration, a print, and a reassignment across the type boundary — and
*nothing else*. No `value` parameter, no `value` return, no `is a <type>`
predicate, no in-place retype, no `type` property, no recursion, and the
entire `nothing` half of the section is completely untouched (zero leaves
emit `nothing`/`null`/`nil`). And, as in the buffers ledger, **none of it
asserts** — every existing emission stops at `Print`-and-eyeball. The next
workers' job here is both "write leaves for the untouched majority" and
"add assertions to what is already emitted."

**Biggest finding — Discrepancy 1: a deterministic segfault.** The
conditional `value` return (factorial pattern, no `Return` on the `To`
line) is documented as a cosmetic limitation ("the value would print as a
number"). It is not cosmetic: returning a number literal from a frame
whose value parameter holds a text **segfaults** the runtime (exit 139,
deterministic, 6/6). Returning a text from a number frame produces a
stable garbage number. Both are valid, compiling programs. This is exactly
the memory-safety class vox-fuzz exists to find, and it is on the
`value`-return path the manual itself warns about — a leaf that exercises
conditional `value` returns would trip it immediately. Not filed;
adjudication goes to the master and the human.

**Second finding — Discrepancy 2: the retype analogy references an
unimplemented conversion.** The manual explains the in-place retype as
"the conversion that the corresponding static cast would use," but
`v as a number` on a value is a compile error (ROADMAP finding 21). The
in-place statement the manual actually documents works; the analogy is
just imprecise. A documentation-clarity issue, not a crash.

**Advice for the next mapper.** Three things this section cost me that the
next one can skip:

1. **Compile-error claims are a separate assertable category.** Four rows
   here (VAL-08/17/24/28) are real, hand-verifiable claims whose assertion
   is a *compiler rejection*, not a runtime check. PROCEDURE §2 wants them
   in the ledger for completeness, but they are `not assertable` from a
   runtime leaf — decide that up front per row rather than discovering it
   at the end.
2. **`a`, `b`, `nothing`, `value` are all landmines as variable names.**
   `a`/`b` are reserved articles (cost me a null/nil probe), `nothing` is
   reserved (VAL-24), and `value` is *not* reserved (VAL-06) — the three
   interact confusingly. Pick non-reserved, non-article names for every
   probe variable (`lhs`, `mid`, `kept`, `lost`, …) and never the bare
   letters.
3. **When the manual names a limitation, probe the *worst* case, not the
   example.** The manual's conditional-return warning reads cosmetic, and
   probing the cosmetic direction (text from number, `VAL-19`) only shows
   a garbage number. The segfault only appears in the *opposite* direction
   (number from text, `D1`). A mapper who probed only the manual's own
   example would record "prints as a number" and miss the crash. Always
   test both directions of a tag-mismatch claim.