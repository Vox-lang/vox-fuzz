# Claim ledger: Command-Line Arguments

Source: `../vox/LANGUAGE.md` lines **4388–4557**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual) — the whole Command-Line Arguments
chapter: Arguments Properties, Basic Usage, Accessing User Arguments,
Checking if Arguments Were Provided, Dynamic Index Access, and all
seven numbered parts of Declarative Flag Parsing.

The 0.4.8→0.4.9 drift in this range is a uniform **+87 lines**, confirmed
at multiple anchors before applying it mechanically. All 5 discrepancies
(still unadjudicated — no prior lawyer verdict) re-verified unchanged via
the full `docs/check-probes.sh` sweep of this directory: 41/41 pass, no
manual or compiler drift found.

This is a **gap analysis**, not a from-scratch map. `existing leaf`
names the leaf that already emits the construct, or `none`, and was
found by `grep` on the accessor (`arguments's <property>`,
`argument at`, `a flag called`, `Parse flags`, `is required`) across
`src/gen_*.vox` — never by leaf name.

Every row below was run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` set to
the sibling `coreasm`) before it was written.

**This section is where the fuzzer already asserts.** Unlike buffers,
four rows land as `verified` on day one: `gen emit argv assertions`
(`src/gen_misc.vox:307-323`) exits 91/92/93/94 when a flag did not parse
to the value the generator passed it. That machinery is the model the
rest of the ledger work copies — and it currently covers four claims
out of fifty-four.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/arguments/`, named `ARG-NN.vox` for the first row it
covers, with its header naming the others. Each opens with a `(...)`
comment giving the claim, the exact `Ran:` command, and an
`expected output:` block recording what the compiler and the binary
**actually** printed. The five discrepancies each have a dedicated
minimal repro at `D1.vox`–`D5.vox` in the same directory.

**`docs/check-probes.sh` needed one change to be able to re-run this
section at all**, and it is the only file outside `docs/ledger/` this
task touched. The script ran every probe binary with no arguments, which
for a ledger *about* the argument vector verifies nothing: half these
probes would have re-run against the empty command line and recorded a
different program's behaviour. A probe may now carry an `Args:` line in
its header; its words become the argument vector the binary is run with.
Probes without that line — every buffer and value probe — are run with
none, exactly as before, and the buffer directory re-runs with the same
result it did before the change (34 pass, 2 fail; both failures predate
this work and are noted in the Report). The change is four lines and is
the master's to keep or revert.

Two probes could not print what they were really testing. `ARG-03`
(`arguments's name`) and `ARG-43` (`last` with no user arguments) both
yield the path the binary was invoked by, which differs between a
by-hand run and the harness's temporary directory, so no recorded block
could ever match twice. Both print a **deterministic identity** instead
— `name is argument 0`, `last is name` — and their headers record the
raw value seen by hand (`./p`). `ARG-10` makes the same substitution for
the one line of the manual's example that prints the program name, and
says so.

