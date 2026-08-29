# Claim ledger: Expressions

Source: `../vox/LANGUAGE.md` lines **1816–2072** — the whole of
`## Expressions`: Literals, Variable Reference, Arithmetic, Comparisons,
Property Checks, Logical Operators, Plural Comparisons with `are`, and
Type Casting.

Manual version: **Vox 0.4.10** (5545 lines, vox `527cb89`), re-pinned
2026-08-22 (previously pinned to a 5611-line 0.4.10 manual). The chapter
heading held at a uniform **+27** shift from 0.4.8 through roughly
EXP-89 (old line 2006), but the manual grew a further ~12 lines inside
the Type Casting / `in` Keyword / Formatted Output subsections between
0.4.8 and 0.4.9 — a genuine content addition, not just reflow — so
EXP-85 through EXP-99 needed individual re-derivation rather than the
uniform offset. Each was landed by searching for its claim's actual
sentence, not by extrapolating the shift. `## Control Flow` now opens at
2073.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct, or `none`, and was filled by
grepping the emitted string literals in `src/gen_*.vox` — not by leaf
name. `status` is `exercised` (a leaf emits the construct and the program
must not crash), `verified` (it also asserts the documented result),
`todo`, `not assertable`, or `folded into X`.

**No leaf in this section asserts anything.** Every existing leaf that
touches an expression either `Print`s a value for a human to eyeball or
branches and prints a fixed label. That is the same finding the buffer
ledger reached, and it is uniform here too, so nothing below is
`verified`. Unlike buffers, though, this section is nearly all
assertable: the generator picks both operands, so it knows every answer.
**88 of the 100 rows can carry an `Exit 95` assertion**, and most of them
are one line of arithmetic away.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` pinned
to the sibling `coreasm`) before being written.

## Probes

Retained, runnable, in `docs/ledger/probes/expressions/`, one file per
hand-verified row named `EXP-NN.vox`. A probe covering more than one row
is named for the first and says so in its own header. Each file is a
single `(...)` comment naming the claim, recording the exact `Ran:`
command, and recording under `expected output:` what the compiler
**actually** printed — then the program. Compile-error rows are probes
too and record the diagnostic; EXP-26 records a runtime `exit 1`.

The five discrepancies each have a dedicated minimal repro at
`D1.vox`–`D5.vox` in the same directory. No probe reads a fixture, so
the directory is location-independent.

**39 probe files + 5 discrepancy repros = 44.** All 44 were re-run in one
final pass with `docs/check-probes.sh docs/ledger/probes/expressions`:
**44 passed, 0 failed, 0 skipped.**

A row has no probe file of its own when it is `folded into` a sibling
(EXP-91, EXP-92, EXP-93, EXP-95, EXP-99) or when a sibling's probe covers
it and says so in its header — the `Also covers:` line names every such
row. Every one of the 100 rows has exactly one **owning** probe that way;
some are named again in a sibling's header as a cross-reference, which is
a pointer, not a second owner.

Nothing in this section is `not assertable` on the "invisible
implementation detail" grounds that took four buffer rows out. Every
claim here is observable from inside a Vox program; the seven
`not assertable` rows are unreachable for a different reason, given in
the Report.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| EXP-01 | 1912 | Integer literals are a literal form: `42`, `0`, `-5`. | emit an integer literal, including a negative one, as an initializer and as an operand | yes — `If whole is not 42 then, Exit 95.` | `gen new var` (`gen_core.vox:36`) emits every program's `a number called v{n} is <literal>` via `gen extreme number` | exercised (non-negative only — `gen extreme number` never returns a `-` literal, so the manual's own `-5` case is unreachable) | |
| EXP-02 | 1913 | Float literals are a literal form: `3.14`, `-2.5`, `0.0`. | emit a float literal, including a negative one and `0.0` | yes — `If ratio is not 3.14 then, Exit 95.` | `gen leaf float math` (`gen_core.vox:401`) via `gen extreme float` | exercised (non-negative only; `gen extreme float` never emits a leading `-`, and never `0.0` — its fixed picks are `0.000000000000000000001` and `9223372036854775807.5`) | |
| EXP-03 | 1914 | String literals are a literal form: `"Hello, World!"`. | emit a double-quoted string literal | yes — print it and compare | everywhere; every leaf emits string literals | exercised | |
| EXP-04 | 1915 | Boolean literals are a literal form: `true`, `false`. | emit both `true` and `false` as literals | yes — `If affirmed is not true then, Exit 95.` | `gen leaf format types` (`gen_text.vox:275`) and the hex-format leaf (`gen_text.vox:460`) both emit `a boolean called ... is true` | exercised for `true` only — **`false` is never emitted as a literal by any leaf**; it appears only inside the argv assertion's `is false` condition (`gen_misc.vox:319`), which is a comparison, not a literal | |
| EXP-05 | 1916 | Hexadecimal literals use the `0x` prefix: `0xFF`, `0xDEADBEEF`. | emit a `0x…` literal in initializer and operand position | yes — `If 'byte mask' is not 255 then, Exit 95.` | **none** — grep finds no emitted `0x` literal anywhere in `src/` | todo — real gap, hand-verified to work; matches BUF-23's finding that hex byte literals are untouched | |
| EXP-06 | 1917 | Binary literals use the `0b` prefix: `0b10110100`, `0b1111`. | emit a `0b…` literal | yes — `If pattern is not 180 then, Exit 95.` | **none** | todo — real gap, hand-verified to work | |
| EXP-07 | 1918 | Character literals use single quotes: `'A'`, `'!'`. | emit a `'c'` literal, including a punctuation one | yes — `If letter is not 65 then, Exit 95.` | **none** — single quotes appear in emitted code only as multi-word *name* delimiters | todo — real gap, hand-verified to work; note the lexer resolves `'A'` as a character rather than as a one-letter quoted name | |
| EXP-08 | 1920 | A float literal is recognized by the presence of a decimal point. | declare `0` as a number and `0.0` as a float and show the two render differently | yes — the float prints `0.0`, the integer prints `0` | `gen leaf float math` emits `{whole}.{fraction}` literals, so the point is always present, but nothing pairs a pointed and an unpointed literal to show the point is what did it | exercised (partially — the discriminating pair is absent) | |
| EXP-09 | 1920 | Floats and integers can be mixed in one arithmetic expression. | emit `<float> add <integer>` and `<integer> add <float>` | yes — `If mixed is not 5.5 then, Exit 95.` | `gen leaf float math` (`gen_core.vox:423`) emits `a float called d{n} is d{m} add {integer operand}` | exercised (one operand order only — the integer is always on the right) | |
| EXP-10 | 1922 | Arithmetic operates on numbers; booleans count as 0/1. | emit a boolean in an arithmetic operand position and assert 1 / 0 | yes — `If upvote is not 1 then, Exit 95.` | **none** — no emitted arithmetic expression has a boolean operand | todo — hand-verified: `true add 0` is 1, `false add 0` is 0, `true add true` is 2 | |
| EXP-11 | 1922, 2177 | A **text** used directly in arithmetic is a compile error, not a coercion. | emit the illegal form deliberately, in a harness slot that expects a compile failure | yes, but **inverted** — the generated program must NOT compile, so this cannot be a leaf in the ordinary corpus; it belongs in a negative-compile fixture set the runner scores separately | none, and correctly so — every existing text-to-arithmetic path casts first (`gen leaf cast and break`, `gen leaf base conversion`) | not assertable **as a normal leaf** — needs a negative-compile channel the harness does not have; probe retained | |
| EXP-12 | 1922, 2177 | A **buffer** used directly in arithmetic is a compile error, with its own diagnostic. | same as EXP-11 | same as EXP-11 | none | not assertable as a normal leaf; probe retained | |
| EXP-13 | 1922, 2177 | A **list** used directly in arithmetic is a compile error. | same as EXP-11 | same as EXP-11 | none | not assertable as a normal leaf; probe retained — note the diagnostic offers no cast, because no list-to-number cast exists, so :2025's "cast them with `as a number`" is wrong for lists | |
| EXP-14 | 1925 | `0xFF` equals 255. | assert the value of a hex literal | yes — `If mask is not 255 then, Exit 95.` | none (see EXP-05) | todo | |
| EXP-15 | 1926 | `0b1010` equals 10. | assert the value of a binary literal | yes | none (see EXP-06) | todo | |
| EXP-16 | 1927 | `'A'` equals 65. | assert the value of a character literal | yes | none (see EXP-07) | todo | |
| EXP-17 | 1931 | `the x` references the variable `x`. | emit a `the`-prefixed variable reference | yes — compare `the x` against `x` | `gen leaf time` (`gen_misc.vox:216`, `:219`, `:221`) is the **only** place any emitted line writes `the` before a name, and there it precedes a timer/time name | exercised (three lines of one leaf); see the invariant note below — the article is effectively pinned to "absent" everywhere else | |
| EXP-18 | 1932 | `the number` references the loop iterator inside `for each`. | emit `the number` inside a range loop | yes — sum the iterations and assert the total | **none** — `gen leaf loop break`/`continue`/the nested-loop head (`gen_flow.vox:426`, `:434`, `:463`) all emit the bare `number` spelling | todo for the documented spelling; the bare spelling is exercised | |
| EXP-19 | 1933 | A bare identifier `x` references the variable. | emit a bare variable reference | yes | `gen var ref` (`gen_core.vox:437`) — every operand in every arithmetic and condition leaf | exercised | |
| EXP-20 | 1938 | `add` is the addition keyword. | emit `x add y` | yes — `If sum is not 15 then, Exit 95.` | `gen deep expr` (`gen_core.vox:280`), `gen leaf deep arithmetic`, `gen leaf float math`, `gen leaf format expression` | exercised | |
| EXP-21 | 1939 | `subtract` is the subtraction keyword. | emit `x subtract y` | yes | `gen thing mirror` (`gen_things.vox:131`) — and **only** there, as the fixed line `Set mirrored's x1 to 0 subtract original's x1`. `gen deep expr`'s operator table uses `minus`, the synonym from the Operators chapter, not the spelling this section documents | exercised (one fixed shape; the left operand is always the literal `0`) | |
| EXP-22 | 1940 | `multiply` is the multiplication keyword. | emit `x multiply y` | yes | `gen deep expr`, `gen leaf deep arithmetic`, `gen leaf float math`, `gen leaf format expression` | exercised | |
| EXP-23 | 1941 | `divide` is the division keyword. | emit `x divide y` | yes | `gen deep expr` (`gen_core.vox:288`), `gen leaf float math` (`gen_core.vox:420`) | exercised | |
| EXP-24 | 1942 | `modulo` is the remainder keyword. | emit `x modulo y` | yes | `gen deep expr`, `gen leaf deep arithmetic`, `gen condition`'s `modulo … is equal to 0` | exercised | |
| EXP-25 | 1943 | `{x add y} multiply z` — curly braces group a subexpression and override precedence. | emit both the braced and the flat form of one expression and assert they differ | yes — 2/3/4 gives 14 flat and 20 braced | `gen leaf deep arithmetic` (`gen_core.vox:469`) emits `{a add b} multiply c modulo d`; `gen deep expr` builds nested braces | exercised (the flat/braced *pair* that proves grouping did something is never emitted) | |
| EXP-26 | 1944 | `{fibonacci of n subtract 1} add {fibonacci of n subtract 2}` is a valid braced arithmetic subexpression. | emit a braced expression containing a function call | **yes, and taken literally it does not terminate** — see **Discrepancy 1**. `of` binds only the next primary, so this is `{f of n} subtract 1`, the argument never shrinks, and the runtime's depth guard stops it with `exit 1` | `gen call one`/`gen call two` emit calls, but never a call inside a braced arithmetic subexpression | todo — and blocked on D1 for the *documented* spelling. The runtime-safety half holds: the guard fires, nothing segfaults | blocked on D1 |
| EXP-27 | 1947 | `the` is optional before variable names in expressions. | emit the same expression with and without the article and assert equal results | yes — both sides are known | effectively **none** (see EXP-17) | todo — the optional form is never varied, which makes "no emitted expression contains `the`" an unjustified invariant | |
| EXP-28 | 1949 | Complex arithmetic subexpressions are grouped with `{...}`. | emit a multi-level braced expression | yes | `gen deep expr` (`gen_core.vox:265` onward) nests braces to a random depth | exercised | |
| EXP-29 | 1950, 2174 | A cast binds tighter than arithmetic and applies to the expression immediately to its left. | emit `a add b as a number` where the two readings differ, and assert the tight one | yes — `3.5 add {2.5 as a number}` is 5.5; the loose reading would be 6 | **none** — no emitted line puts a cast next to an arithmetic operator at all | todo — hand-verified: tight binding, exactly as documented | |
| EXP-30 | 1950, 2174 | Bracing casts a whole arithmetic expression: `{a add b} as a number`. | emit a braced expression followed by a cast | yes — `{3.5 add 2.5} as a number` is 6 | **none** | todo — hand-verified | |
| EXP-31 | 1951 | Comma-separated arithmetic continuation (`…, add …`) is not valid syntax. | deliberately emit the illegal form | inverted, like EXP-11 — the program must fail to compile | none, and correctly so | not assertable as a normal leaf; probe retained. This one is load-bearing for the generator itself: `gen line piece` comma-joins nested lines, and a comma landing mid-expression is exactly this error | |
| EXP-32 | 1956 | `is greater than` compares two values. | emit the comparison in an `If`, in both polarities | yes | `gen condition` (`gen_core.vox:186`), `gen leaf nested if` (`gen_flow.vox:490`) | exercised | |
| EXP-33 | 1957 | `is less than` compares two values. | as above | yes | `gen condition` (`gen_core.vox:188`), `gen leaf loop while` (`gen_flow.vox:272`) | exercised | |
| EXP-34 | 1958 | `is equal to` compares two values. | as above | yes | `gen condition` (`gen_core.vox:190`), the loop-control leaves, `gen leaf clock` | exercised | |
| EXP-35 | 1959 | `x is 0` — a bare value on the right is an equality comparison. | emit `<var> is <literal>` as a condition | yes | **none** — `gen condition` always spells the operator out; every emitted equality is `is equal to` | todo — hand-verified to work and to be the shorter spelling of EXP-34 | |
| EXP-36 | 1962 | `the` is optional before variable names in comparisons. | emit both spellings of one comparison | yes | none (see EXP-17) | todo — same unjustified invariant as EXP-27 | |
| EXP-37 | 1953–1960 | The Comparisons block sits under `## Expressions`, so a comparison is an expression — and the Grammar Summary (`:5230–5232`) derives `comparison` from `expr`. | emit a comparison outside a condition position | **no** — the compiler refuses it. See **Discrepancy 3** | none, and `gen_core.vox:173` already documents the restriction as hand-verified | not assertable — the claim is false as stated; `gen condition`'s confinement to `If`/`while`/`but if` is the correct generator behaviour and is currently an **unjustified** invariant, because the manual does not state the restriction | blocked on D3 |
| EXP-38 | 1967 | `x is even` is true iff x is even. | emit in both polarities and assert | yes — parity of the generated literal is known | `gen leaf predicate probe` (`gen_misc.vox:433`) | exercised | |
| EXP-39 | 1968 | `x is odd` is true iff x is odd. | as above | yes | **none** — `gen leaf predicate probe` reaches oddness only through the `Otherwise` branch of `is even`, which is a different construct | todo | |
| EXP-40 | 1969 | `x is positive` is true iff x > 0. | as above, including x = 0 | yes | `gen leaf predicate probe` (`gen_misc.vox:434`), `gen leaf time` (`gen_misc.vox:220`) | exercised (never against 0, the interesting boundary — hand-verified: 0 is **not** positive) | |
| EXP-41 | 1970 | `x is negative` is true iff x < 0. | as above | yes | **none** — and no leaf emits a negative literal for it to be true of (see EXP-01) | todo | |
| EXP-42 | 1971 | `x is zero` is true iff x = 0. | as above | yes | `gen leaf predicate probe` (`gen_misc.vox:435`) | exercised | |
| EXP-43 | 1972 | `<list> is empty` is true iff the list has no elements. | emit `is empty` on a **list**, full and empty | yes — the generator built the list | `gen leaf file stat` (`gen_files.vox:139`) uses it on a **buffer**; `gen leaf predicate probe` (`gen_misc.vox:431`) uses it on a **text**. Neither is a list | todo for the list case. See **Discrepancy 4** — the manual's own example line cannot be written, because `list` is a reserved word | |
| EXP-44 | 1978 | `<condition> and <condition>` is true iff both are true. | emit an `and` join and assert all four rows of the table | yes | `gen condition` (`gen_core.vox:203`) | exercised | |
| EXP-45 | 1979 | `<condition> or <condition>` is true iff either is true. | as above | yes | `gen condition` (`gen_core.vox:205`) | exercised | |
| EXP-46 | 1980 | `not <condition>` is true iff the condition is false. | emit a `not` condition | yes | **none** — grep finds no emitted `not ` outside `is not equal to`, which is a comparison operator, not the `not` unary | todo — real gap, hand-verified in `If`, `While` and `but if` positions | |
| EXP-47 | 1999 | Several variables can be tested against one value using comma-separated subjects and `are`. | emit a plural comparison | yes | **none** — no emitted line contains `are` | todo — the whole plural surface is unfuzzed | |
| EXP-48 | 2002 | `if x, y, and z are true` is the canonical shape. | emit it | yes | none | todo | |
| EXP-49 | 2003 | `if a, b, and c are not false` — the `are not` form. | emit it | yes | none | todo | |
| EXP-50 | 2004 | A subject may be a single-quoted multi-word name (`'door open'`). | emit a plural comparison with a quoted subject | yes | none for the plural form; quoted names themselves are emitted widely (`'read flags {n}'`, `gen_misc.vox:415`) | todo | |
| EXP-51 | 2009–2014 | `if x, y, and z are true` expands to `if x is true and y is true and z is true`. | emit both forms on the same subjects and assert they agree | yes — hand-verified to agree on all four combinations tried | none | todo — this is the highest-value row in the plural block: it is a *differential* assertion, so it catches an expansion that drops or duplicates a subject without needing to know the right answer | |
| EXP-52 | 2017 | Subjects are separated by commas. | vary the subject count | yes | none | todo — hand-verified at 2, 3 and 5 subjects | |
| EXP-53 | 2018 | The `and` before the last subject is optional. | emit both spellings | yes | none | todo — hand-verified: `x, y, z are true` parses | |
| EXP-54 | 2019 | The predicate after `are` applies to **all** subjects. | flip one subject and assert the clause stops firing | yes | none | todo — hand-verified | |
| EXP-55 | 2020 | `are not` negates the comparison for all subjects. | leave one subject satisfying the predicate and assert the clause does not fire | yes | none | todo — hand-verified: it is a conjunction of negations, not a negated conjunction | |
| EXP-56 | 2024 | Values are converted between types with the `as` or `in` keywords. | emit both keywords | yes | `as`: `gen leaf cast and break`, `gen leaf base conversion`, `gen leaf env`. `in`: `gen leaf time` (`gen_misc.vox:216`) | exercised | |
| EXP-57 | 2028 | `<value> as a <type>` is the articled cast syntax. | emit it | yes | `gen leaf cast and break` (`gen_misc.vox:172`), `gen leaf base conversion` | exercised | |
| EXP-58 | 2029, 2173 | `<value> as <type>` — the article is optional and the two forms are equivalent. | emit both and assert equal results | yes | `as text` is emitted (`gen_misc.vox:172`); no leaf emits `as number` or `as float` article-free, and none pairs the two spellings | exercised (for `as text` only, which is the one type whose articled form is not the natural spelling); the equivalence itself is never put on trial | |
| EXP-59 | 2030 | `<value> in <unit>` is a cast syntax. | emit an `in` cast | yes | `gen leaf time` (`gen_misc.vox:216`), only ever `elapsed in milliseconds` | exercised (one property, one unit) | |
| EXP-60 | 2037 | float → number: `3.14 as a number` gives `3`, truncated. | cast a generated float and assert the truncation | yes — the generator wrote the float | **none** | todo | |
| EXP-61 | 2038 | number → float: `42 as a float` gives `42.0`. | cast and assert | yes | **none** | todo | |
| EXP-62 | 2039 | number → text: `25 as text` gives `"25"`. | cast and assert | yes | `gen leaf cast and break` (`gen_misc.vox:172`) | exercised | |
| EXP-63 | 2040 | text → number: `"123" as a number` gives `123`. | cast and assert | yes | `gen leaf cast and break` (`gen_misc.vox:174`), `gen leaf base conversion` (`gen_text.vox:131`) — the round-trip through text and back is the point of the first | exercised | |
| EXP-64 | 2041 | float → text: `3.14 as text` gives `"3.14"`. | cast and assert | yes | **none** — `gen leaf cast and break` casts only the integer literal | todo | |
| EXP-65 | 2042 | text → float: `"3.14" as a float` gives `3.14`. | cast and assert | yes | **none** — no leaf emits `as a float` at all | todo | |
| EXP-66 | 2043 | boolean → number: `true as a number` gives `1`. | cast and assert | yes | **none** | todo | |
| EXP-67 | 2044 | boolean → number: `false as a number` gives `0`. | cast and assert | yes | **none** (and see EXP-04 — `false` is never emitted as a literal) | todo | |
| EXP-68 | 2045 | number → boolean: `0 as a boolean` gives `false`. | cast and assert | yes, but assert through `as text` or a condition — a bare `Print` of a boolean shows `0`, per LANGUAGE.md:2396, which cannot be told from a number | `gen leaf env` (`gen_misc.vox:85`) emits `Print env{n}count as a boolean` | exercised (never against 0, and printed rather than asserted) | |
| EXP-69 | 2046 | number → boolean: `42 as a boolean` gives `true`. | cast and assert | yes (same caveat) | `gen leaf env` (`gen_misc.vox:85`) | exercised | |
| EXP-70 | 2047 | boolean → text: `true as text` gives `"true"`. | cast and assert | yes | **none** | todo — hand-verified, and it is the cleanest way to assert EXP-68/69, since `as text` renders `true`/`false` where `Print` renders 1/0 | |
| EXP-71 | 2048 | text → boolean: `"true" as a boolean` gives `true`. | cast and assert | yes | **none** | todo | |
| EXP-72 | 2049 | buffer → text: `data as text` gives a copy of the buffer's bytes. | cast a buffer whose contents the generator wrote, assert the text | yes | **none** — `loop_gen.vox:232` casts a buffer to text in the *generator*, not in a generated program | todo | |
| EXP-73 | 2051–2057 | The text made from a buffer is an **independent copy**: clearing, refilling or resizing the buffer leaves the text unchanged. | build a text from a buffer, then mutate and resize the buffer, then assert the text | yes — both values are known | **none** | todo — high value: the manual's own stated reason is that a window would read freed memory after a resize, so this is a memory-safety row, not a formatting one. Hand-verified across `clear`+`append` and across a 16→8192 byte `grow` | |
| EXP-74 | 2061–2062 | A radix word may be inserted right before `number` to parse in another base. | emit the radix forms | yes | `gen pick parse form` (`gen_text.vox:28`), used by `gen leaf base conversion` | exercised | |
| EXP-75 | 2066 | `as a number` is base 10. | emit and assert | yes | `gen pick parse form` (`gen_text.vox:44`) | exercised | |
| EXP-76 | 2067 | `as a hex number` / `as a hexadecimal number` are base 16. | emit both spellings and assert | yes | `gen pick parse form` (`gen_text.vox:36`, `:38`), weighted so base 16 is actually reachable | exercised | |
| EXP-77 | 2068 | `as an octal number` is base 8. | emit and assert | yes | `gen pick parse form` (`gen_text.vox:40`) | exercised | |
| EXP-78 | 2069 | `as a binary number` is base 2. | emit and assert | yes | `gen pick parse form` (`gen_text.vox:42`) | exercised | |
| EXP-79 | 2091 | `as a base N number` — the spaced form, any base 2–36. | emit and assert | yes | `gen pick parse form` (`gen_text.vox:47`) | exercised | |
| EXP-80 | 2092 | `as a baseN number` — the fused form, any base 2–36. | emit and assert | yes | `gen pick parse form` (`gen_text.vox:46`) | exercised | |
| EXP-81 | 2094–2097 | Any base 2–36 works; digits above 9 use `a`–`z`, case-insensitively. | emit both ends of the range, and the same digits in both cases | yes — `gen digit for value` already knows each digit's value | `gen leaf base conversion` draws `base` from 2–36 and builds digits from that base's own alphabet (`gen_text.vox:107`, `:118`) | exercised for the range; **todo for case-insensitivity** — `gen digit for value` returns one fixed case, so `"ZZ"` and `"zz"` are never compared | |
| EXP-82 | 2099–2114 | The radix worked example compiles and gives the values its own comments claim. | reproduce verbatim | yes — hand-verified: `1067631076`, `2334`, `2334`, `-26`, `255` | none as a composite; every sub-claim is covered by EXP-74–EXP-80 | todo (as a composite) — hand-verified to reproduce exactly, negative and uppercase cases included | |
| EXP-83 | 2116–2118 | Parsing stops at the first character invalid for the base: `"12g5" as a hex number` gives 18. | emit a string with a valid prefix and an invalid tail, assert the prefix's value | yes — the generator chose both halves | **none** — `gen leaf base conversion` builds digits from the base's own alphabet on purpose, so a partial parse is never generated | todo — real gap, and the higher-value half of the base-conversion surface, since the well-formed path is already exercised | |
| EXP-84 | 2118–2120 | A string invalid from its very first character gives 0 (`"abc" as a base5 number`). | emit such a string, assert 0 | yes | **none** | todo — hand-verified in base 5, base 10 and base 16, and for the empty string | |
| EXP-85 | 2133–2154 | The casting Examples block compiles and gives the documented results. | reproduce verbatim | yes | none as a composite; sub-claims at EXP-60, EXP-62, EXP-63, EXP-66 | todo (as a composite) — hand-verified; note `pi`, `'pi truncated'` and `'done num'` are all legal names, so unlike EXP-43 this block is literal code | |
| EXP-86 | 2153 | A cast can be written inline in a statement: `Print 3.14159 as a number`. | emit a cast in argument position rather than in an initializer | yes | `gen leaf env` (`gen_misc.vox:85`) emits `Print env{n}count as a boolean` | exercised | |
| EXP-87 | 2158–2164, 2194 | `in` applies to a timer's `duration` or `elapsed`, casting it to a unit. | emit both properties and more than one unit | yes, but only as a **range** assertion — wall-clock readings are not exact. `If 'seconds so far' is less than 1 then, Exit 95.` after a one-second wait | `gen leaf time` (`gen_misc.vox:216`) — `elapsed in milliseconds` only; `duration in <unit>` is never emitted, nor is any unit but milliseconds | exercised (one property, one unit) | |
| EXP-88 | 2167–2168 | `<number> in <unit>` on a plain number is not valid syntax. | deliberately emit the illegal form | inverted, like EXP-11 | none, and correctly so | not assertable as a normal leaf; probe retained | |
| EXP-89 | 2168–2169 | To convert a plain number of milliseconds to seconds, divide: `the millis divide 1000`. | emit the division and assert | yes | `gen deep expr` emits `divide`, but never this idiom against a millisecond value; `gen leaf time` reads `elapsed in milliseconds` and never divides it | todo — hand-verified, and note the division truncates: 5999 divide 1000 is 5 | |
| EXP-90 | 2171–2181 | The zero-pad format specifier converts a number to padded text: `{h:02}` on 9 gives `"09"`. | emit a zero-padded interpolation and assert the text | yes — the generator picks both the number and the width | `gen leaf format types` and `gen leaf format padding` (`gen_text.vox:206`, `:216`, `:268`) emit random zero widths | exercised | |
| EXP-91 | 2184 | `as a <type>` and `as <type>` are equivalent. | — | — | — | folded into EXP-58 | |
| EXP-92 | 2185 | A cast binds tighter than arithmetic; brace to cast a whole expression. | — | — | — | folded into EXP-29 and EXP-30 | |
| EXP-93 | 2186 | Float to number **truncates**, it does not round. | — | — | — | folded into EXP-60 | |
| EXP-94 | 2187 | To round, add 0.5 before casting: `{3.7 add 0.5} as a number` gives 4. | emit the idiom and assert | yes — hand-verified: 3.7 gives 4, 3.2 gives 3, so it really rounds | **none** | todo | |
| EXP-95 | 2188 | Text, buffers and lists cannot be used directly in arithmetic. | — | — | — | folded into EXP-11, EXP-12, EXP-13 — but note the bullet's advice is wrong for lists, which have no numeric cast at all | |
| EXP-96 | 2189 | Text to number **fails** if the text is not a valid number, and sets the error flag. | cast an invalid string, assert the error flag fired and the value is 0 | yes, **with a correction** — the flag fires only when *zero* characters parse. `"12xy" as a number` gives 12 and leaves the flag clear. See **Discrepancy 2** | **none** — no leaf emits a text-to-number cast that can fail | todo — real gap, and a memory-safety-adjacent one: nothing today makes a generated program take the failing branch of a cast | blocked on D2 |
| EXP-97 | 2190–2192 | A non-default-base cast stops at the first invalid character and **does not set the error flag**. | cast a partly-valid and a wholly-invalid string in a non-default base, assert the flag in each case | yes, **with a correction** — the stopping half holds, the flag half does not: `"abc" as a base5 number` sets the flag. See **Discrepancy 2** | **none** | todo | blocked on D2 |
| EXP-98 | 2193 | Zero is `false`; any non-zero number is `true`. | emit a number in condition position and assert which branch runs | yes | **none** — every emitted condition is an explicit comparison or predicate; no leaf ever puts a bare number in condition position | todo — hand-verified, negative numbers included | |
| EXP-99 | 2194 | The `in` keyword is for timer `duration`/`elapsed` casts. | — | — | — | folded into EXP-87 | |
| EXP-100 | 2094 (undocumented precision) | *(not a manual claim — a gap in the manual)* A base outside 2–36 is a **compile** error, not a runtime error and not a silent clamp. | — | inverted, like EXP-11 — but this row's real consequence is a constraint on leaves: any leaf drawing a random base must draw from 2–36, or the generated program will not compile | `gen leaf base conversion` already draws `'rng below' of 35 add 2`, which is exactly 2–36 — the constraint is honoured, silently | not assertable as a normal leaf; probe retained. This is what **justifies** the "base is always 2–36" invariant the corpus shows | |

