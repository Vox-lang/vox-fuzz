# Claim ledger: Things (part A) — defining, declarations and field access, nesting, value copy semantics

Source: `../vox/LANGUAGE.md` lines **814–1194**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual): `## Things` intro, `### Defining a
thing`, `#### The article rule`, `### Declarations and field access`,
`### Nesting`, `### Value copy semantics`. Line 1195 opens `### Printing`,
which belongs to the Things part B ledger, so the range is exactly the
section boundary. No manual-text or compiler-behaviour changes found in
this range between 0.4.8 and 0.4.9 — every re-pin below is a pure line
shift; none of the five discrepancies has a "Resolution: fixed" update
because none needed one.

Compiler used for every probe: `vox v0.4.8`, re-verified against `vox
v0.4.9` on 2026-08-22
(`/home/josj/scr/english/vox/target/release/vox`), `VOX_CORE_PATH` pinned to
the sibling `coreasm`.

This is a **gap analysis**, not a from-scratch map. `src/gen_things.vox`
already carries five thing leaves and `src/gen_text.vox` reads a thing
field through two format-string leaves. The `existing leaf` column names
what already emits the construct, or `none`, and was filled by grepping
the accessor (`'s x1`, `A thing called`, `"Create a t`, `"increment`,
`"The `) across every `src/*.vox`, never by leaf name.

**No existing thing leaf asserts anything.** Every one prints a value for
a human to eyeball. That is the same uniform gap the buffers ledger found,
and it is confirmed here for a second surface: nothing in this document is
`verified`. The `assertable?` column is therefore the most useful column
in the table — this section is unusually rich in assertable claims,
because the generator picks every field value it writes.

## Probes

Every hand-verified row's probe is retained and runnable in
`docs/ledger/probes/things-a/`, named `THG-NN.vox` for the lowest row it
covers; a probe covering several rows says so in its own header (`Also
covers: ...`). Each opens with a `(...)` comment naming the claim, the
exact `Ran:` command, and an `expected output:` block recording what the
compiler **actually** printed. Compile-error probes record the diagnostic;
their block opens `error: ` and closes `(no binary produced; compile
error)`, which is the form `docs/check-probes.sh` recognises.

`THG-51.vox` reads two fixtures in `probes/things-a/fixtures/`. `see`
resolves against the directory of the file that writes it, so that probe
must be compiled where it sits.

**39 probe files for the 39 hand-verified rows, plus D1–D5, for 44 files.**
All 44 re-run against vox 0.4.9 on 2026-08-22 with
`docs/check-probes.sh docs/ledger/probes/things-a`: **44 passed, 0
failed, 0 skipped.**

