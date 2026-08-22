# Claim ledger: Names and strings

Source: `../vox/LANGUAGE.md` lines 645–670, Vox 0.4.9 (5327 lines, vox
4b77934), confirmed 2026-08-22 — the `## Names and strings` section
between `Variables` (which ends at 644) and `## Functions` (which
starts at 671). Confirmed by `grep -n "^## "`: zero drift from the
0.4.8 pinned range; every row's citation re-checked by hand and holds
unchanged.

This is a **gap analysis**, not a from-scratch map, and this section is
genuinely small. It reads at first like a duplicate of Variables'
"Naming Rules" table (LANGUAGE.md:612–641) — but that table is *inside*
the Variables section (446–644) and is already fully mapped, row for
row, as `VAR-48` through `VAR-66` (`docs/ledger/variables.md`), whose
last row (`VAR-66`) explicitly says "the `NAM` ledger owns the argument
itself." So Names and strings' own, non-duplicate content is narrower
than it looks: it is the **historical rationale** for the 0.3.0 split
(a prose narrative, mostly not independently re-testable against a
0.4.8 compiler) plus **one worked example** claiming a specific program
is now a compile error. Hand-verifying that worked example is where
this ledger's only finding is.

## Probes

`docs/ledger/probes/names-and-strings/`. `NAM-03.vox` reproduces the
worked example as literally written and confirms it is rejected.
`D1.vox` and `D1b.vox` are the minimal repros for Discrepancy 1 — the
worked example's *narrower* claim (`is "get five"` specifically "rejects
the string in identifier position") does not hold once the example's
other violation is removed. Historical/narrative rows (`NAM-01`,
`NAM-02`, `NAM-06`) have no probe: there is no 0.3.0-era compiler in
this repo to run them against, and the rows say so.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| NAM-01 | 647–648 | Before 0.3.0, a double-quoted token was both a string literal and an identifier, decided by position, and that overload was "the root of a family of silent wrong answers." | — | **no** — a historical claim about a compiler version not present in this repo (`target/release/vox` is 0.4.8+); nothing to run it against | n/a | not assertable (historical) | |
| NAM-02 | 652–660 | Worked example, pre-0.3.0 behavior: `a number called "x" is "get five".` / `print x.` prints a function pointer as a number (`4198480`) with no error or warning. | — | **no** — same reason as NAM-01; also a **specific fixed value** tied to a specific pre-0.3.0 binary layout, not reproducible from any binary in this repo | n/a | not assertable (historical) | |
| NAM-03 | 662–665 | "So in 0.3.0 the two are split... The program above is now a compile error." | reproduce the worked example verbatim against the current compiler, assert it is rejected | yes, as a compile-error claim | none — no leaf ever emits a string literal in name position (every declaration uses a counter-suffixed bare identifier) | todo — no leaf emits a string literal in name position; hand-verified: the literal program from LANGUAGE.md:652–653 is rejected, **but by the `"x"` half, not the `"get five"` half** — see Discrepancy 1, which is about the next row | |
| NAM-04 | 664–665 | Specifically: `is "get five"` "rejects the string in identifier position and points you at `'get five'`." | isolate the value-position half from the name-position half: declare with a bare name (`x`, not `"x"`) so the compiler must reach the `is "get five"` clause, and check what happens | yes — either a compile error citing `'get five'`, or (if it compiles) the printed value should be inert/an error, never a "looks like data" wrong answer | none | **todo — RESOLVED, vox #65**: the isolated claim now holds — `a number called n is "get five".` is refused at compile time (`cannot initialise 'n', which is a number, with text`), matching the reassignment form. See Discrepancy 1 (resolved). | unblocked |
| NAM-05 | 666–667 | "The cost is that every program written before 0.3.0 must be migrated." | — | **no** — a claim about the corpus of *other* pre-existing Vox programs, not about this compiler's behavior on any one program | n/a | not assertable (narrative/consequence claim) | |
| NAM-06 | 667 | "The payoff is that this class of silent wrong answer is gone." | the general claim ("this class... is gone") is falsified by any surviving instance of the pre-0.3.0 pattern | **no** as stated (a claim about a *class*, not one program) — but it predicts a negative result, and **Discrepancy 1 finds a positive one**, so the general claim does not hold either | n/a | **not assertable as written — and appears false**, see **Discrepancy 1** | blocked on D1 |
| NAM-07 | 662–664 | Restatement: `"..."` is a string literal everywhere; a name is a bare or single-quoted identifier — no overlap, no context-sensitivity. | — | yes | all three forms are emitted across the generator (`VAR-48`) | folded into `VAR-48` — this ledger owns only the *argument for* the rule (why the split happened), not the rule's own truth, which `VAR-48`–`VAR-66` already cover | |

