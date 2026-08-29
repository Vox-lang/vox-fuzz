# Claim ledger: File I/O → files

Source: `../vox/LANGUAGE.md` lines **3481–3872**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned against a 5112-line 0.4.7 manual — the most stale ledger in the
set at re-pin time, three manual versions behind). Row prefix **`FIL`**.

**Note on the line range.** The brief describes this range as "file
properties (the rest of Object Properties), Opening Files, Reading,
Seeking, Writing, Closing, File Operations, Error Handling, Resource
Safety". The range is right, but "the rest of Object Properties" is
four subsections, not one: **File Properties** (3481–3526), **List
Properties** (3527–3546), **List Element Access** (3547–3579) and
**Number Properties** (3580–3601). All four are mapped here, which is
why a ledger called `files.md` carries rows about `nums's last` and
`x's absolute`. They are the tail of the Object Properties chapter that
the buffers ledger stopped short of, and nothing else would pick them
up.

**Two rows changed shape across the 0.4.7 → 0.4.9 re-pin, not just their
line numbers — both are the manual catching up to compiler fixes found
by this same ledger:**

- **FIL-08** (`exists` file property) is **withdrawn**. Vox bug #38 was
  closed by removing the table row rather than implementing it (Josj's
  ruling, `vox/docs/BUGS_FOUND.md` #38); the manual now documents the
  `On error`-around-`open` idiom in its place (3504–3525). Discrepancy 1
  is resolved.
- **FIL-45** (`Read` append-vs-replace) had its claim **reversed**, not
  just moved: LANGUAGE.md used to say `Read` "appends"; Discrepancy 2
  argued the compiler (which replaces) was right and the manual was
  wrong; **the manual was changed to say "replaces"** (3648–3650), not
  the compiler. Discrepancy 2 is resolved.

Both are re-probed against vox 0.4.9 below and both hold.

This is a **gap analysis, not a rewrite**. The `existing leaf` column
names the leaf that already emits the construct in a *generated*
program, or `none`. Generator-internal code does not count: `src/` opens
files, seeks and deletes constantly, and none of that reaches a fuzzed
program. Every `existing leaf` entry was found by `grep -n` on the
accessor or keyword (`open a file`, `Read from`, `Read line`, `Seek`,
`Write `, `Close `, `is available`, `Delete the file`, `On error`,
`'s descriptor`, `'s readable`, `'s writable`, `'s permissions`,
`element `, `'s first`, `'s last`, `'s absolute`), never by leaf name.

**Nothing in this section is `verified`.** The only assertions the whole
generator emits are the four argv/flag checks at `src/gen_misc.vox:316–321`
(exit 91–94). Every file, list and number construct that is emitted today
is `Print`ed for a human to eyeball. That is uniform across the section
and is a finding about the generator, not a surprise per row — the same
finding the buffers ledger reported, now confirmed as generator-wide.

Every row below was hand-run against the real compiler before it was
written.

## Probes

`docs/ledger/probes/files/` holds **45 files** (43 at the original pass,
plus `FIL-102.vox` and `FIL-103.vox` added 2026-08-22): 39 row probes
named `FIL-NN.vox` and 6 discrepancy repros `D1.vox`–`D6.vox`. A probe that
covers more than one row is named for the first and lists the rest in
its own `Also covers:` line.

Each probe opens with a `(...)` header giving the claim, the rows it
covers, the exact command it was run with, and the output the compiler
**actually** produced. Every probe **creates everything it needs** under
`vf_scratch/files/` and touches nothing outside it — no fixtures
directory, no repo-relative input files, nothing to install first. Run
them from the vox-fuzz worktree root; `vf_scratch/` is already
gitignored (`vf_*`).

**Refreshed 2026-08-21 against vox 0.4.8 (+#47/#48/#40).** `D3`, `D4`,
`D5`, `D6` and `FIL-63` were re-recorded because the compiler was fixed
under them: `D6` is now a compile-error probe rather than a segfault, and
nothing in this directory crashes any more. `D4`'s closing marker line was
reworded (it asserted that no write set the flag, which is no longer true).

All 43 were re-run in one final pass from a wiped `vf_scratch/`, and then
a second time with the scratch directory already populated: **43 clean,
0 mismatches, both times.** The probes are idempotent by construction —
each one re-seeds its own input file.

Three probes are not plain "compile, run, diff stdout" and a
`check-probes.sh` will need to special-case them:

| probe | why |
|---|---|
| `D1.vox`, `FIL-44.vox` | must **fail to compile**; the recorded output is the compiler's diagnostic |
| `D6.vox` | must **segfault** (signal 11, exit 139) |
| `FIL-81.vox` | exits **3** by design (an `On error … exit 3` handler) |
| `FIL-48.vox`, `FIL-51.vox` | need bytes on stdin; the recorded command pipes them in |

Rows with no probe file are the ones that cannot be run: `FIL-71`
(access(2) is not observable from Vox), `FIL-84`, `FIL-86`, `FIL-87`,
`FIL-92`, `FIL-94`, `FIL-95`, `FIL-101` (implementation details, marked
`not assertable`), and the pure cross-reference rows `FIL-67`, `FIL-82`,
`FIL-97`, `FIL-98`, `FIL-99`, which are folded into a sibling.

---

## File Properties (3326–3348)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-01 | 3766 | `size` returns the file's size in bytes as a Number, live — it reads 0 before a write and the byte count after. | open a handle, write a known number of bytes, assert `h's size` | yes — the generator knows the exact payload length: `If fw{n}'s size is not 18 then, Exit 95.` | none reads `'s size` on a **file**; `gen leaf file round trip` and `gen leaf stdin read` read `'s size` on the destination **buffer**, which is a different property of a different object | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-02 | 3767 | `descriptor` returns the raw file descriptor number as a Number. | print/assert `h's descriptor` after an open | partly — the exact number is allocation-dependent, but a lower bound is knowable: `If fr{n}'s descriptor is less than 0 then, Exit 95.` (a failed open reports a negative errno, see D5) | `gen leaf file write` (`src/gen_files.vox:97`) emits it — but that leaf is **disabled**: it is dispatched at kind 99, outside every draw (`src/gen_core.vox:578–582`), so no generated program contains it | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-03 | 3768 | `readable` is true iff the file is open for reading. | open in each of the three modes, assert `readable` matches | yes — the generator chose the mode: `If fr{n}'s readable is false then, Exit 95.` | `gen leaf file round trip` (`src/gen_files.vox:184`) emits `Print fr{n}'s readable` on a reading handle only; never on a writing or appending one, and never asserted | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028; readable asserted alongside FIL-04 in the drawn-mode leaf |
| FIL-04 | 3769 | `writable` is true iff the file is open for writing. | same, for `writable` | yes, same shape | only the disabled `gen leaf file write` | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-05 | 3770 | `modified` returns the last modification time as a Unix timestamp Number. | print/assert `h's modified` | partly — the wall clock is unknowable, but a range is: `If f{n}'s modified is less than 1700000000 then, Exit 95.` | only the disabled `gen leaf file write` (which prints `permissions`, not `modified` — nothing emits `modified` at all) | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-06 | 3771 | `accessed` returns the last access time as a Unix timestamp Number. | as FIL-05 | yes, same range assertion | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-07 | 3772 | `permissions` returns the file's permission bits as a Number (`e.g., 0644`). | print/assert `h's permissions` on a file the program itself created | yes — a file created by `open … for writing` is 0644, i.e. **420** decimal: `If f{n}'s permissions is not 420 then, Exit 95.` See the note below the table before writing that leaf. | only the disabled `gen leaf file write` | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-08 | — | *(withdrawn, manual 0.4.9 — see Discrepancy 1)* `exists` returns whether the file exists, as a Boolean. **This claim no longer exists in the manual.** Vox bug #38 (parse error) was resolved by removing the table row (Josj's ruling, option 3 of 3) rather than implementing the property; LANGUAGE.md now documents the `On error`-around-`open` idiom in its place, at 3504–3525. | — | — | — | withdrawn (manual 0.4.9) | |
| FIL-09 | 3775–3783 | The worked example (open for reading, `print src's size`, `print src's modified`, `If src's size is greater than 1048576 then, …`) compiles and behaves as the prose says. | reproduce the chain | yes, as a composite of FIL-01/05 plus a size comparison whose answer the generator knows | none as a chain; the `open`+`Read`+`Print size` half exists in `gen leaf file round trip` | todo (composite) | |

**Note on FIL-07, for whoever writes the leaf.** `permissions` prints
`420`, and `420` **is** octal `0644` — the property returns the raw
mode bits as a Number and `Print` renders a Number in decimal. The
manual writes the example value in octal (`0644`) without saying the
property is not formatted that way, which is exactly the sort of
half-read that produced three false buffer claims on 2026-08-20. Assert
`420`, not `644`. Hand-verified in `FIL-01.vox`.

The old `gen leaf file write` comment (`src/gen_files.vox:87`) says
`permissions` "is machine-dependent … a tty, a pipe and a file all
differ". That was true of its `/dev/stdout` target. For a file the
program creates itself in its own scratch directory it is fixed at 420
under any sane umask, so this row **is** assertable now in a way it was
not when that comment was written.

## List Properties (3350–3368)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-10 | 3812 | `length` returns the number of items in a list. | declare a list of known length, assert `l's length` | yes — the generator wrote the literal: `If l{n}'s length is not 3 then, Exit 95.` | none on a **list**; `gen leaf map inrange` (`src/gen_collections.vox:47`) reads `'s length` on a **map**, and `gen leaf timer and clock` (`src/gen_text.vox:493`) on a clock buffer | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-11 | 3813 | `size` on a list is the same value as `length`. | assert `l's size is l's length`, and both against the known count | yes | none — `'s size` is never read on a list | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-12 | 3814 | `empty` is true iff the list has no items. | assert on both a populated and an empty list | yes | none on a list; `'s empty` is read on `environment` (`src/gen_misc.vox:86`), on `arguments` (`:144`) and on a buffer (`:88`), never on a list | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-13 | 3815 | `first` returns the first item in the list. | assert `l's first` equals the literal the generator emitted first | yes | none — `'s first` appears nowhere in `src/` | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-14 | 3816 | `last` returns the last item in the list. | as FIL-13, for the last literal | yes | none — `'s last` appears nowhere in `src/` | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-15 | 3819–3826 | The worked example compiles, and a Boolean property (`names's empty`) reads directly as an `If` condition with no comparison. | reproduce; emit the bare-property condition form | yes | the bare-property-as-condition form is emitted for **buffers** (`If sb{n} is empty then, …`, `src/gen_files.vox:139`) but that is the `is empty` **predicate**, a different construct from the `'s empty` **property** this row is about | todo | |

## List Element Access (3370–3401)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-16 | 3830 | List indexes are **1-indexed**. | assert `element 1 of l` equals the first literal emitted | yes — this is the whole point of an assertion: today's leaf reads `element 1` and prints it, which passes identically under 0- and 1-indexing | `gen leaf list inrange` (`src/gen_collections.vox:15`) reads `element 1` but never asserts *which* element came back | todo (verification, not exercise) | |
| FIL-17 | 3833–3837 | `element N of list` with a **literal** index returns the Nth item. | vary N across the list's length, assert each | yes | `gen leaf list inrange` — but the literal is **always `1`** (`src/gen_collections.vox:15`), an undeclared rule: nothing in the manual says a program reads the first element. `gen leaf format types` (`src/gen_text.vox:411`) also emits `Print element 1 of gl{n}`, same fixed index. | exercised (index 1 only) — see *Invariants* | |
| FIL-18 | 3839–3840 | `element i of list` with a **variable/expression** index works. | emit an index that is a runtime Vox variable, not a number baked into the generated text | yes | none — every emitter interpolates the index into the generated source as a compile-time literal before the program is written. The variable-index path through the compiler is never taken. Identical gap to BUF-21 on buffers. | todo — real gap, hand-verified to work | |
| FIL-19 | 3845 | `list's first` returns the same item as `element 1`. | assert both against each other and against the literal | yes | none | todo | |
| FIL-20 | 3846 | `list's last` returns the same item as `element length`. | as FIL-19 | yes | none | todo | |
| FIL-21 | 3850–3855 | **Claim extended, 2026-08-22 (0.4.10, #72/#91).** Out-of-bounds list access sets the error flag **and returns 0** — true unconditionally through 0.4.9 (an untyped 0 that a non-number destination could dereference and segfault on — #91). As of 0.4.10 this Error Handling overview states the same provable/unprovable split as the Lists section itself (see `collections-b.md` LST2-25/LST2-28): compiler-provable OOB reads yield the number 0 (only a `number`/`float`/`boolean` destination is legal); unprovable ones yield the destination's typed default (`0`/`""`/`[]`/`{}`). | capture the OOB read into a variable, assert it is 0 | yes — `If bad{n} is not 0 then, Exit 95.` | `gen leaf list oob` (`src/gen_collections.vox:25`) prints the OOB read directly and catches the error; it never captures the value, so the "returns 0" half is untested | exercised (error-flag half); todo (returns-0 half, and the typed-default half is new territory) | |
| FIL-22 | 3856 | List OOB errors are catchable with `On error`. | — | yes | `gen leaf list oob` (`src/gen_collections.vox:26`) | exercised | |
| FIL-23 | 3859–3863 | The error-handling worked example compiles and behaves as shown. | reproduce | yes | same as FIL-21/22 | exercised (composite) | |

Index `0` is out of bounds and errors — the 1-indexing claim from the
other side, hand-verified in `FIL-21.vox`. Worth a leaf: `element 0` is
the single index most likely to expose an off-by-one, and no leaf emits
it (`gen leaf list oob` draws its index from `'rng below' of 500 add 10`,
so it is never below 10).

## Number Properties (3403–3423)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-24 | 3870 | `even` is true iff the number is even. | assert on a number the generator chose | yes — trivially: it drew the number | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-25 | 3871 | `odd` is true iff the number is odd. | as FIL-24; also assert `odd` is the negation of `even` | yes | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-26 | 3872 | `positive` is true iff the number is > 0. | assert on a positive, a negative and 0 | yes | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-27 | 3873 | `negative` is true iff the number is < 0. | as FIL-26 | yes | none | todo | |
| FIL-28 | 3874 | `zero` is true iff the number is 0. | as FIL-26 | yes | none | todo | |
| FIL-29 | 3875 | `absolute` returns the absolute value. | assert against the known magnitude | yes | `gen leaf cast and break` (`src/gen_misc.vox:176`) emits `Print cn{n}'s absolute` on a deliberately extreme literal, unasserted | exercised | |
| FIL-30 | 3876 | `sign` returns -1, 0 or 1. | assert all three cases | yes | none | todo | |
| FIL-31 | 3879–3885 | The worked example (`If x's negative then, …`, `print x's absolute`) compiles and behaves as shown. | reproduce | yes | the `absolute` half only | todo (composite) | |

Six of the seven Number properties are emitted by nothing at all, and
all seven are the cheapest assertions in the entire manual: the
generator picks the number, so it knows every answer without computing
anything. `FIL-24.vox` pins all seven in thirteen lines.

## Opening Files (3425–3462)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-32 | 3893 | `open a file for reading called X at "<path>"` opens an existing file for reading. | — | yes, via `readable`/`size` | `gen leaf file round trip` (`src/gen_files.vox:180`), `gen leaf stdin read` (`:135`, path form `"/dev/stdin"`) | exercised | |
| FIL-33 | 3894 | `open a file for writing called X at "<path>"` opens a file for writing. | — | yes | `gen leaf file round trip` (`src/gen_files.vox:177`), `gen leaf format types` (`src/gen_text.vox:418`, target `"/dev/stdout"` — see *Report*) | exercised | |
| FIL-34 | 3895 | `open a file for appending called X at "<path>"` opens a file for appending. | — | yes | **none** — `for appending` is emitted by no leaf; only the generator's own `src/` code uses it | todo — real gap, one of three modes entirely untested | |
| FIL-35 | 3898–3903 | A file can be opened at a bare descriptor number (`at 0`, `at 1`, `at 2`). | emit the numeric form for descriptors other than 0 | yes | `gen leaf stdin read` (`src/gen_files.vox:133–135`) emits `at 0` half the time; `at 1` and `at 2` are never emitted | exercised (`at 0` only) | |
| FIL-36 | 3906 | A numeric `at` is a **borrowed descriptor**, not a filesystem path. | prove the negative: after `open … at 2`, assert no file named `"2"` exists | yes — `If "2" is available then, Exit 95.` | implied by `gen leaf stdin read`'s `at 0`, never asserted | todo (verification) | |
| FIL-37 | 3908–3914 | The `for <mode>`, `called <name>` and `at <path>` clauses may appear **in any order**; all three permutations shown compile. | emit the clause order at random, not one fixed order | yes (it compiles or it does not) | **none** — every leaf emits exactly `open a file for <mode> called <name> at <path>`, the manual's first order. A fixed ordering the manual explicitly permits to vary. | todo — see *Invariants* | |
| FIL-38 | 3917 | `reading` reads from an existing file. | — | yes | `gen leaf file round trip` | exercised | |
| FIL-39 | 3918 | `writing` creates **or overwrites** — an existing file is truncated. | write a long payload, reopen for writing, write a short one, assert the resulting size is the short length | yes — both lengths are the generator's | `gen leaf file round trip` opens each path for writing exactly once, so the overwrite half is never reached | exercised (create half); todo (overwrite/truncate half) | |
| FIL-40 | 3919 | `appending` adds to the end of an existing file. | write, then append, assert size is the sum | yes | none (FIL-34) | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-41 | 3922 | Text is used for filesystem paths. | — | yes | `gen leaf file round trip` (`src/gen_files.vox:176–177`, a text variable), `gen leaf stdin read` (a string literal) | exercised | |
| FIL-42 | 3923 | Integers are used for file descriptors. | — | yes | `gen leaf stdin read` (`at 0`) | exercised | |
| FIL-43 | 3924 | Descriptor literals must be in `0..2147483647`; outside that is a compile error. | emit the boundary values 0 and 2147483647; the rejected side cannot be emitted by a fuzzer that must produce compiling programs | boundary-in: yes. Boundary-out: **no** — a generated program that fails to compile is a generator defect, not a finding (`src/loop_gen.vox:290`), so `-1` and `2147483648` must never be emitted. | none emits either boundary | todo (in-range boundary only) | |
| FIL-44 | 3925 | Non-integer, non-text `at` values (`at 1.5`, `at true`) are **compile-time** errors. | — | **no**, for the same reason as FIL-43: this claim can only be checked by a program that must not compile. Recorded as a probe, out of scope for a leaf. | n/a | not assertable (by a generator) | |

Hand-verified boundaries, all four (`FIL-43.vox` keeps the one that
runs; these are the diagnostics for the rest):

- `at 2147483647` → compiles, opens, `descriptor` reads `2147483647`
- `at -1` → `error: File descriptor out of range after 'at': -1. Valid range is 0..2147483647 (0 = stdin).`
- `at 2147483648` → same diagnostic with the value substituted
- `at 1.5` and `at true` → `error: Open path must be either a text path like "/path/to/file" or a file descriptor number (0 = stdin, 1 = stdout, 2 = stderr).`

## Reading (3464–3493)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-45 | 3934–3936 | *(claim reversed, manual 0.4.9 — see Discrepancy 2, resolved)* `Read` **replaces** the buffer's contents with the bytes read; each `Read` continues from the file's current position. The manual used to say "appends" (old 3471); Discrepancy 2 found the compiler replaces and argued the manual was wrong; **the manual was fixed to match the compiler**, not the other way round. | pre-seed a buffer with known bytes, read a known file into it, assert size equals the READ length, not the sum, and that the pre-seeded bytes are gone | yes — this is now a straightforward exercise, not a discrepancy check | `gen leaf file round trip` (`src/gen_files.vox:182`) and `gen leaf stdin read` (`:137`, `:141`) both `Read from` into a **fresh** buffer, where append and replace are indistinguishable — the leaf gap that let the old discrepancy hide is unchanged even though the discrepancy itself is resolved | todo — unblocked; the row's own assertion (pre-seed then compare) is what would put the fixed behaviour on trial | |
| FIL-46 | 3937 | `Read line` **replaces** the buffer with the next line. | pre-seed, `Read line`, assert the pre-seeded bytes are gone | yes | none — `Read line` is emitted by no leaf at all | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| FIL-47 | 3938 | Both `Read` and `Read line` work on files **and** on standard input. | all four combinations | yes | `Read from` on a file (`gen leaf file round trip`) and on stdin (`gen leaf stdin read`); neither `Read line` form | exercised (2 of 4) | |
| FIL-48 | 3943 | `Read from standard input into <buffer>` — the spelled-out `standard input` form. | emit the words `standard input` | yes | **none** — `gen leaf stdin read` reaches stdin by path (`"/dev/stdin"`) or descriptor (`0`), never by the documented `standard input` keyword. Three spellings, and the manual's own is the one missing. | todo | |
| FIL-49 | 3944 | `Read from <file handle> into <buffer>` reads a file. | — | yes | `gen leaf file round trip` (`src/gen_files.vox:182`) | exercised | |
| FIL-50 | 3950 | `Read line from <file handle> into <buffer>` reads one line of a file. | — | yes | none | todo | |
| FIL-51 | 3951 | `Read line from standard input into <buffer>` reads one line of stdin. | — | yes | none | todo | |
| FIL-52 | 3947 | `Read line` reads up to a `\n` **or EOF** — a final line with no newline comes back whole. | write a file whose last line has no newline, assert its length | yes — the generator wrote the file | none | todo | |
| FIL-53 | 3955 | `Read line` **includes** the trailing newline when one is present. | assert the line's size is the text length **+ 1** | yes — this is the assertion that catches an off-by-one either way | none | todo | |
| FIL-54 | 3956 | `Read line` returns an **empty buffer at EOF**, and reaching EOF is not an error. | read past the last line, assert size 0 and that no `On error` fired | yes | none | todo | |
| FIL-55 | 3957 | `Read line` resets buffer contents before **each** read (replace, not append). | two successive `Read line`s, assert the second buffer holds only the second line | yes | none | todo | |
| FIL-56 | 3958 | For a **fixed-size** buffer an overlong line is truncated and the error flag is set. | undersize the buffer relative to a line the generator wrote, wrap in `On error`, assert size == capacity | yes — the generator controls both lengths | none for `Read line`. The equivalent for plain `Read` is exercised probabilistically and unasserted: `gen leaf file round trip` and `gen leaf stdin read` deliberately sometimes undersize the buffer, but neither wraps the read in `On error`, so the flag half is never checked (identical to BUF-09). | todo | |

`Read line` is the single largest untouched construct in this section:
**seven rows (FIL-46, 50, 51, 52, 53, 54, 55), every one assertable,
and not one byte of it is emitted by any leaf.** It is also where the
line-oriented buffer logic lives — reset, newline retention, EOF,
truncation — which is exactly the shape that CLAUDE.md says the fuzzer
exists to attack.

## Seeking (3495–3509)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-57 | 3965 | `Seek <file> to line N` is accepted. | — | yes | **none** — the keyword `Seek` does not appear anywhere in `src/`, in a leaf or otherwise | todo | |
| FIL-58 | 3966 | `Seek <file> to byte N` is accepted. | — | yes | none | todo | |
| FIL-59 | 3967 | `Seek <file> to bytes N` (plural) is accepted, as a synonym of `byte`. | emit both spellings | yes | none | todo | |
| FIL-60 | 3971 | Seek positions are **1-indexed**: `line 1` is the start of the file, `byte 1` is offset 0. | seek to byte 1, read N bytes, assert they are the file's first N | yes — the generator wrote the file | none | todo | |
| FIL-61 | 3972 | `Seek … to line N` moves to the first byte of line **N**. | seek to each line of a file the generator wrote with distinct line lengths, assert the line that comes back | yes — seek to each line and assert the line that comes back; it used to fail for every N ≥ 3, fixed by vox #47 (0.4.8) | none | **todo — unblocked.** D3 is resolved: `D3.vox` now lands on the line asked for. The row stays `todo` because `Seek` still appears in no leaf anywhere in `src/`. | |
| FIL-62 | 3973 | `Seek … to byte N` / `bytes N` moves to byte position N. | seek to a known offset, assert the bytes read | yes | none | todo | |
| FIL-63 | 3974–3975 | Invalid targets — a line past EOF, a position < 1, an invalid descriptor — set the error flag. | each of the three, wrapped in `On error` | yes, all three: position < 1, invalid descriptor, and — since vox #47 (0.4.8) — a line past EOF. | none | **todo — unblocked.** D3 is resolved; `FIL-63.vox` now records all three handlers firing. The row stays `todo` because no leaf emits `Seek`. | |

A byte position past EOF also does not set the flag. The manual does not
claim it should — it names only "line past EOF" — and `lseek(2)` is
explicitly allowed to seek past the end, so this is the compiler being
POSIX-correct on a case the manual is silent about. Recorded here so the
next reader does not file it; hand-verified in `FIL-63.vox`.

## Writing (3511–3519)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-64 | 3985 | `Write "<text>" to <file>` writes a string. | write a known payload, reopen, assert the file's size and content | yes — `If f{n}'s size is not 18 then, Exit 95.` | `gen leaf file round trip` (`src/gen_files.vox:178`), `gen leaf format types` (`src/gen_text.vox:419`) | exercised | |
| FIL-65 | 3986 | `Write <buffer> to <file>` writes a buffer's bytes. | fill a buffer with known bytes, write it, assert the file size | yes | **none** — every generated `Write` has a string literal or a format string as its source; a buffer is never written | todo — real gap | |
| FIL-66 | 3987 | `Write a newline to <file>` writes the special value newline (one byte). | assert the file grew by exactly 1 | yes | none | todo | |
| FIL-67 | 3982 | Lead-in: `Write` takes strings, buffers, or special values. | — | — | — | folded into FIL-64/65/66 | |

Two things a leaf-writer here must know, both hand-verified:

1. **`Write` is unbuffered.** A reader opened in the same program,
   before any `Close`, already sees the bytes (`FIL-89.vox`). So
   "write then assert `h's size`" needs no flush and no close — the
   file handle's `size` property updates live, which makes FIL-64/65/66
   about as cheap to verify as anything in the manual.
2. **A failing `Write` used to be invisible** — see **Discrepancy 4**,
   fixed by vox #48 (0.4.8). `On error` after a `Write` now fires. Reading
   the bytes back or checking `'s size` is still the stronger check and is
   what a *verified* row needs; the difference is that the `On error` route
   is open now, so a leaf can put a handler on a write it expects to fail.
3. **`Write <number/float/boolean variable> to <file>` does not compile.**
   vox #40 (0.4.8) turned that crash into a diagnostic — see
   **Discrepancy 6**. A leaf must emit the rewrite the compiler names,
   `Write "{count}" to output.`, not the bare variable.

## Closing Files (3521–3528)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-68 | 4025 | `Close the <name>.` — the definite-article form — closes the handle. | emit the article form | yes (it compiles or it does not) | **none** — every leaf emits the bare `Close <name>` | todo — see *Invariants* | |
| FIL-69 | 4026 | `Close <name>.` — the bare form — closes the handle. | — | yes | `gen leaf file round trip` (`src/gen_files.vox:179`, `:185`), `gen leaf stdin read` (`:143`), `gen leaf format types` (`src/gen_text.vox:420`) | exercised | |

After a `Close`, a `Read from` the same handle sets the error flag and
returns 0 bytes without crashing (`FIL-68.vox`) — a use-after-close is
safe. That is FIL-101's observable half, and it is a good leaf: reading
a closed handle is precisely the "nonsensical but legal" shape
CLAUDE.md asks for.

## File Operations (3530–3556)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-70 | 4031–4035 | `If "<path>" is available then, …` checks whether a path is available. | emit the check on a path the generator created | yes — the generator knows whether it made the file: `If "…" is not available then, Exit 95.` | **none** — `is available` appears in `src/findings.vox:13` and `src/loop_gen.vox`, both generator-internal; no leaf emits it into a generated program | todo | |
| FIL-71 | 4038 | `is available` compiles to `access(2)` with `F_OK`. | — | **no** — which syscall is used is not observable from inside a Vox program | n/a | not assertable | |
| FIL-72 | 4039–4040 | It works on any path expression: string literal, text variable, or buffer. | emit all three source kinds | yes | none | todo | |
| FIL-73 | 4040–4042 | It is not limited to plain files — a directory and a device node both answer. | check a directory the program made and a device node | yes — a directory the generator created must answer true | none | todo | |
| FIL-74 | 4044–4049 | `is not available` negates the check and is usable as a `While` condition. | emit both the `If … is not available` and the `While … is not available` forms | yes, **but the `While` form needs a guard**: a loop on a path that never appears is an unbounded hang, which the runner would report as a false `hang` finding. Emit it only against a path that already exists, so the body never runs. | none | todo — with the hang caveat above | |
| FIL-75 | 4052–4054 | `Delete the file "<path>".` removes the file. | create, delete, assert it is no longer available | yes | none in a generated program (`src/loop_gen.vox:230` is the generator's own writability probe) | todo | |

Deleting a file that is not there **does** set the error flag
(`FIL-75.vox`) — undocumented, and a good `On error` leaf, since it is a
failure the generator can guarantee.

`is available` is worth a leaf soon for a reason beyond coverage: it is
the only way a generated program can *check its own filesystem
side-effects*, which is what would let a file leaf assert instead of
print.

## Error Handling (3558–3590)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-76 | 4059 | Operations that can fail set an error flag. | — | yes, per operation | the three `On error` leaves: `gen leaf buffer oob` (`src/gen_buffers.vox:26`), `gen leaf list oob` (`src/gen_collections.vox:26`), `gen leaf map oob` (`:57`), `gen leaf environment oob` (`src/gen_misc.vox:107`) | exercised | |
| FIL-77 | 4063–4067 | `On error` after a specific operation reports whether **that** operation failed. | — | yes | as FIL-76 | exercised | |
| FIL-78 | 4071 | Out-of-bounds list **and** buffer access are catchable. | — | yes | `gen leaf list oob`, `gen leaf buffer oob` | exercised | |
| FIL-79 | 4072 | Fixed buffer overflow (data exceeds capacity) is catchable. | undersize a buffer against a known input, wrap the read in `On error`, assert the handler fired | yes | **none** — the two leaves that undersize a buffer (`gen leaf file round trip`, `gen leaf stdin read`) do not wrap their `Read` in `On error`, so the overflow is provoked but never caught. Same gap as BUF-09. | todo | |
| FIL-80 | 4073–4075 | File operation failures are catchable. | force an open of a path that cannot exist, assert the handler fired | yes — the generator can name a path under its own scratch directory that it did not create | none — no leaf puts `On error` on a file operation | todo. **Note: this claim used to be true only of `open`, `Read line`, `Seek` and `Delete`, and false of `Write` (D4) and of `Read from` against a failed handle (D5). vox #48 (0.4.8) fixed both, so as of 0.4.8 the claim holds for every file operation probed here.** | |
| FIL-81 | 4079–4082 | An `On error` handler takes a comma-joined list of actions, and `exit N` inside one exits with that code. | emit a multi-action handler | **no, not with `exit`** — vox-fuzz reserves 90–99 and reads every other exit code as the program's own; a leaf that exits from a handler makes the run unclassifiable. Emit the multi-action form with two prints instead. | none — every generated handler is a single `print` | todo (multi-action form only, no `exit`) | |
| FIL-82 | 4084–4086 | Pattern: `element 100 of mylist` guarded by `On error`. | — | — | `gen leaf list oob` | folded into FIL-21/FIL-22 | |
| FIL-83 | 4088–4090 | Pattern: detect truncation by hand with `If buffer's size is equal to buffer's capacity then, …`. | emit the comparison after a read that may truncate | yes | **none** — `'s capacity` is read by no leaf anywhere (the buffers ledger found the same at BUF-10) | todo | |

**Undocumented, and it changes how every `On error` leaf must be
written:** a flag no handler consumes stays set, and is then reported by
the *next* handler — but a **successful** operation clears it first
(`FIL-76.vox`). So `On error` means "did the previous statement fail, or
did an earlier one fail with nothing successful in between". The
practical rule for a leaf: put the handler immediately after the
operation it is about, which the leaves already do, and never assume a
handler that fired blames the statement above it if that statement
cannot set the flag at all.

## Resource Safety (3592–3654)

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| FIL-84 | 4095 | `vox` provides memory safety through automatic resource management. | — | **no** as stated — it is the chapter's thesis, discharged by FIL-85 through FIL-101 | n/a | not assertable (composite thesis) | |
| FIL-85 | 4101 | No buffer overflows: buffers grow dynamically as needed. | read a file far larger than any initial reserve into a dynamic buffer, assert size == file size | yes — the generator wrote the file | none — every append/copy/read destination in the existing leaves is a **fixed**-size buffer; a genuinely unsized buffer is never a read target (same gap as BUF-36) | todo | |
| FIL-86 | 4102 | No use-after-free: resources are tracked and cleaned at exit. | use a closed handle and a double-closed handle, assert neither crashes | the *no-crash* half: yes. The *tracking* mechanism: no. | none | todo (observable half) | |
| FIL-87 | 4103 | No resource leaks: all FDs and buffers are cleaned up automatically. | — | **no** — a leak is by definition invisible to the leaking program; there is no channel to observe it from inside Vox | n/a | not assertable | |
| FIL-88 | 4104 | No manual memory management — the compiler handles allocation and deallocation. | — | **no** — the absence of a language feature; nothing to emit | n/a | not assertable | |
| FIL-89 | 4106–4114 | All resources are cleaned up on exit, **even if you forget to `Close`** (worked example). | exit with an open handle and an un-freed buffer; assert the process exits 0 and the bytes reached disk | yes — the exit code and the written bytes are both knowable | none — every leaf that opens a handle also closes it, so the forgot-to-close path is never generated | todo — real gap, and the manual's own example | |
| FIL-90 | ? | Buffers start at **zero capacity** and grow automatically; no size specification is needed. | declare an unsized buffer, assert `'s capacity is 0` | yes, and it **fails**: capacity reads 4096 | none | blocked — **this is the buffers ledger's Discrepancy 1, restated by this section's own text.** `FIL-91.vox` reproduces it (first output line: `4096`). Not re-opened here; it belongs to that adjudication. | |
| FIL-91 | 4121–4123 | `a buffer called inputbuf.` then `Read from source into inputbuf.` is safe regardless of file size. | read a large file into an unsized buffer, assert no error and full size | yes | none (FIL-85) | todo | |
| FIL-92 | 4126–4128 | Internal structure: 8 bytes capacity, 8 bytes length, N bytes data. | — | **no** — a memory layout with no Vox-level introspection to observe it | n/a | not assertable | |
| FIL-93 | 4134 | On open, the FD is registered in a tracking table. | open many handles without closing, assert none is reused and nothing crashes | the *registration* itself: no. Its consequence — no descriptor is recycled while a handle is live — **yes**, and it scales: 100000 unclosed opens, last descriptor 100002, exit 0 (`FIL-93.vox`) | none | todo (consequence only) | |
| FIL-94 | 4135 | On close, the FD is unregistered from the table. | — | **no** — the table is not observable | n/a | not assertable | |
| FIL-95 | 4136 | On exit, all remaining FDs are closed. | — | **no** — the program is gone by then; nothing inside Vox can observe it. (Note this is *not* discharged by the bytes being on disk: `Write` is unbuffered, so the data is there whether or not the FD was released.) | n/a | not assertable | |
| FIL-96 | 4138–4145 | It works correctly with **conditional** file operations — an `open` inside an `If` whose `Close` is forgotten. | emit an open inside a conditional branch with no close | yes (exit 0, bytes on disk) | none — every generated `open` is unconditional and paired with a `Close` | todo — real gap | |
| FIL-97 | 4151 | Safety-vs-C: buffer overflow is impossible, buffers auto-grow. | — | — | — | folded into FIL-85 | |
| FIL-98 | 4152 | Safety-vs-C: a forgotten close is not a leak — auto-closed on exit. | — | — | — | folded into FIL-87/FIL-89 | |
| FIL-99 | 4153 | Safety-vs-C: a forgotten free is not a leak — auto-freed on exit. | — | — | — | folded into FIL-89 | |
| FIL-100 | 4154 | Safety-vs-C: double free is tracked and cannot happen. | close the same handle twice, assert no crash and no error flag | yes — hand-verified: a double `Close` neither crashes nor raises | none | todo | |
| FIL-101 | 4155 | Safety-vs-C: use after free is not possible by design. | read and write a closed handle, assert no crash | yes for the no-crash half. Note the two halves disagree: a **read** of a closed handle sets the error flag, a **write** does not (D4). | none | todo | |
| FIL-102 | 3976–3978 | *(new row, added 2026-08-22 per the master's brief)* Line `N` exists when the file holds at least `N-1` newlines before it — a file that ends in a newline has one empty last line to seek to; anything beyond that is past EOF and sets the error flag. This is the new precision Discrepancy 3's fix (vox #47) brought into the manual alongside the seek fix itself, at what was old-numbering 3603–3605 and is now 3690–3692. | write a file with a known newline count, seek to line `newlines+1` (should exist, empty, no error) and to line `newlines+2` (should error), assert both | yes — the generator wrote the file and knows its newline count | none — `Seek` appears in no leaf (FIL-57/61/63) | todo — hand-verified in `FIL-102.vox`: a 2-newline file lands line 3 at size 0 with no error, and errors on line 4 | |
| FIL-103 | 3990–4008 | *(new row, added 2026-08-22)* `Write` takes a text, a buffer, or a format string; a bare number/float/boolean **or a `value`** is a compile-time error, not a runtime crash — new manual prose written to document the vox #40 fix (Discrepancy 6). A scalar's error names the exact rewrite (`Write "{count}" to output.`); a `value`'s error says to copy it into a typed variable first. | emit both rejected forms as compile-error probes (a leaf cannot emit them as running programs — see FIL-44's reasoning) | **no**, for the same reason as FIL-43/FIL-44: a fuzzer must never emit a program that fails to compile | n/a | not assertable (by a generator) — hand-verified in `FIL-103.vox` (the `value` half; the scalar half is already `D6.vox`) | |

---

## Discrepancies

**Adjudicated by the language lawyer, 2026-08-20.** Line numbers in this ledger are from the pre-#42 manual and are now **9 low** (e.g. `exists` row is 3346, "Read appends" is 3480, seek rules 3516/3518, write source 3522, catchable errors 3583); re-pin on the next manual version.

Recorded, not adjudicated. Each has a runnable repro in
`docs/ledger/probes/files/`, the lines it contradicts, and the
strongest reading under which the compiler is right. **None has been
filed and none should be, until the lawyer and Josj have seen them.**

### 1. The documented `exists` file property does not parse — RESOLVED

**Resolution confirmed, 2026-08-22.** `vox/docs/BUGS_FOUND.md` #38 is
**fixed** (status: fixed, closed 2026-08-21): the table row was removed
(option 3 of 3, Josj's ruling — not option 1 "implement it" or option 2
"move it to a path predicate"), and the current manual (5327 lines) no
longer lists `exists` anywhere in the File Properties table; it instead
documents the `On error`-around-`open` idiom at 3504–3525, with a
worked example covering both an existing and a missing path, and notes a
path-level `exists` predicate as a planned future addition. The old
citation below (old manual line 3337) is preserved as the historical
record of what the discrepancy was found against; FIL-08 above is now
`withdrawn`, not `blocked`.

`D1.vox`. Old manual line 3337 (pre-0.4.9 manual) listed `exists` in the File Properties table
(`Whether the file exists`, `Boolean`). Repro:

```
open a file for reading called src at "vf_scratch/files/lines.txt".
print src's exists.
```

```
error: Expected property name, got Exists
  --> …:2:13
    |
  2 | print src's exists.
    |             ^--- here
```

Seven of the eight properties in that table work; this one is not known
to the parser at all. This is the red team's bug **#38**, which
`src/gen_files.vox:57` already records ("`exists` is a parse error") —
so it is a **known** gap, listed here because the row has to exist and
because #38 is evidently still open in 0.4.7 while #37 in the same
comment is fixed.

**Reading in which the compiler is correct:** `is available`
(LANGUAGE.md:4038) is described as "the correct, **current** form of
this check", which is language the manual uses for a form that
superseded another. If `exists` was deliberately retired in favour of
`is available`, the compiler is right and the File Properties table is
stale — a manual bug, not a compiler bug. That reading is strengthened
by `exists` being the only property in the table that is a question
about the *path* rather than about the *open handle*, which is exactly
the thing `is available` answers.

**Resolution (lawyer): MANUAL BUG, high — bug #38 confirmed open.** `exists` is a reserved token (`If the environment variable "X" exists`) with no `ObjectProperty` variant on any path; an open handle does not retain its path, so a handle-side `exists` is not implementable without new state, while `is available` (:3548, `access(2)`) answers exactly that question. Lawyer recommends deleting the table row and cross-referencing `is available`. **Awaiting Josj** (design call recorded in #38).

### 2. `Read from … into …` replaces the buffer; the manual says it appends

`D2.vox`. LANGUAGE.md:3752: "`Read` appends incoming data to the buffer
and is best for bulk/stream processing" — stated as the explicit
contrast against 3472, "`Read line` **replaces** the buffer with the
next line". Repro: a buffer holding 4 bytes with room for 124 more,
read a 17-byte file into it.

```
a buffer called sink is 128 bytes in size.
append "PRE-" to sink.
print sink's size.          (4)
Read from source into sink.
print sink's size.          (17, not 21)
print sink.                 (the file's bytes; no "PRE-" prefix)
```

The dynamic-buffer form behaves identically (also in `D2.vox`), so this
is not fixed-buffer truncation. Two successive `Read from`s on one
handle also replace rather than accumulate: the second read's bytes
overwrite the first's.

**Reading in which the compiler is correct:** "appends" may be meant
*relative to the incoming stream*, not to the destination — i.e. each
read continues from where the last one left off in the **file**
(appending to what has been consumed) rather than restarting, which is
true and is the real contrast with `Read line`'s per-line rewind. On
that reading the sentence is about the file position and 3471 is merely
worded in a way that invites the destination-buffer reading. Against it:
the sentence's object is "the buffer", and 3472 uses "replaces the
buffer" for the same grammatical slot to mean the destination. If the
compiler is right, 3471 needs rewording; if the manual is right, this is
a behavioural bug in every `Read from` in the language.

**This one matters more than it looks.** `gen leaf file round trip` and
`gen leaf stdin read` both read into a **fresh** buffer, where the two
readings are indistinguishable — so the fuzzer has never been able to
tell, and would not have found this.

**Resolution (lawyer): MANUAL BUG, high.** codegen/statements.rs:2100 resets the buffer length before reading under the comment "read replaces, not appends", and tests/runtime/b340_pipe_exact_fit.asm asserts it; no other manual sentence depends on append (the `data's full` truncation idiom requires replace). Fix :3480's sentence → vox docs (bundled with the #47/#48 fix branch).

**Resolution confirmed, 2026-08-22: fixed in the manual, not the compiler.**
The current manual (5327 lines) at LANGUAGE.md:3934–3936 now reads: "`Read`
replaces the buffer's contents with the bytes read; each `Read` continues
from the file's current position, so it is best for bulk/stream
processing." — exactly the lawyer's recommended fix. `D2.vox`'s own
recorded output (`17`, not `21`; no `"PRE-"` prefix) is what the manual
now documents rather than contradicts. FIL-45 above is updated to state
the corrected claim.

### 3. `Seek … to line N` lands on line 2 for every N ≥ 2, and a line past EOF does not set the error flag — RESOLVED (vox #47)

`D3.vox`. Two claims broke together. LANGUAGE.md:3972 (was 3507 at the
manual version this was found against): "`Seek … to line N` moves to the
first byte of line `N`". LANGUAGE.md:3974–3975 (was 3509): "Invalid
targets (e.g. line past EOF, position < 1, invalid fd) set the error
flag."

File: `AA\nBBBB\nCCCCCC\nDD\nEEEEEEEE\n` — five lines, all different
lengths, so the landing line is unambiguous.

```
line 1  -> AA
line 2  -> BBBB
line 3  -> BBBB      (should be CCCCCC)
line 5  -> BBBB      (should be EEEEEEEE)
line 99 -> BBBB      (past EOF; should set the error flag, and does not)
```

`line 1` is right and `line 2` is right; **every** target above 2 lands
at the start of line 2. It is absolute, not relative — seeking twice
gives the same place. `Seek … to byte N` is correct throughout
(`FIL-57.vox`), so this is specific to the line form.

**Reading in which the compiler is correct:** I cannot construct one for
the wrong-offset half. The closest is that the implementation scans for
newlines from the current position and the seek is meant to be *relative*
("advance to the next line"), under which `line 2` would mean "one line
forward" — but then two consecutive `Seek to line 2` calls would advance
twice, and they do not, and `line 1` would not rewind to offset 0, and it
does. For the error-flag half there is a real reading: `lseek(2)` past
EOF is legal, so if `to line N` clamps rather than fails, not raising is
consistent with the byte form and 3509's "line past EOF" is simply
describing an intent the implementation does not have. That reading
survives; the wrong-offset one does not.

**Resolution (lawyer): COMPILER BUG, very high — vox bug #47.** `coreasm/x86_64/resource.asm:547` `_seek_fd_line` keeps its line counter in `rcx` across a `syscall`, which clobbers rcx, so the scan stops at the first newline and never reaches EOF (hence no error for line 99 — EOF detection exists, T3 single-line file does set the flag). One-register fix (`rbx` is pushed and free). x86_64 only; other arches have no routine at all.

**Resolution: fixed by vox #47 (0.4.8).** Re-run against current main,
`D3.vox` prints `line 3 -> CCCCCC` and `line 5 -> EEEEEEEE` — each seek
lands on the line asked for — and the seek to line 99 raises the flag, so
the handler fires and the read that follows returns nothing. Both halves of
the discrepancy are gone; both probes (`D3.vox`, `FIL-63.vox`) were
re-recorded on 2026-08-21.

**Both things this note used to flag as unmapped are now mapped
(2026-08-22 re-pin).** The seeking rules are at LANGUAGE.md:3962–3979 in
the current (5327-line, 0.4.9) manual, and the new bullet defining
exactly when line `N` exists is at 3690–3692 — "the file holds at least
`N-1` newlines before it, so a file that ends in a newline has one empty
last line to seek to". That claim now has its own row, **FIL-102**,
hand-verified in `FIL-102.vox`. A byte position past EOF still does not
set the flag, which remains correct (see the note under FIL-63).

### 4. A failing `Write` never sets the error flag — RESOLVED (vox #48)

`D4.vox`. LANGUAGE.md:4073 (was 3574) lists "File operation failures" among the
catchable errors. Four distinct write failures, none caught:

```
Write "one"   to <a handle opened at descriptor 2147483647>   (not caught)
Write "two"   to <a handle opened for READING>                (not caught)
Write "three" to <a handle whose open failed>                 (not caught)
Write "four"  to <a handle that was closed>                   (not caught)
```

The only handler that fires in the whole program belongs to the failed
`open`. `open`, `Read line`, `Seek` and `Delete` all set the flag on
failure; `Write` never does, in any of the four modes tested. So from
inside Vox, **a write that did not happen is indistinguishable from one
that did**.

**Reading in which the compiler is correct:** 3574's "file operation
failures" may be scoped by the surrounding section, whose every example
is a *read* (3567, 3580) — the chapter is titled around `Read from …
On error`. On that reading `Write` was never claimed to be checkable and
the manual is merely silent, not wrong. Silence is still a problem for a
language that promises resource safety, but it makes this a
documentation gap rather than a broken promise.

**Consequence for leaf-writing, regardless of the verdict:** a file leaf
cannot use `On error` to confirm a write. It must read the bytes back or
assert `h's size` — which, happily, works and is live (FIL-64).

**Resolution (lawyer): COMPILER BUG, medium-high — vox bug #48.** `FILE_WRITE_STR/BUF/NEWLINE` (coreasm/x86_64/file.asm:243/285/305) pop straight over rax; `Statement::FileWrite` never touches `_last_error`. Strengthened repro: `Write` to `/dev/full` (real ENOSPC on a valid handle) is uncatchable. Violates :3583 (now 3773 — "Operations that can fail... set an error flag").

**Resolution: fixed by vox #48 (0.4.8).** Re-run against current main, all
four failure modes in `D4.vox` raise the flag and every `On error` fires: an
invalid descriptor, a read-only handle, a handle whose open failed, and a
closed handle. A write that did not happen is now distinguishable from one
that did. The probe was re-recorded on 2026-08-21, and its closing marker —
which used to read "not one of the four failing writes set the error flag" —
now reads "survived all four failing writes".

**Confirmed still fixed on 0.4.9, and now spelled out in the manual
itself, 2026-08-22.** LANGUAGE.md:4073–4075 (Catchable Errors) now reads:
"File operation failures — opening, seeking, reading, writing and
deleting alike. A failed `Write` sets the flag, and so does a `Read
from`, a `Read line from` or a `Write` on a handle whose own `open`
failed." — the manual has caught up to the #48 fix in prose, not just in
behaviour.

**The leaf-writing consequence above is withdrawn.** `On error` after a
`Write` now works, so a file leaf may use it to confirm a write. Reading the
bytes back or asserting `h's size` (FIL-64) is still the stronger check and
is still what a *verified* row wants; the point is that the `On error` route
is no longer closed.

### 5. `Read from` and `Read line from` disagree about a dead handle — RESOLVED (vox #48)

`D5.vox`. A failed `open` leaves the handle with descriptor `-2`. Against
that handle:

```
Read from missing into chunk.       On error -> does NOT fire; 0 bytes
Read line from missing into chunk.  On error -> FIRES
```

Against a descriptor that is merely invalid rather than negative
(`2147483647`), **both** fire. So `Read from` treats a negative
descriptor as a silent EOF and a positive-but-invalid one as an error,
while `Read line from` treats both as errors.

**Reading in which the compiler is correct:** a negative descriptor is
not a descriptor at all but a stored errno, so `Read from` may be
short-circuiting on "there is nothing here to read" and reporting the
truthful answer — zero bytes — rather than a second, redundant error for
a failure the `open`'s own handler was already offered. That is defensible
in isolation. It is harder to defend that `Read line` on the identical
handle disagrees. The manual says nothing about either, so the honest
description is *undocumented and internally inconsistent* rather than
*wrong*.

**Resolution (lawyer): COMPILER BUG, medium — folded into #48.** `FileRead` (statements.rs:2093-2106) skips a negative fd setting nothing; `FileReadLine` (2109-2138) sets `_last_error` on the same jump. One missing line.

**Resolution: fixed by vox #48 (0.4.8).** Re-run against current main,
`Read from` a failed handle sets the flag, so the two verbs now agree in
both directions: negative descriptor and positive-but-invalid descriptor
each raise for `Read from` and for `Read line from` alike. The buffer is
still left at size 0 by a dead read, which is the truthful answer and was
never the complaint. `D5.vox` was re-recorded on 2026-08-21.

### 6. `Write <scalar variable> to <file>` segfaults — bug #40 is not fixed in 0.4.7 — RESOLVED (vox #40, 0.4.8)

`D6.vox`. The brief states that vox bug #40 ("`Write` of a scalar
segfaults") is fixed in 0.4.7 and that the probes should show the fixed
behaviour. Against `vox v0.4.7` at
`/home/josj/scr/english/vox/target/release/vox` it still reproduces:

```
a number called count is 42.
open a file for writing called output at "vf_scratch/files/scalar.txt".
Write count to output.
Close output.
```
```
Segmentation fault (core dumped)          (exit 139, signal 11)
```

Characterised:

| source | result |
|---|---|
| a `number` variable | **segfault** |
| a `float` variable | **segfault** |
| a `boolean` variable | **segfault** |
| a `text` variable | fine |
| a buffer | fine |
| a scalar **literal** (`Write 42 to output.`) | `error: Expected value to write` — rejected at compile time |

So the compile-time guard exists but only catches the literal form; a
variable of the same type walks straight through to the crash.

**Reading in which the compiler is correct:** LANGUAGE.md:3982 (was 3513) says
`Write` takes "strings, buffers, or special values". A Number is none of
those, so the *program* is outside the documented language and the
compiler owes it nothing in particular — and the parser evidently agrees,
since it rejects the literal form outright. Under that reading the bug is
narrow: not "`Write` of a scalar should work" but "the check that already
rejects `Write 42` should also reject `Write count`", which would make
this a missing diagnostic rather than a semantics question.

**That reading does not rescue the segfault.** CLAUDE.md is explicit:
"no program, however stupid … should segfault", and "every signal death
is a top-severity finding — a broken promise about the language's
headline property". Whether the program is sensible is not the bar;
whether it is *legal Vox that compiles* is, and it compiles. **This is
the most severe thing in this ledger.**

Two things follow for the generator, and they pull in opposite
directions, which is why this needs Josj and not a worker:

- `src/gen_files.vox:196–199` currently avoids `Set byte`/`Write`
  because of #40. That comment is still accurate and the workaround must
  stay until this is resolved.
- A leaf that emits `Write <number variable> to <file>` would find this
  bug on its first campaign. It is a two-line leaf. Whether to add it now
  or after the fix is a triage call, not a mapping call.

---

**Resolution (lawyer): COMPILER BUG, top severity — bug #40, fix in flight (vox-40 worker).** The parser guard (parser/io.rs:447-459) filters token CLASS not type (StringLiteral/Identifier only), so a Number variable reaches `FILE_WRITE_STR` and is dereferenced as a pointer; the fix is a type check at codegen/statements.rs:2219-2234's else-branch, not a parser change.

**Resolution: fixed by vox #40 (0.4.8).** The segfault is gone, and it was
closed the way the pro-compiler reading above predicted — by extending the
guard rather than by making the write work. `D6.vox` no longer compiles:

```
error: Cannot write number count to a file; Write takes text, a buffer, or a
format string. Render it as text: Write "{count}" to output.
```

A `float` and a `boolean` variable are refused the same way. The probe was
re-recorded as a compile-error probe on 2026-08-21.

**Both consequences for the generator are settled by this.** The `#40`
workaround comment at `src/gen_files.vox:196–199` is now stale and the
avoidance it describes can be lifted; and the two-line leaf that would have
emitted `Write <number variable> to <file>` must **not** be written — the
program no longer compiles, so it would only produce build failures. What a
leaf *can* now emit is the rewrite the diagnostic names,
`Write "{count}" to output.`, which is a real FIL-64 case with a
generator-known payload.
## Invariants this section justifies

Samenesses in the corpus that LANGUAGE.md actually **requires** in this
area, and may therefore be cited in the `scripts/invariants` report:

- a file handle is named by `called <name>` in every `open` — LANGUAGE.md:3893, FIL-32
- an `open` names exactly one of `reading` / `writing` / `appending` — LANGUAGE.md:3917–3919, FIL-38/39/40
- the `at` value is always either a quoted path or a bare integer, never a float, boolean or bare word — LANGUAGE.md:3922–3925, FIL-41/42/44
- a descriptor literal is always within `0..2147483647` — LANGUAGE.md:3924, FIL-43
- `Read`/`Read line` always names a destination buffer with `into` — LANGUAGE.md:3934–3951, FIL-45/46
- list and seek positions are never 0 or negative in a *valid* access — LANGUAGE.md:3830 and 3685, FIL-16 and FIL-60 (an OOB leaf may of course emit them deliberately; that is the claim under test, not a violation)
- an `On error` handler always follows the operation it is about, never precedes it — LANGUAGE.md:4063–4067, FIL-77
- `Delete the file` always takes a path expression, never a file handle — LANGUAGE.md:4054, FIL-75

**Samenesses this section does NOT justify** — every one is a current or
latent defect and needs either a citation from elsewhere or a fix:

| invariant in today's corpus | verdict |
|---|---|
| every `open` uses the clause order `for <mode> called <name> at <path>` | **defect** — LANGUAGE.md:3908 explicitly permits any order and shows three permutations (FIL-37) |
| every `Close` uses the bare form, never `Close the <name>` | **defect** — LANGUAGE.md:4025 shows the article form first (FIL-68) |
| every list read is `element 1` | **defect** — no rule fixes the index; `src/gen_collections.vox:15` and `src/gen_text.vox:411` both hard-code `1` (FIL-17) |
| every file is opened exactly once per path, and always closed | **defect** — LANGUAGE.md:4108–4114 and 3852–3859 make the forgot-to-close and the reopen-to-overwrite paths documented, supported behaviour (FIL-39, FIL-89, FIL-96) |
| no generated program ever contains `Seek`, `Read line`, `is available`, `Delete the file`, or `for appending` | **defect** — five documented constructs at literally zero emission (FIL-34, FIL-46, FIL-57, FIL-70, FIL-75) |
| every `Write` source is a string or format string | **defect** — LANGUAGE.md:3986–3987 documents buffer and newline sources (FIL-65, FIL-66) |
| every stdin read reaches stdin by `"/dev/stdin"` or `0`, never by `standard input` | **defect** — LANGUAGE.md:3943 is the manual's own spelling (FIL-48) |
| every `On error` handler is a single `print` | **defect** — LANGUAGE.md:4082 shows a comma-joined multi-action handler (FIL-81) |

---
- the identifiers `ASSERT`, `expected`, `got` and the row prefix `FIL` appear in every program that draws an asserting leaf — PROCEDURE.md §6 (the ledger assertion line `ASSERT <ID>: expected <x> got <y>`), a procedure rule rather than a LANGUAGE.md one; the invariants report may cite §6 for these three words and the prefix (added 2026-08-29, leaves merge)

## Report

**Updated 2026-08-22.** **103 rows** (FIL-01 … FIL-103 — FIL-102 and
FIL-103 added this pass, see above) across four property subsections and
six prose sections. Five (FIL-67, FIL-82, FIL-97, FIL-98, FIL-99) are
cross-references folded into a sibling rather than fresh leaf needs, and
one (FIL-08) is **withdrawn** — the manual dropped the claim rather than
the compiler implementing it — leaving **97 distinct claims**.

- **88 are assertable** — the generator can predict the exact result and
  emit a failing-exit check (this count is unchanged from the original
  101-row pass: FIL-08 leaving the assertable pool and FIL-102 joining it
  cancel out).
- **9 are not assertable**: the original eight — FIL-71 (which syscall is
  used), FIL-84 (the chapter's thesis, discharged by its own
  subsections), FIL-87 (a leak is invisible to the leaker), FIL-88 (the
  absence of a feature), FIL-92 (memory layout), FIL-94 (the FD tracking
  table), FIL-95 (post-exit behaviour), and FIL-44 — plus the new
  FIL-103, all for the same reason: a fuzzer must never emit a program
  that fails to compile (`src/loop_gen.vox:290`), so a compile-error
  claim is out of a generator's reach by construction. FIL-43's
  out-of-range half is unreachable for the same reason, though its
  in-range boundary is not.
- **1 is still blocked on an open discrepancy**: FIL-90, which is the
  *buffers* ledger's Discrepancy 1 (dynamic buffer capacity 4096 vs.
  documented "zero") restated by this section's own text at
  LANGUAGE.md:4118, and belongs to that adjudication, not a new one —
  re-probed against vox 0.4.9 (see `buffers.md`), still open, still a
  design question for Josj, not yet a numbered fix.

**All six of this ledger's own discrepancies (D1–D6) are now resolved**,
re-confirmed against vox 0.4.9 and against the current (5327-line)
manual text: D1 and D2 by a **manual** fix (the false claim was removed
or corrected, not the compiler changed); D3, D4, D5 and D6 by a
**compiler** fix (#47, #48, #48, #40 respectively) that the manual has
since caught up to in prose as well as behaviour (see the Catchable
Errors and Write sections). FIL-08 and FIL-45, previously blocked on
D1/D2, are now withdrawn and unblocked respectively; FIL-61 and FIL-63
were already unblocked in the 0.4.8 refresh.

**By status at this re-pin: 20 `exercised`, 66 `todo` (65 + FIL-102), 9
`not assertable`, 1 `blocked` (FIL-90), 5 `folded`, 1 `withdrawn`
(FIL-08). Nothing is `verified`.**

**43 probes, all re-run clean twice** — once from a wiped
`vf_scratch/`, once with it populated.

### The biggest finding

*(Resolved: vox #40 landed in 0.4.8 and this no longer reproduces — see the
`Resolution:` line on Discrepancy 6. The account below is the finding as it
stood when this ledger was written.)*

**`Write <number variable> to <file>` segfaults on vox 0.4.7**
(Discrepancy 6). The brief says bug #40 is fixed; it is not. Number,
float and boolean all die on signal 11; text and buffer are fine; the
scalar *literal* form is caught at compile time, so only the variable
form reaches the crash. Under CLAUDE.md this outranks everything else in
this ledger by category, not by degree: it is a memory-safety violation
in a language whose headline promise is memory safety, reachable from a
four-line program that compiles without a warning.

The runner-up is **Discrepancy 2** — `Read from` replaces the
destination buffer where the manual says it appends. It is quieter but
structurally worse for us: both existing read leaves read into a *fresh*
buffer, where append and replace are indistinguishable, so the fuzzer
has been unable to see this since the day it was written. That is the
signature of a leaf that emits a construct without putting its claim on
trial, and it is the argument for the whole ledger exercise in one row.

### Advice for the next mapper

1. **The "no leaf asserts anything" pattern is generator-wide, not
   per-section.** The buffers ledger suspected it; this section confirms
   it by `grep`: the only assertions in all of `src/` are the four argv
   checks at `src/gen_misc.vox:316–321`. Stop re-discovering it. State it
   once in the header and spend the effort on the `assertable?` column,
   which is where the value is — a row that names the exact assertion
   (`If f{n}'s size is not 18 then, Exit 95.`) is a leaf brief; a row
   that says "yes" is homework for someone else.

2. **Check whether a leaf is actually dispatched, not just whether it
   exists.** `gen leaf file write` (`src/gen_files.vox:91`) emits four of
   this section's eight file properties and is the obvious `grep` hit for
   `'s descriptor`, `'s writable`, `'s permissions` — and it is **dead**,
   parked at kind 99 outside every draw (`src/gen_core.vox:578–582`).
   Reading it as coverage would have marked four rows `exercised` that no
   generated program has ever contained. Always follow the leaf name back
   to the `If kind is N then,` dispatch and check N is in the drawn range.

3. **Probes should build their own world.** The buffers ledger keeps a
   `fixtures/` directory its probes read from, which makes them
   order-dependent and repo-relative. Every probe here writes its own
   input into `vf_scratch/files/` first, so any probe can be run alone,
   in any order, twice in a row. It costs three lines per probe and it is
   why `43 clean, 0 mismatched` could be run as a single command.

4. **Watch for one probe's fixed buffer silently truncating another
   claim.** `FIL-57` first read `alpha\n` into a 5-byte buffer and
   reported size 5, which looks exactly like a newline-retention bug and
   is not one — the buffer was full. When a size comes back one short,
   check the capacity before you write the discrepancy.

5. **`Sleep` and `While … is not available` are hang hazards.** The
   manual's own example for FIL-74 is an unbounded wait loop. Any leaf
   built from it must be guarded so the body never runs, or the runner
   will report a false `hang` on every such program — the same trap
   `src/gen_files.vox:45–53` records for stdin reads.

### Two things outside this section that the master should look at

Neither is mine to fix (the brief forbids touching `src/`), and neither
is a compiler question, so they are not Discrepancies:

1. **`gen leaf format types` still writes to `/dev/stdout`.**
   `src/gen_text.vox:418` emits `open a file for writing called gh{n} at
   "/dev/stdout"`, and it is **live** — kind 42, inside the drawn range
   (`src/gen_core.vox:589–590`). That is the exact target
   `src/gen_files.vox:62–89` disabled `gen leaf file write` for, because
   an independent file description on a redirected stdout gives the child
   its own offset and leaves a sparse NUL hole in the harness's captured
   output (it turned `tests/060_loop_gen.expected` binary). The
   reasoning that killed one leaf appears not to have been applied to the
   other. I have not verified that it currently corrupts anything — only
   that the construct the comment describes as unsafe is still being
   emitted.

2. **`docs/check-probes.sh` does not exist** in this worktree or in the
   buffers one, though PROCEDURE.md §4 makes it an acceptance gate
   ("a ledger whose probes do not re-run clean is not accepted"). The
   four special cases this section needs are listed under *Probes*
   above; a plain stdout diff will report five false failures on a clean
   directory.
