# Claim ledger: Lists and Collections (first half)

Source: `../vox/LANGUAGE.md` lines **2241–2540**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual): List Literals, Mixed-Type Lists,
Nested Lists, Maps, Type Predicates. Row prefix **`LST`**.

The rest of the chapter is mapped elsewhere and is deliberately **not**
re-mapped here: `value` and `nothing` (2541–2790) are `values.md` (`VAL-*`),
and printing / properties / element access / appending / loop expansion
(2791–3127) are `collections-b.md` (`LST2-*`). Where a claim in this range
leans on one of those, the row cross-references it by line.

**This section was rewritten between 0.4.7 and 0.4.9, not just
re-flowed — six of this ledger's eight discrepancies drove a manual or
compiler change, confirmed by re-reading the current text and (for the
compiler-side ones) re-probing against vox 0.4.9 directly:**

- **D1** (unquoted `hello` in the widening example) — manual fixed, the
  worked example now quotes it and moved on to be the compile-error
  example instead (see LST-19).
- **D2** (`For each` over a list of maps claimed to type the loop
  variable) — manual fixed to state the real rule (loop variable stays
  untyped) and show the idiom that actually compiles (LST-57).
- **D3** (the guard idiom's own example doesn't compile) — manual fixed
  to show the idiom that does (LST-67).
- **D4** (the cast-to-convert idiom is a compile error) — manual fixed to
  say so explicitly (LST-68).