Rows with no probe file: THG-02, THG-40, THG-43, THG-44, THG-53 (not
assertable — nothing to run), THG-07/08, THG-12/15, THG-19/20/21/22/23,
THG-25/26, THG-28/29/30/31/32, THG-35, THG-38, THG-47, THG-50, THG-54,
THG-57, THG-59/60/61/62/63, THG-65, THG-67, THG-73 (covered by a sibling
row's probe, named in that probe's `Also covers:` line), and THG-36
(folded into THG-12).

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| THG-01 | 876–882 | A thing is a user-defined composite value type built from named fields; `'s` reads one, and two instances of a type keep their own bytes. | declare two instances of one thing, write a different field in each, read all four fields back | yes — the generator picks both values, so it can emit `If origin's x is not 3 then, Exit 95.` for each | `gen thing flat`, `gen thing nested`, `gen leaf thing copy`, `gen leaf thing member` (all declare + `'s`-read); `gen format types`/`gen format all` in `gen_text.vox` read `zi{n}'s x1`/`hi{n}'s x1` | exercised (construct only — every leaf `Print`s, none asserts) | |
| THG-02 | 879–882 | No vtables, no dispatch, no runtime component: a thing is a layout with every offset fixed at compile time. | — | **no** — an implementation claim; Vox exposes no way to observe dispatch, offsets or code size from inside a program | n/a | not assertable | |
| THG-03 | 884 | A thing is defined once, at the **top level**; a definition inside a function body is refused. | emit a definition inside a `To` body | **no** — a compile-error claim: emitting it produces a non-compiling program, outside the generator's "legal Vox that should compile and run" contract | none (the prelude emits all definitions at top level, which is correct by construction — LANGUAGE.md:884, and one of this section's justified invariants) | not assertable (compile-error claim); hand-verified, probe `THG-03.vox` | |
| THG-04 | 884–886 | A thing's name works everywhere a builtin type keyword works: in declarations, in parameters, and in return types. | a plain global function with a thing parameter and a thing return type, called and read back | yes — the generator chooses the field value the function adds to | **partial**: `gen emit prelude thing methods` emits `To do the t4's 'reflected across', with a t4 called original.` and `Return a t4, mirrored.`, so parameter and return positions exist — but only inside a **manifest member**. No generated program ever writes a *plain* `To <name> with a <thing> called ...`, which is a different parse path (no owner type, no owner-return rule). | todo (plain-function parameter/return); exercised (manifest form) | |
| THG-05 | 886–888 | A definition declares a type — it allocates nothing and emits no code, so the only output around it comes from the ordinary statements. | two definitions and one `Print`; assert exactly one line comes out | yes — count of output lines is known at generation time, though asserting it needs the runner, not an in-program check | every generated program (the prelude emits definitions and they contribute no output) | exercised | |
| THG-06 | 890–893 | `examples/delivery.vox` is a complete program built from two things of its own: it declares them, makes one with a manifest member, nests one inside the other, copies, prints and compares them. | reproduce the composite | yes (as a whole) — but it is the manual's cited example, not a generator shape | none — no leaf composes declare + maker + nest + copy + print + compare in one program | todo (composite); hand-verified verbatim, probe `THG-06.vox` | |
| THG-07 | 897–903 | The minimal definition example compiles and prints `defined`. | — | yes | none emits this exact shape, but the parts are covered by THG-01 | exercised (parts); composite hand-verified in `THG-05.vox` | |
| THG-08 | 905 | The keyword is `thing` and the verb is `has`. | — | yes (any definition puts both on trial) | `gen emit prelude things` (four definitions, all `A thing called tN has`) | exercised | |
| THG-09 | 908–909 | A data field is `a <type> called <name>`, with an optional `is <literal>` default. | emit fields both with and without a default, of each legal type | yes — the generator writes the literal, so it knows the value | `gen emit prelude things` — but **every** field it emits is `a number called xN is 0` or a thing field. The no-default form never appears; nor does any non-zero literal default. | todo (the no-default form, and any default other than `0`) | |
| THG-10 | 908–909 | A field default must be a **literal** — anything computed is refused. | emit `is 2 add 3` as a default | **no** — compile-error claim | none | not assertable (compile-error claim); hand-verified, probe `THG-10.vox` | |
| THG-11 | 910–911 | A definition's second kind of entry is a function member — `a function called <name>`, the manifest. | a definition carrying a function member, and the member defined and called | yes (the maker's result is generator-chosen) | `gen emit prelude things` (t4 carries `'made at'` and `'reflected across'`), driven by `gen leaf thing member` | exercised | |
| THG-12 | 913, 1000–1001 | A field without a default takes its type's **zero** value (number `0`, float `0.0`, boolean `0`, time `0`). | declare a thing with an undefaulted field of each type and read it back before any write | yes — zero is known; `If sample's 'never set' is not 0 then, Exit 95.` | none — every generated field carries `is 0`, so "no default" is never on trial | todo | |
| THG-13 | 913–916 | `thing` is a keyword only inside the definition construct; elsewhere it is an ordinary identifier, so a variable may be called `thing`. | declare `a number called thing is N.` in a program that also defines a thing, and print it | yes — the generator chose N | none — no generated program ever names a variable `thing` | todo (a cheap, high-value row: it is a parser-state claim) | |
| THG-14 | 926–927 | A thing name may be a bare word or a **quoted multi-word** name, the same forms any identifier takes. | define and declare a `'bounding box'`-style type | yes | none — the prelude's four types are `t1`–`t4`, bare words every time. The quoted-type-name path is never taken by any generated program. | todo — real gap, and an unjustified invariant today (see below) | |
| THG-15 | 938–940 | A field may be `number`, `float`, `boolean`, `time`, or any **previously defined** thing. | fields of all four builtin types plus a thing field, read back | yes for all five (defaults and writes are generator-chosen) | `number` and thing fields only (`gen emit prelude things`: `a number called x1`, `a t1 called g1`). **No generated thing has ever had a `float`, `boolean` or `time` field.** | todo (float, boolean, time); exercised (number, nested thing) | |
| THG-16 | 939 | "Previously defined": a field naming a thing defined **below** the line is refused. | emit a definition referencing a later one | **no** — compile-error claim | none (the prelude emits t1/t2 before t3, correct by construction) | not assertable (compile-error claim); hand-verified, probe `THG-16.vox` | |
| THG-17 | 940–942 | `text`, `list`, `map` and `buffer` fields are **deferred** — a thing cannot hold one. | emit such a field | **no** — compile-error claim | none | not assertable (compile-error claim); hand-verified for all four **plus `file`, `timer` and `value`**, which the compiler rejects with the same diagnostic though the manual does not name them. Probe `THG-17.vox`. | |
| THG-18 | 946–948 | `a`/`an` pairs with types and with values coming into being; `the` pairs with known identifiers. | emit both articles in both positions | yes | `a t1 called i{n}` is always `a`; `an` before a vowel-initial thing name never appears (no type name starts with a vowel) | todo (the `an` form) | |
| THG-19 | 950 | `A thing called point has ...` — a *type* comes into being, so `A`. | — | yes | `gen emit prelude things` | exercised | |
| THG-20 | 951 | `a point called origin.` — a value of that type comes into being, so `a`. | — | yes | `gen thing flat`/`nested`/`copy`/`member`, `gen_text.vox` leaves | exercised | |
| THG-21 | 952–954 | `the point's 'placed at'` in a member definition (`To do the point's 'placed at'`) — `point` is a known identifier, so `the`. | — | yes | `gen emit prelude thing methods` (`To do the t4's 'made at'`) | exercised (the manifest itself is mapped by the Things part B ledger; this row exists because the *article* claim is made here) | |
| THG-22 | 955–956 | `a point's 'placed at' with 1 and 0` — a *new point* comes into being from the maker, so `a`. | — | yes — the maker's argument is generator-chosen, so the returned field is predictable | `gen leaf thing member` (`a t4's 'made at' with {'starting x'}`) | exercised | |
| THG-23 | 958–959 | The same word under two articles means two things: `the point's` reads a known member, `a point's` calls a maker that brings a new point into being. | both forms in one program, distinguished by their results | yes | `gen leaf thing member` emits both the type-possessive maker and the instance-possessive receiver, but never asserts which came from which | exercised (construct); todo (verification) | |
| THG-24 | 963–964 | A thing name is a type noun everywhere the builtin ones are, so **every declaration form works**: `a T called N.`, `Create a T called N.`, and `Set a T called N to <a whole T>.` | one declaration of each of the three forms | yes | only the bare `a T called N.` form is ever emitted. `Create a t...` appears nowhere in `src/`; `Set a t... to ...` appears nowhere. | todo (two of three forms) — and an unjustified invariant today | |
| THG-25 | 964–965 | Every declaration form gives every field its **declared default**. | declare via each form, assert each field equals its declared default | yes — the defaults are written by the generator | none asserts a default; `gen thing flat` writes `x1` immediately and never reads the untouched `x2` | todo | see **Discrepancy 4** |
| THG-26 | 972 | `a point called origin.` declares an instance. | — | yes | `gen thing flat`, `gen thing nested`, `gen leaf thing copy` | exercised | |
| THG-27 | 973 | `Set origin's x to 3.` writes a field. | — | yes | `gen thing flat` (`Set i{n}'s x1 to {val}`), `gen thing nested`, `gen leaf thing copy`, both `gen_text.vox` leaves | exercised (construct); todo (nothing reads the value back and asserts it) | |
| THG-28 | 975 | `Print origin's x.` reads a field. | — | yes | `gen thing nested` (`Print i{n}'s g1's x1`), `gen leaf thing copy`, `gen leaf thing member` | exercised | |
| THG-29 | 976 | `origin's y is origin's y add 1.` — **bare assignment** to a field, with the field on both sides. | emit the bare-`is` form with a field as its target | yes — old value plus one is known | **none.** Every generated field write is `Set X's f to V`. The bare-`is` lvalue path is never taken. | todo — real gap | |
| THG-30 | 977 | `increment origin's x.` steps a field. | emit `increment` on a field | yes | **none.** `"increment` appears nowhere in `src/*.vox` as generated text. | todo — real gap | |
| THG-31 | 978 | A field interpolates into a format string (`"origin sits at {origin's x}, {origin's y}"`). | — | yes — the generator knows the whole rendered line | `gen format types` (`Print "{zi{n}'s x1:0Nx}"`, always with a specifier) and `gen format all`, whose field slot goes through `gen format slot` with `gen pick integer spec` — which returns `""` one draw in eight, so the **bare** `{hi{n}'s x1}` slot is reached too, just rarely | exercised (both the bare and the specifier form) | |
| THG-32 | 979–980 | A field works as an operand in a comparison in a condition. | emit `If X's f is greater than N then, ...` | yes — both operands are generator-chosen | **none.** `gen condition` builds both operands from `gen var ref`, which only ever returns `v{n}` — a plain number variable. No thing field ever reaches a condition, or any general expression. | todo — real gap | |
| THG-33 | 983–986 | A field is an ordinary expression and an ordinary lvalue **everywhere either is allowed** — the prose names read, `Set ... to`, bare assignment, increment, **decrement**, format interpolation and comparison. `decrement` is named in the prose and shown in no example. | emit `decrement` on a field | yes | none | todo — hand-verified to work, probe `THG-33.vox` | |
| THG-34 | 986 | `Create` declares a thing with its declared defaults too. | emit the `Create a T called N.` form | yes | none — see THG-24 | todo | |
| THG-35 | 987 | A **quoted variable name** is read and written through the same possessive (`'the far corner''s x`). | declare a thing with a quoted instance name and read/write a field through it | yes | none — every generated instance is `i{n}`/`zi{n}`/`hi{n}`, a bare word. The doubled-quote possessive (`'name''s field`) is never emitted, and it is the one spelling most likely to break a lexer. | todo — real gap, high value | |
| THG-36 | 1000–1001 | *(restatement of THG-12)* A field with no default takes its type's zero. | — | — | — | folded into THG-12 | |
| THG-37 | 1000–1001 | A `float` field and a `boolean` field carry defaults; a `number` field with none is `0`. | a thing with a defaulted float, a defaulted boolean and an undefaulted number | yes — all three values are generator-chosen | none (see THG-15: no generated thing has a float or boolean field) | todo | |
| THG-38 | 1003–1014 | The water-tank example compiles and prints `1.5`, `the pump is running`, `0`. | reproduce | yes | none | todo (composite); hand-verified verbatim in `THG-37.vox` | |
| THG-39 | 1016–1017 | A thing declared inside a function is **local to that function** — the name is not in scope at the top level after the call returns. | declare a thing inside a `To` body and use it only there | the positive half is assertable (write and read the local, assert the value); the negative half (the name is not visible outside) is a compile-error claim and so **not** assertable | **none.** No generated function body declares a thing: `f1`–`f4` (`gen_core.vox`), the grid sinks (`gen_flow.vox`) and `'read flags {n}'` (`gen_misc.vox`) declare only numbers and texts. | todo — real gap; hand-verified, probe `THG-39.vox` | |
| THG-40 | 1017 | A function-local thing's storage is the stack, not `.bss`. | — | **no** — an implementation claim; no Vox construct reports where a variable lives | n/a | not assertable | |
| THG-41 | 1019–1031 | The `'plot a point'` example compiles and prints `the cursor sits at 9, 1`. | reproduce | yes | none | todo (composite); hand-verified verbatim, probe `THG-41.vox` | |
| THG-42 | 1035 | A field may be a thing, so things nest to **any depth**. | nest well past the two levels the manual shows, and read the innermost field through the full chain | yes | `gen emit prelude things` defines exactly one nesting level (t3 holds t1 and t2); `gen thing nested` reads `i{n}'s g1's x1`, a **two**-link chain. Nothing deeper is ever defined or read. | todo (depth > 2); exercised (depth 2). Hand-verified to depth 20, probe `THG-42.vox`. | |
| THG-43 | 1035–1038 | A nested thing contributes its own bytes inline, so a chained possessive is one sum of compile-time offsets, never a pointer chase. | — | **no** — an implementation claim; indistinguishable from a pointer chase at the language level | n/a | not assertable | |
| THG-44 | 1037–1038 | The route's own `'route number'` sits **after** the whole nested segment in the layout. | — | **no** from this section — field order is only observable through `Print`, which the Things part B ledger maps (`Print` walks fields in definition order); nothing in this section exposes byte offsets | n/a | not assertable here — cross-refers to the Printing section | |
| THG-45 | 1053–1059 | The route example: a chained possessive three deep, read and written, `increment` on a chained possessive, and a quoted field name on the outer thing. | reproduce | yes | `gen thing nested` covers the two-deep read/write only. The three-deep chain, `increment` on a chain, and a quoted field name are all absent. | todo; hand-verified verbatim, probe `THG-45.vox` | |
| THG-46 | 1061–1064 | Defaults apply **recursively**: a field whose type is a thing takes that thing's own defaults, written into the nested bytes at declaration. | declare a thing with a nested thing field and read the nested defaults before writing anything | yes — the generator wrote the defaults | none — `t3`'s fields `g1`/`g2` default to `t1`/`t2` whose own fields are all `is 0`, so a recursive default is emitted but is indistinguishable from a zero-fill. A **non-zero** nested default would put the claim on trial; none exists. | todo — the leaf that would prove this needs a non-zero default, which no generated thing has | |
| THG-47 | 1066–1079 | The stamp/letter example prints `25`, `12`, `2`. | reproduce | yes | none | todo (composite); hand-verified verbatim in `THG-46.vox` | |
| THG-48 | 1081–1090 | A thing containing **itself** has no finite size, so the definition that closes the cycle is a compile error naming the chain. | emit a self-referential definition | **no** — compile-error claim | none (correct by construction) | not assertable (compile-error claim); hand-verified, probe `THG-48.vox` | see **Discrepancy 2** |
| THG-49 | 1081 | A thing containing itself **through other things** is a compile error too. | emit a mutually-referential pair | **no** — compile-error claim | none | not assertable (compile-error claim); hand-verified, probe `THG-49.vox`. Note the diagnostic differs from THG-48's: the defined-earlier rule fires first and reports `Unknown field type`, which is exactly what LANGUAGE.md:1092–1095 predicts. | |
| THG-50 | 1092–1095 | Within one file, the **defined-earlier** ordering rule makes a cycle unconstructible: a field type must name a thing defined above the line. | — | **no** — compile-error claim | none (the prelude satisfies it by construction — a justified invariant, see below) | not assertable (compile-error claim); hand-verified in `THG-16.vox` | |
| THG-51 | 1095–1098 | Across files reached by `see`, the analyzer's registry DFS proves the merged registry acyclic; the DFS is defence-in-depth alongside the within-file rule. | two files that `see` each other with a cycle in their things | **no** — compile-error claim, **and** the DFS is not separately observable: the seen file arrives where the `see` is written, so the ordering rule fires first and a Vox program cannot tell which mechanism refused it | none — no generated program emits `see` at all | not assertable; the *outcome* (cross-file cycle refused) hand-verified, probe `THG-51.vox` + `fixtures/thg51_left.vox`, `fixtures/thg51_right.vox` | |
| THG-52 | 1102–1103 | A thing is a value: assignment copies the **whole thing**, and the copy shares nothing with the original. | copy, mutate the copy, read the original back | yes — both values are generator-chosen; `If i1's x1 is not {val} then, Exit 95.` | `gen leaf thing copy` emits exactly this shape (declare, set, copy, mutate, print both) but **prints** rather than asserts, so a copy that aliased would produce two equal numbers and nothing would notice | exercised — **and this is the single highest-value assertion in the section**: the leaf already emits the whole experiment and throws away the verdict | |
| THG-53 | 1103–1105 | A thing's size is a compile-time constant, so a copy is a run of inline moves — no allocation, no pointer left aliased. | — | **no** — an implementation claim; the *observable* half is THG-52 | n/a | not assertable | |
| THG-54 | 1107–1118 | The origin/moved example prints `5` then `9`. | reproduce | yes | `gen leaf thing copy` (same shape, different names) | exercised; hand-verified verbatim in `THG-52.vox` | |
| THG-55 | 1120–1121 | The three spellings of assignment — a declaration with an initialiser, a bare `is`, and `Set ... to` — are all assignment, so **all three copy**. | one copy of each spelling, each mutated afterwards, original read back each time | yes | only the declaration-with-initialiser spelling (`a t1 called i{b} is i{a}`, `gen leaf thing copy`). Bare `is` and `Set ... to` on a whole thing are never emitted. | todo (two of three spellings); hand-verified, probe `THG-55.vox` | |
| THG-56 | 1122–1123 | A copy is **deep by construction**: a nested thing is just more bytes, so copying carries the nested thing along and neither half is shared. | copy a thing with a nested thing field, mutate the copy's nested field, read the original's back | yes | **none.** `gen leaf thing copy` copies `t1`, which is flat. A `t3` (nested) is never used as a copy source or destination. | todo — real gap, and the case where an aliasing bug would actually show | |
| THG-57 | 1125–1140 | The letter/reply example prints `3` then `7`. | reproduce | yes | none | todo (composite); hand-verified verbatim in `THG-56.vox` | |
| THG-58 | 1142–1144 | A function receives a **copy** of a thing; mutating the parameter cannot reach the caller's value. | pass a thing to a function that writes its parameter, then read the caller's copy back | yes — the caller's value is generator-chosen and must be unchanged | **partial**: `gen emit prelude thing methods` has `'reflected across'` take `a t4 called original`, but it only *reads* `original's x1` — it never writes the parameter, so the claim that a write cannot escape is never on trial | todo | |
| THG-59 | 1144–1146 | The only way out is the `Return`, which copies into the caller's own storage. | — | yes | `gen leaf thing member` (both members return a `t4`) | exercised (construct); todo (verification) | |
| THG-60 | 1152 | A thing is usable as a **parameter** type (`To nudged with a point called start.`). | a plain function with a thing parameter | yes | only in the manifest form (`To do the t4's ...`) — see THG-04 | todo (plain form) | |
| THG-61 | 1154 | A thing is usable as a **return** type (`Return a point, start.`). | a plain function returning a thing | yes | only in the manifest form | todo (plain form) | |
| THG-62 | 1147–1160 | The nudged example prints `0` then `1`. | reproduce | yes | none | todo (composite); hand-verified verbatim in `THG-58.vox` | |
| THG-63 | 1162–1163 | `The after is nudged of before.` declares `after` from what the call returns, so a maker never has to have its type written twice. | emit the `The <name> is <call>.` inference form | yes | **none.** `"The ` appears nowhere in `src/*.vox` as generated text; `gen leaf thing member` always writes the type out (`a t4 called i{n} is a t4's 'made at' with ...`). The inference path is never taken. | todo — real gap | |
| THG-64 | 1163–1164 | A whole nested thing read out of a segment is copied the same way — `nudged of span's start` passes a copy and leaves the segment untouched. | pass a nested field as an argument, read the field back afterwards | yes — both values are generator-chosen | none — a chained possessive is never used as a call argument | todo | |
| THG-65 | 1166–1184 | The span example prints `41` then `40`. | reproduce | yes | none | todo (composite); hand-verified verbatim in `THG-64.vox` | |
| THG-66 | 1186–1189 | Assigning a single **value** to a whole thing is rejected, with the field to write named instead. | emit `Set origin to 5.` | **no** — compile-error claim | none | not assertable (compile-error claim); hand-verified, probe `THG-66.vox` | see **Discrepancy 3** |
| THG-67 | 1191–1201 | The exact diagnostic for `Set origin to 5.` is the three-line message quoted in the manual. | — | **no** — compile-error claim | none | not assertable; hand-verified in `THG-66.vox`. The message matches; its caret does not point at the offending line. | see **Discrepancies 2 and 3** |
| THG-68 | 1203–1213 | Stepping a whole thing with `increment` is rejected, naming its fields. | emit `increment origin.` | **no** — compile-error claim | none | not assertable (compile-error claim); hand-verified, probe `THG-68.vox` | see **Discrepancy 2** |
| THG-69 | 1215 | "Writing one field is what those lines mean: `Set origin's x to 5.`" — the named alternative works. | — | yes | `gen thing flat` and friends emit exactly this line | exercised; hand-verified, probe `THG-69.vox` | |
| THG-70 | 1216–1217 | A thing cannot be interpolated into a **text initializer** — a text initializer is a different sink from `Print`, which does render one. | emit `a text called t is "{origin}".` | **no** — compile-error claim | none — `gen format all` interpolates `hi{n}'s x1`, a *field*, into a `Print`, never a whole thing into a text initializer | not assertable (compile-error claim); hand-verified, probe `THG-70.vox`. This is the one whole-thing diagnostic whose caret is correct. | |
| THG-71 | 1217–1218 | A thing cannot be compared with a single value. | emit `If origin is 5 then, ...` | **no** — compile-error claim | none | not assertable (compile-error claim); hand-verified, probe `THG-71.vox`. Cross-refers to the Equality section, which the Things part B ledger maps; the row exists because this section makes the claim. | |
| THG-72 | 1220–1222 | Printing a call's result **directly** needs a variable — the result is a whole thing that must land in storage before it can be read. | emit `Print nudged of before.` | **no** — compile-error claim | none | not assertable (compile-error claim); hand-verified, probe `THG-72.vox` | see **Discrepancy 3** |
| THG-73 | 1223–1236 | The exact diagnostic for `Print nudged of before.` is the two-line message quoted in the manual. | — | **no** — compile-error claim | none | not assertable; hand-verified in `THG-72.vox`. The first line matches; the second is longer than the manual's. | see **Discrepancy 2** |
| THG-74 | 1238–1253 | The workaround: declare a scratch slot from the call, then print it — and a whole thing printed straight out renders as its fields. | emit the inference form followed by a whole-thing `Print` | yes — the rendered text is fully known (`{x: 1, y: 0}`) | `gen thing flat`/`nested` emit `Print i{n}` (whole-thing print), but never from a call's result via the inference form, and never assert the rendered text | exercised (whole-thing print); todo (from a call result, and verification of the rendering) | |
| THG-75 | 1102, 1120–1121 | *(gap)* A **whole thing** may be copied into a nested field (`Set span's start to anchor.`), between two fields of one thing (`Set span's start to span's end.`), and onto **itself** (`Set span's start to span's start.`, `Set twin to twin.`). All are assignment, `delivery.vox:50` relies on the first, and no example in this section shows any of them. | emit each of the three, reading the destination back | yes — every value is generator-chosen | none | todo — the self-copy is the memory-safety edge (an overlapping copy of a byte run onto itself); hand-verified safe, probe `THG-75.vox` | |

