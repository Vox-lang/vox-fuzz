# Claim ledger: Things (part B)

Source: `../vox/LANGUAGE.md` lines **1195–1815**, manual version **Vox
0.4.9** (5327 lines, vox `4b77934`), re-pinned 2026-08-22 (previously
pinned to a 5238-line 0.4.8 manual) — Things § Printing, Equality, The
manifest, The three call forms, One identifier space, Definitions are
top-level only, Cross-file definitions, `.lib` export of a thing is not
yet supported, Sentence consumption and multi-line definitions,
Definition diagnostics, Type predicates and the runtime tag, Design
notes for review.

1195 is `### Printing` and 1816 is `## Expressions`. The drift from the
0.4.8 pin is a remarkably uniform **+27 lines** across the entire
section — every subsection heading in this range shifted by exactly 27,
confirmed against the manual text at more than a dozen points before
applying it — with no sign of local insertions or deletions inside the
range itself. This ledger's own discrepancies are unrelated to what
moved earlier in the manual (they are all diagnostic-wording and
caret-placement observations, none adjudicated), and none has changed
between 0.4.8 and 0.4.9 as far as re-probing could tell (see below).

Compiler used for every probe: `/home/josj/scr/english/vox/target/release/vox`
(`vox v0.4.8`), `VOX_CORE_PATH=/home/josj/scr/english/vox/coreasm`.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct, or `none`, and was decided by
`grep` on the construct — `Print i{`, `'s 'made at'`, `is i{`, `see "`,
`is a `, `--shared` — never by leaf name. `src/gen_things.vox` is the
whole of the generator's things surface; `src/gen_text.vox` touches a
thing only to read one field into a format slot.

**No existing leaf asserts anything about this section.** The pattern the
buffer ledger found holds here too: `gen thing flat`, `gen thing nested`,
`gen leaf thing member` and `gen leaf thing copy` each `Print` a value for
a human to eyeball and stop there. So nothing below is `verified`, and the
`verified` column is uniformly the work still to do rather than a
per-row surprise.

## Probes

One retained probe per hand-verified row, in
`docs/ledger/probes/things-b/`, named `THG2-NN.vox`. A probe covering more
than one row is named for the first and says so in its own header
(`Also covers: …`). Each file opens with a `(...)` comment naming the
claim, the exact `Ran:` command, and an `expected output:` block recording
what the compiler **actually** printed. Compile-error rows are probes too
and record the diagnostic; `docs/check-probes.sh` treats them as such.

`docs/check-probes.sh docs/ledger/probes/things-b` re-runs the directory:
**65 passed, 0 failed, 0 skipped.**

Two sub-directories, neither globbed by `check-probes.sh`:

- `include/` — `geometry.vox` and `point_defined_elsewhere.vox`, the
  fragments the cross-file probes `see`. They are not programs and are
  never compiled alone.
- `shared/` — `THG2-57.vox` and `D5.vox`, the two that need `--shared`.
  `check-probes.sh` compiles every probe beside it *without* that flag and
  would report "expected a compile error, but it compiled", so they sit
  one directory down with their full command in their headers. Both were
  re-run by hand and reproduce exactly.

**62 probe files for 77 rows.** The 15 rows with no file of their own are
THG2-02, THG2-48, THG2-55, THG2-73 and THG2-76 (not assertable — nothing
to run), THG2-69 (an umbrella whose sub-claims each have one), THG2-74 and
THG2-75 (folded into a sibling), and THG2-09, THG2-15, THG2-40, THG2-50,
THG2-52, THG2-58 and THG2-62 (covered by a sibling row's probe, named in
the row). Of the 62, **32 record a compile-error refusal** and 30 record a
program's output.