## Discrepancies

### 1. The manual's own arithmetic example does not compute what it says — a call argument binds tighter than arithmetic

LANGUAGE.md:1944 offers, as an example of braced arithmetic subexpressions:

```
{fibonacci of n subtract 1} add {fibonacci of n subtract 2}
```

`of` binds only the next primary. The braces therefore contain
`{fibonacci of n} subtract 1`, not `fibonacci of {n subtract 1}` — the
argument never shrinks, and the function recurses until the runtime's
depth guard stops it. Repro, `D1.vox`:

```
To halve with a number called n. Return a number, n divide 2.

Print {halve of 10 subtract 4}.
Print {halve of {10 subtract 4}}.
```

Output: `1`, then `3`. `halve of 10 subtract 4` is `{halve of 10}
subtract 4` = 1, not `halve of 6` = 3. `EXP-26.vox` records the
fibonacci form itself: `Error: stack overflow (recursion depth
exceeded)`, `exit 1`.

**The reading in which the compiler is correct.** The Function Calls
section (LANGUAGE.md:881-884) says only "For calls with arguments, use
`of`, `to`, `with`, or `on`" and "Multiple arguments separated by
`and`". It never says an argument may be an arithmetic expression, and
the Grammar Summary's `args ::= arg_clause ("and" arg_clause)*` with
`arg_clause ::= loop_expansion | expr` is ambiguous about how far `expr`
extends before `and` or the end of the call. A tight binding is the only
one that keeps `f of x and g of y` from becoming unparseable. On that
reading the compiler is right and **line 1827 is a manual bug**: the
example needs to be `{fibonacci of {n subtract 1}} add {fibonacci of {n
subtract 2}}`, which does give 55 for n = 10 (last line of `D1.vox`).

