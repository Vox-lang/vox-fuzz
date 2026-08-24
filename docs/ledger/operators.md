# Claim ledger: Operators

Source: `../vox/LANGUAGE.md` lines **4633–4696**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual) — Operators § Arithmetic Operators,
Comparison Operators, Logical Operators, Bitwise Operators, and the
worked **Examples** block.

The 0.4.8→0.4.9 drift in this range is a uniform **+87 lines**, confirmed
at multiple anchors. All 3 discrepancies (still unadjudicated — no prior
lawyer verdict) re-verified unchanged via the full `docs/check-probes.sh`
sweep: 46/46 pass, no manual or compiler drift found. (Discrepancy 1,
`isn't`/`aren't` not lexing, matches `vox-notes/REPORT-CANDIDATES-
ROUND-3.md` candidate N — `candidates-round-4.md` still lists it as an
open design question today, "keep (document) or drop," not a numbered
fix.)

Compiler used for every probe: `vox v0.4.8`
(`/home/josj/scr/english/vox/target/release/vox`, git
`v0.4.8-4-g34f9831`), `VOX_CORE_PATH` pinned to
`/home/josj/scr/english/vox/coreasm`.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct, or `none`, and was determined
by grepping for the operator keyword **inside the emitted string
literals** of `src/gen_*.vox` — not by leaf name, and not by the
generator's own use of the operator in its own source. That distinction
matters here more than in most sections: `add`, `multiply` and `modulo`
appear hundreds of times in `src/gen_*.vox` as the generator doing its
own arithmetic, and almost none of those occurrences put anything into a
generated program.

**No existing leaf asserts an operator result.** `gen expr`, `gen deep
expr`, `gen leaf deep arithmetic` and `gen leaf float arithmetic` all
`Print` their expression for a human to eyeball; `gen condition` feeds a
comparison to an `If` whose branch prints a fixed string. The one
exception in the whole generator is `gen emit argv assertions`
(`src/gen_misc.vox:316–321`), which does assert — with bare `is not`
and bare `is` — and it is the reason OPR-12 and OPR-14 are the only
rows in this ledger that come close to `verified` already. Nothing here
is marked `verified`, because that flip belongs to a campaign
(PROCEDURE.md §7), not to a mapper.

## Probes

Every row's probe is retained and runnable in
`docs/ledger/probes/operators/`, one file per row named `OPR-NN.vox`,
in PROCEDURE.md §4 format: a `(...)` header naming the claim, the exact
`Ran:` command, and an `expected output:` block recording what the
compiler **actually** printed. Compile-error rows are probes too and
record the diagnostic. The three discrepancies each have a minimal
repro at `D1.vox`, `D2.vox`, `D3.vox`.

There is one extra, non-row file: **`assertion-shape.vox`**. It is not a
claim; it is the two assertion shapes the `assertable?` column names
below, proven to compile and to reach exit 95. It exists because
**OPR-40 makes the obvious shape illegal** — a comparison is not a
first-class expression in Vox, so a comparison row *cannot* be asserted
as `If <comparison> is not true then, ... Exit 95.`; it has to route
through a witness variable. A leaf worker who does not know this will
write eight leaves that do not compile. Read that file before writing
any comparison or logical leaf.

**46 files, 46 rows of recorded output, and all 46 re-run clean** under
`VOX=… VOX_CORE_PATH=… docs/check-probes.sh docs/ledger/probes/operators`
— 46 passed, 0 failed, 0 skipped. (Note that `check-probes.sh`'s own
default `VOX` path does not resolve from this worktree; both variables
have to be passed explicitly.)

