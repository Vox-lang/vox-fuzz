# Claim ledger: Variables

Source: `../vox/LANGUAGE.md` lines **457–674**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 — Declaration
with Type, Declaration with Set/Create, Two Canonical Forms, Assignment,
Type Immutability, Naming Rules. Row prefix **`VAR`**.

**Zero line drift held across every version from 0.4.7 through 0.4.9**
(`## Variables` stayed line 446, `## Names and strings` line 645) — **the
streak ended at 0.4.10**: `## Variables` moved to 457 and `## Names and
strings` to 675, an **+11** net shift from insertions earlier in the
manual, though most individual row citations inside this section still
landed unchanged (the shift and later within-section deletions/insertions
partly cancel per-line — e.g. VAR-01's own citation is still 461). The
Type Immutability subsection specifically grew by #74's new `'s
<property>` clause (see VAR-44): LANGUAGE.md:642–648 (was 623) is longer
than its 0.4.9 self, not just relocated.

**Discrepancy 1 is RESOLVED (vox #54)** — re-verified directly against
0.4.9: the list-element type-check gap that let a memory-safety segfault
through is closed; `D1.vox`/`D1b.vox`/`VAR-46.vox` now compile-error
instead of crashing. **Discrepancy 2 remains genuinely open** — this is
the brief's "variables D2" — but its downstream symptom changed as a
side effect of the same #54 fix: the loop-header rebinding itself is
still unchecked (`D2.vox` unchanged), but arithmetic on the resulting
mistyped variable is now a compile error instead of a silent address
leak (`VAR-34.vox` re-recorded). No register number was found for D2
itself; recorded honestly rather than guessed — see the discrepancy
entry for the full trail (`REPORT-CANDIDATES-0.4.10.md` candidate C).

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct — checked by `grep` on the
keyword or accessor inside the generator's *emitted* string literals, never
by leaf name, and never by the generator's own Vox source, which uses the
same constructs for its own variables and would otherwise show a false hit
on every row. `status` follows PROCEDURE.md §3.

**Nothing in this section is `verified`.** The uniform gap the buffers and
values ledgers found holds here too: no leaf asserts a documented result.
It is worse here than elsewhere, because a large fraction of this section's
claims are about what the compiler **rejects**, and a leaf that emits a
compile error violates the generator's contract that a generated program is
legal Vox that should compile and run. Those rows are marked `not
assertable` with that reason, and the honest reading of this section is
that its leaf yield is small but its **discrepancy** yield is the largest
of any section mapped so far: **nine**, one of them a deterministic
segfault on a program the compiler accepted.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` pinned to
the sibling `coreasm`) before being written.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/variables/`, one file per row named `VAR-NN.vox`. A
probe covering more than one row is named for the first and says so in its
header. Each file opens with a `(...)` comment naming the claim, the `Ran:`
command, and an `expected output:` block recording what the compiler
actually printed. `fixtures/helper.vox` is the include target VAR-63 reads;
its `see` is written `./fixtures/…`, which resolves against the probe file's
own directory, so that probe runs from any working directory.

`docs/check-probes.sh docs/ledger/probes/variables` was run as the last act
of writing this ledger: **49 passed, 0 failed, 1 skipped**. The skip is
`D5.vox`, which is a transcript rather than a repro (see below) and
deliberately records no expected output.

Rows with no probe file, and why:

- **VAR-04, VAR-06, VAR-08, VAR-09, VAR-11, VAR-12, VAR-13, VAR-15,
  VAR-19, VAR-20, VAR-23, VAR-24, VAR-25, VAR-29, VAR-30, VAR-32, VAR-33,
  VAR-39, VAR-44, VAR-49, VAR-50, VAR-51, VAR-61** — covered by a sibling
  row's probe, named in the row.
- **VAR-47, VAR-65** — need a second compilation unit and a built
  `.so`/`.lib` pair; they cannot be a single-file probe. Both were
  hand-verified anyway and their transcripts are recorded (VAR-47 below the
  table; VAR-65 in `D5.vox`).
- **VAR-66** — a cross-reference to another section, not a claim.

Discrepancy repros are `D1.vox` … `D9.vox`, plus `D1b.vox`, the
compile-error half of Discrepancy 1 that shows the check the list path is
missing does exist on the map path.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| VAR-01 | 477 | `a` or `an` before a type keyword declares a new variable. | emit both articles across programs | yes — declare under each article and assert the value; hand-verified that neither article is checked against the word after it (`an number` compiles), and that a user thing type is the only way a vowel-initial type is even reachable | every leaf emits `a`; **no leaf ever emits `an`** — grep of every emitted string finds zero | exercised (`a` only) — the missing `an` is an unjustified invariant, see Report | |
| VAR-02 | 479–485 | Worked example: the five `a TYPE called NAME is VALUE.` declarations compile and each name holds its literal. | reproduce all five in one program and assert each | yes — the generator wrote the literals | number/text/boolean/list/map declarations are all emitted, but by five different leaves and never together | exercised (composite); sub-claims are VAR-08/10/11/12/13 | |
| VAR-03 | 490 | `Set a TYPE called NAME to VALUE.` declares and initializes. | emit the `Set` lead-in as an alternative spelling of a declaration | yes — `If NAME is not <literal> then, Exit 95.` | **none** — grep for `Set a ` inside emitted strings finds zero | todo | |
| VAR-04 | 491 | `Create a TYPE called NAME to VALUE.` declares and initializes. | emit the `Create` lead-in | yes, same assertion as VAR-03 | **none** — grep for `Create a ` inside emitted strings finds zero | todo — probe VAR-03.vox | |
| VAR-05 | 496–497 | Every declarable type supports two equivalent forms, both routed through the same type resolver. | for each type, emit both forms in one program and assert they produce the same kind of variable | yes for the types that have both — assert `X's type` is equal for the initialized and the defaulted name | partial: the initialized form is everywhere, the defaulted form only for `timer` and thing types | todo — and the "every" does not hold: `timer` has only the defaulted form, `file`/`time` only the initialized one, see **Discrepancy 8** | |
| VAR-06 | 499–504 | `A TYPE called NAME is VALUE.` declares and initializes immediately; `Set`/`Create` with `to <value>` is the same form with a different lead-in word. | emit the three lead-ins interchangeably and assert the same result from each | yes | the bare lead-in is universal; the other two are never emitted | exercised (bare form only) — probe VAR-03.vox | |
| VAR-07 | 505–506 | `Create a TYPE called NAME.` declares NAME with no initializer and gives it that type's default (zero) value. | emit the no-initializer declaration and assert the default | yes — the default is fixed per type | the no-initializer *shape* is emitted (`a t1 called i{n}` in `gen leaf thing copy`, `a timer called tk{n}` in `gen leaf timer and clock`), but never under the `Create` lead-in and never for a builtin value type | todo — and the bare-lead-in spelling of this form is undocumented, see **Discrepancy 7** | |
| VAR-08 | 509, 521 | Default for `number` is `0`. | `Create a number called N.` then `If N is not 0 then, Exit 95.` | yes | none | todo — probe VAR-07.vox | |
| VAR-09 | 510, 522 | Default for `float` is `0.0`. | as VAR-08, against `0.0` | yes | none | todo — probe VAR-07.vox | |
| VAR-10 | 523 | Default for `text` is the empty string. | assert the length or a bracketed print is empty | yes | none | todo | |
| VAR-11 | 511, 524 | Default for `boolean` is `false` (`0`). | assert the name is false | yes; note the runtime prints a boolean as `1`/`0`, which is the Input/Output section's business | none | todo — probe VAR-07.vox | |
| VAR-12 | 512, 525 | Default for `list` is `[]`. | assert `N's length` is 0 | yes | `a list called l{n} is []` (`gen leaf list mixed`) emits an empty list literal, which is a *different* construct — the initializer is present | todo — probe VAR-07.vox | |
| VAR-13 | 513, 526 | Default for `map` is `{}`. | assert `N's length` is 0 | yes | none — every emitted map carries a literal | todo — probe VAR-07.vox | |
| VAR-14 | ?, 527 | Default for `buffer` is empty, 0 bytes, dynamic capacity. | assert size 0 and that appends grow it | yes for size; **no** for capacity — the compiler reports 4096, which is already Discrepancy 1 of `buffers.md` (BUF-02) | none | todo (size half); the capacity half is blocked on `buffers.md` D1 | |
| VAR-15 | 515, 528 | Default for `value` is `nothing`. | `Create a value called N.` then `If N is not nothing then, Exit 95.` | yes | `gen leaf value roundtrip` declares `a value called y{n} is {number}` — always initialized, never defaulted | todo — probe VAR-07.vox | |
| VAR-16 | 516, 529 | Default for `timer` is "ready to `Start`". | declare bare, Start, Stop, assert elapsed is not negative | yes, weakly — "ready" has no direct reading; the observable form is that Start/Stop then work | `gen leaf timer and clock` emits exactly `a timer called tk{n}` + `Start` + `Stop` + an elapsed read, and checks it is not negative — the closest thing to an assertion anywhere in the generator, though it prints a label rather than exiting 95 | exercised | |
| VAR-17 | ?, 533–536 | `Create a file called N.` is rejected at compile time; a file needs a path. | — | **no** — emitting it produces a non-compiling program, outside the generator's "legal Vox that should compile and run" contract | n/a | not assertable | |
| VAR-18 | ?, 533–536 | `Create a time called N.` is rejected at compile time; a time needs an initializer. | — | **no**, same reason as VAR-17 | n/a | not assertable | |
| VAR-19 | 539–541 | The `file` rejection names what to supply, with the `Example:` line quoted in the manual. | — | **no**, same reason | n/a | not assertable — probe VAR-17.vox reproduces the diagnostic verbatim | |
| VAR-20 | 543–546 | The `time` rejection names what to supply, with its `Example:` line. | — | **no**, same reason | n/a | not assertable — probe VAR-18.vox | |
| VAR-21 | 548–549 | `a file called source is "input.txt".` and `a time called now is current time.` are the accepted way to give those types a value. | emit both declaration forms | yes — assert `X's type` | **none for either**: files reach the generated programs only through `open a file … called fr{n} at …`, and `time` only through `Get current time into tn{n}`; neither `a file called … is …` nor `a time called … is …` is ever emitted | todo — real gap, hand-verified to work | |
| VAR-22 | 568 | `the` before a name references an existing variable. | emit the `the NAME` reference form | yes | `gen leaf timer and clock` emits `the tk{n}'s elapsed in milliseconds` and `the tn{n}'s unix` / `'s year` — the only three `the`-references in the whole generator, and all three are possessive reads | exercised (possessive read only) | |
| VAR-23 | 571 | `the x is 10.` assigns to an existing variable. | emit the `the NAME is VALUE.` assignment | yes — the generator chose the value | **none** — the `the`-as-assignment-target form is never emitted | todo — probe VAR-22.vox | |
| VAR-24 | 572 | `the counter is the counter add 1.` — `the` also reads on the right-hand side of an assignment. | emit a self-referential `the` assignment | yes | **none** | todo — probe VAR-22.vox | |
| VAR-25 | 577–578 | A variable's type is fixed at its declaration and never changes; `value` is the one deliberate exception. | — | **no** — putting it on trial means emitting a mismatch, which does not compile. The exception half is VAR-41. | n/a | not assertable — probe VAR-26.vox | |
| VAR-26 | ? | The `x is <value>.` write form on an already-declared name is type-checked. | — | **no**, compile-error claim. Worth noting separately that the *legal* same-type spelling `x is <value>.` is itself never emitted by any leaf. | none emits the bare reassignment spelling at all | not assertable | |
| VAR-27 | ? | The `the x is <value>.` write form is type-checked the same way. | — | **no**, compile-error claim; the legal spelling is also never emitted | none | not assertable | |
| VAR-28 | ? | The `Set x to <value>.` write form is type-checked the same way. | — | **no**, compile-error claim | the legal same-type spelling **is** emitted: `gen leaf assign` (`Set v{n} to <expr>.`), `gen leaf value roundtrip` (`Set y{n} to "…"`), `gen leaf timer and clock` (`Set ta{n} to ta{n} add te{n}`) | not assertable (the check); exercised (the form) | |
| VAR-29 | 580–582 | A type mismatch on any of those three forms is a compile error, not a silent retype. | — | **no**, compile-error claim | n/a | not assertable — probes VAR-26/27/28.vox | |
| VAR-30 | 585–586 | Worked example: after `a number called n is 5.`, `n is "abc".` errors with `cannot assign text to 'n', which is a number`. | — | **no**, compile-error claim | n/a | not assertable — probe VAR-26.vox | |
| VAR-31 | 587 | `n is "42" as a number.` is accepted and `n` becomes 42. | emit a cast-repaired reassignment of an existing name and assert the result | yes — `If n is not 42 then, Exit 95.` | partial: `gen leaf cast and break` emits `a number called cb{n} is ct{n} as a number` and `gen leaf base conversion` emits `a number called bg{n} is bx{n} as a number` — both **declare a new name**; the cast never lands on an already-declared one, which is the case this claim is about | todo | |
| VAR-32 | 590–603 | The diagnostic names the variable, its declared type, its declaration site, the offending value's type, and the exact cast that would fix it. | — | **no**, compile-error claim | n/a | not assertable — probe VAR-26.vox reproduces the block; but see **Discrepancy 6**, the caret is not where the manual shows it | |
| VAR-33 | 605–607 | The repair uses the ordinary Type Casting mechanism (`as a number` / `as text`), not syntax invented for this rule. | emit both cast directions | yes | `as a number` and `as text` are both emitted (`gen leaf cast and break`, `gen leaf base conversion`), never asserted | exercised — probe VAR-31.vox | |
| VAR-34 | 609–611 | Reusing an already-declared name as a `For each … in <collection>` loop variable rejects a conflicting type. | — | **no**, compile-error claim — but the *memory-safety* half is a real leaf need: emit the pattern and require the program not to produce a wrong answer | `For each w{n} in l{n}` and `For each k{n} in m{n}'s keys` are emitted (`gen leaf list mixed`, `gen leaf map inrange`), always with a fresh name, so the reuse case is never reached | todo — **the claim still does not hold for the loop header**, see **Discrepancy 2** (still open). Note the *downstream* symptom this row's own probe exercises changed: `counted add 1` after the loop used to silently print a raw address, and is now a compile error (vox #54's side effect) — the probe was re-recorded to that. | blocked on D2 |
| VAR-35 | 609–611 | Reusing an already-declared name as a for-range loop variable rejects a conflicting type. | — | **no**, compile-error claim | for-range loops are emitted (`gen leaf timer and clock`, `gen leaf deep grid`, the loop-control leaves), always with a fresh name | not assertable — holds, probe VAR-35.vox | |
| VAR-36 | 611 | Reusing an already-declared name as the target of `open … called` rejects a conflicting type. | — | **no**, compile-error claim | `open a file for reading called fr{n} at …` is emitted (`gen leaf file round trip`, `gen leaf stdin read`, `gen leaf file write`), always with a fresh name | not assertable — holds, probe VAR-36.vox | |
| VAR-37 | 612 | Reusing an already-declared name as the target of `Allocate … for` rejects a conflicting type. | — | **no**, compile-error claim | **none** — `Allocate` is never emitted by any leaf, and appears nowhere else in LANGUAGE.md than this one line: the manual references a construct it does not define | not assertable — holds for text/list targets, does **not** hold for buffer targets, see **Discrepancy 3** | |
| VAR-38 | 613–615 | A nested declaration that reuses an outer name at a different type is rejected; Vox has no block-level scoping, so there is no inner slot for it. | — | **no**, compile-error claim | nested declarations inside `If`/loop bodies are emitted constantly, always with a fresh name | not assertable — holds, probe VAR-38.vox | |
| VAR-39 | 617–622 | Worked example: the `If` block redeclaring `n` as text errors with `cannot bind 'n' to text in this declaration`. | — | **no**, compile-error claim | n/a | not assertable — probe VAR-38.vox reproduces it | |
| VAR-40 | 626–629 | Buffer exemption: writing into a buffer formats the value's text representation into its content, so a buffer accepts any value type on every write. | write a number, a boolean, a float and a text into one buffer in turn and assert the content each time | yes — the generator knows what it wrote and what its text form is | partial: `gen leaf format types` and the `gb`/`gc`/`gw` format leaves write **text** into buffers via `is`, `set`, `append` and `copy` — a number, boolean or float written into a buffer is never emitted, and nothing asserts the resulting content | exercised (text sources only); todo for the cross-type writes and for all assertions | |
| VAR-41 | 630–633 | `value` exemption: a `value`-declared name keeps accepting any type across reassignment. | reassign a value across at least two type boundaries and assert each | yes | `gen leaf value roundtrip` (`a value called y{n} is <number>` → `Set y{n} to "<text>"`) crosses exactly one boundary, number to text, and prints rather than asserts | exercised | |
| VAR-42 | 634–637 | `<valuevar> is a <type>.` retypes a `value` in place: reads the runtime tag, converts, updates the tag. | emit an in-place retype and assert both the converted value and the new `'s type` | yes — the generator supplies the source text and knows its numeric value | **none** — the retype statement is never emitted; `grep` for `is a number.` in emitted strings finds only flag-schema lines (`it is a number.`), a different construct | todo — real gap, hand-verified to work | |
| VAR-43 | 637–640 | The same statement applied to a statically-typed name is rejected. | — | **no**, compile-error claim | n/a | not assertable — holds, probe VAR-43.vox | |
| VAR-44 | 642–648 | **Claim extended, 2026-08-22 (0.4.10, #74).** The check only rejects a mismatch provable statically from the value's own shape — a literal, a cast, a read from a list/map whose element type is provably uniform, and (new in 0.4.10) **a `'s <property>` read whose property has the same type whatever it is read from** — every Object Properties table entry except `first`/`last`/`absolute`/`duration`/`elapsed`, whose type follows the thing they are read from. Before #74, `a text called t is xs's length.` compiled and segfaulted on the first read — the type lock's oracle answered only for `first`/`last` and treated every other property as "type unknown". | for the property half: assign a mistyped property read (e.g. a `number` property into a declared `text`) and expect a compile error naming the two ways out | **no** — a claim about the boundary of a compile-time check; both sides of the boundary are compile errors or sanctioned garbage | n/a | not assertable — **and the list half did not hold through 0.4.9**, see **Discrepancy 1**; probes VAR-45.vox and D1b.vox. **The new property half hand-verified fixed against 0.4.10**: `a text called badlen is xs's length.` now refuses to compile, naming both ways out, where 0.4.9 segfaulted | |
| VAR-45 | 648–651 | A value from a function call, or an unprovable list/map read, is allowed through unchecked. | emit the pattern and require no crash | **not as a correctness oracle** — the manual sanctions the resulting garbage, so there is no documented right answer to assert. As a **memory-safety** leaf it is worth emitting: the program must not crash. | **none** — no leaf assigns a function result or a collection read to an already-declared name of another type | todo (memory-safety leaf) | |
| VAR-46 | 651–654 | The rule closes the class where the compiler-tracked type disagrees with what the variable holds — previously "a wrong number on screen at best and a segfault at worst". | emit the residual patterns and require the program not to crash | yes as a crash oracle | none | todo — **RESOLVED, vox #54**: the segfault no longer reproduces, the mismatch is now refused at compile time. See Discrepancy 1 (resolved); probe VAR-46.vox is now a compile-error probe. | unblocked |
| VAR-47 | 653–655 | The rule says nothing about type agreement across a `.lib` import boundary; a library's declared signature is trusted, not verified against its `.so`. | — | **no** — needs a second compilation unit and a built `.so`/`.lib` pair, outside the generator's one-program contract | n/a | not assertable — hand-verified anyway; transcript below the table | |
| VAR-48 | 658–660 | A name is an identifier, never a string literal: three forms, no overlap, no context-sensitivity. | emit all three forms in one program | yes | all three appear across the generator | exercised — **but the "no context-sensitivity" half does not hold**, see **Discrepancy 5** | |
| VAR-49 | 664 | `"…"` is a string literal, always, everywhere. | — | yes, as data | emitted constantly as data (`Print "…"`, map keys, flag aliases, file paths) | exercised — probe VAR-48.vox | |
| VAR-50 | 665 | `bare_word` is a single-word identifier. | — | yes | every emitted name | exercised — probe VAR-48.vox | |
| VAR-51 | 666 | `'multi word'` is an identifier containing spaces. | — | yes | `gen leaf environment oob` emits `a text called 'the missing value {n}' is …` and reads it back — the **only** leaf that emits a quoted variable name; `'grid sink {n}'`, `'made at'` and `'reflected across'` are quoted *function* names, a different position | exercised (one leaf) — probe VAR-48.vox | |
| VAR-52 | 668–669 | Where an identifier is expected and a string literal is found, that is a compile error. | — | **no**, compile-error claim | n/a | not assertable | |
| VAR-53 | 670–671 | A bare identifier matches `[A-Za-z_][A-Za-z0-9_]*`. | vary the shape of emitted names across the whole accepted set | yes — declare and read back | every emitted name is lowercase letters followed by a counter (`v3`, `gb7`, `fl2label`): no capital, no underscore, no digit anywhere but the tail | exercised (a very narrow band of the set) — **and the manual's set is wrong**, see **Discrepancy 9** | |
| VAR-54 | 670–672 | A bare identifier is not a reserved keyword; reserved keywords remain rejected as names. | — | **no**, compile-error claim | n/a | not assertable — **and it is not enforced in every binding position**, see **Discrepancy 4** | |
| VAR-55 | 671–672 | A name that collides with a reserved word is written quoted (`'number'`, `'version'`). | emit a quoted reserved word as a name and read it back | yes | **none** — no emitted name is a quoted reserved word | todo, hand-verified to work | |
| VAR-56 | 673–674 | A quoted identifier is `'`…`'` containing two or more characters. | emit two-character and longer quoted names | yes | `'the missing value {n}'` only — always long, always multi-word, always the same shape | exercised (one shape) | |
| VAR-57 | 674 | A quoted identifier contains no newline. | — | **no**, compile-error claim | n/a | not assertable | |
| VAR-58 | 674–676 | Exactly one character between single quotes is a character literal, so single-character quoted identifiers do not exist. | emit a character literal and assert its code point | yes — `a number called cN is 'A'.` then `If cN is not 65 then, Exit 95.` | **none** — no leaf emits a character literal at all | todo — a cheap, fully assertable row | |
| VAR-59 | 677–678 | Single-word quoted identifiers are legal but non-canonical, and lex identically to the bare form. | declare under one spelling, read under the other, assert the value | yes | **none** — the one quoted name the generator emits is multi-word and is always read back in the same spelling | todo — fully assertable | |
| VAR-60 | 679–681 | Possessive: after a closing identifier quote, an `s` immediately following and itself followed by a non-identifier character is the possessive marker. | emit `'quoted name's <property>` | yes — assert the property's value | **none** — the possessive is emitted only on bare names (`m{n}'s "label"`, `i{n}'s x1`, `tk{n}'s elapsed`); never on a quoted one | todo — real gap, hand-verified to work | |
| VAR-61 | 681–682 | `'name''s` also works; both spellings are accepted. | emit the doubled form too | yes, same assertion | **none** | todo — probe VAR-60.vox | |
| VAR-62 | 683–684 | Map keys are data, not names, and stay double-quoted. | — | yes | `gen leaf map inrange` / `oob` emit `m{n}'s "label"`, `Set m{n}'s "count" to …`, and map literals with double-quoted keys | exercised | |
| VAR-63 | 684 | File paths are data, not names, and stay double-quoted. | — | yes | double-quoted paths are emitted (`open … at "…"`, `a text called fp{n} is "…"`); `see` is never emitted at all | exercised (for `open`) — **but the rule is not enforced for `see`**, see **Discrepancy 5** | |
| VAR-64 | 684–685 | Flag aliases are data, not names, and stay double-quoted. | — | yes | `gen emit prelude flags` emits `a flag called fl{n}label is "-a" or "--alpha{n}", …` | exercised | |
| VAR-65 | 685 | Version strings are data, not names, and stay double-quoted. | — | **no** — the only positions a version appears in are the `Library` header and `see … version …`, both of which need a second compilation unit | none — `see` and `Library` are never emitted | not assertable — hand-verified anyway; transcript in `D5.vox`, and the rule does **not** hold, see **Discrepancy 5** | |
| VAR-66 | 687–688 | Cross-reference to *Names and strings* for why one token cannot mean two things. | — | — | — | folded into VAR-48; the `NAM` ledger owns the argument itself | |

### Note on VAR-47 — the `.lib` boundary, hand-verified

The row is `not assertable` because it needs two compilation units, but the
claim was checked rather than taken on trust. What was run:

```
kit.vox:   Library kit version "1.0".
           To 'label of' with a number called x. Return text, "value".
built:     vox kit.vox --shared -o libkit.so     (emits libkit.lib)
edited:    libkit.lib's entry changed from "returning a text"
           to "returning a number" — now disagreeing with the .so
consumer:  see kit version "1.0" from "./libkit.lib".
           a number called n is 'label of' of 7.   Print n.
           a text called t is 'label of' of 7.     Print t.
result:    compiles clean; prints 140397753589826 then value.
```

Both directions pass: the `.lib`'s false claim is believed for the number
declaration, which then holds a raw address, and the `.so`'s real text
return still arrives for the text declaration. Nothing checks the two
against each other. The manual is right, and this is the one claim in the
section that is a documented *limitation* rather than a documented
behaviour.

## Discrepancies

Nine, all with a runnable repro in `docs/ledger/probes/variables/`, none
filed, none adjudicated. Ordered by severity.

### 1. A list-element read is not type-checked, and the mismatch it lets through segfaults — RESOLVED (vox #54)

`D1.vox`, and the same program as `VAR-46.vox`. LANGUAGE.md:642–648 says
the check rejects a mismatch it can prove "from the value's own shape (a
literal, a cast, **a read from a list/map whose element type is provably
uniform**, …)" — 0.4.10 additionally extends this to a `'s <property>`
read whose property type does not depend on what it's read from (#74, see
VAR-44). LANGUAGE.md:651–654 says the point of this is to close the
class where the tracked type disagrees with the runtime value — "which
previously produced a wrong number on screen at best and a segfault at
worst".