## Discrepancies

*Recorded, not adjudicated. Each has a runnable repro in
`probes/things-a/`. None filed.*

### 1. A `time` **field** takes zero with no initialiser, but a `time` **variable** must be initialised — the manual contradicts itself

Repro: `probes/things-a/D1.vox`.

LANGUAGE.md:913 (was 826) — "A field without a default takes its type's zero value."
LANGUAGE.md:938 (was 851) — "A field may be `number`, `float`, `boolean`, `time` …".
Together these say a `time` field has a zero value. The compiler agrees:

```
A thing called gauge has
  a time called taken.

a gauge called sample.
Print sample's taken.        (prints 0)
```

LANGUAGE.md:515 lists `time` as **not supported** on a bare `Create`, and
:503–506 explains why: "A default file or time value would be meaningless
(no path to open, no timestamp to hold)". `Create a time called clock.` is
duly refused with `A time variable must be initialized`.

So the same absent timestamp is meaningless in a variable and is `0` in a
field, one line apart. A `time` field also cannot be given a *meaningful*
default, because a default must be a literal (THG-10) and `current time`
is not one — `a time called taken is current time.` is refused. A numeric
literal is accepted (`a time called taken is 1000.` prints `1000`), so the
only initialisers a time field can have are raw timestamps.

**The reading in which the compiler is right:** a field is not a variable.
A thing's layout is fixed at compile time and its bytes must be *some*
value at declaration; there is no "declare it later" for a field, so
refusing an undefaulted `time` field would mean banning `time` fields
outright, which LANGUAGE.md:938 explicitly permits. Zero is then the only
available answer, and it is the same zero `Create a number called n.`
gives. Under this reading the compiler is consistent and **the manual's
Variables section is what is imprecise**: "not supported" at :501 is a
claim about the `Create` statement, not about the type's zero value, and
:503–506 should say so. That is the reading I would put money on — but it
turns a documented "meaningless" into a silently-produced value, and it is
a human's call, not mine.

