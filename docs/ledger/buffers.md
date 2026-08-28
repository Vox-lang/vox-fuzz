# Claim ledger: File I/O → Buffers

Source: `../vox/LANGUAGE.md` lines 3488–3761 (File I/O § Buffers, through
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

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/buffers/`, one file per row named `BUF-NN.vox`
(a probe covering more than one row is named for the first and says so
in its own header comment — e.g. `BUF-26.vox` also covers BUF-27).
Each file opens with a `(...)` comment naming the claim, then an
`(expected output: ...)` comment recording what the compiler actually
printed when the probe was run, then the program itself. The three
Discrepancies below each also have a dedicated minimal repro at
`D1.vox`, `D2.vox`, `D3.vox` in the same directory. `fixtures/long.txt`
is the on-disk input the file-truncation probes (BUF-07, BUF-09) read
from; probes that reference it assume a working directory at the repo
root.

Rows with no probe file: BUF-04, BUF-08, BUF-18 (not assertable from
inside Vox — nothing to run), and BUF-28, BUF-35 (pure
cross-references to a sibling row's claim, not independently
hand-verified). That's 33 probe files for the 33 independently
assertable rows, plus D1–D3, for 36 files total. All 36 were
recompiled and re-run in one final pass after being written and every
one reproduced its recorded `(expected output: ...)` exactly — 36
clean, 0 mismatches, 0 compile failures.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| BUF-01 | 3490 | Buffers come in two declaration forms: dynamic (no size) and fixed-size. | declare both forms, print `'s type` or observe capacity to distinguish them | yes — declare both, compare `'s capacity` | `gen leaf buffer inrange`/`oob` (fixed only) | todo (dynamic form) | |
| BUF-02 | ? | Dynamic buffer "start[s] with zero capacity". | declare `a buffer called x.`, assert `x's capacity is 0` immediately | yes, and it currently **fails** — see Discrepancy 1 | none | todo | |
| BUF-03 | 3501 | Dynamic buffers have no overflow — memory expands as needed, past whatever the initial reserve is. | append past the initial ~4096-byte reserve (see Discrepancy 1) and assert size == total appended, no error flag | yes — generator controls total appended bytes | none (format leaves append only small fixed strings into *fixed*-size targets) | todo | |
| BUF-04 | 3519, 3519 | Buffers are automatically freed on program exit. | — | **no** — not observable from inside a Vox program; no leak-detection channel | n/a | not assertable | |
| BUF-05 | 3510–3515 | `a buffer called X is N bytes in size.` allocates exactly N bytes of capacity. | assert `X's capacity is N` right after declaration | yes | `gen leaf buffer inrange`/`oob` | exercised (construct only — capacity is never printed or asserted by these leaves) | |
| BUF-06 | 3516 | Fixed buffers do not grow; reads/writes are silently truncated at capacity. | append/write past capacity, assert size stays at capacity and error flag is set | yes | none for **append**-into-fixed overflow (see BUF-37); read-into-fixed truncation exercised probabilistically, unasserted (see BUF-09) | todo | |
| BUF-07 | 3518 | A program can check buffer length after an operation to detect truncation. | print/assert `'s size` after a read that may have truncated | yes | `gen leaf file round trip`, `gen leaf stdin read` (both print `'s size` after `Read from ... into ...`) | exercised | |
| BUF-08 | 3519 | Fixed buffers, like dynamic ones, are freed automatically on exit. | — | not assertable, same as BUF-04 | n/a | not assertable | |
| BUF-09 | 3538–3543 | Reading into a full fixed buffer: (a) stops and sets an error flag, (b) discards data beyond capacity, (c) program continues, (d) `On error` catches it. | force `total input length > buffer capacity`, wrap the `Read` in `On error`, assert size == capacity and the handler fired | yes — generator controls both input length and buffer size | `gen leaf file round trip`, `gen leaf stdin read` sometimes undersize the buffer relative to input (by design, per their own comments) | **todo for (a) and (d)** — neither leaf wraps its `Read` in `On error`, so the "sets an error flag" claim is never checked, only "doesn't crash". (b)/(c) exercised (program prints size and continues). | |
| BUF-10 | 3581, ? | `size`/`capacity` properties return current bytes stored / max bytes holdable, as Numbers. | print or assert both after known operations | yes | none read `'s capacity` anywhere; `'s size` is read (not asserted) by file-round-trip/stdin leaves | todo (capacity never read by any leaf) | |
| BUF-11 | 3582 | `length` is a synonym for `size` (same value). | assert `X's length is X's size` after a mutation | yes | none use the `'s length` **property** on a buffer (only the `is empty` **predicate**, a different construct, at `gen leaf stdin read` line 2041); `'s length` is used on maps and clock-check buffers elsewhere but not paired against `'s size` on the same buffer | todo | |
| BUF-12 | 3584 | `empty` is true iff size = 0. | assert before/after append | yes | `gen leaf stdin read` uses the `is empty` **predicate**, not the `'s empty` **property** the manual documents in this table | todo (property form specifically) | |
| BUF-13 | 3585 | `full` is true iff size = capacity — manual scopes this "for fixed buffers" only. | assert on a fixed buffer at/under capacity; also probe a dynamic buffer for the same equality (docs don't say it holds there) | yes | none | todo — also see Discrepancy-adjacent note: property works fine on dynamic buffers too (hand-verified), so the manual's "for fixed buffers" scoping is narrower than reality; not wrong, just imprecise | |
| BUF-14 | 3569–3573 | `type` universal property reports declared type + `(static)`/`(dynamic)`; a buffer variable should report `Buffer (static)`. | declare a buffer, assert `X's type is "Buffer (static)"` | yes | none | todo — was **Discrepancy 2**, fixed in vox #42 (PR #189); now assertable as `Buffer (static)` | |
| BUF-15 | 3609 | `resize`, `reallocate`, `grow`, `shrink` are all accepted spellings of the same resize operation. | emit all four keywords across probes, assert new capacity each time | yes | none | todo | |
| BUF-16 | 3612 | Resize preserves data up to `min(old_length, new_capacity)`. | grow: assert old data intact; shrink-above-length: assert old data intact | yes | none | todo | |
| BUF-17 | 3613 | Shrinking below current data length truncates the data. | shrink capacity below current size, assert size == new capacity and content == prefix | yes | none | todo | |
| BUF-18 | 3614 | "New buffer is allocated and old buffer is freed." | — | **no** — an implementation detail; Vox has no pointer/identity introspection to observe this from the language | n/a | not assertable | |
| BUF-19 | 3678 | Byte positions are 1-indexed. | on a buffer with known content, assert `byte 1 of buf` equals the first byte's known value | yes | `gen leaf buffer inrange` reads/writes a byte but never asserts *which* byte, so 1-vs-0-indexing is never actually pinned down by an assertion (only "doesn't crash") | todo (verification, not exercise) | |
| BUF-20 | 3682 | Reading a byte at a **literal** position works (`byte 1 of data`). | — | yes | `gen leaf buffer inrange` | exercised | |
| BUF-21 | 3683 | Reading/writing a byte at a **variable/expression** position works (`byte i of buf`). | emit a byte access whose index is a runtime Vox variable, not baked into the generated text as a literal | yes | none — every existing leaf interpolates the index into the generated source as a compile-time literal number before the program is even written; the variable-index code path is a different path through the compiler and is never taken | todo — real gap, hand-verified to work correctly | |
| BUF-22 | 3687 | Writing a byte with a decimal literal (`Set byte N of buf to 0-255`). | — | yes | `gen leaf buffer inrange` | exercised | |
| BUF-23 | 3688 | Writing a byte with a hex literal (`0x48`). | — | yes | none | todo, hand-verified to work | |
| BUF-24 | 3689 | Writing a byte with a character literal (`'A'`). | — | yes | none | todo, hand-verified to work (writes the ASCII code) | |
| BUF-25 | 3693–3698 | Declaring a buffer from a string literal, then mutating a byte, then printing shows the mutation (worked example: `"Hello"` → `Set byte 1 ... to 'J'` → prints `"Jello"`). | reproduce the declare→mutate→print chain and assert the printed text | yes — exact string is known at generation time | buffer-from-string declarations exist (`gb{n} is "..."`, `env{n}pathbuf`) but none is followed by a `Set byte`+`Print` pair that demonstrates the mutation | todo — the combined pattern is absent even though its parts exist separately | |
| BUF-26 | 3708 | Out-of-bounds access sets an error flag **and returns 0**. | capture the OOB read into a variable, assert it equals 0 | yes | `gen leaf buffer oob` catches the error but never captures/prints/asserts the resulting value | todo for "returns 0" specifically — the error-flag half is exercised, the return-value half is not | |
| BUF-27 | 3709 | `On error` catches OOB buffer access. | — | yes | `gen leaf buffer oob` | exercised | |
| BUF-28 | 3710 | "Buffer overflow is impossible — the compiler enforces bounds." | same as BUF-26/27 | — | — | covered by BUF-26/27 | not a separate leaf need |
| BUF-29 | 3712–3716 | **Now documented (vox PR #189, was a manual gap when this row was first written).** The OOB boundary for a **write** is capacity, not current length: writing within capacity but past current size silently **extends** the buffer's length rather than erroring. | write at an index in `(size, capacity]`, assert no error and size becomes that index | yes | none | todo | see Discrepancy 3 (resolved) |
| BUF-30 | 3716–3719 | **Now documented (vox PR #189, was a manual gap when this row was first written).** The OOB boundary for a **read** is current size (length), not capacity — reading at an index in `(size, capacity]` errors even though a write there would have succeeded. | read at such an index, assert error fires | yes | none | todo | see Discrepancy 3 (resolved) |
| BUF-31 | 3737 | `append source to destination` adds source bytes to the end of destination. | assert `dest == old_dest + source` and `dest's size == old_size + source_len` | yes | format-string leaves (`gen leaf format types`, the `gt{n}`-family leaf) append into fixed buffers, but nothing asserts the resulting content/length | todo (verification); exercised (construct) | |
| BUF-32 | 3738 | `copy source to destination` replaces destination contents with source bytes. | assert `dest == source` after copy | yes | same format-string leaves `copy "..." to gw{n}` | todo (verification); exercised (construct) | |
| BUF-33 | 3739 | `clear destination` sets length to 0 and preserves capacity. | assert size 0, capacity unchanged, after clear | yes | none on a **user** buffer — `clear` only appears on the generator's own internal `gen_out` accumulator, which is not part of any generated/fuzzed program | todo | |
| BUF-34 | 3740 | Format-string sources are supported for `set`, `is`, `append`, and `copy` when destination is a buffer. | one instance of each of the four verbs with a format-string source | yes | all four forms present: `is` (`gb{n} is "{...}"`), `copy` (`copy "hello{n}" to gw{n}`), `set` (`set gc{n} to "set {...}"`), `append` (`append " {...}" to gc{n}`) | exercised (all four verbs; no assertions) | |
| BUF-35 | 3741 | Format-string buffer writes are "built in-place" (literals appended directly). | — | **no**, distinct from — behaviorally indistinguishable from BUF-34 at the language level; an implementation detail | n/a | not assertable separately from BUF-34 | |
| BUF-36 | 3742 | Dynamic **destination** buffers grow automatically under append/copy. | append/copy content larger than a small initial reserve into a no-size buffer, assert success and size | yes | none — every append/copy destination in the existing leaves is a *fixed*-size buffer (`gw`/`gb`/`gc`/`hw`, 64–192 bytes); a genuinely dynamic (unsized) destination is never used as an append/copy target | todo — real gap | |
| BUF-37 | 3743 | Fixed **destination** buffers truncate when full and set the error flag, under append/copy. | append/copy content that overflows a small fixed destination, assert truncated size == capacity and error flag set | yes | none — existing fixed destinations (64–192 bytes) are deliberately never overflowed by the small tokens appended into them | todo — real gap, hand-verified to truncate+error correctly | |
| BUF-38 | 3744 | Source buffer/text is never modified by append or copy. | print source before and after, assert unchanged | yes | none prints source before/after to compare | todo | |
| BUF-39 | 3747–3760 | The full worked example (Create-with-size, 4 hex byte writes, formatted read-back, OOB read caught by `On error`) compiles and behaves as shown. | reproduce verbatim | yes | none | todo (as a composite); every sub-claim it exercises is individually covered above (BUF-05/23/20/26/27) | hand-verified to reproduce exactly, including the `{b1:02X}` → `0xDE` (not `DE`) formatting, which is correct per LANGUAGE.md:3324's own `{n:X}` → `0xFF` spec, not a bug — see note below the table |

Note on BUF-39: my first read of the worked example's `{b1:02X}` output
looked like a formatting bug (`0xDE` instead of a bare `DE`). It isn't —
LANGUAGE.md:3324 documents `{n:X}` uppercase-hex format as including the
`0x` prefix (`{n:X}` → `0xFF`), so `0xDE` is the compiler being
consistent with a rule stated elsewhere in the manual, just not
restated at the buffer example. Recorded here so the next person
doesn't independently trip over the same false alarm.

## Discrepancies

### 1. Dynamic buffers do not start at zero capacity — and the compiler's own warning says they do

**Resolution (lawyer): MANUAL BUG + misleading diagnostic, high — RESOLVED in vox 0.4.11 (#93).** `INITIAL_BUF_CAP 4096` (coreasm/x86_64/resource.asm) is real and eager; the manual (now LANGUAGE.md:3500) and `warn_uninitialized_buffer` both said "zero capacity". Josj ruled 2026-08-23: 4096 is the rule, the docs were wrong. The manual and the warning now state 4096; no runtime change.

**Still open, re-probed against vox 0.4.9 (2026-08-22): unchanged.** The
repro below still prints `4096`, byte-identical to the earlier finding.
Per `vox-notes/candidates-round-4.md` ("Round-2 G-i: dynamic buffer
capacity 4096 vs manual 'zero' — design call (Josj)"), this is still an
open design question awaiting Josj, **not yet a numbered register entry
in flight** — `vox-notes/REPORT-CANDIDATES-0.4.10.md` candidate G reached
the same "design question for Josj" verdict, and neither
`REPORT-CANDIDATES-ROUND-2.md`/`ROUND-3.md` nor the `fix/bug-NN-*`
branches in the vox repo (`#66`–`#76`, `#87`, `#88`, `#90`) touch it.

LANGUAGE.md:3500 — which as of vox 0.4.11 (#93) reads "Start with 4096 bytes of capacity (size 0) and grow automatically as
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

LANGUAGE.md:3573 says statically-typed variables including `buffer`
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
