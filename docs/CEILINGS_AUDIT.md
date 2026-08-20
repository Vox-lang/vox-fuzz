# Ceilings audit — every bound the generator imposes

**Origin:** Josj, 2026-08-20: *"You said 0-8 flags, if we build that
we'll never know if setting a 9th flag would cause a segfault."*

Every cap in this generator is an unexamined claim that nothing
interesting happens past it. This is the list of those claims, so they
can be argued with individually instead of hiding in the source.

An audit, not a fix. Nothing here is changed yet.

---

## Class 1 — hardcoded. No variation whatsoever.

These are ceilings of one: the program always has exactly this, and no
seed can change it. The worst class, because there is not even a knob to
turn.

| What | Always | Consequence |
|---|---|---|
| thing types | **exactly 4** (`t1`–`t4`) | 0 things, 1 thing, 40 things: never generated |
| thing methods | **exactly 2**, both on `t4` | a thing with 5 methods, or none, never generated |
| prelude functions | **exactly 4** (`f1`–`f3` + reader) | arities 0/1/2 only; 7 parameters never generated |
| flag declarations | **exactly 4** | 0 flags and 9 flags both unreachable |
| flag types | text, number, boolean, text — fixed roles | two number flags never generated |
| flag aliases | `-a`/`--alphaN` etc, fixed | long-only or short-only never generated |
| `Parse flags.` | **always present, always explicit** | the documented auto-insert path has never run |
| `and is required` | **never emitted** | untested entirely |
| section count | **exactly 6 blocks** | order varies; membership never does |

**Root cause, and it is one cause, not nine.** The generator has no
symbol table. Leaves reference things by assumed name — `f1`, `t4's
'made at'`, `fl1label` — so the preludes must emit exactly that cast or
the references dangle. The hardcoded preludes are a substitute for
tracking state. Nothing varies because nothing is *recorded*, so nothing
can be *consulted*.

## Class 2 — structural ceilings. Shape is capped.

| Bound | Range | Line | The claim being made |
|---|---|---|---|
| grid depth | 3..17 | 2825 | 18 nested loop expansions is not interesting |
| expression depth | 2..9 | 392 | a 40-deep expression is not interesting |
| format expression depth | 2..8 | 2478 | same, for format slots |
| statements per program | `--budget`, default 12 | CLI | a 5,000-statement program is not interesting |
| stdin input bytes | 0..1000 | 2124 | a 10 MB stdin is not interesting |
| globals per program | 0..3 | 2728 | 200 globals is not interesting |
| loop iterations | 1..8, 2..6, 5..24, 10..49 | several | a 100,000-iteration loop is not interesting |
| branch count | 1..3 | 818, 833 | a 40-arm `but if` chain is not interesting |
| thing field count | 2..17 | 2400 | a thing with 300 fields is not interesting |

Every row is a guess, and **none was tested before being written**. The
9th-flag question applies to all of them equally: a segfault at 18 grid
levels, or at 4 KB of stdin, or at 200 globals, would be invisible.

## Class 3 — value ranges. Magnitudes are capped.

Less alarming, because bug #34 and #35 came from deliberately including
i64 boundaries, so this class has had *some* thought. But the caps are
still claims.

| Bound | Range | Line |
|---|---|---|
| integer literal digits | 1..18 | 174 |
| float fraction digits | 1..20 | 191 |
| buffer size | 8..67 | 2008 |
| buffer OOB index | 10..509 | 484 |
| number flag value | 0..9999 | 2159 |
| thing field value | 1..65535 | 2427, 2609 |
| exit code | 0..255 minus reserved | 2892 |
| base for conversion | 2..36 | 2056 | (genuinely the language's own limit)

Only the last is a real language bound. The rest are arbitrary.

## What an honest generator would do instead

Not "raise the caps" — that just moves the claim. Two changes:

1. **Draw from a distribution with a long tail, not a uniform range.**
   Mostly small, occasionally enormous. A generator that emits 3 flags
   nine times out of ten and 200 flags once in a hundred costs almost
   nothing and stops asserting that 200 is uninteresting.

2. **Let the compiler define the ceiling, not the generator.** If 512
   flags fails to compile, that is a *finding* — either a real limit
   worth documenting or a bug worth fixing. Right now the generator
   silently enforces limits the language never stated, and so can never
   discover them.

## Known already, from probing during this audit

`a flag called x is "--long-only", it is a number.` **does not parse** —
the parser requires BOTH a short and a long alias (`src/parser/io.rs:37-55`
takes a string, then `Or`, then a string, with no optional path), while
LANGUAGE.md's flag section only ever shows the two-alias form and never
says the pair is mandatory.

So a single-alias flag is either an undocumented restriction or a
missing feature — and it is not a scale question at all. Worth resolving
before the flag generator is rewritten, because it determines whether
"alias shape" is a dimension that can vary.