### 2. The section's `(compile error: …)` blocks read as verbatim transcripts and are abbreviated

Repro: `probes/things-a/D2.vox` (the `increment origin.` case).

Four blocks in this section are written as if they were transcripts. All
four are shorter than what the compiler actually prints:

| manual | what the compiler adds |
|---|---|
| :998–1003 (`ouroboros`) — two lines | three lines, opening `A thing cannot contain itself: ouroboros contains ouroboros` |
| :1111–1113 (`Set origin to 5.`) | a trailing `.` on the second line |
| :1123–1125 (`increment origin.`) | second line continues `, printed as its fields (§7), and compared field by field (§8); no other position reads it as one value.` |
| :1147–1148 (`Print nudged of before.`) | second line continues `: write \`a point called <name> is nudged of ...\` or \`The <name> is nudged of ...\` (plan 310 §5).` |

**The reading in which the compiler is right:** the compiler is obviously
right — nothing here is a behaviour bug. The question is whether the
manual's `(compile error: …)` convention *promises* verbatim text. It is
not stated either way. Elsewhere the manual uses the same parenthetical
for clearly-paraphrased notes (`(n is 0)` at :479), so the convention is
plausibly "gist, not transcript", in which case there is nothing to fix.

Why it matters for this project anyway: a leaf that asserts on diagnostic
text would be built from the manual's version and would fail against the
compiler's. Recorded so the next worker does not build that leaf. (Under
the current contract no leaf emits a non-compiling program at all, so
nothing is blocked on this today.)

