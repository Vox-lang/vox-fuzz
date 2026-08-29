# Claim ledger: Time and Timers

Source: `../vox/LANGUAGE.md` lines **4215–4387**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual) — `## Time and Timers`, through
Getting Current Time, Time Properties, Inline Time Access, Sleep / Wait,
Timers, Timer Properties, Getting Duration, the Complete Timer Example,
and Formatted Time Output.

The 0.4.8→0.4.9 drift in this range is a uniform **+87 lines**, confirmed
at multiple anchors. Compiler: the repo build at
`/home/josj/scr/english/vox/target/release/vox` with `VOX_CORE_PATH`
pinned to the sibling `coreasm`.

All 5 discrepancies (still unadjudicated — no prior lawyer verdict)
re-verified unchanged against vox 0.4.9. **Also fixed two `check-
probes.sh` false-failure classes**, neither specific to this ledger:
clock-dependent probes (`Print current time's hour`-style output that
can never match a fixed recorded value) now recognise the phrase
"clock-dependent output" as an exit-only signal, the same way
"Segmentation" already was; and `D3.vox`'s prose annotation was moved
out of the checked block into the header comment, since it was neither
the bare-`exit N` nor the `(exit N)` convention the checker already
handled. `docs/check-probes.sh docs/ledger/probes/time`: 45/45 pass (was
38/45 before these fixes).

This is a **gap analysis**, not a from-scratch map. The `existing leaf`
column names the leaf that already emits the construct, or `none`. Two
leaves reach this section and no others do:

- `gen leaf timer and clock` (`src/gen_misc.vox:203`) — emits
  `a timer called tk{n}`, `Start tk{n}`, `Stop tk{n}`,
  `the tk{n}'s elapsed in milliseconds`, `Get current time into tn{n}`,
  `the tn{n}'s unix`, `the tn{n}'s year`.
- `gen leaf format types` (`src/gen_text.vox:445`) — emits
  `Get current time into hq{n}` and reads `hour` out of a zero-padded
  format slot.

`src/harness.vox:49–66` uses a timer and `Wait 5 milliseconds`, but that
is the **fuzzer's own harness**, not anything a generated program
contains; it is not coverage and is never counted below.

Neither leaf asserts in the ledger's sense. Both print a **verdict**
(`"tl{n} ok"` / `"tl{n} NEGATIVE"`, `"ht{n} ok"` / `"ht{n} BAD"`) rather
than exiting 95, so a wrong answer becomes a line of output nobody is
diffing against a documented expectation rather than a `wrong-value`
finding. Nothing in this section is therefore `verified`. That is the
same uniform gap the buffer ledger found, and it is not a per-row
surprise.

Every row below was hand-run against the real compiler before it was
written.

## Probes

**45 files** in `docs/ledger/probes/time/`: 40 row probes (`TIM-NN.vox`,
one per hand-verified row, several covering neighbouring rows too) and 5
discrepancy repros (`D1`–`D5`).
A probe that covers more than one row is named for the first and says so
in its own header. `docs/check-probes.sh docs/ledger/probes/time` runs
the directory: **45 passed, 0 failed, 0 skipped.**

Two things about probing a clock deserve stating, because they shape
every file here:

- **Nothing prints a clock value.** A probe whose output moves between
  runs cannot be re-checked, so each one *checks* the clock-dependent
  value and prints a fixed verdict — the rule `gen leaf timer and clock`
  already set for itself (`src/gen_misc.vox:191`). Ranges are chosen so
  the verdict survives a slow machine: a one-second wait is checked as
  "at least 999 ms", never "exactly 1000".
- **The manual's five worked examples are recorded as exit-code probes.**
  They print raw clock values, so their output cannot be pinned. Each is
  kept verbatim, its exit status is the recorded outcome, and one real
  run is kept underneath as documentation. Those are TIM-12, TIM-14,
  TIM-20, TIM-40, TIM-42, TIM-43.

Rows with no probe file of their own: TIM-02, TIM-03 (covered by
TIM-01.vox), TIM-04, TIM-06 – TIM-10 (covered by TIM-05.vox), TIM-17 –
TIM-19, TIM-49 (covered by TIM-16.vox), TIM-33, TIM-34 (covered by
TIM-21.vox), TIM-35 (covered by TIM-24.vox), TIM-37 – TIM-39 (covered by
TIM-36.vox), TIM-44 (covered by TIM-11.vox and D5.vox), TIM-60 (covered
by TIM-36.vox, TIM-40.vox and TIM-46.vox).