No row is without a probe. Eighteen rows have no file of their own and
are covered by a sibling's, named in that file's header — including the
two folded cross-references, ARG-29 (in `ARG-25.vox`) and ARG-37 (in
`ARG-35.vox`). That is 36 `ARG-NN.vox` files for 54 rows; with the five
`D<n>.vox` repros, **41 files, all 41 re-run clean** under
`VOX=… VOX_CORE_PATH=… docs/check-probes.sh docs/ledger/probes/arguments`
— 41 passed, 0 failed, 0 skipped.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| ARG-01 | 4716 | Command-line arguments are read through the `'s` property syntax on the special name `arguments`. | emit any `arguments's <property>` read | yes — every property below is predictable, since the generator chooses the argv | `gen leaf arguments inrange` (`gen_misc.vox:142`), `gen leaf format expression` (`gen_text.vox:330`, inside a format slot) | exercised | |
| ARG-02 | 4722 | `arguments's count` is the total number of arguments, including the program name. | read `count` with a known argv | yes — `If arguments's count is not {expected} then, Exit 95.` where expected is the positional count plus 1 (**not** the raw argv length — see ARG-41) | `gen leaf arguments inrange` (`gen_misc.vox:143`) prints it; `gen leaf format expression` interpolates it | exercised (construct only; never compared against the argv the generator passed) | |
| ARG-03 | 4723 | `arguments's name` is the program name, argv[0]. | read `name` | yes, but **not** as a literal — the binary path varies per run (per-pid scratch dir, see `sandbox.vox`). The assertable form is the identity `If arguments's name is not the argument at 0 then, Exit 95.` | none — deliberately dropped from `gen leaf arguments inrange` (`gen_misc.vox:118-130`) because printing the raw path breaks the byte-exact test fixtures | todo | |
| ARG-04 | 4724 | `arguments's first` is the first user argument, argv[1]. | read `first` with a known argv | yes — `If arguments's first is not "{passed}" then, Exit 95.` | none | todo | |
| ARG-05 | 4725 | `arguments's second` is the second user argument, argv[2]. | read `second` with a known argv | yes, same shape as ARG-04 | none | todo | |
| ARG-06 | 4726 | `arguments's last` is the last argument. | read `last` with a known argv | yes when at least one positional is passed. With none it is argv[0] instead (ARG-43), so the assertion must branch on the count the generator chose | none | todo | |
| ARG-07 | 4727 | `arguments's empty` is true exactly when there are no user arguments (argc ≤ 1). | read `empty` with a known argv | yes — the generator knows whether it passed positionals: `If arguments's empty then, Exit 95.` when it did | `gen leaf arguments inrange` (`gen_misc.vox:144`) prints it | exercised | |
| ARG-08 | 4728 | `arguments's all` is the user arguments as a collection, usable for loop expansion. | bind it to a list and iterate it | yes — `If all's length is not {n} then, Exit 95.`, and each element compared to what was passed | `gen leaf treating print` (`gen_flow.vox:189`) uses it as a loop-expansion source | exercised — but **only ever with a `treating` clause**; the plain forms (bind to a list, `For each … from`, bare `Print each item from`) are never emitted. See ARG-40 | |
| ARG-09 | 4729 | `arguments's raw` is the original, unfiltered user arguments as a collection. | bind `raw` to a list, iterate it | yes — raw's length and elements are exactly the argv the generator built, before any filtering | none — `arguments's raw` appears nowhere in `src/` | todo — the one property in the table that no leaf reads at all | |
| ARG-10 | 4733–4741 | The Basic Usage example compiles and behaves as its prose says (composite): count bound to a number, printed with `the argc`; name bound to a text. | reproduce the declare-then-print chain | yes for the count half; the name half only as the ARG-03 identity | none binds `arguments's count` to a variable — every read is inline | todo | |
| ARG-11 | 4745–4752 | The Accessing User Arguments example compiles and behaves (composite): `count is greater than 1` guard, `first` declared inside the comma-continued branch, `Otherwise` arm. | reproduce the guarded-read shape | yes — the generator knows which arm must run | none | todo | |
| ARG-12 | 4757–4760 | `arguments's empty` is usable directly as an `If` condition, with no comparison. | `If arguments's empty then, …` | yes — which arm runs is known | none — `gen leaf arguments inrange` prints the property but never branches on it | todo | |
| ARG-13 | 4764–4769 | `the argument at the <number variable>` reads an argument by a computed index. | emit a byte-for-byte `the argument at the <var>` read | yes — `If the argument at the n is not "{passed}" then, Exit 95.` | none — flagged as unreachable in `gen_misc.vox:132-136` on the ground that the program is run with no arguments. **That is no longer true**: `loop_gen.vox:128` passes `gen_argv` to both runs | todo — and the reason it was skipped has expired | |
| ARG-14 | 4773 | Vox supports declarative CLI flag parsing, schema-first. | emit a flag schema and a parse point | yes, via the individual rows below | `gen emit prelude flags` (`gen_misc.vox:348-366`) | exercised | |
| ARG-15 | 4777, 4780–4782 | A flag schema is a name, two alias strings joined by `or`, and `it is a <type>`. | emit the declaration form; vary name, both aliases, and type | yes — the schema's effect is asserted through ARG-17/18/19 | `gen emit prelude flags` emits four of them | exercised — but the names and alias spellings are **frozen**: `gen_flags` is pinned to 1 (`gen_core.vox:1004`), so every program ever generated declares `fl1label`/`fl1count`/`fl1on`/`fl1scratch` with aliases `-a`/`--alpha1`, `-b`/`--beta1`, `-c`/`--gamma1`, `-s`/`--scratch1` | |
| ARG-16 | 4785–4789 | The supported flag value types are exactly `boolean`, `number` and `text` — the list is exhaustive. | — | **no** — the exhaustiveness half is a compile error, and a generated program must compile. The three positive cases are ARG-17/18/19 | `gen emit prelude flags` emits all three types | not assertable (exhaustiveness); the three types themselves exercised | |
| ARG-17 | 4787 | A `boolean` flag's presence sets it true. | pass the flag, assert true; omit it, assert false | yes — and it already does | `gen emit prelude flags` + `gen build argv` (`gen_misc.vox:273-278`) + `gen emit argv assertions` (`Exit 93`/`Exit 94`) | **verified** | |
| ARG-18 | 4788 | A `text` flag consumes the next token as text. | pass `-a <word>`, assert the flag holds `<word>` | yes — and it already does (`Exit 91`) | `gen emit argv assertions` (`gen_misc.vox:316`) | **verified** | |
| ARG-19 | 4789 | A `number` flag consumes the next token and parses it as a number. | pass `-b <digits>`, assert the flag holds that number | yes — and it already does (`Exit 92`) | `gen emit argv assertions` (`gen_misc.vox:317`) | **verified** | |
| ARG-20 | 4793 | Flags may be marked required **and/or** given defaults — the two modifiers combine. | emit one flag carrying both modifiers | the declaration compiles, but the runtime behaviour is Discrepancy 3: required aborts before the default can be read, so there is nothing to assert but the exit status | none — no leaf emits `is required` at all | todo — blocked on D3 | |
| ARG-21 | 4796, 4800 | `with default <value>` initializes the flag when it is not passed. | declare a default, do not pass the flag, assert the default is what is read | yes — `If fl{n}label is not "d{n}" then, Exit 95.` on the runs where the generator chose not to pass `-a` | `gen emit prelude flags` (`gen_misc.vox:352`) emits `with default "d{n}"` one draw in three | exercised — text only, never asserted; number and boolean defaults compile (probe ARG-21) and are never emitted | |
| ARG-22 | 4797, 4801 | `and is required` requires the flag to be present at runtime. | declare a required flag and omit it | only as an **expected exit status** — the program aborts before its first statement, printing nothing (ARG-51). The runner does not carry an expected exit code today: `loop_gen.vox` treats any clean exit outside 91–94 as a pass, so a silent `exit 1` is invisible | none — deliberately avoided (`gen_misc.vox:339-341`), on the ground that a required flag "would abort every program". The generator now chooses the argv and could simply pass it | todo — needs runner support for an expected exit code | |
| ARG-23 | 4802–4803 | A flag with no `with default` that is not passed holds its type's empty value: `""` for a text, `0` for a number, false for a boolean. | leave each type unsupplied and assert the empty value | yes — `If fl{n}count is not 0 then, Exit 95.` on the runs where `-b` was not passed | `gen build argv` shapes 6–9 (`gen_misc.vox:281-303`) leave flags unsupplied and the program prints them | exercised — `gen_asserts_argv` is false for exactly those shapes, so the empty-value claim is the one thing never checked | |
| ARG-24 | 4804–4805 | An unsupplied `text` flag is safe to read and can be tested with `is empty`. | `If fl{n}label is empty then, …` on a run where `-a` was not passed | yes — the generator knows whether it passed `-a` | **none.** The comment at `gen_misc.vox:395-398` says `is empty` on the text flag is deliberate, but the leaf below it (`gen leaf flag read`) only prints; the `is empty` probe that exists (`gen leaf predicate probe`, `gen_misc.vox:431`) applies it to a plain text `pt{n}`, not to a flag | todo — a comment claims coverage the code does not have | |
| ARG-25 | 4809–4813, 4822 | `Parse flags.` parses explicitly, at exactly that point. | emit `Parse flags.` with ordinary code before it | yes — everything after it reads parsed values | `gen emit prelude flags` (`gen_misc.vox:362`) | exercised — emitted in **every** program, which is itself an unjustified invariant (see below) | |
| ARG-26 | 4815 | With `Parse flags.` omitted, parsing is inserted automatically immediately after the last flag schema declaration. | emit a program with a schema and no parse statement | yes — reads after the last schema must see parsed values. The "immediately after the **last**" half is only observable as a compile error (ARG-31), so a generated program can prove the positive half only | none — `Parse flags.` is always emitted | todo | |
| ARG-27 | 4819 | Flag schema declarations are valid as long as they appear before parsing occurs. | any schema-then-parse program | structurally true of anything that compiles; nothing to assert beyond ARG-25/26 | `gen emit prelude flags` | exercised | |
| ARG-28 | 4821 | Normal code may be placed before and between schema declarations. | emit a statement before the first schema and between two schemas | yes — the interleaved statements' own output is predictable | none — the schema block is contiguous and always the first thing in the program | todo — CLAUDE.md names this exact pattern (`flags always contiguous`) as a defect, and the manual explicitly permits the alternative | |
| ARG-29 | 4822 | An explicit `Parse flags.` chooses exactly when parsing happens. | — | — | — | folded into ARG-25 | |
| ARG-30 | 4823 | Declaring a new flag schema after `Parse flags.` is a compile-time error. | — | **no** — emitting it produces a program that does not compile, outside the generator's "legal Vox that should compile and run" contract | n/a | not assertable | |
| ARG-31 | 4824 | Using a flag variable before the parse point is a compile-time error. | — | **no** — same reason as ARG-30 | n/a | not assertable | |
| ARG-32 | 4830 | After parsing, `arguments's all` is the filtered positional view: recognized flags are removed. | pass flags and positionals, assert `all` holds only the positionals | yes — the generator built the argv, so it knows exactly which tokens survive | `gen leaf treating print` reads `all` after parsing, and `gen build argv` shape 9 puts real positionals in it | exercised — never compared against what was passed | |
| ARG-33 | 4831 | After parsing, `arguments's raw` keeps the original user-provided sequence unchanged. | assert `raw`'s length and elements equal the argv passed | yes — the strongest assertion in the section: raw is the generator's own list, element for element | none | todo | |
| ARG-34 | 4835–4847 | The all-vs-raw worked example compiles and behaves as shown (composite), including a flag read from inside a format slot (`"output:{output}"`). | reproduce the example, including the flag-in-a-slot read | yes | flags are read bare (`gen leaf flag read`) and format slots carry `arguments's count` (`gen_text.vox:330`), but a **flag** inside a format slot is never emitted | todo | |
| ARG-35 | 4851 | `--` stops flag processing. | pass `--` in the argv, assert the flags after it did not parse | yes — the generator controls where `--` goes | none — `gen build argv` never appends `--` | todo | |
| ARG-36 | 4851 | Tokens after `--` are treated as positional arguments. | assert those tokens appear in `all` | yes | none | todo | |
| ARG-37 | 4856–4862 | The example invocation `myprog --verbose -- -v file.txt`: `--verbose` parses as a flag, `-v` after `--` is a positional. | — | — | — | folded into ARG-35/ARG-36 | |
| ARG-38 | 4866–4879 | The Practical Pattern example compiles and behaves (composite), including flag names that are **quoted** because they are reserved words: `'version'`, `'number'`. | emit at least one quoted flag name | yes | none — every generated flag name is an unquoted `fl1…` | todo — the quoted-name path through the parser is never taken | |
| ARG-39 | 4873, 4876 | A boolean flag's own name is usable bare as an `If` condition. | `If fl{n}on then, …` | yes — and it already does | `gen emit argv assertions` (`gen_misc.vox:321`): `If fl{n}on then, Exit 94.` | **verified** (as the false-expectation half of the argv assertion) | |
| ARG-40 | 4879 | `Print each item from arguments's all` prints each positional argument. | emit the bare print-each form | yes — the generator knows the positionals | `gen leaf treating print` emits it **only** with a `treating` clause attached (`gen_flow.vox:199`) | todo for the plain form — a different path through the compiler | |
| ARG-41 | 4722, 4724–4726 (undocumented precision) | *(not a manual claim — a gap in the manual)* After parsing, **every** positional property follows the filtered view, not the raw argv: `count`, `empty`, `first`, `second`, `last` and `the argument at` all count and index the positionals only. 4417 says this of `all` and of nothing else. | read each of them after a parse that filtered something, assert against the filtered list | yes — `If arguments's count is not {positionals + 1} then, Exit 95.` | none — `count` is printed but never compared, so the filtered-vs-raw distinction is invisible today | todo | see Discrepancy 1 |
| ARG-42 | 4724–4725 (undocumented) | *(gap)* Reading `first` or `second` when there is no such argument sets the error flag — `On error` catches it — and yields `""`. | read them with a known-short argv, wrapped in `On error` | yes — the generator knows how many positionals it passed | none | todo | |
| ARG-43 | 4726 (undocumented) | *(gap)* `last` never errors: with no user arguments it returns the program name, where `first` errors instead. | read `last` on a positional-free argv | yes, as the identity `last is name` (the literal path is not assertable, ARG-03) | none | todo | see Discrepancy 2 |
| ARG-44 | 4764–4769 (undocumented) | *(gap)* `the argument at N` indexes **argv**, not the user arguments: index 0 is the program name and does not error, index 1 is the first user argument, a negative index sets the error flag and yields `""`, and a bare literal or a computed expression is accepted where the manual shows only a variable. | emit index 0, a positive index, a negative index, and a literal-index form | yes for every part | none | todo | |
| ARG-45 | 4777, 4780 (undocumented) | *(gap)* A schema must carry **exactly two** alias strings; one is a compile error. The diagnostic demands a *long* alias, but two short aliases (`"-a" or "-b"`) are accepted — the enforced rule and the stated rule differ. | — | **no** — the negative half is a compile error. The positive half (two aliases, any mix of short and long) is what every schema already emits | `gen emit prelude flags` (always two, always short-then-long) | not assertable | see Discrepancy 5 |
| ARG-46 | 4789 (undocumented) | *(gap)* A `number` flag whose value does not parse sets the error flag on the first read and holds 0. | pass a non-numeric value, wrap the read in `On error`, assert 0 and that the handler fired | yes — the generator chose the bad token | `gen build argv` shape 6 (`gen_misc.vox:283-286`) | exercised — `gen_asserts_argv` is false for this shape, so neither the 0 nor the error flag is checked | |
| ARG-47 | 4789 (undocumented) | *(gap)* A `number` flag value beyond i64 sets the error flag **and** leaves the value wrapped modulo 2^64 (`99999999999999999999` → `7766279631452241919`), which then propagates through arithmetic. | pass an over-range value, assert both the error flag and the wrapped value | yes — the wrap is computable at generation time | `gen build argv` shape 7 (`gen_misc.vox:288-292`); its comment says "Raises too" and stops there — the wrapped value is not mentioned or checked | exercised | see Discrepancy 4 |
| ARG-48 | 4789 (undocumented) | *(gap)* A `number` flag given a decimal value truncates toward zero **silently** — `1.5` → `1`, no error flag, nothing for a program to notice. | pass a decimal value, assert the truncated integer and that no error fired | yes | none | todo | |
| ARG-49 | 4788 (undocumented) | *(gap)* A flag whose value token is missing because argv ends keeps its empty value and raises nothing; the flag itself is still consumed and does not fall into the positional view. | end the argv on a value-taking flag, assert the empty value and that `all` is empty | yes | `gen build argv` shape 8 (`gen_misc.vox:293-297`) | exercised — unasserted | |
| ARG-50 | 4830 (undocumented) | *(gap)* An unrecognized flag is not consumed: it stays in both `all` and `raw`, and so does the token after it. 4417 says "recognized flags removed" and leaves the rest undefined. | pass an unknown flag plus a positional, assert both survive into `all` | yes | `gen build argv` shape 9 (`gen_misc.vox:298-303`) | exercised — unasserted | |
| ARG-51 | 4801 (undocumented) | *(gap)* A missing required flag aborts with exit status 1 and **no output at all** — nothing on stdout, nothing on stderr, no mention of which flag was missing. | declare a required flag, omit it, expect exit 1 | only as an expected exit status — see ARG-22 | none | todo | see Discrepancy 3 |
| ARG-52 | 4777 (undocumented) | *(gap)* Two schemas may share a name: they merge into one variable and every alias of both triggers it. "Define each supported flag once" is not enforced — no error, no warning. Duplicate *aliases* across two flags are accepted too. | emit two schemas with one name, assert either alias sets the same variable | yes | none | todo | |
| ARG-53 | 4812 (undocumented) | *(gap)* A second `Parse flags.` is a compile-time error. The manual presents the parse point as explicit-or-automatic and never says the explicit form is once-only. | — | **no** — compile error | n/a | not assertable | |
| ARG-54 | 4812 (undocumented) | *(gap)* `Parse flags.` with no schema at all is legal: nothing is recognized, so nothing is filtered and a leading-dash token is just another positional. | emit a schema-free program with a parse point | yes — `all` equals the whole argv | none — the schema block is never empty | todo | |