- **D5** (an opaque value's list write silently guesses a type) — **the
  compiler was fixed** (vox #45), not just the manual: the ambiguous
  write is now refused at compile time. Re-verified directly against
  0.4.9. LST-18/19/20 rewritten, LST-21 withdrawn.
- **D6** (the cyclic-list example's output was an abbreviation
  unmarked as one) — manual fixed, now says "abbreviated" explicitly.
- **D7** (a collection interpolated outside `Print` renders a raw
  address) — **the *variable*-form sub-case this ledger tested is fixed**
  (vox #44), re-verified directly against 0.4.9. The *expression*-form
  sub-case (`"{element 2 of nested}"`) is a distinct, still-open finding
  tracked in `collections-b.md`'s own D7 — see below.
- **D8** (`is equal to` on two collections always answers "not equal") —
  **still open**, re-probed against 0.4.9, byte-identical. Recorded as a
  design decision for Josj, not a numbered fix in flight.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names the
leaf that already emits the construct — found by `grep` on the accessor or
keyword (`a list called`, `a map called`, `'s length`, `'s keys`, `element `,
`append`, `is a `), never by leaf name — or `none`. `status` follows
PROCEDURE.md §3.

**Lists and maps have the best existing coverage of any surface mapped so
far, and still nothing here is `verified`.** Five leaves emit collections
(`gen leaf list inrange`, `list oob`, `list mixed`, `map inrange`, `map oob`,
plus list use inside `gen leaf butif append`, `format value` and `format
types`). Between them they cover a good third of this section's constructs —
and every one of them stops at `Print`-and-eyeball. The uniform
assertion-free gap the buffers and values ledgers found holds here too.

Three whole sub-sections are untouched by any leaf: **nested lists**
(zero leaves emit a list inside a list), **type predicates** (`grep` for
`is a ` across `src/` finds only flag-schema text — not one predicate is
ever emitted), and **cycle-safe printing**.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` pinned to
the sibling `coreasm`) before being written.

## What can be asserted about a collection at all

This has to come before the table, because it constrains every
`assertable?` cell in it. **A collection has no whole-value oracle.**

- `is equal to` between two collections compiles and always answers "not
  equal", silently — including two lists built from the identical literal
  (**Discrepancy 8**);
- a collection's rendering can only be produced in `Print` position, and a
  program cannot read its own output back; capturing it into a text instead
  yields a raw heap address (**Discrepancy 7**).

So an assertion like `If xs is not equal to "[1, 2, 3]" then, Exit 95.`
compiles cleanly and fires on **every** run — a false-finding factory of
exactly the kind `CLAUDE.md` warns about, and the most expensive mistake
available on this surface.

The oracle that *is* available is element-wise and is enough for almost
everything here: `element N of`, `'s first`, `'s last`, `'s length`,
`'s empty`, `map's "key"`, `'s keys` / `'s values` (themselves lists, read
element-wise), the `is a <type>` predicates, and — for a nested child —
extraction into a declared `list`/`map` variable first, which works
(LST-28). Where a row's claim is *about* the rendering (LST-16, LST-24,
LST-32, LST-38, LST-53), the assertable part is the structure and the error
flag, not the printed text; those rows say so. (LST-54, formerly in this
list, is withdrawn as of 0.4.15 — #111, see below.)

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/collections-a/`, named `LST-NN.vox` for the first row it
covers, with any further rows named in its own header. Each file opens with a
`(...)` comment naming the claim, the `Ran:` command, and an
`expected output:` block recording what the compiler actually printed.

**36 `LST-NN.vox` probe files** plus **`D1.vox`–`D8.vox`** for the eight
discrepancies — 44 files. Re-run against vox 0.4.9 with `docs/check-
probes.sh` (now present in this worktree) on 2026-08-22: **44 passed, 0
failed, 0 skipped.** Four probes were re-recorded to match the fixed
behaviour: `LST-18.vox`, `LST-19.vox` and `D5.vox` are now compile-error
probes (vox #45 turned a silent wrong value into a compile-time
rejection) and `D7.vox`'s verdicts flip from `WRONG` to `ok` (vox #44).

Three probes deliberately print a **verdict** rather than the value under test
(`LST-35`, `D7`, `D8`): the value there is a live heap address that changes
between runs, and a probe whose output wanders cannot be re-checked. That is the same
rule generated programs live under, and it is the point of Discrepancy 7.

Rows with no probe file: LST-05 (not assertable — nothing to run), LST-07
(no syntax of its own; folded into LST-06), LST-15 (folded into LST-06),
LST-50 (a cross-reference to `values.md` VAL-27, probed there), LST-67 and
LST-68 (their repros are `D3.vox` and `D4.vox`).

## The table

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| LST-01 | 2376–2383 | Lists are created with square brackets and comma-separated values; all four literal forms compile (number list, text list, mixed list, empty list). | emit each of the four literal shapes, print each | yes, **element-wise only** — `If element 1 of nums is not 1 then, Exit 95.` plus `If nums's length is not 3 then, Exit 95.`. The whole-rendering form is unavailable: see **Discrepancy 8** | `gen leaf list inrange`/`list oob` (2-element number literal only), `gen leaf list mixed` (number+text+float), `gen leaf butif append`/`format value` (`[]`) | exercised — no leaf emits a **text-only** literal, and none asserts | |
| LST-02 | 2386 | Lists are 1-indexed: `element 1 of` is the first element. | read `element 1` of a list whose first element the generator chose, assert it | yes — `If element 1 of xs is not 10 then, Exit 95.` | `gen leaf list inrange` emits `Print element 1 of l{n}` but never asserts **which** element came back, so 1-vs-0 indexing is never actually pinned | exercised (construct); todo (the assertion that fixes the base) | |
| LST-03 | 2387 | A list literal may contain mixed types. | emit a literal mixing at least two of number/text/decimal/boolean | yes — assert each slot reads back as its own type | `gen leaf list mixed` (number, text, float — never a boolean) | exercised; todo for a boolean in the literal | |
| LST-04 | 2388 | Empty lists `[]` are allowed. | declare `[]`, assert `length` is 0 and it prints `[]` | yes — `If xs's length is not 0 then, Exit 95.` and `If xs's empty is not 1 then, Exit 95.` | `gen leaf butif append`, `gen leaf format value` both declare `[]` then append into it | exercised; todo (nothing asserts the empty state before the first append) | |
| LST-05 | 2389 | Lists are allocated on the heap with automatic memory management. | — | **no** — no allocation or free is observable from inside a Vox program; there is no leak channel. Same category as BUF-04/BUF-08 | n/a | not assertable | |
| LST-06 | 2393 | A list may freely hold numbers, texts, decimals and booleans together. | one literal holding all four, iterated | yes — assert each printed element | `gen leaf list mixed` (three of the four; no boolean) | exercised; todo (boolean slot + assertions) — hand-verified (`LST-06.vox`) | |
| LST-07 | 2394 | The author never declares mixedness — the compiler resolves it. | — | not separately assertable: there is **no syntax** to declare it, so the claim is proved by every mixed literal that compiles | `gen leaf list mixed` | folded into LST-06 | |
| LST-08 | 2394–2397 | Lists the compiler can prove homogeneous keep a statically-typed fast path; lists with mixed elements carry a per-slot runtime tag instead. | emit a homogeneous list and do arithmetic on the loop variable (accepted); the mixed counterpart is rejected | **partly** — the difference is observable only as a **compile-time accept/reject**, which a runtime leaf cannot assert. The accepted half runs and is assertable (`If item add 1 is not …`) | `gen leaf butif append` does arithmetic on list-sourced numbers, but from variables, not from a `For each` loop variable | todo — hand-verified the accepted half (`LST-08.vox`); the rejected half is **Discrepancy 3** | |
| LST-09 | 2396–2397 | Every element of a mixed list prints and reads back as what it is. | iterate a mixed list, assert each element | yes — the generator chose every literal | `gen leaf list mixed` prints, never asserts | exercised; todo (verification) — hand-verified (`LST-06.vox`) | |
| LST-10 | 2399–2403 | Worked example: `[1, "two", 3.5, yes]` iterated with `For each … print item` prints `1`, `two`, `3.5`, `1`. | reproduce and assert the four lines | yes | `gen leaf list mixed` is the same shape minus the boolean | exercised; todo (boolean + assertions) — hand-verified (`LST-06.vox`) | |
| LST-11 | 2405 | `append` onto a mixed list respects the appended element's actual type. | append a text onto a number-headed mixed list, assert it reads back as a text | yes | `gen leaf list inrange` appends a **number** onto a number list; `gen leaf format value` appends a text onto an empty list; neither appends across a type boundary into an already-mixed list | todo — hand-verified (`LST-11.vox`) | |
| LST-12 | 2405 | `set element N of` respects the new element's actual type (it retypes the slot). | `set element 1 of` a mixed list to a text, assert the slot reads back as a text | yes | none — `set element` is never emitted by any leaf (`grep "set element"` in `src/` finds nothing) | todo — real gap, hand-verified (`LST-11.vox`) | |
| LST-13 | 2405 | `element N of` respects each slot's actual type. | read every slot of a mixed list, assert each | yes | `gen leaf list inrange`, `gen leaf format value` read `element 1` only, of a homogeneous list, unasserted | exercised (homogeneous only); todo (mixed + assertions) — hand-verified (`LST-11.vox`) | |
| LST-14 | 2405 | `'s first` / `'s last` respect the slot's actual type. | read both on a mixed list, assert | yes | none — `grep "'s first"` / `"'s last"` in `src/` finds no leaf emitting either on a list | todo — real gap, hand-verified (`LST-11.vox`). Property itself is an LST2 row (2688–2692) | |
| LST-15 | 2405 | Iteration respects each element's actual type. | — | yes | `gen leaf list mixed` | folded into LST-06/LST-10 | |
| LST-16 | 2405 | `{...}` format interpolation respects each element's actual type. | interpolate a whole mixed list in **print position** | **no** — the rendering is only produced in print position, and printed text cannot be read back (**Discrepancy 8**); capturing it into a text to compare is exactly what **Discrepancy 7** breaks. Exercise-only claim | `gen leaf format types` interpolates `{hl{n}}` and `{hm{n}}` inside a `Print`, unasserted | exercised; todo (verification) — hand-verified (`LST-11.vox`) | |
| LST-17 | 2407 | Booleans print as `1`/`0`, matching homogeneous boolean lists. | emit a boolean-only list and a mixed list containing booleans, assert both renderings | yes, element-wise — `If element 1 of flags is not 1 then, Exit 95.` and `If element 2 of flags is not 0 then, Exit 95.` (a boolean slot read back compares against 1/0). Not by rendering: **Discrepancy 8** | none — no leaf puts a boolean in a list at all | todo — hand-verified (`LST-17.vox`) | |
| LST-18 | 2429–2437 | **Claim reversed, 2026-08-22 — the compiler was fixed, not just documented.** A function whose return type is *not* declared is "the one thing a slot cannot be written from" — appending its result to a list is now a **compile error** naming both fixes ("declare it... or assign it to a declared variable first"). The old claim ("widens the list to mixed... always read back as what it is") was Discrepancy 5, and Discrepancy 5's compiler-side fix (vox #45) changed the *behaviour*, not just the manual: the ambiguous write is now refused outright rather than guessed at. | emit `append <undeclared-return-call> to <list>` → expect a compile error naming both rewrites | **no, from a runtime leaf** — this is now a compile-error claim (same category as `values.md` VAL-08); the compile-time guard is what a leaf must now *avoid* triggering, not exercise | none | not assertable (compile-error claim) — **re-verified against 0.4.9, 2026-08-22**: `append five of 4 to items.` (an undeclared-return `five`) now refuses to compile with exactly this diagnostic, where it used to compile and print a raw address. Discrepancy 5 RESOLVED. | |
| LST-19 | 2439–2443 | **Claim reversed — this is now the manual's own compile-error example, not a passing one.** The worked widening example the manual shows is `To five with a number called x. Return x add 1. a list called items is []. append five of 4 to items.` with the recorded result `(compile error: 'five' has no declared return type)`. | reproduce, assert the compile error | **no, from a runtime leaf** (compile-error claim, same as LST-18 — this is now the same construct) | none | not assertable (compile-error claim) — re-verified against 0.4.9: reproduces the exact diagnostic quoted in the manual. What used to be Discrepancy 1 (the old `hello` example needed quoting) is moot — the manual's current example already quotes `"hello"` correctly at 2288 and no longer uses this construct as its worked example at all; that quoting fix (D1) is confirmed landed too. | |
| LST-20 | 2425–2427 | A function result whose return type **is** declared is statically known, is tagged with that type at the write, and widens the list only because its type differs from the other elements. | append a `Return a text, …` result next to a number, assert the text reads back as a text | yes | none | todo — hand-verified (`LST-20.vox`); contrast with LST-18, which is the same program minus the declared return type — and which is now a compile error rather than a runtime widening | |
| LST-21 | — | *(withdrawn, manual 0.4.9)* Residual limitation: for a genuinely opaque value the slot's own tag may still be a conservative `TAG_INTEGER` guess; the list still widens and reads dispatch on tags, "so the value prints correctly **when it really is a number**". **This paragraph no longer exists in the manual.** It described the pre-fix behaviour Discrepancy 5 found (a silent guess); now that the compiler refuses the write outright (LST-18), there is no guess left to hedge about. | — | — | — | withdrawn (manual 0.4.9) — superseded by LST-18's compile-time rejection | |
| LST-22 | 2458 | A list element may itself be a list. | emit a literal with a list inside it, read the child back | yes — assert the child's rendering | none — no leaf emits a nested collection literal (`grep` for `[[` and for a list name inside a list literal finds nothing) | todo — real gap, hand-verified (`LST-22.vox`) | |
| LST-23 | 2458–2460 | A nested list prints recursively with brackets; a list value in a slot carries the list tag (4). | extract the child into a `list` variable and assert its `length` and elements — the parent's printed brackets themselves are not capturable | yes, element-wise (**Discrepancy 8**) | none | todo — hand-verified (`LST-22.vox`) | |
| LST-24 | 2460–2467 | `[1, [2, 3], "four"]` prints exactly as written. | assert every slot: `element 1` is a number, `element 2` extracts as a list of length 2, `element 3` is the text | yes, element-wise; the exact printed text is **not** assertable (**Discrepancy 8**) | none | todo — hand-verified (`LST-22.vox`) | |
| LST-25 | 2461–2462 | A homogeneous list-of-lists (`[[1, 2], [3, 4]]`) keeps the statically-typed fast path — it is not mixed. | emit one, assert that both children extract cleanly and carry the right lengths | yes, element-wise; the fast path itself is a compile-time property (same limit as LST-08) | none | todo — hand-verified (`LST-22.vox`) | |
| LST-26 | 2464–2470 | Worked example: `print nested` → `[1, [2, 3], "four"]`; `print element 2 of nested` → `[2, 3]`. | reproduce, assert the extracted child's length and elements | yes, element-wise (**Discrepancy 8**) | none | todo — hand-verified (`LST-22.vox`) | |
| LST-27 | 2469–2470 | Two-level extraction chains: `element 2 of element 2 of deep` → `[3, 4]`. | emit a chained `element N of element M of`, assert | yes | none — no leaf chains element access at all | todo — real gap, hand-verified (`LST-22.vox`) | |
| LST-28 | 2473–2475 | `element N of`, `first`/`last`, iteration and whole-list print all yield a **usable child list**: its `length`, its own `element N of`, and a `For each` over it all work. | extract a child into a `list` variable, assert length, element, and the loop's output | yes | none | todo — hand-verified (`LST-28.vox`) | |
| LST-29 | 2477–2480 | Worked example: `inner` extracted from a literal has `length` 2 and iterates `2`, `3`. | reproduce, assert | yes | none | folded into LST-28 — hand-verified in `LST-28.vox` | |
| LST-30 | 2483–2485 | The `is a list` predicate recognises a nested-list element by its runtime tag and folds to true on a statically-typed list variable. | emit the predicate on both a mixed element and a declared list, assert the branch taken | yes — the generator knows which slot is the list | none — **no leaf emits any type predicate** | todo — real gap, hand-verified (`LST-30.vox`) | |
| LST-31 | 2487–2490 | Worked example prints `s`, `L`, `s`. | reproduce, assert the three lines | yes | none | folded into LST-30 — hand-verified in `LST-30.vox` | |
| LST-32 | 2520–2523 | **Claim narrowed, 2026-08-29 (0.4.15, #111) — the reason for the cap changed, the cap itself did not.** Printing still caps recursion at a depth of 64 as a defensive backstop: an over-deep subtree prints `...` and sets the error flag. The old framing ("a list that contains itself would recurse forever, so printing is capped") is gone — since #111 makes nesting always copy, **a list can never truly contain itself any more**, so the cap is no longer a cycle-safety mechanism in practice; it now guards only the hypothetical of 64 separate, explicitly-written nested literal levels, which "ordinary nesting never approaches." | build a list nested 64 explicit levels deep (no self-reference will do it any more — see LST-33), print it, assert the error flag and that the program continues | yes for the error flag and the survival — which is the memory-safety half. The 64-bracket rendering itself is not capturable (**Discrepancy 8**), so the depth cap stays eyeball-only | none — no leaf builds a 64-deep literal | todo — **still the single most valuable untested claim in this section for a memory-safety fuzzer, and now more expensive to reach**: 64 explicit levels must be generated, not one `append x to x.` (see LST-33). Old probe (`LST-32.vox`, self-referential, 0.4.14) is stale — its own construction no longer reaches the cap at all, see LST-33 | |
| LST-33 | withdrawn (manual v0.4.15, #111) | **Withdrawn, 2026-08-29.** The worked example this row cited — `a list called x is []. append x to x. print x.` prints the 64-deep capped form, then `cyclic` from an `On error` handler — no longer exists in any form: LANGUAGE.md now states the opposite result for that exact program. Verified directly against the 0.4.15 stack (`nested-selfappend.vox`, `VOX_CORE_PATH=.../wt-stack-0415/coreasm .../stack-0415/vox-stack`): `print x.` now prints `[[]]`, no error, no handler firing. See the new self-append row(s) added 2026-08-29 (LANGUAGE.md:2517–2519) for the claim that replaces this one; see LST-32 for what the depth cap still means. | — | — | — | withdrawn — superseded by the new self-append semantics (#111); no longer a live claim | |
| LST-34 | withdrawn (manual v0.4.15, #111) | **Withdrawn, 2026-08-29.** "Extracting a child with `element N of` yields a *reference*, not a copy … a child extracted before [a reallocation] may point at freed memory" — this whole two-sentence limitation paragraph has been deleted from LANGUAGE.md outright, not reworded: `grep` for "freed memory", "a reference to the child" and "One limitation remains" (Nested Lists' own copy) across the 0.4.15 manual finds none of them. The replacement text (LANGUAGE.md:2496–2515, #111) asserts the **opposite**: "a collection placed inside another collection is a copy, not a shared reference … reading a nested collection back out (`element N of`, …) all copy." Verified directly (`nested-elementcopy.vox`, the manual's own two-mutation worked example): mutating `inner` after nesting it in `outer`, and mutating a `got` extracted via `element 1 of outer`, both leave `outer` as `[[1, 2], 3]` throughout — no aliasing, so the reallocation hazard this row described cannot occur any more. See the new element-N-of-copies row(s) added 2026-08-29 for the claim that replaces this one. | — | — | — | withdrawn — superseded by the new copy-in semantics (#111); no longer a live claim | |
| LST-35 | n/a — the manual's two sentences documenting this limitation are **gone** (0.4.10, #68) | **Claim reversed, 2026-08-22 — the limitation is fixed, not just documented differently.** The manual used to warn that the **expression** form of format interpolation (`"{element 2 of nested}"`) has no runtime-tag dispatch, so a nested list did not render there; use the **variable** form `"{nested}"` instead. 0.4.10's #68 fixed the underlying bug: the hole's expression path now dispatches on the slot's runtime tag "in every sink — Print, a text initializer, buffer `set`/`copy`/`append`, `write`, filesystem paths, `treating` clauses and function arguments" (CHANGELOG.md #68), so the two LANGUAGE.md sentences that documented the limitation were removed outright rather than reworded — "One limitation remains for this stage" (this row's own citation target — see LST-34) replaced the old "Two limitations remain", and as of 0.4.15 (#111) that "one limitation" sentence is **itself** gone too (LST-34, withdrawn): the Nested Lists subsection carries no "limitation" language of any kind any more. | emit the expression form in Print position and in a non-print sink (text initializer, buffer `copy`), assert the rendering matches the variable form's | yes now — the rendering is stable and correct, so a whole-value text comparison works: `If rendered is not "[2, 3]" then, Exit 95.` (the old probe's live-heap-address hazard is gone) | none emits the expression form on a collection; `gen leaf format types` uses the variable form only | todo — **hand-verified fixed against 0.4.10** (`LST-35.vox`, rewritten): the expression form now renders `[2, 3]` identically in `Print`, a text initializer, and a buffer `copy`. This closes the expression-form sub-case of **Discrepancy 7** (tracked there as vox candidate #68, now landed) | |
| LST-36 | 2527–2528 | A map is a key/value collection — a JSON object; keys are text and values may be any type (number, text, decimal, boolean, list, or another map). | emit a map whose values span several types, assert each keyed read | yes, entry-wise | `gen leaf map inrange`/`map oob`, `gen leaf format value`/`format types` — all with **text and number values only** | exercised (number/text values); todo (decimal, boolean, list, map values + assertions) — hand-verified (`LST-36.vox`, `LST-52.vox`) | |
| LST-37 | 2528–2529 | A map literal uses braces with `"key": value` pairs; an empty map is `{}`. | emit both the populated literal and `{}`, assert `length` and `empty` | yes | `gen leaf map inrange`/`map oob`/`format value`/`format types` emit populated literals; **no leaf emits `{}`** | exercised (populated); todo (`{}` and assertions) — hand-verified (`LST-36.vox`) | |
| LST-38 | 2531–2536 | Worked example: `person` prints `{"name": "Ada", "age": 36}` and `emptymap` prints `{}`. | reproduce, assert each key's value and both `length`s | yes, entry-wise; the whole rendering is **not** assertable (**Discrepancy 8**) | none asserts a map's contents at all | todo — hand-verified (`LST-36.vox`) | |
| LST-39 | 2538 | Read a value by key with `map's "key"`, the key written as a text literal. | read a known key, assert the value | yes | `gen leaf map inrange` (`Print m{n}'s "label"`, `Print m{n}'s "count"`), unasserted | exercised; todo (verification) — hand-verified (`LST-39.vox`) | |
| LST-40 | 2538–2539 | A quoted key carrying `{...}` interpolation builds a **dynamic** key. | emit a read and a write whose key comes from a runtime variable, assert | yes — the generator chose the variable's value | none — every key in every leaf is a compile-time literal baked into the generated source | todo — real gap (the dynamic-key code path is never taken), hand-verified (`LST-40.vox`) | |
| LST-41 | 2539–2541 | The value read back carries its runtime tag, so a text prints as text and a number as a number. | read a text-valued and a number-valued key, assert both | yes | `gen leaf map inrange` reads one of each, unasserted | exercised; todo (verification) — hand-verified (`LST-39.vox`) | |
| LST-42 | 2543–2546 | Worked example: `person's "name"` → `Ada`, `person's "age"` → `36`. | reproduce, assert | yes | as LST-39 | folded into LST-39 — hand-verified in `LST-39.vox` | |
| LST-43 | 2548 | `Set map's "key" to value` inserts a new entry or replaces an existing one. | emit both a replace and an insert, assert value and `length` after each | yes | `gen leaf map inrange` emits `Set m{n}'s "count" to …` — a **replace** only; no leaf ever inserts a new key | exercised (replace); todo (insert + assertions) — hand-verified (`LST-43.vox`) | |
| LST-44 | 2548–2554 | **Claim extended, 2026-08-22 (0.4.10, #75).** The map may reallocate on growth, so the returned pointer is stored back into the variable automatically — **including when the variable is a `map` parameter, in which case the caller's map is what grows** (new clause; cross-references the new [A collection parameter is the caller's collection](#a-collection-parameter-is-the-callers-collection) section, LANGUAGE.md:845). Before #75, a `map`/`list` parameter's growth silently stopped after `max(8, element count)` elements and leaked the block it outgrew (CHANGELOG #75) — the local-variable half of this claim held on 0.4.9, but the parameter half did not. | grow a map well past its initial capacity, read every entry back; separately, grow a `map` **parameter** past its initial capacity from inside a function and assert the growth is visible to the caller | **partly** — the reallocation itself is an implementation detail with no Vox-visible handle; what is assertable is the observable consequence (every entry survives many inserts, and — new — that a caller's map reflects growth done through a parameter) | none — no leaf inserts more than one key into a map, and no leaf grows a collection through a function parameter at all | todo — hand-verified at 200 inserts (`LST-44.vox`); the parameter half hand-verified separately against 0.4.10 (see `functions.md` for the `#a-collection-parameter-is-the-callers-collection` claim — not yet its own row here) | |
| LST-45 | 2555–2558 | Worked example: after `set person's "age" to 37`, `length` is still 2 — a replace, not an insert. | reproduce, assert `length` | yes | `gen leaf map inrange` emits both the `Set` and a `Print m{n}'s length`, but never asserts that the length did **not** change | exercised; todo (the assertion is the whole claim) — hand-verified (`LST-43.vox`) | |
| LST-46 | 2561 | `length` is the live entry count and `empty` is true only at zero entries, as for lists. | assert `length` and `empty` on a populated and an empty map | yes | `gen leaf map inrange` prints `'s length`; **no leaf reads `'s empty` on a map** (`environment's empty` and a buffer's `is empty` are different targets) | exercised (`length`); todo (`empty` + assertions) — hand-verified (`LST-36.vox`) | |
| LST-47 | 2562–2563 | `keys` and `values` each yield a **fresh** list, in insertion order. | mutate the returned list and assert the map's `length` is unaffected; assert `element N of` the keys list after a replace and after an insert | yes, element-wise — the generator chose the insertion order | `gen leaf map inrange` emits `For each k{n} in m{n}'s keys, Print k{n}`; **no leaf reads `'s values` at all**, and nothing asserts order or freshness | exercised (`keys` iteration); todo (`values`, freshness, order) — hand-verified (`LST-47.vox`) | |
| LST-48 | 2565–2568 | Worked example: iterating `person's keys` prints `name`, `age`; iterating `person's values` prints `Ada`, `37`. | reproduce, assert both sequences | yes | as LST-47 | folded into LST-47 — hand-verified in `LST-47.vox` | |
| LST-49 | 2570–2581 | **Claim extended, 2026-08-22 (0.4.10, #72/#91).** A missing key does not crash: the lookup sets the error flag, so an `on error` handler reacts, and yields a value the destination can hold. Before 0.4.10 this always meant the untyped number 0 (which a `text`/`list`/`map` destination could then dereference as a pointer and segfault — #91). As of 0.4.10 the rule splits: where the compiler can **prove** the key absent (a map literal it can see all of), the read is the **number** 0 regardless of the map's value types, so only a `number`/`float`/`boolean` destination is legal — a `text`/`list`/`map` destination is refused at compile time, naming the key (#72). Where it **cannot** prove it (a dynamic key, or a map reachable through `Append`/`Set`/an alias/a call), the read yields the destination's **typed default** instead — `0`/`""`/`[]`/`{}` (#91). | read an absent key from a **literal** map (compiler-provable) into a `number`, assert 0 and the error flag; separately read an absent key from a **`Set`-grown** map into a `text`/`list`/`map` destination, assert the typed default and the error flag | yes — both halves are now cleanly assertable with a plain value comparison | `gen leaf map oob` reads a missing key and catches it — but never captures or asserts the returned value, and never demonstrates the typed-default half on a non-number destination | exercised (error-flag half); todo (the provable-0 assertion, and the new typed-default half) — **hand-verified against 0.4.10**: the provable case (`gen leaf map oob`'s own shape) is unchanged from 0.4.9 (still 0); the unprovable/typed-default case is genuinely new territory — a `Set`-grown map's missing key read into `text`/`list`/`map` now yields `""`/`[]`/`{}` respectively, where pre-0.4.10 it would have handed a raw 0 to a pointer-typed read | |
| LST-50 | 2581–2583 | "No such key" stays distinguishable from "the key is set to `nothing`". | read an absent key and a `nothing`-valued key, assert the two behave differently | yes | none — no leaf emits `nothing` anywhere (`values.md` VAL-21) | todo — cross-reference: probed as `values.md` **VAL-27**, not re-probed here. Citation shifted only (2430–2432 → 2561–2563); claim itself unaffected by the 0.4.10 missing-key rule change (LST-49) | |
| LST-51 | 2585–2588 | Worked example: `print person's "nope"` prints `0` and the handler prints `missing`. | reproduce, assert both lines | yes | `gen leaf map oob` is the same shape without the assertion | folded into LST-49 — hand-verified in `LST-49.vox` | |
| LST-52 | 2590 | A map value may be a list or another map, and printing is recursive. | emit a map holding a list and a map, extract each child into a typed variable, assert its length and entries | yes, entry-wise (**Discrepancy 8**) | none — every map value in every leaf is a number or a text | todo — real gap, hand-verified (`LST-52.vox`) | |
| LST-53 | 2590–2593 | **Claim narrowed, 2026-08-29 (0.4.15, #111) — same treatment as LST-32.** `_map_print` shares the same 64-deep `_print_depth` budget as `_list_print`, **as a defensive backstop** — the old framing ("so a mixed map/list tree is cycle-safe") is gone, since #111 makes nesting always copy, so a genuine map→list→map cycle can no longer be built at all. The cap now only guards a hypothetical of 64 separate, explicitly-written nested levels. | build a map/list tree nested 64 explicit levels deep (no self-reference will do it any more — see LST-54, withdrawn), print it, assert the error flag and that the program continues | yes for the error flag and the survival — which is the memory-safety half; the 64-level rendering itself is not capturable (**Discrepancy 8**) | none | todo — **still worth building, and now more expensive to reach** (64 explicit levels, not a `set m's "self" to m.` cycle). Old probe (`LST-53.vox`, map→list→map self-reference, 0.4.14) is stale — its own construction no longer reaches the cap at all, see LST-54 | |
| LST-54 | withdrawn (manual v0.4.15, #111) | **Withdrawn, 2026-08-29 — same treatment as LST-33.** The claim this row cited — a self-referential map (`set m's "self" to m.`) prints 64 levels deep, then `...`, sets the error flag, and unwinds safely — no longer exists in any form: LANGUAGE.md now states the opposite result for that exact statement (LANGUAGE.md:2593–2597, #111). Verified directly against the 0.4.15 stack: `set m's "self" to m.` now nests exactly **one** level deep, no error, no `...`. See LST-82 for the claim that replaces this one. | — | — | — | withdrawn — superseded by the new copy-in semantics (#111); no longer a live claim | |
| LST-55 | 2599–2601 | The `is a map` predicate folds to true on a statically-typed map variable and compares the tag at run time on a mixed value. | emit both forms, assert the branch | yes | none — no leaf emits any predicate | todo — hand-verified (`LST-55.vox`) | |
| LST-56 | 2601–2604 | A map rides the `value` ABI: passed to a `value` parameter or returned from a `value` function it carries its tag (5) alongside the payload and round-trips intact. | pass a map through a `value` function, assert the rendering and `is a map` on the way out | yes | `gen leaf value roundtrip` emits a `value` local but never a `value` **parameter or return**, and never a map through one (`values.md` VAL-02) | todo — hand-verified (`LST-56.vox`); `'s type` reports `Map (dynamic)`, consistent with VAL-14 | |
| LST-57 | 2606–2620 | **Claim corrected, 2026-08-22 — the manual now describes the real behaviour instead of the wrong one.** A map may be an element of a list (`[{"a": 1}, {"b": 2}]`); the slot carries the map tag (5), so `is a map` fires on a `For each` loop variable over such a list. The loop variable itself is **deliberately untyped**, though, and reading a key with `'s "key"` is a *static* check, so `entry's "tag"` inside the loop is a compile error — read a key by looping over the positions and declaring the element instead (worked example at 2460–2465, verbatim the idiom Discrepancy 2's resolution proposed). | emit a list of maps, iterate it, assert `is a map` fires on the loop variable; separately, emit the position-loop idiom and assert the keyed read | yes for both halves now that the manual states the real rule | none — no leaf puts a map in a list | todo — the tag half holds (`LST-57.vox`, `LST-55.vox`); the direct `entry's "tag"` form is **correctly** a compile error, not a bug — Discrepancy 2 RESOLVED (manual corrected to match the compiler, exactly the lawyer's recommendation) | |
| LST-58 | 2622–2623 | Limitation: keys are text only — a non-text key is rejected with "Map keys must be text". | emit a numeric key → expect a compile error | **no, from a runtime leaf** — emitting a known compile error breaks the generator's "legal Vox that should compile and run" contract (same category as `values.md` VAL-08) | none | not assertable (compile-error claim) — hand-verified (`LST-58.vox`) | |
| LST-59 | 2623–2624 | Limitation: there is no map entry deletion. | — | **no** — the claim is the absence of a feature; there is nothing to emit | none | not assertable (absence claim) — hand-verified (`LST-59.vox`): `Delete <map>'s "key".` does compile, but as the **file**-deletion sentence (LANGUAGE.md:4094) applied to the key's value, so it sets the error flag and changes nothing. No silent near-miss | |
| LST-60 | 2628–2630 | `is a <type-noun>` compares the value's runtime type tag, so it works on a mixed-list element whose type is only known at run time. | emit the predicate on a mixed element, assert the branch taken | yes — the generator knows every slot's type | none — `grep "is a "` across `src/` finds only flag-schema text (`it is a text`), never a predicate | todo — real gap, hand-verified (`LST-60.vox`) | |
| LST-61 | 2632–2640 | Worked example: the four-arm dispatch over `[1, "two", 3.5, yes]` prints `number: 1`, `text: two`, `decimal: 3.5`, `boolean: 1`. | reproduce, assert the four lines | yes | none | folded into LST-60 — hand-verified in `LST-60.vox` | |
| LST-62 | 2642 | The type nouns are `number`, `text`, `decimal`, `boolean`, `list`, `map`. | emit all six against a list holding one of each, assert each match | yes | none | todo — hand-verified all six (`LST-62.vox`) | |
| LST-63 | 2642–2643 | The declaration synonyms also work as predicate nouns: `integer`→number, `string`→text, `float`/`real`→decimal, `bool`→boolean, `dictionary`→map. | emit each synonym, assert it matches the same slot its canonical noun does | yes | none | todo — hand-verified all five synonym spellings, `real` included (`LST-63.vox`) | |
| LST-64 | 2644–2649 | Negate with `is not a`. | emit the negated form, assert the branch | yes | none | todo — hand-verified (`LST-64.vox`) | |
| LST-65 | 2651–2653 | `is a boolean` and `is a number` are distinct even though both print as numbers: a boolean carries tag 3, a number tag 0. | put a boolean and a number in one list, dispatch with `is a number` **first**, assert the boolean does not match it | yes — this is the ordering that catches a tag collision | none | todo — hand-verified (`LST-62.vox`, whose `is a number` arm comes first and the boolean falls through it) | |
| LST-66 | 2653–2656 | On a statically-typed value the predicate folds at compile time — it costs nothing and is always true — so the sentence is legal on **any** value, not just a mixed one. | emit the predicate on several declared variables, assert the true branch every time | yes | none | todo — hand-verified for number, text, list and map (`LST-64.vox`, `LST-30.vox`, `LST-55.vox`) | |
| LST-67 | 2658–2676 | **Claim corrected, 2026-08-22.** The predicate reads the runtime tag; it does **not** narrow the static type, so arithmetic on the tested value is refused inside the guard exactly as outside it. Guarding means getting the element into a *declared* variable — which a `For each` loop variable can never be — so loop over the positions instead (worked example at 2513–2522, verbatim the idiom Discrepancy 3's resolution proposed; the manual's old "guard it yourself" wording that implied `if item is a number, item add 1` works directly is gone). | emit the position-loop guard idiom, assert the number branch computes and the non-number branches fall through | yes — the working composition is now what the manual itself shows | none | todo — unblocked. Discrepancy 3 RESOLVED (manual corrected to show the idiom that actually compiles, not the one that doesn't) | |
| LST-68 | 2678–2683 | **Claim corrected, 2026-08-22.** The cast expression is explicitly **not** a way round the guard limitation: `item as a number` on a dynamically-tagged element is rejected for the same reason arithmetic is (`<value> as a <type>` converts a *statically*-typed value only). The manual no longer offers this as the recommended conversion — LST-67's position-loop idiom is. | emit the cast on a mixed element → expect a compile error, exactly as the manual now says to expect | **no, from a runtime leaf** — this is now correctly documented as a compile-error claim (same category as `values.md` VAL-08), not a passing construct | none | not assertable (compile-error claim) — Discrepancy 4 RESOLVED (manual corrected; overlaps `values.md` D2, also resolved) | |
| LST-69 | 2685–2687 | A predicate result is itself a boolean value: it can be stored in a list (`append item is a number to flags`) and each stored slot carries the boolean tag, so a later `is a boolean` recognises it. | emit the append-a-predicate form, assert each stored slot and the round-trip predicate | yes, element-wise — the generator knows every slot's type, so it knows every flag | none | todo — hand-verified (`LST-69.vox`) | |
| LST-70 | 2689–2693 | User-defined things are not in the tag system in v1: there is no `is a <thing>` predicate, and a `list` or `map` of user things, or a `value` holding one, is deferred. | emit `is a <thing>` → expect a compile error; emit a list of things → expect a compile error | **no, from a runtime leaf** (compile-error claims, same category as LST-58) | `gen leaf thing`/`thing member`/`thing copy` emit things, but never near a list, a map or a predicate — correctly, since all three are rejected | not assertable (compile-error claim) — hand-verified both halves (`LST-70.vox`; the list-of-things rejection is recorded in its header) | |
| LST-71 | 2493–2494 | **New row, 2026-08-29 (0.4.15).** Printing is recursive at any depth: a nested list prints exactly as written, however deep — a distinct, more general restatement of LST-23's "prints recursively with brackets" (2458–2459), new text as of 0.4.15. | build a list nested several levels deep (e.g. 4), print it, assert the exact rendering | yes — the generator wrote every element | none | todo — hand-verified (`a list called deep is [1, [2, [3, [4, 5]]]]. print deep.` → `[1, [2, [3, [4, 5]]]]`, exactly as written) | |
| LST-72 | 2496–2501 | **New row, 2026-08-29 (0.4.15, #111) — GitHub #34, owner ruling.** A collection placed inside another collection is a **copy**, not a shared reference: the parent owns its contents. This is the general rule the following rows (LST-73 through LST-79) each put on trial for one specific write-in or read-out form. | — | n/a — a framing claim, not independently testable; see the sub-claim rows | n/a | not a leaf need — the sub-claim rows below carry the assertions | |
| LST-73 | 2498–2499 | Building a list or map literal with a collection element copies it. | build `outer` from a literal containing a previously-declared `inner`, mutate `inner` afterward, assert `outer`'s copy is unaffected | yes | none | todo — hand-verified (`a list called inner is [1, 2]. a list called outer is [inner, 3]. Set element 1 of inner to 777. print outer.` → `[[1, 2], 3]`, unaffected) | |
| LST-74 | 2499 | Appending a collection to a list copies it. | `append` a previously-declared list into another list, mutate the source afterward, assert the destination's copy is unaffected | yes | none | todo — hand-verified (`append src to out.` then `Set element 1 of src to 999.` leaves `out` as `[[1, 2]]`, `src` as `[999, 2]`) | |
| LST-75 | 2499–2500 | Setting a map value to a collection copies it. | `Set map's "key" to <list>` from a previously-declared list, mutate the source afterward, assert the map's copy is unaffected | yes | none | todo — hand-verified (a map built from `{"key": inner}` then `Set element 1 of inner to 999.` leaves the map's `"key"` as `[1, 2]`) | |
| LST-76 | 2500–2501 | Reading a nested collection back out with `element N of` copies it. | extract a nested element with `element N of`, mutate the extracted copy, assert the parent is unaffected | yes | none | todo — hand-verified (`a list called got is element 1 of outer. Set element 1 of got to 555. print outer.` → still `[[1, 2], 3]`) | |
| LST-77 | 2500–2501 | Reading a nested collection back out with `'s first`/`'s last` copies it. | extract with `'s first`, mutate the extracted copy, assert the parent is unaffected | yes | none | todo — hand-verified (`a list called f is outer's first. Set element 1 of f to 999.` leaves `outer` as `[[1, 2], [3, 4]]`, `f` as `[999, 2]`) | |
| LST-78 | 2500–2501 | Reading a nested collection back out as a map value copies it. | read a map value that is itself a list, mutate the extracted copy, assert the map is unaffected | yes | none | todo — hand-verified (`a list called got is m's "key". Set element 1 of got to 555.` leaves `m`'s `"key"` as `[1, 2]`) | |
| LST-79 | 2500–2501 | Reading a nested collection back out via a `For each` loop binding copies it. | bind the loop variable to a nested-collection element, declare a fresh variable from it, mutate that, assert the parent is unaffected | yes | none | todo — hand-verified (`For each item in outer, a list called captured is item, Set element 1 of captured to 999.` leaves `outer` as `[[1, 2], [3, 4]]`) | |
| LST-80 | 2506–2515 | The worked example (declare `inner`/`outer`, mutate `inner`, print `outer` unaffected; extract `got` via `element 1 of`, mutate `got`, print `outer` still unaffected) compiles and behaves exactly as shown. | reproduce verbatim | yes | none | todo (as a composite); sub-claims covered by LST-73 (the `inner`/`outer` half) and LST-76 (the `got` half) | |
| LST-81 | 2517–2519 | **Replaces withdrawn LST-33.** Because nesting always copies, a list can never truly contain itself: `a list called x is []. append x to x.` copies `x`'s state at the moment of the append (here, `[]`) and appends that copy, so `x` ends up `[[]]` — one level deep, not a cycle. | reproduce verbatim, assert the exact result | yes | none | todo — hand-verified (`a list called x is []. append x to x. print x.` → `[[]]`, no error, no cycle) | |
| LST-82 | 2593–2597 | **New row, 2026-08-29 (0.4.15, #111).** A map value that is itself a collection is copied in — the same copy-in rule a list applies to its own elements — so `set m's "self" to m.` copies `m`'s state at the moment of the `set` (before `"self"` exists in it) rather than making `m` contain itself: `m` ends up one level deep, not a cycle. | reproduce, assert the exact result | yes | none | todo — hand-verified (`a map called m is {"a": 1}. set m's "self" to m. print m.` → `{"a": 1, "self": {"a": 1}}`, one level deep) | |

## Discrepancies

Bonus finding from adjudication (lawyer): the symbol-located diagnostic caret can land inside a COMMENT — `(mentions hello here)` on line 1 then `append hello to items.` reports `1:11`, under the comment. Every probe whose header quotes the offending token will mis-point. Register entry.

### 1. The worked mixed-list example does not compile as printed — RESOLVED

LANGUAGE.md:2440–2443 (old: 2238–2243):

```
To five with a number called x. Return x add 1.
a list called items is [].
append hello to items.
append five of 4 to items.
print element 1 of items.   (prints: hello)
```

Line 2240's `hello` is unquoted. Compiling it (`D1.vox`) gives:

```
error: Unknown variable: hello
```

**Strongest reading under which the compiler is correct:** LANGUAGE.md:717–718
is explicit that 0.3.0 split the two meanings of a quoted token — `"..."` is a
string literal everywhere, a bare or single-quoted token is an identifier —
precisely to kill a family of silent wrong answers. Under that rule `hello` in
expression position **must** be an identifier, and there is no variable
`hello`, so the rejection is exactly right and the example is missing its
quotes. Repaired (`LST-19.vox`) it produces the documented output. A
documentation typo, not a compiler bug — but it is in a code block a mapper or
a leaf worker would copy verbatim.

**Resolution (lawyer, 2026-08-20): MANUAL BUG, high** — `hello` must be quoted; fix old manual line 2240 only. → vox docs PR.

**Resolution confirmed, 2026-08-22.** The manual's widening example now quotes `"hello"` (2288) and no longer uses the unquoted form anywhere. The *old* worked example (append hello / append five of 4) has been repurposed entirely — it is now the manual's own worked demonstration of Discrepancy 5's compile-error fix (LST-19).

### 2. A `For each` over a list of maps does not type the loop variable as a map — RESOLVED

Old manual line 2381–2383 (pre-0.4.9): "A map may also be an element of a list
(`[{"a": 1}, {"b": 2}]`) — the slot carries the map tag (5) and a `For each`
over such a list **types the loop variable as a map**." Repro (`D2.vox`):

```
a list called holder is [{"tag": 1}, {"tag": 2}].
For each entry in holder, print entry's "tag".
```
```
error: Map access target must be a map: entry
```

The tag half is true — `is a map` fires on the loop variable inside the very
same loop (`LST-55.vox`) — and extracting the element into a declared `map`
variable first works (`LST-57.vox`). Only the accessor is refused.

**Strongest reading under which the compiler is correct:** "types the loop
variable as a map" can be read as "the loop variable carries the map tag", not
"the loop variable is statically a map". Map access with `'s "key"` is a
*static* check (the diagnostic says so: "Map access **target** must be a
map"), and a `For each` loop variable over a heterogeneous-capable list has no
static type to check against — the same reason arithmetic on a mixed element
is refused (Discrepancy 3). Under that reading the compiler is internally
consistent and the manual's sentence promises more than the word "types"
delivers. What the manual does not give is any working way to read a key off a
map *inside* the loop, which is what a reader would take from that sentence.

**Resolution (lawyer): MANUAL BUG, medium-high** — the loop variable is deliberately untyped (analyzer removes its scalar type); "types the loop variable as a map" was never implemented. Composable today: `For each position from 1 to holder's length, a map called entry is element position of holder, print entry's "tag".` → manual sentence fixed + that idiom shown. (Propagating a homogeneous list's element type would be a feature — Josj's call.)

**Resolution confirmed, 2026-08-22.** LANGUAGE.md:2606–2620 now states the corrected rule verbatim and shows exactly this idiom as the worked example (2460–2465). Re-verified: `entry's "tag"` inside the loop is still, correctly, a compile error.

### 3. The guard idiom the manual prescribes does not compile — RESOLVED

Old manual line 2419–2421 (pre-0.4.9): "arithmetic on a mixed element still dispatches
statically, so guard it yourself before operating — `if item is a number, …
item add 1 …`." Repro (`D3.vox`) is that sentence:

```
a list called mixedbag is [1, "two", 3.5].
For each item in mixedbag,
  if item is a number, print item add 1. otherwise print "guarded away".
```
```
error: Cannot use a value item in arithmetic: its type is only known at
runtime, and arithmetic on a dynamically-tagged value is not currently
supported.
```

The identical statement over a homogeneous list compiles and runs
(`LST-08.vox`). The guard changes nothing: the rejection is unconditional on
the element's lack of a static type.

**Strongest reading under which the compiler is correct:** "dispatches
statically" is the compiler saying it resolves arithmetic from the *static*
type; a mixed element has none, so there is nothing to dispatch and it must
refuse. Read that way the sentence is a warning that arithmetic will not adapt
to the runtime tag, and "guard it yourself" means "get the value into
something statically typed first" — which does work:

```
a list called mixedbag is [1, "two", 3.5].
a number called extracted is element 1 of mixedbag.
print extracted add 1.        (prints 2)
```

The parenthetical at 2421 ("Automatic guarding is a later decision; see the
roadmap") supports that this area is unfinished. So the compiler is
consistent; the manual's *example* is the defect — it shows an idiom that
cannot be written, and it is the one idiom the section calls "the guard idiom
that makes mixed lists programmable".

**Resolution (lawyer): MANUAL BUG, high** — the compiler documents (analyzer/types.rs:172-188) that a predicate guard does not narrow; the manual's idiom is a dead end. NOTE the ledger's own workaround (extract into a declared variable inside the loop) also fails; only the index-loop form works: `For each position from 1 to mixedbag's length, if element position of mixedbag is a number, a number called got is element position of mixedbag, print got add 1. otherwise print "guarded away".` → manual fixed.

**Resolution confirmed, 2026-08-22.** LANGUAGE.md:2658–2676 now states the "does not narrow" rule explicitly and shows the index-loop idiom verbatim (2513–2522), matching the lawyer's proposed fix exactly.

### 4. The cast the manual recommends for converting a mixed element is a compile error — RESOLVED

Old manual line 2422–2424 (pre-0.4.9): "To *convert* a value rather than test it, use the cast
expression `<value> as a <type>` — e.g. `item as a number` or `item as a
float`." Both are rejected (`D4.vox`):

```
error: Cannot cast item to a number: item's type is only known at runtime, and
casting a dynamically-tagged value is not currently supported by the compiler
(a known gap, not yet resolvable from within the language).
```

**Strongest reading under which the compiler is correct:** the diagnostic
names it as a known, tracked gap rather than claiming the program is wrong, so
the compiler is refusing honestly rather than misbehaving. This is the same
missing conversion `values.md` Discrepancy 2 found from the `value` side
(ROADMAP finding 21) — but there the manual only used the cast as an
*analogy*, while here it is offered as the concrete thing to write, with the
mixed-list element named. Same underlying gap, strictly worse documentation
exposure. Worth adjudicating together with `values.md` D2.

**Resolution (lawyer): MANUAL BUG, high** over a real missing feature (plan 294 finding 21 / values.md D2). Delete or hedge the `item as a number` sentence. → manual fixed.

**Resolution confirmed, 2026-08-22.** LANGUAGE.md:2678–2683 now explicitly says the cast is refused for the same reason and points at the index-loop idiom instead. Re-verified: `item as a number` on a mixed element still fails to compile, as expected — it is documented as failing, not as working.

### 5. An opaque text in a list IS silently reinterpreted — and the manual contradicts itself about it — RESOLVED (compiler fixed, vox #45)

Old manual line 2232–2235 (pre-0.4.9) promised that an unprovable value "widens the list to
mixed, so the element is **always read back as what it is rather than silently
reinterpreted**". Old line 2250–2254 then conceded the slot tag "may still
be a conservative `TAG_INTEGER` guess" and narrows the promise to "the value
prints correctly **when it really is a number**". Repro (`D5.vox`):

```
To 'opaque label'. Return "hi".

a list called items is [].
append "anchor" to items.
append 'opaque label' to items.
print element 2 of items.
```
```
4210906
```

The text is stored tagged as a number; `is a number` fires on it, `is a text`
does not, and it prints a raw address. The address is **stable across runs**
(4210906, 5/5), because it is a static rodata address — so it looks like data,
not like a crash. That is precisely the failure mode LANGUAGE.md:725–728 says
0.3.0 was designed to eliminate: "a function pointer, printed as a number,
silently. No error, no warning; the program runs and gives a wrong answer that
looks like data."

**Strongest reading under which the compiler is correct:** the second
paragraph is the operative one. It names the mechanism (`TAG_INTEGER` guess),
names the fix (runtime tag propagation, stage 1d), points at
`docs/COLLECTIONS_ROADMAP.md`, and hedges the promise to the number case. Read
that way the compiler is doing exactly what the manual's own limitation
paragraph says it does, and the defect is that the paragraph twenty lines
earlier states the opposite without qualification. Under this reading nothing
needs to change in the compiler and one sentence at 2234–2235 needs the same
hedge the later paragraph carries.

Two things make it worth a human's attention anyway: the wrong value is a code
address, and there is no diagnostic. A leaf that appends an undeclared-return-
type call to a list would produce a program whose printed output is a pointer —
which is why LST-18 is `blocked on D5` rather than ready to build.

**Resolution (lawyer): MANUAL BUG, high + compiler defect (type confusion, NOT memory-unsafe), medium** — 2233-2235 is contradicted by 2250-2254. The defect is broader than lists: an undeclared return type is silently taken as an integer (`print 'opaque label'.` alone prints the address; a declared `text` destination saves it). Honest compiler fix: reject at the widening site like things.rs:817. → manual hedged; compiler defect filed as a register entry.

**Resolution confirmed, 2026-08-22: fixed exactly as recommended — reject at the widening site.** Re-run `D5.vox` against vox 0.4.9 directly: the program **no longer compiles**. `append 'opaque label' to items.` (an undeclared-return-type call) now fails with `error: 'opaque label' has no declared return type, so its result is read as a number here`, naming both fixes (declare the return type, or assign to a declared variable first). This is vox bug #45 (`vox/docs/BUGS_FOUND.md`). The manual's contradiction is resolved by removing the thing it contradicted itself about, not by hedging one side of it — see LST-18/19/20/21 above.

### 6. The cyclic-list example's recorded output is an abbreviation, not a transcript — RESOLVED, now MOOT (0.4.15, #111)

**Moot as of 2026-08-29 (0.4.15, #111).** The example this discrepancy was about — `a list called x is []. append x to x. print x.` producing a 64-deep, `...`-capped, `cyclic`-flagged print — no longer exists: #111 made nested collections copy on every write, so a list can never contain itself any more, and the same three-line program now prints `[[]]` with no error. "Abbreviated vs. verbatim" is no longer a live question for this program; the underlying wording question (does an inline `(prints: …)` comment mean "exact" or "shorthand") may still matter elsewhere, but this specific example has moved on. See LST-33 (withdrawn) and LST-32 (narrowed) above.

Old manual line 2303 (pre-0.4.9) recorded the self-referential list's output as
`(prints: [[...]] then cyclic)`. It actually prints 64 opening brackets, then
`...`, then 64 closing brackets, then `cyclic` (`D6.vox`, and the exact string
is in `LST-32.vox`'s recorded output).

**Strongest reading under which the compiler is correct:** the surrounding
prose (2293–2297) is exact — "capped at a depth of 64", "the over-deep subtree
prints as `...`" — and the inline comment is plainly shorthand for "a lot of
brackets", in the same register as the section's other `(prints: …)` notes.
Nothing is wrong with the compiler. Recorded only because this section's
examples are otherwise literal transcripts, and a leaf worker who asserted this
one verbatim would build a false-finding factory that fires on every run.

**Resolution (lawyer): MISREADING, high** — the prose is exact; the inline `(prints: …)` is shorthand. Manual gets "(abbreviated)"; leaves must not assert it verbatim.

**Resolution confirmed, 2026-08-22 (against 0.4.10–0.4.14).** LANGUAGE.md read "(prints: [[...]] then cyclic — abbreviated: 64 opening brackets, then `...`, then 64 closing brackets, then `cyclic`)" — the word "abbreviated" was there. **Superseded, 2026-08-29 (0.4.15, #111):** this exact sentence is gone from the manual along with the rest of the self-referential-list framing (see the "Moot as of 2026-08-29" note above) — there is no longer a "(prints: …)" comment on this example to be abbreviated or verbatim, because the example's own documented output changed.

### 7. A collection interpolated into a format string renders only in `Print` position; everywhere else it renders a raw, run-varying heap address — the VARIABLE-form sub-case RESOLVED (vox #44); the EXPRESSION-form sub-case still open (see collections-b.md D7 / candidate #68)

Found while probing LST-35. The claim lines are in the FMT ledger's range, not
this one, but the behaviour is what LST-16 and LST-35 rest on, so it is
recorded here with the cross-reference.

LANGUAGE.md:3451–3453 (was 3082–3085): all format-string sinks "share one name resolver, so
special names … render **identically** whether the result is printed, written
to a file, or built into a buffer". LANGUAGE.md:3425 (was 3054–3056): a format string used
as a value "materializes into a fresh NUL-terminated string, so it works as a
text initializer or assignment". Repro (`D7.vox`), **re-verified against
vox 0.4.9 — the variable form (`"{flat}"`) tested here now renders
correctly in all three sinks:**

```
a list called flat is [1, 2, 3].
print "print position: {flat}".      (prints: print position: [1, 2, 3])
a text called captured is "{flat}".
print captured.                      (0.4.7/0.4.8: 139857342844928 — an address; 0.4.9: "[1, 2, 3]", correct)
a buffer called sink is 64 bytes in size.
copy "{flat}" to sink.
print sink.                          (0.4.7/0.4.8: 139857342844928 — an address; 0.4.9: "[1, 2, 3]", correct)
```

Maps behave the same way. The address **changes between runs** (three
consecutive runs gave 140678866919424 / 139924057444352 / 140086226763776), so
a generated program that does this has wandering output and vox-fuzz's own
runner would classify it as nondeterminism — a false finding manufactured by
the generator.

**Strongest reading under which the compiler is correct:** "special names" at
3082–3085 may mean only the named specials the sentence goes on to list
(`{arguments's first}`, `{current time's hour}`, specifiers, `0x`/`0o`
prefixes), not every value type; and LANGUAGE.md:2442–2445 already warns that
list rendering in format strings is tag-dispatch-dependent and incomplete at
this stage, recommending the variable form — which does work in the position
the manual demonstrates it in (`print "{nested}"`). Under that reading the
compiler renders collections in the one position that was implemented and the
manual simply never scoped the "identically" sentence. What that reading does
not excuse is the *silence*: the non-print sinks do not fail, they emit a live
pointer as text.

**No existing leaf is affected.** `gen leaf format types` builds its
`{hl{n}}` and `{hm{n}}` slots into `Print "…"` statements only, and no leaf
anywhere assigns a `{list}` or `{map}` slot to a text variable or copies one
into a buffer. The corpus is clean today — and the first leaf worker who adds
a collection slot to a non-print sink will make it wander. That is the single
most important thing to carry into the leaf-building brief for this section.

**Resolution (lawyer): COMPILER BUG, high** — `VarType::List/Map` rendering exists only in codegen/print.rs; the shared resolver (codegen/format.rs) hands the raw pointer to the buffer path, which has no List/Map arm, so `{list}` in a text initializer or buffer copy formats a pointer as an integer — the exact per-sink duplication the resolver's own doc comment forbids. Carried by old manual lines 3054-3056, :3081, and the things precedent at :1224-1227 (compile error with fix-it); the old 3082-3085 "identically" citation does NOT carry it — these are the pre-0.4.9 line numbers the lawyer's adjudication was built on. → register entry; fix: things-style rejection at minimum, list-print-to-buffer in full.

**Resolution confirmed for this sub-case, 2026-08-22: fixed by vox #44.**
`D7.vox` re-run against 0.4.9 prints `[1, 2, 3]` correctly in the text-
initializer and buffer sinks, where it used to print a raw, run-varying
address. `docs/BUGS_FOUND.md` #44 ("`{list}`/`{map}` in a format string
renders correctly only in `Print` position") covers exactly this. **This
does not close the discrepancy entirely** — `collections-b.md`'s own D7
found a second, narrower sub-case in the *expression* form
(`"{element 2 of nested}"`) that #44's fix did not reach even in `Print`
position, tracked as vox candidate **#68** (`fix/bug-68-format-hole-
mixed-element`, in flight, not yet landed). This section's own repro
(the variable form) is fully resolved; the residual is FMT/LST2
territory, not re-opened here.

### 8. `is equal to` on two collections always answers "not equal", silently

Found while checking the `assertable?` column for LST-01. The claim lines are
in the EXP ledger's range (1789–2025), not this one, but the consequence
governs every assertion this section could ever emit, so it is recorded here.

LANGUAGE.md:1958 introduces `lhs is equal to rhs` with no type
restriction, and LANGUAGE.md:4973 lists `is equal to` / `is` as *the*
equality operator. Things are documented as compared **field by field**. A
reader has no warning that collections are the exception. Repro (`D8.vox`),
**re-verified against vox 0.4.9, byte-identical**:

```
a list called lhs is [1, 2, 3].
a list called rhs is [1, 2, 3].
If lhs is equal to rhs then, print "equal". Otherwise, print "NOT equal".
```
```
NOT equal
```

Two identical maps behave the same way, and a list compared against its own
documented rendering as a text (`lhs is equal to "[1, 2, 3]"`) is also "not
equal". Nothing warns; the comparison compiles and runs.

**Strongest reading under which the compiler is correct:** a list variable
holds a heap pointer, and `is equal to` on two pointers is reference equality
— two separately allocated lists really are different objects. That is a
coherent and common semantics, and the manual never promises structural
equality for anything except things (whose field-by-field comparison it
documents explicitly, which is arguably the exception rather than the rule).
Under that reading the compiler is consistent and the manual is silent rather
than wrong.

What that reading does not cover is the silence at the *type* level: `lhs is
equal to "[1, 2, 3]"` compares a list against a text and is accepted without
a diagnostic, which is the same shape as the 0.3.0 identifier/literal overload
LANGUAGE.md:717–728 was written to eliminate. And whatever the right
semantics, the practical consequence is fixed: a leaf must never assert a
collection whole. Recorded and stopped.

**Resolution (lawyer): DESIGN DECISION NEEDED, high** — it is pointer equality (self and alias compare EQUAL, so "always not equal" was wrong), documented nowhere, the odd one out beside texts (content) and things (field by field); and list-vs-text/number/buffer comparison compiles silently (analyzer/types.rs:199-200 exempts comparisons). → Josj: document identity semantics and reject cross-type aggregate comparison, or implement structural equality.

**Still open, 2026-08-22.** Re-probed `D8.vox` directly against vox
0.4.9: byte-identical to the original finding (`NOT equal` for two
identical-literal lists, two identical-literal maps, and a list against
its own documented rendering as text). Not in `vox-notes/candidates-
round-4.md`'s open-design-questions list, but also not among the
`fix/bug-66-*`…`fix/bug-90-*` branches present in the vox repo — no
evidence this has been assigned a register number. Recorded as still
awaiting Josj's design call, not filed as a numbered fix in flight.

## Invariants this section justifies

Samenesses the manual actually requires of any generated program in this area,
each with the line and the row that justifies it:

- list literals always wrapped in `[` `]` with `, ` between elements — LANGUAGE.md:2376, LST-01
- list element indices never 0 (1-indexed) — LANGUAGE.md:2386, LST-02
- an empty list always renders exactly `[]` — LANGUAGE.md:2382, 2388, LST-04
- booleans inside a list always render `1`/`0`, never `true`/`false` — LANGUAGE.md:2407, LST-17
- text elements inside a list always render quoted; numbers never — LANGUAGE.md:2407, LST-09
- nested list elements always render with their own brackets, recursively — LANGUAGE.md:2458–2461, LST-23
- recursive printing always stops at exactly depth 64 and always emits `...` at the cap — LANGUAGE.md:2520–2523, LST-32, LST-53 (LST-54 withdrawn, 0.4.15, #111 — see above)
- map literals always wrapped in `{` `}` with `"key": value` pairs — LANGUAGE.md:2528, LST-37
- an empty map always renders exactly `{}` — LANGUAGE.md:2528, LST-37
- every map key is always a quoted text — LANGUAGE.md:2527, 2622–2623, LST-36, LST-58
- map reads are always spelled `<map>'s "<key>"` — LANGUAGE.md:2538, LST-39
- `keys` and `values` always come back in insertion order — LANGUAGE.md:2562–2563, LST-47
- a replaced key always keeps its original position, never moves to the end — LANGUAGE.md:2556–2558, LST-45, LST-47
- type-predicate nouns always drawn from the closed set `number`/`text`/`decimal`/`boolean`/`list`/`map` plus `integer`/`string`/`float`/`real`/`bool`/`dictionary` — LANGUAGE.md:2642–2643, LST-62, LST-63

Everything else in this section must vary, and the invariant report should be
read as demanding a fix for any of these that it finds fixed: element counts,
element types and their order within a literal, whether a list is empty /
homogeneous / mixed / nested and how deep, entry counts, key names and their
lengths, value types, which of `keys`/`values` is iterated, whether the
optional `is not a` form appears, which synonym spelling of a type noun is
used, and whether a predicate chain has two arms or six. Today's five
collection leaves fix most of those: every generated list is exactly two
elements before its one append, every generated map is exactly two entries
with the keys `label` and `count`, every mixed list is number-then-text-then-
float in that order, and every predicate count is zero. None of those has a
citation.

## Report

**Updated 2026-08-22: 70 rows** (LST-01 through LST-70, no gaps, no
duplicates — the row count is unchanged, but LST-21 is now withdrawn
rather than live). Seven (LST-07, LST-15, LST-29, LST-31, LST-42, LST-48,
LST-51) are explicit folds into a sibling row rather than fresh leaf
needs; one (LST-50) is a cross-reference to `values.md` VAL-27, probed
there; one (LST-21) is withdrawn — the manual paragraph it cited no
longer exists, superseded by LST-18's compile-time rejection. That
leaves **61 distinct claims** (was 62).

**Assertable: 51** of the 61 name a concrete assertion the generator could
emit (was 54 — LST-18 and LST-19 moved to the compile-error bucket below
when vox #45 turned their claim into a compile-time rejection). **2 more
have a partial oracle** — LST-08 and LST-44, where the claim is about
something unobservable (which code path the compiler took; whether a
reallocation happened) but its consequence is assertable. **8 are flatly
not assertable** (was 6), in four distinct flavours worth keeping apart:

- **not observable from Vox at all** — LST-05 (heap allocation and automatic
  free), the same category as BUF-04/BUF-08;
- **compile-error claims** — LST-58 (non-text key), LST-70 (`is a <thing>`,
  list-of-things), and now **LST-18 and LST-19** too (appending an
  undeclared-return-type call's result to a list, since vox #45). Real,
  hand-verified, but a runtime leaf cannot emit them without breaking the
  "legal Vox that should compile and run" contract;
- **absence claims** — LST-59 (no map deletion): there is nothing to emit;
- **claims whose documented form used to not compile, now correctly
  documented as not compiling** — LST-67 and LST-68's discrepancies
  (D3, D4) are resolved: the manual now shows the idiom that *does*
  compile as the recommendation, and states the cast/guard limitation as
  a fact rather than an accidental dead end. Neither is blocked any more.

**Existing coverage: broad, shallow, and assertion-free.** Five leaves emit
collections and they genuinely cover list declaration, append, `element N of`
in and out of range, mixed literals, map literals, keyed read and write,
`'s length`, `'s keys` iteration, and the missing-key error path. Not one of
them asserts anything — every single one prints for a human to eyeball. So the
work on this section splits cleanly: *add assertions* to about twenty rows
that are already emitted, and *build from nothing* for three whole
sub-sections that no leaf touches — **nested lists** (LST-22…LST-35),
**type predicates** (LST-60…LST-70), and **cycle-safe printing**
(LST-32, LST-53, LST-54).

**Biggest finding (HISTORICAL, true through 0.4.14) — the cycle-safety
claims are untested and they are the memory-safety claims in this
section.** LST-32, LST-53 and LST-54 say that a self-referential list, a
self-referential map, and a mixed map/list cycle each print to a 64-deep
cap, set the error flag, and *unwind safely instead of overflowing the
stack*. That is a stack-overflow guard, stated in the manual, that
nothing in the fuzzer has ever exercised — and building a cycle is two
lines of generated Vox (`a list called ring is []. append ring to ring.`).
By `CLAUDE.md`'s ordering — every signal death is top severity, buffers
and collections are where the promise lives — that is where the first
leaf batch for this section should go, ahead of the assertion retrofits.

**Superseded, 2026-08-29 (0.4.15, #111).** That two-line cycle-building
idiom no longer builds a cycle at all — nesting always copies now, so
`append ring to ring.` yields `[[]]`, not a self-reference. LST-33,
LST-34 and LST-54 (the rows whose claims depended on a cycle actually
existing) are withdrawn; LST-32 and LST-53 are narrowed (the depth-64
cap is still real, as a defensive backstop, but is now only reachable
via 64 explicit nested literal levels — much more expensive to build
than the old two-line idiom, see their rows above). The stack-overflow
guard itself is presumably still real and still untested by any leaf,
but the cheap way to reach it is gone; the next worker's cost-benefit
call on whether to build 64 explicit levels is now a real trade-off,
not a two-line freebie.

**Runner-up — Discrepancy 5, an opaque text in a list silently reinterpreted
as a number and printed as a stable code address — RESOLVED (vox #45).**
The manual's self-contradiction is gone because the compiler now refuses
the write outright rather than guessing; there is nothing left to hedge.

**Updated 2026-08-22 (0.4.10): of the eight discrepancies, seven are now
resolved** (D1, D2, D3, D4, D5, D6 — re-verified directly against vox
0.4.9; D7 — the expression-form sub-case, re-verified directly against
0.4.10, vox #68 landed) and **one remains open** (D8, a design decision
still awaiting Josj). D7 was still open as of the 0.4.9 pass, tracked
separately in `collections-b.md` as vox candidate #68; that candidate
landed in 0.4.10 and closed both sub-cases (the variable form was
already fixed by #44). Four of the seven resolved ones (D1, D3, D4, D6)
were defects in the manual's own code examples — three that did not
compile as printed and one whose recorded output was not what ran — and
all four now show the correct form.

**The one that will still bite the leaf worker is D8**: `is equal to`
between two collections always answers "not equal", silently, so the
obvious whole-list assertion is a false-finding factory. See *What can
be asserted about a collection at all*, above — that section is the
single most important thing to put in the leaf-building brief, ahead of
everything in the table.

### Advice for the next mapper

1. **Compile every code block in your range before you write a single row.**
   Four of my seven discrepancies are broken examples, and I found them only
   because I probe-ran everything. A `vox-preflight` pass over the section
   first would have found all four in one go and would have cost minutes. Do
   that before enumerating claims, not after.
2. **When a claim's failure prints a pointer, the probe must print a verdict.**
   Two probes here (`LST-35`, `D7`) would otherwise have wandering output and
   could never be re-checked. Write `If x is equal to "<documented>" then …
   Otherwise …` and record the verdict. This is the same rule the generated
   programs live under, and applying it to probes keeps `check-probes.sh`
   meaningful.
3. **Test the *position* a construct appears in, not just the construct.**
   D7 exists because `{list}` renders correctly in `Print` and wrongly in a
   text initializer and a buffer sink. I would have missed it entirely if I had
   only reproduced the manual's example, which is in print position. When a
   feature is documented as working "everywhere", probe at least three of the
   everywheres.
4. **Grep the accessor AND check what consumes it.** `gen leaf format types`
   reads `'s length` on a buffer, not a map; `is empty` on a buffer is not
   `'s empty` on a map; `environment's empty` is a third thing. A `grep` that
   stops at the property name will credit coverage that does not exist. Read
   the line the hit is on and the statement it is built into.
5. **Probe the assertion mechanism itself before you fill in `assertable?`.**
   I wrote a dozen `assertable? yes` cells naming a whole-value comparison
   before checking that the comparison works. It does not (D8), it fails
   silently, and every one of those cells would have shipped a false-finding
   factory to a leaf worker. The `assertable?` column is a claim like any
   other — run it. On a new surface, the first probe should be "can I even
   compare one of these?", before the first claim is enumerated.
6. **`flag` is reserved**, as are `a`, `b` and `nothing`; `key`, `entry`,
   `item`, `marker`, `value` and `thing` are all fine. Extend the naming
   landmine list `values.md` started rather than rediscovering it.

### What I could not do

- **LST-34** (HISTORICAL, true through 0.4.14) — the documented use-after-free
  (a child list held across a parent reallocation) did not reproduce at 5000
  appends. The manual hedges with "may", so the row is not a discrepancy, but
  I cannot say the hazard is absent — only that I did not find the shape that
  triggers it. It is worth a targeted red-team attempt rather than a leaf.
  **Superseded, 2026-08-29 (0.4.15, #111): LST-34 is withdrawn — the manual
  no longer claims this hazard exists at all** (`element N of` now copies,
  per the replacement text at LANGUAGE.md:2496–2515), so there is nothing
  left to red-team.
- **LST-08, LST-25** — the homogeneous fast path is a compile-time property.
  I probed its observable shadow (arithmetic on the loop variable is accepted
  for a homogeneous list, rejected for a mixed one) but there is no way from
  inside a running Vox program to assert which path the compiler took.
- **LST-44** — I probed 200 map inserts; I did not establish where the
  reallocation threshold actually is, so the row asserts survival rather than
  the reallocation itself.
- The reference worktree holding `PROCEDURE.md`, `buffers.md`, `values.md` and
  `docs/check-probes.sh` was removed part-way through this session. I had read
  all four by then; the probe checker used for the final pass is a local
  reconstruction of `check-probes.sh` with identical parsing and comparison
  logic, kept in scratch and not added to this branch.
