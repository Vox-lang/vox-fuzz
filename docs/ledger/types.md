# Claim ledger: Types

Source: `../vox/LANGUAGE.md` lines 428–445 (version 0.4.8 + bugs #49–#54
fixed, b26f66e), the `Types` table between `Basics` and `Variables`.
Confirmed against the manual by `grep -n "^## "`: the section runs from
the `## Types` heading at 428 to the blank line before `## Variables` at
446 — the brief's pinned range (428–445) is exact, no drift.

This is a **gap analysis**, not a from-scratch map. The Types table is
eleven rows (`Type | Keyword | Description`), and every one of those
types already has deep, independent coverage from a section mapped
earlier: `number`/`text`/`boolean`/`list`/`map` from Variables (`VAR`),
`buffer` from `BUF` (39 rows), `file` from `FIL` (101 rows), `time`/
`timer` from `TIM` (60 rows), `thing` from `THG`/`KEY`. So most rows
below **fold into an existing ledger's row** rather than needing a fresh
leaf — the Types table itself makes no claim its owning section doesn't
already make in more detail. The one row that turned out to have
independent, previously-unasserted content is `number`: the table's own
description, "Whole numbers", is not enforced anywhere, and no other
ledger had tested that specific silent gap. That is this section's
finding, in the Discrepancies section below.

## Probes

`docs/ledger/probes/types/`, one file per row that got a *fresh* hand-run
(a row that only cites another ledger's existing probe does not get a
second copy). `TYP-01.vox` and `D1.vox`/`D1-frac.vox` cover the number/
decimal-tag mismatch; `TYP-02.vox` the float IEEE-754 double-rounding;
`TYP-04.vox` the boolean literal pair; `TYP-06.vox` the map text-key
compile error. Rows folded into another section's row (`TYP-03/05/07/08/
09/10/11`) have no probe here — their probe lives with the ledger that
owns the claim, cited in the row.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| TYP-01 | 432 | `number` (Integer) holds "whole numbers". | declare a `number` with a fractional literal, check it is retained and how `'s type` / `is a number` / `is a decimal` classify it | yes — `a number called n is 3.5. If n's type is not "Number (static)" then, Exit 95.` (the retention half); see Discrepancy 1 for why the classification half contradicts the row itself | none — every emitted `number` literal is drawn as a whole value (`'rng below'` and friends never emit a decimal point into a `number`-typed declaration) | todo — and the claim as titled does **not** hold, see **Discrepancy 1** | |
| TYP-02 | 433 | `float` is "Floating-point numbers (64-bit IEEE 754)". | declare two floats whose sum is not exactly representable, assert the double-rounding | yes — `a float called s is f add g. If s is equal to 0.3 then, Exit 95.` (0.1+0.2 ≠ 0.3 in binary64) | `gen leaf timer and clock`? no — greps for `a float called` land in `gen_core.vox`/`gen_text.vox` as arithmetic operands, never followed by an equality assertion against an exact decimal | todo — hand-verified: the double-rounding is present exactly as IEEE 754 predicts | |
| TYP-03 | 434 | `text` (String) holds "Text strings". | — | yes, trivially | text declarations are the single most common construct in every leaf file | exercised — no independent verification needed; the type's actual behavior (escaping, formatting, concatenation) is `FMT`'s and `EXP`'s territory, not this table's | |
| TYP-04 | 435 | `boolean` is "`true` or `false`". | declare a boolean from each literal, assert both round-trip and print as the tag `is a boolean` recognizes | yes — `if b is a boolean then` after each declaration | `a boolean called ... is true`/`is false` forms appear across every leaf file as flags and predicate results, but nothing declares directly from the literal `false` in isolation and asserts the type/predicate | todo (isolated literal-pair check); hand-verified both literals compile, retain, and print `1`/`0` (not the words `true`/`false` — printing format is `EXP`'s/`FMT`'s claim, not this table's) | |
| TYP-05 | 436 | `list` holds a "Collection of items". | — | yes | `LST-03`/`LST-06` (mixed-type list literals) | folded into `LST-03` | |
| TYP-06 | 437 | `map` is a "Key/value collection (JSON object; **text keys**)". | declare a map literal with a non-text key, assert it is rejected | yes, as a compile-error claim — `Map keys must be text` | `LST-36` exercises text-keyed maps but never tries a non-text key | todo — no leaf emits a non-text map key; hand-verified: `a map called m is {5: 1}.` is rejected at compile time with `error: Map keys must be text` | |
| TYP-07 | 438 | `buffer` is a "Memory block for I/O (dynamic or fixed-size)". | — | yes | the entire `BUF` ledger (39 rows) | folded into `BUF-01` (the two declaration forms) | |
| TYP-08 | 439 | `file` is a "File descriptor handle (auto-cleaned)". | — | yes for the handle half; the auto-clean half is not assertable from inside Vox | `open a file for reading/writing called X at ...` (`gen leaf file round trip` and siblings, `src/gen_files.vox`) | folded into `FIL-87`/`FIL-89`/`FIL-98` (resource safety, "a forgotten close is not a leak") | |
| TYP-09 | 440 | `time` is a "Date/time value (unix timestamp with components)". | — | yes | `Get current time into tn{n}` (`gen leaf timer and clock`, `gen_misc.vox:218`) declares a `time` implicitly rather than via `a time called X is current time.` | folded into `TIM-01`/`TIM-03` | |
| TYP-10 | 441 | `timer` is a "Stopwatch for measuring durations". | — | yes | `a timer called tk{n}` / `Start`/`Stop` (`gen leaf timer and clock`) | folded into `TIM-21` | |
| TYP-11 | 442 | `thing` is `*(contextual)*`, a "User-defined composite value type". | — | yes | `a t4 called i{n} is ...` (`gen leaf thing member`, `src/gen_things.vox`) declares instances of a defined thing type; no leaf declares a variable literally named `thing` to exercise the contextual half | folded into `THG-13` (contextual-elsewhere half) / `KEY-76`, `KEY-79` (the exact worked example `a number called thing is 1.`) | |

## Discrepancies

### 1. A `number` silently holds and prints a fractional value, and the `is a` predicate then disagrees with `'s type` about what it is