## Discrepancies

### 1. After parsing, `arguments's count` is not "the total number of arguments"

LANGUAGE.md:4722 defines `count` as "Total number of arguments
(including program name)". After `Parse flags.` it is the count of the
**filtered** view. Repro (`probes/arguments/D1.vox`), five user
arguments of which three are consumed by the schema:

```
a flag called verbose is "-v" or "--verbose", it is a boolean.
a flag called output is "-o" or "--output", it is a text.
Parse flags.

a list called original is arguments's raw.
Print "arguments actually passed: {original's length}".
Print "arguments's count: {arguments's count}".
```

Run as `./p -o mine.txt pos1 -v pos2`:

```
arguments actually passed: 5
arguments's count: 3
```

`first`, `second`, `last` and `the argument at` follow the same filtered
view (`probes/arguments/ARG-41.vox`): with that argv, `first` is `pos1`,
not `-o`.

The reading in which the compiler is right: 4413–4418 establishes that
after parsing there are two views, and names `all` the "filtered
positional argument view" and `raw` the original. Every scalar property
in the table is a projection of the positional view — `first` is
"First **user** argument", `empty` is "no **user** arguments" — so a
consistent implementation makes them all agree with `all`, which is
exactly what this does. Under that reading the only thing wrong is the
one word "Total" in the `count` row, written before flag parsing
existed and never revisited. The behaviour is coherent and, for a CLI,
almost certainly the useful one; it is the documentation that stops one
sentence short. **Not filed.**