Discrepancies 1–5 have their own repros at `D1.vox`–`D4.vox` and
`shared/D5.vox`, making 65 files in the directory itself plus two in
`shared/` and two fragments in `include/`.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| THG2-01 | 1197 | `Print p.` walks the fields in definition order and recurses into the things they hold, rendering map-style. | print a whole thing whose field order is not alphabetical, and a nested one, asserting the exact rendered text | **partly** — the field *values* are assertable one at a time (`If i{n}'s x1 is not {v} then, Exit 95.`), but the **rendering** — the order, the braces, the recursion — is not assertable from inside Vox at all: a whole thing can only go to `Print`, and `copy "{i{n}}" to buf` / `a text called t is "{i{n}}"` are both refused (THG2-07), so there is nothing to compare against. Checking the rendering needs the harness to diff stdout | `gen thing flat` (`Print i{n}` on t1/t2, src/gen_things.vox:53), `gen thing nested` (`Print i{n}` on t3, :63) | exercised — the construct is emitted and the program must not crash; nothing checks the rendering, the order, or the recursion | |
| THG2-02 | 1198–1199 | Every field name is baked into the emitted program; nothing is read from a descriptor and nothing is allocated. | — | **no** — an implementation detail. Vox exposes no allocation counter and no descriptor, so a program cannot tell a baked-in name from a looked-up one | n/a | not assertable | |
| THG2-03 | 1200 | A quoted field name prints in the quotes it is written with. | declare a thing with a quoted multi-word field and a quoted single-word field, print it, assert both spellings | **no** — same reason as THG2-01: the quoting is a property of the rendering, and the rendering never becomes a value a program can compare. Hand-verification is the only route | none — every generated field name is `x1`, `x2`, `g1`, `g2`: unquoted, single-word, never spaced. The quoted-name path is untouched | todo — and the claim as written is **false for a single-word quoted name**; see Discrepancy 1 (`D1.vox`) | |
| THG2-04 | 1201 | A function member takes no part in printing — it is the type's API, not its state. | print a whole instance of a type that declares members, assert the members do not appear | **no** — a rendering property, unreachable from inside the program (THG2-01). What a leaf *can* do is emit the print and let the harness see the line | none — `t4` is the only generated type with a manifest, and `gen leaf thing member` only ever prints `i{n}'s x1`, never the whole instance. No generated program prints a thing that has members | todo — a real gap: one line (`Print i{n}` for a t4) would close it | |
| THG2-05 | 1203–1238 | The Printing worked example compiles and behaves as shown. | reproduce it verbatim | **partly**, composite of THG2-01/03/04/06 (renderings, not assertable from inside) and the maker call of THG2-34 (assertable field by field) | none as a whole; its parts are split across `gen thing flat`/`nested` and `gen leaf thing member` | todo (composite) — hand-verified (`THG2-05.vox`). The boolean field renders as `1`, which is how Vox prints a boolean everywhere, not something this section contradicts | |
| THG2-06 | 1240–1241 | A whole thing interpolates into a format string under `Print` — `Print "the span runs {span}".` | emit `Print "… {i{n}} …"` with a whole instance in the slot, assert the rendered text matches the `Print i{n}` rendering | **no** from inside — neither rendering can be captured into a comparable value (THG2-01). A leaf emits both prints and the harness sees two identical lines; the equality is checkable only there | none — the format leaves (`gen leaf format types`, src/gen_text.vox:445, slot built at :474; `gen leaf format specifiers`, :259, slot built at :290) interpolate `hi{n}'s x1` / `zi{n}'s x1`, a **field**. A whole thing is never in a slot | todo — real gap, hand-verified to work (`THG2-06.vox`) | |
| THG2-07 | 1242–1255 | A text initializer is a different sink and rejects a whole-thing interpolation, naming the field to interpolate instead. | emit `a text called t is "… {i{n}} …"` → expect the compile error | **no, from a runtime leaf** — the generator's contract is legal Vox that compiles and runs; emitting a known compile error is outside it | none | not assertable (compile-error claim) — hand-verified (`THG2-07.vox`) | |
| THG2-08 | 1259 | `is` between two values of the same thing compares those same fields at the same depth. | declare two instances, set them alike, assert the comparison fires; set one field apart, assert it does not | yes — the generator sets every field, so it knows the answer: `If i{a} is not i{b} then, Exit 95.` | none — `is` appears between two instances only as a **copy** (`a t1 called i{b} is i{a}`, src/gen_things.vox:87). No generated program ever *compares* two things | todo — real gap | |
| THG2-09 | 1260 | `is not` is the negation of `is`. | same probe, both directions | yes, same assertion inverted | none | todo — hand-verified (covered by `THG2-08.vox`) | |
| THG2-10 | 1260–1261 | The comparison is written out by the compiler, so it recurses into nested things. | two `t3`s differing only in `g1's x1`, assert `is not`; then make them match, assert `is` | yes | none | todo — hand-verified (`THG2-10.vox`) | |
| THG2-11 | 1263–1284 | The Equality worked example compiles and behaves as shown. | reproduce it verbatim | yes, composite of THG2-08/09 plus a manifest member that takes no part | none | todo (composite) — hand-verified (`THG2-11.vox`) | |
| THG2-12 | 1286–1287 | Two things of different types cannot be compared — `origin is span` is rejected. | emit `If i{t1} is i{t2}` → expect the compile error | **no, from a runtime leaf** (compile-error claim, as THG2-07) | none | not assertable (compile-error claim) — hand-verified (`THG2-12.vox`) | |
| THG2-13 | 1287–1303 | There is no ordering on a whole thing — `origin is greater than marker` is rejected, naming the field to compare instead. | emit `If i{a} is greater than i{b}` → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-13.vox`). Its caret points at the wrong line; see Discrepancy 3 | |
| THG2-14 | 1307–1308 | A thing's callable API is declared in one place, the manifest: each `a function called <name>` entry names a member. | declare a manifest, define every entry, call each one, assert the result | yes — the generator writes the member bodies, so it knows what each returns | `gen emit prelude things` (src/gen_things.vox:117–121: `a function called 'made at'`, `a function called 'reflected across'` on t4) | exercised — the manifest is emitted and both entries are called, but nothing asserts the returned field values | |
| THG2-15 | 1308–1309 | The member is defined with `To do the <type>'s <name>`. | — | yes, same assertion as THG2-14 | `gen emit prelude thing methods` (src/gen_things.vox:124, :129) | exercised — hand-verified (covered by `THG2-14.vox`) | |
| THG2-16 | 1309–1310, 1566–1567 | `do` is a keyword only in the position `To do the <type>'s <name>`; everywhere else it is an ordinary identifier — `To do.` defines a function called `do`, and `do.` calls it. | emit a program that uses `do` as a function name and as a variable name alongside a real member definition | yes — assert the function's own return value | none — the generator never emits `do` outside the member-definition position | todo — hand-verified (`THG2-16.vox`, also covers THG2-40) | |
| THG2-17 | 1311–1312 | The member definition uses `the <type>'s` — a known identifier, per the article rule. | — | **no, from a runtime leaf** for the negative half (writing `a` there is a compile error); the positive half is THG2-15 | `gen emit prelude thing methods` (always `the t4's`) | exercised (positive form); the article's load-bearing-ness is not assertable (compile-error claim) — hand-verified (`THG2-17.vox`) | |
| THG2-18 | 1314–1332 | The manifest worked example — a two-entry manifest, one maker and one transformer, both defined — compiles. | reproduce it verbatim | yes (it prints nothing; the assertion is that it compiles and exits 0) | `gen emit things block` emits the same shape with different names (t4 / 'made at' / 'reflected across') | exercised — hand-verified (`THG2-18.vox`) | |
| THG2-19 | 1334–1335 | Function members take no storage, so layout, copy, printing and equality see only the data fields. | on a type with members: copy an instance, print it, compare it, mutate the copy, compare again | yes — the generator knows every field value at every step | `gen leaf thing copy` does exactly this — but on **t1**, which has no manifest. The one type with members (t4) is never copied, never printed whole, never compared | todo — the construct exists and the type exists, but never on the same instance. Hand-verified (`THG2-19.vox`) | |
| THG2-20 | 1337–1357 | Every declared member returns its owner; a definition whose `Return` hands back another thing is a compile error naming both the definition line and the `Return` line. | emit a member returning a different thing → expect the compile error | **no, from a runtime leaf** (compile-error claim). The positive half — that a conforming member compiles — is exercised | `gen emit prelude thing methods` obeys the rule (both members `Return a t4,`); nothing tests the rejection | not assertable (compile-error claim) — hand-verified (`THG2-20.vox`), and it does name both lines | |
| THG2-21 | 1359–1361 | A function computing some other type from a thing is an ordinary global function with no manifest entry, reached by the instance possessive. | emit a global function taking a t1 first and returning a number, call it both ways, assert the result | yes — `If r{n} is not {computed} then, Exit 95.` | none — every generated global function (`f1`–`f4`, emitted by `gen emit prelude functions`, src/gen_core.vox:843–860) takes numbers or a text. **No generated function anywhere takes a thing**, so the instance possessive on an ordinary function is unreachable | todo — real gap, and the largest one in this section. Hand-verified (`THG2-21.vox`) | |
| THG2-22 | 1361–1363 | The owner-return check reads the body's `Return` lines, not the signature, so a member whose only `Return` sits inside an `If` is not wrongly rejected. | emit a member whose Returns are all inside an If/Otherwise, call it, assert the field | yes | none — the prelude members return unconditionally at body level | todo — hand-verified (`THG2-22.vox`) | |
| THG2-23 | 1365–1379 | A `To do` naming a member the manifest does not list errors at the definition, naming the entry to add. | emit an undeclared `To do the t4's …` → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-23.vox`) | |
| THG2-24 | 1381–1394 | A declared member that nothing defines errors at the type, where the promise was made. | emit a manifest entry with no definition → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-24.vox`) | |
| THG2-25 | 1396–1397 | A member is defined once; a second `To do the point's 'placed at'` errors at the second definition, naming the first. | emit two definitions of one member → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-25.vox`) | |
| THG2-26 | 1403–1404 | Free call — the function's own name, unchanged, in the global namespace. | call a thing-taking global function by its bare name, assert the result | yes | `gen call one` / `gen call two`, reached through `gen leaf call` (src/gen_core.vox:374, :387, :428) — the free-call **form** is exercised, but never with a thing argument, and the result is printed, not asserted | exercised (form only) | |
| THG2-27 | 1404 | `of`, `to`, `with` and `on` all introduce arguments. | emit each of the four spellings, assert each call's result | yes — all four must give the same answer, which the generator knows | **none for `to`, `with`, `on`** — every generated free call uses `of`, and every generated member call uses `with` (src/gen_things.vox:33). Three of the four spellings never appear | todo — real gap and an unjustified invariant; hand-verified all four work in both call forms (`THG2-27.vox`) | |
| THG2-28 | 1406–1420 | The free-call worked example compiles and prints 25. | reproduce it verbatim | yes | none (no generated function takes a thing) | todo — hand-verified (`THG2-28.vox`) | |
| THG2-29 | 1422–1423 | The instance possessive `receiver's 'member'` is sugar for `'member' of receiver`. | emit both spellings of the same call and assert they agree | yes — `If a{n} is not b{n} then, Exit 95.`, and the generator also knows the literal answer | `gen leaf thing member` emits the instance possessive on a **manifest member** (src/gen_things.vox:35); the `'member' of receiver` half is never emitted, so the equivalence is never tested | todo (the equivalence) — hand-verified (`THG2-29.vox`) | |
| THG2-30 | 1423–1424 | The receiver fills the function's first parameter; any further arguments follow the call preposition. | emit a receiver call with at least one extra argument, assert the result | yes | none — `gen leaf thing member`'s receiver call (`i{n}'s 'reflected across'`) takes **no** further arguments, so the extra-argument path is never taken | todo — real gap, hand-verified (`THG2-30.vox`) | |
| THG2-31 | 1424–1426 | A field always wins over a function of the same name — the collision rule refuses that program rather than letting one shadow the other. | emit a global function named after an existing field of its first parameter's type → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-31.vox`) | |
| THG2-32 | 1427–1428 | A receiver is anything that names a whole thing, so a field holding one reads the same way. | emit `i{n}'s g1's 'member'` — a receiver reached through a field — and assert the result | yes | none — `gen thing nested` chains a possessive to a **field** (`i{n}'s g1's x1`, src/gen_things.vox:62) but never to a **call**; t3's fields are t1/t2, neither of which has a manifest or a function taking it | todo — real gap, hand-verified (`THG2-32.vox`) | |
| THG2-33 | 1430–1460 | The instance-possessive worked example compiles and prints 25, 9, 144. | reproduce it verbatim | yes, composite of THG2-29/30/32 | none | todo — hand-verified (`THG2-33.vox`) | |
| THG2-34 | 1462–1463 | The type possessive `a <type>'s 'member'` calls a member declared in the manifest; the article is `a` because a new thing comes into being. | emit the type-possessive call, assert the new thing's fields | yes — the generator passes the arguments, so it knows the fields: `If i{n}'s x1 is not {x} then, Exit 95.` | `gen leaf thing member` (src/gen_things.vox:33, `a t4 called i{n} is a t4's 'made at' with {x}`); the next line prints `i{n}'s x1` but does not assert it | exercised — hand-verified, including that `the <type>'s` in the same position is refused (`THG2-34.vox`) | |
| THG2-35 | 1464–1465 | The type possessive is the only way to call a maker — a member whose first parameter is not the thing. | — | **no, from a runtime leaf** for the negative half (a free call to a member is a compile error) | `gen leaf thing member` calls the maker the only legal way | not assertable (compile-error claim) — hand-verified (`THG2-35.vox`): a member is not in the global function namespace at all, so the free call reports `Unknown function` | |
| THG2-36 | 1467–1481 | The type-possessive worked example compiles and prints 1. | reproduce it verbatim | yes | `gen leaf thing member` emits the same shape with different names | exercised — hand-verified (`THG2-36.vox`) | |
| THG2-37 | 1483–1502 | A maker cannot be reached by the instance possessive, and the message says so rather than reporting the member as missing. | emit `i{n}'s 'made at'` → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-37.vox`) | |
| THG2-38 | 1504–1531 | A member whose first parameter *is* the thing gets both the type possessive and the instance possessive. | call the same member both ways on the same value, assert the two results agree | yes | `gen leaf thing member` reaches `'reflected across'` (first parameter is a t4) by the **instance** possessive only (src/gen_things.vox:35); the type-possessive spelling of that same member is never emitted | todo (the second form) — hand-verified (`THG2-38.vox`) | |
| THG2-39 | 1533–1564 | A member name belongs to its owner: two things may each declare a `'placed at'`, and the two definitions compile under distinct internal names. | declare the same member name on two types, define both, call both, assert both results | yes | none — only `t4` has a manifest, so no member name is ever shared between two types | todo — real gap, hand-verified (`THG2-39.vox`) | |
| THG2-40 | 1566–1567 | `do` stays an ordinary identifier outside `To do the <type>'s`: `To do.` defines a function called `do`, and `do.` calls it. | — | yes | none | todo — hand-verified (covered by `THG2-16.vox`) | |
| THG2-41 | 1571–1572 | Type names, variable names and function names share a single global identifier namespace. | emit a program whose type, variable and function names are all distinct and all used | yes (trivially — the assertion is that it compiles and runs) | every generated program: types `t1`–`t4`, functions `f1`–`f4`, variables `c{n}`/`i{n}`, all in one namespace by construction | exercised — hand-verified (`THG2-41.vox`) | |
| THG2-42 | 1573–1583 | Reusing a name is first-come-first-served; the second definition errors at its own line, naming the first. | emit a name collision → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none — the generator's name counters make collisions impossible by construction | not assertable (compile-error claim) — hand-verified (`THG2-42.vox`) | |
| THG2-43 | 1585–1586 | The same error names a function, a parameter, a loop variable, an inferred variable, or another thing, whichever came first. | five collisions, one per prior kind → expect five compile errors | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — all five hand-verified; a **function** and **another thing** are named by their own kind, but a parameter, a loop variable and an inferred variable are all reported as "a variable". See Discrepancy 2 (`D2.vox`); probe `THG2-43.vox` records the function case | |
| THG2-44 | 1586–1588 | A thing's own fields and members live in a separate per-type member space (a type owns one), so `point's x` and `segment's x` do not collide. | declare two types sharing a field name, set and read both, assert both | yes | `gen emit prelude things`: t1 and t2 both declare `x1` and `x2`, and `gen thing flat` sets and prints them on whichever type it picked | exercised — hand-verified (`THG2-44.vox`); no leaf asserts the values | |
| THG2-45 | 1588–1603 | The member-space collision rule is first-come-first-served too: the second definition of any name in a type's member space — a field, a declared member, or a global function whose first parameter is that type — errors at its own line, pointing at the first. | emit each of the three collisions → expect three compile errors | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — all three hand-verified; `THG2-45.vox` records the field-versus-declared-member case, `THG2-31.vox` the field-versus-global-function case, and the declared-member-versus-global-function case was run by hand | |
| THG2-46 | 1605–1620 | A thing definition inside a **function body** is a compile error, and the message says to move it above the block. | emit a definition inside a function body → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none — `gen emit things block` always emits definitions at the top level | not assertable (compile-error claim) — hand-verified (`THG2-46.vox`) | |
| THG2-47 | 1605–1620 | The same rule inside an `If` and inside a loop. | emit a definition inside each → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — both hand-verified; `THG2-47.vox` records the `If` case and its header records the loop case | |
| THG2-48 | 1607–1609 | A thing's layout is fixed for the whole program and has no block scope. | — | **no** — the rationale for THG2-46/47, not a separately observable behaviour; Vox has no way to ask a type for its scope | n/a | not assertable | |
| THG2-49 | 1622–1625 | A thing defined in one file is usable from another via `see`; the definition is parsed into the program the way a function is. | emit a two-file program: a definition in an included file, instances in the includer | yes — assert the fields the includer sets | **none** — no generated program contains a `see` at all. `see` appears only in the generator's own source (`src/main.vox:24–37`) | todo — real gap, whole surface untouched. Hand-verified (`THG2-49.vox`) | |
| THG2-50 | 1625–1628 | The whole surface crosses the boundary: the type noun in a declaration, a field read and write, the manifest member reached by the type possessive, and a global function taking the thing reached by the instance possessive. | one two-file program exercising all four, asserting each result | yes | none | todo — hand-verified (covered by `THG2-49.vox`, which exercises all four) | |
| THG2-51 | 1629–1631 | The seen file arrives where the `see` is written, so the same defined-earlier rule that orders one file orders the pair. | emit a `see` written *below* a use of the included type → expect the compile error | **no, from a runtime leaf** (compile-error claim); the positive ordering is part of THG2-49 | none | not assertable (compile-error claim) — hand-verified (`THG2-51.vox`) | |
| THG2-52 | 1633–1667 | The cross-file worked example compiles and prints 11, 3, 4, 4. | reproduce it verbatim | yes | none | todo — hand-verified (covered by `THG2-49.vox`, which *is* the example) | |
| THG2-53 | 1669–1673 | A type name is one identifier across the whole compilation: defining the same thing in two files reached by `see` errors at the second definition, naming the other file. | emit a duplicate type across a `see` → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-53.vox`). The manual writes the filename relative; the compiler prints it absolute | |
| THG2-54 | 1675–1677 | A `see` of a file that cannot be read is now an error (it was previously silent without `-v`). | emit a `see` of a missing file → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-54.vox`) | |
| THG2-55 | 1682–1684 | A `.lib` interface file names types by noun, and no noun spells a user-defined thing, so an exported signature taking or returning a thing cannot be written. | — | **no** — the rationale for THG2-57; the observable consequence is the refusal | n/a | not assertable | |
| THG2-56 | 1684–1685, 1695–1696 | Ordinary compilation is unaffected: the same source compiles fine as an ordinary program, and the refusal fires only at the library interface. | compile a `Library`-declared source containing a thing-crossing function as an ordinary program, assert it runs | yes | none — the runner never passes `--shared` (`src/runner.vox`), and no generated program carries a `Library` declaration | todo — hand-verified (`THG2-56.vox`) | |
| THG2-57 | 1685–1693 | An exported library function whose signature mentions a thing is refused with `--shared`, naming both crossings and the rule "A thing is a layout private to one compilation". | build a thing-crossing library with `--shared` → expect the refusal | **no, from a runtime leaf** — and further out of reach than the other compile-error rows, because it needs a second compiler flag the harness never passes | none | not assertable (compile-error claim; needs `--shared`) — hand-verified (`shared/THG2-57.vox`); the refusal reproduces verbatim | |
| THG2-58 | 1697–1698 | The diagnostic names each crossing field and points at the workaround — pass `start's x` and `start's y` as separate values. | — | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (covered by `shared/THG2-57.vox`). Each **crossing** is named (the parameter by name, the return by position), but the workaround line is generic — "pass its fields across the boundary instead" — and does not spell the fields out as the manual's sentence suggests. The caret is also misplaced; see Discrepancy 5 | |
| THG2-59 | 1702–1705 | A thing definition's entries are comma-separated and the construct closes on a **period**. | emit a definition closed by a period, including the one-line form | yes (it compiles and the instance prints) | `gen emit prelude things` closes every definition with a period (src/gen_things.vox:107, :111, :115, :121) — but always multi-line, one entry per line | exercised (multi-line form); the one-line form is `todo` — hand-verified (`THG2-59.vox`) | |
| THG2-60 | 1704–1706 | A blank line force-closes the entry list, along with anything else still open. | emit a definition whose last entry has no period, closed by the blank line that follows | yes | none — every generated definition ends with a period *and* a blank line, so the blank line is never the thing that closes it | todo — hand-verified (`THG2-60.vox`) | |
| THG2-61 | 1706–1708 | Indenting the entries is conventional but not required — the commas and the terminator carry the structure. | emit an unindented definition | yes | none — `gen emit prelude things` indents every entry with exactly four spaces, every time | todo — an unjustified invariant as well as a gap. Hand-verified (`THG2-61.vox`) | |
| THG2-62 | 1712–1714 | The definition construct creates a family of sentences that are never valid Vox; each gets a targeted error stating the intent it recognises and naming the canonical form. | — | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified as the umbrella over THG2-63…THG2-68, all six of which do get a targeted, canonical-form-naming error. The related member-definition mis-spellings do **not** — `To do a point's …` gets the parser's generic "Expected a statement, got With" (`THG2-17.vox`) | |
| THG2-63 | 1716–1720 | `Create a thing called point.` → "A thing is defined, not created as a variable", naming the canonical form. | → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-63.vox`) | |
| THG2-64 | 1722–1726 | `A thing called point is 5.` → "'is' declares a variable; a thing definition uses 'has'". | → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-64.vox`) | |
| THG2-65 | 1728–1732 | `A thing called point has.` → "A thing needs at least one field". | → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-65.vox`) | |
| THG2-66 | 1734–1742 | A definition listing only manifest entries describes a zero-byte thing, so v1 requires at least one data field. | → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none — every generated type has at least one data field | not assertable (compile-error claim) — hand-verified (`THG2-66.vox`); the diagnostic adds the line "`a function called <name>` declares callable API, not storage" | |
| THG2-67 | 1744–1752 | A field default must be a literal of the field's own type; a computed value belongs in a function that returns the thing. | → expect the compile error for each mismatch | **no, from a runtime leaf** (compile-error claim). The positive half — a matching default, including the documented whole-number-for-a-float case — is assertable | `gen emit prelude things` gives every field `is 0`, a number literal on a number field; no other pairing is ever emitted | not assertable (compile-error claim) — hand-verified (`THG2-67.vox`), including `a float called weight is 2.` compiling to `{weight: 2.0}`. The check misfires on an unsupported field type; see Discrepancy 4 | |
| THG2-68 | 1754–1767 | Declaring with an unknown type name keeps the unknown-type error, extended to suggest near-miss **user-defined** type names alongside the builtins. | → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-68.vox`); the user-defined `point` appears both in the "Known here" list and in the `did you mean` suggestion | |
| THG2-69 | 1771 | User-defined things are not in the runtime tag system in v1. | — | umbrella over THG2-70…THG2-72 | none | not assertable separately — hand-verified through THG2-71/THG2-72 | |
| THG2-70 | 1772–1773 | The type nouns `is a <type>` recognises are the builtins: `number`, `text`, `decimal`, `boolean`, `list`, `map`. | emit a `value`-parameter dispatch over all six nouns, assert the arm that fires | yes — the generator chose the argument, so it knows the arm | none — no generated program contains an `is a <type>` predicate at all. (`it is a text` in `gen emit prelude flags`, src/gen_misc.vox:351, is flag-schema syntax, a different construct) | todo — real gap; the whole predicate surface is untouched by any leaf. Hand-verified (`THG2-70.vox`) | |
| THG2-71 | 1773 | There is no `is a point` — a user thing cannot be asked for its runtime type. | emit `If i{n} is a t1` → expect the compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`THG2-71.vox`); the diagnostic enumerates exactly the six nouns THG2-70 lists | |
| THG2-72 | 1773–1775 | A `list` or `map` of user things, or a `value` holding one, is likewise deferred. | emit `[i{n}]`, a map with a thing value, and `a value called v is i{n}` → expect three compile errors | **no, from a runtime leaf** (compile-error claim) | none — no generated program puts a thing in a collection or a value | not assertable (compile-error claim) — all three hand-verified; `THG2-72.vox` records the list case, and its header records the other two, which give the identical diagnostic | |
| THG2-73 | 1775 | Things live in the compile-time type table, not the runtime tag. | — | **no** — a restatement of THG2-69 in implementation terms; no observable behaviour of its own | n/a | not assertable | |
| THG2-74 | 1782–1786 | Design note: members-only definitions are rejected; conservative and reversible. | — | — | — | folded into THG2-66 | |
| THG2-75 | 1789–1794 | Design note: `.lib` export of a thing is refused; ordinary compilation unaffected. | — | — | — | folded into THG2-56 and THG2-57 | |
| THG2-76 | 1797–1802 | Design note: the `origin` naming question — the tests and STYLE.md declare `a point called origin` and then set it to (3,4), which is arguably untruthful. | — | **no** — a question about this repo's own style guide, not a claim about the language; nothing a Vox program can observe | n/a | not assertable (not a language claim) | |
| THG2-77 | 1805–1811 | Things are acyclic by two mechanisms: the within-file defined-earlier ordering rule (a field type must be defined above the line), and the analyzer's registry DFS across files reached by `see`. | emit a field naming a thing defined below, a direct self-reference, and a cross-file cycle → expect three compile errors | **no, from a runtime leaf** (compile-error claim). *Which* mechanism caught a cycle is not observable at all — see below | `gen emit prelude things` always defines t1 and t2 above t3, which is the ordering rule obeyed rather than tested | not assertable (compile-error claim) — hand-verified (`THG2-77.vox`). All three shapes are refused, but a mutual-`see` cycle is refused by the **ordering** rule ("Unknown field type 'ring' in thing 'wheel'"), so I could not construct a program in which the DFS is demonstrably the mechanism that fires. The manual's "the DFS is load-bearing, not redundant" is a claim about compiler internals and has no probe | |