Worth noting for triage: the *safety* half is fine. An unbounded
recursion is caught and reported, and the process exits 1 rather than
smashing the stack. Not filed.

### 2. The two error-flag bullets for text-to-number describe a rule neither of them states, and each is wrong in the opposite direction

LANGUAGE.md:2189 (was 2053) — "Text to number **fails** if text is not a valid
number (sets error flag)."
LANGUAGE.md:2190–2192 (was 2054–2056) — "Text to number in a non-default base … stops
parsing at the first character invalid for that base, rather than
failing outright — **it does not set the error flag**."

Repro, `D2.vox`, four casts crossing base 10 and base 16 with partial
and total failure:

```
base 10 partial   "12xy" as a number          -> 12,  flag CLEAR
base 10 total     "abc"  as a number          -> 0,   flag SET
hex    partial    "12g5" as a hex number      -> 18,  flag CLEAR
hex    total      "zzz"  as a hex number      -> 0,   flag SET
```

So base 10 does **not** "fail if the text is not a valid number" — a
valid prefix is enough — and a non-default base **does** set the flag
when nothing parses. The empty string also sets it (`EXP-96.vox`).

**The reading in which the compiler is correct.** There is one uniform
rule, and it is a good one: *parsing stops at the first character
invalid for the base, and the error flag is set iff zero characters were
consumed.* Every observation above follows from it. The two bullets are
then each a partial description written from a different example — 2026
from the `"abc"` case, 2027–2029 from the `"12g5"` case — and the
contrast between them is an artefact of which example the author had in
mind, not a real difference between bases. On that reading nothing is
wrong with the compiler and **both bullets are manual bugs**, replaceable
by the single sentence above.

