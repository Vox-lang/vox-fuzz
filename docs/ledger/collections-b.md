# Claim ledger: Lists and Collections (second half)

Source: `../vox/LANGUAGE.md` lines **2791–3127**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual): Printing a List, List Properties,
List Element Access, Appending to Lists, Loop Expansion with Collections
(including the chained-clause grid), Conditional Branching with `but if`,
and Inline Value Substitution with `treating`. Row prefix **`LST2`**.

The rest of the chapter is mapped elsewhere and is deliberately **not**
re-mapped here: List Literals, Mixed-Type Lists, Nested Lists, Maps and
Type Predicates (2241–2540) are `collections-a.md` (`LST-*`), and `value` /
`nothing` (2541–2790) are `values.md` (`VAL-*`). Where a claim in this range
leans on one of those, or on the buffer section, the row cross-references it
by line and row ID.

**Nine of this ledger's ten discrepancies are now resolved** — D1, D5,
D6, D8 by manual fixes (the false or self-contradicting claim was
reworded or corrected), re-verified directly against vox 0.4.9;
D2, D3, D4, D10 by compiler fixes (#50, #49, #49, and an uncredited
diagnostic-caret fix respectively), also against 0.4.9; **and D7 — the
expression-form sub-case, RESOLVED 2026-08-22 by vox #68 landing in
0.4.10** (the variable-form sub-case was already fixed by #44). D7 was
the brief's "collections-b D7," the one row this pass's re-pin needed a
fix-in-flight citation for — #68 is that number, now landed. **D9 alone
remains genuinely open** (`respectively` is not actually reserved),
unchanged, a design question for Josj with no register number found.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names the
leaf that already emits the construct — found by `grep` on the accessor or
keyword (`print each`, `append each`, `and each`, `treating`, `but if`,
`otherwise`, `element `, `'s length`, `'s first`, `'s last`, `'s empty`,
`open a file`), never by leaf name — or `none`. `status` follows
PROCEDURE.md §3.

**Nothing in this section is `verified`.** The same uniform gap the buffers,
values and collections-a ledgers found holds here: seven leaves emit
constructs from this range and not one of them asserts a documented result.
The single exception in the whole generator — `gen leaf format types`'
`clock check` line — asserts a *text length*, not anything in this section.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` pinned to
the sibling `coreasm`) before being written.

## What can be asserted about a list at all

This constrains every `assertable?` cell below, and it inherits two hard
limits from the sibling ledger:

- **Never compare a collection whole.** `is equal to` between two lists
  compiles and always answers "not equal", silently, including two lists
  built from the identical literal (collections-a **D8**). An assertion like
  `If xs is not equal to "[1, 2, 3]" then, Exit 95.` fires on every run.
- **A list's rendering exists only in `Print` position.** Interpolating a
  list into a text initializer or a buffer sink yields a live heap address
  that changes between runs (collections-a **D7**, reproduced in this range
  as **D7** below). A program therefore cannot capture its own rendering and
  check it, and **no rendering claim in this section (LST2-01…LST2-13) is
  assertable from inside the generated program.** Their assertable shadow is
  the *structure* — `'s length`, `element N of`, `'s first`, `'s last` — and
  those rows say so.

The oracle that *is* available is element-wise and covers almost everything
else here: `'s length` / `'s size` / `'s empty` / `'s first` / `'s last`,
`element N of` with a literal or a variable index, the error flag via
`On error`, a counting variable incremented inside a loop-expansion body,
and — for `but if` and `treating` — an accumulator list whose final length
and elements the generator can compute in advance.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/collections-b/`, named `LST2-NN.vox` for the first row it
covers; a probe covering more than one row says so in its header. Each file
opens with a `(...)` comment naming the claim, the `Ran:` command, and an
`expected output:` block recording what the compiler actually printed.
`fixtures/two-lines.txt` is the 11-byte on-disk input `LST2-54.vox` reads;
probes that reference it use a path relative to the **repo root**, which is
where `docs/check-probes.sh` runs probe binaries from. `LST2-90.vox` writes
`/tmp/lst2-90-out.txt` when run.

Two probes record a run that `check-probes.sh` cannot reproduce on its own
and say so in the header: `LST2-50.vox` records the **no-argument** run
(the checker passes no arguments) with the three-argument transcript in
prose, and `LST2-90.vox` does the same for its file-copy run.

Rows with no probe file of their own: the ones folded into a sibling
(LST2-64), the two that are cross-references to `buffers.md` (LST2-33,
LST2-34), and the four whose only runnable form **is** a discrepancy repro —
LST2-39 (`D1.vox`), LST2-92 (`D6.vox`), LST2-71 (`D9.vox`, plus its own
`LST2-71.vox` for the half that does compile) and LST2-96 (`D3.vox` and
`D4.vox`). That is **33 `LST2-NN.vox` files** plus **`D1`–`D10`** for the ten
discrepancies — 43 files. All 43 re-run clean with `docs/check-probes.sh
docs/ledger/probes/collections-b`: **43 passed, 0 failed, 0 skipped**.

**Refreshed 2026-08-21 against vox 0.4.8 + #49/#50.** `D2`, `D3` and `D4`
were re-recorded because the compiler was fixed under them, not because the
ledger was wrong — see their `Resolution:` lines. `D3` and `D4` are now
compile-error probes, so the old core-dump flake they used to cause is gone
with them: no probe in this directory crashes any more, and `ulimit -c 0` is
no longer needed to get a clean sweep. `D10.vox` is new — a caret-placement
defect in the diagnostic #49 introduced, found while refreshing `D3`.

## The table

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| LST2-01 | 2924–2925 | Printing a list variable directly renders its contents, not its heap address. | `print <list variable>` as a bare statement | **no** — the rendering cannot be read back from inside the program (see *What can be asserted*). Assertable shadow: `If xs's length is not N then, Exit 95.` | none — **no leaf anywhere prints a whole list**; `gen leaf list inrange` prints `element 1 of` it, `list mixed` iterates it element by element | todo | |
| LST2-02 | 2928, 2930 | `[1, 2, 3]` prints exactly `[1, 2, 3]`. | a number-only list printed whole | no (rendering) — shadow is length + `element N of` per slot | none | todo | |
| LST2-03 | 2929, 2931 | `[1, "two", 3.5, yes]` prints `[1, "two", 3.5, 1]` — each slot by its own runtime tag. | a mixed list printed whole | no (rendering) | `gen leaf list mixed` builds exactly this shape but never prints the list whole — only `For each w in l, Print w` | todo — the construct exists, the *print-whole* step is missing | |
| LST2-04 | 2932 | The same rendering appears inside `{...}` interpolation: `print "list: {nums}"` → `list: [1, 2, 3]`. | a list variable in a format slot, in `Print` position | no (rendering) | `gen leaf format types` emits `Print "list {hl{n}}"` | exercised (Print position, always a two-number list, never asserted) | |
| LST2-05 | 2935 | Elements are separated by `, ` and the whole is wrapped in `[` `]`. | any list printed whole | no (rendering) | `gen leaf format types` (two-number list only) | exercised | |
| LST2-06 | 2935–2937 | **Claim reworded, 2026-08-22 — the self-contradiction is gone.** Each element "renders **by its own type, not the list's**: text elements are quoted (so `["1"]` is distinguishable from `[1]`)". The old wording ("renders exactly as it does when printed individually") is gone; the new wording is almost verbatim the lawyer's proposed fix for Discrepancy 8. | a text element printed both individually and inside a list | no (rendering) | none — no leaf prints a text-bearing list whole | todo — Discrepancy 8 RESOLVED (manual reworded) | |
| LST2-07 | 2937 | Booleans inside a list render as `1`/`0`. | a boolean element in a printed list | no (rendering) | none — no leaf puts a boolean in a list | todo | |
| LST2-08 | 2937–2938 | Floats and numbers inside a list render "as usual" (a whole-valued float keeps its `.0`). | a float element in a printed list | no (rendering) | `gen leaf list mixed` builds a float element but never prints the list whole | todo | |
| LST2-09 | 2938 | An empty list prints exactly `[]`. | `a list called x is []. print x.` | no (rendering) — shadow: `If x's length is not 0 then, Exit 95.` | none — `gen leaf butif append` declares `[]` lists but never prints one | todo | |
| LST2-10 | 2938–2940 | A nested list element renders recursively with its own brackets intact: `[1, [2, 3], "four"]`. | a list holding a list, printed whole | no (rendering) — shadow: extract the child into a `list` variable (collections-a LST-28) and check its length | none — zero leaves emit a nested list (collections-a says the same) | todo | |
| LST2-11 | 2940–2941 | A map element, or a whole map, renders as `{"key": value, …}` via `_map_print`. | a map printed whole, and a map inside a printed list | no (rendering) — shadow: `m's length` and keyed reads | `gen leaf format types` emits `Print "map {hm{n}}"` (whole map only) | exercised for a whole map; **todo** for a map inside a list — no leaf nests one | |
| LST2-12 | 2942–2946 | **Claim extended, 2026-08-22 (0.4.10, #68).** The *variable* form of `{...}` interpolation carries the full list rendering. The manual now states this together with LST2-13 in one merged sentence: both forms, in every sink, "dispatch on the element's runtime tag, so an element renders in a hole exactly as it does printed as a statement." | `print "{xs}"` where `xs` is a list variable | no (rendering) | `gen leaf format types` | exercised | |
| LST2-13 | 2942–2946 | **Claim reversed, 2026-08-22 — the limitation is fixed, not just documented differently (0.4.10, #68) — Discrepancy 7 (this ledger's expression-form sub-case) RESOLVED.** The old claim said the *expression* form (`print "{element 2 of xs}"`) does **not** dispatch on a nested element's runtime tag, and instead renders a live heap address that changes between runs. #68 fixed the underlying bug: both the variable and expression forms now dispatch on the runtime tag, in every sink (Print, a text initializer, buffer `set`/`copy`/`append`, `write`, filesystem paths, `treating` clauses, function arguments) — see CHANGELOG.md #68. | a format slot holding an `element N of` expression over a nested list, in Print position and in a non-print sink; assert the rendering matches the variable form's | yes now — the rendering is stable and correct: `If rendered is not "[2, 3]" then, Exit 95.` (the old live-heap-address hazard is gone, so a leaf **may** now emit this form) | none | todo — **hand-verified fixed against 0.4.10**: `print "{element 2 of nested}"`, a text initializer, and a buffer `copy` all now render `[2, 3]` (see `collections-a.md` LST-35, whose retained probe covers exactly this) | |
| LST2-14 | 2950 | List properties are reached with the `'s` syntax. | any `<list>'s <property>` read | yes — every property below is a number or boolean the generator can predict | none — **no leaf reads any property of a list**; `'s length` is emitted on a map and on a buffer, `'s empty` on `environment`/`arguments`/a buffer, `'s first`/`'s last` on nothing at all | todo | |
| LST2-15 | 2955, 2964 | `length` is the number of items, typed Number. | `print xs's length` after known appends | yes — `If xs's length is not 3 then, Exit 95.` | none (on a list) | todo | |
| LST2-16 | 2956, 2965 | `size` is the same value as `length`. | both read on the same list | yes — `If xs's size is not xs's length then, Exit 95.` | none (on a list) | todo | |
| LST2-17 | 2959, 2966 | `empty` is a Boolean, true iff the list has no items (prints `0` when it has some). | read on an empty and a non-empty list | yes — `If xs's empty is not 0 then, Exit 95.` | none (on a list) | todo | |
| LST2-18 | 2957, 2967 | `first` is the first item. | read after a known declaration | yes — `If xs's first is not 10 then, Exit 95.` | none | todo | |
| LST2-19 | 2958, 2968 | `last` is the last item. | read after a known append | yes — `If xs's last is not 5 then, Exit 95.` (the generator appended 5) | none | todo | |
| LST2-20 | 2962–2968 | *(gap in the manual)* On an **empty** list, `first` and `last` each return 0 **and set the error flag** — the same contract the manual gives only for out-of-range `element N of`. `length`/`size` are 0 and `empty` is 1 without raising the flag. | read `first`/`last` on a declared-empty list inside `On error` | yes — assert the handler fired and the value is 0 | none | todo — hand-verified (`LST2-20.vox`) | |
| LST2-21 | 2972 | List elements are 1-indexed: element 1 is the first item. | `element 1 of` a list whose first element the generator chose | yes — `If element 1 of xs is not 10 then, Exit 95.` | `gen leaf list inrange` emits `Print element 1 of l{n}` but never asserts *which* element came back, so 1-vs-0 indexing is never pinned | todo (verification); exercised (construct) | |
| LST2-22 | 2974–2978 | `element N of <list>` with a **literal** index reads slot N. | reads at several literal indices, not only 1 | yes | `gen leaf list inrange` (index 1 only, every time — an unjustified invariant of its own) | exercised, narrowly | |
| LST2-23 | 2979–2980 | `'s first` and `'s last` agree with `element 1 of` and `element N of`. | all four read on one list | yes — `If xs's first is not element 1 of xs then, Exit 95.` | none | todo | |
| LST2-24 | 2982–2984 | `element i of <list>` with a **variable** index works and reads the same slot a literal would. | an index that is a runtime Vox variable, not baked into the generated text | yes | none — every existing leaf interpolates the index as a compile-time literal before the program is written, so the variable-index path is never taken (the same gap buffers.md found at BUF-21) | todo — real gap, hand-verified | |
| LST2-25 | 2988–2993 | **Claim extended, 2026-08-22 (0.4.10, #72/#91).** Out-of-bounds element access sets an error flag **and returns 0** — true unconditionally on 0.4.9 and earlier (an untyped 0 that a `text`/`list`/`map` destination then dereferenced as a pointer and segfaulted — #91). As of 0.4.10 the manual states a provable/unprovable split: where the compiler can prove the index is past the end, it returns the **number** 0 whatever the list's elements are (so only a `number`/`float`/`boolean` destination is legal; `text`/`list`/`map` is now a compile error); where it cannot prove it, it returns the destination's typed default — `0`/`""`/`[]`/`{}` — never a raw 0 that a pointer-typed read could dereference. | capture a **compiler-provable** OOB read into a number and check it; separately, capture an **unprovable** (variable-index, or a mixed-list) OOB read into a text/list/map and assert the typed default | yes — `If bad is not 0 then, Exit 95.` for the provable/number half; `If missed's empty is not 1 then, Exit 95.` (via a buffer built from the text) for the unprovable/typed-default half | `gen leaf list oob` catches the error but never captures or checks the value | todo — **hand-verified against 0.4.10**: a literal-index OOB read on a homogeneous number list still yields `0` (error flag set); a variable-index OOB read on a **mixed** list into a `text` destination yields empty text (error flag set) — the homogeneous-list case cannot exercise the typed-default half at all, because a homogeneous list's proven element type (vox #54) fixes the destination type regardless of the index | |
| LST2-26 | 2994 | `On error` catches an out-of-bounds element access. | — | yes (that the handler ran) | `gen leaf list oob` | exercised | |
| LST2-27 | 2996–2999 | The worked bounds example (`element 100 of` a 3-element list, caught by `On error`) compiles and behaves as shown. | reproduce verbatim | yes | `gen leaf list oob` emits exactly this shape with a random index ≥ 10 | exercised | |
| LST2-28 | 2988–2993 | *(gap)* Index **0**, a **negative** index, the first index past the end, and a **variable** index out of range all behave identically to a far out-of-bounds read: error flag set, and (0.4.10, #72/#91) the provable/unprovable split LST2-25 now describes. The manual defines no lower bound and never says index 0 is out of bounds. | reads at 0, −1, N+1 and a variable index, each under `On error` | yes | none — `gen leaf list oob` only ever draws an index ≥ 10, so the interesting boundaries are never reached | todo — hand-verified (`LST2-25.vox`). **Re-verified against 0.4.10**: index `0` and a negative index both still return `0` with the error flag set, on both a homogeneous and a mixed list — unchanged in substance, only the manual's surrounding rule text moved (2855 → 2992–2997) | |
| LST2-29 | 3004 | `append` adds an element to the **end** of the list. | append, then read `'s last` | yes — `If xs's last is not 4 then, Exit 95.` | `gen leaf list inrange`, `gen leaf butif append` | exercised | |
| LST2-30 | 3006–3010 | The worked example: two appends onto a 3-element list give length 5. | reproduce verbatim | yes | `gen leaf list inrange` appends once, never reads the length | todo (the length read); exercised (the append) | |
| LST2-31 | 3014 | `append <value> to <list>` appends exactly **one** element. | append once, assert the length grew by exactly 1 | yes | `gen leaf list inrange`, `gen leaf butif append` | exercised | |
| LST2-32 | 3015 | `append` is overloaded by destination type: `append <source_buffer> to <destination_buffer>` appends bytes. | both spellings in one program | yes — see `buffers.md` BUF-31 for the buffer half's own assertion | format-string leaves append into fixed buffers (`gen leaf format types`, the `gt{n}` family) | exercised (both halves exist, in different leaves; never in one program, never asserted) | |
| LST2-33 | 3017 | `copy <source_buffer> to <destination_buffer>` replaces destination contents. | — | yes | — | cross-reference to `buffers.md` **BUF-32**; not re-mapped here | |
| LST2-34 | 3018 | `clear <buffer>` resets a buffer to empty while preserving capacity. | — | yes | — | cross-reference to `buffers.md` **BUF-33**; not re-mapped here | |
| LST2-35 | 3021–3023 | **Claim extended, 2026-08-22 (0.4.10, #75).** Lists grow dynamically — memory is allocated as needed, "wherever the list is named from — a variable, a global, or a `list` parameter naming the caller's list" (new clause). Before #75, growth through a `list` **parameter** silently stopped after `max(8, element count)` elements and leaked the block it outgrew every call past that (CHANGELOG #75) — the local-variable half of this claim held on 0.4.9, the parameter half did not. | append far past any plausible initial reserve, then read both ends and the middle; separately, grow a `list` **parameter** the same way and assert the caller sees the growth | yes — the generator knows the count and every value: `If grown's length is not 2000 then, Exit 95.` | none — the biggest list any leaf builds is three elements plus one append, and no leaf grows a collection through a parameter at all | todo — hand-verified to 2000 appends for the local-variable half (`LST2-35.vox`); the parameter half hand-verified separately against 0.4.10 (grew a list parameter to 50 entries, caller's own variable read all 50 back) — see `functions.md`, not yet its own retained probe here | |
| LST2-36 | 3024–3026 | **Claim corrected, 2026-08-22 — the false claim is gone.** "**Mixed types**: Appends of different types are allowed in any order; each element is printed by its own type, **never by the list's**." The old "type tracking: the first append determines the list's element type for printing" bullet is gone — replaced with the correct rule, matching what LST2-06 also now says. | append two different types in each order and print | no (rendering, same limit as LST2-06) — assertable shadow: `is a <type>` on each slot after appending in each order, asserting the tag never changes with order | none | todo — unblocked, Discrepancy 5 RESOLVED (manual corrected) | |
| LST2-37 | 3027–3030 | **Claim extended, 2026-08-22 (0.4.10, #77).** `append` works with any value: integers — a negative literal included — strings, booleans, variables, expressions, and (new in 0.4.10) `nothing`, floats, function calls, arithmetic, and the collection reads `element N of <list>`, `byte N of <buffer>` and `<name>'s <property>`. Before #77, a negative literal, `nothing`, `element N of`, `byte N of`, a `'s` possessive and the operator spelling `times` were refused in the append slot specifically (a hand-written parser copy that had fallen behind the general expression parser) even though every other value position accepted them. | one append of each kind, including the newly-legal ones (`-5`, `nothing`, `element N of`, `byte N of`, `'s` property) | yes (via `'s length` and `element N of` per slot) | `gen leaf butif append` appends an expression drawn from `gen append expr`; `gen leaf list inrange` appends a number literal. **Booleans, texts, `nothing`, and the collection-read forms are never appended by any leaf.** | exercised for numbers/variables/expressions; **todo** for texts, booleans, and the newly-legal forms — hand-verified `-5`, `nothing`, and `element 1 of [7, 8, 9]` all now append correctly | |
| LST2-38 | 3041–3044 | The append-integers example (declare `[]`, append twice) compiles and runs. | reproduce verbatim | yes | `gen leaf butif append` declares `[]` and appends | exercised | |
| LST2-39 | 3046–3049 | **RESOLVED, 2026-08-22.** The append-strings example now reads `append "hello" to words.` / `append "world" to words.` — quoted. The old unquoted form (`append hello to words.`) is gone. | reproduce verbatim | yes — `If element 1 of words is not "hello" then, Exit 95.` | none | todo — unblocked, Discrepancy 1 RESOLVED (manual fixed) | |
| LST2-40 | 3051–3053 | The append-from-variables example (`append x to nums.`) compiles and runs. | append a declared variable rather than a literal | yes | `gen leaf butif append` (via `gen append expr`) | exercised | |
| LST2-41 | 3055–3060 | The append-in-loops example: a `While` loop appending `i multiply i` builds `[1, 4, 9, 16, 25]`. | an append whose value is an expression, inside a loop | yes — the generator knows the whole sequence: check `'s length` and the last element | `gen leaf butif append` appends an expression, but never inside a loop; no leaf appends from within a loop body | todo — real gap, hand-verified (`LST2-36.vox`) | |
| LST2-42 | 3065 | `each … from` works with lists and ranges to execute an action once per item. | a loop-expansion sentence over each source kind | yes — count iterations into an accumulator | `gen leaf treating print`, `gen call grid`, `gen leaf deep grid`, `gen leaf treating grid` | exercised | |
| LST2-43 | 3069 | A **list literal** is a legal source: `print each number from [1, 2, 3].` | — | yes | `gen leaf treating print` (source choice 1), `gen call grid` | exercised | |
| LST2-44 | 3072 | A **range** is a legal source: `print each number from 1 to 10.` | a range source under `print each`, not only under a grid call | yes | `gen call grid` and `gen leaf deep grid` use ranges, but only as grid clauses of a function call — **no leaf emits `print each … from N to M`** | todo for the print form; exercised for the call form | |
| LST2-45 | 3075 | A function call runs once per item: `double of each n from [1, 2, 3].` | — | yes — assert an accumulator the callee mutates | `gen call grid`, `gen leaf treating grid` (both via `f3`) | exercised | |
| LST2-46 | 3077–3080 | `append each x from source to dest` appends every element of one list to another. | — | yes — `If dest's length is not source's length then, Exit 95.` | none — `grep "append each"` finds nothing in `src/` | todo — real gap, hand-verified (`LST2-42.vox`) | |
| LST2-47 | 3083 | The syntax is `<action> each <variable> from <collection>`. | — | yes | the four loop-expansion leaves above | exercised | |
| LST2-48 | 3086 | Supported collections include **lists**: a literal, or any list *variable*. | a loop expansion whose source is a declared list variable | yes | `gen leaf treating print` and `gen call grid` both use list **literals** only; no leaf ever names a list variable as an `each` source | todo for the variable form; exercised for the literal form | |
| LST2-49 | 3087 | Supported collections include **ranges**: `1 to 10`, `start to end`, inclusive at both ends. Undocumented precision: a range whose start exceeds its end yields **zero** iterations rather than counting down or erroring, and both bounds may be variables. | ranges with literal and variable bounds, including start > end and start = end | yes — the generator picks both bounds, so it knows the count exactly | `gen call grid`, `gen leaf deep grid` (literal bounds only, always ascending) | exercised for ascending literal ranges; **todo** for variable bounds, start = end, and start > end | |
| LST2-50 | 3088 | Supported collections include **`arguments's all`**. | — | yes — the generator controls argv (the existing argv assertions already prove the pattern) | `gen leaf treating print` (source choice 0) | exercised — but always with **zero** arguments passed, so the loop body has never run once in a campaign | |
| LST2-51 | 3091 | `print each X from Y` — print each item. | the bare form, without a `treating` clause | yes | `gen leaf treating print` — **always with a `treating` clause attached**; the bare form is never emitted | todo for the bare form | |
| LST2-52 | 3092 | `function of each X from Y` — call a function per item. | — | yes | `gen call grid`, `gen leaf treating grid`, `gen leaf deep grid` | exercised | |
| LST2-53 | 3093 | `append each X from Y to Z` — append each item to a list. | — | yes | none | todo (same gap as LST2-46) | |
| LST2-54 | 3094 | `open ... at each X from Y` — open a file per path. | a loop-expansion `open` with a read/close body | yes — assert the byte count read from a fixture the generator wrote | none — every `open` a leaf emits names a single path; `grep "at each"` finds nothing | todo — real gap, hand-verified (`LST2-54.vox`) | |
| LST2-55 | 3105–3109 | `print <func> of each n from …` prints the value the function **returns** for each item. | a returning function under `print … of each` | yes — the generator knows every returned value | none — `gen call grid` emits a bare call statement, never `print f of each` | todo | |
| LST2-56 | 3121 | An empty collection does nothing: `print each n from [].` runs the body zero times. | an empty-literal source, with a following statement to prove the program continued | yes — assert an accumulator is untouched | none — no leaf emits an empty `each` source; `gen leaf treating print`'s `arguments's all` is empty in practice but is not an empty *literal* | todo | |
| LST2-57 | 3126 | `and` joins **any number** of `each` clauses in one sentence. | grids of two, three and four clauses | yes | `gen call grid` (always exactly two), `gen leaf deep grid` (up to `gen_grid_depth`, all range clauses) | exercised | |
| LST2-58 | 3127–3128 | The action runs once per element of the **Cartesian product**, **row-major** — leftmost clause is the outermost loop. | a grid whose callee prints both variables, so the ordering is visible | yes — the generator knows the exact call sequence; assert an accumulator that encodes order (e.g. `total = total multiply 10 add left`) | `gen call grid` emits the construct; nothing checks the order | todo (verification); exercised (construct) | |
| LST2-59 | 3131 | The 2×2 example (`'pair' of each x from [1, 2] and each y from [10, 20].`) runs 4 calls. | reproduce verbatim | yes | `gen call grid` | exercised | |
| LST2-60 | 3132–3133 | The triple grid — one list and two ranges, 2 × 2 × 2 = 8 calls. | a three-clause grid mixing a list and two ranges | yes | `gen leaf deep grid` goes deeper but uses **only** range clauses; `gen call grid` mixes a list and a range but only two clauses. The documented mixed-three shape is emitted by neither. | todo | |
| LST2-61 | 3136–3140 | A **fixed argument** may appear in any position among the clauses. | grids with the fixed argument leading and trailing | yes | none — every grid clause any leaf emits is an `each` clause | todo — hand-verified (`LST2-61.vox`) | |
| LST2-62 | 3143–3150 | Arity is checked: the number of argument clauses must equal the callee's parameter count; a one-value action given two `each` clauses is a compile error, not a concatenation. | — | **no** — a compile-error claim; a runtime leaf cannot emit it without breaking the "legal Vox that should compile and run" contract | n/a | not assertable — hand-verified (`LST2-62.vox`) | |
| LST2-63 | 3152–3155 | The single-value specialized forms `print`, `append` and `open` take **one** clause only; a second `each` is the arity error, with the message naming the form. | — | **no** — compile-error claim | n/a | not assertable — hand-verified for all three forms (`LST2-63.vox`) | |
| LST2-64 | 3152–3153 | "This is what stops `print each x from A and each y from B` being misread as printing both on one line." | — | — | — | folded into LST2-63 | |
| LST2-65 | 3157–3162 | The deliberate asymmetry: in `print <func> of …` the grid form requires the **first** clause to be an `each`, so a leading fixed argument stays an error. | — | **no** — compile-error claim | n/a | not assertable — hand-verified (`LST2-65.vox`) | |
| LST2-66 | 3164–3170 | An empty collection **anywhere** in a grid produces zero calls, regardless of position. | grids with the empty clause leading and in the middle | yes — assert an accumulator the callee would have mutated is still 0 | none — no leaf emits an empty grid clause | todo — hand-verified (`LST2-66.vox`) | |
| LST2-67 | 3172–3179 | Binding the same loop variable twice in one sentence is a compile error that **names** the variable. | — | **no** — compile-error claim | n/a | not assertable — hand-verified (`LST2-67.vox`). Note `gen call grid` and `gen leaf treating grid` already take care to draw fresh `e{N}` names precisely to stay legal here. | |
| LST2-68 | 3181–3186 | `but if` attaches to the **innermost** iteration of a grid, and its condition may reference **every** loop variable. | a grid whose `but if` compares two loop variables | yes — the generator knows exactly which cells match | none — `gen leaf butif print` / `butif append` never sit on a grid; `gen call grid` never carries a `but if` | todo — real gap, hand-verified (`LST2-68.vox`) | |
| LST2-69 | 3188–3197 | After the sentence, **each** loop variable independently retains its last-iteration value. | read both loop variables after a two-clause grid | yes — `If the left is not 3 then, Exit 95.` | none — no leaf reads a loop variable after its sentence | todo | |
| LST2-70 | 3189–3191 | For a **range** clause, "last-iteration value" means the counter that ENDED the loop — i.e. `end + 1`, matching a handwritten `For each … from 1 to N`. | read a range clause's variable after the sentence, and compare with the handwritten form | yes, and this is the trap worth asserting: `If the inner is not 4 then, Exit 95.` after `… each inner from 1 to 3` | none | todo — hand-verified, `end + 1` confirmed for both forms (`LST2-69.vox`) | |
| LST2-71 | 3199–3202 | Zip is not the semantics; `respectively` is "reserved as a possible future marker … not parsed today". | a sentence using `respectively`, and a variable named `respectively` | **no** — the not-parsed half is a compile-error claim | n/a | not assertable — hand-verified: not parsed (`D9.vox`), but **not reserved either** (`LST2-71.vox`), see **Discrepancy 9** | |
| LST2-72 | 3204–3215 | Loop variables shadow outer variables of the same name, and after the loop the outer name holds the last iteration's value. | declare a variable, shadow it with a loop variable, read it after | yes — `If the x is not 3 then, Exit 95.` | none | todo — hand-verified (`LST2-69.vox`) | |
| LST2-73 | 3219 | `but if` is a generic conditional branch over **any** base action, including inside ordinary loops and loop expansion. | `but if` on a plain statement, inside a `For each`, and on a loop expansion | yes | `gen leaf butif print` (plain `Print` base), `gen leaf butif append` (plain `append` base) | exercised for plain bases; **todo** for a `but if` inside a loop or on a loop expansion — no leaf emits either | |
| LST2-74 | 3222–3226 | The fizzbuzz example: `modulo 6` is checked first, so 6 and 12 print `fizzbuzz`. | reproduce verbatim | yes — the generator knows every line of the expected 15 | none (the construct is emitted by `butif print`; this specific overlapping-conditions shape is not) | todo as a composite; its sub-claims are LST2-78/82 | |
| LST2-75 | 3228–3230 | The even/odd example labels only the matching iterations. | reproduce verbatim | yes | none | todo | |
| LST2-76 | 3232–3234 | The conditional-append example: `append each number from 1 to 5 to out, but if … append 0.` gives `[1, 0, 3, 0, 5]`. | a `but if` append chain on a loop expansion | yes — the generator computes the whole result: check `out's length` and each element | `gen leaf butif append` emits a `but if` append chain, but never over a loop expansion | todo — hand-verified (`LST2-76.vox`) | |
| LST2-77 | 3238 | The default action is the base statement. | a chain whose conditions are all false | yes | `gen leaf butif print`, `gen leaf butif append` | exercised | |
| LST2-78 | 3239 | Each `but if` clause is checked **in order**. | a chain with two conditions that both hold | yes — assert the first one's effect, not the second's | `gen leaf butif print`/`append` emit multi-branch chains, but their conditions come from `gen condition` and are not arranged to overlap, so ordering is never actually put on trial | todo (verification); exercised (construct) | |
| LST2-79 | 3240 | If a condition is true, that alternative runs **instead of** the default. | a chain where the base action's effect would be visible if it also ran | yes | `gen leaf butif print`/`append` | exercised | |
| LST2-80 | 3241 | If no conditions match, the default action runs. | — | yes | `gen leaf butif print`/`append` | exercised | |
| LST2-81 | 3242 | An optional `otherwise` clause provides a final alternative. | an `otherwise` on both a `print` base and an `append` base | yes | `gen leaf butif append` **always** emits one; `gen leaf butif print` **never** does (its own comment records that the bare spelling is rejected after `print`) | exercised for `append` only — and the presence of the clause is fixed per leaf rather than varied, which is an unjustified invariant. **D2 resolved by vox #50 (0.4.8+): the bare `otherwise` now compiles after `print` too**, so the print leaf can carry either spelling; what still holds this row at `append`-only is `gen leaf butif print`, whose stale comment says the bare form is rejected. | |
| LST2-82 | 3245 | Conditions are checked in order — **first match wins**. | overlapping conditions, as in fizzbuzz | yes | same as LST2-78 | todo (verification) | |
| LST2-83 | 3246 | Multiple `but if` clauses can be chained. | — | yes | `gen leaf butif print`/`append` emit 1–3 branches | exercised | |
| LST2-84 | 3247 | The alternative action can be **any** valid Vox statement. | alternatives that are a `Set` and a function call, not only a `print`/`append` | yes | `gen leaf butif print` alternatives are always `print <expr>`; `butif append`'s are always `append <expr>`. No other statement kind is ever an alternative. | todo — real gap, hand-verified with a `Set` and a call (`LST2-73.vox`) | |
| LST2-85 | 3248 | `otherwise` provides a catch-all alternative. | — | yes | `gen leaf butif append` | exercised (append only) | |
| LST2-86 | 3249 | `but if` works with both ranges and collections. | a chain over a range source and over a list source | yes | none — no `but if` chain any leaf emits sits on a loop expansion at all | todo | |
| LST2-87 | 3250 | The loop variable is available in the conditions. | a condition naming the loop variable | yes | none (same reason as LST2-86) | todo | |
| LST2-88 | 3251 | In an `append` branch the `to <list/buffer>` target may be **omitted** and is inherited from the base append; **retargeting** to a different list/buffer is not allowed. | an append chain with an omitted target, plus the compile-error form | yes for the inheritance half; the retargeting ban is a compile-error claim | `gen leaf butif append` always omits the target (inheritance exercised) | exercised (inheritance); not assertable (the ban) — the refusal names both lists, hand-verified | |
| LST2-89 | 3255 | `treating X as Y` performs inline value substitution on a loop expansion. | — | yes — the generator picks the collection and the match, so it knows exactly which iterations substitute | `gen leaf treating print`, `gen leaf treating grid` | exercised | |
| LST2-90 | 3257–3263 | The file example: `open … at each filename from arguments's all treating "-" as "/dev/stdin"` reads a named file or standard input from the same sentence. | a loop-expansion `open` with a `treating` clause and real argv | yes — the generator controls argv and the fixture's byte count | none — no leaf emits `open … at each` at all | todo — hand-verified both ways (`LST2-90.vox`). Note the manual's block omits the `content` buffer declaration and is an `Unknown buffer: content` compile error as printed. | |
| LST2-91 | 3264–3265 | The print-with-default example: `print each name from names treating "" as "Anonymous".` | a text collection with an empty-text match | yes | `gen leaf treating print` uses `"-"`→`"none"` on `arguments's all` (always empty) or number literals on a number list; an empty-text match is never emitted | exercised in shape; **todo** for the empty-text match | |
| LST2-92 | 3267–3268 | **RESOLVED, 2026-08-22.** The call-with-substitution example now reads `process of each filename from files treating "-" as "/dev/stdin".` — the loop variable is renamed from the reserved `file` to `filename`. | reproduce verbatim | yes — the generator controls `files` and can predict the substitution | none | todo — unblocked, Discrepancy 6 RESOLVED (manual fixed) | |
| LST2-93 | 3275 | The syntax is `… each <var> from <collection> treating <match> as <replacement>, …`. | — | yes | `gen leaf treating print`, `gen leaf treating grid` | exercised | |
| LST2-94 | 3277 | If the loop variable equals `<match>` it is replaced with `<replacement>` for that iteration. | a collection that definitely contains the match | yes — `gen leaf treating print` already draws both from the same 0–99 range, so a hit is possible but never guaranteed; a leaf that plants the match can assert the substituted value | `gen leaf treating print` (hit not guaranteed), `gen leaf treating grid` | exercised; **todo** for a guaranteed hit and its assertion | |
| LST2-95 | 3275 | *(gap)* In a grid, a `treating` clause binds to the **one** `each` clause it follows, not to the whole sentence: a value matching the pattern in another clause is left alone. | a grid where the same value appears in two clauses and only one carries `treating` | yes | `gen leaf treating grid` gives **each** clause its own `treating`, so the per-clause scoping is emitted but never contrasted against an unadorned sibling clause | exercised (both clauses adorned); **todo** for the contrast — hand-verified (`LST2-95.vox`) | |
| LST2-96 | 3085–3088 | *(gap, now closed)* The "Supported collections" list was **not enforced**: an `each` clause over a scalar compiled with no diagnostic and **segfaulted**, and one over a map or a buffer compiled and yielded garbage. **Fixed by vox #49 (0.4.8+)** — both are now compile errors with kind-specific hints. | — | **no** — a leaf still must not emit this, because it no longer compiles. The row stays on the record as the history of the hole. | n/a — no leaf emits a non-list, non-range, non-`arguments` source | not assertable — the construct is rejected at compile time, so no running program can put it on trial. **Discrepancies 3 and 4 resolved** (`D3.vox`, `D4.vox`) | |

## Discrepancies

None of these has been filed, and none is adjudicated here. Each has a
runnable minimal repro in `docs/ledger/probes/collections-b/`.

### 1. The manual's "Append strings" example does not compile — RESOLVED

Old manual line 2764–2767 (pre-0.4.9), inside the Appending to Lists examples block:

```
(Append strings)
a list called words is [].
append hello to words.
append world to words.
```

Repro (`D1.vox`) → `error: Unknown variable: hello` (and the same for
`world`); no binary is produced. Bare words are not text literals in Vox;
`append "hello" to words.` compiles and works.

**Strongest reading under which the compiler is correct:** unquoted `hello`
is an identifier everywhere else in the language, and a language whose
literals need quotes cannot make an exception here without making
`append x to nums` (old manual line 2771, four lines later, and *deliberately*
about a variable) ambiguous. The compiler is right and the example is a
typo — but it is a typo in the one block a reader copies from, and it sits
directly above the variable example whose whole point is the distinction.

**Resolution (lawyer): MANUAL BUG, certain** — quote `"hello"`/`"world"` at :2766–2767. → vox docs.

**Resolution confirmed, 2026-08-22.** LANGUAGE.md:3046–3049 now quotes both strings.

### 2. The documented `otherwise` clause is rejected after a `print` base action and accepted after an `append` one

LANGUAGE.md:3242 ("An optional `otherwise` clause provides a final
alternative") and 3099 ("`otherwise` provides a catch-all alternative") name
the clause without qualification, in a section that says at 3070 that `but
if` works "over any base action" (was 2960/2966/2937 pre-0.4.9). Repro (`D2.vox`):

```
a number called gauge is 8.
print gauge, but if gauge is greater than 50 print "high", otherwise print "low".
```
```
error: Expected a statement, got Otherwise
```

The three neighbouring spellings all compile and run:

| sentence | result |
|---|---|
| `print gauge, but if … print "high", but otherwise print "low".` | prints `low` |
| `append 1 to kept, but if … append 7, otherwise append 9.` | `[9]` |
| `append 1 to kept, but if … append 7, but otherwise append 9.` | `[9]` |

So the clause exists for both base actions; only the bare `otherwise`
spelling after `print` is refused.

**Strongest reading under which the compiler is correct:** the section is
titled "Conditional Branching with `but if`" and every clause in it is
introduced by `but`. Under that reading the manual's "`otherwise` clause" is
shorthand for "`but otherwise` clause" — it names the distinguishing word,
not the token sequence — and `print`'s grammar is simply the stricter of the
two, with `append`'s bare form the lenient outlier. The generator already
knows half of this: `gen leaf butif print`'s own comment records that bare
`otherwise` is rejected after `print` and concludes the print chain must
never carry one. **The new half is that `but otherwise` works after
`print`**, so the coverage gap that comment describes is closable without
emitting anything illegal.

**Resolution (lawyer): COMPILER BUG, high — vox bug #50.** `src/parser/control_flow.rs:81` omits `Token::Else | Token::Otherwise` from the chain-continuation set; `parse_block` deliberately leaves `Otherwise` current (its trailing-comma arm :1268–1276) and the caller refuses it — only the terse `append` branch re-enters on Comma and reaches the Else/Otherwise arm at :105. Not print-specific (`increment n, otherwise increment n` fails too). Fix: add the two tokens at :81.

**Resolution: fixed by vox #50 (0.4.8+).** `D2.vox` re-run against current
main compiles and prints `low`; the bare `otherwise` spelling is now
accepted after a `print` base action, exactly as LANGUAGE.md:3242 and 3099
describe. The probe now records the fixed behaviour. LST2-81 is unblocked
on the compiler side — what still holds it at "exercised for `append`
only" is `gen leaf butif print`, which has never emitted the clause; its
comment saying the bare spelling is rejected after `print` is now stale.

### 3. A loop-expansion clause over a scalar compiles silently and segfaults — RESOLVED (vox #49)

Old manual line 2803–2806 (now 2936–2939, unchanged in substance) lists the supported collections as lists, ranges and
`arguments's all`. A scalar is none of them. Repro (`D3.vox`) is the whole
program:

```
print each part from 4.
```

Segmentation fault, exit 139, deterministic (5/5 runs). `a number called
gauge is 4. print each part from gauge.` crashes identically, as does a text
**variable**. (A text **literal** — `print each part from "hello".` — instead
runs zero iterations and exits 0.)

By `CLAUDE.md`'s ordering this is the most serious thing in this section: Vox
promises that no program, however stupid, segfaults, and this one is two
tokens long. Note also that the analyzer already rejects the neighbouring
mistake — `element 1 of <a number>` is a clean compile error — so the
machinery to refuse a non-collection exists and is simply not applied to the
`each … from` clause.

**Strongest reading under which the compiler is correct:** there is no
reading under which the segfault is correct. The nearest defensible position
is that the *diagnostic* is missing rather than the behaviour being wrong —
`each … from <scalar>` is meaningless, the manual never says it is legal, and
a language that checks this at compile time would reject it there. That makes
this a missing check, not a wrong answer. It does not excuse the crash: a
missing compile-time check must degrade to a runtime error flag, which is the
contract the rest of this section (LST2-25) is built on.

**Resolution (lawyer): COMPILER BUG — MEMORY SAFETY, certain — vox bug #49.** `ForEach` gets no collection-kind check in the analyzer (`src/analyzer/statements.rs:852` only analyzes definedness) and codegen (`src/codegen/statements.rs:1482–1487`) unconditionally does `mov rax, [rax + 8]` on the scalar's VALUE as a list header. Broader than the ledger: the plain `For each part in n,` and `append each part from 4 to out.` crash too — every ForEach. Fix: known-scalar rejection by name (number/float/boolean/text/buffer/map), precedent `analyzer/expressions.rs:675–685` (`Element access target must be a list`), NOT a whitelist (untyped list parameters must keep working).

**Resolution: fixed by vox #49 (0.4.8+).** `D3.vox` re-run against current
main is refused at compile time — `error: Loop collection must be a list:
a number`, with the hint `` `each ... from` walks a list, a range, or
`arguments's all` ``. The segfault is gone: no binary is produced. A named
number reports the variable's name (`Loop collection must be a list:
gauge`) plus a kind-specific hint; a text variable and a text literal are
refused as `... must be a list: text`. The probe now records the compile
error. One defect *was* introduced with the new diagnostic — its caret is
located by text-searching the source, so it can land inside a comment; that
is Discrepancy 10, and nothing is blocked on it.

### 4. A loop-expansion clause over a map or a buffer compiles silently and yields garbage — RESOLVED (vox #49)

The quiet sibling of Discrepancy 3, same lines, same absent check. Repro
(`D4.vox`):

```
a map called scores is {"a": 1, "b": 2, "c": 3}.
print each entry from scores.        (prints 0, 0, 3)
a buffer called sink is "abc".
print each part from sink.           (prints 6513249, 0, 0)
```

No diagnostic, no error flag, no crash. The values are stable across runs of
one binary but are not the map's keys, its values, its length, or anything
else the program contains. An empty map produces no iterations at all, which
is what makes this look like it is "working" from a distance.

**Strongest reading under which the compiler is correct:** a map and a buffer
are both heap objects with a length, so the loop-expansion lowering can walk
them as if they were lists and produce *something* rather than failing; under
that reading the compiler is doing the only thing it can with an operand
nobody specified. What that does not excuse is the silence — this is a wrong
answer with no flag raised, the exact failure mode `CLAUDE.md` calls the
nastiest kind. Separated from D3 because the observable behaviours differ
(garbage versus crash) even though the missing check is the same one.

**Resolution (lawyer): COMPILER BUG, same defect as D3 — folded into #49.** Map/buffer headers misread as a list header: the 3-entry map iterates 3 times; the buffer's first "element" printed 6513249 = 0x636261 = "abc". One check fixes both.

**Resolution: fixed by vox #49 (0.4.8+).** `D4.vox` re-run against current
main is refused at compile time, once per clause, with kind-specific hints:
`scores is a map - iterate ``scores's keys`` or ``scores's values``` and
`sink is a buffer - ``each ... from`` walks a list, a range, or
``arguments's all```. The silent garbage is gone. The probe now records the
compile errors.

### 5. "The first append determines the list's element type for printing" is not what happens — RESOLVED

Old manual line 2753 (pre-0.4.9), a "Key features" bullet. Repro (`D5.vox`):

```
a list called sayings is [].
append "text first" to sayings.
append 42 to sayings.
print sayings.                       (prints ["text first", 42])

a list called tallies is [].
append 42 to tallies.
append "then text" to tallies.
print tallies.                       (prints [42, "then text"])
```

Both directions render each element by its own tag. The same holds when the
list starts from a literal and when the appended text is opaque (the return
of a function rather than a literal). Nothing observable changes with the
order of the first append.

**Strongest reading under which the compiler is correct:** old manual line 2673–
2675 (now 2804–2806, since reworded — see Discrepancy 8), eighty lines earlier in the same chapter, said each element "renders
exactly as it does when printed individually" — which is per-element
dispatch, the opposite of a whole-list element type. The compiler follows the
rendering rule and the "type tracking" bullet is the stale one; "type
tracking" plausibly describes the internal homogeneous fast path
(collections-a LST-08, LST-25), whose real observable consequence is which
arithmetic the analyzer accepts on a loop variable, not what printing looks
like. Under that reading the compiler is right, the bullet is misdescribing
an optimisation, and the manual contradicts itself within one chapter.

The practical consequence either way: a leaf must not assume a homogeneous
rendering after a first append, and LST2-36 stays `todo` until this is
adjudicated.

**Resolution (lawyer): MANUAL BUG, high** — the :2753 "type tracking" bullet is false in both directions and contradicts :2673–2675 (the rule the compiler follows); it describes an internal fast path in observable-behaviour language. → reword or delete.

**Resolution confirmed, 2026-08-22.** LANGUAGE.md:3024–3026 now reads "Mixed types: Appends of different types are allowed in any order; each element is printed by its own type, never by the list's" — the bullet was reworded exactly as recommended, not deleted.

### 6. The manual's "Call function with substitution" example does not compile — RESOLVED

Old manual line 2986 (now 3118–3119, since fixed — see below):

```
process of each file from files treating "-" as "/dev/stdin".
```

Repro (`D6.vox`) → `error: Cannot use 'file' as a variable name - it's a
reserved keyword.` The sentence binds a loop variable called `file`, and
`file` is reserved. Renaming the loop variable is the whole fix; with
`each entry` the same sentence runs and substitutes correctly.

**Strongest reading under which the compiler is correct:** `file` is a
keyword of the file-I/O statements (`open a file for reading called …`), and
a loop variable is a variable like any other, so the reserved-word check is
right to fire. The example is simply written in a word the language owns —
the same class of defect as collections-a's broken examples, and the second
one in this range after Discrepancy 1.

**Resolution (lawyer): MANUAL BUG, certain** — `file` is a keyword (:439) and keywords are reserved as variable names (:4577); the example is DUPLICATED at :419 and :2986 — both need the rename.

**Resolution confirmed, 2026-08-22.** LANGUAGE.md:3267–3268 now reads `process of each filename from files treating "-" as "/dev/stdin".` — renamed, as recommended.

### 7. A collection interpolated outside `Print` position renders a run-varying heap address — variable form RESOLVED (vox #44), expression form RESOLVED (vox #68, landed in 0.4.10)

This is collections-a's Discrepancy 7 reproduced against **this** range's
claim. LANGUAGE.md:2942–2946 (was 2680–2681, then 2811–2813) said "the same rendering appears inside the
*variable* form of `{...}` format interpolation"; the sentence is now
merged with the expression-form half and states the fixed rule for both
(see LST2-12/LST2-13, above). It appears in `Print`
position. Repro (`D7.vox`, written as verdict lines so it re-runs clean),
**re-verified against vox 0.4.9, 2026-08-22 — split result**: the
*variable* form (`a text called captured is "{flat}".`) now renders the
list correctly. The *expression* form (`"{element 2 of nested}"`) still
renders a raw heap address:

```
a list called flat is [1, 2, 3].
print "print position: {flat}".      (prints: print position: [1, 2, 3])
a text called captured is "{flat}".  (captured is NOT "[1, 2, 3]")
a list called nested is [1, [2, 3], "four"].
a text called inner is "{element 2 of nested}".   (inner is NOT "[2, 3]")
```

Raw, the two failing slots print bare integers that change between runs
(139857342844928 / 140086226763776 / …) — live heap addresses. The
expression-form half is *documented* at 2681–2682 ("does not dispatch on a
nested element's runtime tag"), but the manual does not say what it renders
instead, and a run-varying pointer is a nondeterminism finding manufactured
by the generator rather than found by it.

**Strongest reading under which the compiler is correct:** as argued in
collections-a — the "identically in every sink" sentence at 3082–3085 may
scope only to named specials, and 2311–2314 already warns that list rendering
in format strings is tag-dispatch-dependent and incomplete, recommending the
variable form, which does work in the position the manual demonstrates. What
that reading does not cover is the silence: the non-print sinks do not fail,
they emit a live pointer as text.

**Consequence for this section, unchanged from the sibling ledger:** LST2-13
must stay `todo`, and no leaf may put a collection slot in a non-print sink
via the expression form; the variable form is now safe.

**Resolution (lawyer): COMPILER BUG, duplicate of vox #44** — same print-only `_list_print` path (`codegen/print.rs:94/237/318/381`); :2680–2681 is a second citation for #44. New sub-case: the EXPRESSION form `print "{element 2 of nested}"` leaks an address in print position too. Fold into #44 as an extra repro.

**Split resolution, confirmed 2026-08-22.** #44 fixed the variable-form
sub-case (this ledger's `D7.vox` and collections-a's `D7.vox` both
confirm it directly). The expression-form sub-case this row's discovery
added — which #44's fix did **not** reach, even in print position — was
tracked as vox candidate **#68** (`fix/bug-68-format-hole-mixed-
element`), matching `vox-notes/REPORT-CANDIDATES-0.4.10.md` candidate E
("The *expression* form of a format hole over a mixed list renders every
element as an integer... partially — #44 fixed the variable form in
every sink; this path untouched") and `ROUND-2.md`'s "#68 format hole
over a mixed element."

**#68 landed in 0.4.10, discrepancy fully RESOLVED, re-verified
2026-08-22.** CHANGELOG.md #68: "The tag was loaded and then discarded:
the hole's expression path rendered by the compiler's static guess
instead of the slot's runtime tag. It now dispatches on that tag in
every sink — Print, a text initializer, buffer `set`/`copy`/`append`,
`write`, filesystem paths, `treating` clauses and function arguments."
Re-ran `D7.vox` verbatim against 0.4.10: `a text called inner is
"{element 2 of nested}".` now equals `"[2, 3]"`, where it used to hold a
live heap address that changed between runs. Both sub-cases of this
discrepancy are now closed; LST2-13 (above) is unblocked.

### 8. "Renders exactly as it does when printed individually" contradicts its own sentence — RESOLVED

Old manual line 2673–2675 (pre-0.4.9): "Each element renders exactly as it does when printed
individually: text elements are quoted (so `["1"]` is distinguishable from
`[1]`)". Repro (`D8.vox`), still reproduces (this is the compiler's behaviour, always correct):

```
a text called word is "alpha".
print word.                (prints: alpha)
a list called packed is [word].
print packed.              (prints: ["alpha"])
```

A text printed individually is bare; the same text inside a list is quoted.
The two halves of the sentence cannot both be true.

**Strongest reading under which the compiler is correct:** the colon
introduces the operative rule and the leading clause is a loose gloss meaning
"by its own type, not by the list's" — which is exactly what the compiler
does, and exactly what Discrepancy 5's bullet gets wrong. Recorded because
the sentence is the only place the manual states the rendering rules, and a
leaf author who reads the first half writes a different assertion from one
who reads the second. Low severity; a five-word edit fixes it.

**Resolution (lawyer): MANUAL BUG, low** — replace "exactly as it does when printed individually" with "by its own type, not the list's" (:2673–2675).

**Resolution confirmed, 2026-08-22.** LANGUAGE.md:2935–2937 now reads "Each element renders by its own type, not the list's: text elements are quoted..." — the exact replacement text the lawyer proposed.

### 9. `respectively` is described as reserved but is usable as an identifier

LANGUAGE.md:3201–3202 (was 2919–2920, unchanged in substance): "English's zip marker is `respectively`, which is
reserved as a possible future marker for a zip mode; it is not parsed today."
The second half is exactly true — `D9.vox` shows `'pair' of each x from …
and each y from … respectively.` is `error: Unknown function: respectively`.
But the first half is not: `a number called respectively is 4.` compiles and
prints 4 (`LST2-71.vox`), while genuinely reserved words (`file`, `empty`,
`number`, `from`, `flag`, `nothing`) are refused by name.

**Strongest reading under which the compiler is correct:** "reserved" here is
a design reservation — the word is earmarked for a future feature — not a
claim about today's lexer, and the sentence says so in its own second half
("not parsed today"). Under that reading nothing is wrong and the word is
merely doing double duty. The reason to record it anyway: reserving a word in
the *design* sense without reserving it in the *lexer* sense means a program
that uses `respectively` as a name compiles today and breaks the day zip
lands — which is precisely what reserved-word lists exist to prevent, and
what the compiler already does for `file` and `nothing`.

**Resolution (lawyer): MANUAL BUG + design decision** — `respectively` is not in the lexer at all; by the manual's own definition (:4783, was :4583) the sentence is false. **Josj:** reserve it now (one lexer line + table entry) or document it as unreserved like `value` (:2584, was :2479).

**Still open, re-probed against vox 0.4.9, 2026-08-22: unchanged.**
`a number called respectively is 4. print respectively.` still compiles
and prints `4`. LANGUAGE.md:3199–3202 is byte-identical to the pre-0.4.9
wording — no manual change, no compiler change. This is a design
decision awaiting Josj, not a numbered fix in flight; not in the brief's
"still open, cite the fix" list either, so no number was expected.
### 10. The `#49` collection-kind diagnostic points its caret at a comment — RESOLVED

Found on 2026-08-21 while refreshing `D3.vox`/`D4.vox` against the #49 fix.
The new diagnostic is right about *what* is wrong and wrong about *where*:
it locates the span by searching the source text for the clause, so it marks
the first textual occurrence — including one inside a comment. Repro
(`D10.vox`) is two lines:

```
(this comment quotes print each part from gauge. in prose)
print each part from 4.
```
```
error: Loop collection must be a list: a number
  --> D10.vox:1:33
    |
  1 | (this comment quotes print each part from gauge. in prose)
    |                                 ^--- here
```

The message (`a number`) is derived from the real statement — the literal
`4` — while the caret is on the comment. `D3.vox`'s own header comment
quotes the clause, which is why that probe reported line 6 of a header
whose only statement is on line 21. With a named collection the caret lands
on the variable's *declaration* rather than on the loop clause (`D4.vox`),
which is a milder form of the same thing.

**Strongest reading under which the compiler is correct:** none for the
comment case — a caret inside a comment cannot be right. For the
declaration case there is one: naming where the offending variable was
*introduced* is a reasonable thing for a type-kind error to do, and the hint
line already names the variable, so a reader is not misled. Only the
comment case is unambiguously wrong.

Severity is low and nothing is blocked on it: the program is correctly
refused either way, no leaf can emit a program that fails to compile, and
`docs/check-probes.sh` matches on the message rather than the span. It is
recorded because a diagnostic that points at the wrong line is exactly the
kind of thing that costs an hour the next time somebody trusts it.

**Resolution confirmed, 2026-08-22: fixed.** Re-run `D10.vox` against vox
0.4.9: the caret now lands on line 2 (`:2:12`), the actual offending
statement, not on the comment on line 1.

## Invariants this section justifies

Samenesses the manual actually requires of any generated program in this
area, each with the line and the row that justifies it:

- a printed list is always wrapped in `[` `]` with `, ` between elements — LANGUAGE.md:2935, LST2-05
- an empty list always prints exactly `[]` — LANGUAGE.md:2938, LST2-09
- text elements inside a printed list are always quoted; numbers never are — LANGUAGE.md:2936–2937, LST2-06
- booleans inside a printed list always render `1`/`0`, never `true`/`false` — LANGUAGE.md:2937, LST2-07
- a nested list element always prints with its own brackets, recursively — LANGUAGE.md:2938–2940, LST2-10
- a map inside a printed list always renders `{"key": value, …}` — LANGUAGE.md:2940–2941, LST2-11
- a list property read is always spelled `<list>'s <property>` — LANGUAGE.md:2950, LST2-14
- the list property name is always one of `length`, `size`, `empty`, `first`, `last` — LANGUAGE.md:2962–2968, LST2-15…LST2-19
- a list element read is always spelled `element <index> of <list>` — LANGUAGE.md:2975, LST2-22
- list element indices are always 1-based; index 0 is never the first element — LANGUAGE.md:2972, LST2-21
- `append <value> to <list>` always puts the value at the END — LANGUAGE.md:3004, LST2-29
- one `append` statement always adds exactly one element — LANGUAGE.md:3014, LST2-31
- a loop expansion is always spelled `<action> each <variable> from <collection>` — LANGUAGE.md:3083, LST2-47
- an `each` clause's collection is always a list, a range, or `arguments's all` — LANGUAGE.md:3085–3088, LST2-48/49/50 (nothing enforces this — LST2-96)
- a range clause is always inclusive at both ends — LANGUAGE.md:3087, LST2-49
- grid clauses are always joined by `and` — LANGUAGE.md:3126, LST2-57
- a grid always runs row-major, leftmost clause outermost — LANGUAGE.md:3127–3128, LST2-58
- the number of argument clauses always equals the callee's parameter count — LANGUAGE.md:3143–3150, LST2-62
- `print`, `append` and `open` always carry exactly one `each` clause — LANGUAGE.md:3154–3155, LST2-63
- a `print <func> of …` grid always leads with an `each` clause — LANGUAGE.md:3157–3162, LST2-65
- every `each` clause in one sentence always binds a different loop variable name — LANGUAGE.md:3172–3178, LST2-67
- `but if` clauses are always evaluated in written order, first match wins — LANGUAGE.md:3239, 3245, LST2-78, LST2-82
- a `but if` append branch always omits its target and never names another list — LANGUAGE.md:3251, LST2-88
- `treating` is always spelled `treating <match> as <replacement>` and always follows its own `each` clause — LANGUAGE.md:3275, LST2-93, LST2-95

Everything else in this range must vary, and the invariant report should be
read as demanding a fix for any of these that it finds fixed: which property
is read and on what shape of list; whether an element index is a literal or a
variable, and which index; how many appends and of which value kind
(literal / variable / expression / text / boolean); whether a list is printed
whole, iterated, or only indexed; which collection kind an `each` clause
draws from; range bounds, direction, and whether they are literals or
variables; grid depth, clause order, and whether a fixed argument appears and
where; how many `but if` branches a chain carries; whether an `otherwise`
appears and in which spelling; what kind of statement an alternative is;
whether a `treating` clause appears and on which clause of a grid; and every
loop variable name.

**Fixed today with no citation** (read out of the leaves, not out of a
corpus — the master's invariant run over a real campaign is the authority):
every generated list literal is two elements and every `list mixed` is
number-then-text-then-float in that order; `gen leaf list inrange` always
appends exactly once and always reads `element 1`; `gen leaf list oob` always
draws an index ≥ 10, so index 0, −1 and N+1 are never reached; `gen leaf
butif print` **never** carries an `otherwise` and `gen leaf butif append`
**always** does; every `print each` is emitted with a `treating` clause
attached and never bare; every grid outside `deep grid` is exactly two
clauses; and no generated program has ever printed a whole list.

## Report

**96 rows** (LST2-01 through LST2-96, no gaps, no duplicates). One (LST2-64)
is an explicit fold into a sibling row; two (LST2-33, LST2-34) are
cross-references to `buffers.md` BUF-32/BUF-33 and are not re-mapped here.
That leaves **93 distinct claims**. By status: **35 exercised, 50 todo, 6
not assertable, 2 blocked on a broken manual example, 0 verified** — counting
a row as `exercised` only when a leaf emits its construct outright, not when
a leaf emits a narrower cousin (those rows read `todo … ; exercised …` and
say which half is which).

**Assertable: 71** of the 93 name a concrete assertion the generator could
emit. The other **22** fall into four distinct flavours, worth keeping apart
because only the first has a usable workaround:

- **14 rendering claims** (LST2-01…LST2-13, LST2-36) — a list's rendering
  exists only in `Print` position and a program cannot read its own output,
  so the printed text is unreachable as an oracle. Every one of them has an
  assertable *shadow* (`'s length`, `element N of`, `'s first`/`'s last`),
  named in its row. This is a different flavour from the buffer ledger's
  freed-on-exit rows: the behaviour is fully observable by a human reading
  the output, just not by the program.
- **5 compile-error claims** (LST2-62, LST2-63, LST2-65, LST2-67, LST2-71;
  the retargeting ban in LST2-88 is a sixth, but that row is assertable for
  its inheritance half) — real, hand-verified, but a runtime leaf cannot emit
  them without breaking the "legal Vox that should compile and run" contract.
- **2 claims whose documented form does not compile** — LST2-39 and LST2-92,
  both blocked on a discrepancy (D1, D6) rather than on a missing leaf.
- **LST2-96**, which a leaf must not emit for the opposite reason: it
  crashes.

**Existing coverage: seven leaves, broad in the middle of the range and
absent at both ends.** `gen leaf list inrange`/`oob`, `gen leaf butif print`/
`append`, `gen call grid`, `gen leaf deep grid`, `gen leaf treating print`/
`grid` and `gen leaf format types` between them exercise append, element
access in and out of range, the `but if` chain, the two-clause and deep
grids, and both `treating` forms. Not one asserts a documented result.

**Three whole sub-sections have zero coverage:**

1. **Printing a list.** No leaf anywhere prints a whole list variable —
   `grep` for a bare `Print l{`/`print l{` in `src/` finds nothing. The only
   list rendering that reaches a campaign is `gen leaf format types`'
   `Print "list {hl{n}}"`, always a two-element number list. Every rendering
   rule the manual states — quoting, boolean 1/0, float form, empty `[]`,
   nested brackets, a map inside a list — is untested.
2. **List properties.** Not one of `length`, `size`, `empty`, `first`, `last`
   is ever read on a list. `'s length` is emitted on a map and a buffer,
   `'s empty` on `environment`/`arguments`/a buffer, and `'s first`/`'s last`
   on nothing at all. This is the same trap `buffers.md` flagged for
   `capacity` and `full`: a `grep` that stops at the property name credits
   coverage that does not exist.
3. **Loop expansion in its own right.** `print each … from <range>`,
   `append each … to`, `open … at each`, `print <func> of each`, an empty
   collection, and a list *variable* as a source are all absent. The
   `each` machinery is exercised almost entirely through function-call grids
   and `treating`, never through the four specialized forms the manual leads
   with.

**Biggest finding — Discrepancy 3, a two-token segfault.** `print each part
from 4.` compiles without a diagnostic and dies with SIGSEGV, deterministically.
Vox's headline promise is that no program, however stupid, corrupts memory,
and this is about as stupid and as short as a program gets. Discrepancy 4 is
the same missing check failing quietly instead — a map or buffer `each`
source yields garbage values with no flag raised. The compiler already
rejects the neighbouring mistake (`element 1 of <a number>` is a clean
compile error), so the check exists and is simply not wired to the `each …
from` clause. **These are the first two things to put in front of a human.**

**Runner-up — Discrepancy 2 is immediately actionable and cheap.** `gen leaf
butif print` deliberately never emits an `otherwise` because the bare
spelling was rejected after `print`; `but otherwise` was accepted and behaved
correctly. **As of vox #50 (0.4.8+) both spellings work**, so the leaf can
vary which one it emits. That closes a real coverage gap and removes an unjustified
invariant (otherwise-always-on-append, never-on-print) with a one-line change
to an existing leaf.

One process note for whoever runs the gate: `docs/check-probes.sh` uses a
10-second timeout, and any probe that deliberately crashes will trip it
occasionally on a machine with core dumps enabled. `D3.vox` did once in
about twenty sweeps — before #49 turned it into a compile-error probe. No
probe in this directory crashes today, but the note stands for the next one
that does: `ulimit -c 0` before the sweep is the fix; the alternative —
softening the probe so it stops crashing — would delete the finding.

**Updated 2026-08-22: of ten discrepancies, eight are now resolved**
(D1, D2, D3, D4, D5, D6, D8, D10 — re-verified directly against vox
0.4.9, not just re-read). D2, D3, D4 and D10 by compiler fixes (#50,
#49, #49, and an uncredited caret fix); D1, D5, D6, D8 by manual fixes.
**Two remain open**: D7 (split — the variable-form sub-case is fixed by
#44, but the expression-form sub-case is a distinct finding tracked as
candidate #68, still in flight) and D9 (`respectively`, a design
question for Josj, no register number found). D1 and D6 were broken
examples in the manual — the same pattern collections-a found four of,
and the same reason: neither block was ever compiled — and both now
show the corrected form. D7 is collections-a's D7 reproduced against
this range's own claim.

### Advice for the next mapper

1. **`grep` the accessor *and* the operand type.** Half this section's
   coverage gaps were invisible until I read the statement each `'s length`
   hit was built into: three of them are on maps and buffers, none on a list.
   `buffers.md` gave this advice; I can confirm it caught six rows here that
   a name-level grep would have marked `exercised`.
2. **Probe the empty case and the boundary case of every property and
   accessor, even when the manual is silent.** Three rows in this ledger
   (LST2-20, LST2-28, LST2-49) exist only because I ran `first` on an empty
   list, `element 0`, and a descending range. All three are real, documented
   nowhere, and all three are exactly the kind of thing a fuzzer generates by
   accident at 3am.
3. **Feed every construct an operand of the wrong type once.** D3 and D4 both
   came from one five-minute pass asking "what if the collection isn't a
   collection?" — and one of them is a segfault. The manual's "Supported X"
   lists are claims about what the compiler *rejects* as much as what it
   accepts, and nothing else in the ledger tests the rejection half.
4. **Distinguish "not assertable" flavours in the report, not just the
   column.** This section has three genuinely different kinds (unreadable
   rendering, compile-error claims, must-not-emit) and lumping them under one
   count would hide that fourteen rows have a perfectly good assertable
   shadow while eight have none.
5. **Read the leaves' comments before writing `existing leaf`.** `gen leaf
   butif print`'s comment already contained half of Discrepancy 2, recorded
   by whoever built it and never followed up. The generator's own source is a
   ledger of hand-verified facts that nobody indexed.
6. **Naming landmines, extending the list `values.md` and `collections-a.md`
   started.** Reserved and refused by name: `file`, `empty`, `number`,
   `from`, `flag`, `a`, `b`, `nothing`, `reading`. Accepted: `respectively`
   (see D9), `entry`, `step`, `gauge`, `roster`, `member`, `part`, `path`.
   Also: **multi-word identifiers do not work in a plain program** the way
   they do in the generator's own quoted-name style — `a list called started
   blank is [].` parses as a function call and fails with `Unknown function:
   blank`. Probe programs must use single-word or underscored names.

### What I could not do

- **LST2-96 has no probe of its own** beyond the two discrepancy repros, and
  I did not chart the whole space of wrong operand types — I tested a number
  literal, a number variable, a text variable, a text literal, a map and a
  buffer. A `thing`, a `value`, a `nothing` and a file handle are untested as
  `each` sources.
- **LST2-50 has never had its loop body run in a campaign.** `gen leaf
  treating print` uses `arguments's all`, and the fuzzer passes no arguments,
  so the construct is emitted and iterates zero times every single run. I
  recorded this in the row rather than treating it as coverage.
- **LST2-35 establishes that 2000 appends work**, not where any reallocation
  threshold is; the same limit collections-a hit at LST2-44 for maps.
- **The `_map_print` mechanism named at LANGUAGE.md:2941** (was 2679) is an internal
  function name. I verified the rendering it is credited with; I did not
  verify that the rendering comes from that function, and there is no way to
  from inside Vox.