```
a list called counts is [1, 2].
a text called label is "x".
label is element 1 of counts.
Print label.
```

Compiles with no diagnostic; **exits 139, SIGSEGV, on every run** (three
runs, three core dumps). The integer 1 is being dereferenced as a string
pointer.

The machinery is not missing — it is not wired to lists. `D1b.vox` is the
same read against a **map** whose value types are uniformly text:

```
a map called names is {"a": "one", "b": "two"}.
a number called counted is 5.
counted is names's "a".
```

→ `error: cannot assign text to 'counted', which is a number`. So the map
path proves uniformity and rejects; the list path does not.

Reading the compiler as correct: "provably uniform" could be a claim about
what the compiler *can* prove rather than what it *does* prove in every
position, and a list variable is tracked as `list` rather than `list of
text`, so the element type genuinely is not in the type it carries — the
map path may be getting its answer from the literal rather than from the
variable's type. Under that reading LANGUAGE.md:644's parenthetical is
over-promising and the code is consistent. That reading does **not** rescue
LANGUAGE.md:651–654, which says the segfault case is closed; it is not.

This is a memory-safety violation on a program the compiler accepted, which
by `CLAUDE.md` is top severity regardless of how the type rule is read.

**Resolution confirmed, 2026-08-22: fixed by vox #54.** `vox/docs/
BUGS_FOUND.md` #54 ("A list element read into a variable of another type
segfaults") names this exact repro. Re-run `D1.vox`/`VAR-46.vox` against
vox 0.4.9: `label is element 1 of counts.` is now refused at compile
time — `error: cannot assign number to 'label', which is a text` — the
list path now proves uniformity and rejects, matching the map path
(`D1b.vox`) that already worked. The segfault is gone.

### 2. `For each NAME in <collection>` does not type-check the rebinding — STILL OPEN, symptom changed by vox #54's side effect

`D2.vox`, and `VAR-34.vox` for the consequence. LANGUAGE.md:609–612: "This
isn't limited to reassignment. Any construct that binds a name to a new
runtime value is checked the same way: reusing an already-declared name as
a `For each`/for-range loop variable … reject[s] a type that conflicts with
the name's existing declaration."

```
a number called counted is 5.
a list called words is ["alpha", "beta"].
For each counted in words,
  a number called ignored is 0.

