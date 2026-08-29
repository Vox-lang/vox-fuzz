# Claim ledger: Functions

Source: `../vox/LANGUAGE.md` lines **671–813**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), confirmed 2026-08-22 — the whole
`## Functions` chapter — Definition, Function Scope, Parameter and Local
Types, Function Calls, Calling as Statement, Reading a Result. Row prefix
**`FUN`**.

**Correction, 2026-08-22: the previously-stated end boundary (786) was
wrong, not just drifted.** `## Functions` opens at 671 as this ledger
always said, but `## Things` opens at **814**, not immediately after
786 — re-checked directly (`grep -n "^## Functions\|^## Things"`). The
gap, lines 787–813, is the back half of the "Reading a result"
subsection (the declared-vs-undeclared-return-type propagation rules,
including the exact passage FUN-41 already tests). That content was
never outside this ledger's *conceptual* scope — several rows already
address it — but the header's own boundary number was simply incorrect
before this pass, independent of any 0.4.8→0.4.9 drift. Several rows in
this ledger (FUN-40 through FUN-43) carry `*(gap)*` line-citation
placeholders rather than a precise number; those remain unresolved by
this pass and are a real follow-up, not a drift artifact — re-deriving
them precisely against 671–813 is the next mapper's first job here.

**Discrepancies 7 and 8 (RESOLVED, vox #53) and row FUN-41 (RESOLVED,
vox #45) were the previous pass's headline finding** — all three
re-verified directly against 0.4.9:
- **D7/D8**: `Return a buffer, "<text literal>"` used to silently yield
  an empty buffer (one string-initialised buffer in the program) or
  **segfault** (two or more) — a top-severity memory-safety fault on a
  program that compiled clean. Both are now a clean compile-time
  refusal naming the exact working rewrite, regardless of buffer count.
- **FUN-41**: an undeclared-return-type function's result, used in
  expression position, used to print an untyped machine word. Now a
  compile error, matching the same #45 fix already confirmed from the
  collections-a ledger.

**Discrepancies 1, 2 and 5 are now ALSO RESOLVED, 2026-08-22 (0.4.10) —
this pass's headline finding.** All three were the "still open, tracked
as an in-flight candidate" rows the previous pass left; all three
candidate branches landed in the 0.4.10 release, re-verified directly
against 0.4.10, not just re-read:
- **D1** (a global declared *below* a forward-referencing function read
  as a raw machine word for every type but `number`) — **RESOLVED, vox
  #66**. The five-global `D1.vox` repro now prints identically whether
  read from above or below the function. This was the brief's headline
  "still open" row, and the biggest single finding of the previous pass
  ("a whole class of silent wrong answers... one line away from being
  live in the generator") — closed without ever reaching a campaign.
- **D2** (a `map` parameter's `'s size`/`'s length` compiled into the
  file-size routine — failed to assemble, or silently printed `-1`) —
  **RESOLVED, vox #76**. `D2.vox`/`D2b.vox` now print the correct entry
  count through the parameter, matching the top-level read.
- **D5** (a declared `float`/`map` return printed *directly* rendered
  its raw bit pattern / a heap address) — **RESOLVED, vox #67**.
  `D5.vox` now prints the same value whether routed through a variable
  or printed directly; FUN-40 (below) is unblocked by the same fix.

Candidates #66 and #67 were tracked in `vox-notes/REPORT-CANDIDATES-
0.4.10.md` (candidates A and B) as `fix/bug-66-forward-global-read` and
`fix/bug-67-declared-return-printed` respectively, both in flight at the
time of the previous pass; #76 (D2) was not one of the two candidates
this ledger had already flagged, but the same register entry closes it.
Probes updated to record the fixed (0.4.10) output where they previously
recorded the bug (D1/D1b/D5 remain exit-code-only checks, since their
own headers already noted the addresses vary per run — a probe-format
choice unrelated to which behaviour they record).

This is a **gap analysis**, not a from-scratch map. `existing leaf` names
the leaf that already emits the construct — checked by `grep` on the
emitted text (`"To `, `Return a `, `called p`, the call-line strings),
never by leaf name — or `none`. `status` follows PROCEDURE.md §3.

**No leaf anywhere in the generator asserts anything about a function** —
the same uniform gap the buffers and values ledgers found. The generator
does emit functions: four in the shared prelude (`f1`–`f4`), one grid
sink, one flag reader, and two thing methods. Every one of them either
`Print`s for a human to eyeball or returns a number nobody checks. The
only assertions in the whole generator are the four argv checks
(`src/gen_misc.vox:316-321`, exits 91–94) and they run at top level, not
through a call. So nothing here is marked `verified`. The `verified by`
column is therefore empty except where PROCEDURE.md §5 puts something
else in it: a row that depends on an open discrepancy carries
`blocked on D<n>`.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` pinned
to the sibling `coreasm`) before being written. **Nine discrepancies**
came out of it, one of them a deterministic segfault on a six-line
program that compiles clean.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/functions/`, one file per row named `FUN-NN.vox`. A
probe covering more than one row is named for the first and says so in
its header (`FUN-01` also covers FUN-03/08/09; `FUN-02` also covers
FUN-05/37; `FUN-06` also covers FUN-32/35; `FUN-07` also covers
FUN-08/36; `FUN-14` also covers FUN-15/16; `FUN-19` also covers FUN-20).
Each file opens with a `(...)` comment naming the claim, the `Ran:`
command, and an `expected output:` block recording what the compiler
actually printed. Two discrepancies have a second repro because they have
two distinct symptoms: `D1b.vox` reaches Discrepancy 1 through the
generator's own prelude shape rather than a hand-written example, and
`D2b.vox` is Discrepancy 2's assembly-failure half.

Rows with no probe file of their own: FUN-03, FUN-08, FUN-09, FUN-15,
FUN-16, FUN-20, FUN-32, FUN-36, FUN-37 (each covered by a sibling's probe,
named above), FUN-31 (a claim about compiler versions before v0.1.16 —
nothing to run today), and FUN-34/FUN-35 (restatements folded into
FUN-05/FUN-32). That is **31 `FUN-NN.vox` probe files**, plus **11
discrepancy repros** — `D1`, `D1b`, `D2`, `D2b`, `D3`, `D4`, `D5`, `D6`,
`D7`, `D8`, `D9` — for **42 files** in the directory, and
`fixtures/data.txt`, a twelve-byte file the file-parameter probes read.

`docs/check-probes.sh docs/ledger/probes/functions` re-runs the whole
directory: **42 passed, 0 failed, 0 skipped**, in one final pass after
every probe was written. Probes that read a file use the repo-root-relative
path `docs/ledger/probes/functions/fixtures/data.txt`, because
`check-probes.sh` runs the compiled binary from the repo root.

Four probes are compared on their **exit code** rather than their stdout,
because they print an address that changes from run to run: `D1`, `D1b`
and `D5` end in a deliberate `Exit 3.`, and `D8` records `exit 139` — the
segfault.

## The table

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FUN-01 | 736–738 | The definition template: `To <name> with a <type> called <p1> and a <type> called <p2>. Return a <type>, <expression>.` — signature, parameters and return all in one sentence. | emit a whole function on one line and call it | yes — the generator picks both operands, so `If 'add numbers' of 3 and 5 is not 8 then, Exit 95.` | `gen emit prelude functions` (`src/gen_core.vox:848,850`) emits f2/f3 as one-line signatures but puts the body and `Return` on following lines; the single-sentence form is never emitted | todo | |
| FUN-02 | 740–748 | No-parameter functions are valid, in both name forms (`To 'show version'.`, `To ping.`), body on the following indented lines. | emit a no-parameter function and call it | yes — assert what the body printed | `gen emit prelude functions` (f1, `src/gen_core.vox:845`), `gen emit prelude flag reader` (`'read flags {n}'`, `src/gen_misc.vox:387`) | exercised | |
| FUN-03 | 752 | Worked example: `To 'add numbers' with a number called x and a number called y. Return a number, the x add y.` compiles and adds. | reproduce the example | yes — `Exit 95` on a wrong sum | none emits the `the x add y` form; f3 (`src/gen_core.vox:850`) is the same shape with a body-local and a plain `p1 add p2` | todo | |
| FUN-04 | 754 | Worked example: `To 'check divisibility' of a number called divisor and a number called dividend. Return a boolean, the divisor modulo the dividend is 0.` — parameters via `of`, `Return a boolean,` on a comparison. | emit an `of`-introduced parameter list and a boolean return | yes — generator picks both numbers, knows the remainder | none — every emitted definition uses `with` (see Invariants), and no emitted function returns a boolean | todo | |
| FUN-05 | 758 | **Claim widened, 2026-08-29 (0.4.15, #110) — was "bare single word or single-quoted multi-word name", now explicitly allows a single-quoted single word too.** A function name is a bare word, or any name in single quotes (a single word may be quoted too): `add`, `'add numbers'`. | emit all three name forms: bare, single-quoted multi-word, single-quoted single-word | yes — assert what each prints | bare: f1–f4 (`src/gen_core.vox:845-859`); quoted multi-word: `'grid sink N'` (`src/gen_flow.vox:522`), `'read flags {n}'` (`src/gen_misc.vox:387`); **quoted single-word: none** | exercised (bare, quoted multi-word); todo (quoted single-word — the #110 fix itself, new row added 2026-08-29, below) | |
| FUN-06 | 759 | Parameters are optional, and `with` and `of` introduce them identically. | emit the same parameter list both ways and call both | yes — both must return the same value | `with` only — f2/f3/f4 (`src/gen_core.vox:848-859`), `'grid sink N'` (`src/gen_flow.vox:522`), the thing methods (`src/gen_things.vox:124,129`). **`of` is never emitted in a definition.** | todo (the `of` form) — real gap, hand-verified to work | |
| FUN-07 | 760 | **Claim widened, 2026-08-29 (0.4.15, #110) — was "bare if single-word, single-quoted if it contains spaces", now explicitly allows a single-quoted single word too.** Parameters use `a <type> called <name>` syntax: a bare word, or any name in single quotes (a single word may be quoted too). | emit a parameter whose name contains a space, and separately a single-quoted single-word parameter name | yes — pass a known value, assert it comes back | every emitted parameter name is a bare single word (`p1`, `p2`, `x1`, `original`) — **no emitted parameter name is single-quoted, multi- or single-word** | todo (both quoted forms) — real gap, hand-verified to work; the single-word case is also the #110 fix, new row added 2026-08-29, below | |
| FUN-08 | 761 | Multiple parameters are joined with `and`. | emit two or more parameters | yes | f3 (two, `src/gen_core.vox:850`), `'grid sink N'` (3–17, `src/gen_flow.vox:515-522`) | exercised | |
| FUN-09 | 762 | A declared return type follows `Return a <type>,`. | emit a function with a declared return type and use the result | yes | f1/f2/f3 (`Return a number`, `src/gen_core.vox:845-850`), thing methods (`Return a t4`, `src/gen_things.vox:127,132`) | exercised (`number` and the thing type only — see FUN-23) | |
| FUN-10 | 762 *(gap)* | *(not a manual claim — a gap in the manual)* `Return a <type>, <expr>.` is also a **statement inside the body**, not only a clause on the `To` line, and an early return from inside an `If` leaves the function at once. The manual says only that "return type follows `Return a <type>,`" and never says where the sentence may stand. | emit a body-position `Return`, and an early return under an `If` | yes — assert the value each branch returns | `gen emit prelude functions` f2/f3 (body-position `Return`); early return is emitted only in the generator's own source, never into a generated program | exercised (body position); todo (early return under an `If`) | |
| FUN-11 | 780–786 | **Claim extended, 2026-08-22 (0.4.10, #66) — Discrepancy 1 RESOLVED.** Variables declared at top level are global and can be read inside a function — **including inside a function written above the declaration**, because the body runs when it is called and reads the global as its declared type either way; a function that runs *before* the declaration is reached (impossible for a normal call — this covers only the pathological same-name-shadowing edge) reads the type's empty value, never a wrong-typed raw word. The new sentence exists because #66 fixed exactly the bug this row was `blocked on D1` for: pre-0.4.10, a global declared **below** a forward-referencing function was read inside it as a raw machine word for every type but `number` (a rodata address for `text`, IEEE-754 bits for `float`, a heap address for `list`/`buffer`). Top-level code itself still has no such licence — reading a global above its own top-level declaration is a *separate*, still-enforced compile error (see [Declaration Order](#declaration-order), #79). | emit a function that reads a global of each type, from both sides of the definition, and asserts it | yes — the generator declared the global, so it knows the value | `'read flags {n}'` (`src/gen_misc.vox:388-392`) reads three flag globals, one of them a **text**, inside a function body — the only leaf that reads any global from inside a function, and it reads the text one through a declared local rather than directly | exercised (partially — flags only, never asserted, and only via a declared local); todo for a direct read and for an assertion. **Re-verified against 0.4.10** (`FUN-11.vox`): a global declared *below* a forward-referencing function now reads correctly for all five types tested (`number`, `text`, `float`, `list`, `buffer`) — the "which is where it breaks" half of the old claim no longer breaks | |
| FUN-12 | 787 | Variables declared inside a function are local to it and are not available at top level. | — | **no** — the claim is that a program is REJECTED; emitting it produces a non-compiling program, outside the generator's "legal Vox that should compile and run" contract | n/a (no leaf should ever emit this) | not assertable — hand-verified: the program is rejected, but the diagnostic is misplaced, **see Discrepancy 9** | |
| FUN-13 | 788 | Referencing an unknown variable inside a function is a compile-time error. | — | **no** — same reason as FUN-12 | n/a | not assertable — hand-verified: rejected, `Unknown variable: nowhere`, caret correct | |
| FUN-14 | 789–791 | Assigning to a top-level variable inside a function (`Set g to ...`) mutates the global itself, and the new value is visible after the call returns. | emit a function that bumps a global by a known amount, call it a known number of times, assert the global | yes — `If g is not 111 then, Exit 95.` | **none** — no emitted function body assigns to a top-level global. The thing methods (`src/gen_things.vox:126,131`) `Set` fields of a **local**, which is a different construct. | todo — real gap | |
| FUN-15 | 789–790 | The `the g is ...` spelling of that assignment does the same thing. | emit the `the g is ...` spelling inside a function | yes, same assertion as FUN-14 | none | todo | |
| FUN-16 | 791 | The mutation is visible to **every other function**, not only to the caller. | emit a second function that reads the global and asserts it | yes | none — the generated program never has two functions that touch the same global | todo | |
| FUN-17 | 792–794 | Declaring a variable inside a function **shadows** a top-level variable of the same name; the global is left untouched. | emit a function whose local reuses a global's name, assert the local inside and the global outside | yes — both values are the generator's own | **none** — every emitted local name is uniquely serialised (`fl{n}local`, `r`, `gtotal`, `c{n}`), so a shadowing collision is impossible by construction | todo — real gap, and the naming scheme is what makes it unreachable | |
| FUN-18 | 794–795 | Recursion still gets a fresh set of locals per call. | emit a self-recursive function with a local, assert the unwind order | yes — the generator picks the depth | **none** — no emitted function calls itself or any other function | todo — real gap | |
| FUN-19 | 795–798 | This applies to `value` too: payload and runtime type tag are stored as a pair, in whichever storage (function-local, or the global's own pair of locations) that `value` uses. | emit a `value` global retagged inside one function and a `value` local shadowing it in another | yes — assert the printed value after each step | none — `gen leaf value roundtrip` / `gen leaf text value` declare `value` **locals at top level** only (see `docs/ledger/values.md` VAL-02) | todo | |
| FUN-20 | 798–799 | A `value` mutation inside one function is never visible to another unless it is genuinely the same global. | second function reads the same `value` global and asserts the tag survived | yes | none | todo | |
| FUN-21 | 803–805 | All eleven expressible types are legal parameter types: `number`, `float`, `text`, `boolean`, `list`, `map`, `buffer`, `file`, `time`, `timer`, `value`. | emit a parameter of each type and pass a value of that type | yes — assert what the callee sees | `number` (f2/f3, grid sink) and `text` (f4) only; `t4`, a **thing** type, in the thing methods. **Nine of the eleven never appear in any emitted parameter list.** | exercised (2 of 11); todo (9 of 11) — the biggest single coverage gap in this section | |
| FUN-22 | ? | A typed parameter supports the same properties and operations as a top-level variable of that type. | read each type's properties off a parameter and off a top-level variable, assert they match | yes — assert equality of the two reads | **none** — no emitted function body reads a property off a parameter at all (`p1's ...` is never emitted); the thing methods read `original's x1`, a thing field, which is the Things section's construct | todo — was **false for three of the eleven types**; **Discrepancy 2 (`map`) RESOLVED by vox #76** (2026-08-22), so now **false for two**: see **Discrepancies 3 (`timer`), 4 (`file`)** | blocked on D3, D4 |
| FUN-23 | 806–808 | The same eleven types are legal as a declared `Return a <type>,` return type — parameters and returns share one vocabulary. | emit a function returning each type and receive it into a variable of that type | yes | `number` only (f1/f2/f3); `t4` in the thing methods. **Ten of the eleven never appear as a return type.** | exercised (1 of 11); todo (10 of 11) — hand-verified: all eleven are accepted, but `file` and `timer` cannot be received by the `a <type> called X is <call>.` declaration form (**Discrepancy 6**) and `Return a buffer, "<literal>"` is broken (**Discrepancies 7 and 8**) | blocked on D6, D7, D8 |
| FUN-24 | 808–812 | A parameter or return type may be `value`, the dynamic type whose runtime tag travels with its payload across the call. | emit a `value` parameter dispatched on `is a <type>`, and a `value` return, asserting the branch and the round trip | yes — the generator chose the argument, so it knows the branch | none — no emitted function takes or returns a `value` (`docs/ledger/values.md` VAL-02 says the same from the other side) | todo | |
| FUN-25 | 814–820 | The `'contains token'` example fragment compiles and behaves: parameters via `of`, a `buffer` and a `text` parameter, a buffer declared **inside** the body from a format string interpolating the text parameter, `hay's size`, `byte 1 of hay`. | reproduce the fragment | yes — the caller's buffer is the generator's own, so size and byte 1 are both known | none (composite; its parts are FUN-06, FUN-21, FUN-26, FUN-29) | todo — hand-verified to reproduce exactly (`FUN-25.vox`) | |
| FUN-26 | 824–825 | **Claim extended, 2026-08-22 (0.4.10, #90).** Buffer parameters support `'s size`, `'s empty`, `'s full` and byte access. New: a `buffer` parameter **is** the caller's buffer and stays the caller's buffer across a reallocating growth — an `append`, `resize`, or an out-of-capacity byte write that moves the block is followed by the caller's variable too (LANGUAGE.md:831–837, new prose). Before #90, growing a buffer past capacity through a parameter moved it and freed the old block, but the reallocated pointer stopped at the callee's frame, so the caller's next read used unmapped memory — a memory-safety bug, not just a wrong answer. | pass a known buffer, assert all four reads; separately, grow a `buffer` **parameter** past its capacity from inside a function and assert the caller's own variable reads the grown, moved buffer correctly | yes — `If payload's size is not 3 then, Exit 95.` | none — no buffer is ever passed to a function, and none is ever grown through a parameter | todo — hand-verified correct for the four static reads; the growth-through-parameter half hand-verified against 0.4.10 separately (grew a 8-byte buffer parameter past 200 bytes; caller's own variable read the moved block correctly, no fault) — not yet its own retained probe | |
| FUN-27 | 825–827 | **Claim extended, 2026-08-22 (0.4.10, #76).** List parameters support `'s length` and element access. New: **map parameters** now support `'s length`/`'s empty`/`'s keys`/`'s values` and keyed access, and print as a whole map. Before #76 a `map` parameter's `'s length`/`'s size` read dispatched into the **file**-size routine — a program with no `float` anywhere failed to *assemble* (`undefined symbol _file_size`, no Vox diagnostic at all), and one that happened to link the file runtime printed `-1` for a two-entry map — Discrepancy 2, now RESOLVED. | pass a known list, assert length and elements; pass a known map, assert `'s length` and a keyed read | yes | none — no list or map is ever passed to a function | todo — hand-verified correct (`length`, `size`, `empty`, `first`, `last` and `element N of` all read correctly through a list parameter). **Map half re-verified against 0.4.10** (`D2.vox`, re-run): `'read map' of ages` now prints `2` for a two-entry map, where 0.4.9 either failed to assemble or printed `-1` | |
| FUN-28 | 828 | File parameters support file properties. | pass an open handle, assert `size` and `readable` | yes — the generator wrote the file, so it knows the size | none — no file handle is ever passed to a function | todo — **`readable` and `writable` are still always false through a parameter as of 0.4.10** (not in the #66–#91 register — re-verified `D4.vox` unchanged): see **Discrepancy 4**. `size` and `descriptor` are correct. | blocked on D4 |
| FUN-29 | 837–838 | Buffers declared **inside** a function body work with every initializer form, including format strings. | emit a function body declaring a buffer three ways (byte count, string literal, format string) | yes — assert each buffer's size | none — no emitted function body declares a buffer at all; the only in-body declarations are `number` and `text` (`src/gen_core.vox:848`, `src/gen_misc.vox:388-389`, `src/gen_flow.vox:522`) | todo — hand-verified correct | |
| FUN-30 | 839–841 | A function call's declared return type is tracked through assignment: reassigning an **existing** variable from a call (`the label is classify of n.`) preserves the correct type. | reassign an existing variable of each type from a call, assert the value and a property | yes | none — every emitted call's result goes straight into `Print`, never into an existing variable | todo — hand-verified correct for `text` and `buffer`, in both the `the X is` and `Set X to` spellings; **fails for `file` in the declaration form**, see **Discrepancy 6** | blocked on D6 |
| FUN-31 | — | **Claim extended, 2026-08-22 (0.4.10).** Historical note: buffer-typed parameters, function-local buffer declarations with initializers, and reassignment-from-a-call were all rejected or corrupted before v0.1.16. New closing clause: "The buffer-parameter rule above is newer: see docs/BUGS_FOUND.md #90" — the manual now cross-references the 0.4.10 fix (see FUN-26) directly from this historical note, rather than leaving the buffer-parameter-write-back rule undated. | — | **no** — a claim about compiler versions that are not the one under test; there is no way to put a previous release on trial from inside a generated program | n/a | not assertable — **citation lost 2026-08-23**: not stated in 527cb89; the whole parenthetical was at 5611:798–803 and the spec diet removed it (the buffer-parameter rule it cross-referenced survives above it, see FUN-26) | |
| FUN-32 | 873 | In expressions, a call is the function name followed by `of`, `to`, `with`, or `on` and its arguments. | emit each of the four connectors | yes — every connector must produce the same result | **`of` only** — `Print f2 of c{n}` (`src/gen_core.vox:374`), `Print f3 of ... and ...` (`:387`), `f4 of "..."` (`src/gen_text.vox:408`), `'grid sink N' of ...` (`src/gen_flow.vox:105`), `f3 of each ... from ...` (`src/gen_flow.vox:55,218`). **`to`, `with` and `on` are never emitted.** | exercised (`of`); todo (the other three) — real gap, all four hand-verified identical | |
| FUN-33 | 876–878 | The three example call fragments parse and evaluate: `'add numbers' of 3 and 5`, `'check divisibility' of the number and 6`, `calculate with x and y`. | reproduce all three | yes | partially — the first shape is `f3 of c1 and c2`; the `the <name>` argument form and the `with` connector are not emitted | todo | |
| FUN-34 | 882 | **Claim widened, 2026-08-29 (0.4.15, #110) — same wording change as FUN-05.** (Call site) the function name is a bare word, or any name in single quotes (a single word may be quoted too). | — | — | — | folded into FUN-05 (the same rule, restated for the call site; both forms are exercised) | |
| FUN-35 | 883 | For calls with arguments, use `of`, `to`, `with`, or `on`. | — | — | — | folded into FUN-32 | |
| FUN-36 | 884 | Multiple arguments are separated by `and`. | emit a call with two or more arguments | yes | `Print f3 of c{a} and c{b}` (`src/gen_core.vox:387`), `'grid sink N' of ...` with 3–17 clauses (`src/gen_flow.vox:105`) | exercised | |
| FUN-44 | 885 | **New row, 2026-08-29 (0.4.14, #105).** Writing an argument right after the function name with none of `of`/`to`/`with`/`on` is an error naming the missing preposition, not a call with that argument silently dropped. Before #105 this used to be silently split into two statements — the call reporting the wrong arity and the dropped argument a second, unrelated "Unknown function" error; now one diagnostic, anchored at the token itself. Hand-verified with both a quoted multi-word name and a bare single-word name. | — | **no, from a runtime leaf** — this is now a compile-error claim, same category as FUN-41/FUN-42 | none — the generator never omits a connector before an argument (`gen call one`/`gen call two` always emit `of`) | not assertable (compile-error claim) — hand-verified against 0.4.14: `'add numbers' first and second.` → `error: 'first' follows the call with no preposition — arguments are introduced with 'of', 'to', 'with', or 'on'.`, caret on `first` | |
| FUN-45 | 758, 882 | **New row, 2026-08-29 (0.4.15, #110).** A function declared with a single-quoted single-word name (`To 'greet' with a number called x.`) both defines and is called correctly — the grammar accepted this before #110 (FUN-05), and now the manual says so explicitly too. | declare a function with a quoted single-word name, call it, assert the returned/printed value | yes | none — every generated function name is either bare or a quoted multi-word phrase; no leaf ever quotes a single word | todo — real gap, hand-verified (`To 'greet' with a number called x. Print x. 'greet' of 42.` → `42`) | |
| FUN-46 | 760 | **New row, 2026-08-29 (0.4.15, #110) — the case FUN-07 flagged as a real gap.** A parameter declared with a single-quoted single-word name (2+ characters — LANGUAGE.md:696–699 excludes one character, that lexes as a char literal) works exactly like a bare one: it is readable inside the body and the passed value round-trips. | declare a parameter with a quoted single-word name, pass a known value, assert it comes back | yes | none | todo — real gap, hand-verified (`To 'greet' with a number called 'radius'. Print radius. 'greet' of 7.` → `7`) | |
| FUN-47 | 2849–2855 | **New row, 2026-08-29 (0.4.15, #112) — one of five newly-fixed types; `number`/`float`/`boolean`/`text`/`value` were already correct before #112 and are covered by `values.md` VAL-19, not duplicated here.** A `list`-returning function whose only `Return` sits in a branch that never fires falls off its end to a real, usable **empty list** `[]` — before #112 this segfaulted. | declare a conditional-`Return` `list` function, call it so the branch never fires, assert the result prints `[]`, has `length` 0, and is still writable (`append` succeeds) | yes | none — no leaf declares a conditional-return function of any collection or thing type | todo — real gap, hand-verified (`To 'maybe list' with a boolean called b. If b, Return a list, [1, 2, 3]. a list called r is 'maybe list' of false. print r. print r's length. append 9 to r. print r.` → `[]`, `0`, `[9]`) | |
| FUN-48 | 2849–2855 | **New row, 2026-08-29 (0.4.15, #112).** A `map`-returning function that falls off its end hands back a real, usable **empty map** `{}` — before #112 this hung. | as FUN-47, for `map`; assert the result prints `{}`, has `length` 0, and a key can still be set | yes | none | todo — real gap, hand-verified (`a map called r is 'maybe map' of false. print r. print r's length. set r's "y" to 2. print r.` → `{}`, `0`, `{"y": 2}`) | |
| FUN-49 | 2849–2855 | **New row, 2026-08-29 (0.4.15, #112).** A `buffer`-returning function that falls off its end hands back a real, usable **empty buffer** — before #112 this segfaulted. | as FUN-47, for `buffer`; assert `'s size` is 0 and the buffer is still writable (`append` succeeds) | yes | none | todo — real gap, hand-verified (`'s size` reads `0`, `'s capacity` reads `4096` — consistent with `buffers.md` Discrepancy 1's dynamic-capacity finding, not a new one — and `append "x" to r.` then prints `x`) | |
| FUN-50 | 2849–2855 | **New row, 2026-08-29 (0.4.15, #112).** A `time`-returning function that falls off its end hands back **the zero time** (unix 0). | as FUN-47, for `time`; assert `'s unix` is 0 | yes | none | todo — real gap, hand-verified (`a time called r is 'maybe time' of false. print r's unix. print r's year.` → `0`, `1970`) | |
| FUN-51 | 2849–2855 | **New row, 2026-08-29 (0.4.15, #112).** A `thing`-returning function that falls off its end hands back **the all-defaults instance** for that type — every field holds its own declared default, not zero unless the field's own default is zero — before #112 this read the caller's leftover stack (a wrong-answer, not a crash). | as FUN-47, for a thing type whose fields declare non-zero defaults; assert every field reads its declared default, not garbage | yes — the generator wrote the field defaults, so the expected values are known | none — no leaf declares a conditional-return function of a thing type | todo — real gap, hand-verified (`A thing called point has a number called x is 7, a number called y is 9. To 'maybe point' with a boolean called b. If b, Return a point, <unused>. a point called r is 'maybe point' of false. print r's x. print r's y.` → `7`, `9` — the type's own declared defaults, confirming this is the all-defaults instance and not zeroed or uninitialised memory) | |
| FUN-37 | 887–892 | Calls with no arguments can be written directly, as a bare sentence (`'show version'.`, `ping.`). | emit a bare no-argument call statement | yes — assert what the callee printed or changed | `'read flags {n}'` as its own line (`src/gen_misc.vox:415`); the expression-position variant of the same form, `Print f1` (`src/gen_core.vox:366`), is also emitted | exercised | |
| FUN-38 | 894–898 | A call with arguments used inside a `Print` statement: `Print 'add numbers' of x and y.` — the whole of the "Calling as Statement" section. | emit it | yes — `Exit 95` if the printed sum is wrong (needs the value captured first, since `Print` discards it) | `Print f2 of c{n}`, `Print f3 of c{a} and c{b}` (`src/gen_core.vox:374,387`) | exercised | |
| FUN-39 | 894–898 *(gap)* | *(gap)* A call **with arguments** is also legal as a bare statement, its result discarded. The section is headed "Calling as Statement" but its only example is a `Print`, and :772–777 promises the bare form only for calls with **no** arguments. | emit a bare call-with-arguments statement | yes — assert a side effect the callee had | `f4 of "..."` (`src/gen_text.vox:408`) is exactly this shape | exercised — the manual should say so | |
| FUN-40 | 897 *(gap)* | **Claim reversed, 2026-08-22 (0.4.10, #67) — Discrepancy 5 RESOLVED.** Printing a call result **directly**, without routing it through a declared variable, is now correct for every type: `text`, `boolean`, `list`, `number`, and — newly fixed — `float` and `map`, which used to render as raw IEEE-754 bits and a raw heap address respectively. | direct-print a `float`- and `map`-returning call, assert the rendering matches the routed-through-a-variable sink | yes — the generator knows the returned value, so a whole-value comparison works for every type now | `Print f2 of ...` etc. print a `number` directly; no leaf yet direct-prints a `float`- or `map`-returning call | todo — hand-verified against 0.4.10 (`D5.vox`, re-run): `Print 'give float'.` now prints `2.5`, `Print 'give map'.` now prints `{"ann": 30}` | |
| FUN-41 | 873 *(gap)* | **RESOLVED 2026-08-22 (vox #45).** *(gap, as originally written)* A function with **no** declared return type, used in expression position, used to yield an untyped machine word (`Print announce of 9.` printed `1`). Now it is a compile error: `'announce' returns nothing, so its result cannot be used as a value here` — matching the fix already confirmed elsewhere (collections-a LST-18/19). | — | **no, from a runtime leaf** — this is now a compile-error claim, same category as `values.md` VAL-08 | f4 (`src/gen_core.vox:859`) has no return type but is only ever called as a **statement** (`src/gen_text.vox:408`), never in expression position, so the generator does not currently hit it — correctly, since it would now refuse to compile | not assertable (compile-error claim) — was filed as **vox bug #45** (`vox/docs/BUGS_FOUND.md:2931`), now fixed; re-verified directly against 0.4.9, probe re-recorded | |
| FUN-42 | 764–776 *(gap)* | **Gap RESOLVED 2026-08-25 (vox bug #96, fixed 0.4.11).** *(gap, as originally written)* The manual never said **where** a function definition may stand — and the compiler used to accept one nested inside an `If` or `While` body and **hoist** it (the body did not run when the block ran; the name was callable from the top level afterwards). The manual now states the rule (LANGUAGE.md:764-776): definitions are **top-level only** — "a function is defined where a `thing` is defined: at the top level" — and a definition reached while an `If`, a loop, or another function's body is still open is a **compile error**. The compiler enforces it: a nested definition is refused with `error: A function is defined at the top level, like a thing`. | — | **no, from a runtime leaf** — this is now a compile-error claim, same category as FUN-41 | none — the generator never emits a nested definition, and its own top-level-only rule (`src/gen_flow.vox:495-501`: "a function definition is only legal at the top level") is now exactly the language's rule, no longer stricter than it | not assertable (compile-error claim) — retained probe `FUN-42.vox` re-recorded to the current top-level-only rule; re-verified against 0.4.13 (bug #96, fixed 0.4.11) | |
| FUN-43 | 734 *(gap)* | *(gap)* A function body written on indented lines is closed by a **blank line**, not by EOF and not by the body's last period. Without one, every following top-level statement is swallowed into the body; the compiler warns but the program still builds and runs, silently doing nothing. | keep emitting the blank line — this is the one sameness this section genuinely requires | yes — the negative form is a legal program that produces no output, which a leaf could assert against, but it is a trap not a feature | every emitted definition ends `\n\n` (`src/gen_core.vox:845-859`, `src/gen_flow.vox:522`, `src/gen_misc.vox:393`) | exercised — and this is what justifies the blank-line invariant, see below | |

## Discrepancies

Nine, in eleven runnable repros in `docs/ledger/probes/functions/`
(Discrepancies 1 and 2 each have two, because each has two distinct
symptoms). None filed, none adjudicated — PROCEDURE.md §5.

Read in severity order rather than in numbered order: **8** is a
segfault, **1** is a whole class of silent wrong answers and is one line
away from being live in the generator, **2**, **3**, **4** and **5** are
narrow silent wrong answers, **7** is a missing diagnostic, and **6** and
**9** are most likely manual imprecision and diagnostic quality rather
than compiler faults.

### 1. A global declared *below* a function is read inside that function as a raw machine word, unless it is a `number` (`D1.vox`, `D1b.vox`) — RESOLVED (vox #66)

LANGUAGE.md:780: "Variables declared at top level are global and can be
used inside functions." No ordering condition is attached — and none is
needed for a `number`, which works in both directions. For every other
type it is wrong:

```
To 'show all'.
  Print counter.
  Print label.
  Print ratio.
  Print items.
  Print payload.

a number called counter is 42.
a text called label is "hello".
a float called ratio is 2.5.
a list called items is [1, 2, 3].
a buffer called payload is "ABC".

'show all'.
```

prints `42`, `4210888`, `4612811918334230528`, `139733748330496`,
`139733748322304` — the number, then a rodata address, then 2.5's
IEEE-754 bit pattern, then two heap addresses. The same five globals read
at top level print `42 hello 2.5 [1, 2, 3] ABC`. Move the declarations
**above** the function and all five are correct inside it too
(`FUN-11.vox`).

The failure is a **read**, not a store: `a text called echoed is label.`
inside the same forward-referencing function, then `Print echoed`, prints
`hello` — the bytes are there, the type is not. Writing works too: `Set
label to "changed"` from inside such a function updates the global
correctly. And a format string is no safer than `Print`: `Print "interp
{label}"` prints `interp 4198496`.

Strongest reading in which the compiler is correct: the analyzer walks
the source in order, so at the point it types the function body the
global has no declared type yet, and it falls back to the widest
assumption it has — an integer slot. Everything downstream is then
consistent with that assumption, and a *number* global genuinely is that
slot, which is why the number case looks fine. On this reading the
compiler is not wrong so much as under-informed, and the fix is either a
declaration-gathering pre-pass or a diagnostic at the untyped read. What
it must not keep doing is what LANGUAGE.md:725-728 says the 0.3.0
identifier/literal split was written to end: *"a function pointer,
printed as a number, silently. No error, no warning; the program runs and
gives a wrong answer that looks like data."* The manual's own example of
that disease prints `4198480`; this one prints `4198496`.

Related but **not the same** as vox bug #45
(`vox/docs/BUGS_FOUND.md:2931`), which is about a **call** with no
declared return type. Here there is no call — the read site is a plain
global reference, and there is no return type to declare. Same family
(a read where nothing supplies a type), different site. Not filed.

**This is already one line away from being live in the generator**
(`D1b.vox`). `src/gen_misc.vox:383` emits a flag-reader function, and
`src/gen_core.vox:963` (`gen emit ordered blocks`) rotates six prelude
blocks so the reader can be emitted **before** the flag schema it reads —
deliberately; the comment at `src/gen_misc.vox:369-375` records that
shape as hand-verified legal. It is legal. What keeps it correct is an
accident: the reader copies the text flag into a **declared** text local
(`a text called fl1local is fl1label.`) and prints the local. Delete the
copy and print the flag directly and the same function prints a stack
address. So the "no campaign has ever caught this" answer is not that the
shape is unreachable — it is that one line of one leaf happens to launder
the type.

**Resolution confirmed, 2026-08-22 — RESOLVED by vox #66.** CHANGELOG.md
#66: "Codegen now reads every top-level declaration's type in a pre-pass
and gives it to each function body before generating it, so a global is
read as its declared type wherever the declaration sits." Re-ran `D1.vox`
verbatim against 0.4.10: the five-global `'show all'` program now prints
`42 hello 2.5 [1, 2, 3] ABC` — exactly the top-level rendering, for every
type, from a function written above every one of the declarations. This
was the mapper's own top severity ranking ("a whole class of silent wrong
answers and is one line away from being live in the generator") — closed
without ever reaching a campaign. LANGUAGE.md:780–786 now states the fixed
rule directly, with the empty-value caveat for the one case that remains
special (a function that runs *before* the declaration is reached).

### 2. A `map` parameter's `size`/`length` is compiled into the **file**-size routine (`D2.vox`, `D2b.vox`) — RESOLVED (vox #76)

LANGUAGE.md:805: a typed parameter "supports the same properties and
operations as a top-level variable of that type." A `map` parameter does
not:

```
a map called ages is {"ann": 30, "bob": 40}.

To 'read map' with a map called lookup.
  Print lookup's length.

'read map' of ages.
```

does not assemble: ``D2b.asm:72: error: symbol `_file_size' not defined``.
That symbol name is the evidence. Put a `float` anywhere in the program —
which links the file runtime in for unrelated reasons — and the same code
builds and prints **-1**, the file-size error value, where the top-level
read of the same map prints **2** (`D2.vox`). `lookup's size` behaves
identically. Element access through the same parameter (`lookup's "ann"`)
is **correct**, so it is the size/length property specifically.

Two symptoms, one cause: a map parameter's size/length dispatches to the
file `size` implementation, which is absent unless something else drags
it in and wrong when it is present.

Strongest reading in which the compiler is correct: none that I can
construct. `-1` is not a defensible answer for a two-entry map, and a
program that fails to assemble is not a defensible outcome for legal Vox
either. The most charitable framing is that `map` was added to the
parameter-type list (LANGUAGE.md:803–805, "plan 296") ahead of the
property plumbing, and the property dispatcher's fall-through happens to
land on `file`. Not filed.

**Resolution confirmed, 2026-08-22 — RESOLVED by vox #76.** CHANGELOG.md
#76: "The declared-type to codegen-type table had been copied out four
times and `map` had reached only the declaration's copy... The four
copies are now one `vartype_of_declared_type`." Re-ran `D2.vox` verbatim
against 0.4.10: `'read map' of ages` now prints `2` — the correct entry
count, matching the top-level read, where 0.4.9 either failed to
assemble (`undefined symbol _file_size`) or printed `-1` depending on
whether a `float` elsewhere in the program happened to link the file
runtime in. LANGUAGE.md:824–828 now documents map parameters explicitly
alongside buffer, list and file parameters. #76's own changelog entry
credits this exact discrepancy: "Found by the vox-fuzz candidate audit
and adjudicated by the language lawyer."

### 3. A `timer` parameter's `'s elapsed` is a compile error (`D3.vox`)

```
To 'show timer' with a timer called clock.
  a number called waited is clock's elapsed in milliseconds.
```

```
error: Property 'elapsed' requires a timer: clock
```

with the caret on the parameter's own declaration, which says `a timer
called clock` two words to its left. The identical read on a top-level
timer compiles and runs (`FUN-22.vox`). The parameter **declaration** is
accepted on its own — `To 'show timer' with a timer called clock.` with a
body that never touches `clock` compiles and runs fine (`FUN-21.vox`) —
so `timer` is a legal parameter type that cannot be used for the one
thing a timer is for.

Strongest reading in which the compiler is correct: the same one as
Discrepancy 2 — `timer` is in the parameter-type vocabulary but the
property dispatcher's "is this a timer?" test only recognises top-level
timer storage, and a parameter slot is not that. On that reading the
diagnostic is honest about what it checked, and the bug is the narrow
test rather than the message. Not filed.

### 4. A `file` parameter's `readable` and `writable` are always false (`D4.vox`)

LANGUAGE.md:828: "file parameters support file properties." Two of the
eight do not. **Not in the 0.4.10 register (#66–#91) — re-verified
unchanged, 2026-08-22:** `D4.vox`'s repro still reads `0` for `src`'s
`readable` through a parameter, `1` at top level; still open.

```
open a file for reading called src at "...".
open a file for writing called sink at "...".
```

| property | `src` top level | `src` via parameter | `sink` top level | `sink` via parameter |
|---|---|---|---|---|
| `readable` | 1 | **0** | 0 | 0 |
| `writable` | 0 | 0 | 1 | **0** |
| `size` | 12 | 12 | — | — |
| `descriptor` | 3 | 3 | — | — |

`size` and `descriptor` survive the call; the two booleans do not. This is
a silent wrong answer of exactly the shape a fuzzer exists to find: a
guard written as `If handle's writable then, ...` inside a helper
function never fires, and nothing says why.

Strongest reading in which the compiler is correct: `readable`/`writable`
are the only two file properties that are not read from the on-disk inode
or the descriptor number but from the open-mode flags the compiler
recorded at the `open` site. A parameter carries the handle, not the
compile-time site, so the flag lookup finds nothing and answers `false`.
That is a coherent implementation story, and it explains precisely which
two properties break — but "the caller opened it for writing" is a fact
about the value, not about the syntax, and the manual promises it travels.
Not filed.

### 5. A declared `float` or `map` return is mis-rendered when the call result is printed directly (`D5.vox`) — RESOLVED (vox #67)

```
To 'give float'. Return a float, 2.5.
To 'give map'. Return a map, {"ann": 30}.

a float called 'routed float' is 'give float'.
Print 'routed float'.        (2.5          — right)
Print 'give float'.          (4612811918334230528 = 0x4004000000000000 — wrong)
Print 'give map'.            (140201717768192 — a heap address, wrong)
```

`text`, `boolean` and `list` returns print correctly in the same position
(`FUN-40.vox`). This is the shape of vox bug #45 — except that #45's
stated cure is *declaring the return type*, and here it **is** declared
and the result is still wrong. So either #45 is narrower than its fix
description, or this is a second defect with the same signature.

Strongest reading in which the compiler is correct: `Print` of a call
result has no variable to carry a type, so it uses the call's declared
return type — and for `float` and `map` the "declared return type" is
recorded in a form the `Print` dispatcher does not consult, falling back
to the integer formatter. That makes it the same root as #45 (a read
where nothing supplies a type) reaching a case #45's fix does not cover.
It is not a memory-safety fault: the pointer is handed to the wrong
formatter, never dereferenced as an integer. Not filed.

**Resolution confirmed, 2026-08-22 — RESOLVED by vox #67.** CHANGELOG.md
#67: "Declaring the return type is the first way out bug #45's diagnostic
offers, so it now works for all eleven types." Re-ran `D5.vox` verbatim
against 0.4.10: `Print 'give float'.` now prints `2.5` (was
`4612811918334230528`, the bit pattern) and `Print 'give map'.` now
prints `{"ann": 30}` (was a raw heap address) — both direct-print sinks
now agree with the routed-through-a-variable sink. FUN-40 (below) is
unblocked by this fix.

### 6. `Return a file,` works, but the returned handle cannot be received by the `a file called X is <call>.` form (`D6.vox`)

LANGUAGE.md:806-808 lists `file` among the eleven legal return types;
:748-750 says a call's declared return type "is tracked through
assignment".

```
Set viaset to 'give file'.
Print viaset's size.        (12 — right)

a file called viadecl is 'give file'.
Print viadecl's size.       (compile error, caret on the DECLARATION)
```

```
error: Property 'size' requires a buffer, list, map, or file variable: viadecl
```

Strongest reading in which the compiler is correct, and I think it is the
right one: **this is not about functions at all.** `a file called alias
is src.` — aliasing one top-level file variable to another, no call in
sight — is rejected identically. The `a file called X is <expr>` form
simply does not exist in the language, and the call is an innocent
bystander; the `Set` form proves the returned value itself is intact. On
that reading LANGUAGE.md:839-841 is imprecise rather than false ("tracked
through assignment" is true of the assignments that exist), and the
sharper statement of the gap is that a `file` variable can only be
brought into existence by `open`/`Create`. `timer` is the same: `a timer
called got is 'give timer'.` is a parse error, and `Set got to 'give
timer'.` works. Worth a manual sentence rather than a compiler change.
Not filed.

### 7. `Return a buffer, "<text literal>"` yields an empty buffer, silently (`D7.vox`) — RESOLVED (vox #53)

```
a buffer called direct is "ABC".
Print direct's size.                (3   — right)

To 'give literal'. Return a buffer, "ABC".
a buffer called 'from literal' is 'give literal'.
Print 'from literal''s size.        (0   — wrong, and it prints nothing)
```

A function that builds `a buffer called made is "ABC".` and returns
**that** yields size 3 (`FUN-23.vox`). So the text-to-buffer conversion
the declaration form performs is not performed in the return expression,
and no diagnostic mentions it.

Strongest reading in which the compiler is correct: `Return a buffer,
<text literal>` is a type mismatch — the manual never promises a text
literal converts to a buffer anywhere except in a declaration's
initializer — and the analyzer chose to accept it rather than reject it.
On that reading this is a **missing diagnostic**, not a wrong answer, and
the fix is to refuse the construct and name the way out, the way
`push_whole_thing_not_interpolable` does (the precedent cited in vox
#45's own fix direction). It is silent either way, and Discrepancy 8 is
what silence costs here. Not filed at the time.

**Resolution confirmed, 2026-08-22: fixed by vox #53.** `vox/docs/
BUGS_FOUND.md` #53 ("`Return a buffer, "<text literal>"` answers with an
empty buffer — or segfaults, once the program holds a second string")
names this exact pair (D7/D8) as its origin. Re-run `D7.vox` against vox
0.4.9: it no longer compiles. The construct is now refused outright,
exactly the "missing diagnostic" fix this discrepancy's strongest
reading predicted: `error: Cannot return text "ABC" as a buffer; the
caller reads what Return hands back as a buffer, and text is not one.
Build the buffer first: 'a buffer called made is "ABC". Return a buffer,
made.'` — which is precisely the working form `FUN-23.vox` already used.

### 8. The same construct **segfaults** once a second string-initialised buffer exists (`D8.vox`) — RESOLVED (vox #53)

Six lines. Legal Vox. Compiles clean. Exits 139, deterministically
(3/3 runs, and again under `check-probes.sh`):

```
To 'give literal'. Return a buffer, "ABC".

a buffer called direct is "ABC".
a buffer called second is "DEF".
a buffer called 'from literal' is 'give literal'.
Print 'from literal''s size.
```

It dies **before printing anything**, so the fault is in the declarations,
not the property read. The boundary is sharp and was bisected:

- one string-initialised buffer in the program → Discrepancy 7's silent
  empty buffer, no crash;
- two or more → segfault. The second one counts whether it is at top
  level or **inside another function's body**;
- replacing the literal return with a buffer-**variable** return
  (`a buffer called made is "ABC". Return a buffer, made.`) is safe at any
  buffer count.

So the text literal in the return expression is the trigger; the buffer
count only decides whether the damage is visible.

Strongest reading in which the compiler is correct: there isn't one.
CLAUDE.md's first line about what this generator is for — *"no program,
however stupid, and no input, however hostile, should segfault"* — makes
this the top-severity class, and the program here is not even
particularly stupid. The most useful framing for whoever fixes it is that
Discrepancy 7 and this are one defect at two doses: the return expression
hands back something that is not a buffer, and the receiving declaration
treats it as one. Not filed, per PROCEDURE.md §5 — but this is the row to
carry to Josj first.

**Resolution confirmed, 2026-08-22: fixed by vox #53, same fix as
Discrepancy 7.** They were one defect at two doses, and the fix was one
fix: the construct is refused at compile time regardless of how many
buffers exist, so the dose no longer matters. Re-run `D8.vox` against vox
0.4.9: it no longer segfaults — it no longer compiles, with the same
diagnostic D7 now gets. Top-severity memory-safety finding, closed the
way CLAUDE.md's own framing said it had to be: not by making the crash
answer correctly, but by refusing the program before it could run.

### 9. The "locals are not available at top level" rule is enforced, but the diagnostic points inside the function (`D9.vox`)

```
To 'make local'.
  a number called localsum is 7.
  Print localsum.

'make local'.
Print localsum.          <- the offending line
```

The diagnostic, from the six lines above on their own:

```
error: Unknown variable: localsum
  --> 3:9
  3 |   Print localsum.
    |         ^--- here
  hint: `localsum` is declared only in some branches of an `if`/`otherwise`,
        so it is not in scope after it - declare it in every branch, or
        before the `if`
```

The caret lands on line 3, **inside** the function, where the read is
perfectly legal; the hint describes an `if`/`otherwise` the program does
not contain. (Running the retained `D9.vox`, which carries this ledger's
standard comment header, gives the same message pointed at `D9.vox:5:9` —
a line inside the comment. That second misdirection is vox bug #46, not
this discrepancy.) Delete the last line and the program compiles and prints 7,
which is what identifies the last line as the real offender. The name
chosen changes the message but not the misdirection: with a name that
collides with a reserved word the error becomes `Unknown identifier` or
`reserved keyword`, still pointed at the function's own declaration.

Strongest reading in which the compiler is correct, and it holds:
LANGUAGE.md:787 promises only that this is a **compile-time error**, and
it is one. Nothing in the manual promises where the caret lands, so on the
letter of the claim the compiler is right and this is a diagnostic-quality
defect. Recording it anyway because it cost this mapper twenty minutes
hunting a scope bug inside a function body that was not there, and
because it is the same family as vox bug #46, "the diagnostic caret can
land inside a comment" (`vox/docs/BUGS_FOUND.md:2998`). Not filed.

## Invariants this section justifies

Every sameness below is one the manual actually requires; a generated
program that varies it is producing illegal Vox. Everything else about a
function must vary.

- a blank line after every function definition — LANGUAGE.md:743–748 (the
  manual's own two-definition example), and the compiler's own warning
  quoted in `FUN-43.vox`; FUN-43
- every function definition begins with `To ` — LANGUAGE.md:737, FUN-01
- every parameter is written `a <type> called <name>` — LANGUAGE.md:760,
  FUN-07
- parameters in a definition are joined with `and`, and arguments at a
  call site are separated with `and` — LANGUAGE.md:761 and :770, FUN-08,
  FUN-36
- a declared return type is always written `Return a <type>,` —
  LANGUAGE.md:762, FUN-09
- a function or parameter name containing a space is always
  single-quoted — LANGUAGE.md:758 and :760, FUN-05, FUN-07. Note the
  converse is **not** justified: a single-word name may be quoted too
  (`To 'ping'.` and `'ping'.` both work, `FUN-05.vox`), so "single-word
  names are never quoted" is a rule nobody wrote — **except for a
  single-CHARACTER name**, which genuinely cannot be quoted: a
  single-quoted one-character token is a character literal
  (LANGUAGE.md:696–699, "that is why single-character quoted identifiers
  do not exist"), confirmed 2026-08-29 (`a number called 'x' is 1.` →
  `error: Expected a name, got IntegerLiteral(120)`; `'radius'`,
  two-plus characters, works fine). Not a new invariant to justify —
  this one is the manual's own, explicit rule, not an accident of the
  generator.

Nothing else. In particular the following are **not** justified and are
defects in the current corpus, all confirmed by `grep` over the emitted
strings rather than by reading leaf names:

- every emitted call uses the connector `of` — LANGUAGE.md:883 accepts
  `of`, `to`, `with` and `on`, all four hand-verified identical (FUN-32)
- every emitted definition introduces parameters with `with` — :698 says
  `of` works identically (FUN-06)
- every emitted parameter name is a bare single word (`p1`, `p2`, `x1`,
  `original`) — :699 permits single-quoted multi-word names (FUN-07)
- every emitted parameter is `number` or `text` (plus the thing type `t4`
  on the two thing methods); nine of the eleven expressible types never
  appear in any parameter list (FUN-21)
- every emitted return type is `number` (plus `t4` on the thing methods);
  ten of the eleven never appear (FUN-23)
- no emitted function body reads a property off a parameter (FUN-22)
- no emitted function assigns to a global, shadows one, or calls any
  function including itself (FUN-14, FUN-17, FUN-18)
- no emitted function-related construct asserts anything

## Report

**43 rows** (FUN-01 through FUN-43). Two (FUN-34, FUN-35) are
restatements folded into a sibling, leaving **41 distinct claims**. Of
those, **37 are assertable** — the generator picks the arguments, so it
knows the answer and can emit an `Exit 95` check. Four are not: FUN-12
and FUN-13 (the claim is that a program is *rejected*, which a leaf must
never emit), FUN-31 (a claim about pre-v0.1.16 compilers), and FUN-41 (a
shape no leaf may emit while vox #45 is open). FUN-40 counts as
assertable but is **embargoed**: a leaf must not print a `float` or `map`
call result directly while Discrepancy 5 is open, and must route it
through a declared variable instead.

**Existing coverage: 14 rows exercised, 0 verified.** The generator emits
eight functions in total — `f1`–`f4` (`src/gen_core.vox:843`), one grid
sink (`src/gen_flow.vox:503`), one flag reader (`src/gen_misc.vox:383`),
two thing methods (`src/gen_things.vox:124,129`) — and between them they
cover the skeleton of the section: definitions with and without
parameters, both name forms, `and`-joined parameters and arguments, a
declared return type, a bare no-argument call, a call in `Print`
position, and a bare call with arguments. Not one of them checks a
result.

**The biggest finding is Discrepancy 8: a six-line program that compiles
clean and segfaults.** `Return a buffer, "<literal>"` plus two
string-initialised buffers, deterministic, exit 139. That is a broken
memory-safety promise, which CLAUDE.md rates above everything else in
this document. Discrepancy 7 is the same construct at a lower dose
(silent empty buffer), and Discrepancy 1 is the widest: **every**
non-number global declared below a function reads as a raw machine word
inside it, with no warning — a whole class of silent wrong answers, and
the disease LANGUAGE.md:717-728 says 0.3.0 was written to cure.

**Why no campaign has ever found Discrepancy 1** is worth stating,
because the answer is not the comfortable one. The generator already
emits the bug's exact shape: the flag reader (`src/gen_misc.vox:383`) is
the one emitted function that reads globals, and the six-block rotation
(`src/gen_core.vox:963`) can place it **before** the flag schema, which
was a deliberate choice with a hand-verification comment behind it
(`src/gen_misc.vox:369-375`). The reader survives on an accident: it
copies the text flag into a **declared** text local and prints the local.
`D1b.vox` is that same function with the copy removed, and it prints a
stack address. One line of laundering is all that stands between the
current corpus and a silent wrong answer in every program that draws that
rotation. **Advice to whoever builds these leaves: a leaf that reads a
global from inside a function must vary both the side of the definition
the global is declared on AND whether the read goes through a declared
local — the second is what actually decides the answer.**

**Advice for the next mapper**, beyond that:

1. **Read properties off a parameter, not just a top-level variable.**
   Three of the nine bugs in this document (Discrepancies 2, 3, 4) are
   invisible unless you pass the value into a function first, and all
   three are in the "same properties and operations" sentence at
   LANGUAGE.md:805-806 that reads like boilerplate. That sentence is the
   single highest-yield line in this section.
2. **Print the result twice — once out of a variable, once straight from
   the call.** Discrepancy 5 only appears in the second form, and only for
   two of the eleven types. A probe that assigns first will report all
   clear.
3. **When a probe fails to *assemble*, read the missing symbol name.**
   ``symbol `_file_size' not defined`` in a program with no files in it is
   what identified Discrepancy 2's root; without it the `-1` would have
   looked like an ordinary wrong answer.
4. **Beware your own probe.** I lost time to two false alarms worth
   flagging: `text's length` is not supported at all (it errors with
   "Property 'size' requires a buffer, list, map, or file variable"),
   which has nothing to do with functions and poisons any probe that uses
   it; and `copy`, `bytes`, `numbers`, `reading` and `stopwatch` are all
   reserved words that produce confusing errors when used as variable
   names. Neither was a language bug.
5. **The diagnostic caret can be lying about which line is at fault**
   (Discrepancy 9, and vox #46). The probe headers in this directory are
   comments, and the compiler's caret quotes *them* when reporting an
   error at a program line number — so when reading a compile-error probe's
   output, trust the message, not the source line it prints.

**What I could not do:** nothing in this section needed root, a device,
or a second process, so no row is blocked for want of privileges. No row
is left unmapped. Per the brief I did not commit, did not push, and did
not touch `src/`.

**One note on the brief's own numbering:** it asks for probes named
`probes/functions/THG-NN.vox`. `THG` is the Things prefix; `INDEX.md`
fixes this section's prefix as `FUN`, and PROCEDURE.md §1 says row IDs
carry the section's prefix, so the probes are named `FUN-NN.vox`.

### Addition, 2026-08-29: FUN-44 (0.4.14, #105)

**One new row.** LANGUAGE.md:885, the sentence 0.4.14 added right after
FUN-36's bullet in the same list: writing an argument directly after
the function name, with none of `of`/`to`/`with`/`on`, is a compile
error naming the missing preposition — not a call with that argument
silently dropped. Hand-verified against the installed 0.4.14 binary
with both a quoted multi-word function name and a bare single-word one;
both produce the same diagnostic shape, anchored at the dropped token.
Not assertable by a leaf, same category as FUN-41/FUN-42 (a compile-error
claim), so **44 rows total, 38 assertable, 14 exercised, 0 verified** —
the assertable/exercised counts above are otherwise unchanged by this
addition.