## Discrepancies

### 1. The initial-declaration form (`a TYPE called NAME is "string literal".`) does not type-check its string-literal value against a non-text `TYPE` — reproducing, in narrower form, exactly the bug class this section says 0.3.0 closed — RESOLVED (vox #65)

LANGUAGE.md:664–665 claims the worked example `a number called "x" is
"get five".` is "now a compile error" because "`is "get five"` rejects
the string in identifier position." Hand-verifying the program *as
written* confirms it is rejected — but by the compiler's very first
token check, on `"x"` (a string literal where the declared *name* is
expected), never reaching the `is "get five"` clause the manual credits.
Removing only the `"x"` violation isolates the claim:

Repro (`D1.vox`):
```
a number called n is "get five".
print n.
```
Output:
```
4198488
```

No error. No warning. A garbage number, printed as if it were data —
which is exactly the pre-0.3.0 failure mode NAM-02 describes, reproduced
against the live 0.4.8 compiler. Three further checks pin down the
mechanism (`D1b.vox` bundles the reassignment-form comparison and the
type-independence check):

1. **The value is the address of that declaration's own string
   literal, not derived from parsing its content.** In isolation (one
   string, one program) every mismatched string — `"abc"`, `"42"`,
   `"a"`, a 30-character unrelated string — prints the identical
   `4198488` (`0x401058`), which looks at first like a fixed constant.
   It isn't: declaring **two** variables from the identical string
   `"abc"` in **one** program prints two *different* values (`D1b.vox`:
   `4198488`, `4198492`), and the gap between each pair of consecutive
   values across a run of differently-sized strings equals the
   *preceding* string's byte length plus one — exactly what you'd see
   if each string literal is laid out immediately after the last one in
   the binary and the printed number is that string's own address. So
   this is not a misparse of the text as a number and not a symbol/
   function-pointer lookup either — it's the same pointer-to-the-
   literal's-bytes the compiler correctly produces when the declared
   type *is* `text` (compare `a text called y is "get five". print y.`,
   which prints the text fine), just bit-copied into a `number`/
   `boolean` slot without the dereference-and-render step `text` gets.
   The single-string-per-program tests happening to agree at `4198488`
   is simply what you'd expect when it's the *only* string literal in
   an otherwise structurally-identical binary each time — a coincidence
   of program shape, not evidence of a fixed sentinel.
2. **The *reassignment* form is correctly fixed.** `a number called n is
   1. n is "get five".` (an existing variable reassigned, `VAR-26`'s
   construct) is properly rejected: `error: cannot assign text to 'n',
   which is a number`. Type-checking on assignment works exactly as
   `VAR-26`/`VAR-29` document.
3. **The failure is specific to register-width types.** `number` and
   `boolean` both reproduce the garbage-pointer value (`4198488`) when
   declared from a mismatched string literal. `float`, `list`, and `map`
   instead silently take their **zero value** (`0.0`, `[]`, `{}`) —
   still wrong (a string literal is not a valid initializer for any of
   these, and none of the three should compile), but a *different* wrong
   answer, not the pointer-as-number pattern.