Print counted.            → beta
Print counted's type.     → Number (static)
```

The for-**range** half of the same sentence does reject (`VAR-35.vox`), so
the two halves of one claim behave differently. After the loop, `counted`
holds a text pointer while still reporting `Number (static)`, and
`counted add 1` prints a raw address (`VAR-34.vox`). No crash, but this is
the "wrong number on screen" half of the class LANGUAGE.md:651–654 says is
closed.

Reading the compiler as correct: the same argument as Discrepancy 1 — the
element type of a `list` is not part of what the compiler tracks, so there
is nothing to compare against, and the for-range case is checkable only
because a range is a number by construction. If that is the intended
reading then LANGUAGE.md:609–611 should say "for-range" and not "`For
each`", because as written it promises a check that is not there.

**Still open on vox 0.4.9, re-verified 2026-08-22 — but the *symptom*
changed as a side effect of vox #54's fix to Discrepancy 1.** `D2.vox`
itself (`Print counted.` / `Print counted's type.` after the loop) is
byte-identical to the original finding: `beta` / `Number (static)`, no
rejection. What changed is `VAR-34.vox`'s downstream consequence —
`counted add 1` used to silently print a raw address; #54 made the
analyzer track the element type through the loop *body* (not the
*header*), so that same arithmetic is now a clean compile error,
`Cannot use text counted in arithmetic; cast it first with 'as a number'
or 'as a float'.` The "wrong number on screen" half of LANGUAGE.md:651–654's
promise is closed; the loop-header rejection LANGUAGE.md:609–612 itself
promises is not — this matches `vox-notes/REPORT-CANDIDATES-0.4.10.md`
candidate C exactly ("`#54` closed the wrong-value consequence, not the
rejection") and its own re-check: "On 0.4.9 the same program is `error:
Cannot use text counted in arithmetic...`. So #54 removed the raw
address. What it left is the acceptance of the loop header itself."
**This is the brief's "variables D2," and I could not find a register
number for it** — it is not among the `fix/bug-66-*`…`fix/bug-90-*`
branches present in the vox repo, and it is a genuine bug (not a design
question), so it is not in `candidates-round-4.md`'s open-questions list
either (that list is design questions only). Recorded honestly as
adjudicated-but-unassigned rather than guessing a number.

### 3. `Allocate N for X` is let through onto a buffer, and zeroes its capacity

`D3.vox`. LANGUAGE.md:611–613 names "the target of `Allocate ... for`"
among the bindings that reject a conflicting type.

```
a buffer called room is 8 bytes in size.
Print room's capacity.      → 8
Allocate 64 for room.
Print room's capacity.      → 0
Print room's type.          → Buffer (static)
```

An 8-byte buffer silently becomes a 0-byte one, with no diagnostic.

A text or list target **is** rejected (`VAR-37.vox`: `cannot bind 'label'
to a number in this Allocate statement`), and the message reveals the rule:
`Allocate` binds its target **as a number** holding a raw address. That
makes a *number* target genuinely not a conflict — `a number called room is
5.` followed by `Allocate 64 for room.` leaves `room` holding an address
like 140491170975744, which is the compiler doing exactly what the rule
says. The buffer case is the one that escapes: `buffer` is exempted from
assignment checking by LANGUAGE.md:626–629, but that exemption is written
about *writing a value into a buffer*, which is not what `Allocate` does.

Reading the compiler as correct: if the buffer exemption is implemented as
"buffer names are exempt from every binding check" rather than "writes into
a buffer are a format operation", then this falls out of the exemption and
the manual's phrasing at 581–584 is too narrow. The capacity going to 0
still deserves a look on its own.

Separately: `Allocate` appears in LANGUAGE.md **only** at line 567. The
manual references a construct it never defines — its syntax
(`Allocate <size> [for] <name>`) had to be read out of
`../vox/src/parser/statements.rs:423` (the compiler repo, not this one). That is a documentation gap in its own
right.

### 4. Reserved keywords are rejected as declaration names but accepted as loop variables

`D4.vox`. LANGUAGE.md:670–672: "A **bare identifier** … is not a reserved
keyword. Reserved keywords remain rejected as names".

```
For each number from 1 to 3, Print number.     → 1 2 3
a number called number is 5.                   → error: Cannot use 'number' as a
                                                 variable name - it's a reserved keyword.
```

The generator already depends on the permissive half: `src/gen_flow.vox`
lines 426 and 434 emit exactly that loop, so every campaign that reaches
the loop-control leaves binds a reserved word as a name.

Reading the compiler as correct: rule 2 is stated inside the *Naming Rules*
table, whose subject is what a name may look like when a name is being
*introduced by a declaration*; a loop variable is bound by a construct that
already knows a number is coming and has no ambiguity to resolve. Under
that reading the manual's "remain rejected as names" is scoped too broadly
and should say "as declared variable names". Recorded because either the
scope or the compiler is wrong, and a fuzzer that emits reserved words as
loop names should know which.

### 5. `see` paths and `version` strings accept single-quoted identifiers

`VAR-63.vox` (runnable) and `D5.vox` (the version half, transcript only —
it needs a built `.lib`). LANGUAGE.md:683–685 lists file paths and versions
among the things that are "data, not names" and "stay double-quoted", and
LANGUAGE.md:659–660 promises the three name forms have "no overlap, no
context-sensitivity".

```
see './fixtures/helper.vox'.       → the include happens; the fixture prints
see kit version '1.0' from "./libkit.lib".   → compiles
see kit version '9.9' from "./libkit.lib".   → Error: … has library "kit" but not
                                               version "9.9". Available: "1.0".
```

The `'9.9'` failure is what proves the token was consumed as *data*: it was
matched against the library's version list, not treated as an identifier.
Map keys (`VAR-62.vox`) and flag aliases (`VAR-64.vox`) do enforce the
double-quoting; `see` paths and versions do not. So a single-quoted token
means an identifier in most positions and a data string in `see`/`version`
position, which is context-sensitivity of exactly the kind 612–613 rules
out.

Reading the compiler as correct: rule 6 could be read as style advice —
"stay double-quoted" as a recommendation about how to write data, not a
statement about what the parser rejects — and the parser being lenient
where no identifier could possibly be meant is harmless. The
"no context-sensitivity" sentence is the harder one to rescue, since it is
stated as a property of the language and not as advice.

### 6. The type-mismatch diagnostic places its caret by searching the source text

`D6.vox`. LANGUAGE.md:595–603 shows the caret under the offending
statement. It is instead placed at the **first textual occurrence** of that
statement anywhere in the file — including inside a comment:

```
(this comment mentions n is "abc". on purpose)
a number called n is 5.
n is "abc".
Print n.
```

```
error: cannot assign text to 'n', which is a number
  --> prog.vox:1:24
  1 | (this comment mentions n is "abc". on purpose)
    |                        ^ this assigns text
  note: 'n' was declared as a number at prog.vox:2:17
```

`D6.vox` is the same thing inside a retained probe: its header comment
carries a copy of the statement on line 7, and the caret lands there
(`--> D6.vox:7:4`) rather than on line 21, where the statement actually is.

The `note:` line points at the real declaration, so the two halves of one
diagnostic disagree about where the program is. The same happens to the
reserved-leading-underscore message (`D9.vox`). This bit while writing this
ledger: `VAR-26.vox`'s header comment originally quoted the statement it
was about, and the probe's own documentation stole the caret.

Reading the compiler as correct: there is no reading in which line 1 is the
right answer. The mildest version is that this is cosmetic — the message,
the note and the help are all correct and only the span is misplaced — but
it misleads exactly when a program is long enough to need the caret.

### 7. There are more than "Two Canonical Forms", and one of them is undocumented

`D7.vox`. LANGUAGE.md:496–506 is headed "Two Canonical Forms" and describes
the no-initializer form only under `Create`. Accepted in fact:

| lead-in | `is V` | `to V` | no initializer |
|---|---|---|---|
| *(none)* — `a`/`an` | yes | **no** — misleading diagnostic, below | **yes, undocumented** |
| `Set a` | yes | yes | yes |
| `Create a` | yes | yes | yes (the documented one) |

`a number called n.` compiles and takes the default, and nothing in the
section says so. The two spellings are also not diagnostically equal: `a
buffer called warned.` emits `Warning: Buffer "warned" declared without size
or initializer. This creates a zero-capacity buffer which may not be
useful.` while the documented `Create a buffer called unwarned.` emits
nothing — for the same resulting buffer, capacity 4096 either way.

And the one rejected cell has a diagnostic that points somewhere else
entirely: `a number called n to 9.` reports `Missing function name after
'To'`, because `to` in that position is lexed as the function-definition
keyword.

Reading the compiler as correct: "canonical" may mean "the two forms we
recommend" rather than "the two forms that parse", in which case the extra
spellings are tolerated non-canonical input and the section is describing
style. The buffer warning asymmetry survives that reading: if `Create a
buffer called N.` is the canonical way to get a default buffer, warning on
its documented equivalent is backwards.

### 8. `timer` supports only one of the two canonical forms

`D8.vox`. LANGUAGE.md:496: "Every declarable type supports two equivalent
forms". `a timer called clock is 0.` → `error: Expected a statement, got
Is`. There is no initializer form for a timer at all.

Reading the compiler as correct: the section already carves out `file` and
`time` as types that support only *one* of the two forms, so "every" is
known to be loose by line 503. A timer has no literal to be initialized
from, exactly as a file has no default to fall back on — so the carve-out
list is simply incomplete rather than the compiler being wrong. Cheap to
fix in the manual; recorded because a mapper reading 469 literally would
write a leaf that does not compile.

### 9. A bare identifier may not start with an underscore

`D9.vox`. LANGUAGE.md:670 gives the bare-identifier set as
`[A-Za-z_][A-Za-z0-9_]*`, which admits a leading underscore.

```
a number called _start is 1.
→ error: Variable name '_start' starts with '_', which is reserved for the
  Vox runtime; choose a name without the leading underscore.
```

Underscores anywhere else in the name are fine (`a_b_9`, `VAR-53.vox`), so
only the leading position disagrees.

Reading the compiler as correct: reserving a leading underscore for runtime
symbols is ordinary and deliberate — the message says so — and the regex in
the manual is a lexical description that the name-resolution pass then
narrows, the same way it narrows the set by rejecting reserved keywords
(which the regex also admits). Under that reading the manual is
under-specified rather than wrong, and should give the set as
`[A-Za-z][A-Za-z0-9_]*` or state the reservation next to it. Worth fixing
because a generator that varies name shapes across the stated set will emit
non-compiling programs.

## Invariants this section justifies

Samenesses the manual actually requires, for the `citation` column of
`scripts/invariants`:

- no generated variable name is ever double-quoted — LANGUAGE.md:664, 668, VAR-49, VAR-52
- no generated bare name begins with a digit — LANGUAGE.md:670, VAR-53
- no generated bare name is a reserved keyword **in declaration position** — LANGUAGE.md:670–672, VAR-54 (loop-variable position is exempt in fact — D4)
- no generated quoted name is a single character — LANGUAGE.md:673–676, VAR-58
- no generated quoted name contains a newline — LANGUAGE.md:674, VAR-57
- every generated `file` or `time` declaration carries an initializer — LANGUAGE.md:533–536, VAR-17, VAR-18
- no generated `timer` declaration carries an initializer — LANGUAGE.md:529, VAR-16, D8
- a generated name is never redeclared, or rebound by a loop / `open` / `Allocate`, at a conflicting type — LANGUAGE.md:577–582, 609–615, VAR-25, VAR-34–VAR-39
- map keys and flag aliases in generated programs are always double-quoted — LANGUAGE.md:683–685, VAR-62, VAR-64

One sameness the corpus will show that the **manual does not justify** but
the compiler requires: no generated bare name begins with `_`. That is
Discrepancy 9; until it is adjudicated the invariant report should cite the
compiler diagnostic, not a LANGUAGE.md line.

## Report

**66 rows** (VAR-01 … VAR-66). One (VAR-66) is a cross-reference folded
into VAR-48, leaving **65 distinct claims**.

**Assertable: 40 of 65.** By status: **17 exercised, 0 verified, 25 todo,
23 not assertable**, one folded.

The 24 rows whose `assertable?` is a flat no are not an accident of
coverage, they are structural: **21 of them are claims about what the
compiler rejects**, and a leaf that emits one produces a program that does
not compile, which breaks the generator's standing contract that a
generated program is legal Vox that should compile and run. Those rows say
so in the column rather than sitting at `todo`, so a future leaf worker
does not try to build them. The other three are VAR-44 (a claim about the
boundary of a compile-time check, with compile errors on one side and
sanctioned garbage on the other) and VAR-47 / VAR-65 (need a second
compilation unit). VAR-45 sits between the two: worthless as a correctness
oracle, because the manual sanctions the garbage it produces, but worth a
leaf as a **crash** oracle. VAR-66 is the fold.

**Existing coverage is thin and lopsided.** The declaration form `a TYPE
called NAME is VALUE.` is emitted by every leaf in the generator and the
other five accepted spellings are emitted by none. Concretely, `grep` over
every emitted string literal in `src/gen_*.vox` finds **zero** occurrences
of: the article `an`; the lead-in `Set a` or `Create a`; the assignment
form `the x is …`; the bare reassignment form `x is …`; the in-place
retype `x is a <type>.`; a character literal; a quoted reserved word; a
possessive on a quoted name; `Allocate`; `see`; `a file called … is …`; `a
time called … is …`. Every one of those is a documented form of this
section that no generated program has ever contained.

**The biggest finding is Discrepancy 1**: a four-line program that the
compiler accepts and that segfaults deterministically. It is exactly the
failure LANGUAGE.md:651–654 says the type-immutability rule closed, and it
is reachable from a list literal with uniform elements — an extremely
ordinary shape. That is a broken memory-safety promise, which `CLAUDE.md`
ranks above everything else here.

**Nine discrepancies is a lot for one section**, and the shape of them is
worth naming: seven of the nine are places where the manual states a rule
more broadly than the compiler enforces it (`For each`, `Allocate`,
reserved keywords, `see`/`version` quoting, the identifier regex, "two
canonical forms", "every declarable type"). This section is unusually
declarative — it is mostly rules about rules — and each such sentence is a
universal quantifier that one counter-example falsifies. Expect the same
density in `KEY` (keywords) and `GRM` (grammar summary), which are the
other two rule-about-rules sections.

**Advice for the next mapper.**

1. **Grep emitted strings, not the file.** The generator is written in Vox,
   so `grep 'a number called' src/gen_*.vox` returns 300 hits of which
   almost none are emitted. The only reliable query is for the pattern
   *inside a double-quoted literal*:
   `grep -ohn '"[^"]*called[^"]*"' src/gen_*.vox`. Doing this the naive way
   would have marked a dozen rows here `exercised` that are in fact `todo`.
2. **Sort compile-error claims out first.** In a rule-heavy section, most
   claims are about rejection, and they are all `not assertable` for the
   same reason. Deciding that once, up front, is quicker than arguing it
   per row — and it stops the ledger from promising leaves that cannot
   exist.
3. **Do not quote the offending statement in a probe's header comment.**
   Discrepancy 6 means a comment that echoes the code steals the
   diagnostic's caret, and the probe then documents the wrong thing. Two
   probes here had to be rewritten for it.
4. **Check both halves of a compound claim.** Three of the nine
   discrepancies are one half of a sentence holding and the other half not
   — for-range vs `For each … in`, map reads vs list reads, map keys vs
   `see` paths. A sentence that names two constructs is two rows' worth of
   probing even when it is one row.
5. **The compiler's diagnostics are a better spec than the manual here.**
   `Allocate`'s syntax is not in LANGUAGE.md at all; its rejection message
   (`this allocates a number`) is what revealed that `Allocate` binds a
   number, which is what makes the number-target case correct rather than a
   bug. Read the error text, not just the exit status.
