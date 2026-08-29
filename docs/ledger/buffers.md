# Claim ledger: File I/O → Buffers

Source: `../vox/LANGUAGE.md` lines 3513–3801 (File I/O § Buffers, through
Object Properties, Buffer Properties, Buffer Resizing, Buffer Byte
Access, Buffer Append and Copy).

**Re-pinned 2026-08-23** to Vox 0.4.10 (`LANGUAGE.md`, 5545 lines, vox
`527cb89`, previously b557ae5/5611) — every `line` cell above was re-derived by searching the
current manual text for the claim's sentence, not by adding an offset to
the old (5112-line) citation. The section itself now runs 3285–3480, not
3139–3324; the drift grows from +144 lines at the top of the section to
+156 at the bottom because of insertions earlier in the manual (0.3.0's
identifier/literal split docs, the `value` type, function-parameter
sections) unrelated to buffers itself.

This is a **gap analysis**, not a from-scratch map. `src/gen.vox` already
has 47 leaves. `existing leaf` names the leaf that already emits the
construct, or `none`. `status` is `exercised` (a leaf emits the
construct and the program must not crash) or `todo` (nothing does).
**No existing buffer leaf currently emits an assertion** — every one
either `Print`s a value for a human to eyeball, or catches an error and
prints a fixed string — so nothing in this document is marked
`verified` under the brief's definition (construct emitted AND
documented result asserted). That gap is uniform across the whole
section and is the main finding, not a per-row surprise.

Every row below was hand-run against the real compiler
(`/home/josj/scr/english/vox/target/release/vox`, `VOX_CORE_PATH` set to
the sibling `coreasm`) before being written. The Discrepancies section
gives minimal repros for the three that matter most.