**Strongest reading under which the compiler is correct:** the `is a`
predicate work in `TYP` Discrepancy 1 already establishes that some
runtime classification in this compiler tracks a value's *literal shape
at the point it was written*, separately from static declared type —
so it is plausible the type-check added for 0.3.0 was implemented only
on the **reassignment forms** (`x is <value>.`, `Set x to <value>.`,
both of which `VAR-26`–`VAR-29` confirm work) and the *initial*
`a TYPE called NAME is VALUE.` declaration form still routes its `VALUE`
through an older code path that predates the split — one that, for a
`number`/`boolean` target, still treats an unresolvable quoted token as
a symbol reference the way 0.3.0's predecessor did, and for
`float`/`list`/`map` targets instead falls through to that type's
default-value codegen (both consistent with "the 0.3.0 type-check machinery
was retrofitted onto assignment, not onto every value-producing
position"). Under that reading, the manual's specific worked example
(with both violations present) is technically still true — the `"x"`
half genuinely does get caught, first — but the surrounding narrative's
broader claim ("this class of silent wrong answer is gone") is false for
the initial-declaration form specifically, which the manual's own
example doesn't isolate. Not filed at the time; repros retained above
and in `D1.vox`/`D1b.vox`.

**Resolution confirmed, 2026-08-22: fixed by vox #65.** `vox/docs/
BUGS_FOUND.md` #65 ("A declaration whose initializer is the WRONG type
is accepted — `a text called n is 5.` segfaults on the first read, `a
number called n is "get five".` prints the literal's address") names
this exact repro. Re-run `D1.vox`/`D1b.vox` against vox 0.4.9: the
initial-declaration form now type-checks its value exactly like the
reassignment form does — `error: cannot initialise 'n', which is a
number, with text`, naming the fix-it rewrite. The class of silent
wrong answer NAM-06 said was "gone" now actually is, for both the
declaration and the reassignment forms.

## Report

**7 rows** (NAM-01 through NAM-07). Three (`NAM-01`, `NAM-02`, `NAM-05`)
are purely historical/narrative and not assertable against any compiler
in this repo — there is no way to run a 0.3.0-era binary, and they say
so rather than guessing. One (`NAM-07`) is a restatement folded into
`VAR-48`, which already owns the rule's truth. That leaves three rows
(`NAM-03`, `NAM-04`, `NAM-06`) that actually predict something a live
compiler can confirm or refute — and hand-verifying them is where this
small section's one real finding lives.

**The finding**: the manual's own worked example, read as a *whole
program*, is correctly rejected — but not for the reason the prose
gives. Isolating the half the prose actually credits (`is "get five"`
in value position) showed the initial-declaration form, as of the
0.4.8 compiler this section was first mapped against, still exhibited
the exact silent-wrong-answer pattern (a string literal misread as an
identifier reference, converted to a number, printed as if it were
data) that this section's whole narrative says 0.3.0 eliminated, while
the reassignment form was genuinely fixed (confirmed against `VAR-26`).
Recorded as Discrepancy 1, not filed at the time — the strongest
reading was that the 0.3.0 type-check had been added to assignment
forms and never extended to the initial-declaration form's value
position.

**Update, 2026-08-22**: re-run against vox 0.4.9, Discrepancy 1 is
**resolved by vox #65** — the initial-declaration form now type-checks
its value the same way the reassignment form does, closing the gap
NAM-04 and NAM-06 depended on. All seven rows in this ledger now stand
on solid ground: nothing left blocked, nothing left open.

**For the next section's mapping:** when a section's prose credits a
FIX to "the two are split, full stop," don't just re-run the section's
own worked example as a single go/no-fail check — a compound example
with two independent violations can pass for the wrong reason (as this
one does, tripping the first violation and never reaching the second).
Isolate each sub-claim the prose actually makes and test it separately;
that's the only way NAM-04's gap was visible at all. Also worth
carrying forward: `TYP`'s Discrepancy 1 and this section's Discrepancy 1
share a root cause (a value's static declared type and its runtime
representation can diverge, in more than one direction, in more than one
place) — worth a single cross-cutting write-up once more sections
surface the same pattern, rather than re-discovering it per section.