## Discrepancies

Each has a runnable minimal repro in `docs/ledger/probes/things-b/`.
Recorded, not filed, not adjudicated.

### 1. A single-word field name written in quotes prints without them

LANGUAGE.md:1200: "A quoted field name prints in the quotes it is written
with." Repro (`D1.vox`):

```
A thing called stamp has
  a number called 'day sent' is 25,
  a number called 'depth' is 2,
  a number called 'altitude' is 1.

a stamp called posted.
Print posted.
```

Output:
```
{'day sent': 25, depth: 2, altitude: 1}
```

All three names are written in quotes; only the multi-word one comes back
quoted. The rule the compiler actually follows is "quote a name that
*needs* quoting", not "print the quotes it was written with".

**The reading in which the compiler is right:** Vox treats `'depth'` and
`depth` as the same identifier — quoting is a lexical device for names
that could not otherwise be one token, and what the compiler stores is
the canonical name, not its spelling. Printing then re-quotes only where
re-reading the output would need it, which keeps the rendering
round-trippable and minimal. Under that reading the manual's sentence is
loose shorthand for the common case (a multi-word name), and the precise
statement would be "a field name that requires quotes prints in quotes".
That is a one-line manual fix, not a compiler change. Nothing here is
unsafe; it matters because a leaf that asserted the manual's literal
wording would be a false-finding factory.