**LANGUAGE.md:432** describes the Integer type/`number` keyword as holding
"Whole numbers." Nothing else in the manual (checked: no other occurrence
of "whole number" or an integer-only restriction anywhere in
LANGUAGE.md) states that assigning a fractional literal to a
`number`-typed variable is rejected, so this is the *only* place the
constraint is claimed at all.

Repro (`TYP-01.vox`):

```
a number called n is 3.5.
print n.
print n's type.
if n is a number, print "is a number: yes". otherwise print "is a number: no".
if n is a decimal, print "is a decimal: yes". otherwise print "is a decimal: no".
```

Output:
```
3.5
Number (static)
is a number: no
is a decimal: yes
```

So: (a) the fractional value is not rejected, not truncated, and not
silently converted — it is stored and printed exactly as written,
directly contradicting "whole numbers"; (b) worse, the `'s type`
property (which reflects the *static declared* type per
`LANGUAGE.md:3202–3208`/`BUF` Discrepancy 2's sibling behavior) says
`Number (static)`, while the `is a <noun>` predicate (which
`LANGUAGE.md:2403–2405`/`LST-62` establish reads a *runtime value tag*,
not the declared type) says the opposite — `is a number` is **false**
and `is a decimal` is **true** for the very same variable. Compare the
same variable holding a whole value (`D1-frac.vox`'s companion, run by
hand): `a number called n is 3. if n is a number, ...` prints `is a
number: yes` and `is a decimal: no` — so the predicate's answer flips
with the *value*, not the *declaration*, confirming the tag is set at
assignment time from the literal's shape, independent of `n`'s static
type.

**Strongest reading under which the compiler is correct:** the `is a`
predicate is documented (`LANGUAGE.md:2403–2405`, `LST-62`/`LST-63`) as a
**runtime value-shape** check — it exists specifically so a list holding
mixed literals (`[1, "two", 3.5, yes]`) can be dispatched on per-element,
and per that section's own worked example a bare `3.5` element already
reports as `decimal` regardless of any variable's declared type. Read
this way, the predicate is doing exactly its documented job — it was
never specified to agree with `'s type`, and nothing in `LST` or `VAR`
claims the two must match for a *statically number-typed variable*
holding a *dynamically fractional* value, because the manual never
anticipated that combination existing (`number` was assumed whole). So
the compiler is internally consistent under its own two separate rules;
the actual bug, if there is one, is that the **static type system**
lets a `number` hold a non-whole value at all — the Types table's
"whole numbers" is aspirational and nothing downstream of declaration
enforces it, and *that* absence is what lets the predicate's runtime
tag and the property's static tag diverge. Not filed; repro above and
`TYP-01.vox`/`D1-frac.vox` retained.

## Report

**11 rows** (TYP-01 through TYP-11), one per row of the Types table —
this section is exactly as small as its line count suggests. **7 fold
directly into an already-mapped section's row** (`VAR`/`LST` for
text/list/map's mundane half, `BUF`/`FIL`/`TIM`/`THG`/`KEY` for
buffer/file/time/timer/thing) with no fresh leaf need of their own — the
Types table adds nothing to those sections' claims beyond restating
them. **4 rows got a fresh hand-run** (`TYP-01`, `TYP-02`, `TYP-04`,
`TYP-06`) because their exact claim (whole-numbers, IEEE-754
double-rounding, the true/false literal pair, and the text-only map key
enforcement) had not been independently probed by any other ledger.

**One real finding, TYP-01**: `number`'s "whole numbers" is not
enforced by the compiler in any way — a `number`-typed variable can be
declared with, hold, print, and arithmetic on a fractional value exactly
as a `float` would, and the `is a number` / `is a decimal` predicates
then classify it by its *runtime value shape* rather than its *static
declared type*, producing a genuinely confusing result where `n's type`
and `n is a number` disagree about the same variable. Recorded as
Discrepancy 1, not filed — the strongest reading treats the predicate as
correct on its own documented terms (`LST-62`) and locates the actual
gap in the *absence* of a whole-number check at the type-immutability
layer (`VAR`'s territory) rather than in the predicate itself.

**For the next section's mapping:** when a summary table like this one
sits downstream of sections that are already deeply mapped, check each
row against the owning section's ledger *before* writing a leaf-need —
most of the work here was confirming what NOT to duplicate, not writing
new probes. The one row worth a fresh look was the one whose adjective
("whole") no other ledger had reason to test, because it reads as
throwaway color text in a keyword table rather than a rule. Read every
adjective in a table cell as a claim; that's where TYP-01 came from.