This matters more than a wording fix: EXP-96 and EXP-97 are the rows a
leaf would use to make a generated program take the *failing* branch of a
cast, and a leaf built from the bullets as written would assert "no flag"
on a base-5 total failure and manufacture a finding on every seed. Not
filed.

### 3. Comparisons and property checks are documented as expressions and by the grammar, but the compiler accepts them only in condition position

The Comparisons block (1836–1843) and the Property Checks block
(1847–1856) are subsections of `## Expressions`. The Grammar Summary is
more explicit still:

```
expr        ::= or_expr                              (LANGUAGE.md:5866)
and_expr    ::= comparison ("and" comparison)*       (:5231)
comparison  ::= additive (comp_op additive)?         (:5232)
var_decl    ::= ("a"|"an") type "called" name "is" expr "."   (:5187)
```

Taken together those four productions say `a boolean called dominant is
x is greater than y.` parses. It does not — `Expected a statement, got
Is` (`EXP-37.vox`). Nor does `Print x is greater than y.`, nor `a
boolean called lopsided is x is odd.`. All three are accepted only
inside an `If`, `While` or `but if` condition (`D3.vox`).

**The reading in which the compiler is correct.** Vox's `is` is heavily
overloaded — it is also the declaration copula (`a number called x is
5.`) and the assignment verb (`the x is 5.`). In `a boolean called
dominant is x is greater than y.` the parser has already consumed one
`is` as the copula; a second `is` inside the initializer would make the
sentence genuinely ambiguous with a two-clause declaration. Confining
comparisons to a position where no copula is in play removes the
ambiguity, and it is the kind of restriction a natural-language grammar
has to make somewhere. On that reading the compiler is right and the
**manual is incomplete in two places**: the Comparisons and Property
Checks blocks need a sentence saying where these forms may appear, and
the Grammar Summary needs `condition` as a production distinct from
`expr`.