### 2. The identifier-space error calls a parameter, a loop variable and an inferred variable all "a variable"

LANGUAGE.md:1585–1586: "The same error names a function, a parameter, a
loop variable, an inferred variable, or another thing, whichever came
first." Repro (`D2.vox`) with a parameter first:

```
To measure with a number called point. Print point.

A thing called point has
  a number called x is 0.
```

Output:
```
error: 'point' is already defined as a variable on line 1
```

The five kinds were each run by hand. A prior **function** gives "already
defined as a function"; a prior **thing** gives "already defined as a
thing"; a **parameter**, a **loop variable** and an **inferred variable**
all give "already defined as a variable".

**The reading in which the compiler is right:** the sentence's list is of
the *prior definitions the rule catches*, not of the labels the message
prints; and "variable" is truthful for all three of the collapsed kinds —
a parameter, a loop variable and an inferred variable are all variables.
The message still names the kind at the granularity the identifier table
records and still gives the line, which is the part a reader needs.
Under that reading the manual is describing coverage, not wording. The
cost of leaving it is small but real: someone reading the manual expects
"already defined as a parameter" and will hunt for a bug that is not
there.

### 3. The whole-thing comparison diagnostics point their caret at the declaration, not at the comparison

Repro (`D3.vox`) — the offending line is 11, the caret lands on line 9:

```
a point called origin.        (line 9)
a point called marker.        (line 10)
If origin is greater than marker then,   (line 11)
    Print "further along".
```

Output:
```
error: 'origin' holds a whole point, which nothing puts in order
  ...
  --> D3.vox:9:16
   9 | a point called origin.
     |                ^--- here
```

The same misplacement appears on the different-types comparison
(`THG2-12.vox`) and on the free-call-to-a-member error
(`THG2-35.vox`, whose caret lands on the manifest entry rather than the
call).

**The reading in which the compiler is right:** the message is *about*
`origin` — what it holds — and the declaration is where `origin` acquired
that property, so pointing there answers "why is this a whole point?".
The sibling owner-return diagnostic (LANGUAGE.md:1337–1340) deliberately
names two lines for the same reason, and does so correctly. Under that
reading this is a considered choice rather than a bug, and the fix would
be to name *both* lines here too — the declaration and the use — as the
owner-return message already does. Nothing in the manual pins the caret
for these two messages, so this is a diagnostic-quality question, not a
contradiction.

### 4. A field type the language does not support yet is also reported as a default-type mismatch against itself

LANGUAGE.md:1744–1752 documents the default-must-match-the-field-type
check. Repro (`D4.vox`):

```
A thing called stamp has
  a text called label is "post".
```