### 2. `last` reaches a place `first` refuses to go

With no user arguments, `arguments's first` sets the error flag and
yields `""`, while `arguments's last` quietly returns the program name.
Repro (`probes/arguments/D2.vox`):

```
Print "empty is {arguments's empty}".
a text called one is arguments's first.
On error print "first errored".
Print "first is [{one}]".
a text called ending is arguments's last.
On error print "last errored".
If ending is arguments's name then,
    Print "last is the program name".
Otherwise,
    Print "last is not the program name".
```

Output:

```
empty is 1
first errored
first is []
last is the program name
```

So a program that asks "what was the last thing on my command line?"
when nothing was passed gets its own path back, with no error flag to
tell it apart from a real argument — and `empty` is true at the same
moment, which is the contradiction a reader would notice first.

The reading in which the compiler is right: the table says "First
**user** argument (argv[1])" for `first` but only "Last argument" for
`last`. Those are different words and this implementation takes them
literally — `last` ranges over all of argv, including argv[0], and with
no user arguments the last of argv *is* the program name. Under that
reading the behaviour is exactly documented and the fault is that one
table row is scoped differently from its neighbours without saying so.
**Not filed.** Either the row should read "Last user argument", in which
case this is a bug, or it should say "Last argument, which is the
program name when no user arguments were given", in which case it is a
doc fix. That choice is not a worker's to make.

