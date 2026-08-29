# Claim ledger: Dynamic Values (`value`) and `nothing`

Source: `../vox/LANGUAGE.md` lines **2666–2915**, manual version **Vox
0.4.11** (5603 lines, vox `e0c5b7f`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual): the `value` type (§Dynamic Values)
and `nothing` (§Nothing, the absent value). Row prefix **`VAL`**.

**This section was substantially rewritten between 0.4.7 and 0.4.9, not
just shifted.** Both of this ledger's discrepancies drove real manual
changes:

- **VAL-19** (Discrepancy 1: conditional `value` return): the manual's
  own claim is now the **opposite** of what it said before — "Conditional
  `value` returns work" (2680–2699) replaces "does not track the return
  type." Row text rewritten below, not just re-cited. The narrower
  limitation that survives (branches declaring *different* types) is a
  new claim with its own row, **VAL-32**.
- **Discrepancy 2** (retype analogy referencing an unimplemented cast):
  the manual now has an explicit clarifying paragraph (2626–2629) saying
  the `as` cast is *not* an alternative to the in-place retype on a
  `value` — see the Discrepancies section below, now resolved.

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
gives minimal repros for the two that matter — one of them was a
deterministic segfault on a valid, compiling program. **Discrepancy 1 has
since been fixed in vox (#43, 0.4.8) and both its probes were re-recorded
to the fixed behaviour on 2026-08-21.**

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
but which produce no binary. That is **25 `VAL-NN.vox` probe files** (24
at the original pass, plus `VAL-32.vox` added 2026-08-22) for the 25
independently hand-verified rows, plus **`D1.vox`** and **`D2.vox`** for
the two discrepancies — 27 files total. All 25 runnable probes were
recompiled and re-run against vox 0.4.9; every one reproduced its
recorded `expected output:` exactly. The four compile-error probes
reproduce their recorded compiler errors.

**Refreshed 2026-08-21 against vox 0.4.8 + #43.** `D1.vox` used to record a
deterministic segfault (exit 139, 6/6 runs); vox #43 fixed it, so `D1.vox`
now records `99` and `VAL-19.vox` now records `fallback` /
`Text (dynamic)` where it recorded `4210906` / `Number (dynamic)`. Nothing
in this directory crashes any more. All 26 re-run clean with
`docs/check-probes.sh docs/ledger/probes/values`.

## The table

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| VAL-01 | 2697–2699 | A `value` carries its runtime tag alongside its payload across a call, so one function can accept "whatever this slot holds" and ask `is a …` inside to find out which. | declare a `value` parameter, dispatch on `is a <type>` inside, print a per-branch label | yes — generator controls the argument, knows which branch must fire, asserts the label | none — no leaf emits `with a value` or any `is a <type>` predicate | todo | |
| VAL-02 | 2701–2703 | Three declaration forms: `with a value called x` (parameter), `Return a value, <expr>` (return), `a value called r` (local). | emit all three forms in one program | yes — local form asserted on VAL-07, param on VAL-03, return on VAL-05 | `gen leaf value roundtrip`, `gen leaf text value` (local form only — `a value called y{n} is …`) | **verified** — `gen leaf value forms` asserts the three declaration forms and the round-tripped tag+payload (value band live 2026-08-23) | `gen leaf value forms` (ASSERT VAL-02) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-03 | 2705–2715 | Worked `describe` example: a `value` parameter dispatches `is a number` / `is a text` / Otherwise and prints `number` / `text` / `decimal` for `[1, "two", 3.5]`. | reproduce the example, assert the three labels | yes | none | **verified** — `gen leaf value dispatch`, `gen leaf list mixed` asserts the three dispatch labels of the worked example (value band live 2026-08-23) | `gen leaf value dispatch`, `gen leaf list mixed` (ASSERT VAL-03) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-04 | 2717–2720 | Inside the callee a `value` parameter's `is a …` predicates read its tag, printing dispatches on it, and it can be forwarded or appended back into a list with the tag preserved; a `value` return carries its tag back out. | value param + predicate dispatch + append-back of a value return | yes | none | **verified** — `gen leaf value dispatch label`, `gen leaf value forwarding` asserts the branch taken matches the tag passed; forwarding through a list keeps tag and payload (value band live 2026-08-23) | `gen leaf value dispatch label`, `gen leaf value forwarding` (ASSERT VAL-04) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-05 | 2719–2732 | A function returning `a value` carries its tag back out, so the `echo` round-trip leaves `out` as `[1, "two", 3.5]` with the original tags intact. | reproduce the echo round-trip, assert `out`'s content and tags | yes — generator knows the input list | none | **verified** — `gen leaf value dispatch` asserts the value-return round-trip keeps the original tags (value band live 2026-08-23) | `gen leaf value dispatch` (ASSERT VAL-05) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-06 | 2734–2737 | `value` is not a reserved word; recognized only where a type is expected, so `a value is 5.` declares a variable named `value`. | declare a variable named `value`, print it | yes | none | **verified** — `gen leaf value name` asserts a variable named `value` declares and reads back (value band live 2026-08-23) | `gen leaf value name` (ASSERT VAL-06) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-07 | 2739–2749 | A `value` local keeps its tag through reassignment: `set r to 7.` retags a text-holding value as a number, so `If r is a number` then fires. | declare value from text, `set` to number, assert `is a number` | yes | `gen leaf value roundtrip` — reassigns a value across the type boundary (`Set y{n} to "reassigned{n}"`), so the reassignment-retag **construct** is exercised, but the tag is never asserted | **verified** — `gen leaf value retag` asserts both directions — the new tag is there and the old is gone, tag pair drawn per emission (value band live 2026-08-23) | `gen leaf value retag` (ASSERT VAL-07) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-08 | 2751–2760 | Bare arithmetic on a `value` is a compile error (its type is only known at runtime). | emit `v add 1` inside a `value`-parameter function → expect a compile error | **no, from a runtime leaf** — the generator's contract is "legal Vox that should compile and run"; emitting a known compile error is outside it. The compile-rejection itself is hand-verified. | none | not assertable (compile-error claim) — hand-verified (`VAL-08.vox`) | |
| VAL-09 | 2762–2769 | A `value` can be retyped in place: `<valuevar> is a <type>.` reads the runtime tag, performs the conversion, stores the result back with the new tag. Works for `number`, `float`/`decimal`, `text`, and `boolean` targets. | emit a retype to each of the four targets, assert the post-retype value/behavior | yes | none | **verified** — `gen leaf value retype` asserts in-place retype to each target stores the new tag (value band live 2026-08-23) | `gen leaf value retype` (ASSERT VAL-09) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-10 | 2770–2774 | Worked retype example: `numstr` is `"357"`; `numstr is a number.`; `print numstr add 1` prints `358` (arithmetic works because the variable is now tracked as a number). | reproduce, assert `358` | yes — exact value known at generation time | none | **verified** — `gen leaf value retype sum` asserts post-retype arithmetic works (the 357 add 1 shape) (value band live 2026-08-23) | `gen leaf value retype sum` (ASSERT VAL-10) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-11 | 2781–2791 | The same phrase in **condition** position is a type predicate, not a cast: `If numstr is a number then` tests the tag and is false while `numstr` still holds the text `"357"`, so Otherwise fires. | emit the predicate on a text-holding value, assert the Otherwise branch | yes | none | **verified** — `gen leaf value predicate` asserts condition position is a predicate, not a cast — Otherwise fires and the text survives (value band live 2026-08-23) | `gen leaf value predicate` (ASSERT VAL-11) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-12 | 2793–2795 | After a successful in-place retype the variable is tracked with the new type for the rest of its lifetime; retyping to the type it already holds is a no-op. | retype then do arithmetic (proves the new type is tracked); retype to the same type, assert unchanged and no error | yes | none | **verified** — `gen leaf value retype tracking` asserts new predicate true, old false; same-type retype is a flagless no-op (value band live 2026-08-23) | `gen leaf value retype tracking` (ASSERT VAL-12) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-13 | 2797–2807 | A failed conversion sets `_last_error` and leaves the variable as `0`; `On error` catches it. | retype `"abc"` to number wrapped in `On error`, assert handler fired and value `0` | yes | none | **verified** — `gen leaf value bad retype` asserts a failed conversion sets the flag, `On error` catches, the value is 0 (value band live 2026-08-23) | `gen leaf value bad retype` (ASSERT VAL-13) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-14 | 2809–2816 | The `type` property on a `value` returns a text description with a `(dynamic)` suffix for each runtime tag: `Text`, `Number`, `Float`, `Boolean`, `List`, `Map`, `Nothing` (all `(dynamic)`). | declare a value of each tag, assert each `'s type` | yes | none — no leaf reads `'s type` on a value | **verified** — `gen leaf value type property` asserts the exact `type` text per runtime tag, `(dynamic)` suffix included (value band live 2026-08-23) | `gen leaf value type property` (ASSERT VAL-14) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-15 | 2812–2816 | The type reported by `type` changes with reassignment (`Text (dynamic)` → `Number (dynamic)` after `set v to 42`). | print `type` before and after reassignment | yes | none | todo — hand-verified (`VAL-15.vox`) | |
| VAL-16 | 2818 | `type` is a display helper for debugging/logging; type tests belong in the `is a <type>` predicate. | — | not a behavior — a usage recommendation | n/a | folded into VAL-14 (the property) and VAL-11 (the predicate) | |
| VAL-17 | 2824–2827 | Retyping a statically-typed variable is a compile error; the compiler reports the declared type and points at the explicit cast (`a text called t is n as text.`) as the correct rewrite. | emit `n is a text.` for a `number` var → expect the compile error; the rewrite itself is valid | **no, from a runtime leaf** for the compile-error half (same reason as VAL-08); the rewrite half is assertable and hand-verified to produce `Text (static)` | none | not assertable (compile-error claim) — hand-verified (`VAL-17.vox`; rewrite verified separately) | |
| VAL-18 | 2829–2832 | Recursion with `value` works: a `value` parameter threads its tag through every frame, so a walker over mixed data classifies correctly at any depth; `value` parameters compose (a value passed straight to another value function round-trips its tag). | a recursive/by-tag classifier over mixed data; two value functions composing | yes | none | todo — hand-verified (`VAL-18.vox`) | |
| VAL-19 | 2834–2855 | **Claim rewritten 2026-08-22 (manual's own claim reversed, not just its line number); enumeration widened 2026-08-29 (0.4.15, #112).** The old (0.4.7) manual said a conditional `value` return does not track its type; the current manual says the opposite: **"Conditional `value` returns work."** A function whose only returns sit inside an `If`/`Otherwise` (the factorial pattern, no `Return` on the `To` line) carries its declared return type just as the single-expression form does, and each branch hands back its own runtime tag (worked example: `score of 7` → `7`, `score of "hello"` → `99`). If no branch fires and the function falls off its end, it hands back the empty value of its declared type — as of 0.4.15 this is spelled out per type, not just "empty text, zero, or a value tagged 0": empty text, `0`/`0.0`/`false` (and the zero time for a `time` return), `[]`, `{}`, an empty buffer, the all-defaults instance for a `thing`, or a `value` tagged as the number `0`. Before #112 this only actually worked for `number`/`float`/`boolean`/`text`/`value` — a `list`/`buffer` return segfaulted, a `map` return hung, and a `thing` return handed back uninitialised stack (CHANGELOG.md, Unreleased). The five now-fixed types get their own rows in `functions.md` (FUN-45 onward, 2026-08-29 addition) since the fix is function-return machinery, not `value`-specific; this row stays scoped to the `value`-tagged case, which was already correct pre-#112. | reproduce the worked example; assert both printed values | yes — the *working* assertion to emit is `If lost's type is not "Text (dynamic)" then, Exit 95.` after a text-returning branch | none | todo — unblocked (D1 resolved by vox #43, 0.4.8). Re-verified against 0.4.9 directly: `D1.vox`'s program still prints `99`, no segfault, exit 0. | |
| VAL-20 | 2864–2865 | The internal ABI that carries the tag is documented in `docs/abi_value.md`; roadmap context in `docs/COLLECTIONS_ROADMAP.md` stage 1d. | — | not assertable — a documentation pointer, not a language behavior | n/a | not assertable | |
| VAL-21 | 2869–2881 | `nothing` is the absent value (null equivalent); it can sit in a list slot, a map value, or a `value` parameter/return, and it prints as the word `nothing`. | put `nothing` in a list slot and a map value, print, assert the word `nothing` appears | yes | none — no leaf emits `nothing`/`null`/`nil` anywhere | **verified** — `gen leaf absent value` asserts `nothing` read back from a list slot, a map value and a local, printing as the word `nothing` (value band live 2026-08-23) | `gen leaf absent value` (ASSERT VAL-21) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-22 | 2873–2881 | `nothing` prints inside aggregates as `[1, nothing, "x"]` and `{"found": 4, "absent": nothing}`. | reproduce both, assert the exact printed text | yes | none | folded into VAL-21 — hand-verified in `VAL-21.vox` | |
| VAL-23 | 2883–2885 | `null` and `nil` are accepted spellings of the same literal as `nothing`; all three produce the identical value. | emit all three, assert identical printed form | yes | none | todo — hand-verified (`VAL-23.vox`) | |
| VAL-24 | 2884–2885 | `nothing` is a reserved word; it cannot be used as a variable name. | declare a variable named `nothing` → expect a compile error | **no, from a runtime leaf** (compile-error claim, same reason as VAL-08) | none | not assertable (compile-error claim) — hand-verified (`VAL-24.vox`) | |
| VAL-25 | 2887–2893 | Test for `nothing` with `is nothing` / `is not nothing` — an equality (like `is true`), not a type predicate; there is no `is a nothing`. | emit `is nothing` / `is not nothing` on present and `nothing`-valued map entries, assert the branch | yes | none | **verified** — `gen leaf absent test` asserts `is nothing` / `is not nothing`, both directions, four assertions (value band live 2026-08-23) | `gen leaf absent test` (ASSERT VAL-25) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-26 | 2895–2903 | `nothing` is not zero: `0 is nothing` is false and `nothing is 0` is false; `is nothing` compares the runtime type tag, so the two never collide. | emit both comparisons, assert neither "never" branch fires | yes | none | todo — hand-verified (`VAL-26.vox`) | |
| VAL-27 | 2905–2914 | A missing map key is an error, not `nothing`: reading a never-set key sets the error flag (does not silently hand back `nothing`); "key absent" and "key holds nothing" stay distinguishable. | read a never-set key in `On error`, assert handler fires and value `0`; contrast with a key set to `nothing` | yes | none | **verified** — `gen leaf absent key` asserts a never-set key raises the flag; a present key holding `nothing` reads back flagless (value band live 2026-08-23) | `gen leaf absent key` (ASSERT VAL-27) · vox 0.4.11 · seeds 41000–41219, 77777–77788 |
| VAL-28 | 2916–2923 | Arithmetic on `nothing` written literally is a compile error. | emit `nothing add 1` literally → expect a compile error | **no, from a runtime leaf** (compile-error claim, same reason as VAL-08) | none | not assertable (compile-error claim) — hand-verified (`VAL-28.vox`) | |
| VAL-29 | 2925–2933 | When a value turns out to be `nothing` at run time (read out of a map or mixed list), arithmetic on it sets the error flag (not a compile error); `On error` catches it. | read `nothing` from a map, add `1`, wrap in `On error`, assert the handler fires | yes | none | todo — hand-verified (`VAL-29.vox`) | |
| VAL-30 | 2935–2942 | The stored payload of `nothing` really is `0`, so unguarded `total add missing_field` quietly evaluates to `total` (a plausible wrong answer); guard with `is not nothing` first. | show `m's "absent" add 1` evaluates to `1` (0 + 1) unguarded; show the guarded form | yes — generator knows the payload is `0` | none | todo — hand-verified (`VAL-30.vox`) | |
| VAL-31 | 2944–2945 | Comparisons are not arithmetic, so `is nothing`, `is not nothing`, and ordinary equality keep working on a `nothing` without raising the flag. | run comparisons on a `nothing` with no `On error`, assert no flag | yes | none | folded into VAL-25 — hand-verified in `VAL-25.vox` (no `On error`, runs clean) | |
| VAL-32 | 2857–2863 | *(new row, added 2026-08-22)* A function whose conditional branches declare **different** return types (`Return a text` in one, `Return a number` in the other) has no single type for the `To` line to promise, so it declares none and the caller reads the result as a number. This is the narrower limitation that survives now that VAL-19's general case (conditional returns of the *same* type) is fixed. Conditional `value` *parameters* with a void return still work as they always have. | reproduce with a text-in-one/number-in-other function, assert the caller sees the text's address reinterpreted as a number (a specific, deterministic wrong-looking value the generator can predict) | yes — the address a given string literal lands at is deterministic per compile, hand-verified in `VAL-32.vox` | none | todo — hand-verified: `classify of 5` (branch returns `Return a text, "big".`) read into a `number called result` prints `4198488`, a raw rodata address, not `0` | |

## Discrepancies

### 1. The conditional `value` return does not just "print as a number" — it segfaults in one direction — RESOLVED (vox #43)

Old manual line 2570–2574 (pre-0.4.9; the paragraph itself is gone —
see below) described the limitation mildly:

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

**Resolution: fixed by vox #43 (0.4.8).** Both directions are fixed, and
LANGUAGE.md was corrected in the same change. Re-run against current main:

- `D1.vox` — number returned from a text-tagged frame — no longer
  segfaults. It takes the `Otherwise` branch and prints `99`, exit 0.
- `VAL-19.vox` — text returned from a number-tagged frame — no longer
  prints garbage. It prints `fallback` / `Text (dynamic)`: each branch now
  hands back its own runtime tag.

The manual no longer calls this a limitation. Where 0.4.7 had the
"does not track the return type" paragraph, the current
manual has **"Conditional `value` returns work"** (LANGUAGE.md:2834–2855)
with `D1.vox`'s program as its worked example; run verbatim it prints `7`
then `99`. A narrower limitation remains documented at 2701–2707 —
branches that declare *different* types (`Return a text` in one, `Return
a number` in the other) have no single type for the `To` line to
promise, so the caller reads the result as a number. **That claim now
has its own row — VAL-32, added and hand-verified 2026-08-22 (see
above).** VAL-19's row text has also been rewritten to state the current
(positive) claim rather than the withdrawn 0.4.7 wording.

Both probes were re-recorded to the fixed behaviour on 2026-08-21.

### 2. The in-place retype analogy references a conversion the compiler does not implement for `value` — RESOLVED (manual clarified, compiler unchanged)

**Resolution confirmed, 2026-08-22.** The underlying gap is exactly as
found — `v as a number` on a `value` is still a compile error on 0.4.9,
re-probed verbatim below with the identical message — but the manual has
been clarified at LANGUAGE.md:2776–2779 to say so explicitly: "The
explicit `as` cast is not an alternative here: `numstr as number` is a
compile error on a `value`, because a cast needs its source type at
compile time and a `value` only knows its type at runtime — the in-place
retype is how a `value` is converted." That is precisely the
documentation-clarity fix this discrepancy's "strongest reading" argued
for, below. ROADMAP finding 21 (the `as`-on-`value` gap itself) remains
open as a feature gap, not a documentation gap.

Old manual line 2510–2512 (pre-0.4.9) explained the in-place retype as
performing "the conversion that the corresponding static cast would
use." But the corresponding static cast on a `value` (`v as a number`) is
itself a compile error:

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
  `nil`, empty, or `0`) — LANGUAGE.md:2869, VAL-21 / VAL-22
- `null`, `nil`, and `nothing` are interchangeable as the absent-value
  literal — **not** an invariant the generator should enforce: the manual
  lists all three as valid (LANGUAGE.md:2883), so a leaf that *always*
  picks one spelling would be asserting an undeclared rule. Variation here
  is the default (CLAUDE.md); the row that justifies allowing all three is
  VAL-23
- `nothing` is a reserved word — a generated name must never collide with
  it — LANGUAGE.md:2884, VAL-24
- `value` is **not** a reserved word, so `value` *may* appear as an
  ordinary identifier (e.g. a variable named `value`) — LANGUAGE.md:2734,
  VAL-06; the generator's name-pool must not blacklist it
- a value's `type` is always reported with the `(dynamic)` suffix
  (`Text (dynamic)`, `Number (dynamic)`, …) — LANGUAGE.md:2809, VAL-14
- in-place retype works only on variables declared `value`; a
  statically-typed variable retyped in place is a compile error, so a
  generated program must never emit `<staticvar> is a <type>.` —
  LANGUAGE.md:2824, VAL-17
- arithmetic on a literal `nothing` is a compile error, so a generated
  program must never emit `nothing` directly inside an arithmetic
  expression — LANGUAGE.md:2916, VAL-28
- bare arithmetic on a `value` is a compile error, so a generated program
  must never use a `value` directly in arithmetic without first retyping
  it (`v is a number.`) — LANGUAGE.md:2751, VAL-08 / VAL-09
- ~~the conditional `value` return (factorial pattern, no `Return` on the
  `To` line) is a documented *don't*; generated `value`-returning
  functions must use the single-expression `Return a value, <expr>.` form
  on the `To` line — LANGUAGE.md:2834–2855, VAL-19 — WITHDRAWN, see below~~
  **Withdrawn 2026-08-21: this invariant is no longer justified.** vox #43
  (0.4.8) made the conditional form work and LANGUAGE.md:2834–2855 now
  documents it as working. A leaf that always picks the single-expression
  form is now an *unjustified* invariant — both forms are legal and the
  choice between them must vary. The one sameness that survives is
  narrower: branches that declare *different* types still have no single
  return type (LANGUAGE.md:2857–2863, VAL-32), so a leaf must declare the same
  type in every branch of one function.

No other sameness is required by this section. In particular the manual
does **not** pin: how many `is a <type>` branches a dispatcher uses, which
retype target a leaf picks, whether a `value` holds a number/text/float/
boolean/list/map/nothing, or whether `is nothing` is tested — all of those
must vary (CLAUDE.md: variation is the default; sameness needs a citation).

## Report

**Updated 2026-08-22: 32 rows** (VAL-01 through VAL-32 — VAL-32 added
this pass, see above). Five are explicit cross-references folded into a
sibling row rather than fresh leaf needs (VAL-04 → VAL-03/05; VAL-16 →
VAL-14; VAL-22 → VAL-21; VAL-31 → VAL-25; and VAL-02 is an index whose
forms are probed on the rows that use them), and one is a documentation
pointer (VAL-20), leaving **26 distinct behavioral claims**.

Of those, **22 are assertable from a runtime leaf** (21 original + the
new VAL-32) — the generator
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

**Biggest finding — Discrepancy 1: a deterministic segfault.**
*(Fixed in vox by #43, 0.4.8; the account below is the finding as it stood
when this ledger was written — see the `Resolution:` line on Discrepancy 1.)*
The
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
   test both directions of a tag-mismatch claim. (Both directions were
   fixed by vox #43; the lesson is what found the crash, not the crash.)