Output:
```
error: Field 'label' of thing 'stamp' is a text, but its default is a text
  A field's default must be a literal of the field's own type; ...

error: Field 'label' of thing 'stamp' is a text, which a thing cannot hold yet
  ...text is deferred until copying a text handle is verified not to observe mutation...
```

The first message names the same type twice and says they do not match.
The second message is the real one.

**The reading in which the compiler is right:** the default-literal check
knows only the field types a thing can actually hold (number, float,
boolean, time, another thing) and has no accepted-literal set for `text`,
so every literal is a mismatch there. The program is refused either way,
and it is refused for a correct reason by the second error — the first is
redundant noise on an already-invalid program, not a wrong verdict. The
fix is ordering: reject the unsupported field type first and skip the
default check for it. Worth noting because the self-contradicting
sentence is the kind of thing that sends a reader looking for a bug in
their own program.

### 5. The `--shared` thing-crossing diagnostics locate their caret by searching the source text for the function's name — RESOLVED

**Resolution confirmed, 2026-08-22 — fixed, uncredited (no BUGS_FOUND
entry found for it).** Re-built `shared/D5.vox` with `--shared` against
vox 0.4.9: **both** errors now point at line 24 (the actual definition),
not at the comment on line 19. The messages also changed shape — they
now name the function and the parameter/field involved (`Exported
function 'nudged east' takes a point ('start')...` /
`... returns a point, ...`) instead of the generic wording quoted below.
The account that follows is the finding as it stood against 0.4.8; the
probe has been re-recorded to the fixed behaviour.