### 3. `and is required` makes `with default` unreachable, and aborts in silence

LANGUAGE.md:4793 says flags may be marked required "and/or" given
defaults; 4387 says a default "initializes the flag value if the flag is
not passed". Put both on one flag and the rules collide: the flag is not
passed, so the default should initialize it — but required aborts first.
Repro (`probes/arguments/D3.vox`):

```
a flag called output is "-o" or "--output", it is a text with default "out.txt" and is required.
Parse flags.

Print "output is {output}".
```

Run with no arguments: exit status **1**, and not one byte on stdout or
stderr. No diagnostic, no name of the missing flag, no usage line. A
user sees a program that does nothing and returns failure.

The reading in which the compiler is right: "and/or" grants only that
both modifiers may appear on one declaration, not that both take effect;
`required` is a precondition checked at the parse point, and a
precondition that fails ends the program before any default can matter.
The default is then dead weight on that declaration — legal, useless,
and arguably the programmer's mistake rather than the compiler's. The
silence is harder to defend: nothing in the manual says a required flag
prints anything, so the compiler breaks no stated promise, but exit 1
with no output is indistinguishable from a crash that happens to have a
tidy status. **Not filed.** Two questions for the human: should
`required` plus `default` be a compile-time error, and should the abort
name the flag it is missing.