### 3. Whole-thing diagnostics caret the **declaration**, not the offending statement

Repro: `probes/things-a/D3.vox`.

```
1 A thing called point has
2   a number called x is 0,
3   a number called y is 0.
4
5 a point called origin.
6 Set origin to 5.
```

The caret lands on **5:16** — the `origin` in `a point called origin.`,
which is correct Vox — not on line 6, which is the mistake. The same shape
holds for `increment origin.` (THG-68), for `If origin is 5 then,`
(THG-71), and for `Print nudged of before.` (THG-72), where the caret goes
to `To nudged with a point called start.` five lines earlier. The text
interpolation case (THG-70) is the exception: it carets the slot itself,
correctly.

**The reading in which the compiler is right:** every one of these messages
opens by asserting a *type* fact — "`origin` holds a whole point" — and the
declaration is where `origin` acquired that type. Pointing at the
declaration answers "why do you think it holds a whole point?", which is
the question a reader who wrote line 6 actually has. On that reading the
placement is deliberate and only the inconsistency with THG-70 is odd.
Nothing in LANGUAGE.md promises where a caret lands, so this may be
entirely intended.

### 4. "All three lines below" precedes a block containing one line

Repro: `probes/things-a/D4.vox`.

LANGUAGE.md:964–965 (was 877–878): "All three lines below declare a `point` and give
every field its declared default:" — and the block at :880–894 contains
exactly one declaration, `a point called origin.`

