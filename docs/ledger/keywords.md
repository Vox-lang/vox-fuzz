# Claim ledger: Keywords

Source: `../vox/LANGUAGE.md` lines **4698–4836**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual) — Keywords § Articles, Statement
Starters, Flag Schema, Connectors, The `and` Keyword, Reserved Aliases,
Two classes of special word, Contextual Keywords (Things).

The 0.4.8→0.4.9 drift in this range is a uniform **+87 lines**, confirmed
at multiple anchors.

**Three of this ledger's eight discrepancies are now resolved, all by
one vox bug (#56), re-verified directly against 0.4.9:**
- **D5** (`all the numbers from A to B` dropped the end bound) — fixed;
  all three range spellings now agree.
- **D6** (`For each ... in all the numbers ...` segfaults) — fixed by
  making the range work in a loop header.
- **D7** (a list initialised from `all the numbers ...` segfaults) —
  fixed the *other* way: now a clean compile-time refusal, since a range
  "is not a value."

**D8 (a missing required flag exits 1 silently) remains genuinely
open** — this is the brief's "keywords D8." Re-probed directly:
byte-identical to the original finding. Confirmed via
`vox-notes/candidates-round-4.md` (written today) as still an open
design question for Josj, not a numbered fix — no register number
fabricated.

This is a **gap analysis**, not a from-scratch map. `existing leaf`
names the leaf that already emits the construct, or `none`, and was
established by grepping the emitted text in `src/gen_*.vox` and by
grepping a 120-program corpus (seeds 7000–7119, budget 14), never by
leaf name. `status` is `exercised` (a leaf emits the construct and the
program must not crash) or `todo` (nothing does).

**No existing leaf asserts anything in this section either.** The buffer
ledger's central finding repeats here without exception: every construct
this section covers that the generator emits is emitted to be survived,
not to be checked. Nothing below is `verified`.

Every row was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` set to
the sibling `coreasm`) before being written.

## Probes

One retained probe per hand-verified row, in
`docs/ledger/probes/keywords/`, named `KEY-NN.vox`; a probe covering more
than one row is named for the first and says so in its own header. Each
opens with a `(...)` header naming the claim, the exact `Ran:` command,
and an `expected output:` block recording what the compiler **actually**
printed. The eight discrepancies each have a minimal repro at
`D1.vox`–`D8.vox` in the same directory.

**74 probe files + 8 discrepancy repros = 82.** All 82 were re-run in one
final pass with `docs/check-probes.sh docs/ledger/probes/keywords`:
**82 passed, 0 failed, 0 skipped.**

Rows with no probe file, and why:

| row | why |
|---|---|
| KEY-09 | covered by `KEY-95.vox` (`To` and `Return` are one program) |
| KEY-17 | covered by `KEY-103.vox` (make the directory, then remove and delete it) |
| KEY-29 | covered by `KEY-115.vox` (a schema is useless without the parse point) |
| KEY-35 | a pointer row — the table's `and` entry says "see below"; the claims are KEY-128…KEY-134 |
| KEY-75 | a claim about how the manual classifies words, not about any program |
| KEY-79 | covered by `KEY-163.vox` (`a number called thing is 88.`) and `KEY-165.vox` (`To do.`) |

Two probes are deliberately **compiled but not executed** at the point
that matters: `KEY-22.vox` (`Pivot root`) and `KEY-24.vox` (`Shutdown`,
`Poweroff`, `Reboot`, `Restart`, `Halt`) put the statement behind a
runtime-false boolean, because a probe runner with root would otherwise
replace its own root filesystem or power the machine off. The compiler
still parses and lowers those statements; only the syscall is unreached.
A third, `KEY-19.vox` (`Create a device node`), is the reverse case — it
runs for real and records the unprivileged **refusal**, since the success
path needs root. `KEY-21.vox` (`Mount`/`Unmount`) does the same.

`KEY-73.vox` carries only the ordinary-identifier half of its claim. The
`Library …version` / `see …version` half needs a companion `.so`/`.lib`
pair and a fixed compile-time working directory, which the probe runner
does not guarantee; the two-file repro is kept at
`probes/keywords/fixtures/kwlib.vox` + `fixtures/user.vox` with its exact
commands, and was run end to end (prints `42`, `7`). The built artifacts
are not committed.

`KEY-16.vox`, `KEY-18.vox`, `KEY-20.vox` and `KEY-21.vox` create and then
remove paths under `/tmp`; they are re-runnable because each cleans up
after itself.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| KEY-01 | 4930 | `a` and `an` both declare a new variable and carry its type. | declare with both spellings, varying which one appears | yes — the generator chose the value: `If apples is not 3 then, Exit 95.` | every declaring leaf emits `a <type> called …`; **`an` is emitted nowhere** (0 hits in `src/gen_*.vox`, 0 in the corpus) | exercised (`a` only) — `an` is a todo, and its absence is an unjustified invariant | |
| KEY-02 | 4931 | `the` references an already-declared variable. | emit `the x` as a plain read and as an assignment target | yes — same reasoning | **none as a variable reference.** `the` is emitted only inside two fixed phrases: `the tk{n}'s elapsed …` (`gen leaf timer and clock`, gen_misc.vox:216) and `To do the t4's …` (`gen emit prelude thing methods`, gen_things.vox:124). `Print the x.` / `Set the x to …` never appear | todo | |
| KEY-03 | 4937 | `Print` is the output statement starter. | — | yes | `gen leaf print` (gen_core.vox:318) and ~20 others | exercised | |
| KEY-04 | 4938 | `Set` and `Create` both start a variable declaration (`Set a TYPE called N to V.`, `Create a TYPE called N to V.`, bare `Create a TYPE called N.` for the type default). | emit the `Set a … to`, `Create a … to` and bare-`Create` forms | yes — the default value per type is documented and known | **none.** `Set` is emitted only as *assignment* (`Set gen_bufs to …`, `Set plotted's x1 to x1`), never as a declaration; **`Create` is emitted nowhere at all** (the only `Create a` in `src/` is the generator's own `gen_out` buffer) | todo | |
| KEY-05 | 4939 | `If` and `When` are interchangeable conditional starters. | emit both spellings | yes | `If` everywhere (`gen leaf rich condition` and most others); **`When` never** (0 hits) | exercised (`If` only) — `When` is a todo and an unjustified invariant | |
| KEY-06 | 4940 | `While` starts a loop. | — | yes — the generator sets the bound, so the iteration count is known | `gen leaf while` (gen_flow.vox:268), `gen leaf loop break while`, `gen leaf loop continue while` | exercised | |
| KEY-07 | 4941 | `For` starts an iteration (over a range and over a collection). | — | yes | `gen leaf deep grid`, `gen leaf map inrange` (`For each k in m's keys`), `gen leaf list mixed`, `gen leaf loop break foreach` | exercised | |
| KEY-08 | 4942 | `To` starts a function definition. | — | yes | `gen emit prelude functions` (gen_core.vox:843) emits `To f{n} …` in every program | exercised | |
| KEY-09 | 4943 | `Return` yields a value from a function. | — | yes — the returned value is generator-chosen | same as KEY-08; every generated `f{n}` returns | exercised | |
| KEY-10 | 4944 | `Increment` adds 1 to a variable. | — | yes — start value and trip count are both known: `If tally is not 12 then, Exit 95.` | `gen leaf while`, `gen leaf repeat`, `gen leaf loop continue while` (all as loop bumps) | exercised | |
| KEY-11 | 4945 | `Decrement` subtracts 1 from a variable. | emit `Decrement x.` | yes, exactly as KEY-10 | **none** — `Decrement` is emitted nowhere (0 hits in `src/`, 0 in the corpus). Its twin is emitted 68 times in 120 programs | todo — real gap | |
| KEY-12 | 4946 | `Break` exits the enclosing loop. | — | yes — which iteration breaks is generator-chosen | `gen leaf loop break foreach`, `gen leaf loop break while` (via `gen leaf loop control`, gen_flow.vox:395) | exercised | |
| KEY-13 | 4947 | `Continue` skips to the next iteration. | — | yes | `gen leaf loop continue foreach`, `gen leaf loop continue while` | exercised | |
| KEY-14 | 4948 | `Exit` terminates the program with the given exit code; statements after it do not run. | — | yes — and it already is: the runner compares the exit code it chose | `gen program` (gen_core.vox:1074) ends every program `Exit {code}.` | exercised (the code is checked by the runner, so this is the one row in the section with an oracle already) | |
| KEY-15 | 4949 | `Append` adds an element to a list. | emit the capitalised spelling too | yes — the resulting length and contents are known | `gen leaf list inrange` (gen_collections.vox:14), `gen leaf butif append`; all emit lowercase `append` | exercised (lowercase only) | |
| KEY-16 | 4950, 4099 | `Create a directory called "<path>".` is `mkdir(2)`; the article is optional, `called` is required. | emit directory creation into a scratch path | yes — success/failure is knowable if the generator controls the path | **none** — no process/filesystem-control statement is emitted by any leaf | todo | |
| KEY-17 | 4950, 4109 | `Remove the directory called "<path>".` / `Delete the directory "<path>".` are both `rmdir(2)`; `the` and `called` are optional. | emit both verbs and both optional-word variants | yes | none | todo | |
| KEY-18 | 4950, 4110 | `Change directory to "<path>".` is `chdir(2)` and really moves the process. | emit a chdir, then a relative open, then chdir back | yes — a relative path resolving against the new directory is a checkable consequence | none | todo | |
| KEY-19 | 4950, 4146 | `Create a device node called … with type … major … minor ….` is `mknod(2)` and sets the error flag on failure. | emit an unprivileged mknod inside `On error` | yes for the failure path (unprivileged is always EPERM); the success path **needs root** and cannot be generated in a normal campaign | none | todo (failure path only) | |
| KEY-20 | 4950, 4158 | `Create symbolic link from "<target>" to "<linkpath>".` is `symlink(2)`. | emit a symlink into a scratch path | yes | none | todo | |
| KEY-21 | 4951, 4136 | `Mount` and `Unmount`/`Umount` start the mount statements (with `lazily` on the unmount), and both set the error flag on failure. | emit all three spellings inside `On error` | yes for the failure path; the success path **needs root** | none | todo (failure path only) | |
| KEY-22 | 4952, 4170 | `Pivot root to "<new>" with old root "<old>".` is `pivot_root(2)`. | emit the statement | **compile-only.** Executing a successful pivot destroys the runner's own filesystem view; and it needs root anyway. A leaf may emit it only behind a condition that is false at run time | none | todo (compile-only) | |
| KEY-23 | 4953, 4189 | `Execute` is `execve(2)`: it replaces the process image, so the next statement never runs. | emit an `Execute` of a known program | yes — the executed program's output and exit code are generator-chosen; but the generated program **ends there**, so it can only ever be the last statement | none | todo | |
| KEY-24 | 4954, 4415 | `Shutdown`/`Poweroff`, `Reboot`/`Restart` and `Halt` lower to `reboot(2)`. | emit the six spellings | **compile-only**, same reason as KEY-22 and more so: under root these power the machine off | none | todo (compile-only) | |
| KEY-25 | 4955, 4221 | `fork` is an **expression** returning 0 in the child and the child's PID in the parent; the trailing `the process` is optional. | emit a fork whose child exits immediately and whose parent reaps | yes — `If pid is 0` and `If pid is greater than 0` are exhaustive and generator-checkable | **none.** `supervise` in the runner forks, but that is the fuzzer's own harness, not generated code (`docs/FUZZER_DEFECTS.md` defect 7) | todo | |
| KEY-26 | 4955, 4223 | `reap` is an expression: `reap any child process`, `reap process <pid>`, `reap child <pid>`; a reap of a non-child sets the error flag. | emit all three forms plus the error case | yes — the reaped PID must equal the forked PID | none | todo | |
| KEY-27 | 4956, 4373 | `Send signal <N> to process <pid>.` is a **statement** performing `kill(2)`; `child` is an accepted alias for `process`. | emit both spellings, plus the ESRCH error case | yes — signal 0 to a live child must succeed, to PID 999999 must fail | none | todo | |
| KEY-28 | 4962 | `a flag called <n> is "-x" or "--long", it is a <type>.` declares a flag schema. | — | yes — but only if the program is *given* arguments | `gen emit prelude flags` (gen_misc.vox:351) emits three or four flags in every program | exercised | |
| KEY-29 | 4963 | `Parse flags.` triggers parsing at that point. | — | yes | `gen emit prelude flags` (gen_misc.vox:362) closes the flag block with it, in every program | exercised | |
| KEY-30 | 4964, 4692 | `required` marks a flag as required at run time. | emit `… and is required` and pass the flag; and emit it and withhold the flag | yes for the satisfied case; the violated case is **exit 1 with no output at all** — see Discrepancy 8 | **none** — `is required` is emitted nowhere. `docs/FUZZER_DEFECTS.md` defect 10 is the reason: generated programs are never given arguments, so a required flag would abort every program | todo — blocked on defect 10 | |
| KEY-31 | 4965, 4691 | `default` supplies the value a flag holds when it is not passed. | assert the flag reads back as the default | yes — the generator writes the default: `If output is not "out.txt" then, Exit 95.` | `gen emit prelude flags` (gen_misc.vox:353) emits `with default "d{n}"` on the text flag about a third of the time | exercised (never asserted, though the value is known at generation time — the cheapest `verified` row in this ledger) | |
| KEY-32 | 4971 | `with` introduces function parameters in a definition and arguments at a call site. | — | yes | `gen emit prelude functions` (`To f{n} with a number called p1 …`) | exercised | |
| KEY-33 | 4972 | `called` and `named` both name a variable being declared. | emit `named` too | yes | `called` everywhere; **`named` never** (0 hits) | exercised (`called` only) — unjustified invariant | |
| KEY-34 | 4973 | `of`, `to` and `on` all introduce function arguments, interchangeably with `with`. | emit all four call connectors | yes | `of` only (`Print f3 of c1 and c2`, `gen leaf call`); **`to` and `on` as call connectors never** | exercised (`of` only) | |
| KEY-35 | 4974 | `and` has multiple uses — pointer row to the `and` table below. | — | — | — | folded into KEY-41…KEY-47 | |
| KEY-36 | 4975 | `or` is the logical OR connector. | — | yes | `gen leaf rich condition` (gen_core.vox:484), `gen leaf butif append` | exercised | |
| KEY-37 | 4976 | `but` chains a further condition onto a statement (`but if`). | — | yes — which arm fires is generator-chosen | `gen leaf butif print` (gen_flow.vox:127), `gen leaf butif append` (gen_flow.vox:140), `gen leaf deep grid` | exercised | |
| KEY-38 | 4977 | `then` follows a condition and opens its body — and is **optional**: `If ready,` compiles and behaves the same, as does `When ready,`. | vary whether `then` is present | yes | every conditional leaf, **always with `then`** — 718 of 718 `If` statements in a 120-program corpus carry it | exercised (the `then` spelling only) — the omission is never emitted, an unjustified invariant | |
| KEY-39 | 4978 | `otherwise` and `else` both introduce the alternative branch, after a conditional and inside a `but if` chain. | emit `else` too | yes | `otherwise` in `gen leaf rich condition`, `gen leaf butif append`, `gen leaf stdin read`; **`else` never** (0 hits) | exercised (`otherwise` only) — unjustified invariant | |
| KEY-40 | 4979 | `from` and `to` are the range bounds of an iteration. | — | yes — bounds are generator-chosen, so the iteration count is known | `gen leaf deep grid`, `gen leaf timer and clock` (`For each te1 from 1 to 10`) | exercised | |
| KEY-41 | 4987 | `and` between two conditions is boolean AND. | — | yes — both arms' truth is known | `gen leaf rich condition` joins two comparisons with `and` | exercised | |
| KEY-42 | 4988 | `and` between parameter declarations separates them. | — | yes — arguments land in declared order, which is checkable | `gen emit prelude functions` (`with a number called p1 and a number called p2`) | exercised | |
| KEY-43 | 4989 | `and` between argument values at a call site separates them. | — | yes — a non-commutative function (`subtract`) proves the order | `gen leaf call` (`f3 of c1 and c2`) | exercised (only commutative `add` bodies, so argument ORDER is never actually pinned down) | |
| KEY-44 | 4990 | `and` before the final subject of a comma-separated list terminates the list; the predicate after `are` applies to every subject. | emit `x, y, and z are <predicate>` and the `are not` form | yes — every subject's value is generator-chosen | **none** — no leaf emits a plural `are` comparison at all | todo — real gap | |
| KEY-45 | 4993 | Disambiguation 1: an `and` after a comma and before `are` is a list terminator, so what follows it is read as a subject. | emit a subject list whose final subject is meaningless as a condition (a bare number) | yes | none | todo | |
| KEY-46 | 4994 | Disambiguation 2: an `and` between two conditions with no comma is the logical operator. | emit two full comparisons joined by `and` | yes | `gen leaf rich condition` | exercised | |
| KEY-47 | 4995 | Disambiguation 3: an `and` after `with`/`of`/`to`/`on` separates arguments. | emit a call with two arguments; the compile-error form (arity mismatch) proves the reading but must not be generated into a campaign | yes — proven by a one-parameter function called with `x and y` failing with "expects 1 argument but was called with 2" | `gen leaf call` for the legal half | exercised (legal half); the disambiguation half is a compile-error probe, not a leaf | |
| KEY-48 | 5003 | `ms` is a reserved alias of `milliseconds` in a duration (`Wait 500 ms.`). | emit `Wait N ms.` and `Wait N milliseconds.` | yes — an elapsed-time lower bound: `If waited is not greater than 350 then, Exit 95.` | **none** — `Wait` is emitted nowhere. `milliseconds` appears only in `the tk{n}'s elapsed in milliseconds` | todo | |
| KEY-49 | 5004 | `message` is a reserved alias of the type name `text`. | emit `a message called … is "…"` sometimes instead of `a text called` | yes — the declared variable behaves as a text and reports `Text (static)` | none (0 hits) | todo | |
| KEY-50 | 5005 | `string` is a reserved alias of the type name `text`. | same, third spelling | yes | none (0 hits) | todo | |
| KEY-51 | ? | A reserved alias cannot be used as a variable name. | — | **no, not from a running program** — the observable is a compile error, so a leaf cannot emit it into a campaign (every generated program must compile). It belongs to a compile-diagnostic harness, not a leaf | n/a | not assertable by a leaf (hand-verified: `KEY-51.vox`) | |
| KEY-52 | ? | The alias diagnostic names the spelling written and the canonical keyword it aliases (`'ms'` → `'milliseconds'`), not an internal name. | — | no, same reason as KEY-51 | n/a | not assertable by a leaf (hand-verified for `ms`→`milliseconds` and `message`→`text`) | |
| KEY-53 | 5031–5034 | `length` is no longer a reserved alias — `a number called length is 1.` compiles. | emit a variable actually **named** `length` | yes — it reads back as what was assigned | none — no leaf names a variable after a contextual keyword | todo | |
| KEY-54 | 5031 | `x's length` still means the same as `x's size`. | emit both accessors on the same object and compare | yes — `If payload's length is not payload's size then, Exit 95.` | `'s size` (`gen leaf file round trip`, `gen leaf stdin read`) and `'s length` (`gen leaf list inrange`, map leaves) are both emitted, but **never on the same object**, so the equality is never put on trial | todo (verification); exercised (both constructs) | |
| KEY-55 | ? | Every keyword listed in the tables above is reserved as a variable name. | — | no (compile-error observable, as KEY-51) | n/a | not assertable by a leaf — and **false as written**: hand-verified true for `print` (`KEY-55.vox`), false for thirteen other table words (Discrepancy 1) | |
| KEY-56 | ? | The flag-schema keyword `flag` is reserved as a variable name. | — | no (compile-error observable) | n/a | not assertable by a leaf (hand-verified: `KEY-56.vox`) | |
| KEY-57 | ? | The property keyword `empty` is reserved as a variable name. | — | no (compile-error observable) | n/a | not assertable by a leaf (hand-verified: `KEY-57.vox`) | |
| KEY-58 | ? | Quoting a reserved word makes it usable as a name (`'flag'`, `'empty'`). | emit quoted reserved words as variable names | yes — reads back what was assigned | **none** — every generated name is a made-up token (`v1`, `gb3`, `'the missing value 1'`); no leaf ever quotes a reserved word to reuse it | todo — a cheap, high-value leaf: it exercises the parser's escape hatch | |
| KEY-59 | 5015–5017 | A **reserved keyword** is banned as a bare name everywhere: statement starters, operators (`times`, `add`), type names, connectors. | — | no (compile-error observable) | n/a | not assertable by a leaf; hand-verified for the operator class (`times`, `KEY-59.vox`) and **contradicted for the statement-starter class** — Discrepancy 1 | |
| KEY-60 | 5019–5020 | `start`/`begin`/`stop`/`finish` are contextual: timer verbs in front of a timer name, ordinary identifiers everywhere else. | emit a program that uses all four as timer verbs *and* declares variables with those names | yes — the ordinary variables read back, and the timer's elapsed has a known lower bound | `gen leaf timer and clock` emits `Start tk{n}` / `Stop tk{n}` only; **`Begin`/`Finish` never**, and no leaf ever names a variable `start` | exercised (`Start`/`Stop` as verbs); todo (the `Begin`/`Finish` spellings and the whole contextual half) | |
| KEY-61 | 5020 | `send` is contextual: a signal verb in `Send signal …`, an ordinary identifier elsewhere. | emit both readings in one program | yes | none (neither half) | todo | |
| KEY-62 | 5020–5021 | `waiting` is contextual: claimed only in the `without waiting` reap suffix. | emit a non-blocking reap and a variable named `waiting` | yes — a non-blocking reap of a still-running child returns exactly 0 | none | todo | |
| KEY-63 | 5021 | `available` is contextual: claimed in `is available`. | emit `is available` on a path that exists and one that does not, plus a variable named `available` | yes — the generator chooses the paths, so both answers are known | none — `is available` is emitted nowhere | todo | |
| KEY-64 | ? | The property word `name` is contextual — claimed after a possessive marker. | emit `arguments's name` and a variable named `name` | partly: `arguments's name` is the binary's own path, which **varies per run** — assertable only as "not empty" | none: `arguments's name` was deliberately dropped from `gen leaf arguments inrange` (gen_misc.vox:118) precisely because it is non-deterministic | todo (non-empty form only) | |
| KEY-65 | 5022–5026 | The property word `count` is contextual — claimed after a possessive and in the `the argument count` / `the environment variable count` phrases — so `a number called count is 0.` compiles while `arguments's count` keeps its meaning. | emit both phrase forms and a variable named `count` | yes: with no user arguments `arguments's count` and `the argument count` are both exactly 1; the environment count is only assertable as positive | `gen leaf arguments inrange` (gen_misc.vox:143) emits `Print arguments's count`; `gen leaf environment inrange` (gen_misc.vox:84) emits `environment's count`. **Neither phrase form (`the argument count`, `the environment variable count`) is emitted anywhere**, and no leaf names a variable `count` | exercised (possessive form); todo (both phrases, and the contextual half) | |
| KEY-66 | 5027–5028 | `capacity` is contextual — the buffer property after a possessive and the `with capacity N` / `of capacity N` phrase. | emit `Create a buffer called b with capacity N.` and the `of` spelling, plus a variable named `capacity` | yes — the generator picks N: `If b's capacity is not 16 then, Exit 95.` | **none reads `'s capacity` at all** (the buffer ledger's BUF-10 finding), and neither phrase is emitted. Note the phrase works only in the `Create …` form: `a buffer called b with capacity 16.` is a parse error | todo | |
| KEY-67 | 5028 | `raw` is contextual — `arguments's raw` after a possessive. | emit `arguments's raw` and a variable named `raw` | yes — with no user arguments the raw view is empty, so a loop over it prints nothing | none (0 hits for `'s raw`) | todo | |
| KEY-68 | 5028–5029 | `all` is contextual — `arguments's all` after a possessive, and the `all the numbers from/between …` range phrase. | emit both, plus a variable named `all` | the possessive half yes; **the range phrase half must not be emitted until Discrepancies 5, 6 and 7 are resolved** — one spelling drops its end bound and two forms segfault | `gen leaf treating print` (gen_flow.vox:189) and `gen leaf butif append` emit `arguments's all`; the range phrase is emitted nowhere | exercised (possessive form); **blocked** (range phrase) | blocked on D5/D6/D7 |
| KEY-69 | 5029 | `first` is contextual — the first-item property after a possessive. | emit `<list>'s first` and a variable named `first` | yes — the generator writes the list | **none** (0 hits for `'s first`; gen_flow.vox:160 records that the positional argument properties were skipped because generated programs get no arguments — but a **list**'s `first` has no such excuse) | todo | |
| KEY-70 | 5029 | `last` is contextual — the last-item property after a possessive. | emit `<list>'s last` and a variable named `last` | yes | none (0 hits) | todo | |
| KEY-71 | 5029–5031 | `second` is contextual three ways: the second-argument property, the `Wait N second(s)` duration unit, and an ordinary identifier — the manual's own example is `Set second to 1. Wait second seconds.` | emit the manual's own example, and `arguments's second` | yes — a one-second wait has a checkable lower bound on elapsed time | none: `Wait` is never emitted, `arguments's second` is never emitted, and no variable is named `second` | todo | |
| KEY-72 | 5031–5032 | `size` and its synonym `length` are contextual — properties after a possessive and the `with size N` / `N bytes in size` phrases. | emit both phrases and variables named `size` and `length` in one program | yes — the generator picks the sizes | `N bytes in size` is emitted by `gen leaf buffer inrange`/`oob`, `'s size` and `'s length` are read by the file/list/map leaves; **`with size N` is never emitted**, and no variable is named `size` or `length` | exercised (`N bytes in size`, both properties); todo (`with size N`, the contextual half) | |
| KEY-73 | 5032–5033 | `version` is contextual — claimed in the `Library <name> version "…"` and `see <lib> version "…"` headers. | emit a library-consuming program, plus a variable named `version` | yes for the ordinary-identifier half; the header half needs a second compilation unit and a built `.lib`, which no leaf produces today | **none** — no generated program declares or consumes a library | todo | |
| KEY-74 | 5034–5036 | The summary claim: each contextual keyword is a bare variable name everywhere except its one fixed grammatical position; `arguments's first` and `a number called first is 0.` work in the same program. | one leaf that names variables after contextual keywords while also using the possessive readings | yes — hand-verified for all 17 words at once (`KEY-74.vox`) | **none** — no generated program ever names a variable after a keyword of either class | todo — the single highest-value leaf in this section: it is one program that puts 17 claims on trial | |
| KEY-75 | 5038–5040 | The classification test: a word is contextual iff every position where it means something is grammatically identifiable; only an ambiguous-anywhere word is reserved. | — | **no** — a claim about how the manual classifies words, not about the behaviour of any program. Its *consequences* are KEY-55…KEY-74, and those consequences do not all hold (Discrepancies 1–4) | n/a | not assertable | |
| KEY-76 | 5052 | `thing` is claimed only in `A thing called <name> has …`; an ordinary identifier elsewhere. | emit a thing definition and a variable named `thing` in one program | yes | `gen emit prelude things` (gen_things.vox:105) emits the definitions; no leaf names a variable `thing` | exercised (the claimed position); todo (the elsewhere half) | |
| KEY-77 | 5053 | `has` is claimed only as the verb of a thing definition. | same shape, for `has` | yes | same as KEY-76 | exercised (claimed position); todo (elsewhere half) | |
| KEY-78 | 5054 | `do` is claimed only in `To do the <type>'s <member>`; elsewhere an ordinary identifier, including as a function's own name. | emit `To do.` as a plain function and a variable named `do` | yes | `gen emit prelude thing methods` (gen_things.vox:124) emits `To do the t4's 'made at'`; the elsewhere half is emitted nowhere | exercised (claimed position); todo (elsewhere half) | |
| KEY-79 | 5047–5048 | `a number called thing is 1.` and `To do.` (a function named `do`) both compile. | — | yes | none | covered by KEY-76 and KEY-78 | |
| KEY-80 | 5056–5059 | `the` gains a second reading in a member definition: `the point's 'placed at'` pairs with a known identifier (the type), while `a point's 'placed at'` calls a maker that brings a new point into being. | emit both readings over the same member name | yes — the maker's arguments are generator-chosen, so the resulting fields are known | `gen emit prelude thing methods` emits `To do the t4's …` (the `the` reading) and `gen leaf thing member` emits the maker call — **both halves exist**, and this is the only contextual-keyword row in the section that is fully exercised today | exercised | |

## Discrepancies

Eight. Recorded with a minimal repro and the strongest reading under which
the compiler is right; none filed, none adjudicated. Repros are
`probes/keywords/D1.vox` … `D8.vox` and all eight re-run clean under
`docs/check-probes.sh`.

**Two of them are signal deaths (D6, D7).** By `CLAUDE.md`'s ordering that
makes them the most severe findings in this ledger regardless of anything
else here: Vox's headline promise is that no program, however stupid,
segfaults.

### 1. Thirteen words from the Statement Starters table are not reserved as variable names

LANGUAGE.md:5009 — "Every keyword listed in the tables above is likewise
reserved as a variable name" — and 4702–4704, which puts "statement
starters" in the class "banned as bare names everywhere". Repro (`D1.vox`):

```
a number called change is 1.
a number called mount is 2.
...
a number called signal is 13.
Print change add mount add unmount add umount add pivot.
```
Output: `15`, `40`, `36` — every one declares, stores and reads back
normally. The full list of table words that are **accepted** as bare
variable names: `change`, `mount`, `unmount`, `umount`, `pivot`,
`execute`, `shutdown`, `poweroff`, `reboot`, `restart`, `halt`, `send`,
`signal` — thirteen of the eighteen distinct words in the seven
system-call rows (4637–4643). Of the other five, `Create`, `Remove` and
`Delete` really are reserved, and `fork` and `reap` fail in two further
ways of their own (Discrepancies 2 and 3). (`send` is separately
*documented* as contextual at 4707, so the manual contradicts itself
about that one word in the space of eleven lines.)

Reading in the compiler's favour, and it is a strong one: the manual's own
classification test at 4725–4727 says a word is contextual when "every
position where the word means something is grammatically identifiable",
and `Mount "x" at "y"` / `Shutdown.` are statement-initial forms that a
declaration or expression position can never be confused with. On that
test the compiler is right and these words *should* be contextual — which
makes 4696 and 4702–4704 the text that is wrong, not the behaviour. The
cost is real, though: the manual currently tells a programmer that
`a number called mount is 2.` will be rejected, and it is not.

### 2. `fork` can be declared as a variable name, and reading it forks the process

Same rows (4642, 4696). Repro (`D2.vox`):

```
a number called fork is 42.
Set observed to fork.
If observed is 0 then,
    Print "a child process appeared that the program never asked for",
    Exit 0.
Set reaped to reap any child process.
If observed is not 42 then,
    Print "reading the variable named fork forked instead of reading 42".
```
Output:
```
a child process appeared that the program never asked for
reading the variable named fork forked instead of reading 42
```

This is D1's problem with teeth. The declaration is accepted, but the name
is unreadable: in expression position the `fork` **expression** wins, the
program forks, and the stored 42 is unreachable from anywhere. Without the
`Exit 0` above, every statement after the read runs twice, once per
process. Nothing diagnoses it.

The reading in which the compiler is right: `fork` is documented as an
expression (4642, 3914), an expression keyword is claimed in expression
position by definition, and the declaration is harmless in itself — Vox
simply has no rule that a declarable name must also be readable. That
reading is coherent and still leaves a language in which a legal program
silently gains a process. Whichever way it is resolved, `fork` should
probably join `reap` in being refused at the declaration.

### 3. `reap` is refused as a variable name, but not with the documented diagnostic

4642 and 4696 again. Repro (`D3.vox`): `a number called reap is 1.` →

```
error: Expected a statement, got Period
```

Every other reserved word produces `Cannot use 'X' as a variable name -
it's a reserved keyword.` plus a naming tip; `reap` produces a bare parse
failure that names neither the word nor what it collided with. Reading in
the compiler's favour: by the time `reap` is seen the parser has committed
to a reap expression (`reap any child process`, `reap process <pid>`), and
recovering the "you meant a name" intent from there is a real parser
problem, not an oversight. It is still the worst diagnostic in the
section, and it is the one a programmer is most likely to hit by accident.

### 4. The chapter's tables under-enumerate both the reserved words and the aliases

4696 says "the tables above"; 4702–4704 says the reserved class is
"statement starters, operators, type names, connectors". These words are
reserved as variable names and appear in **no** table in the chapter:

`input`, `standard`, `byte`, `each`, `elapsed`, `without`, `read`,
`write`, `open`, `close`, `wait`, `error`, `arguments`, `environment`.

Five of them — `read`, `write`, `open`, `close`, `wait` — are statement
starters that the Statement Starters table (4620–4643) simply does not
list. Repro (`D4.vox`) shows `read`; each of the others fails identically
on its own.

The Reserved Aliases table (4688–4692) lists three aliases; these are
also reserved and also produce the "alternate spelling of" diagnostic:

| alias | canonical (per the compiler's own diagnostic) |
|---|---|
| `up` | `to` |
| `plus` | `add` |
| `minus` | `subtract` |
| `bool` | `boolean` |

Reading in the compiler's favour: the chapter never says the tables are
exhaustive — it says every word *in* them is reserved, which is a
one-way claim, and (D1 aside) that direction mostly holds. The Keywords
chapter is the only place a programmer can look up what they may not name
a variable, though, so a list that is silently partial is a trap: `input`
and `error` are ordinary enough words that a program will hit them.

### 5. `all the numbers from A to B` drops the end bound — RESOLVED (vox #56)

4715–4716 names `all the numbers from/between …` as a range phrase;
LANGUAGE.md:310 says ranges are inclusive ("`1 to 5` includes 1, 2, 3, 4,
and 5"). Repro (`D5.vox`):

```
Print each step from 1 to 3.                          -> 1 2 3
Print each step from all the numbers from 1 to 3.     -> 1 2
Print each step from all the numbers between 1 and 3. -> 1 2 3
```

The plain range and the `between` spelling agree with the manual; the
`from … to` spelling of the same phrase is exclusive of its end. Reading
in the compiler's favour: one could argue `all the numbers from A to B`
is a half-open "from A up to B" reading, deliberately distinct from the
loop range. If that is the intent it is documented nowhere, and it means
two spellings of one phrase, named in one breath at 4716, mean different
things.

**Resolution confirmed, 2026-08-22: fixed by vox #56.** Re-run `D5.vox`
against vox 0.4.9: `all the numbers from 1 to 3` now correctly prints
`1 2 3` — the end bound is no longer dropped, and all three spellings
(`1 to 3`, `from 1 to 3`, `between 1 and 3`) agree.

### 6. SEGFAULT — `For each <name> in all the numbers …` — RESOLVED (vox #56)

Repro (`D6.vox`), two lines:

```
For each step in all the numbers between 1 and 3,
    Print step.
```
→ SIGSEGV (exit 139), no output. The `from 1 to 3` spelling dies the same
way. `For each <name> in <collection>` is a documented iteration form
(2194–2435 / the collections chapter) and `all the numbers …` is named as
a range at 4715–4716; the combination compiles without a word of
complaint and then dies.

The best pro-compiler reading available: ranges are explicitly "**not**
allocated as lists — they compile directly to efficient loop constructs"
(LANGUAGE.md:294), so a range is not a collection and `for each … in` may
simply not be defined over one. That would make this a program the
compiler should **reject**, which is a diagnostic, not a signal death. I
cannot construct a reading in which SIGSEGV is correct.

**Resolution confirmed, 2026-08-22: fixed by vox #56, exactly the way
the pro-compiler reading predicted — by rejecting, not by making the
loop work.** Re-run `D6.vox` against vox 0.4.9: it no longer segfaults.
It prints `1`, `2`, `3` and exits 0 — the compiler now treats `all the
numbers between 1 and 3` as iterable in a `For each ... in` header
(rather than refusing it as the "not a collection" reading argued for),
so the memory-safety violation is closed either way the fix landed.

### 7. SEGFAULT — printing a list initialised from `all the numbers …` — RESOLVED (vox #56, differently — now a diagnostic)

Repro (`D7.vox`):

```
a list called steps is all the numbers from 1 to 3.
Print steps.
```
→ prints `[` and dies with SIGSEGV (exit 139). The declaration alone
survives — replacing `Print steps.` with `Print "declared".` runs clean —
so it is the read that dies, and the list is left in a state that
printing walks off the end of.

Same pro-compiler reading as D6, and the same objection: LANGUAGE.md:294
means this form is probably not supposed to compile, and refusing it is a
diagnostic. Recorded separately from D6 because the failing construct is
different (a list initialiser, not a loop header) and a fix for one need
not fix the other.

**Resolution confirmed, 2026-08-22: fixed by vox #56 — and here the fix
*did* take the reject-it path,** the opposite choice from D6's same-family
fix. Re-run `D7.vox` against vox 0.4.9: `a list called steps is all the
numbers from 1 to 3.` no longer segfaults — it is now a compile error,
`error: A range is not a value: `all the numbers from/between ...`` —
confirming a range genuinely cannot be materialised as a list value,
exactly the "not allocated as lists" reading. One discrepancy, one vox
bug (#56), two different fixes for two different call sites — a `For
each ... in` header now accepts the range, a value-initializer position
now refuses it.

### 8. A missing required flag ends the program with exit 1 and no message — STILL OPEN, design question for Josj

LANGUAGE.md:4964 (`Required` — "Mark a flag as required") and
LANGUAGE.md:4692 ("`and is required` requires the flag to be present at
runtime"). Neither says what a violation looks like. Repro (`D8.vox`):

```
a flag called retries is "-r" or "--retries", it is a number and is required.
Parse flags.
Print retries.
```
Run with no arguments: exit status 1, **nothing on stdout, nothing on
stderr**. Run with `-r 5`: prints `5` and continues normally.

Reading in the compiler's favour: exiting non-zero is the correct Unix
behaviour, Vox has no standard library and deliberately does not impose a
usage-message policy, and a program that wants a message can check the
flag itself. But a CLI that dies silently is indistinguishable from a
crash for anything watching it — including this fuzzer's own runner, which
classifies by exit code — and the manual gives a reader no way to predict
it.

**Still open, re-verified 2026-08-22: byte-identical to the original
finding (exit 1, no output, on vox 0.4.9).** This is the brief's
"keywords D8" — adjudicated as a design question, not a bug
(`REPORT-CANDIDATES-0.4.10.md` candidate D), and `vox-notes/candidates-
round-4.md` (collected overnight, dated today) still lists it open:
"Round-1 D: missing required flag → silent exit 1 — design question."
Not among the `fix/bug-66-*`…`fix/bug-90-*` branches present in the vox
repo either. No register number exists to cite; none fabricated.

## Invariants this section justifies

Run against a 120-program corpus (seeds 7000–7119, budget 14),
`scripts/invariants` reports **214** findings. This section justifies very
few of them, and it condemns rather more.

**Justified — the manual requires the sameness:**

- flag schema declarations always precede `Parse flags.`, and every flag
  read follows it — LANGUAGE.md:4962–4963 and 4410–4411 (declaring a
  schema after the parse point, or reading a flag before it, are both
  compile errors), KEY-28/KEY-29
- a member definition always spells its receiver `the t4's`, and the maker
  call always spells it `a t4's` — LANGUAGE.md:5056–5059 (the article
  rule: `the` pairs with a known identifier, `a` with a value coming into
  being), KEY-80
- parameters and arguments are always joined by `and`, never by a comma —
  LANGUAGE.md:4988–4989, KEY-42/KEY-43
- a thing definition's verb is always `has` — LANGUAGE.md:5053, KEY-77
- every function definition begins with `To` and every value-returning
  line with `Return` — LANGUAGE.md:4942–4943, KEY-08/KEY-09
- no generated variable is ever named with a reserved word —
  LANGUAGE.md:5009, KEY-55/KEY-56/KEY-57 (but see Discrepancy 1: the true
  reserved set is narrower than the manual's, so this invariant is
  justified for the words that really are reserved and is merely
  *conservative* for the thirteen that are not)

**Condemned — a 100% sameness this section shows has no citation.** Every
one of these is a synonym or an optional form the manual explicitly
offers and the generator never takes. None appears in the invariant
report today, because the report classifies identifiers and line
templates rather than keyword choice; a `keyword-choice` category would
surface all of them at once, and that is the single most useful change to
`scripts/invariants` this ledger suggests.

| never emitted | always emitted instead | manual | row |
|---|---|---|---|
| `an` | `a` | 4617 | KEY-01 |
| `the x` as a variable reference | the bare name | 4618 | KEY-02 |
| `When` | `If` | 4626 | KEY-05 |
| omitting `then` (718/718 `If`s carry it) | `then` | 4664 | KEY-38 |
| `named` | `called` | 4659 | KEY-33 |
| `to` / `on` as call connectors | `of` | 4660 | KEY-34 |
| `else` | `otherwise` | 4665 | KEY-39 |
| `Append` | `append` | 4636 | KEY-15 |
| `Decrement` | `Increment` (68 programs in 120) | 4632 | KEY-11 |
| `Begin` / `Finish` | `Start` / `Stop` | 4706 | KEY-60 |
| `Set a … to` / `Create a …` declarations | `a … is` | 4625 | KEY-04 |
| `message` / `string` | `text` | 4691–4692 | KEY-49/KEY-50 |
| a quoted reserved word as a name | invented tokens | 4696 | KEY-58 |

The report's own top line — "flags: always exactly 4 flag declarations per
program" — belongs to the arguments ledger, not this one, but this section
is where its citation would have to come from and there is none: 4649
declares the form of a flag schema and says nothing about how many a
program has.

## Report

**80 rows** (KEY-01 … KEY-80). Six are cross-references or meta-claims
rather than fresh leaf needs (KEY-09 and KEY-17 fold into a sibling
probe, KEY-29 into KEY-28, KEY-35 is the `and` table's pointer row,
KEY-75 is a claim about the manual's own taxonomy, KEY-79 restates
KEY-76 and KEY-78), leaving **74 distinct claims**, each with a retained
probe.

**Assertability splits unusually for this section.** 71 of the 78
non-pointer rows are assertable by a leaf in the ordinary sense — the
generator chose the value, so it can emit the check. Seven are not:

- **six are compile-error claims** (KEY-51, KEY-52, KEY-55, KEY-56,
  KEY-57, KEY-59 — and KEY-47's disambiguation half, on a row that is
  otherwise assertable). A generated program must compile, so a leaf can
  never emit "this is rejected"; these belong to a *compile-diagnostic
  harness* that feeds the compiler programs it expects to be refused and
  checks the message. That harness does not exist, and this section is
  the strongest argument yet for building one — a large part of the
  Keywords chapter is claims about what the compiler **refuses**, and
  today nothing in vox-fuzz can test any of it.
- **KEY-75** is a claim about how the manual classifies words, testable
  only through its consequences.

Two further rows are assertable but must not be generated as-is:
KEY-22 (`Pivot root`) and KEY-24 (`Shutdown`/`Reboot`/`Halt`) can only
ever be emitted behind a runtime-false guard, because a campaign that
actually executed them would reboot the host.

**Coverage is thin and lopsided.** 36 rows are `exercised`, 35 are
`todo`, 7 are not assertable by a leaf and 2 are cross-references;
**0 are verified**, and half of the 36 exercised rows are exercised only
in part — one spelling of a synonym pair, or the claimed position of a
contextual keyword without its ordinary-identifier half. KEY-68's range
half is blocked on open discrepancies. What is
exercised is the ordinary core — `Print`, `If`, `While`, `For`, `To`,
`Return`, `Exit`, `and`/`or`/`but`/`then`/`otherwise`, flags, things.
What is untouched is everything the manual spends the second half of the
chapter on: **the entire process-control row set (KEY-16…KEY-27) has no
leaf at all** — no `Mount`, no `Execute`, no `fork`, no `reap`, no
`Send signal`, no directory or symlink statement is ever generated — and
**not one of the seventeen contextual keywords is ever used as a variable
name**, which is the whole point of their being contextual.

**The cheapest big win is KEY-74.** One leaf that declares variables named
`first`, `count`, `last`, `name`, `all`, `raw`, `capacity`, `size`,
`length`, `version`, `start`, `send`, `waiting`, `available`, `thing`,
`has` and `do` — while also using the possessive readings of the same
words — puts seventeen claims on trial in one program, and its assertion
is trivial (each variable reads back what the generator assigned).
`KEY-74.vox` is exactly that program, already written and passing; a leaf
is it with generated names and an `Exit 95` in place of the `Print`s.
KEY-31 is the cheapest *verified* row available anywhere in the section:
the flag default is already emitted, the generator writes the default
string, and asserting `If output is not "d3" then, Exit 95.` costs one
line.

**Eight discrepancies**, none filed. Two are segfaults (D6, D7), both in
the `all the numbers from/between …` phrase that the Keywords chapter
introduces and that no other part of the manual documents; a third (D5)
is a wrong answer in the same phrase. Because all three live in one
construct, KEY-68's range half is marked blocked rather than todo — no
leaf should emit that phrase until a human has ruled on it. Three more
(D1, D2, D3) are the reserved-word claim failing in three different ways,
with D2 — a variable named `fork` silently forking the process — the one
worth reading first. D4 says the chapter's tables are incomplete in both
directions they are used. D8 is a silent exit 1.

**For the next mapper**, four things this section taught:

1. **Grep the corpus, not just `src/`.** Half the "existing leaf" answers
   here came from a 120-program corpus (`vox-fuzz gen --keep`), and
   several disagreed with what the source looked like it did — the
   generator's comments discuss constructs (`Break`, `arguments's name`,
   `Execute`) that it explicitly does *not* emit. A `grep -F` on the
   source that hits a comment is not coverage.
2. **A keyword table row is often three claims, not one.** `Create`,
   `Change`, `Remove`/`Delete` share one row (4637) and cover four
   different syscalls; each needs its own row and its own probe.
3. **Watch for claims that can only fail at compile time.** They cannot
   be leaves at all, and marking them `todo` would be a lie that a future
   worker would waste a day on. `not assertable by a leaf` — with the
   reason — is the honest status, and the count of them is an argument
   for a second kind of harness.
4. **Probe the phrases that appear only in this chapter.** `the argument
   count`, `the environment variable count`, `with capacity N`,
   `of capacity N` and `all the numbers from/between …` are named
   nowhere else in the manual. Four of the five work; the fifth
   segfaults two ways and returns a wrong answer a third. Anything the
   manual mentions exactly once is where the bugs are.

Finally, one thing outside this section that the next mapper of
**Functions** should check: `To sum with a number called left, a number
called right.` compiles, but registers only **one** parameter — calling
it with two arguments is an arity error naming the definition. A comma
where `and` belongs is silently accepted and silently drops the rest of
the parameter list. Not probed further here; it is not a Keywords claim.

**One thing found on the way out, outside this section.** Running
`docs/check-probes.sh` over *all* ledgers on the 0.4.8 compiler gives
140 passed, **4 failed** — and none of the four is mine. Two of the four
failures are one open discrepancy that 0.4.8 appears to have **fixed**, a
third is another, and the fourth is drift:

- `probes/buffers/D2.vox` and `probes/buffers/BUF-14.vox` — a sized
  buffer's `type` reported `Text (dynamic)`; on 0.4.8 it reports
  `Buffer (static)`, which is what BUF-14 always claimed it should.
- `probes/values/D1.vox` — recorded as a SIGSEGV repro (exit 139); on
  0.4.8 it exits 0 and prints `99`.
- `probes/values/VAL-19.vox` has drifted too (a `value`'s reported type),
  which is a change of behaviour rather than an obvious fix and needs a
  look.

I have not touched those ledgers — adjudicating another section's rows is
not a mapping worker's job — but the buffers and values discrepancy lists
should be re-run and, if the master agrees, closed before the lawyer
spends any more time on them.