### 4. An over-range number flag raises *and* hands back a wrapped value

Repro (`probes/arguments/D4.vox`), run as
`./p -r 99999999999999999999`:

```
a flag called retries is "-r" or "--retries", it is a number.
Parse flags.

Print "retries is {retries}".
a number called doubled is retries multiply 2.
Print "and it computes: {doubled}".
```

Output:

```
retries is 7766279631452241919
and it computes: -2914184810805067778
```

`99999999999999999999 - 5 × 2^64 = 7766279631452241919`: the value is
wrapped modulo 2^64, not clamped and not zeroed. The error flag *is*
set — `probes/arguments/ARG-47.vox` catches it with `On error` — but a
program that does not wrap the read in a handler, which is every program
the manual's own examples show, computes with that number and then wraps
again into a negative on the first multiply.

The reading in which the compiler is right: the error flag is set, so
the failure *is* signalled through the channel Vox provides, and a
program that ignores an error flag gets whatever was in the variable —
the same contract as an out-of-bounds buffer read, which returns 0 and
raises. The difference that makes this worth a human's attention is
that 0 is obviously a non-answer while `7766279631452241919` looks like
a real one, so the unchecked path is silently wrong rather than
obviously wrong. Contrast the well-behaved sibling: a non-numeric value
raises and yields 0 (`ARG-46`). **Not filed.**