Repro (`shared/D5.vox`), built with `--shared`:

```
Library geometrykit version "1.0".

(A comment that mentions 'nudged east'.)      (line 19 of the probe)

A thing called point has
  a number called x is 0.

To 'nudged east' with a point called start.   (line 24 of the probe)
  Return a point, start.
```

Output: the **parameter**-crossing error points at line 19, inside the
comment; the **return**-crossing error points at line 24, the definition.
Remove the comment and both point at the definition. Two mentions before
the definition move both carets into the comment — which is how this was
found, in the first draft of `shared/THG2-57.vox`, whose header quoted
the diagnostics it was recording.

So each of the two errors takes a successive textual occurrence of the
function's name rather than the definition's own span, and a mention
inside a comment counts.

**The reading in which the compiler is right:** the `--shared` interface
check runs after the AST is lowered, on a signature summary that carries
names but not spans, and the location is recovered by lookup rather than
carried. That is a legitimate implementation shortcut everywhere the name
appears exactly once, which is the normal case. Nothing in the manual
promises a span for these two messages — the manual quotes their text
only (LANGUAGE.md:1691–1693), and the text is exactly right. The
consequence is confined to files that mention the exported function's
name in prose above its definition, which is exactly what a documented
library does.

## Invariants this section justifies

- a thing's fields always print in definition order, and always the same
  order for a given type — LANGUAGE.md:1197, THG2-01
- a thing always prints as `{name: value, ...}`, braces and `, `
  separators — LANGUAGE.md:1197, THG2-01
- a field name containing a space always prints inside single quotes —
  LANGUAGE.md:1200, THG2-03 (a single-word name never does — see
  Discrepancy 1)
- a function member never appears in a thing's printed output, in a copy,
  or in a comparison — LANGUAGE.md:1201, 1334–1335, THG2-04, THG2-19
- two things of different types are never compared, and no whole thing is
  ever ordered — LANGUAGE.md:1286–1289, THG2-12, THG2-13
- a member definition always reads `To do the <type>'s <name>` — always
  the definite article — LANGUAGE.md:1311–1312, THG2-17
- a type-possessive call always reads `a <type>'s <name>` — always the
  indefinite article — LANGUAGE.md:1462–1463, THG2-34
- every `To do` member body ends in `Return a <its own type>,` —
  LANGUAGE.md:1337–1340, THG2-20
- every manifest entry has exactly one `To do` definition, and every
  `To do` has a manifest entry — LANGUAGE.md:1365–1397, THG2-23, THG2-24,
  THG2-25
- a member is never reached by a bare free call — LANGUAGE.md:1462–1465,
  THG2-35
- every name in a program is unique across types, variables and functions
  — LANGUAGE.md:1571–1575, THG2-41, THG2-42
- no name occurs twice in one type's member space —
  LANGUAGE.md:1588–1592, THG2-45
- every thing definition sits at the top level, never inside a block —
  LANGUAGE.md:1607–1610, THG2-46, THG2-47
- a thing is always defined above every use of it, including the
  definitions of things that hold it — LANGUAGE.md:1629–1631, 1805–1809,
  THG2-51, THG2-77
- a thing definition's entries are always comma-separated, and the list
  always ends with a period or a blank line — LANGUAGE.md:1702–1706,
  THG2-59, THG2-60
- every thing definition has at least one data field —
  LANGUAGE.md:1734–1735, THG2-66
- every field default is a literal of the field's own type —
  LANGUAGE.md:1744–1745, THG2-67
- no generated program contains `is a <user thing>` —
  LANGUAGE.md:1772–1773, THG2-71
- no generated program puts a thing in a list, a map or a value —
  LANGUAGE.md:1773–1775, THG2-72
- no `--shared` build exports a function taking or returning a thing —
  LANGUAGE.md:1682–1692, THG2-57