Every row in this ledger has a probe. Nothing in this section is an
implementation detail, so there is no `not assertable` row of the
BUF-04 "unobservable from inside Vox" kind. Six rows carried the status
`not assertable` through 0.4.9 (OPR-22, OPR-23, OPR-34, OPR-40, OPR-41,
OPR-42): their outcome was a **compile error**, which no runtime leaf
could be built to carry, so the probe recorded the diagnostic and the
harness — not a generated program — was what would notice a change.
**As of 0.4.10, OPR-22, OPR-23 and OPR-41 all RESOLVED (vox #84, #84,
#77) and became ordinary assertable rows** — the compiler was fixed to
match the manual, rather than the manual needing correction. OPR-34,
OPR-40 and OPR-42 still carry the status `not assertable`. Of those
three, **one** (OPR-34) is a row where the manual's claim is
**contradicted** by the compiler — down from three of six before
0.4.10, since OPR-22 and OPR-23 were the other two contradicted rows and
are now resolved. PROCEDURE.md's status ladder has no value for that, so
it is said in the row rather than invented as a new status, the way
`buffers.md` handled BUF-02.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| OPR-01 | 4861 | `add` is the addition operator. | emit `x add y` and assert the sum | yes — `If lhs add rhs is not 26 then, Print "ASSERT OPR-01: expected 26", Exit 95.` | `gen expr` (choice 0), `gen deep expr`, `gen append expr`, `gen leaf float arithmetic`, `gen leaf deep arithmetic` — all `Print`, none assert | exercised | |
| OPR-02 | 4861 | `plus` is an accepted spelling of addition. | emit `x plus y` and assert the sum | yes — same shape as OPR-01 | **none** — every `plus` in `src/gen_*.vox` is prose in a comment; the spelling is never emitted | todo — hand-verified to work | |
| OPR-03 | 4862 | `subtract` is the subtraction operator. | emit `x subtract y` and assert the difference | yes — `If lhs subtract rhs is not 14 then, … Exit 95.` | `gen emit prelude thing methods` (`src/gen_things.vox:131`) emits exactly one hardcoded `0 subtract original's x1`, never asserted and never varied | exercised (one fixed instance) | |
| OPR-04 | 4862 | `minus` is an accepted spelling of subtraction. | emit `x minus y` and assert the difference | yes — same shape | `gen expr` (choice 1), `gen deep expr`, `gen append expr` | exercised | |
| OPR-05 | 4863 | `multiply` is the multiplication operator. | emit `x multiply y` and assert the product | yes — `If lhs multiply rhs is not 120 then, … Exit 95.` | `gen expr` (choice 2), `gen deep expr`, `gen append expr`, `gen leaf float arithmetic`, `gen leaf deep arithmetic` | exercised | |
| OPR-06 | 4863 | `times` is an accepted spelling of multiplication. | emit `x times y` and assert the product | yes — same shape | `gen expr` (choice 3), `gen deep expr`; deliberately excluded from `gen append expr` — see OPR-41 | exercised | |
| OPR-07 | 4864 | `divide` is the division operator. | emit `x divide y` with a nonzero divisor and assert the quotient | yes, but the generator must apply OPR-35's truncation rule to compute the expected value | `gen deep expr` (choice 4, safe divisor 2–10), `gen leaf float arithmetic` | exercised | |
| OPR-08 | 4865 | `modulo` is the modulo operator. | emit `x modulo y` and assert the remainder | yes — `If lhs modulo rhs is not 2 then, … Exit 95.` | `gen deep expr` (choice 5), `gen condition` (the `… modulo m is equal to 0` check), `gen leaf deep arithmetic` | exercised | |
| OPR-09 | 4865 | `mod` is an accepted spelling of modulo. | emit `x mod y` and assert the remainder | yes — same shape | **none** — never emitted | todo — hand-verified to work | |
| OPR-10 | 4865 | `remainder` is an accepted spelling of modulo. | emit `x remainder y` and assert the remainder | yes — same shape | **none** — the string `remainder` does not occur anywhere in `src/gen_*.vox` | todo — hand-verified to work | |
| OPR-11 | 4871 | `is equal to` tests equality. | emit the comparison in an `If` on operands known equal **and** on operands known unequal | yes, via the witness shape (OPR-40 forbids the direct one): `a number called witness is 0. If lhs is equal to rhs then, Set witness to 1. If witness is not 1 then, … Exit 95.` | `gen condition` (comparison choice 2) | exercised | |
| OPR-12 | 4871 | bare `is` is an accepted spelling of equality. | emit `If x is y` on both a matching and a non-matching pair | yes — witness shape | `gen emit argv assertions` (`src/gen_misc.vox:319`, `If fl{n}on is false then, Exit 93.`) — and this one **does** assert, but only against a boolean literal, never against another variable or a number | exercised (boolean-literal operand only) | |
| OPR-13 | 4872 | `is not equal to` tests inequality. | emit the comparison both ways round | yes — witness shape | `gen condition` (comparison choice 3) | exercised | |
| OPR-14 | 4872 | bare `is not` is an accepted spelling of inequality. | emit `If x is not y` both ways round | yes — witness shape | `gen emit argv assertions` (`src/gen_misc.vox:316–317`) — asserts against a text literal and a number literal, exits 91/92 | exercised (literal operands only; never variable-vs-variable) | |
| OPR-15 | 4873 | `is greater than` is a **strict** greater-than. | emit it on a greater pair, an equal pair and a lesser pair | yes — witness shape, one per case | `gen condition` (comparison choice 0) — never on an equal pair, so strictness is not pinned | exercised (strictness untested) | |
| OPR-16 | 4874 | `is less than` is a **strict** less-than. | as OPR-15 | yes — witness shape | `gen condition` (comparison choice 1) — same gap | exercised (strictness untested) | |
| OPR-17 | 4875 | `is greater than or equal to` admits the equal case. | emit it on greater, equal and lesser pairs | yes — witness shape; the equal case is the one that distinguishes it from OPR-15 | `gen condition` (comparison choice 4) — operands are two random variable references, so the equal case is hit only by coincidence and never checked | exercised (the equal case, which is the whole claim, is untested) | |
| OPR-18 | 4876 | `is less than or equal to` admits the equal case. | as OPR-17 | yes — witness shape | `gen condition` (comparison choice 5) — same gap | exercised (equal case untested) | |
| OPR-19 | 4882 | `and` is logical conjunction. | emit all four rows of the truth table and assert which fire | yes — witness shape per row | `gen condition` (joiner choice 1) joins a comparison with a modulo check; the operand truth values are whatever the random variables give, so no row of the table is ever pinned | exercised (truth table untested) | |
| OPR-20 | 4883 | `or` is logical disjunction. | as OPR-19 | yes — witness shape per row | `gen condition` (joiner choice 2) — same gap | exercised (truth table untested) | |
| OPR-21 | 4884 | `not` is logical negation. | emit `If not <condition>` on a true and on a false condition | yes — witness shape | **none** — prefix `not` is never emitted into a generated program (the only ` not ` in emitted text is the `is not` of OPR-14 and the word "not" inside an error message string) | todo — real gap, hand-verified to work | |
| OPR-22 | 4884 | **Claim reversed, 2026-08-22 (0.4.10, #84) — Discrepancy 1 RESOLVED.** `isn't` is an accepted spelling of `not`, and now compiles: `If lhs isn't rhs then,` works exactly as `If lhs is not rhs then,` would. Before #84, the lexer split the apostrophe off as a structural token (the possessive marker / quoted-name delimiter) before word lookup, so `isn't` lexed as `Identifier("isn")`, `Apostrophe`, `Identifier("t")` and the keyword table entry for it was dead code. | emit `If x isn't y then,` on a matching and a non-matching pair, assert the branch | yes — witness shape, same as OPR-21 | none — `isn't` is never emitted by any leaf | todo — **hand-verified fixed against 0.4.10** (`D1.vox`, re-run): compiles and fires correctly | |
| OPR-23 | 4884 | **Claim reversed, 2026-08-22 (0.4.10, #84) — Discrepancy 1 RESOLVED.** `aren't` is an accepted spelling of `not`, and now compiles in the plural `are` position (LANGUAGE.md:1988): `If lhs, rhs aren't 3 then,` works exactly as `are not` would. Same underlying fix as OPR-22. Note: the two undocumented contractions `doesn't`/`don't` that sat beside `isn't`/`aren't` in the lexer's keyword arm but never in the manual's table were **removed** rather than fixed — they still do not compile, correctly, since the manual never promised them. | emit the plural-`are` form with `aren't`, assert the branch | yes — witness shape | none — `aren't` is never emitted by any leaf | todo — **hand-verified fixed against 0.4.10**: `If lhs, rhs aren't 3 then,` compiles and fires correctly on a true predicate; `doesn't`/`don't` re-verified still refused (`Expected a statement, got Apostrophe`), as the manual never listed them | |
| OPR-24 | 4899 | `bit-and` is bitwise AND. | emit `x bit-and y` on known operands and assert the result | yes — `If lhs bit-and rhs is not 160 then, … Exit 95.` | **none** — `bit-and` does not occur anywhere in `src/gen_*.vox` | todo — real gap | |
| OPR-25 | 4900 | `bit-or` is bitwise OR. | as OPR-24 | yes | **none** | todo — real gap | |
| OPR-26 | 4901 | `bit-xor` is bitwise XOR. | as OPR-24 | yes | **none** | todo — real gap | |
| OPR-27 | 4902 | `bit-shift-left` shifts left. | emit `x bit-shift-left n` and assert; keep `n` under 64 or apply OPR-37 | yes | **none** | todo — real gap | |
| OPR-28 | 4903 | `bit-shift-right` shifts right. | as OPR-27 | yes | **none** | todo — real gap | |
| OPR-29 | 4907–4908 | The example's binary literals are legal number initialisers carrying the values the section then relies on (`0b11110000` is 240, `0b10101010` is 170). | declare a number from a `0b` literal and assert its decimal value | yes — `If lhs is not 240 then, … Exit 95.` | **none** emits a `0b` literal; `gen leaf base convert` in `src/gen_text.vox` covers `as a binary number` **casting from text**, a different construct | todo — composite with the Expressions section (LANGUAGE.md:1906, 1915) | |
| OPR-30 | 4911 | A bitwise expression is legal as a **declaration initialiser** (`a number called result is lhs bit-and rhs.`). | emit the declaration form, not just a `Print` | yes — assert `result` afterwards | **none** | todo | |
| OPR-31 | 4914, 4917, 4920, 4921 | A bitwise expression is legal as a **`Set … to …` value**, and a variable may be reassigned through all five operators in turn. | emit the four `Set` lines of the example and assert after each | yes — four assertions | **none** | todo | |
| OPR-32 | 4920–4921 | The shift count may be an integer literal. | emit a literal shift count; also emit a **variable** shift count, which the manual never shows | yes | **none** | todo — hand-verified that the variable form works too | |
| OPR-33 | 4924 | Bitwise operations **chain without braces**, associating left to right (`value bit-shift-right 8 bit-and 0xFF`). | emit a two-operator chain with no `{...}` and assert; pick operands that distinguish left- from right-association | yes, and the probe already carries the discriminating case: `240 bit-shift-right 4 bit-and 3` is 3 left-to-right and would be 240 right-to-left | **none** — `gen deep expr` chains arithmetic but never bitwise, and always brackets with `{...}` when `grouped` is true | todo — the unbraced chain is the interesting half and nothing emits it | |
| OPR-34 | 4906–4925 | The worked example, as a whole, compiles and does what the surrounding prose says. | reproduce verbatim | **no** — it does not compile. See **Discrepancy 2** | none | not assertable — the block does not compile; **the manual's claim is contradicted**, blocked on D2. Every individual line of it is covered by OPR-29/30/31/32/33 and all of those pass | |
| OPR-35 | 4864 (undocumented precision) | *(gap in the manual)* Integer `divide` truncates **toward zero** (`-7 divide 2` is `-3`, not `-4`), and **dividing by zero yields 0** with no crash and no halt. | emit a division with a zero divisor and assert the result is 0 and the program continues; emit a negative dividend and assert the truncation direction | yes — the generator picks both operands | **none** — `gen deep expr` and `gen leaf float arithmetic` both deliberately force a nonzero divisor (see their own comments), and no leaf emits a negative dividend | todo — real gap, and the zero-divisor case is memory-safety-relevant | |
| OPR-36 | 4865 (undocumented precision) | *(gap)* `modulo` **by zero yields 0** with no crash, and a negative dividend gives a **negative** remainder (`-7 modulo 3` is `-1`; the sign follows the dividend). | emit modulo by zero and assert 0; emit a negative dividend and assert the sign | yes | **none** — `gen condition`'s modulo check forces a modulus of 2–6 and a nonnegative left operand | todo — real gap | |
| OPR-37 | 4902–4903 (undocumented precision) | *(gap)* **Shift counts are taken modulo 64.** `1 bit-shift-left 64` is 1; `1 bit-shift-left 100` is `1 bit-shift-left 36`; a negative count wraps the same way (`16 bit-shift-right -2` is `16 bit-shift-right 62`, i.e. 0). The manual states no bound on the count. | emit shift counts at, above and below 64 and assert against the mod-64 rule | yes — but **only if the generator applies the mod-64 rule when computing its expected value**. A leaf that draws a random shift count and asserts `x << n` naively will manufacture false findings the moment `n` reaches 64. | **none** | todo — this row is the trap in this section; write it before writing OPR-27/28's leaves, not after | |
| OPR-38 | 4895–4903 (undocumented precision) | *(gap)* **Every bitwise operator applied to a float operand yields `0.0`**, whatever the operands — the float is neither truncated to an integer nor refused. `6.0 bit-and 4` is `0.0` where `6 bit-and 4` is `4`. | emit a bitwise operation with a float operand | yes — assert `0.0`, but see **Discrepancy 3**: encoding this as an oracle encodes a behaviour nobody has blessed | **none** — `gen leaf float arithmetic` never reaches a bitwise operator | todo — **blocked on D3**; do not build a leaf that asserts `0.0` until the discrepancy is adjudicated | |
| OPR-39 | 4878–4884 (table gives no precedence; prose precedence is at LANGUAGE.md:1972–1978, #83 RESOLVED) | **Claim narrowed, 2026-08-22 (0.4.10, #83).** The *table* still gives three operators and no precedence at all — that half of the gap stands. But `not`'s precedence specifically is documented in prose elsewhere (LANGUAGE.md:1972–1978: "`not` binds looser than every comparison and property check, and tighter than `and` and `or`") and, as of 0.4.10, the **compiler now implements exactly that** — before #83, `not` was parsed as an operator on a primary, so `If not v1 is v2 then,` compiled as `(not v1) is v2` (false whatever the operands) instead of `not (v1 is v2)`, and `not <comparison>` had no working spelling at all. | emit a three-term condition whose truth value differs under the two readings, and assert which branch fires; separately, emit `not <comparison>` (e.g. `not v1 is v2`) and assert it reads as `not (v1 is v2)`, not `(not v1) is v2` | yes — witness shape; `affirmed or denied and denied` is the discriminator (true under `and`-tighter, false left-to-right); `not v1 is v2` with `v1 ≠ v2` is a second, sharper discriminator (true under the correct reading, false under the old broken one) | `gen condition` emits exactly one join of exactly two conditions, so a three-term condition is never built and precedence is never exercised; no leaf emits `not` in front of a comparison at all | todo — **hand-verified fixed against 0.4.10**: `not v1 is v2` (v1=4, v2=6) now fires the "not-equal" branch, confirming `not` binds the whole comparison; `not flag1 and flag2` (flag1=false, flag2=true) fires, confirming `not` binds tighter than `and` | |
| OPR-40 | 4867–4876 (undocumented precision) | *(gap)* The comparison operators are **not first-class expressions**: a comparison parses only in a condition position. `Print lhs is greater than rhs.` and `a boolean called ordered is lhs is greater than rhs.` are both compile errors, while the arithmetic and bitwise operators are legal anywhere a value is. The Operators section presents the four tables as peers and says nothing about this. | — | **no** — the outcome is a compile error. But this row governs the `assertable?` answer for OPR-11 through OPR-21 and for OPR-19/20/21, which is why it is here rather than in the Expressions ledger | the restriction is already known to the generator — `gen condition`'s own comment (`src/gen_core.vox:170–176`) records hand-verifying it against 0.4.5 — but it is nowhere in the manual | not assertable — a compile error is the outcome; **manual gap**, reproduces on 0.4.8 | |
| OPR-41 | 4863 (undocumented precision) | **Claim reversed, 2026-08-22 (0.4.10, #77) — RESOLVED.** A limit on OPR-06 that used to hold: `times` was **rejected in the value slot of `append <value> to <collection>`**, where `multiply` was accepted, because the append slot was parsed by a hand-written copy of the general parser that had fallen behind it. #77 rewrote the append value slot to read one general-expression primary, so `times` (and a negative literal, `nothing`, `element N of`, `byte N of`, a `'s` possessive) now all work there too, exactly as everywhere else. | emit `append x times y to list`, assert the product landed | yes — `If element N of list is not 12 then, Exit 95.` | `gen append expr` (`src/gen_core.vox:139–164`) exists to route around the old limit — now unnecessary but harmless | todo — **hand-verified fixed against 0.4.10** (`OPR-41.vox`, re-run): `append lhs times rhs to tally.` now compiles and appends the product `12` | |
| OPR-42 | 4859–4903 (undocumented precision) | *(gap)* A text, buffer or list operand in a **bitwise** expression is a clean compile error, the same as in arithmetic (`Cannot use text label in arithmetic; cast it first…`). LANGUAGE.md:1911 states this for arithmetic only, far away; the Operators section says nothing about any operator's operand domain. | — | **no** — compile error, and that is the point: the compiler refuses the pointer-as-integer case rather than letting it through | none | not assertable — a compile error is the outcome, and that is the desired one; **manual gap**, the compiler is right and undocumented. Contrast OPR-38, where the float case is neither converted nor refused | |

## Discrepancies

### 1. `isn't` and `aren't` are documented spellings of `not` and do not lex — RESOLVED (vox #84)

LANGUAGE.md:4884 — `| Not | \`not\`, \`isn't\`, \`aren't\` |`. Repro
(`probes/operators/D1.vox`):

```
a number called lhs is 7.
a number called rhs is 3.
If lhs isn't rhs then, Print "isnt fired".
```

```
error: Expected a statement, got Apostrophe
  --> D1.vox:3:11
```

`aren't` fails identically (`OPR-23.vox`), in the plural-`are` position
the Expressions section documents at LANGUAGE.md:2046–2090, and so do
`doesn't` and `don't` — which the lexer also accepts and the manual does
not mention.

The intent is unambiguously in the compiler:
`src/lexer/scan.rs:360` reads

```rust
"not" | "isn't" | "aren't" | "doesn't" | "don't" => Token::Not,
```

so a word-level keyword table claims all four contractions. The word
never gets there. The scanner treats `'` as a structural token before
word lookup — it is both the possessive marker (`name's`,
`src/lexer/scan.rs:118`) and the quoted-name delimiter (`'my nums'`,
`:587`) — so `isn't` lexes as `Identifier("isn")`, `Apostrophe`,
`Identifier("t")` and the keyword arm is dead code.

**The strongest reading in which the compiler is correct:** Vox has
committed the apostrophe to two structural jobs that a general-purpose
identifier language does not have, and an English contraction is
genuinely ambiguous against both — `isn't` is a plausible prefix of a
quoted name, and `x's` is the possessive Vox depends on everywhere. A
lexer that resolved the contraction would have to special-case a closed
list of English words *before* the possessive rule, which is a real
grammar hazard for a language whose whole premise is that names are
English phrases. On that reading the compiler is right to keep the
apostrophe structural, the dead keyword arm is a leftover of an
abandoned attempt, and **the manual is wrong to advertise the
contractions** — `isn't`/`aren't` should come out of the table, and
`not` (which works, OPR-21) is the whole story.

Recorded, not filed, not decided. Note that this is a *documentation*
claim failing, not a memory-safety one: the compiler refuses cleanly
with a located diagnostic.

**Resolution confirmed, 2026-08-22 — RESOLVED by vox #84.**
CHANGELOG.md #84: "Each now lexes as the two words it stands for — `is
not` and `are not` — while the four undocumented contractions that sat
unreachable beside them in the same table (`doesn't`, `don't`, `it's`,
`they're`) were removed rather than woken." So the fix went the opposite
direction from what this discrepancy's "strongest reading" argued for
(that reading proposed removing `isn't`/`aren't` from the manual instead)
— the compiler was changed to match the manual, not the other way
around. Re-ran `D1.vox` verbatim against 0.4.10: `If lhs isn't rhs then,`
now compiles and fires (`isnt fired`), where 0.4.9 refused it with
`Expected a statement, got Apostrophe`. `aren't` confirmed separately in
the plural-`are` position (OPR-23). `doesn't`/`don't` — never documented
— remain refused, correctly.

### 2. The Operators section's only worked example does not compile

LANGUAGE.md:4907–4925. The block declares `lhs`, `rhs` and `result`, and
its last line reads from `value`, which nothing declares. Repro is the
block copied verbatim (`probes/operators/D2.vox`):

```
(Chained operations)
Set result to value bit-shift-right 8 bit-and 0xFF.
```

```
error: Unknown identifier 'value'
  help: did you mean `false`?
```

Every other line of the block compiles and produces the documented
result; OPR-29/30/31/32/33 reproduce them individually and all pass,
including the chained shape once the operand is declared
(`0x12345678 bit-shift-right 8 bit-and 0xFF` is 86).

**The strongest reading in which the compiler is correct:** it plainly
is correct — an undeclared identifier must be an error, and the help
text even offers the nearest name it knows. The reading that saves the
*manual* is that the fenced block is a set of illustrative fragments
rather than one program, with `value` standing in for "any number
variable" the way `<condition>` does in the Logical Operators fragment
at LANGUAGE.md:2040–2044. That reading is weak here: the block is not
marked `vox fragment` (the manual has that marker and uses it at
1820 and 1838), it opens with two real declarations and threads a
single `result` variable through six statements, so it reads as a
program and every other line is one.

Worth noting for the ledger's own sake: a fenced example that does not
compile is exactly the class of defect `vox-preflight` exists to catch,
and this one is in the manual the ledger is mapping *from*.

### 3. Bitwise operators silently return `0.0` for a float operand

Nothing in LANGUAGE.md states the operand domain of the bitwise
operators. LANGUAGE.md:1911 states it for **arithmetic** — "Arithmetic
operates on numbers (booleans count as 0/1). Text, buffers, and lists
must be cast with `as a number` or `as a float` … using them directly is
a compile error" — and says nothing about floats there or about bitwise
anywhere. Repro (`probes/operators/D3.vox`):

```
a float called whole is 6.0.
Print whole bit-and 4.
a number called 'same value as an integer' is 6.
Print 'same value as an integer' bit-and 4.
```

```
0.0
4
```

The same holds for `bit-or`, `bit-xor`, `bit-shift-left` and
`bit-shift-right`, for any operands, integral-valued or not
(`OPR-38.vox`): the result is always `0.0`, and it keeps float type.

So a float operand is the one case that is **neither converted nor
refused**. A text or list operand is a clean compile error (OPR-42); an
integer works (OPR-24–28); a boolean is converted, 0/1, per 1805 —
`true bit-or 2` is 3, hand-verified. Only the float slips through and
produces a wrong-looking answer with no diagnostic.

**The strongest reading in which the compiler is correct:** bitwise
operators are defined over integers, a float is outside their domain,
and the manual has simply never said what happens outside the domain —
so `0.0` is an unspecified result, not a wrong one. There is real
support for this: the operators are code-generated on the integer path,
a float operand arrives in a floating-point register that the integer
instruction reads as zero, and the result is then re-tagged float
because that is the static type of the expression. Under that reading
the compiler is doing something internally consistent and the fix is a
manual sentence plus, arguably, a diagnostic.

**Consequence for leaf work, either way:** OPR-38 must not have a leaf
built until this is adjudicated. Asserting `0.0` would encode
present behaviour as an oracle, and if the verdict is "should be a
compile error" or "should truncate", every generated program carrying
that assertion becomes a false-finding factory — the exact failure mode
CLAUDE.md names. Leaves for OPR-24 through OPR-28 are unaffected as long
as they keep their operands integral, which is the natural thing to do.

## Invariants this section justifies

Almost nothing. This section is a keyword table: it declares
**alternatives**, and every alternative it declares is a dimension the
generator is obliged to vary rather than a sameness it may fix. Stated
positively, so the invariant report has something to cite:

- an arithmetic operator is one of `add`, `plus`, `subtract`, `minus`,
  `multiply`, `times`, `divide`, `modulo`, `mod`, `remainder` — a closed
  vocabulary of ten — LANGUAGE.md:4861–4865, OPR-01…OPR-10
- a comparison operator is one of `is equal to`, `is`, `is not equal
  to`, `is not`, `is greater than`, `is less than`, `is greater than or
  equal to`, `is less than or equal to` — LANGUAGE.md:4871–4876,
  OPR-11…OPR-18
- a bitwise operator is one of `bit-and`, `bit-or`, `bit-xor`,
  `bit-shift-left`, `bit-shift-right` — LANGUAGE.md:4899–4903,
  OPR-24…OPR-28
- a comparison never appears outside a condition position —
  LANGUAGE.md gives no citation for this; it is the compiler's rule
  (OPR-40) and is a **manual gap**, so the invariant report should carry
  it as `OPR-40 (undocumented)` rather than as a clean citation
- `times` never appears in an `append … to …` value slot — **this
  invariant is now STALE, 2026-08-22 (0.4.10, #77 resolved OPR-41):**
  `append x times y to list.` compiles and works as of 0.4.10 (`gen
  append expr`'s `times`-exclusion in `src/gen_core.vox:139–164` was a
  legitimate, deliberately-declared workaround for a real compiler
  limit — not an undeclared rule — but the limit it worked around is
  gone). Continuing to exclude `times` is now an **unforced sameness
  with no citation left to justify it**, exactly the CLAUDE.md pattern
  ("undeclared rules are the real enemy"): a fix to `gen append expr`
  belongs in the next leaf-touching batch for this section, not a
  documentation note.

Everything else the report finds in this surface — which operator, how
many operands, which spelling of a synonym, the sign and magnitude of
the operands, whether a shift count is under 64 — has **no citation and
must vary**. Two specific samenesses the current generator contributes
and cannot justify:

- `gen expr` never emits `plus`, `subtract`, `divide`, `modulo`, `mod`
  or `remainder` — six of the ten spellings, drawn from a table of five
  choices where the manual offers ten
- every emitted division and modulo has a **nonzero literal divisor in
  2–10** (`gen deep expr`, `gen condition`, `gen leaf float
  arithmetic`, each by its own explicit comment). That is a defensible
  engineering choice for those leaves and an indefensible property of
  the corpus: OPR-35/36 say the zero divisor is legal, safe and
  completely untested.

## Report

**42 rows** (OPR-01 … OPR-42). 34 of them map the section's four
keyword tables and its worked example one-to-one; the remaining 8
(OPR-35…OPR-42) are undocumented-precision rows in the BUF-29/BUF-30
style — behaviour that is real, reproducible, and that a leaf worker
must know before asserting anything in this section.

**Assertable: 39 of 42, up from 36 (0.4.10, #77/#84).** OPR-22, OPR-23
and OPR-41 were compile-error claims through 0.4.9 and are now ordinary
assertable rows. The three that remain not assertable are the three
whose documented or observed outcome is still a **compile error**
(OPR-34, OPR-40, OPR-42) — a runtime leaf cannot carry them, and their
probes record the diagnostic instead. Nothing in this section is
unobservable in the BUF-04 sense; there are no implementation-detail
rows.

**Coverage: 17 exercised, 0 verified, 22 todo, 3 not assertable.** Exercised is generous —
it means a leaf emits the construct into a generated program. Within
that: the comparison rows are exercised only against *random* operand
pairs, so `is greater than or equal to` has never once been checked on
an equal pair, which is the entire content of the claim; and the
logical rows are exercised with operand truth values nobody controls, so
no row of either truth table has ever been pinned.

**The biggest finding: the entire bitwise table is untouched.** Not
shallow — absent. `bit-and`, `bit-or`, `bit-xor`, `bit-shift-left` and
`bit-shift-right` do not occur anywhere in `src/gen_*.vox`, in emitted
text or otherwise. That is five operators, one third of this section,
plus everything the worked example demonstrates about them
(declaration-initialiser form, `Set` form, unbraced chaining), plus the
`0b` literal the example is built on. It is also the operator family
most likely to be interesting: shifting is where a count of 64 wraps
(OPR-37), and a float operand is where a silent `0.0` appears (OPR-38).

Three discrepancies, all recorded with minimal repros, none filed:
1. `isn't` and `aren't` are in the manual's Not row and do not lex; the
   lexer has the keyword arm but the scanner eats the apostrophe first.
2. The section's only worked example does not compile — its last line
   reads an undeclared `value`.
3. Bitwise on a float silently yields `0.0` instead of converting or
   refusing, unlike every other operand type.

**Advice for the next mapper.**

*Re-pin `INDEX.md` before you start.* It is pinned to 0.4.7 and the
manual is 0.4.8; from `ARG` onward every range in it is about 128 lines
short. I mapped the section, not the range, and said so in the header —
do the same, and say so, rather than mapping whatever the stale numbers
land on.

*Check the syntactic position a construct is legal in, not just whether
it compiles.* OPR-40 cost me four probes to pin down and it changes the
`assertable?` answer for eleven rows: a comparison cannot be printed,
cannot be bound to a boolean, and therefore cannot be asserted the
obvious way. If your section has a construct that only appears inside
`If`, find that out early — `assertion-shape.vox` is the artefact I wish
had existed before I started.

*Grep emitted strings, not the generator's own code.* `add` occurs 165
times in `src/gen_*.vox` and perhaps five of those put an `add` into a
generated program. The rest are the generator counting. Grep for the
keyword **inside a `"…"`**, then read the enclosing `To 'gen …'` to see
which leaf it is; the `gen expr` / `gen condition` helpers are where
most of it actually lives, not in the leaves.

*A synonym table is a variation obligation.* Ten spellings for five
arithmetic operations, and the generator emits four of the ten. That is
not a coverage gap to be scheduled — it is `gen expr` asserting a rule
("arithmetic is spelled `add`, `minus`, `multiply` or `times`") that
nobody wrote down. Expect the same shape in the Keywords section
(§4611–4749) next door, which is nothing but alias tables.

*Two apostrophe traps, in generated Vox and in your own probes.* An
apostrophe inside a double-quoted string breaks the parse
(`Print "isn't fired".` fails with `expected a name, found a string
literal`) because `'` is claimed by the quoted-name syntax. And a
surprising number of ordinary words are reserved: `yes`, `negative`,
`zero`, `bigger` all bounced probes of mine before the probe reached
the thing it was testing. Budget for it.
