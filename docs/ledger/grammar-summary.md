# Claim ledger: Grammar Summary

Source: `../vox/LANGUAGE.md` lines 5816–5882, Vox 0.4.10 (5545 lines, vox
527cb89), confirmed 2026-08-22 — the EBNF block that closes the manual
(33 named productions). Uniform +87 drift from the 0.4.8 pinned range
(5176–5240), confirmed at every production boundary by hand (`## Grammar
Summary` now at 5263, end of file now at 5327) — the whole block is one
contiguous fenced code region, so the shift holds exactly, start to
end, with no internal insertions to break it.

This is a **gap analysis**, not a from-scratch map — this section had
never been mapped (`INDEX.md` said `no`). Each production's claim is
**"every alternative this production lists parses"** — a narrower claim
than any sibling section's, which mostly assert runtime behavior. Where
a sibling ledger has already put a form on runtime trial, this ledger's
job is only to confirm it against the grammar's own wording and flag
where the two disagree — **not** to re-derive semantics from scratch. Per
the brief: a production with no independent syntax of its own (its forms
only ever appear nested inside a parent production) is folded into the
parent's row rather than given a hollow row of its own; each fold is
named explicitly below.

33 named productions in the manual's EBNF collapse to **23 rows**
(GRM-01 through GRM-23) after folding: `statement` (the union, GRM-02,
folded — no row of its own) and `params`/`param` (GRM-06), `thing_entry`/
`field_decl`/`member_decl` (GRM-10), `arg_clause` (GRM-09) each fold into
their parent because none has independent syntax outside it.

## Probes