Note that **indentation of a definition's entries is not on this list**.
LANGUAGE.md:1706–1708 says outright that indenting is conventional and
not required, so the generator's uniform four spaces (`gen emit prelude
things`) is an unjustified invariant, not a justified one.

## Report

**77 rows** (THG2-01 through THG2-77). Two of them (THG2-74, THG2-75) are
design notes folded into a sibling row rather than fresh leaf needs,
leaving **75 distinct claims**.

**Assertable from a runtime leaf: 33, plus 2 partly.** That is low, for
two reasons worth stating plainly.

**First, this is mostly a diagnostics section.** 31 of its rows are claims
about what the compiler *refuses*, and the generator's standing contract
is legal Vox that should compile and run, so a leaf cannot put them on
trial without breaking that contract. They are marked `not assertable
(compile-error claim)` after the convention `values.md` set, and **every
one was still hand-verified and has a retained probe** — 32 recorded
refusals across 62 probe files, all reproducing exactly.

**Second, and this was the surprise: the whole Printing subsection is
unassertable from inside a Vox program.** A whole thing's rendering can
only reach `Print`. It cannot be captured — `a text called t is
"{origin}"` is refused (THG2-07), and so is `copy "{origin}" to buf`,
with the same diagnostic — so there is no value to compare an expectation
against. A leaf can assert a thing's fields one at a time, but the
*order*, the braces, the recursion and the quoting of field names
(THG2-01, THG2-03, THG2-04, THG2-06) are checkable only by the harness
diffing stdout. This is a different shape of gap from "no leaf asserts
yet", and the leaf worker should not be sent to write assertions that
cannot exist. It also means Discrepancy 1 can never be caught by a leaf,
only by a probe like the one filed here.

By status: **11 exercised, 0 verified, 28 todo, 36 not assertable, 2
folded.** THG2-17 is counted as exercised for its positive half and also
carries a compile-error half, which is why the refusal count (31 rows) and
the not-assertable count (36 rows) overlap by one.

**Existing coverage: 11 rows exercised, 0 verified.** `src/gen_things.vox`
is the entire things surface, and it is a good deal narrower than it
looks. What it does emit: whole-thing printing (flat and nested), field
read and write, chained possessives, value-copy, a two-entry manifest on
`t4`, the type-possessive maker call and the instance-possessive receiver
call. What it never emits, in this section:

- **No generated function anywhere takes a thing** (`f1`–`f4` take
  numbers and a text). That single fact makes THG2-21, THG2-26 with a
  thing argument, THG2-28, THG2-29, THG2-30, THG2-32 and THG2-33 all
  unreachable — the free call and the instance possessive on an
  *ordinary* function are simply not in the corpus. This is the biggest
  finding in the section and the cheapest to fix: one `To 'nudged east'
  with a t1 called start.` in the prelude opens seven rows.
- **No thing is ever compared.** `is` appears between two instances only
  as a copy. THG2-08/09/10/11 are untouched.
- **No whole thing is ever interpolated** into a format string; the
  format leaves interpolate a *field*. THG2-06.
- **`t4` — the only type with a manifest — is never printed whole, never
  copied and never compared**, so THG2-04 and THG2-19 (a member takes no
  part in printing, copy or equality) are never actually put on trial,
  even though both halves exist separately.
- **No generated program contains a `see`**, so the entire cross-file
  surface (THG2-49 through THG2-54) is untouched, and the harness never
  passes `--shared`, so THG2-56/57 are out of reach of the current
  campaign shape as well.
- **No generated program contains an `is a <type>` predicate.** THG2-70's
  whole surface is untouched by any leaf. (`it is a text` in the flag
  schema is different syntax.)

**Unjustified invariants this section's leaves contribute** — none of
these has a citation, and each is a rule nobody declared:

1. every free call uses the preposition `of`; `to`, `with` and `on` never
   appear in a call (LANGUAGE.md:1404 says all four introduce arguments)
2. every member call passes its arguments with `with`, and the receiver
   call passes none at all (LANGUAGE.md:1423–1424 permits further
   arguments after any of the four prepositions)
3. exactly one type per program has a manifest, and it always has exactly
   two entries, always in the same order
4. every thing definition indents its entries by exactly four spaces
   (LANGUAGE.md:1706–1708 says indentation is not required)
5. every thing definition closes with a period *and* a blank line, so the
   blank-line-force-close path is never taken
6. every thing definition is multi-line, one entry per line; the one-line
   form never appears
7. every field default is `is 0` — a number literal on a number field —
   so no other legal field type or default is ever emitted
8. no member name is ever shared between two types (THG2-39)

**Historical note (0.4.8, superseded).** This section used to flag that
`INDEX.md` pinned an older manual than this ledger, and that four probes
elsewhere (`buffers/`, `values/`) needed re-running after 0.4.8 fixed two
open discrepancies. **Both are now done** — the whole ledger set was
re-pinned to 0.4.9 in this pass (2026-08-22), buffers' and values'
discrepancies were re-verified directly, and this ledger's own
Discrepancy 5 turned out to have been fixed too (see above), found only
because the retained probes were re-run rather than trusted.

**Advice for the next mapper.** Three things cost me time and would cost
you the same:

- **Budget for a diagnostics section.** A third of this range is compile
  errors. They are still rows, they are still hand-verified, and they
  still get probes — but `docs/check-probes.sh` only matches the *first*
  line of a recorded compile error, so put the exact `error: …` line
  first and prose after it. Keep the parentheses in your probe header
  balanced: Vox comments nest, and an unbalanced `)` in a recorded
  diagnostic ends the comment early.
- **Do not quote the diagnostic you are recording if it names an
  identifier.** Discrepancy 5 was found by accident when a probe header
  that quoted an error message moved the caret that the same probe was
  recording. Assume any diagnostic may be located by name lookup and keep
  the header free of the names it discusses.
- **Grep for the construct, not the concept.** "Things are covered" is
  true and useless. `grep -n "is i{"` is what showed that `is` between
  two instances is only ever a copy, never a comparison; `grep -n "with a
  t1 called"` is what showed that no generated function takes a thing at
  all. Both are one-line greps that overturn a paragraph of assumption.