## The table

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| TIM-01 | 4545, 4548 | `Get current time into <name>.` reads the current date/time into a new name as a `time` value. | emit the statement and read a property back | yes — `If now's unix is less than 1750000000 then, Print "ASSERT TIM-01: expected an epoch second count got {now's unix}". Exit 95.` | `gen leaf timer and clock` (`gen_misc.vox:218`), `gen leaf format types` (`gen_text.vox:490`) | exercised | |
| TIM-02 | 4549 | `a time called <name> is current time.` is the same operation in declaration form. | emit the declaration form at least sometimes instead of the `Get` form | yes — same assertion as TIM-01 on the declared name | none — both leaves emit only `Get current time into` | todo | |
| TIM-03 | 4545 | What either form produces is a `time` value (`'s type` reads `Time (static)`). | declare a time, assert its `type` | yes — `If now's type is not "Time (static)" then, … Exit 95.` | none — no leaf reads `'s type` on a time | todo | |
| TIM-04 | 4554 | Components of a time are read with the `'s` possessive. | any property read | yes — implied by any property assertion | both leaves (`'s unix`, `'s year`, `'s hour`) | exercised | |
| TIM-05 | 4558 | `hour` is the hour of day, 0–23, a Number. | read `hour` and bound it | yes — `If now's hour is less than 0 or now's hour is greater than 23 then, … Exit 95.` Exactly assertable against `unix` (see TIM-11). | `gen leaf format types` reads `hour` inside a `{…:02}` slot and checks the *width* is 2; the value is never bounded | exercised | |
| TIM-06 | 4559 | `minute` is the minute, 0–59, a Number. | read `minute` and bound it | yes — bound 0–59, and exactly `now's unix modulo 3600 divide 60` | none | todo | |
| TIM-07 | 4560 | `second` is the second, 0–59, a Number. | read `second` and bound it | yes — bound 0–59, and exactly `now's unix modulo 60` | none | todo | |
| TIM-08 | 4561 | `day` is the day of month, 1–31, a Number. | read `day` and bound it | yes — bound 1–31 (an exact assertion needs calendar arithmetic the generator does not have) | none | todo | |
| TIM-09 | 4562 | `month` is the month, 1–12, a Number. | read `month` and bound it | yes — bound 1–12 | none | todo | |
| TIM-10 | 4563 | `year` is the year (e.g. 2026), a Number. | read `year` and bound it below | yes — `If ty is less than 2026 then, … Exit 95.` (the build year is a lower bound the generator knows) | `gen leaf timer and clock` (`gen_misc.vox:221–222`) — checks `> 2000` but **prints** the verdict instead of exiting 95 | exercised | |
| TIM-11 | 4564 | `unix` is the Unix timestamp: seconds since the epoch. | read `unix` and check it is an epoch second count | yes, and **exactly** — `hour`/`minute`/`second` must equal the UTC decomposition of `unix`; that is a real oracle with no reference clock | `gen leaf timer and clock` (`gen_misc.vox:219–220`) — checks positive, prints the verdict | exercised | |
| TIM-12 | 4568–4581 | The Time Properties worked example compiles and runs, including the `Print the <name>'s <property>.` article form. | emit the whole sequence, article form included | yes — as the sum of TIM-05…TIM-11 | none — no leaf emits `the <time>'s <property>` with the article, nor `minute`/`second`/`day`/`month` at all | todo | |
| TIM-13 | 4586, 4590 | `current time's <property>` reads a property with nothing stored. | emit an inline read | yes — assert it against a stored reading taken in the same program | none | todo | |
| TIM-14 | 4589–4591 | The Inline Time Access example compiles and runs. | emit the three lines | yes — as TIM-13 | none | todo | |
| TIM-15 | 4596 | `Wait`/`Sleep` pause execution for the specified duration. | emit a wait between a timer's Start and Stop, assert the measured duration | yes — `If measured is less than requested then, … Exit 95.` The generator picks the duration, so it knows the floor. | none. `gen leaf timer and clock` deliberately never emits `Wait` (`gen_misc.vox:187–189`: "`Wait` IS the construct that needs a bound and is deliberately still not emitted here") | todo | |
| TIM-16 | 4606 | `Wait <N> second.` and `Wait <N> seconds.` are both accepted. | emit both, varying which | yes — as TIM-15 | none | todo | |
| TIM-17 | 4607 | `Wait <N> millisecond.` and `Wait <N> milliseconds.` are both accepted. | emit both | yes — as TIM-15 | none | todo | |
| TIM-18 | 4608 | `Sleep for <N> seconds.` is accepted. | emit it | yes — as TIM-15 | none | todo | |
| TIM-19 | 4609 | `Sleep for <N> milliseconds.` is accepted. | emit it | yes — as TIM-15 | none | todo | |
| TIM-20 | 4599–4602 | The four Sleep/Wait example lines compile and run. | emit all four spellings in one program | yes — as TIM-15 | none | todo | |
| TIM-21 | 4613 | A timer is a stopwatch: it tracks a start time, an end time, and the elapsed duration. | Start, do known work, Stop, read all three | yes — `start time <= end time`, and duration within the bounds of the known work | `gen leaf timer and clock` — Start/Stop and `elapsed`, but never `start time` or `end time` | exercised (partly — two of the three properties are never read) | |
| TIM-22 | 4618 | `Create a timer called '<name>'.` creates a timer under a quoted multi-word name. | emit the `Create` form with a quoted name | yes — assert `'s running` is false before Start | none — the leaf emits only the bare `a timer called tk{n}` form with a one-word name | todo | |
| TIM-23 | 4619 | `a timer called <name>.` creates a timer without `Create`. | emit the bare form | yes — same | `gen leaf timer and clock` (`gen_misc.vox:207`) | exercised | |
| TIM-24 | 4625, 4627 | `Start the <timer>.` starts it and `Stop the <timer>.` stops it. | emit both, with the article | yes — `running` is true between them and false after | `gen leaf timer and clock` (`gen_misc.vox:208, 214`) — but always the article-less `Start tk{n}` / `Stop tk{n}`; the manual's own `Start the 'job timer'.` form is never emitted | exercised (partly — the article form is never emitted) | |
| TIM-25 | 4631 | `Begin` is an accepted spelling of `Start`. | pick between the two spellings at random | yes — `running` is true after `Begin` | none — the leaf always writes `Start` | todo | |
| TIM-26 | 4632 | `Finish` is an accepted spelling of `Stop`. | pick between the two spellings at random | yes — `running` is false after `Finish` | none — the leaf always writes `Stop` | todo | |
| TIM-27 | 4634–4636 | The four words are contextual, not reserved: they open a timer statement only when a name operand follows — `Start the t.`, `stop t.` | emit the lowercase and the article-less spellings too | yes — `running` behaves the same whichever spelling is used | `gen leaf timer and clock` emits exactly one of the four shapes (capitalised, no article); lowercase and the article form are never emitted | exercised (partly) | |
| TIM-28 | 4636–4637 | `a number called stop is 0.` compiles — the timer words are ordinary names elsewhere. | emit a variable named `stop`/`start`/`begin`/`finish` | yes — assert the variable's value round-trips | none — the generator's name pool never produces these | todo | |
| TIM-29 | 4637 | A program may define and call its own zero-argument `start.` function. | emit `To start.` and a call to it | yes — assert the function's side effect happened | none | todo | |
| TIM-30 | 4638–4639 | "`End` is not a Stop spelling: `end` belongs to the `exit` family of keywords and remains reserved." | — | the first half is right; the second is **false** — `a number called end is 7.` compiles and prints 7, and `End.` is not an exit statement either | none | todo — **blocked on D1** | blocked on D1 |
| TIM-31 | 4645 | `duration` is the total duration of the measured interval. | measure a known interval, assert the total | yes — the generator picks the waits, so it knows the sum | none — no leaf reads `duration` | todo | |
| TIM-32 | 4646 | `elapsed` is the time elapsed **while the timer is running**. | read `elapsed` without stopping the timer, twice, and assert it grew | yes — `If second read is less than first read then, … Exit 95.` | none — the leaf reads `elapsed` only *after* `Stop` (`gen_misc.vox:223`, `'timer stop'` precedes `'read elapsed'`), which is TIM-48's shape, not this one | todo | |
| TIM-33 | 4647 | `start time` is when the timer was started, as a unix timestamp Number. | read it after Start | yes — assert it is >= a `unix` read taken just before Start | none | todo | |
| TIM-34 | 4648 | `end time` is when the timer was stopped, as a unix timestamp Number. | read it after Stop | yes — assert `end time >= start time` | none | todo | |
| TIM-35 | 4649 | `running` says whether the timer is currently running, as a Boolean. | read it before Start, between, and after Stop | yes — false/true/false | none | todo | |
| TIM-36 | 4653 | `in <unit>` casts a duration to a specific unit. | emit the cast | yes — the two units must agree: `milliseconds` within 1000 of `seconds × 1000` | `gen leaf timer and clock` (`gen_misc.vox:216`) — `elapsed in milliseconds` only | exercised | |
| TIM-37 | 4656 | `<timer>'s duration in seconds` reads. | emit it | yes — assert against the known waits | none | todo | |
| TIM-38 | 4657 | `<timer>'s duration in milliseconds` reads. | emit it | yes — same | none | todo | |
| TIM-39 | 4658 | `<timer>'s elapsed in seconds` reads. | emit it | yes — same | none — only the `in milliseconds` cast is ever emitted | todo | |
| TIM-40 | 4664–4686 | The Complete Timer Example compiles and behaves as shown: create, start, wait, read `elapsed`, wait, stop, read `duration`, read both raw timestamps. | emit the whole sequence | yes — as the sum of TIM-15, TIM-21, TIM-31, TIM-33, TIM-34, TIM-37 | none | todo (composite) | |
| TIM-41 | 4690–4692 | A time property can be read directly inside a format slot, and the zero-pad specifier applies to it. | emit `"{now's hour:02}"` | yes, and **already the right shape**: a zero-padded hour is two characters whatever the clock reads | `gen leaf format types` (`gen_text.vox:491–493`) — builds the text, copies it into a buffer and checks `'s length is equal to 2`, printing the verdict instead of exiting 95 | exercised (one property; the check is a printed verdict, not an assertion) | |
| TIM-42 | 4695–4697 | `Print "{now's hour:02}:{now's minute:02}:{now's second:02}"` prints a `09:05:03`-shaped time. | emit all three slots in one string | yes — the rendered text is 8 characters with `:` at positions 3 and 6 | none — only `hour` is ever put in a slot | todo | |
| TIM-43 | 4703–4709 | The named-parts variant — each padded property stored in a `text` first, then combined in one more format string — produces the same thing. | emit the two-stage form | yes — same assertion as TIM-42 | none | todo | |
| TIM-44 | 4556–4564 *(undocumented)* | *(gap)* The time components are **UTC**. The manual names no timezone; the properties agree with the UTC decomposition of `unix` and do not move when `TZ` does. | assert `hour` equals `unix modulo 86400 divide 3600` | yes — exactly, and it is the strongest oracle in the section | none | todo — see **Discrepancy 5** | |
| TIM-45 | 4645–4646 *(undocumented)* | *(gap)* The "requires cast" note is not enforced: `duration` and `elapsed` read with no cast, and the uncast reading is the seconds one. | read both forms and compare | yes — `If uncast is not (duration in seconds) then, … Exit 95.` | none | todo — see **Discrepancy 2** | |
| TIM-46 | 4641–4649 *(undocumented)* | *(gap)* A timer that was never started reads 0 for every property and is not running; `Stop` before any `Start` is not an error, but leaves a duration equal to the whole reading of the monotonic clock (the machine's uptime), not to any interval the program asked for. | emit Stop-before-Start and read the properties back | partly — "all zero before any Stop" is exactly assertable; the post-Stop duration is a machine-dependent number, so only "absurdly larger than anything this program waited for" is assertable | none | todo | |
| TIM-47 | 4625 *(undocumented)* | *(gap)* Starting an already-run timer **restarts** it: the next `duration` covers only the second run. | Start/Stop twice with different waits, assert the second duration is the shorter one | yes — the generator picks both waits | none | todo | |
| TIM-48 | 4646 *(undocumented)* | *(gap)* After `Stop`, `elapsed` freezes and reads the same as `duration`. | read `elapsed` twice after Stop with a wait between | yes — `If second read is not first read then, … Exit 95.` and `elapsed == duration` | `gen leaf timer and clock` emits the shape (it reads `elapsed` after `Stop`) but asserts nothing about it beyond "not negative", printed | exercised | |
| TIM-49 | 4606–4609 *(undocumented)* | *(gap)* `for` is optional after both verbs: `Sleep 4 milliseconds.` and `Wait for 5 milliseconds.` both compile. | vary whether `for` appears | yes — as TIM-15 | none | todo | |
| TIM-50 | 4605–4609 *(undocumented)* | *(gap)* The duration operand is a literal or a bare variable; an expression there is a compile error naming the four unit words. | — | **no** — a compile-error claim; emitting it would produce a non-compiling program, outside the generator's contract. It is a **constraint on the generator**: compute the duration into a name first. | none | not assertable | |
| TIM-51 | 4606–4609 *(undocumented)* | *(gap)* A negative duration in **seconds** returns immediately (the kernel rejects a negative `tv_sec`). | emit a negative seconds wait, assert the program continued quickly | yes — measure it with a timer | none | todo | |
| TIM-52 | 4611–4649 *(undocumented)* | *(gap)* Accepted spellings the manual never lists: `retrieve`/`fetch` for `get`, `stopwatch` for `timer`, `pause` for `wait`, `delay` for `sleep`, `timestamp`/`unixtime` for `unix`, and plural `hours`/`minutes`/`days`/`months`/`years` for the property names. | vary the spelling wherever more than one exists | yes — each alias must give the same answer as its canonical form | none — every leaf uses one fixed spelling | todo — see **Discrepancy 4** | |
| TIM-53 | 4560 *(undocumented)* | *(gap)* The plural spellings stop short of `seconds`: `now's second` reads, `now's seconds` is a compile error, because `seconds` is the Wait unit word. | — | **no** — a compile-error claim; it is a constraint on TIM-52's spelling variation | none | not assertable | |
| TIM-54 | 4545 *(undocumented)* | *(gap)* A `time` printed, or put in a format slot, renders as its unix second count — a `time` **is** its unix seconds. | print a time and its `unix` and compare | yes — `If "{now}" is not "{now's unix}" then, … Exit 95.` | none | todo | |
| TIM-55 | 4556–4649 *(undocumented)* | *(gap)* The section's property words are reserved variable names: `duration`, `elapsed`, `running`, `timer`, `stopwatch`, `time`, `unix`, `hour`, `minute`, `day`, `month`, `year`, `wait`, `sleep`, `milliseconds`, `ms`, `current` are all rejected; `second`, `start`, `begin`, `stop`, `finish`, `end` are accepted. | — | **no** — a naming rule, not a runtime result. It is a **constraint on the generator's name pool**, and the six accepted words are names it is allowed to use (TIM-28). | n/a | not assertable | |
| TIM-56 | 4625 *(undocumented)* | *(gap)* `Start`/`Stop` on a non-timer is `Start requires a timer: <name>`, and on an unknown name is `Unknown timer: <name>`. | — | **no** — compile-error claims. Recorded because the diagnostic's span points at the **declaration** of the operand, not at the offending `Start` — which will mislead triage of a generated program that fails to compile. | none | not assertable | |
| TIM-57 | 4556–4564 *(undocumented)* | *(gap)* A time property read from a plain number is accepted and the number is decomposed as an epoch second count (`3` → unix 3, hour 0, year 1970). | emit a time property on a non-time number | yes — `If (3)'s year is not 1970 then, … Exit 95.` — and it is a memory-safety row: it must not crash | none | todo | |
| TIM-58 | 4653 *(undocumented)* | *(gap)* `in` accepts only `second`/`seconds`/`millisecond`/`milliseconds`/`ms`. `minutes`, `hours` and `nanoseconds` are compile errors. | — | **no** — a compile-error claim; it is the constraint that bounds TIM-36's unit variation | none | not assertable | |
| TIM-59 | 4556–4564 *(undocumented)* | *(gap)* A time property read from a **text** is a compile error: `Property 'year' requires a time value (number)`. | — | **no** — a compile-error claim. Its parenthetical is the clearest statement anywhere that a `time` is a number. | none | not assertable | |
| TIM-60 | 4613, 4647–4648 *(undocumented)* | *(gap)* `duration`/`elapsed` and `start time`/`end time` come from **different clocks**: the timestamps are unix wall-clock seconds, the durations are monotonic and carry millisecond precision. A 1.5-second job shows start and end one second apart and a duration of 1500 ms. | read all four around a known interval | yes — `duration in milliseconds` must be finer than the timestamp difference allows | none | todo | |

### A note on the worked examples

All five run, but none of them lays out the way it reads. `Print` ends
its line (LANGUAGE.md:3348–3361 gives `without newline` as the way to
avoid that), so

```
Print "Current time: ".
Print the now's hour.
```

produces two lines, not `Current time: 04`. The Complete Timer Example
has the same shape three times over. Nothing here is a claim the manual
makes explicitly — no expected output is printed beside these examples —
so it is not filed as a discrepancy, but a reader copying the example to
get the layout it implies will not get it, and a leaf built from these
examples should use `without newline` or a format string.

## Discrepancies

Recorded, not adjudicated. Each has a runnable repro in
`docs/ledger/probes/time/`.

### 1. `end` is not reserved, is not an exit keyword, and the manual uses it as a name elsewhere

LANGUAGE.md:4638–4639, closing the note on contextual timer words:

> (`End` is not a Stop spelling: `end` belongs to the `exit` family of
> keywords and remains reserved.)

Repro (`D1.vox`):

```
a number called end is 7.
print end.
```

Output: `7`. It compiles; `end` is not reserved. And it is not an exit
keyword either — `End.` on its own gives `Unknown function: End`, while
LANGUAGE.md:2410 lists the exit aliases as `quit` and `terminate`.

The manual also contradicts itself here: **LANGUAGE.md:302** writes
`Set end to 5.` in the Ranges section, and **LANGUAGE.md:1102** writes
`a point called end.` in a thing definition. Both require exactly the
behaviour the compiler has.

**The strongest reading in which the compiler is correct:** `end` *is*
in the exit family as far as the lexer's alias table is concerned —
`src/lexer/tokens.rs:124` maps `"exit" | "quit" | "terminate" | "end" |
"halt" | "abort"` to `exit` — so the sentence describes a real internal
fact. What it gets wrong is the consequence. That table feeds the
"alternate spelling" diagnostic, not the statement parser and not the
reserved-name check, so being in the family costs `end` nothing: it is
neither usable as a statement nor banned as a name. Under that reading
the compiler is behaving as designed (and as the manual's own Ranges and
Things examples need it to), and the parenthetical at 4225 is asserting
a consequence that does not follow. The half that *is* true — `End` is
not a Stop spelling — is true.

### 2. `duration` and `elapsed` are marked "requires cast", and do not

LANGUAGE.md:4645–4646:

| `duration` | Total duration (requires cast) | Duration |
| `elapsed` | Elapsed time while running (requires cast) | Duration |

Repro (`D2.vox`):

```
a timer called lap.
Start the lap.
Stop the lap.
print lap's duration.
print lap's elapsed.
```

Output: `0` / `0` — no cast, no error. On a timer that has measured 1500
milliseconds (`TIM-45.vox`) the uncast reading is `1`, i.e. exactly the
`in seconds` reading.

**The strongest reading in which the compiler is correct:** "requires
cast" is advice about *meaning*, not a statement about what the parser
enforces — a bare `duration` is a Duration whose unit you have not
chosen, and printing one without saying which unit you wanted is a
question the compiler answers with its default (seconds) rather than
refusing. That reading is coherent, and it leaves the manual owing the
reader one sentence: what the uncast reading means. As written, a reader
takes "requires cast" for a compile-time rule and is wrong, and a leaf
built on that reading would never emit the uncast form at all.

### 3. A negative millisecond wait never returns; the same nonsense in seconds returns at once

The manual gives no behaviour for a negative duration (LANGUAGE.md:4605–
4196 lists only `Wait <N> …`). What happens is asymmetric.

Repro (`D3.vox`), which does not terminate:

```
Wait -5 milliseconds.
print "the wait returned".
```

`TIM-51.vox` is the other half: `Wait -1 seconds.` and
`Sleep for -2 seconds.` both return immediately and the program carries
on.

The mechanism is in `coreasm/x86_64/time.asm`, `SLEEP_MILLISECONDS`: the
count is divided by 1000 with an **unsigned** `div`, so `-5` is
18446744073709551611 milliseconds and `tv_sec` becomes about 1.8 × 10¹⁶
seconds — roughly 585 million years. `SLEEP_SECONDS` writes the value
straight into `tv_sec`, where a negative number is rejected by the kernel
(`EINVAL`) and the syscall returns at once.

**The strongest reading in which the compiler is correct:** durations are
counts, and a count is unsigned; `Wait -5 milliseconds.` is not a request
to wait a negative time but a request to wait 2⁶⁴−5 of them, which the
program is then honestly doing. Nothing is corrupted, nothing crashes,
and a program that asks to sleep forever sleeps forever. It is worth
weighing against that: the seconds spelling of the identical nonsense
does *not* wait forever, so whichever behaviour is right, both cannot be.
For this project the practical consequence is the same either way — a
generated `Wait` with an unbounded operand is a hang, which is a finding
category of its own, and it is why `gen leaf timer and clock` refuses to
emit `Wait` at all today (`src/gen_misc.vox:187–189`). Any leaf that
starts emitting `Wait` must bound the operand to a small positive
literal or a name it has just assigned a small positive literal.

### 4. The Time and Timers section has reserved aliases, and the Reserved Aliases table does not list them

LANGUAGE.md:5165–5240 introduces its table as the alternate spellings
"also reserved because the compiler recognizes them as aliases for
canonical keywords", and lists three: `ms`, `message`, `string`.

Repro (`D4.vox`):

```
a number called stopwatch is 1.
print stopwatch.
```

Compile error: `'stopwatch' is an alternate spelling of the reserved
keyword 'timer'.` — the diagnostic names it an alias in so many words.
`TIM-52.vox` runs the rest of them working as aliases: `retrieve` for
`get`, `pause` for `wait`, `delay` for `sleep`, `timestamp` and
`unixtime` for `unix`, and the plural property spellings
`hours`/`minutes`/`days`/`months`/`years` (`src/lexer/tokens.rs:217–234`
is the table they come from).

**The strongest reading in which the compiler is correct:** the Reserved
Aliases table says "A few alternate spellings are **also** reserved",
which is a sample and not a closure — the sentence that does the real
work is the one after it, "Every keyword listed in the tables above is
likewise reserved as a variable name", and the timer property table *is*
a table above. Under that reading nothing is wrong, only unlisted. The
cost is still real for this project: every one of these is both a name a
generated program must not collide with and a spelling the generator
should be varying, and neither fact is discoverable from the manual.

### 5. The time components are UTC, and the manual never says so

LANGUAGE.md:4556–4564 gives `hour` as "Hour of day (0-23)" and names no
timezone anywhere in the section.

Repro (`D5.vox`) checks the components against the UTC decomposition of
`unix` and reports that they agree. Run on a machine in BST (UTC+1) at
local 05:01, `now's hour` read `4`; run again under
`TZ=America/New_York` — local 00:01 — it still read `4`. `TZ` is
ignored; the components are UTC.

**The strongest reading in which the compiler is correct:** a `time` is
its unix second count (TIM-54, TIM-57), and the only decomposition of a
unix count that needs no further input is the UTC one. Local time would
require a timezone database and a `TZ` reading, which is a much larger
promise than a property table implies. UTC is the right default, and the
manual is simply missing the word. The reason it matters here rather
than being a footnote: without it there is no oracle. With "UTC" written
down, `hour`, `minute` and `second` become exactly assertable against
`unix` and this section gains its only reference-free way to catch a
wrong answer.

## Invariants this section justifies

Every sameness this section's rules actually require of generated
programs, with the line and the row that justifies it. The invariant
report's `citation` column is filled from these.

- a time property is read with the `'s` possessive, never any other way —
  LANGUAGE.md:4554, TIM-04
- the property names are exactly `hour`, `minute`, `second`, `day`,
  `month`, `year`, `unix` for a time and `duration`, `elapsed`,
  `start time`, `end time`, `running` for a timer; nothing else is a
  property of either — LANGUAGE.md:4556–4564, 4643–4649, TIM-05…TIM-11,
  TIM-31…TIM-35
- `in` is followed only by a second or millisecond unit word —
  LANGUAGE.md:4653, TIM-36, TIM-58
- a `Wait`/`Sleep` duration operand is a literal or a bare name, never an
  expression — TIM-50
- a generated name is never one of `duration`, `elapsed`, `running`,
  `timer`, `stopwatch`, `time`, `unix`, `hour`, `minute`, `day`, `month`,
  `year`, `wait`, `sleep`, `milliseconds`, `ms`, `current` — TIM-55
- `Start`/`Stop` name a timer, never any other variable — TIM-56
- a time property is read from a time or a number, never from a text —
  TIM-59

**Samenesses this section does NOT justify** — each is a rule nobody
declared, and every one of them is in the corpus today:

- `Start` is always the start spelling and `Stop` always the stop
  spelling. The manual gives `Begin` and `Finish` equal standing
  (LANGUAGE.md:4631–4632, TIM-25, TIM-26), so the choice must vary.
- the timer statement is always capitalised and always article-less
  (`Start tk{n}`). All four combinations parse
  (LANGUAGE.md:4634–4636, TIM-27).
- a timer is always created with the bare `a timer called <name>.` form.
  `Create a timer called '<name>'.` is equally documented
  (LANGUAGE.md:4618, TIM-22).
- a timer name is always one word. The manual's own examples use quoted
  multi-word names throughout (LANGUAGE.md:4618, TIM-22).
- the current time is always obtained with `Get current time into <name>`.
  The declaration form is equally documented (LANGUAGE.md:4549, TIM-02).
- `elapsed` is always cast `in milliseconds`. `in seconds` is equally
  documented and the uncast form works too (LANGUAGE.md:4656–4658,
  TIM-37…TIM-39, TIM-45).
- `duration` never appears at all, though it is the property the section
  is built around (LANGUAGE.md:4645, TIM-31).
- only `unix`, `year` and `hour` are ever read. Four of the seven time
  properties are never emitted by anything (TIM-06…TIM-09).
- `Wait` and `Sleep` never appear. This one is **deliberate and correct
  today** (`src/gen_misc.vox:187–189`) and Discrepancy 3 says why, but it
  is still an unjustified invariant: the manual documents the construct
  and it needs a bounded leaf, not a permanent absence.

## Report

**60 rows** (TIM-01 … TIM-60). 43 of them map claims the manual actually
makes; the remaining 17 (TIM-44 … TIM-60) are undocumented behaviour
found while probing, recorded the way the buffer ledger recorded BUF-29
and BUF-30 — the manual is silent and the compiler is not.

**Assertable: 54 of 60.** Six are not: TIM-50, TIM-53, TIM-56, TIM-58 and
TIM-59 are compile-error claims (emitting them would produce a
non-compiling program, outside the generator's contract — they are
constraints on the generator instead), and TIM-55 is a naming rule. Of
the 54, TIM-46 is only partly assertable and TIM-30 is blocked on
Discrepancy 1.

The section is unusually rich in oracles for something clock-driven,
because of one fact: **`unix` and the
components are the same number seen two ways**, so `hour`, `minute` and
`second` can be asserted exactly with no reference clock at all
(TIM-11.vox). That is the single most useful thing in this map.

**Existing coverage: 12 rows exercised, 0 verified, 42 todo, 6 not
assertable.** Two leaves touch this section, and four of the twelve
exercised rows are only partly exercised — each of those rows says which
half is missing. What the two leaves do with the constructs they emit is
the same thing the buffer ledger found: `gen leaf
timer and clock` and `gen leaf format types` both *check* their results
and both **print a verdict rather than exiting 95**, so a wrong answer
becomes an output line rather than a `wrong-value` finding. Turning those
two printed verdicts into assertions is a smaller job than any new leaf
here and should come first.

**The biggest finding is Discrepancy 3**: `Wait -5 milliseconds.` never
returns, while `Wait -1 seconds.` returns immediately. It is a hang, it
is one line long, and it reproduces every time. It is also the reason
this section has no `Wait` coverage at all, which leaves six documented
rows (TIM-15 … TIM-20) untested — the largest single gap in the section
and the one that most needs a decision before a leaf is built.

**For the next mapper**, four things this section cost me:

1. **Re-pin the line range before you start.** `INDEX.md` is on 0.4.7 and
   the manual is on 0.4.8, 128 lines longer. The brief's range pointed at
   the wrong chapter entirely.
2. **A clock-driven probe has to check, not print.** `docs/check-probes.sh`
   diffs stdout exactly, so any probe that prints a time is unrunnable a
   second later. Verdict-printing is the pattern (`gen_misc.vox:191` got
   there first). For the manual's worked examples, which must stay
   verbatim, record them as exit-code probes — the checker honours an
   `exit N` in the expected block and ignores stdout.
3. **Probe the keyword census by hand, early.** `a number called <word>
   is 1.` over every word in your section's tables takes one loop and
   answers a question the manual does not: which of them are reserved.
   Seventeen words in this section are reserved and the manual lists
   none of them; six that look reserved are not. That is TIM-55, D4 and
   half of D1, all from the same two-minute loop.
4. **`the <name>'s type` does not parse** — for any type, not just times:
   `n's type` works, `the n's type` is rejected. It cost me a probe
   rewrite and it belongs to whoever maps Types (428–445) or Expressions
   (1789–2025), not here. Worth checking whether the article is refused
   in front of other universal properties too.