Until that is adjudicated, "no generated program contains a comparison
outside a condition" is an **unjustified invariant** in the corpus
report — the generator is doing the right thing for a reason nobody has
written down. `gen_core.vox:173` already carries the hand-verification
in a comment; it deserves a citation. Not filed.

### 4. A Property Checks example cannot be written as shown — `list` is a reserved word

LANGUAGE.md:1972, in a block of six one-line examples:

```
the list is empty
```

No variable may be called `list`: `Cannot use 'list' as a variable name
- it's a reserved keyword`. The other five lines of the same block use
`x`, `y`, `z`, `n` and `value`, and all five of those **are** legal
names — `value` is the one type name the compiler lets through, which I
checked against `number`, `text`, `map`, `buffer`, `boolean` and `float`,
all of which are refused. So the block otherwise reads as literal code
and this one line does not. Repro: `D4.vox`.

**The reading in which the compiler is correct.** The block is fenced
```` ```vox fragment ````, and the surrounding sections use the same
fence for shapes containing `<condition>` and `<statement>`
placeholders. On that reading `list` here is a placeholder standing for
"some list variable", not a name, and the compiler is simply enforcing
its own reserved-word rule. The counter-argument is that every other
identifier in the block is a real legal name, so a reader has no signal
that this one is not — which is precisely how a mapper (or a leaf) picks
up a form that cannot be generated. A one-character fix (`the roster is
empty`) removes the trap. Not filed.

### 5. The Grammar Summary says parentheses group expressions; in Vox they are comments

LANGUAGE.md:1949 says to group arithmetic subexpressions with `{...}`,
and :1853 shows `{x add y} multiply z`. The Grammar Summary at :5318
says:

```
primary ::= literal | identifier | func_call | "(" expr ")"
```

Parentheses are Vox's comment delimiters, so `(x add y)` is a comment
and the rest of the sentence loses its subject: `Print (x add y)
multiply z.` gives `Expected a statement, got Multiply`. Repro:
`D5.vox`.

**The reading in which the compiler is correct.** The comment syntax is
documented and load-bearing everywhere else in the language and in this
very ledger's probes; `{...}` is documented as the grouping punctuation
in the section this ledger maps. The compiler is unambiguously right and
the Grammar Summary line is a leftover from an EBNF template. It is
recorded here rather than left to the `GRM` ledger because it directly
contradicts a claim inside this section's line range — a reader who
trusts the grammar will write parenthesised arithmetic and get a
confusing error. Not filed.

## Invariants this section justifies

- arithmetic grouping is always `{...}`, never `(...)` — LANGUAGE.md:1949, EXP-28
- no comma ever continues an arithmetic expression — LANGUAGE.md:1951, EXP-31
- a text, buffer or list operand always carries a cast before reaching an arithmetic operator — LANGUAGE.md:1922, 2177, EXP-11/EXP-12/EXP-13
- a radix base is always between 2 and 36 — LANGUAGE.md:2094, EXP-100
- `in` never follows anything but a timer's `duration`/`elapsed` — LANGUAGE.md:2167, EXP-88
- a hexadecimal literal always carries `0x` and a binary literal always `0b` — LANGUAGE.md:1925–1926, EXP-05/EXP-06
- a character literal is always single-quoted — LANGUAGE.md:1927, EXP-07
- the plural `are` predicate is never a comparison operator, only a value — LANGUAGE.md:1999 "against the same value", EXP-47 (hand-verified: `are greater than 5` is a compile error)

**Not justified, and therefore defects** — every one of these is a
sameness the corpus shows that no line of the manual asks for. They are
listed here rather than in the rows because `scripts/invariants` will
report them and the next reader needs the verdict, not a hunt:

- no generated program contains a negative numeric literal (EXP-01, EXP-02, EXP-41)
- no generated program contains a hex, binary or character literal (EXP-05, EXP-06, EXP-07)
- every emitted boolean literal is `true` (EXP-04)
- `the` never precedes a variable in an emitted expression or comparison, outside three lines of `gen leaf time` (EXP-17, EXP-27, EXP-36)
- every emitted subtraction is `0 subtract <field>`, in one leaf (EXP-21)
- every emitted equality is spelled `is equal to`, never the bare `x is 0` (EXP-35)
- no emitted condition contains `not` (EXP-46)
- no emitted line contains `are` (EXP-47 … EXP-55)
- `is empty` is never applied to a list (EXP-43)
- ten of the thirteen basic conversions never appear (EXP-60/61/64/65/66/67/70/71/72)
- every emitted `in` cast is `elapsed in milliseconds` (EXP-59, EXP-87)
- every generated base-conversion string is well-formed for its base, so the partial-parse and total-failure paths are never taken (EXP-83, EXP-84, EXP-96, EXP-97)
- comparisons never appear outside a condition — correct behaviour, but currently uncited; see **Discrepancy 3**

## Report

**100 rows** (EXP-01 through EXP-100). Five are `folded into` a sibling
(EXP-91, EXP-92, EXP-93, EXP-95, EXP-99), leaving **95 distinct claims**.

Of those, **seven are `not assertable` by an ordinary leaf**. Six —
EXP-11, EXP-12, EXP-13, EXP-31, EXP-88, EXP-100 — are so for the *same*
reason, which is new and worth naming: they are claims that something is
a **compile error**. A generated program that fails to compile is scored
by `loop_gen.vox` as a generator defect, not a finding, so the corpus
cannot carry them. They need a negative-compile channel: a small fixture
set of programs the harness expects to be *rejected*, with the expected
diagnostic. That is a harness change, not a leaf, and it is the single
structural gap this section found. The seventh, EXP-37, is not assertable
because the claim is false as written — see Discrepancy 3. Everything
else — **88 rows** — is assertable today.

**Existing coverage is 42 rows `exercised`, 0 `verified`, 46 `todo`.**
The "no leaf asserts anything" pattern the buffer ledger predicted holds
here exactly, and this section is where it costs most: buffers had rows
that were genuinely hard to assert, whereas here the generator chose both
operands of nearly every expression it emits. `gen leaf deep arithmetic`
prints `{v1 add v2} multiply v3 modulo 4` and nobody checks the answer,
even though the generator computed the operands. Adding assertions to the
arithmetic, comparison, predicate and base-conversion leaves that already
exist would move roughly twenty rows from `exercised` to `verified`
without writing a single new leaf.

**Biggest finding: the plural `are` surface is completely unfuzzed.**
Nine rows (EXP-47 … EXP-55), no emitted `are` anywhere in `src/`, and it
is a *rewriting* feature — the compiler expands `x, y, and z are true`
into a conjunction before anything else sees it. That is exactly the
shape of construct that carries bugs indefinitely when nobody uses it,
the same story as the flag schema (#31/#32) and `is empty` (#33) noted in
`gen_text.vox`. EXP-51 is the row to build first, because it is
*differential*: emit the plural form and the written-out conjunction over
the same subjects and assert they agree. That catches a dropped or
duplicated subject without the generator needing to know the right
answer, and it scales to any subject count.

**Five discrepancies**, all with repros, none filed. Two of them (D1,
D2) are the kind that would have become false-finding factories: a leaf
built from LANGUAGE.md:1944 as written would generate a non-terminating
program on every seed and be scored as a hang, and a leaf built from
LANGUAGE.md:2190–2192 as written would assert "no error flag" on a case
where the flag reliably fires. D3 is the nastiest for a different
reason: it is an invariant the generator already honours correctly, for a
rule the manual does not contain, so it looks like a defect in the
invariant report and is not one.

**Advice for the next mapper.**

1. *Check the line range against the manual before you start.* The brief
   gave 1789–2025 from `INDEX.md`, pinned at 0.4.7; the section really
   runs to 2033 at 0.4.8, and the eight extra lines held four claims and
   one of the five discrepancies. Grep for the next `^## ` heading rather
   than trusting the table.