The claim itself is true: all three declaration forms work on a thing and
all three take the declared defaults (D4 runs them side by side and gets
`1 2` three times). Only the example is missing two of its three lines.

**The reading in which the manual is right:** "below" may mean the whole
subsection rather than the immediately following block. The subsection's
three code blocks do open with three different declarations — `a point
called origin.` (:885), `Create a point called 'the far corner'.` (:907),
and `a 'water tank' called cistern.` (:922) — and each does take its
declared defaults. That reading is coherent and may well be what was
meant; it is just not what the sentence's placement suggests.

### 5. A function-local name read out of scope is reported against the **legal** in-function use, with a hint about an `if` that is not there

Repro: `probes/things-a/D5.vox`.

```
4 To 'plot a point'.
5   a point called cursor.
6   Print cursor's x.
7
8 'plot a point'.
9 Print cursor's x.
```

Line 9 is the mistake; the compiler reports `Unknown variable: cursor` at
**6:9**, the in-function read, which is correct Vox. Delete line 6 and the
caret moves to line 9, which is right (that is `THG-39.vox`). The hint
reads "`cursor` is declared only in some branches of an `if`/`otherwise`"
— there is no `if` in the program.

**Not specific to things.** The same shape with `a number called cursor is
4.` reproduces identically, so this belongs to whoever maps Function Scope
(LANGUAGE.md:735, was 705 — the sentence itself is unchanged, only shifted, by the 0.4.10 growth of the surrounding Function Scope section), not to this ledger. It is recorded here because it was
found while probing LANGUAGE.md:1016–1017 (was 929–930), and because it would waste the
next mapper's time twice. Cross-reference: this is the same diagnostic-quality issue as `functions.md`'s Discrepancy 9 ("locals are not available at top level" rule enforced, diagnostic points inside the function) — not in the 0.4.10 register, still open.