Every hand-verified row's probe is retained in
`docs/ledger/probes/grammar-summary/`, named `GRM-NN.vox`. Unlike
buffers.md's probes (which assert a documented runtime result), most of
these probes assert **nothing** — the claim under test is "this parses
and produces the output its own arithmetic/logic predicts," so a clean
compile-and-run with the expected printed values IS the assertion, the
same shape examples.md uses. Three discrepancy repros (`D1.vox`–`D3.vox`)
record where a production's literal wording and the compiler disagree.
GRM-02 has no probe file (folded, no independent syntax — see above).

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| GRM-01 | 5819 | `program ::= statement*` — a program is zero or more statements, run in sequence. | any multi-statement program | yes — trivially, by every probe in every ledger | every probe in `docs/ledger/probes/*/` is itself an instance | exercised | |
| GRM-02 | 5820–5822 | `statement` is the union of print_stmt, var_decl, assignment, if_stmt, while_stmt, for_stmt, func_def, thing_def, member_def, increment, decrement, break, continue, append_stmt. | — | — (no independent syntax; each alternative is its own row below or a sibling ledger's) | — | folded — see GRM-03 through GRM-15 and FLW (control-flow.md) for increment/decrement/break/continue, whose own surface syntax this production does not spell out at all | |
| GRM-03 | 5824–5825 | var_decl's two forms: `("a"\|"an") type "called" name "is" expr "."` and `("Set"\|"Create") "the"? type? "called"? name "to" expr "."` — both bring a NEW variable into being. | all spellings in one program | yes | `a TYPE called NAME is VALUE` is universal (VAR-02); `Set`/`Create ... to` are cross-ref'd at VAR-03/VAR-04 (**todo** there — no leaf emits either), and VAR-06 already notes the three lead-ins are meant to be interchangeable | exercised (bare `a`/`an` form, VAR-01/02); todo (`Set`/`Create` forms, same gap VAR-03/04/06 already record) | |
| GRM-04 | 5827 | assignment: `"the" name "is" expr "."` — reassigns an EXISTING variable (distinct from var_decl's "is", GRM-03). | reassign then print | yes | VAR-26 notes this exact bare spelling ("`x is <value>.`") is never emitted by any leaf, despite being the legal, documented form | todo — cross-ref VAR-26 | |
| GRM-05 | 5829 | append_stmt's first form: `"append" expr "to" name "."` — appends one value. | append twice, print | yes | BUF-31 (buffers.md): format-string leaves append into fixed buffers, but nothing asserts the result | exercised (construct); todo (assertion) — same gap BUF-31 already records | |
| GRM-06 | 5832–5834 | func_def, folding in params/param (no independent syntax): `"To" identifier (("with"\|"of") params)? "." "Return" "a" type "," expr "."`, params via `and`. | both introducer prepositions, a multi-param list | yes | FUN-01/FUN-06 (functions.md): the one-sentence template and `with`/`of` interchangeability are both established there (`of` is a real gap: **no leaf ever emits it** in a definition, per FUN-06) | exercised (`with`, FUN-06); todo (`of` in a **definition** — GRM-08/FUN-32 already cover `of` at the **call** site, a different position) | |
| GRM-07 | — | *(folded into GRM-06 — no independent syntax)* | — | — | — | — | |
| GRM-08 | 5836 | func_call: `identifier ("of"\|"with"\|"to"\|"on") args` — four alternative call prepositions, same call kind. | call the same function all four ways | yes | **already established, not a new finding**: FUN-32 (functions.md:759) hand-verified this exact claim — "all four connectors... hand-verified identical," and records the same gap: `of` is the only one any leaf emits | exercised (`of`, FUN-32); todo (`to`/`with`/`on`, same gap FUN-32 already records) | |
| GRM-09 | 5837–5838 | args/arg_clause (arg_clause folded — no independent syntax): each argument to a call is independently either a plain `expr` or a `loop_expansion` (a grid call). | a two-argument grid call | yes | LST2-44 (collections-b.md): `gen call grid`/`gen leaf deep grid` already use ranges as grid clauses of a function call — this row's contribution is confirming the Grammar Summary's own wording (`args ::= arg_clause*`) matches | exercised — cross-ref LST2-44 | |
| GRM-10 | 5840–5843 | thing_def, folding in thing_entry/field_decl/member_decl (none has independent syntax outside it): `"A" "thing" "called" name "has" thing_entry ("," thing_entry)* "."`; a field_decl's `("is" literal)?` initializer is optional; a member_decl (`"a" "function" "called" name`) only declares the manifest slot — the callable body is GRM-11. | a field with a default, one without, one member_decl | yes | THG (things-a.md) maps field_decl's full claim set; THG2-14 (things-b.md) establishes the manifest pattern this row's member_decl half exercises | exercised — cross-ref THG/THG2-14 | |
| GRM-11 | 5845–5846 | member_def: `"To" "do" "the" name "'s" name (("," ("with"\|"of"))? params)? "." body "Return" "a" name "," expr "."` — note the comma before `with`/`of` that a plain func_def lacks. | a manifest member with a parameter, called and its field read | yes | THG2-14/THG2-15 (things-b.md) already map this production's full claim set (this row's probe is adapted from `THG2-14.vox` almost verbatim) | exercised — cross-ref THG2-14/THG2-15 | |
| GRM-12 | 5848–5850 | if_stmt: `("If"\|"When") condition "then" "," block ("but if" condition "then" "," block)* ("otherwise"\|"else")? ","? block? "."` — five alternation points. | When, else, otherwise, and a but-if chain, all in one program | yes | FLW-03/FLW-04/FLW-07 (control-flow.md) map "But if...then," and the period-before-"But if" sentence-continuation rule this row also had to rediscover by hand before finding FLW-03 already had it | exercised (`If`, `else`, `otherwise`, cross-ref FLW-03); todo (`When`, and the `But if...then,` chain form itself — FLW-03 says "hand-verified to work" but marks its OWN status `todo`, since no leaf in `main` emits it) | |
| GRM-13 | 5852 | while_stmt: `"While" condition "," block "."` — no alternatives. | a counting loop | yes | FLW (control-flow.md) maps this production's full claim set | exercised — cross-ref FLW | |
| GRM-14 | 5854–5855 | for_stmt's two forms: `"For each" name "from" expr "to" expr "," block "."` (range) and `"For each" name "in" expr "," block "."` (collection). | both forms in one program | yes | FLW (control-flow.md, range form); LST2 (collections-b.md, collection form) | exercised — cross-ref FLW/LST2 | |
| GRM-15 | 5857–5861 | print_stmt's three forms: plain `Print expr` with a but-if tail, `Print each name from expr (treating)?` with a but-if tail, and `Print <func> of each name from expr` (per-item function return). This but-if is a DIFFERENT production from if_stmt's (GRM-12) — no `then`, no comma before the branch's `print` — sharing only the two words. | all three forms, one but-if firing | yes | FMT (input-output.md, plain form); LST2-55/LST2-44 (collections-b.md, the each/func forms) | exercised — cross-ref FMT/LST2 | |
| GRM-16 | 5863 | loop_expansion: `"each" name "from" expr ("treating" expr "as" expr)?` — the shared clause used by print_stmt, args, append_stmt's second form, and for_stmt's "in" form. | a treating substitution under a bare `Print each`; separately, under `append_stmt` | yes | BAS2 (basics-expansion.md) maps this production's full claim set including grid/nested expansion | exercised (under `Print`, BAS2-52). **Discrepancy 3 RESOLVED (vox #70, 2026-08-22)** — the substitution under `append_stmt` was a silent no-op through 0.4.9; hand-verified fixed against 0.4.10 (`append each item from src treating 2 as 20 to dst.` now substitutes correctly), still no leaf emits it | |
| GRM-17 | 5866–5870 | expr's precedence chain: or_expr → and_expr → comparison → additive → multiplicative → primary, in that binding order. | one expression exercising all six levels, inside a condition | yes | EXP (expressions.md) and OPR (operators.md) map operator behavior; **this production's own claim that plain `expr` is legal wherever the grammar cites it (var_decl, assignment, print_stmt) is FALSE for the `comparison` level — see Discrepancy 1, cross-ref EXP-D3** | exercised (precedence itself, inside an `If` condition — the only position a `comparison` actually parses); the wider `expr`-everywhere claim is **not assertable as written** — see Discrepancy 1 | |
| GRM-18 | 5872 | multiplicative's operators: `multiply`, `times`, `divide`, `modulo` — `times` is a full synonym for `multiply`. | `times` and `multiply` side by side | yes | OPR-06 (operators.md) already established this; OPR-41 recorded a separate, narrower gap (`times` rejected specifically inside `append <value> to <collection>`'s value slot) — **RESOLVED (vox #77, 2026-08-22)**, `times` now works there too | exercised — cross-ref OPR-06/OPR-41 | |
| GRM-19 | 5873 | primary: `literal \| identifier \| func_call \| "(" expr ")"` — the fourth alternative claims parentheses group expressions. | a grouped arithmetic subexpression | yes | literal/identifier/func_call are exercised everywhere else in this ledger; **the parenthesized-grouping claim is FALSE — see Discrepancy 2, cross-ref EXP-D5** (parentheses are comments; the actual grouping punctuation, `{...}`, is not listed as a `primary` alternative at all) | exercised (first three alternatives); the fourth is **not assertable as written** — see Discrepancy 2 | |
| GRM-20 | 5875–5877 | type: `number \| float \| text \| boolean \| list \| map \| buffer \| file \| time \| timer \| value \| <user-defined thing name>` — twelve type names. | one variable of every type, declared and printed/accessed | yes | each type has its own ledger (variables.md, buffers.md, files.md, time-and-timers.md, values.md, collections-a.md, things-a.md); none of them states "all twelve in one program" as a single combined claim, which is this row's own contribution | exercised — cross-ref the per-type ledgers | |
| GRM-21 | 5878–5879 | name/identifier: `bare \| quoted` — "quoted" means single-quoted (`'my count'`); a name is never double-quoted. | a bare name and a single-quoted one holding the same value | yes | `names-and-strings.md` NAM-07 (LANGUAGE.md 662–664) states this exact restatement and folds it into `VAR-48`; single-quoted identifiers are also used incidentally across many probes (every function name in this repo) | exercised — cross-ref NAM-07/VAR-48 | |
| GRM-22 | 5880 | literal: `string \| number \| "true" \| "false" \| "nothing"` — five literal forms. | all five as declaration initializers | yes | EXP-04 (expressions.md) covers `true`/`false` (and notes `false` is never emitted as a literal by any leaf); VAL (values.md) covers `nothing`; string/number literals are exercised constantly everywhere | exercised — cross-ref EXP-04/VAL; `false` as a literal is a gap EXP-04 already records | |
| GRM-23 | 5881 | string: `'"' ... '"'` — "a string literal is data, never a name." Using one where a name is expected is a compile error. | trigger the compile error | **no, compile-error claim** — not assertable from a generated leaf (the fuzzer's contract is legal, compiling Vox) | `names-and-strings.md` NAM-03 (LANGUAGE.md 662–665) reproduces the manual's own worked example verbatim and hand-verifies the identical rejection — `NAM-03.vox`: `error: expected a name, found a string literal` | not assertable (compile-error claim) — cross-ref NAM-03; hand-verified: `expected a name, found a string literal` | |

## Discrepancies

### 1. `var_decl`/`assignment`/`print_stmt` claim `expr` (including `comparison`), but a `comparison` only parses in condition position

LANGUAGE.md's own Grammar Summary says, taken together:

```
var_decl    ::= ("a"|"an") type "called" name "is" expr "."   (:5271)
expr        ::= or_expr                                        (:5312)
and_expr    ::= comparison ("and" comparison)*                 (:5314)
comparison  ::= additive (comp_op additive)?                    (:5315)
```

So `a boolean called ok is total is 5.` should parse — `expr` includes
`comparison`, and `is` is a valid `comp_op`. It does not:
`Expected a statement, got Is` (`D1.vox`). The same failure holds for
`assignment` (`the ok is total is 5.`) and for `print_stmt`'s plain form
(`Print total is 5.`) — any position that already used `is` as its own
copula/verb before reaching the initializer.

**Resolution: already adjudicated by the lawyer for this exact claim.**
This is the **identical finding** as Discrepancy 3 in `expressions.md`
(EXP-D3), independently rediscovered here while hand-verifying GRM-17
before finding EXP-D3 already existed. EXP-D3's own text names the fix
this ledger's line range would need: "the Grammar Summary needs
`condition` as a production distinct from `expr`" — i.e., the fix belongs
in exactly the section this ledger maps. Not re-adjudicated separately
here; see `expressions.md`'s Discrepancy 3 for the full reading and
resolution status. Recorded here because :5271–5274/:5304 are inside
this ledger's own line range and a reader of the Grammar Summary alone
(without also reading expressions.md) would hit the identical trap.

### 2. `primary`'s `"(" expr ")"` alternative — parentheses do not group; they are comments

LANGUAGE.md:5873:

```
primary ::= literal | identifier | func_call | "(" expr ")"
```

`a number called n is (2 add 3).` does not parse the way this line
claims — `(2 add 3)` is read as a comment (Vox's comment delimiter),
consuming the initializer entirely: `Expected a statement, got Period`
(`D2.vox`).

**Resolution: already adjudicated by the lawyer for this exact claim.**
Identical to Discrepancy 5 in `expressions.md` (EXP-D5), independently
rediscovered here. EXP-D5's reading: the compiler is unambiguously
correct (comment syntax is documented and load-bearing everywhere), and
":5318 is a leftover from an EBNF template." Not re-adjudicated
separately; see `expressions.md`'s Discrepancy 5. Worth adding here,
since EXP-D5 does not mention it: `primary` as written is not just wrong
about parentheses, it is also **incomplete** — `{...}`, the actual
grouping punctuation (LANGUAGE.md:1943, 1949), is not listed as a
`primary` alternative at all. Fixing the parenthesis line without adding
a `{...}` alternative would leave the production still not describing
how grouping actually works.

### 3. append_stmt's `treating` clause: wrong position in the manual's own grammar, and a silent no-op once moved to a position that parses — RESOLVED (vox #70, manual grammar corrected)

LANGUAGE.md:5829–5830, **before** 0.4.10:

```
append_stmt ::= "append" expr "to" name "."
              | "append" "each" name "from" expr "to" name
                ("treating" expr "as" expr)? "."
```

Two separate problems, both hand-verified minimal (`D3.vox`):

1. The literal position shown — `treating` AFTER `to name` — is a
   compile error: `append each item from src to dst treating 2 as 20.`
   gives `Expected a statement, got Treating`.
2. Moving `treating` to where `loop_expansion` actually attaches it
   (right after `from expr`, BEFORE `to name` — matching print_stmt's own
   placement, GRM-15, and `loop_expansion`'s own production, :5310) DOES
   parse: `append each item from src treating 2 as 20 to dst.` compiles
   and runs. But the substitution never happens — `dst` ends up
   `[1, 2, 3]`, not `[1, 20, 3]`, even though the byte-identical clause
   substitutes correctly under `Print each` (GRM-16, `BAS2-52.vox`).

**The reading in which the compiler is correct.** For (1): the manual's
own placement may simply be a typo relative to how every other
`treating`-bearing production in this same Grammar Summary places the
clause (immediately after the `expr` it modifies, never after a
trailing `to`/target clause) — `loop_expansion`'s own line, :5310, is
the internally-consistent version, and append_stmt's line probably
should have deferred to it (`append_stmt`'s second form is, after all,
just `"append" loop_expansion "to" name "."` in spirit, even though it
is not literally spelled that way). For (2): `append each ... to ...`
is itself a documented **gap**, not just an undocumented precision —
LST2-46 (collections-b.md) already records that no leaf emits this
append-each form at all, hand-verified only as far as the base
substitution-free case. It is plausible the `treating` parameter is
simply wired up in the parser (hence no error) but never reaches the
substitution step in the append-each code path specifically, because
that whole code path is this thin. Neither reading resolves it fully:
the manual's own worked shape for append_stmt does not parse under any
placement its own line implies, and the one placement that does parse
silently drops a documented feature. Not filed.

**Resolution confirmed, 2026-08-22 — RESOLVED by vox #70, and the manual
itself was corrected too.** LANGUAGE.md:5829–5830 now reads:

```
append_stmt ::= "append" expr "to" name "."
              | "append" "each" name "from" expr ("treating" expr "as" expr)? "to" name "."
```

— `treating` moved to immediately after `from expr`, matching
`loop_expansion`'s own placement (part 1 of this discrepancy, fixed by
the manual PR rather than the compiler). CHANGELOG.md #70: "the clause
was parsed and thrown away, so `append each name from names treating "-"
as "anon" to out.` appended `["ann", "-"]`... Written after the
destination it now names itself instead of falling through as `Expected
a statement, got Treating`" — part 2, the silent no-op, fixed in the
compiler. Re-ran the D3.vox repro shape against 0.4.10:
`append each item from src treating 2 as 20 to dst.` now compiles (as it
did before) **and** substitutes (`dst` is `[1, 20, 3]`, not `[1, 2,
3]`), agreeing with `Print each`'s behaviour (GRM-16, `BAS2-52.vox`).
Both symptoms are closed.

## Invariants this section justifies

This section's own claims are almost entirely about **what parses**, not
about what a compiling program must always contain — so it justifies
very few corpus-level invariants on its own. The two genuine ones:

- byte-for-byte, the article before a type keyword is always `a` or `an`, never a bare type name — LANGUAGE.md:5824, GRM-03 (cross-ref VAR-01)
- a function call's connector is always one of exactly `of`/`with`/`to`/`on`, never a bare juxtaposition or another preposition — LANGUAGE.md:5836, GRM-08 (cross-ref FUN-32)

Everything else this section documents (operator precedence, the type
list, the literal list) is a closed, exhaustive vocabulary the compiler
enforces at the grammar level — a generator cannot produce an
out-of-vocabulary token that still compiles, so there is nothing for
`scripts/invariants` to flag as *suspiciously* uniform; uniformity there
is the language, not an undeclared generator rule.

## Report

**23 rows** (GRM-01 through GRM-23; GRM-02 and GRM-07 folded with no
independent probe, per the header). All 21 non-folded, non-compile-error
rows hand-verified and passing; 1 row (GRM-23) is a compile-error claim,
not assertable from a generated leaf, also hand-verified. **3
discrepancies**, none filed at the time: two (Discrepancies 1 and 2) are
**already adjudicated findings from expressions.md**, independently
rediscovered here before the cross-reference was found — recorded rather
than duplicated, because their line numbers fall inside this ledger's own
range and a reader of only this section would hit the identical trap.
The third (Discrepancy 3, append_stmt's `treating` clause) was genuinely
new here: no existing ledger row (`grep -rn "append.*treating"` across
`collections-b.md`/`basics-expansion.md` found nothing) already covered
the combination of append-each plus a substitution. **Discrepancy 3
RESOLVED, 2026-08-22 — vox #70 (0.4.10), manual grammar also corrected**
(see the discrepancy's own entry above).

**The gaps that matter — grammar forms NO section ledger covers**, as
asked for explicitly:

1. ~~**GRM-21/GRM-23 (name/identifier, string-as-data-not-name)**~~ —
   **update, 2026-08-22: closed.** `names-and-strings.md` (LANGUAGE.md
   645–670, prefix `NAM`) was unmapped when this row was first written;
   it has since been mapped (7 rows, `NAM-01`–`NAM-07`). GRM-21 now
   cross-refs `NAM-07` for the bare-or-single-quoted restatement and
   GRM-23 cross-refs `NAM-03` for the worked example's compile-error
   claim, both re-verified. `names-and-strings.md`'s own Discrepancy 1
   (the pre-0.3.0 pointer-as-number story's *narrower* claim did not
   hold under an 0.4.8 compiler) is now resolved by vox #65 as of 0.4.9.
2. **GRM-06/GRM-08 (`of` at a definition's parameter-introducer position
   vs. call position)** — these are two *different* gaps that read as
   one at a skim. FUN-06 already flags `of` missing at the **definition**
   site (`To 'name' of a number called x...`); FUN-32 already flags
   `to`/`with`/`on` missing at the **call** site. Both gaps are real,
   both are already recorded in `functions.md`, and neither needed a new
   row here — but a mapper skimming only the Grammar Summary could
   easily conflate "of/with are interchangeable" (definition side) with
   "of/with/to/on are interchangeable" (call side) and think one gap
   closes the other. It does not: closing FUN-06 (emit `of` in a
   definition) does nothing for FUN-32 (emit `to`/`with`/`on` in a
   call), and vice versa.
3. **GRM-12's if_stmt-level `But if ... then,` chain form** — FLW-03
   already hand-verified this works, but its own status is `todo`: no
   leaf in `main` emits it. Every existing leaf's "but if" is the
   *print_stmt*-level one (GRM-15, no `then`), not this one — so despite
   being the Grammar Summary's own headline `if_stmt` alternative, the
   only `but if` any generated program has ever contained is the *other*
   production entirely.

**Biggest single finding:** two discrepancies that squarely belong to
this section's own text (parenthesized grouping, `expr` vs. `condition`)
were already found and adjudicated by a *different* mapper working
`expressions.md`, whose own writeup explicitly says so ("recorded here
rather than left to the GRM ledger because it directly contradicts a
claim inside this section's line range"). That cross-reference worked as
designed — but it means a chunk of this section's own claims were
effectively pre-mapped by someone who never opened this file. Worth
generalizing: before hand-verifying a Grammar Summary production, grep
every existing `discrepancy` block across `docs/ledger/*.md` for the
production's own line number — LANGUAGE.md is one document, and a
Grammar Summary line frequently restates a claim some other section's
mapper already tested against the compiler, sometimes with the exact
repro already sitting in a probes directory.

**For future work on this section:** GRM-19's `primary` fix (add a
`{...}` alternative once the `"(" expr ")"` line is corrected) is the
remaining highest-value next step — a two-line manual fix already
scoped by EXP-D5. (The `names-and-strings.md` gap noted above at the
time of the original mapping has since been closed.)