2. *Grep the emitted strings, not the generator's own code.* Nearly every
   arithmetic keyword appears hundreds of times in `src/gen_*.vox` as the
   generator's own arithmetic. What matters is what appears **inside a
   double-quoted string that reaches `gen emit`**. `grep -n '"[^"]*\bkeyword\b'`
   is the query; it turned "arithmetic is well covered" into
   "`subtract` appears exactly once, in a fixed line, with `0` on the
   left".
3. *Ask what the manual's optional forms are pinned to.* Every "X is
   optional" sentence is an invariant waiting to be found: the article in
   EXP-27 and EXP-36 is documented as optional twice and is fixed at
   "absent" in every emitted line. Those sentences are the cheapest way
   to find undeclared rules, because the manual has already told you the
   dimension is free.
4. *Reserved words will eat your probes.* `zero`, `negative`, `yes`,
   `remainder`, `bigger`, `minutes`, `year`, `list`, `stopwatch` and `a`
   are all reserved, and several of them are the obvious name for the
   variable a probe wants. Every one cost a compile cycle here. Budget
   for it, and note that `value` is the one type name that **is** a legal
   variable name.
5. *A comment that is not closed swallows the program.* Vox comments
   nest, so a probe header written as `(claim …` followed by
   `(expected output: … )` leaves the outer comment open and the whole
   program becomes a comment — it compiles, runs, and prints nothing.
   The PROCEDURE.md §4 format is one comment containing both; follow it
   literally. All 44 probes here silently produced empty output until
   this was fixed, and `docs/check-probes.sh` is what caught it.