**The reading in which the compiler is right:** if the analyzer resolves
names against one flat table built in source order, a name that fails to
resolve at top level can only be reported at its first occurrence, and the
if/otherwise hint is the generic advice attached to every unresolved-name
error. That explains the behaviour without making it correct: the
diagnostic points a reader at a line they must not change.

## Invariants this section justifies

Sameness the invariant report will show that LANGUAGE.md actually
requires:

- every thing definition sits at the top level, before any statement that
  uses it — LANGUAGE.md:884, THG-03
- a thing field's type is always a thing defined **above** it, so `t3` is
  never defined before `t1`/`t2` — LANGUAGE.md:1092–1095, THG-16, THG-50
- a manifest member's `To do the <type>'s <member>` always follows that
  type's definition — LANGUAGE.md:1092–1095 (the same ordering rule),
  THG-11, THG-21
- no generated thing has a `text`, `list`, `map`, `buffer`, `file`,
  `timer` or `value` field — LANGUAGE.md:940–942, THG-17
- a whole thing is never assigned a single value, never incremented, never
  interpolated into a text initializer, and never compared with a single
  value — LANGUAGE.md:1186–1218, THG-66, THG-68, THG-70, THG-71
- a call returning a thing is never printed directly — LANGUAGE.md:1220–1222,
  THG-72
- a field default is always a literal — LANGUAGE.md:908–909, THG-10

Sameness the manual does **not** justify, and which this section's rows
name as defects (each is a `todo` row above, not a tuning knob):

- exactly four thing types per program, always named `t1`–`t4` — no rule
  says four, or any number, and no rule says bare-word names (THG-14)
- every thing field is a `number` named `x1`/`x2`/`g1`/`g2` — the manual
  permits `float`, `boolean`, `time` and quoted multi-word names (THG-15,
  THG-35)
- every field carries the default `is 0` — the manual makes the default
  optional and the literal free (THG-09, THG-12, THG-37)
- exactly one level of nesting exists (t3 holds t1/t2) — "things nest to
  any depth" (THG-42)
- every instance is declared with the bare `a T called N.` form — two more
  forms are documented (THG-24, THG-34)
- every field write is `Set X's f to V` — bare `is` and `increment`/
  `decrement` are documented lvalue positions (THG-29, THG-30, THG-33)
- no thing is ever declared inside a function body (THG-39)
- no plain function ever takes or returns a thing; only manifest members do
  (THG-04, THG-60, THG-61)