**Addition, 2026-08-29 (Vox 0.4.14, `4995394`): rows BUF-40 through
BUF-54.** 0.4.14 added a whole new `#### Releasing a Buffer` subsection
(LANGUAGE.md:3645–3754, `Free`/`Release`/`Deallocate`) inside this
ledger's existing 3488–3761 range — the range itself did not move, so
every row above (BUF-01–BUF-39) keeps its citation unchanged. Hand-run
against the installed 0.4.14 binary (`/usr/bin/vox`, `VOX_CORE_PATH`
`/usr/share/vox/coreasm`). One new discrepancy: **Discrepancy 4**, "A
list also accepts `Free`" has no observable effect on the list at all
(length/contents/error-flag all unchanged). `grep` on `Free \|Release
\|Deallocate ` across `src/gen_*.vox` confirms no leaf emits any of the
three spellings yet, so every new row is `existing leaf: none`.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/buffers/`, one file per row named `BUF-NN.vox`
(a probe covering more than one row is named for the first and says so
in its own header comment — e.g. `BUF-26.vox` also covers BUF-27;
`BUF-41.vox` also covers BUF-42; `BUF-43.vox` also covers BUF-44 and
BUF-45).
Each file opens with a `(...)` comment naming the claim, then an
`(expected output: ...)` comment recording what the compiler actually
printed when the probe was run, then the program itself. The four
Discrepancies below each also have a dedicated minimal repro at
`D1.vox`, `D2.vox`, `D3.vox`, `D4.vox` in the same directory.
`fixtures/long.txt` is the on-disk input the file-truncation probes
(BUF-07, BUF-09) and the Releasing-a-Buffer probes that read a file
(BUF-47, BUF-53) read from; probes that reference it assume a working
directory at the repo root.

Rows with no probe file: BUF-04, BUF-08, BUF-18, BUF-40 (not assertable
from inside Vox — nothing to run), and BUF-28, BUF-35, BUF-49 (pure
cross-references to a sibling row's claim, not independently
hand-verified). Of BUF-40–54's 13 independently-assertable rows, 10
retained probe files cover them (three files each cover two or three
rows: BUF-41.vox also covers BUF-42; BUF-43.vox also covers BUF-44 and
BUF-45). **43 `BUF-NN.vox` probe files total** (33 from BUF-01–39, 10
new from BUF-40–54) **plus D1–D4, for 47 files total.**
`docs/check-probes.sh docs/ledger/probes/buffers` reports 47 passed, 0
failed, 0 skipped.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| BUF-01 | 3515 | Buffers come in two declaration forms: dynamic (no size) and fixed-size. | declare both forms, print `'s type` or observe capacity to distinguish them | yes — declare both, compare `'s capacity` | `gen leaf buffer inrange`/`oob` (fixed only) | todo (dynamic form) | |
| BUF-02 | ? | Dynamic buffer "start[s] with zero capacity". | declare `a buffer called x.`, assert `x's capacity is 0` immediately | yes, and it currently **fails** — see Discrepancy 1 | none | todo | |
| BUF-03 | 3526 | Dynamic buffers have no overflow — memory expands as needed, past whatever the initial reserve is. | append past the initial ~4096-byte reserve (see Discrepancy 1) and assert size == total appended, no error flag | yes — generator controls total appended bytes | none (format leaves append only small fixed strings into *fixed*-size targets) | todo | |
| BUF-04 | 3544, 3544 | Buffers are automatically freed on program exit. | — | **no** — not observable from inside a Vox program; no leak-detection channel | n/a | not assertable | |
| BUF-05 | 3535–3540 | `a buffer called X is N bytes in size.` allocates exactly N bytes of capacity. | assert `X's capacity is N` right after declaration | yes | `gen leaf buffer inrange`/`oob` | exercised (construct only — capacity is never printed or asserted by these leaves) | |
| BUF-06 | 3541 | Fixed buffers do not grow; a read or write past capacity is truncated at capacity and sets the error flag. | append/write past capacity, assert size stays at capacity and error flag is set | yes | none for **append**-into-fixed overflow (see BUF-37); read-into-fixed truncation exercised probabilistically, unasserted (see BUF-09) | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| BUF-07 | 3543 | A program can check buffer length after an operation to detect truncation. | print/assert `'s size` after a read that may have truncated | yes | `gen leaf file round trip`, `gen leaf stdin read` (both print `'s size` after `Read from ... into ...`) | exercised | |
| BUF-08 | 3544 | Fixed buffers, like dynamic ones, are freed automatically on exit. | — | not assertable, same as BUF-04 | n/a | not assertable | |
| BUF-09 | 3563–3568 | Reading into a full fixed buffer: (a) stops and sets an error flag, (b) discards data beyond capacity, (c) program continues, (d) `On error` catches it. | force `total input length > buffer capacity`, wrap the `Read` in `On error`, assert size == capacity and the handler fired | yes — generator controls both input length and buffer size | `gen leaf file round trip`, `gen leaf stdin read` sometimes undersize the buffer relative to input (by design, per their own comments) | **todo for (a) and (d)** — neither leaf wraps its `Read` in `On error`, so the "sets an error flag" claim is never checked, only "doesn't crash". (b)/(c) exercised (program prints size and continues). | |
| BUF-10 | 3606, ? | `size`/`capacity` properties return current bytes stored / max bytes holdable, as Numbers. | print or assert both after known operations | yes | none read `'s capacity` anywhere; `'s size` is read (not asserted) by file-round-trip/stdin leaves | todo (capacity never read by any leaf) | |
| BUF-11 | 3607 | `length` is a synonym for `size` (same value). | assert `X's length is X's size` after a mutation | yes | none use the `'s length` **property** on a buffer (only the `is empty` **predicate**, a different construct, at `gen leaf stdin read` line 2041); `'s length` is used on maps and clock-check buffers elsewhere but not paired against `'s size` on the same buffer | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| BUF-12 | 3609 | `empty` is true iff size = 0. | assert before/after append | yes | `gen leaf stdin read` uses the `is empty` **predicate**, not the `'s empty` **property** the manual documents in this table | todo (property form specifically) | |
| BUF-13 | 3610 | `full` is true iff size = capacity — manual scopes this "for fixed buffers" only. | assert on a fixed buffer at/under capacity; also probe a dynamic buffer for the same equality (docs don't say it holds there) | yes | none | todo — also see Discrepancy-adjacent note: property works fine on dynamic buffers too (hand-verified), so the manual's "for fixed buffers" scoping is narrower than reality; not wrong, just imprecise | |
| BUF-14 | 3594–3598 | `type` universal property reports declared type + `(static)`/`(dynamic)`; a buffer variable should report `Buffer (static)`. | declare a buffer, assert `X's type is "Buffer (static)"` | yes | none | todo — was **Discrepancy 2**, fixed in vox #42 (PR #189); now assertable as `Buffer (static)` | |
| BUF-15 | 3634 | `resize`, `reallocate`, `grow`, `shrink` are all accepted spellings of the same resize operation. | emit all four keywords across probes, assert new capacity each time | yes | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| BUF-16 | 3637 | Resize preserves data up to `min(old_length, new_capacity)`. | grow: assert old data intact; shrink-above-length: assert old data intact | yes | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| BUF-17 | 3638 | Shrinking below current data length truncates the data. | shrink capacity below current size, assert size == new capacity and content == prefix | yes | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| BUF-18 | 3639 | "New buffer is allocated and old buffer is freed." | — | **no** — an implementation detail; Vox has no pointer/identity introspection to observe this from the language | n/a | not assertable | |
| BUF-19 | 3712 | Byte positions are 1-indexed. | on a buffer with known content, assert `byte 1 of buf` equals the first byte's known value | yes | `gen leaf buffer inrange` reads/writes a byte but never asserts *which* byte, so 1-vs-0-indexing is never actually pinned down by an assertion (only "doesn't crash") | todo (verification, not exercise) | |
| BUF-20 | 3716 | Reading a byte at a **literal** position works (`byte 1 of data`). | — | yes | `gen leaf buffer inrange` | exercised | |
| BUF-21 | 3717 | Reading/writing a byte at a **variable/expression** position works (`byte i of buf`). | emit a byte access whose index is a runtime Vox variable, not baked into the generated text as a literal | yes | none — every existing leaf interpolates the index into the generated source as a compile-time literal number before the program is even written; the variable-index code path is a different path through the compiler and is never taken | todo — real gap, hand-verified to work correctly | |
| BUF-22 | 3721 | Writing a byte with a decimal literal (`Set byte N of buf to 0-255`). | — | yes | `gen leaf buffer inrange` | exercised | |
| BUF-23 | 3722 | Writing a byte with a hex literal (`0x48`). | — | yes | none | todo, hand-verified to work | |
| BUF-24 | 3723 | Writing a byte with a character literal (`'A'`). | — | yes | none | todo, hand-verified to work (writes the ASCII code) | |
| BUF-25 | 3727–3732 | Declaring a buffer from a string literal, then mutating a byte, then printing shows the mutation (worked example: `"Hello"` → `Set byte 1 ... to 'J'` → prints `"Jello"`). | reproduce the declare→mutate→print chain and assert the printed text | yes — exact string is known at generation time | buffer-from-string declarations exist (`gb{n} is "..."`, `env{n}pathbuf`) but none is followed by a `Set byte`+`Print` pair that demonstrates the mutation | todo — the combined pattern is absent even though its parts exist separately | |
| BUF-26 | 3742 | Out-of-bounds access sets an error flag **and returns 0**. | capture the OOB read into a variable, assert it equals 0 | yes | `gen leaf buffer oob` catches the error but never captures/prints/asserts the resulting value | todo for "returns 0" specifically — the error-flag half is exercised, the return-value half is not | |
| BUF-27 | 3743 | `On error` catches OOB buffer access. | — | yes | `gen leaf buffer oob` | exercised | |
| BUF-28 | 3744 | "Buffer overflow is impossible — the compiler enforces bounds." | same as BUF-26/27 | — | — | covered by BUF-26/27 | not a separate leaf need |
| BUF-29 | 3746–3750 | **Now documented (vox PR #189, was a manual gap when this row was first written).** The OOB boundary for a **write** is capacity, not current length: writing within capacity but past current size silently **extends** the buffer's length rather than erroring. | write at an index in `(size, capacity]`, assert no error and size becomes that index | yes | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028; Discrepancy 3 resolved |
| BUF-30 | 3750–3753 | **Now documented (vox PR #189, was a manual gap when this row was first written).** The OOB boundary for a **read** is current size (length), not capacity — reading at an index in `(size, capacity]` errors even though a write there would have succeeded. | read at such an index, assert error fires | yes | none | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028; Discrepancy 3 resolved |
| BUF-31 | 3777 | `append source to destination` adds source bytes to the end of destination. | assert `dest == old_dest + source` and `dest's size == old_size + source_len` | yes | format-string leaves (`gen leaf format types`, the `gt{n}`-family leaf) append into fixed buffers, but nothing asserts the resulting content/length | todo (verification); exercised (construct) | |
| BUF-32 | 3778 | `copy source to destination` replaces destination contents with source bytes. | assert `dest == source` after copy | yes | same format-string leaves `copy "..." to gw{n}` | todo (verification); exercised (construct) | |
| BUF-33 | 3779 | `clear destination` sets length to 0 and preserves capacity. | assert size 0, capacity unchanged, after clear | yes | none on a **user** buffer — `clear` only appears on the generator's own internal `gen_out` accumulator, which is not part of any generated/fuzzed program | verified | vox 0.4.14 · vox-fuzz feat/ledger-leaves-2026-08-28 (this PR) · seeds 20260829–20261028 |
| BUF-34 | 3780 | Format-string sources are supported for `set`, `is`, `append`, and `copy` when destination is a buffer. | one instance of each of the four verbs with a format-string source | yes | all four forms present: `is` (`gb{n} is "{...}"`), `copy` (`copy "hello{n}" to gw{n}`), `set` (`set gc{n} to "set {...}"`), `append` (`append " {...}" to gc{n}`) | exercised (all four verbs; no assertions) | |
| BUF-35 | 3781 | Format-string buffer writes are "built in-place" (literals appended directly). | — | **no**, distinct from — behaviorally indistinguishable from BUF-34 at the language level; an implementation detail | n/a | not assertable separately from BUF-34 | |
| BUF-36 | 3782 | Dynamic **destination** buffers grow automatically under append/copy. | append/copy content larger than a small initial reserve into a no-size buffer, assert success and size | yes | none — every append/copy destination in the existing leaves is a *fixed*-size buffer (`gw`/`gb`/`gc`/`hw`, 64–192 bytes); a genuinely dynamic (unsized) destination is never used as an append/copy target | todo — real gap | |
| BUF-37 | 3783 | Fixed **destination** buffers truncate when full and set the error flag, under append/copy. | append/copy content that overflows a small fixed destination, assert truncated size == capacity and error flag set | yes | none — existing fixed destinations (64–192 bytes) are deliberately never overflowed by the small tokens appended into them | todo — real gap, hand-verified to truncate+error correctly | |
| BUF-38 | 3784 | Source buffer/text is never modified by append or copy. | print source before and after, assert unchanged | yes | none prints source before/after to compare | todo | |
| BUF-39 | 3787–3800 | The full worked example (Create-with-size, 4 hex byte writes, formatted read-back, OOB read caught by `On error`) compiles and behaves as shown. | reproduce verbatim | yes | none | todo (as a composite); every sub-claim it exercises is individually covered above (BUF-05/23/20/26/27) | hand-verified to reproduce exactly, including the `{b1:02X}` → `0xDE` (not `DE`) formatting, which is correct per LANGUAGE.md:3349's own `{n:X}` → `0xFF` spec, not a bug — see note below the table |
| BUF-40 | 3645 | `Free <buffer>.` releases a buffer's memory immediately, rather than waiting for program exit. | — | **no** — "immediately" is a timing/implementation-detail claim, not observable from inside Vox (same category as BUF-04/BUF-08); its one observable consequence is that the freed state is visible to the very next statement, which BUF-43 onward test | n/a | not assertable | |
| BUF-41 | 3646 | `Release <buffer>.` and `Deallocate <buffer>.` are accepted as the same statement as `Free <buffer>.` — three interchangeable spellings. | emit all three spellings on separate buffers, assert each empties its buffer (size 0) identically | yes | none — `grep` for `Free \|Release \|Deallocate ` across `src/gen_*.vox` finds nothing | todo | |
| BUF-42 | 3647 | All three spellings accept an optional article `the` (`Free the X.`). | emit `the` before the operand for each spelling | yes | none | todo (probe shared with BUF-41) | |
| BUF-43 | 3655–3656 | After `Free`, the buffer is empty: `size`/`length` read 0. | assert `X's size is 0` and `X's length is 0` right after `Free` | yes | none | todo | |
| BUF-44 | 3657–3659 | A freed buffer behaves exactly like a fixed buffer of capacity 0 — `capacity` reads 0, `empty` is true. Hand-verified extra consequence the sentence implies but doesn't spell out: `full` also reads true (0 == 0). | assert capacity 0, empty true, full true after `Free` | yes | none | todo | |
| BUF-45 | 3656 | After `Free`, `X as text` reads back `""` (the empty string). | assert `X as text is ""` | yes | none | todo | |
| BUF-46 | 3656–3657 | After `Free`, every read past the buffer is refused with the error flag — e.g. a byte read (`byte 1 of X`) errors and, per the OOB-read contract elsewhere in this section (BUF-26), returns 0. | attempt a byte read on a freed buffer inside `On error`, assert the flag fired and the returned value is 0 | yes | none | todo | |
| BUF-47 | 3656–3657 | After `Free`, every write past the buffer (`append`, `Set byte`, `copy`, `Set`, `Read … into`) is refused with the error flag; execution continues. | attempt each of the five write forms on a freed buffer inside `On error`, assert each fires and the program continues | yes | none | todo | |
| BUF-48 | 3656–3657 *(gap)* | Resize (`resize`/`reallocate`/`grow`/`shrink`) on a freed buffer is also refused with the error flag. Not itself named by this subsection's prose (only "read or write" is stated, and the resize keywords belong to the sibling Buffer Resizing subsection) — hand-verified to hold anyway, consistent with the general contract. | attempt each of the four resize spellings on a freed buffer inside `On error` | yes | none | todo — under-enumerated by the manual but not contradicted; not a Discrepancy | |
| BUF-49 | 3659 | `On error` catches the refusal from a write or read on a freed buffer, the same as it does for a full fixed buffer. | — | — | — | covered by BUF-46/BUF-47/BUF-48 | not a separate leaf need |
| BUF-50 | 3661–3669 | The worked example (declare from string, `Free`, `length` 0, `as text` `""`, `append` refused, caught by `On error`) compiles and behaves exactly as shown. | reproduce verbatim | yes | none | todo (as a composite); sub-claims covered by BUF-43/BUF-45/BUF-47 | |
| BUF-51 | 3671–3678 | `Free`ing an already-freed buffer is a no-op that sets the error flag rather than releasing anything a second time; the worked example (double `Free`, caught by `On error`) compiles and behaves as shown. | double-`Free`, assert the error flag fires the second time and the program continues | yes | none | todo | |
| BUF-52 | 3680–3683 | A `buffer` function parameter is the caller's buffer, so `Free` inside the function releases the same block the caller sees, and the caller's own variable is left empty too — exactly as a resize inside the function already is (FUN-26). | pass a buffer to a function that frees it, assert the caller's own variable reads size 0 / empty after the call | yes | none | todo — real gap | |
| BUF-53 | 3685–3697 | Per-iteration use: declaring a buffer inside a loop body and `Free`ing it each iteration compiles and runs (the "keeps memory flat" idiom's worked example). "Keeps memory flat" itself is not observable from inside Vox. | reproduce the loop shape (the manual's fragment omits `total_lines`/`source`, supplied by hand) | yes for the compiles-and-runs half; **no** for the memory-flat half (implementation detail) | none | todo (runs-without-crash half); not assertable (memory-flat half) | |
| BUF-54 | 3699–3708 | **Claim rewritten, 2026-08-29 (0.4.15, #109) — was one clause, now a full paragraph, and the compiler now agrees with it.** "A list also accepts `Free`, with the same after-state a buffer gets": empty (length 0, `empty` true, prints `[]`), every later write refused with the error flag, a second `Free` the same no-op-that-flags; `Free` releases the list and every nested list/map it holds, recursively; a `list` function parameter is the caller's list, so freeing one empties the caller's own variable too. | emit `Free` on a `list`, assert its post-`Free` state matches the buffer contract (emptied, further writes refused) | yes, and it now **passes** — Discrepancy 4 RESOLVED, see below | none | todo — unblocked (Discrepancy 4 resolved); sub-claims split into BUF-55 onward (2026-08-29 addition, below) | |

Note on BUF-39: my first read of the worked example's `{b1:02X}` output
looked like a formatting bug (`0xDE` instead of a bare `DE`). It isn't —
LANGUAGE.md:3349 documents `{n:X}` uppercase-hex format as including the
`0x` prefix (`{n:X}` → `0xFF`), so `0xDE` is the compiler being
consistent with a rule stated elsewhere in the manual, just not
restated at the buffer example. Recorded here so the next person
doesn't independently trip over the same false alarm.

## Discrepancies

### 1. Dynamic buffers do not start at zero capacity — and the compiler's own warning says they do

**Resolution (lawyer): MANUAL BUG + misleading diagnostic, high — RESOLVED in vox 0.4.11 (#93).** `INITIAL_BUF_CAP 4096` (coreasm/x86_64/resource.asm) is real and eager; the manual (now LANGUAGE.md:3525) and `warn_uninitialized_buffer` both said "zero capacity". Josj ruled 2026-08-23: 4096 is the rule, the docs were wrong. The manual and the warning now state 4096; no runtime change.

**Still open, re-probed against vox 0.4.9 (2026-08-22): unchanged.** The
repro below still prints `4096`, byte-identical to the earlier finding.
Per `vox-notes/candidates-round-4.md` ("Round-2 G-i: dynamic buffer
capacity 4096 vs manual 'zero' — design call (Josj)"), this is still an
open design question awaiting Josj, **not yet a numbered register entry
in flight** — `vox-notes/REPORT-CANDIDATES-0.4.10.md` candidate G reached
the same "design question for Josj" verdict, and neither
`REPORT-CANDIDATES-ROUND-2.md`/`ROUND-3.md` nor the `fix/bug-NN-*`
branches in the vox repo (`#66`–`#76`, `#87`, `#88`, `#90`) touch it.

LANGUAGE.md:3525 — which as of vox 0.4.11 (#93) reads "Start with 4096 bytes of capacity (size 0) and grow automatically as
needed." Repro:

```
a buffer called d.
print d's capacity.
```

Compiler output:
```
Warning: Buffer "d" declared without size or initializer.
  This creates a zero-capacity buffer which may not be useful.
  Consider: a buffer called 'd' is 1024 bytes.
4096
```

The warning text and the runtime value disagree with each other, not
just with the manual: the warning says "zero-capacity", the property
says 4096. Reading in the compiler's favor: 4096 is plausibly an
internal initial reserve (an implementation optimization — avoid a
realloc on first append) that the manual and the warning both describe
in terms of the *logical* capacity a user asked for (none), not the
bytes actually allocated. If that's the intended reading, `capacity`
documents the wrong thing (it should report a user-facing "0 requested"
concept, or the manual should say buffers reserve 4096 bytes up front).
Either way this is worth a human decision, not a fix from me. Not filed.

### 2. A fixed-size (or `Create ... with size N`) buffer's `type` property reports `Text (dynamic)`, not `Buffer (static)`

**Resolution (lawyer → fixed): COMPILER BUG — vox bug #42, fixed in vox PR #189 (2026-08-20).** `BufferDecl` never registered `declared_types`; now it does, and every spelling prints `Buffer (static)`. Probe `D2.vox` and `BUF-14.vox` updated to the corrected output. Still open for Josj: `is a buffer` does not parse, so the manual's recommended predicate cannot be used for buffers.

LANGUAGE.md:3598 says statically-typed variables including `buffer`
report `(static)`. Repro:

```
a number called n is 3.
a buffer called buf1 is 16 bytes in size.
a buffer called buf2 is "seed".
print n's type.
print buf1's type.
print buf2's type.
```
Output:
```
Number (static)
Text (dynamic)
Buffer (static)
```

`buf1` (declared with a byte count, via either `is N bytes in size`,
`is N bytes`, or `Create a buffer called X with size N`) is mistagged.
`buf2` (declared from a string literal) is tagged correctly. So the bug
tracks the *declaration form*, not "buffer-ness" in general — the
type-property machinery apparently keys off something specific to the
string-initializer path and falls through to a default/wrong case for
the capacity-only path. Not filed; minimal repro above.

### 3. Byte read/write bounds checking: reads are checked against `size`, writes are checked against `capacity` — undocumented, and the two disagree with each other

**Resolution (lawyer): MANUAL BUG (doc gap), medium-high; behaviour must NOT change** — it is required by the manual's own worked example at :3312–3319. **Fixed in the manual by vox PR #189**: the Bounds Checking paragraph now defines bounds (writes 1..capacity extend size, reads 1..size, 0 out of bounds) and :3166 no longer says "silently".

LANGUAGE.md's Bounds Checking section (3426–3429) just said "out-of-bounds
access sets an error flag and returns 0," with no definition of what
"bounds" means relative to size vs. capacity, and no mention that a
write can change the length — **that gap is now closed**: the manual at
3431–3438 (added by vox PR #189, confirmed present in the 5327-line
0.4.9 text re-read for this pass) states exactly the write/read
asymmetry this discrepancy found. BUF-29/BUF-30 above are re-pinned to
that paragraph and are no longer "undocumented precision." Repro (fixed
buffer, capacity 8, filled to
size 4 via `append "ABCD"`):

```
Set byte 6 of fx to 88.     (index 6 is in (size=4, capacity=8])
print fx's size.            (-> 6: the write EXTENDED the length)
a number called g is byte 5 of fx.   (index 5, now < size=6)
On error print "gap read errored".  (does not fire; g is 0, the gap-filled byte)
a number called atcap is byte 8 of fx.  (index 8, == capacity, but > size=6)
On error print "read at capacity edge errored".  (FIRES)
```

So: a write at any index up to *capacity* succeeds and silently
extends `size` to that index, zero-filling the gap; a read at any index
beyond the *current* `size` errors, even if it's within capacity. This
is internally consistent (you can't read data you haven't "committed"
by writing it, even though the allocation exists) but it's a real
behavior with real edge cases — a byte written at index 100 of an
8192-byte dynamic buffer instantly makes `size` 100 — and none of it is
in the manual. This reading treats the compiler as correct and the docs
as incomplete; I don't see an alternative reading where the compiler is
wrong here, since the write-extends-length behavior is exactly what
lets `Set byte N of buf to V` be usable at all on a buffer nobody has
appended to yet (see the file's own comment at gen.vox:2107, which the
brief's warnings already flagged: "a fixed-size buffer starts EMPTY").
Worth documenting; not filed as a bug since nothing crashes or violates
memory safety.

### 4. "A list also accepts `Free`" — but `Free` on a list has no observable effect at all — RESOLVED (vox #109, 0.4.15)

**Resolution, 2026-08-29: RESOLVED by vox #109 (0.4.15).** The manual now
states the full contract at LANGUAGE.md:3699–3708 ("A list also accepts
`Free`, with the same after-state a buffer gets: it becomes empty …, and
every later write … is refused with the error flag; a second `Free` is
the same no-op-that-flags …; `Free` releases the list and every
collection it holds …, recursively …; a `list` function parameter is the
caller's list, so freeing one empties the caller's own variable too"),
and the compiler now agrees with it: re-running `D4.vox` (`VOX_CORE_PATH=
/home/josj/scr/english/worktrees/wt-stack-0415/coreasm
/home/josj/scr/english/vox-notes/stack-0415/vox-stack D4.vox -o p && ./p`)
prints `0` / `1` / `[]` / `append to freed list refused` / `0` / `[]` —
length 0, empty true, contents `[]` after `Free`, and the following
`append` is caught by `On error` and does not change the list — the
exact contract this discrepancy found missing. See BUF-54 (rewritten
above) and BUF-55 onward (2026-08-29 addition) for the split-out
assertable sub-claims. Original write-up retained below for history.

`D4.vox`. LANGUAGE.md:3699–3708 (was the single sentence closing the
"Releasing a Buffer" subsection at 0.4.14's 3674; 0.4.15 expanded it to
the paragraph quoted above): "A list also accepts `Free`." Read in
context —
immediately after four paragraphs establishing that `Free` empties a
buffer, refuses further reads/writes with the error flag, and is a no-op
on a second call — a reader expects the same contract to hold for a
list: emptied, further mutation refused. The claim is stated a second
time, more directly, in the Keywords chapter's Statement Starters table
(LANGUAGE.md:5059): `Free` — "Release a buffer **or list's** memory
immediately" — which leaves less room to read 3674 as a narrow "the
grammar merely accepts it" claim than it would standing alone (see the
pro-compiler reading below, which is weaker for having two citations to
answer instead of one).

```
a list called nums is [1, 2, 3].
Free nums.
print nums's length.
print nums's empty.
print nums.
append 9 to nums.
On error print "append to freed list refused".
print nums's length.
print nums.
```
Output:
```
3
0
[1, 2, 3]
4
[1, 2, 3, 9]
```

The statement is accepted (no compile error, no runtime error flag set
on the `Free nums.` line itself), but it changes nothing: `length` is
still 3, `empty` is still false, the printed contents are unchanged, and
the following `append` succeeds normally with no error — the list
behaves as if `Free` had never been called. This isn't a crash and isn't
a memory-safety fault (nothing is read after being freed, because
nothing was freed), but it falsifies the natural reading of the
sentence at 3674.

The strongest reading under which the compiler is correct: "accepts"
is doing real, narrow work here — the sentence promises only that the
*grammar* does not reject a `list` operand to `Free` (unlike, say, a
`number`, which would presumably be a type error), not that `Free` on a
list performs the same release-and-refuse contract just described for
buffers three paragraphs earlier. Every other verb in this subsection
that documents an effect says so explicitly and at length (the buffer
paragraphs run to four sentences with a worked example each); this
sentence is one clause with no worked example and no restated
consequence, which is consistent with it meaning "also legal," not
"also has this effect." On that reading `Free` on a list is a
currently-inert no-op — plausibly a stub for a not-yet-wired code path
— and the manual is imprecise rather than wrong, though a reader would
have to already doubt the natural reading to arrive there. **This
reading is weaker than it looks once the Statement Starters table's own
`Free` row (LANGUAGE.md:5059, "release a buffer or **list's** memory
immediately") is in evidence** — a table entry is exactly the kind of
terse, no-worked-example statement the "grammar-only" reading leans on,
yet its wording ("release... memory") is about as hard to read as
grammar-only as English allows. Still not filed; the two citations and
the repro above are handed to the human as-is, not resolved here.

**Master note (2026-08-29).** Mechanism established: a top-level (global) list gets no code at all — `Statement::Free` looks the name up in the stack-variable table only (`src/codegen/statements.rs:1179`), so the global path is a silent no-op; a function-local list DOES emit `HEAP_FREE` (munmap) and the variable is left dangling — the next read of it segfaults (rc 139; `vox-notes/evidence/2026-08-29-free-on-a-list/`). Recorded as a candidate plus design question Q10 (what a freed list should read as); BUF-54 stays `todo` until ruled.

## Invariants this section justifies

Sameness the invariant report will show that a rule actually requires (PROCEDURE §8). Section added 2026-08-29 with the leaves merge; LANGUAGE.md-required samenesses for buffers are still to be enumerated.

- the identifiers `ASSERT`, `expected`, `got` and the row prefix `BUF` appear in every program that draws an asserting leaf — PROCEDURE.md §6 (the ledger assertion line `ASSERT <ID>: expected <x> got <y>`), a procedure rule rather than a LANGUAGE.md one; the invariants report may cite §6 for these three words and the prefix (added 2026-08-29, leaves merge)

## Report

**39 rows** (BUF-01 through BUF-39). Two of those (BUF-28, BUF-35) are
explicit cross-references folded into a sibling row rather than fresh
leaf needs, leaving **37 distinct claims**. Of those, **33 are
independently assertable** — the generator already knows enough to
predict the exact result and can emit a failing-exit assertion. 4 are
flatly not assertable from inside Vox (freed-on-exit ×2 — BUF-04,
BUF-08 — "new buffer allocated" identity — BUF-18 — and the in-place-
write implementation detail — BUF-35).

**Existing coverage is real but shallow.** `gen leaf buffer inrange`/
`oob` and the format-string leaves touch a good fraction of the
constructs in this section, but *every single one* stops at "doesn't
crash" — none of them assert a documented result. That's the biggest
single finding: the next workers' job on this section isn't mostly
"write leaves for untouched constructs" (though BUF-15/16/17 resize,
BUF-21 variable-indexed byte access, BUF-33 clear-on-a-user-buffer,
BUF-36/37 dynamic/fixed append-copy destinations, and BUF-23/24
hex/char byte literals are genuinely untouched) — it's "add assertions
to what's already being emitted."

**Three discrepancies found**, all recorded above with minimal repros,
none filed:
1. Dynamic buffer capacity is 4096, not 0, contradicting both the
   manual and the compiler's own warning message.
2. `buf's type` reports `Text (dynamic)` instead of `Buffer (static)`
   for any buffer declared with a byte count (fixed-size or
   `Create ... with size`), but is correct for string-literal
   declarations. Clean, narrow, reproducible.
3. Byte-write bounds are checked against capacity (and silently extend
   length); byte-read bounds are checked against current length. Real,
   consistent, and completely undocumented — a documentation gap more
   than a bug, but it changes what "out of bounds" means throughout
   this section and should probably be written into LANGUAGE.md.

**For the next section's mapping:** the "no leaf asserts anything"
pattern is likely universal across `gen.vox`, not specific to buffers —
worth checking once instead of re-discovering it per section. Also
worth carrying forward: check every property in a table against
`grep -n "'s <property>"` in gen.vox, not just whether the *type* is
used somewhere — `capacity` and `full` are documented, plausible-looking
properties that turned out to be completely unread by any leaf, and
that's easy to miss by skimming leaf names rather than grepping
accessors. Finally: hand-verify the compiler's *implementation
detail* bullets (e.g. "old buffer is freed") separately from its
*observable* bullets before writing the row — they need a different
"assertable?" answer (no, categorically) rather than "todo".

### Addition, 2026-08-29: Releasing a Buffer (BUF-40 through BUF-54)

**15 new rows**, mapping the whole `#### Releasing a Buffer` subsection
0.4.14 added (LANGUAGE.md:3645–3754). One (BUF-49, `On error` catching
the refusal) is a cross-reference folded into BUF-46/47/48 rather than a
fresh leaf need, leaving **14 distinct new claims**. Of those, **13 are
independently assertable** and 1 is not (BUF-40, the "immediately"
timing claim — same category as BUF-04/BUF-08). All 13 assertable rows
are `todo`: `grep` on `Free \|Release \|Deallocate ` across
`src/gen_*.vox` confirms no leaf emits any of the three spellings yet,
so this whole subsection is currently **unexercised**, not just
unverified — the next leaf batch here starts from zero, not from
"exercised, needs assertions" the way most of BUF-01–39 did.

**One discrepancy, found here and RESOLVED 2026-08-29 (vox #109, 0.4.15):** Discrepancy 4 — "A list also accepts
`Free`" (LANGUAGE.md:3699–3708) compiled and ran, but had **no observable
effect whatsoever** on the list: length, emptiness, and contents were
unchanged and a subsequent `append` was not refused. Every buffer-side
claim in this subsection was confirmed to hold exactly as documented
(three spellings, the optional `the`, empty-after-`Free`, `as text`
`""`, every read/write refused, idempotent double-`Free`, the
parameter-aliasing case, and — hand-verified beyond what the manual
states by name — all four resize spellings refused too, BUF-48); the
list sentence is the one claim in the whole subsection that did not
hold up.

**Hand-verification method:** every row above was probed against the
installed 0.4.14 binary (`/usr/bin/vox`, `VOX_CORE_PATH
/usr/share/vox/coreasm`) from a `vf_scratch/` scratch directory before
being written into the table, then re-verified as its final retained
probe file. `docs/check-probes.sh docs/ledger/probes/buffers` reports
47 passed, 0 failed, 0 skipped across the whole directory, old and new
rows together.