### 5. The one-alias diagnostic states a rule the compiler does not enforce

`probes/arguments/D5.vox`:

```
a flag called solo is "-s", it is a boolean.
```

```
error: Expected long flag alias string like '--number'
```

But `probes/arguments/ARG-52.vox` compiles and runs
`a flag called twoshort is "-a" or "-b", it is a boolean.` — two short
aliases, no long one — and both spellings set the flag. So the rule the
compiler enforces is "exactly two alias strings"; the rule its
diagnostic states is "one of them must be long". The manual states
neither: 4364 says "including aliases" and every example happens to
show one short and one long.

The reading in which the compiler is right: the parser reaches that
error only after consuming the first alias and finding no `or`, and at
that point the overwhelmingly common intent is a missing long form, so
the message is a *helpful guess about what you meant* rather than a
statement of the grammar. That is defensible for a hint and not for the
error line itself. Nothing is broken here — a program either compiles or
does not — but a fuzzer that trusts diagnostics as specification would
learn a rule that is not real, and so would a reader. **Not filed.**
The underlying two-alias requirement should be in LANGUAGE.md either
way; it is the only hard grammar rule in this section that the manual
does not state.

## Invariants this section justifies

Sameness a corpus report will show that the manual (or the compiler's
enforced grammar) actually requires:

- every flag declaration carries exactly two alias strings — no
  LANGUAGE.md line states it; enforced by the compiler, ARG-45, D5
- every flag's type is one of `boolean`, `number`, `text` —
  LANGUAGE.md:4785–4789, ARG-16
- every flag schema declaration precedes the parse point —
  LANGUAGE.md:4819, ARG-27
- no flag variable is read before the parse point —
  LANGUAGE.md:4824, ARG-31
- at most one `Parse flags.` per program — no LANGUAGE.md line states
  it; enforced by the compiler, ARG-53

Everything else this section's leaves hold constant is **not** justified,
and the list is long. The load-bearing cause is one line:
`gen_core.vox:1004` pins `gen_flags` to 1 for every program ever
generated, so the entire flag surface is a single frozen shape:

- exactly four flag declarations in every program (CLAUDE.md names this
  one by name); no rule says four, or any number
- always the same four flag names — `fl1label`, `fl1count`, `fl1on`,
  `fl1scratch` — and the same aliases, `--alpha1`/`--beta1`/`--gamma1`/
  `--scratch1`
- always short alias first, long alias second (ARG-52 proves the order
  is free, and that neither has to be long)
- the schema block is always contiguous and always the first thing in
  the program — LANGUAGE.md:4821 explicitly permits code before and
  between declarations (ARG-28)
- `Parse flags.` in every program — LANGUAGE.md:4815 makes it optional
  (ARG-26)
- no program ever declares a `required` flag (ARG-22)
- no program ever passes `--` (ARG-35, ARG-36)
- no program ever uses a quoted flag name (ARG-38)
- `arguments's name`, `first`, `second`, `last`, `raw` and
  `the argument at` never appear in any generated program — six of the
  eight documented accessors, plus the whole Dynamic Index Access
  subsection
- `Print each item from arguments's all` only ever appears carrying a
  `treating` clause (ARG-40)

## Report