- the `The <name> is <call>.` inference form never appears (THG-63)

## Report

**75 rows** (THG-01 … THG-75). One (THG-36) is a restatement folded into
THG-12, leaving **74 distinct claims**.

- **39 rows are hand-verified with a retained probe**; 44 probe files in
  total including D1–D5 and two `see` fixtures. `docs/check-probes.sh
  docs/ledger/probes/map-things` → **44 passed, 0 failed, 0 skipped.**
- **5 rows are flatly not assertable** — implementation claims with no
  language-level observation: THG-02 (no dispatch / offsets fixed), THG-40
  (stack not `.bss`), THG-43 (inline bytes, no pointer chase), THG-44
  (layout order — only reachable through `Print`, which part B maps),
  THG-53 (inline moves, no allocation).
- **15 rows are compile-error claims**, which are not assertable *by a
  leaf* under this project's contract (a generated program must be legal
  Vox that compiles): THG-03, THG-10, THG-16, THG-17, THG-48, THG-49,
  THG-50, THG-51, THG-66, THG-67, THG-68, THG-70, THG-71, THG-72, THG-73.
  Every one is hand-verified with a probe anyway, because the ledger's job
  is to be complete against the text. They also generate the *negative*
  invariants above — the shapes a leaf must never emit.
- **54 rows are assertable by a leaf**, and the generator can predict the
  exact result for every one of them, because it chooses every field
  value, every default and every literal it writes.

**Biggest finding: `gen leaf thing copy` already runs the whole
value-copy experiment and throws away the verdict.** It declares a `t1`,
writes `x1`, copies the instance, writes `x1` on the copy, and prints both
— which is precisely the experiment LANGUAGE.md:1102 (was 1015) describes. It then
`Print`s two numbers for a human who is not reading. If the copy ever
aliased, the leaf would emit two identical numbers and the campaign would
come back clean. One assertion (`If i{orig}'s x1 is not {val} then, Exit
95.`) turns the most important claim in the section from `exercised` into
`verified`, and it is a two-line change to a leaf that already exists.
That is where the next batch should start. The buffers ledger reported
"no leaf asserts anything" as a buffers finding; it is now confirmed for a
second surface and should be treated as universal.

**Second finding: this section's undeclared rules are unusually
concentrated.** Four thing types, all bare-word `t1`–`t4`, all fields
`number`, all defaulted `is 0`, one nesting level, one declaration form,
one field-write form. Nine unjustified invariants are listed above. Every
one of them is a rule nobody wrote — the manual permits quoted multi-word
type and field names, `float`/`boolean`/`time` fields, absent defaults,
non-zero defaults, any nesting depth, three declaration forms, and five
lvalue positions. `src/gen_things.vox` is 142 lines and its prelude is a
fixed block of literal text; making the *prelude itself* random (how many
types, what they are called, what fields they have, in what order) is
probably worth more than any single new leaf.

**Third finding: the highest-risk constructs are the ones never emitted.**
The doubled-quote possessive `'the far corner''s x` (THG-35) is the
spelling most likely to break a lexer and no generated program contains
it. A thing field never reaches a condition or a general expression
(THG-32) because `gen condition` and `gen var ref` only know about
`v{n}`. A thing is never declared inside a function body (THG-39), so the
stack-storage path in the manual's own parenthetical is never taken. And
`gen leaf thing copy` only ever copies a **flat** thing (THG-56), so the
deep-copy claim — the one where an aliasing bug would actually show — is
untested.

**Five discrepancies**, all with repros, none filed. D1 (`time` field zero
vs `time` variable must-initialise) is the only one that is a real
contradiction inside the manual and the only one I would put in front of
the lawyer first. D2 and D4 are documentation precision. D3 is a caret
placement that has a good pro-compiler reading. D5 is not a things
problem at all and should be handed to whoever maps Function Scope.

**Advice for the next mapper.**

1. `grep` the generated **text**, not the generator's own Vox. Half this
   map's `existing leaf` answers came from grepping `"increment`, `"The `,
   `"Create a t` — string literals that would be *emitted* — and all three
   came back empty while the generator's own source uses those words
   constantly. Grepping without the quote gives you the generator's code
   and tells you nothing.
2. Follow the operand functions to the bottom. `gen condition` looks like
   it exercises the whole comparison table; it does, but only over
   `gen var ref`, which returns `v{n}` and nothing else. Any claim of the
   form "X works in a condition / in an expression" is `todo` for every
   surface except plain numbers, and you will not see that from the leaf.
3. Compile-error claims are a large fraction of a syntax-heavy section —
   15 of 74 here. They need their own answer in `assertable?` (not
   assertable *by a leaf*, since the generated program must compile), a
   probe anyway, and a line in the **negative** invariants list, because
   "no generated program ever does X" is a sameness the report will flag
   and that these rows are exactly what justifies.
4. Reserved words bite. `A thing called reading has …` fails with
   "Cannot use 'reading' as a variable name - it's a reserved keyword"
   before you get anywhere near the claim you were testing. Pick probe
   names that are obviously nouns of the domain and re-run on the first
   surprise.
5. One more compiler nicety worth knowing and not worth a discrepancy:
   `A field default must be a literal` suggests `is "text"` as an example
   — but `text` fields are deferred (THG-17), so that half of the hint is
   unreachable advice.
