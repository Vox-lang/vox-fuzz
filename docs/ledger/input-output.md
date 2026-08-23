# Claim ledger: Input/Output → Print, format strings, conditional print

Source: `../vox/LANGUAGE.md` lines **3128–3283**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual) — Input/Output, from the `##
Input/Output` heading to the `## File I/O` heading: Print, Format
Strings, Format Specifiers, Expressions in Format Strings, Format
Strings as Values, Format Strings Everywhere, Declarations in Branches,
Escape Sequences, Conditional Print.

The 0.4.8→0.4.9 drift in this range is a uniform **+56 lines**, confirmed
at multiple anchors before applying it mechanically.

**Both discrepancies with an open compiler-side finding are now
resolved, re-verified directly against vox 0.4.9:**
- **D1** (`{arguments's first}` into a buffer segfaults) — already
  marked fixed by vox #52 in an earlier pass; re-confirmed here.
- **D2** (a list in a format string used as a *value* renders a raw
  pointer) — **fixed by vox #44**, the same fix that closed
  collections-a's and collections-b's own D7 (variable-form sub-case).
  Both facets (a list held in a text, and `{arguments's all}` in a
  `Print` slot) now render correctly; re-tested directly, not just
  re-read. The narrower *expression*-form sub-case those two ledgers
  found remains open elsewhere (vox candidate #68) but is untouched by
  this section's own claims.

**Also fixed a probe-formatting inconsistency, not a compiler-drift
finding**: `FMT-43.vox` recorded its diagnostic as `compile error:
<message>` (one line, non-standard prefix) where the convention every
other compile-error probe in this repo uses is a bare `error: <message>`
line plus a separate `(compile error - no binary is produced)` note —
`check-probes.sh`'s message-matching logic only strips a leading `error:
`, not `compile error:`, so this one probe was failing on a wording
mismatch, not a behavioural one. Reformatted to the standard convention;
the recorded diagnostic text itself is unchanged and still accurate.

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct, or `none`, and was established
by `grep` on the construct — `without newline`, `and if`, `\\`, `the `,
`Execute`, `Create a directory`, `treating ... as "{` — not by leaf name.

Format strings are the best-covered surface in this generator.
`src/gen_text.vox` carries four dedicated leaves — `gen leaf format
specifiers`, `format expression`, `format value`, `format types` — over
the `gen format slot` / `gen pick integer spec` / `gen pick float spec`
helpers, and between them
they emit **every row of the specifier table** and **most of the sinks**
"Format Strings Everywhere" names. That is a much better starting position
than buffers had. The gaps are concentrated elsewhere: `Print` itself
(the article form, `without newline`), the escape table's last row, the
`treating` and filesystem-path sinks, `Execute`, all of Declarations in
Branches, and `and if`.

One correction to the buffer ledger's forward-looking advice ("the 'no
leaf asserts anything' pattern is likely universal"): **it is not
universal.** `gen leaf format types` already asserts — its `clock check`
line emits `If hc{n}'s length is equal to 2 then, ... Otherwise, Print
"ht{n} BAD"` — and `gen leaf timer and clock` and `gen leaf predicate
probe` do the same. The assertions are in the print-a-BAD-line form, not
the exit-95 form PROCEDURE.md §6 now mandates, so they are findings only
if a human reads the output; converting them is a smaller job than writing
them from nothing.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` set to
the sibling `coreasm`) before being written.

## Probes

`docs/ledger/probes/input-output/`, one file per hand-verified row named
`FMT-NN.vox`, plus `D1.vox`–`D5.vox` for the discrepancies. A probe
covering more than one row is named for the first and says so in its own
header (FMT-22 also covers FMT-24; FMT-41 also covers FMT-44; FMT-45 also
covers FMT-46; FMT-47 also covers FMT-48 and FMT-49).
Each opens with a `(...)` comment naming the claim, the exact `Ran:`
command, and an `expected output:` block recording what the compiler
**actually** printed.

**53 probe files. `docs/check-probes.sh docs/ledger/probes/input-output`
reports 53 passed, 0 failed, 0 skipped.** Three of them record a refusal
rather than an output (FMT-18, D4, D5 are compile-error probes).

**Refreshed 2026-08-21 against vox 0.4.8 + #52.** `D1.vox` used to record
`exit 139`; vox #52 fixed the crash, so it was rewritten to record the
fixed behaviour — all three buffer verbs now copy `{arguments's first}`
and the program exits 0. Nothing in this directory crashes any more.

Rows with no probe file: FMT-23 and FMT-30 (nothing to run — see each
row), and FMT-24, FMT-44, FMT-46, FMT-48, FMT-49, each covered by a
sibling's probe that names it in its own header (FMT-22 covers FMT-24;
FMT-41 covers FMT-44; FMT-45 covers FMT-46; FMT-47 covers FMT-48 and
FMT-49).

Three probes deliberately assert rather than print, because their honest
output is not stable across runs: FMT-37 (the clock), D2 and D3 (raw
pointer addresses). Each says so in its own header. FMT-31, FMT-32,
FMT-34, FMT-38 and FMT-39 write under `/tmp`; all are idempotent and
re-run clean, `Create a directory` included (hand-verified: a second run
over an existing directory exits 0 silently).

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FMT-01 | 3287 | `Print "literal".` writes the literal followed by a newline. | a Print of a string literal | yes — the generator wrote the literal, so `If out is not "…" then, Exit 95.` is only reachable through a file round-trip; in practice this is the floor row and asserting it buys nothing | `gen leaf format specifiers`, `gen leaf butif print`, and most leaves' `Print "…"` lines | exercised | |
| FMT-02 | 3288 | `Print the x.` — a variable reference written with the article `the` prints the same value the bare form does. | a Print whose operand carries the article | yes — same value both ways, so the leaf can print both and assert equality | **none for a Print operand.** `gen var ref` returns a bare `v{N}` and every leaf interpolates that, so no `Print` in any generated program ever carries the article. The article is not entirely absent from emitted text — `gen leaf timer and clock` emits it before a possessive (`a number called tl{n} is the tk{n}'s elapsed in milliseconds`, and likewise for `'s unix` / `'s year`), and `gen emit prelude thing methods` emits it in a method header (`To do the t4's 'made at'`) — but never as a plain variable reference, which is the form this row claims | todo — real gap, hand-verified to work | |
| FMT-03 | 3289 | `Print 'add numbers' of 3 and 5.` prints a function call's result. | a Print whose operand is a call | yes — the prelude's `f1`/`f2`/`f3` are fixed, so the generator can compute the expected result | `gen call zero` (`Print f1`), `gen call one` (`Print f2 of c{N}`), `gen call two` (`Print f3 of c{N} and c{M}`), all reached through `gen leaf call` / `gen leaf call safe` | exercised | |
| FMT-04 | 3294 | `Print "…" without newline.` suppresses the trailing newline on a literal. | a Print with the `without newline` suffix, followed by another Print, so the joined line is observable | yes — two suppressed prints and a plain one make one known line; assert it after a file round-trip, or simply let the invariant report see a line the generator predicted | **none** — `without newline` appears **zero times** across all eight `src/gen_*.vox` files | todo — real gap | |
| FMT-05 | 3295 | The same suffix works on a bare variable reference, not only a literal. | as FMT-04 with a variable operand | yes, same way | **none** (same grep) | todo — real gap | |
| FMT-06 | 3294–3296 | The worked example: two suppressed prints then a plain one produce the single line `Loading: 75%`; `%` in a literal is a character, not a format directive. | the three-statement sequence verbatim | yes — the whole line is known at generation time | **none** | todo (composite of FMT-04/FMT-05) | |
| FMT-07 | 3301 | `{}` interpolates a variable's value into a string literal. | any format slot naming a variable | yes — the generator chose the value | `gen leaf format specifiers` (`print default`), `gen leaf format types` (nine typed slots), `gen leaf format value` | exercised | |
| FMT-08 | 3304–3306 | The worked example: a text slot and a number slot in one string with literal text between and after them. | one string carrying two slots of different types and interleaved literal text | yes | `gen leaf format types` `print all` puts nine slots of nine types in one string with separators — a superset of the example's shape, though not the example's text | exercised | |
| FMT-09 | 3313 | `{var}` with no specifier is default formatting: what `Print` alone would render. | a bare slot | yes | `gen leaf format specifiers` (`print default`); `gen pick integer spec` returns `""` on pick 0 and `gen format slot` then emits `{inner}`, never `{inner:}` | exercised | |
| FMT-10 | 3314 | `{var:.N}` renders a float to N decimal places (`{pi:.2}` → `3.14`). | a float slot with a `.N` specifier | yes — the generator picks both the float and N, so it can compute the rounded string | `gen leaf format specifiers` (`print precision`), `gen pick float spec` pick 1 | exercised | |
| FMT-11 | 3315 | `{var:N}` pads to N characters. **Hand-verified precision the table omits: the pad is spaces on the LEFT — right-aligned in the field** (`{x:6}` → `    42`). | a numeric slot with a bare width | yes — `If padded is not "    42" then, Exit 95.` | `gen leaf format specifiers` (`print width`, `print text width`, `print boolean pad`), `gen pick integer spec` pick 1, `gen pick float spec` pick 2 | exercised | |
| FMT-12 | 3316 | `{var:0N}` zero-pads to N characters (`{x:06}` → `000042`). | a numeric slot with a `0N` specifier | yes, same way | `gen leaf format specifiers` (`print zero pad`), `gen pick integer spec` pick 2 | exercised | |
| FMT-13 | 3317 | `{var:x}` is lowercase hex **and includes a `0x` prefix** (`{n:x}` → `0xff`). | a numeric slot with `:x` | yes — the generator knows n | `gen leaf format specifiers` (`print hex`), `gen pick integer spec` pick 3 | exercised | |
| FMT-14 | 3318 | `{var:X}` is uppercase hex, also prefixed, and the prefix's `x` stays lowercase (`{n:X}` → `0xFF`). | a numeric slot with `:X` | yes | `gen leaf format specifiers` (`print hex upper`), `gen pick integer spec` pick 4 | exercised | |
| FMT-15 | 3319 | `{var:b}` is binary and, unlike x/X/o, carries **no** base prefix (`{n:b}` → `101`). | a numeric slot with `:b` | yes | `gen leaf format specifiers` (`print binary`, on the modest `zk` operand), `gen pick integer spec` pick 5 | exercised | |
| FMT-16 | 3320 | `{var:o}` is octal and carries a `0o` prefix (`{n:o}` → `0o10`). | a numeric slot with `:o` | yes | `gen leaf format specifiers` (`print octal`), `gen pick integer spec` pick 6 | exercised | |
| FMT-17 | 3321 | `{var:04x}` is width-4 zero-padded lowercase hex. **Hand-verified precision the table omits: the width counts the DIGITS, not the whole rendering — `0x00ff` is six characters, the prefix sits outside the padded field.** | a numeric slot with a padded-hex specifier | yes — and this is the one specifier row where a naive reading (width 4 → four characters total) would produce a false-finding factory | `gen leaf format specifiers` (`print padded hex`), `gen pick integer spec` pick 7 | exercised | |
| FMT-18 | 3323–3326 | The value inside `{}` must be a variable or expression, never a bare literal: `{255:x}` is refused because `255` is read as a variable name. Hand-verified that the specifier is irrelevant — `{255}` is refused identically. | — | **no** — a leaf cannot emit this. `CLAUDE.md`'s invariant is that a generated program is legal Vox that should compile and run; a deliberate compile error would be classified as a generator defect by the runner, not a finding. Assertable by the *harness* (a negative-compile fixture), not by a leaf | n/a | not assertable (by a leaf) — probe retained; see also **Discrepancy 5** | |
| FMT-56 | 3372–3379 | **New row, 2026-08-22 (0.4.10, #85) — closes a gap neither FMT-10 (precision alone) nor FMT-11 (width alone) covered.** A width and a precision written together in one format specifier **compose**: `{var:8.2}` asks for two decimal places, padded out to eight characters — the precision decides the digits, the width decides the padding, each honoured wherever there is something to honour it with. `{n:8.2}` on a whole number prints `  255.00`, `{n:08.2}` prints `00255.00`; on a `float` the places are printed and the padding is not (no float padder yet — the same limit a bare `{f:8}` already has). Before #85, the spec reader consumed the width and then matched the leftover `.2` against the base specifiers, falling to a catch-all that dropped the precision silently: `{f:8.2}` printed `2.5`, not `2.50`. | emit `{n:W.P}` on a whole number and assert both the digit count and the padding; separately on a `float`, assert the digits print and the padding does not | yes — the generator knows the value, so it knows the exact padded/rounded string | none — no leaf emits a combined width-and-precision specifier at all (`gen leaf format specifiers`/`gen pick integer spec`/`gen pick float spec` each emit width or precision, never both together) | todo — real gap, hand-verified against 0.4.10: `a number called n is 255.` — `Print "{n:8.2}"` → `  255.00`, `Print "{n:08.2}"` → `00255.00` | |
| FMT-19 | 3386 | An arithmetic expression is legal inside a slot: `{x add y}`. **Citation corrected, 2026-08-22** — the arithmetic-shift auto-repin landed this (and FMT-20/21) on unrelated prose ("count the compiler can hold...") both in the 0.4.9 and 0.4.10 passes; a pre-existing loose anchor, not a 0.4.10 regression. Now pointed at the actual worked-example line. | a slot whose contents are an expression | yes — the generator built the expression | `gen leaf format expression` (`sum slot`, and `deep slot` from `gen deep expr` at depth 2–8) | exercised | |
| FMT-20 | 3387 | **Citation corrected, 2026-08-22 — see FMT-19.** `{x multiply y}` — a second operator in a slot, so the feature is the expression grammar and not one hardcoded verb. | as FMT-19 with another operator | yes | `gen leaf format expression` (`product slot`, `chain slot`) | exercised | |
| FMT-21 | 3388 | **Citation corrected, 2026-08-22 — see FMT-19.** A possessive special name resolves inside a slot: `{arguments's count}`. Hand-verified: with no arguments the count is 1, so the program name is counted. | a slot naming a possessive special | yes — `arguments's count` is 1 under the runner, which passes no arguments | `gen leaf format expression` (`count slot`) — the **only** argument property any leaf ever places in a slot | exercised | |
| FMT-22 | 3382 | Format strings are expressions, not just Print arguments. | a format string in a non-Print position | yes | `gen leaf format value` (`token decl`, `path decl`, `held decl` in `gen leaf format expression`) | exercised | |
| FMT-23 | 3383 | A format string used as a value materializes into a fresh **NUL-terminated** string. | — | **no** directly — NUL-termination is not observable from inside Vox. Its one observable consequence is that the string survives `execve`'s argv, which is FMT-25 | n/a | not assertable separately — observable half is FMT-25, freshness half is FMT-29 | |
| FMT-24 | 3384 | A format string works as a text **initializer** and as an **assignment**. | both `a text called t is "{…}"` and `Set t to "{…}"` | yes — the generator knows both strings | `gen leaf format value` (`token decl`, `path decl`) covers the initializer. **The assignment form is absent**: `grep` for `Set <text> to "{` across all leaves finds nothing; `scratch set` is a *buffer* `set`, a different statement (FMT-33) | exercised (initializer only) — todo for assignment | |
| FMT-25 | 3384–3385 | A format-string text survives being carried through a list into an `Execute` argument list. | append the text to a list, `Execute` with that list | yes — the child echoes the argument back, so the parent's expected string is checkable | **none for the Execute half** — `gen leaf format value` does `list append` + `print element`, which is bug #17's shape and worth keeping, but **`Execute` appears in no leaf at all** (`grep`: only a comment in `gen_files.vox`) | todo — real gap | |
| FMT-26 | 3402 | `a text called tok is "{word}".` builds a text from a **buffer's** contents. | a text initialized from a slot naming a buffer | yes — the generator filled the buffer | `gen leaf format value` (`token decl`, over the `gw{n}` buffer filled by `buffer fill`) — the manual's own worked example, already emitted | exercised | |
| FMT-27 | 3392 | `a text called path is "/bin/{tok}".` builds a text from **another text** that itself came from a format string. | the chained case | yes | `gen leaf format value` (`path decl`) | exercised | |
| FMT-28 | 3387–3397 | The whole worked example compiles and runs. | the example end to end | yes | every line but the last: `Execute` is unreached (FMT-25) | todo (composite) — sub-claims FMT-24/26/27 exercised, FMT-25 todo | |
| FMT-29 | 3399 | Each evaluation allocates a **new** string: the source buffer can be cleared and refilled without disturbing a text already made from it. | make a text from a buffer, `clear` and refill the buffer, make a second text, assert the first is unchanged | yes — both strings are known at generation time; this is a clean exit-95 assertion | **none** — no leaf clears or refills a buffer after making a text from it, and `clear` on a *user* buffer appears in no leaf at all (`gen_core.vox:987`'s `clear gen_out` is the generator's own accumulator, never part of a generated program — the same finding buffers.md records as BUF-33) | todo — real gap | |
| FMT-30 | 3402–3403 | *(parenthetical)* Before v0.1.17 a format string outside `Print` compiled to a NULL pointer that printed empty and corrupted `execve` argv arrays. | — | **no** — a claim about a version of the compiler that no longer exists; not testable against the pinned binary. Its live content ("today it does not") is FMT-23/FMT-25 | n/a | withdrawn (historical note, manual 0.4.8) | |
| FMT-31 | 3407 | The umbrella claim: **every** statement taking a string value accepts a format string. | one sink the manual does not name, so "every" is tested rather than the five listed | yes | the named sinks are FMT-32–FMT-36; the unnamed sink probed here (`Open a file … at "{…}"`) is emitted by `gen leaf format value` (`open line` uses a fixed `/dev/stdout`, **not** a format string) | todo for an unnamed sink; the named ones are covered per-row below | |
| FMT-32 | 3408 | The `write` sink accepts a format string. | `write "{…}" to <handle>` | yes — read the file back and assert the bytes | `gen leaf format value` (`write line`), `gen leaf file write`, `gen leaf file round trip` | exercised | |
| FMT-33 | 3408 | The buffer sinks `set`, `copy` and `append` accept format strings. | all three verbs on a buffer | yes — assert the buffer's contents after each | `gen leaf format value`: `buffer fill` (copy), `scratch set` (set), `scratch append` (append), `built decl` (the `is` initializer form). All four verbs present — the same finding buffers.md records as BUF-34 | exercised | |
| FMT-34 | 3408–3409 | Filesystem paths accept format strings (`Create a directory called "{base}/{name}"`). | the manual's own shape | yes — the generator chose the path, so it can stat it back or simply re-create it; hand-verified idempotent | **none** — `Create a directory` appears only in `src/harness.vox`, the generator's own mkdir-p, never in a generated program | todo — real gap | |
| FMT-35 | 3409 | `treating` clauses accept format strings. | `treating <match> as "{…}"` | yes — the substituted value is known | **none** — `gen leaf treating print` and `gen leaf treating grid` both use plain literals for match and replacement; no `{` ever reaches a treating clause | todo — real gap | |
| FMT-36 | 3409 | Function arguments accept format strings. | `f4 of "{…}"` | yes — `f4` prints its parameter, so the expected line is known | `gen leaf format value` (`call line`, and `f4` was added to the prelude for exactly this, `gen_core.vox:859`) | exercised | |
| FMT-37 | 3410–3411 | All sinks share one name resolver, so special names (`{arguments's first}`, `{current time's hour}`) render identically whether printed, written to a file, or built into a buffer. | the same special-name slot in all three sinks, compared against each other | yes — cross-sink equality is assertable without knowing the value, which is what makes the clock case checkable at all | partial: `gen leaf format expression` puts `arguments's count` in a **Print** slot only; `gen leaf format types` puts `hq{n}'s hour` in a text and a buffer. No leaf compares two sinks, and no leaf puts an argument **text** property in any sink | **todo — the claim now holds for the text properties.** It was FALSE as written until vox #52 (0.4.8+), when `{arguments's first/last}` into a buffer sink stopped segfaulting and started copying the text; **Discrepancy 1 is resolved** (`D1.vox`). It is still false for `{arguments's all}`, which is a *list* and renders a raw pointer in every non-`Print` sink — that is **Discrepancy 2**, which is still open. The row stays `todo` because no leaf puts an argument text property in any sink | |
| FMT-38 | 3411–3412 | Format specifiers render identically in every sink. | one specifier-bearing slot printed, buffered, and written, compared | yes — cross-sink equality again | `gen leaf format value` puts `gen pick integer spec` output into the text, buffer, list, map, `value` and file sinks; its own comment names this claim as what it is on trial for. **No cross-sink comparison is asserted** — each sink is printed for a human to eyeball | exercised (verification missing: nothing compares the sinks) | |
| FMT-39 | 3420–3422 | The `0x`/`0o` prefixes specifically survive every sink — the prefix is part of the rendering, not something `Print` adds. | the x/X/o specifiers across sinks | yes | same leaf; `gen pick integer spec` draws `x`, `X`, `o` with probability 3/8 per slot | exercised (same missing verification as FMT-38) | |
| FMT-40 | 3414–3415 | A **variable** declared in every branch of an `if`/`otherwise` chain definitely exists afterwards and can be used after the branch. | declare the same name in both arms, use it after | yes — both arms' values are known, and which arm runs is known | **none** — no leaf declares anything inside a branch. `gen leaf assign`'s comment (`gen_core.vox:336`) records the generator deliberately steering *around* this family ("a name declared on a single conditional path is out of scope afterwards, bug #25's family"), which is the SOME-branch case (FMT-43) — the EVERY-branch case that makes it legal was never taken up | todo — real gap | |
| FMT-41 | 3414–3415 | The same holds for a **file handle**. | open the same handle name in both arms, write to it after | yes — the written bytes are known | **none** | todo — real gap | |
| FMT-42 | 3416 | Such a name is usable **from inside functions**, "exactly like a top-level declaration". | a function reading the branch-declared name | yes | **none** | todo — held through 0.4.9 with a caveat: it was exactly like a top-level declaration *including* a forward-reference defect a top-level text global had. **Discrepancy 3 RESOLVED, 2026-08-22 (vox #66)** — the caveat is gone; hand-verified against 0.4.10 | |
| FMT-43 | 3417–3418 | A name declared in only SOME branches stays scoped to its condition; cross-condition use is a **compile error**. | — | **no** — same reason as FMT-18: a leaf may not emit an illegal program. Harness-assertable, not leaf-assertable | n/a | not assertable (by a leaf) — probe retained; the diagnostic even names the rule and suggests the fix | |
| FMT-44 | 3420–3429 | The worked example (a file handle opened in both arms of a flag test, written to afterwards) compiles and behaves as shown. | the example verbatim | yes | **none** | todo (composite of FMT-40/FMT-41) — hand-verified to work once the flag declaration the fragment omits is supplied; see FMT-41's probe | |
| FMT-45 | 3436 | `{{` renders one literal `{`. | a doubled opening brace in a printed literal | yes | `gen leaf format types` (`print escapes`) emits `braces {{lit}}` next to a live slot | exercised | |
| FMT-46 | 3437 | `}}` renders one literal `}`. | a doubled closing brace | yes | same line | exercised (covered by FMT-45's probe) | |
| FMT-47 | 3438 | `\n` renders a newline. | a `\n` in a printed literal | yes | `gen leaf format value` (`write line`), `gen leaf file write`, `gen leaf file round trip` — all in **write** payloads. Never in a `Print` | exercised (write sink only) | |
| FMT-48 | 3439 | `\t` renders a tab. | a `\t` in a printed literal | yes | `gen leaf format types` (`print escapes`, `tab\there`) | exercised (covered by FMT-47's probe) | |
| FMT-49 | 3440 | `\\` renders one literal backslash. | a doubled backslash in a literal | yes | **none** — `grep` for an emitted `\\` across all eight `src/gen_*.vox` files finds nothing. The escape table's only uncovered row | todo — real gap, hand-verified to work (covered by FMT-47's probe) | |
| FMT-50 | 3443–3447 | The escape example compiles and prints as shown. | the three statements verbatim | yes | `print escapes` covers `{{`/`}}`/`\t` in one line; `\n` in a **Print** is never emitted, `\\` never at all | todo (composite of FMT-45/46/47/48) | |
| FMT-51 | 3452 | `Print <default>, but if <condition> print <value>.` — the alternative **replaces** the default, it is not printed in addition to it. | a one-clause conditional print | yes — the generator picks the condition and both values, so it knows which line comes out | `gen leaf butif print` (1–3 clauses drawn from `gen condition`/`gen expr`) | exercised | |
| FMT-52 | 3457 | Clauses chain, and — the shape the manual's own line shows — **without a comma between them after the first**. | a chain whose second and later clauses have no leading comma | yes | `gen leaf butif print` chains 1–3 clauses but puts `", but if"` before **every** clause, so the comma-less continuation the manual actually documents is never emitted. Reserved-word note for whoever writes it: the manual's example names the loop variable `number`, which the compiler refuses as a keyword | exercised (comma'd form) — todo for the comma-less form | |
| FMT-53 | 3461 | First matching condition wins, and only that clause runs. | a chain where two clauses both match, in both orders | yes — the generator chooses the operand and both conditions, so it knows which fires; the two-orders form is what proves it is position and not specificity | `gen leaf butif print` emits the construct, but its conditions come from `gen condition` and nothing asserts which fired | exercised (verification missing) | |
| FMT-54 | 3462 | A chain may be chained with `but if` **or `and if`**. | a chain mixing both spellings | yes | **none** — `and if` appears **zero times** in emitted text across all eight `src/gen_*.vox` files | todo — real gap, and the claim is imprecise: `and if` is a valid **continuation** but not a valid **opener**. See **Discrepancy 4** | |
| FMT-55 | 3463 | The default value prints when no condition matches. | a chain whose conditions all fail | yes — trivially, the generator chose the operand | `gen leaf butif print` reaches this probabilistically; nothing asserts it | exercised (verification missing) | |

## Discrepancies

Recorded, not adjudicated. Repros in `docs/ledger/probes/input-output/`.

### 1. `{arguments's first}` built into a buffer segfaults — a memory-safety violation, in the one place the manual promises the sinks are the same

`D1.vox`. LANGUAGE.md:3418–3422: "All sinks share one name resolver, so
special names like `{arguments's first}` and `{current time's hour}` …
render identically whether the result is printed, written to a file, or
built into a buffer."

```
a buffer called built is 64 bytes in size.
copy "{arguments's first}" to built.
Print built.
```
→ `Segmentation fault (core dumped)`, exit 139.

Hand-narrowed:

| slot | `Print` | `write` to a file | into a buffer (`set`/`copy`/`append`) |
|---|---|---|---|
| `{arguments's count}` | `3` | `3` | `3` |
| `{current time's hour}` | `22` | `22` | `22` |
| an ordinary `a text called who is "world"` | `world` | `world` | `world` |
| `{arguments's first}` | `hello` | `hello` | **segfault** → `hello` after #52 |
| `{arguments's last}` | `there` | `there` | **segfault** → `there` after #52 |
| `{arguments's all}` | *(a pointer — see D2)* | *(a pointer)* | **segfault** → *(a pointer — see D2)* after #52 |

All three buffer verbs crash; the split is by the property's **type**
(the text-valued argument properties), not by the sink. It crashes with
or without arguments passed, so an empty argv is not the trigger.

The strongest pro-compiler reading I can construct: the argument text
properties return a pointer into the process's original `argv` block
rather than into the runtime's own string arena, and the buffer sink —
unlike `Print` and `write`, which consume a `char*` and are done — copies
through a path that expects an arena string with a length header in front
of it, and reads that header from unmapped memory before the argv strings.
On that reading the resolver really is shared and it is the *buffer
copy-in* that is unsound, which would make this one bug in one function
rather than a resolver split. It does not make the compiler correct: this
is a program of legal Vox, per the manual's own example vocabulary,
segfaulting. Per `CLAUDE.md` that is a top-severity finding — a broken
promise about the language's headline property.

Why no campaign has caught it: `gen leaf format expression` is the only
leaf that puts an argument property in a slot, it uses `arguments's count`
(the safe, numeric one), and only in a `Print`. The crashing combination
is unreachable by today's generator. **Not filed.**

**Resolution: fixed by vox #52 (0.4.8+).** Re-run against current main,
`D1.vox` no longer crashes: `copy`, `set` and `append` of
`"{arguments's first}"` into a buffer all produce the argument text, and
`Print` of the buffer prints what `Print` and `write` print — which is what
LANGUAGE.md:3418–3422 promised. The probe was rewritten on 2026-08-21 to
record that; it now exercises all three buffer verbs and exits 0.

One thing the fix does **not** cover, already on the record:

- `{arguments's last}` is fine, but note for anyone writing a probe around
  it: with no arguments it resolves to `argv[0]`, so its output depends on
  where the binary was built. `D1.vox` uses `first` for that reason.

(`{arguments's all}` into a buffer no longer crashes and no longer
renders a raw pointer either — see Discrepancy 2 below, now resolved.)

### 2. A list in a format string used as a value renders its raw pointer — RESOLVED (vox #44)

`D2.vox`. LANGUAGE.md:3384 says a format string used as a value
"materializes into a fresh NUL-terminated string"; 3158–3161 says one
shared name resolver renders every sink identically.

```
a list called ordinary is [1, 2, 3].
a text called held is "{ordinary}".
Print ordinary.        ->  [1, 2, 3]
Print "{ordinary}".    ->  [1, 2, 3]        (print slot: correct)
Print held.            ->  140444409614336  (value context: a pointer, on 0.4.8)
```

Every value context was affected identically — initializer, assignment,
and comparison operand. Second facet, same shape: `Print "{arguments's
all}".` used to render a pointer in the **Print** sink too, where an
ordinary list in a print slot was correct (`Print arguments's all.`
renders `[]`). The buffer sink could not be probed for either facet on
0.4.8 — it segfaulted on the argument properties (D1, itself fixed by
#52) — so the pointer used to surface in whichever sink the
list-rendering path was not wired into.

Pro-compiler reading (as it stood on 0.4.8): `Print` of a collection has
a dedicated renderer that walks the elements, and the format-slot
resolver hands the sink a machine word; where the sink is `Print` and
the name is an ordinary list, the two happen to meet and the walker
runs. Everywhere else the word is formatted as a number. On that reading
the manual was promising a uniformity across sinks the implementation
did not have for collection-typed names.

**Resolution confirmed, 2026-08-22: fixed by vox #44.** Re-run `D2.vox`
against vox 0.4.9: `'the held list' is equal to "[1, 2, 3]"` now holds —
the value-context sink renders the list correctly, matching `Print` and
the print-slot form. Re-tested the second facet directly too:
`Print "{arguments's all}".` now prints `[]`, matching `Print
arguments's all.` exactly, where it used to leak a pointer. Both facets
of this discrepancy are closed by the same fix that closed collections-a
and collections-b's own D7 (the *variable*-form sub-case). The narrower
*expression*-form sub-case those two ledgers found (`"{element 2 of
nested}"`) is untouched by #44 and remains open as vox candidate #68 —
not re-tested here since it is outside this section's own claims, but
worth knowing this section's `{...}` value-context sink shares the fix,
not just the gap.

### 3. A text global printed from inside a function defined earlier in the file renders its pointer — RESOLVED (vox #66)

`D3.vox`. Reached from this section through FMT-42, but the defect is not
this section's — it belonged to Functions / Variables (same underlying
bug as `functions.md`'s Discrepancy 1, independently rediscovered here).

```
To 'show label'.
  Print label.

a text called label is "one".
Print label.        ->  one
'show label'.       ->  4198488
```

Moving the function definition **below** the declaration fixes it. The
value itself is intact: inside the same function, `a text called copied is
label. Print copied.` prints `one`, and `If label is equal to "one"` is
true. Only the print/format path is wrong, and only for a text — a
number global is unaffected.

LANGUAGE.md:773 said top-level variables "can be used inside functions",
with no ordering caveat at the time. LANGUAGE.md:3416 leaned on that same
promise for branch-declared names ("exactly like a top-level
declaration"), and it was — defect included, which is why FMT-42 was
recorded as holding rather than failing.

Pro-compiler reading (at the time): the function body was analysed
before the declaration was reached, so at that point `label` had no
known type and the printer fell through to the number path. That was a
forward-reference ordering rule the manual never stated, not a wrong
answer for a well-formed program.

**Resolution confirmed, 2026-08-22 — RESOLVED by vox #66.** CHANGELOG.md
#66: "Codegen now reads every top-level declaration's type in a pre-pass
and gives it to each function body before generating it, so a global is
read as its declared type wherever the declaration sits." Re-ran the
repro verbatim against 0.4.10: `'show label'.` now prints `one`, matching
the top-level print — no ordering caveat needed after all; LANGUAGE.md:773
now states the fixed rule directly, including the one case that remains
genuinely special (a function that runs *before* the declaration is
reached reads the type's empty value, never a wrong-typed raw word). See
`functions.md` Discrepancy 1 for the fuller writeup — same fix, same
register entry.

### 4. `and if` cannot open a conditional-print chain, though the manual reads as though it can

`D4.vox`. LANGUAGE.md:3463: "Chain with `but if` or `and if`."

```
a number called score is 4.
Print the score, and if the score modulo 2 is equal to 0 print "two".
```
→ `error: Expected a statement, got Comma`

The same statement with `but if` first and `and if` second compiles and
runs, and both spellings then mean first-match-wins (FMT-54's probe). So
`and if` is a valid continuation, never an opener.

Pro-compiler reading, and I think it is the right one, because the manual
argues it elsewhere itself: the keyword chapter's Connectors table gives
`but` the purpose "Conditional chaining" (LANGUAGE.md:4943) and gives
`and` "Multiple uses (see below)" (LANGUAGE.md:4941), and the `and`
disambiguation table that follows (LANGUAGE.md:4952–4962) lists exactly
four contexts for it — logical operator, parameter separator, argument
separator, list terminator — none of which is opening a conditional
chain. So `but` is the chaining keyword and `and` is a separator that
needs something on its left; a leading `and if` has nothing to join to,
and the comma before it has no statement to close. On that reading the
sentence at 3211 is imprecise rather than the parser wrong: it should say
the chain **opens** with `but if` and **continues** with either. A
one-line manual fix. **Not filed.**

### 5. The bare-literal-in-a-slot diagnostic points at the first textual occurrence of the slot, comments included

`D5.vox`. FMT-18's compile error is anchored by searching the source for
the slot text, so a comment that merely *mentions* the slot steals the
caret from the code that caused it:

```
(this comment mentions {255:x} and is where the caret lands)
Print "{255:x}".
```
```
error: Unknown variable: 255
  --> D5.vox:1:12
  1 | (this comment mentions {255:x} and is where the caret lands)
    |            ^--- here
```

Comments are otherwise inert — the same comment **without** line 2
compiles clean, so the comment is not being compiled, only pointed at.

Pro-compiler reading: the diagnostic carries the slot's identity rather
than its position and the renderer recovers a position by searching the
source; on any file where the slot appears once — which is every file the
compiler's own tests would have — the recovered position is right. The
verdict is correct, the program really is invalid and really is refused;
this is a source-span recovery weakness in the error renderer.

Cosmetic, and last on this list for that reason. Recorded because it will
mislead whoever debugs a generated program: PROCEDURE.md §6 requires each
leaf's doc comment to name its ledger IDs, and this ledger's own probes
carry claim text in their comments — exactly the files where a slot is
likely to appear in prose before it appears in code. It cost me one
false-alarm investigation while writing FMT-18. **Not filed.**

## Invariants this section justifies

Samenesses the corpus will show that the manual actually requires:

- every `{n:x}` / `{n:X}` rendering begins `0x`, with a lowercase `x` in the prefix regardless of the specifier's case — LANGUAGE.md:3317–3318, FMT-13, FMT-14
- every `{n:o}` rendering begins `0o` — LANGUAGE.md:3320, FMT-16
- no `{n:b}` rendering carries a base prefix — LANGUAGE.md:3319, FMT-15
- a padded-hex rendering is always the prefix plus exactly N digits, never N characters in total — LANGUAGE.md:3321, FMT-17
- a bare width pads on the left with spaces, never on the right — LANGUAGE.md:3315, FMT-11
- `{{` and `}}` always collapse to exactly one brace — LANGUAGE.md:3436–3437, FMT-45, FMT-46
- no format slot ever contains a bare numeric literal — LANGUAGE.md:3323–3326, FMT-18
- every conditional-print chain opens with `but if`, never with `and if` — LANGUAGE.md:3463 as the parser reads it, FMT-54, D4
- no conditional-print chain carries an `otherwise` clause — the Conditional Print rules (LANGUAGE.md:3463) list no `otherwise` arm and the compiler refuses one; the loop-expansion `but if` at LANGUAGE.md:3236/3043 does have one and is a different statement. `gen_flow.vox:111–120` already documents this distinction, and `gen leaf butif append` correctly emits `otherwise` where `gen leaf butif print` correctly does not
- a conditional-print statement emits exactly one line — LANGUAGE.md:3463, FMT-51, FMT-53, FMT-55

Samenesses this section's leaves contribute that **nothing justifies** —
each one an undeclared rule, and each one a row above:

- no generated program contains the article `the` before a plain variable reference; the only emitted articles precede a possessive (`the tk{n}'s elapsed`) or open a method header — FMT-02
- every `Print` in every generated program ends a line; `without newline` is never emitted — FMT-04, FMT-05
- no generated program emits a literal-backslash escape — FMT-49
- no generated program emits `and if` — FMT-54
- every `but if` clause in a print chain is preceded by a comma — FMT-52
- no generated program declares a variable or a file handle inside a branch — FMT-40, FMT-41, FMT-42
- no generated program puts a format string in a filesystem path or in a `treating` clause — FMT-34, FMT-35
- no generated program reassigns a text from a format string, only initializes one — FMT-24
- no generated program calls `Execute` — FMT-25
- `\n` appears only in `write` payloads, never in a `Print` — FMT-47

## Report

**55 rows** (FMT-01 through FMT-55). FMT-30 is withdrawn (a parenthetical
about a compiler version that no longer exists), leaving **54 live
claims**. Of those, **51 are assertable** — the generator picks the value,
the specifier and the sink, so it can predict the exact string. Three are
not:

- FMT-18 and FMT-43 are compile-error claims. A leaf may not emit them:
  `CLAUDE.md`'s standing invariant is that a generated program is legal
  Vox that should compile and run, so a deliberate refusal would be
  classified as a generator defect rather than a finding. **They are
  assertable by the harness** — a negative-compile fixture directory —
  and that is worth building once, because this manual makes compile-error
  claims in many sections and today nothing tests any of them.
- FMT-23 (NUL-termination) is not observable from inside Vox at all; its
  one observable consequence is FMT-25.

**Existing coverage: 33 exercised, 18 todo, 3 not assertable, 1
withdrawn — and 0 verified**, since no leaf in this section asserts a
documented result in the exit-95 form PROCEDURE.md §6 defines.
That is a far better starting position than buffers (6 of 39), and the
reason is `src/gen_text.vox`: four dedicated leaves already emit **every
row of the specifier table** and four of the six sinks "Format Strings
Everywhere" names. Anyone assigned this section should read
`gen leaf format value`'s doc comment before writing anything — it names
this manual section by line number and enumerates the sinks it set out to
cover.

**The biggest finding is Discrepancy 1: a segfault.** `{arguments's
first}` built into a buffer kills the process, and the manual sentence it
falsifies is the one promising that exact substitution is safe. It is
unreachable by today's generator by one accident — the only leaf that puts
an argument property in a slot uses the numeric one, in the only sink that
survives. One leaf that crosses argument properties with buffer sinks
would have found it, and FMT-37 is that leaf. *(Fixed in vox by #52,
0.4.8+ — see the `Resolution:` line on Discrepancy 1. The account here is
the finding as it stood when this ledger was written; the reason it went
unfound for so long is still the lesson.)*

**Where the gaps cluster.** Not in format strings, which are well covered,
but in the section's less glamorous halves:

1. **`Print` itself.** `without newline` appears zero times in the whole
   generator, and the article `the` never reaches a `Print` operand — it
   is emitted only before a possessive, by `gen leaf timer and clock`.
   Two constructs the manual documents in its first fourteen lines, both
   trivially emittable.
2. **Declarations in Branches** — nothing at all, and `gen leaf assign`'s
   own comment shows the generator was taught to steer *around* this
   family after bug #25 without ever taking up the legal every-branch
   form that the same subsection documents.
3. **Two sinks** — filesystem paths and `treating` clauses — plus
   `Execute`, which no leaf calls at all.
4. **`and if`**, and the comma-less clause continuation the manual's own
   example shows.
5. **Verification rather than exercise** for FMT-38/39 and FMT-53/55: the
   constructs are emitted, the sinks are printed side by side for a human
   to eyeball, and nothing asserts that they agree. Cross-sink equality is
   the cheapest assertion in this section, because it does not require
   knowing the value — which is what makes even the clock case checkable.

**For the next mapper.**

- **Re-pin `INDEX.md` before you start.** Its ranges are 0.4.7; the manual
  is 0.4.8 and everything below the collections chapter has shifted +77
  lines. Walk from the section's own `##` heading to the next one rather
  than trusting the brief's numbers — that is what caught it here, and the
  brief's range would otherwise have silently dropped four subsections.
- **Correct the buffer ledger's parting advice**: assertions are *not*
  universally absent. `gen leaf format types`, `gen leaf timer and clock`
  and `gen leaf predicate probe` all assert already, in a
  print-a-BAD-line form. Check before you assume.
- **Cross-sink equality is the assertion that costs nothing.** Where a
  value is unpredictable (a clock, a pid, an address), you can still
  assert that two renderings of it agree, or that its width is fixed.
  Both tricks are already in this generator and both are underused.
- **A discrepancy whose output is an address is still recordable** — write
  the probe as a comparison against the expected string and record the
  verdict line, not the address. D2 and D3 are built that way and re-run
  clean; the raw values are in this document's prose where they belong.
- **Watch for reserved words in the manual's own examples.** `number` is a
  keyword and the Conditional Print example uses it as a variable name; a
  worker copying that example verbatim gets a compile error that looks
  like a language bug. `vox-preflight` exists for this.

**One thing for the master, outside this section.** Re-running
`docs/check-probes.sh docs/ledger/probes/buffers` against the current
binary reports **34 passed, 2 failed** — `BUF-14.vox` and `D2.vox`, both
on the same line, both expecting `Text (dynamic)` and now getting
`Buffer (static)`. That is buffers.md's **Discrepancy 2 fixed in the
compiler** since that ledger was mapped (it was mapped against 0.4.7; the
manual is now 0.4.8). Nothing of mine touches buffers — I checked before
reporting it — so it is a real drift, and it is exactly what
`check-probes.sh` exists to notice. BUF-14's row, its probe, and D2's
entry all need updating, and D2 needs a `Resolution:` line. Worth doing
before the next buffer leaf batch is scoped, since BUF-14 is currently
recorded as `todo` on the strength of a bug that no longer exists.