**54 rows** (ARG-01 through ARG-54). Two (ARG-29, ARG-37) are
cross-references folded into a sibling, leaving **52 distinct claims**:
38 from the manual's own text and 14 recording behaviour the manual does
not cover, in the "undocumented precision" style the buffer ledger
established.

Of the 52, **44 are assertable** — the generator builds the argv, so it
knows every answer. 8 are not: five compile-error claims (ARG-16's
exhaustiveness, ARG-30, ARG-31, ARG-45, ARG-53), which a generated
program cannot contain and still compile, and three that need something
the runner does not have (ARG-20, ARG-22, ARG-51 all reduce to "the
program exits 1 having printed nothing", and `loop_gen.vox` treats every
clean exit outside 91–94 as a pass).

**Status today: 4 verified, 15 exercised, 28 todo, 5 not assertable**, plus
the 2 folded cross-references.

The four verified rows are the whole point of this section. `gen emit
argv assertions` already does exactly what the ledger asks of every
other section: it knows what it passed, it emits `Exit 91/92/93/94`, and
a wrong answer becomes a finding with no reference implementation.
ARG-17, ARG-18, ARG-19 and ARG-39 are those four rows. It is the only
assertion machinery in the generator and it covers four claims out of
fifty-four.

**Biggest finding: the reason six of the eight documented accessors are
unreachable has expired.** `gen_misc.vox:112-140` explains at length
that `first`/`second`/`last`/`the argument at`/`name` are skipped
because "the generated program runs with no user arguments
(runner.vox's 'run program' always passes an empty argument list)". That
was true when it was written and is not true now: `loop_gen.vox:128`
passes `gen_argv` — the argv the generator chose — to both oracle runs,
and `gen build argv` fills it with flags, values and, in shape 9, real
positionals. Every one of those properties is now not merely reachable
but **assertable**, and `raw` is the most assertable construct in the
whole ledger: it is the generator's own list handed back element for
element. The comment is the only thing still holding the surface shut.

Second finding, smaller and sharper: `gen_misc.vox:395-398` claims an
`is empty` probe on the text flag that the code below it does not
contain (ARG-24). The `is empty` that exists is on a plain text. A
comment that describes coverage the leaf does not have is worse than no
comment, because it is what the next mapper greps for.

**Five discrepancies**, all with repros, none filed. D1 (post-parse
`count` is the filtered count) and D2 (`last` returns the program name
where `first` errors) are documentation precision, and both would be one
sentence in LANGUAGE.md. D3 (`required` plus `default`, and the silent
exit 1) and D5 (a diagnostic stating a rule the compiler does not
enforce) want a human decision about what the language should do. D4 (an
over-range number flag raises *and* returns the value wrapped modulo
2^64) is the one worth a compiler person's eye: the error flag is set,
so the contract is arguably kept, but the value left behind looks
exactly like a real answer and keeps wrapping through arithmetic.

**For the next mapper**, four things this section cost time on:

1. **The line ranges in `INDEX.md` are all stale.** It pins 0.4.7 at
   5112 lines; the manual is now 0.4.8 at 5240. This section had moved
   128 lines down. Re-pin the whole table against `grep -n '^## '` before
   mapping anything, and expect every range below Time and Timers to
   have shifted by a similar amount.
2. **`docs/check-probes.sh` runs probes with no arguments and from the
   repo root.** If your section's behaviour depends on how the binary
   was invoked, a recorded output block is worthless without the `Args:`
   line added here. If it depends on the binary's *path* — anything
   touching `arguments's name` — no recorded block can ever match twice;
   assert a deterministic identity instead and record the raw value in
   the header.
3. **Print a boolean and you get `1` or `0`, not `true`/`false`.** Every
   assertion this section proposes had to be written against that.
4. **Read the comments in `src/` as history, not as fact.** Two of the
   largest findings here are comments that were true when written and
   are not now. `grep` the accessor and then check the *runner*, not
   just the leaf.

**Unrelated, found while running the gate:** `docs/ledger/probes/buffers`
now fails two of its 36 probes — `BUF-14.vox` and `D2.vox` both record
`Text (dynamic)` and the compiler at 34f9831 prints `Buffer (static)`.
That is buffer Discrepancy 2 (a sized buffer's `type` property) having
been **fixed** in the compiler since the buffer ledger was mapped. Those
two probes and the BUF-14 row need re-recording, and buffers' D2 needs a
`Resolution:` line. Not touched — it is not this section.
