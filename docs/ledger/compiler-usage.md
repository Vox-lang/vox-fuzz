# Claim ledger: Compiler Usage

Source: `../vox/LANGUAGE.md` lines 5138–5175 (Compiler Usage: Basic
Usage, Options, Examples), manual version 0.4.8 + bugs #49–#54 fixed, vox
main b26f66e. `INDEX.md`'s pinned range (5010–5047) is stale; this
section has moved to 5138–5175 at this commit (`## Compiler Usage` at
5138, the next `##` — Grammar Summary — at 5176).

This is a **gap analysis**, not a from-scratch map — this section had
never been mapped (`INDEX.md` said `no`). These claims are about the
`vox` **compiler binary's CLI**, not the Vox language, so — per the
brief — they are proved by shell transcripts and by the harness/`test.sh`
themselves, not by generated leaves; there is no `gen_*.vox` leaf that
could exercise `--shared` or `-v`, because a generated program never
invokes the compiler on itself.

## Probes

Every row's probe is retained in `docs/ledger/probes/compiler-usage/`,
named `CLI-NN.vox`. Rows CLI-01 through CLI-04, CLI-07, CLI-08 are
ordinary `.vox` source files that `docs/check-probes.sh`'s standard
`vox probe.vox -o work/name && ./work/name` invocation can compile and
run cleanly; the CLI-specific flag behavior (`--emit-asm`'s missing
executable, `-v`'s pipeline log, `--shared`'s `.so`+`.lib` pair) is
hand-verified separately and recorded in each file's header as a
transcript, since check-probes.sh has no way to pass extra flags to the
compiler it invokes. Rows CLI-05 and CLI-06 (`--link`, `--lib-path`) are
**not** runnable as a single file under check-probes.sh at all — both
need a prebuilt `libtally.so`/`libtally.lib` pair sitting beside them,
which check-probes.sh cannot stage — so their files carry `Ran: (not
runnable as a single file; see transcript above)` and no `expected
output:` block, matching the convention `variables/D5.vox` and
`expansion/BAS2-13.vox` already use for hand-run-only probes; they are
`SKIP`ped by check-probes.sh, not failed. `D1.vox` (the `--link` no-op
discrepancy) follows the same convention.

CLI-04's library source (`tally_lib.vox`, `Library tally version "1.0".`
+ one function) and CLI-05/CLI-06's consumer source (`tally_user.vox`,
`see tally version "1.0" from "./libtally.lib".` + one call) are original
to this ledger, written to prove the CLI flags — not copied from
`../vox/examples/mathkit_*.vox`, though that pair (referenced from
LANGUAGE.md's own Shared Libraries section) was used to find the exact
working invocation before these were written.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| CLI-01 | 5140–5145 | Basic Usage: `vox <source.vox> [options]` — one source file, zero or more options; with no options, output defaults to the source's stem (no extension). | reproduce a no-options compile and check the default output name | yes — the compiler's own behavior is deterministic and observable via `ls` | `test.sh`'s own harness (`"$VOX" "$f" -o "$bin"`, always WITH `-o`, never tests the no-`-o` default-name path) and the Makefile (`$(VOX) src/main.vox -o $(BIN)`, same) — neither exercises the bare no-options form this row is actually about | exercised (basic invocation shape, via `-o`) for the general form; todo for the specific "no `-o` → source-stem name" default, which nothing in the repo's own build/test infra uses | |
| CLI-02 | 5147 | `--emit-asm`: output assembly only (don't assemble/link) — no executable is produced. | compile with `--emit-asm`, assert the `.asm` file exists and the executable does not | yes | none — `grep -rn "emit-asm"` in `src/*.vox` finds nothing; despite an earlier design doc (`docs/superpowers/plans/2026-08-17-vox-fuzz-v1.md`) describing a nondeterminism checker built on `--emit-asm`, the flag is not used anywhere in the current harness (`src/runner.vox`'s determinism check works some other way) | todo — hand-verified: `hello.asm` is written, no `hello` executable appears | |
| CLI-03 | 5148 | `--run`: compile and run the program in one command. | compile with `--run`, assert the program's own stdout appears | yes | none in `src/`; `test.sh` always compiles then runs as two separate steps (`"$VOX" "$f" -o "$bin"` then `"$bin"`), never `--run` | todo — hand-verified: identical stdout to a separate compile-then-run | |
| CLI-04 | 5149 | `--shared`: build a shared library (`.so`) instead of an executable — and (undocumented in this section) also emits a companion `.lib` interface file beside it. | build with `--shared -o X.so`, assert `X.so` is an ELF shared object and `X.lib` exists | yes | `../vox/examples/mathkit_lib.vox` demonstrates the identical pattern (referenced from LANGUAGE.md's Libraries and Imports chapter, out of this section's range); nothing in `src/` (vox-fuzz never builds a `.so` of itself) | todo — hand-verified: `file libtally.so` reports `ELF 64-bit LSB shared object`; `libtally.lib` (142 bytes) appears alongside it, undocumented by this section but load-bearing for CLI-05/CLI-06 | |
| CLI-05 | 5150 | `--link <libs>`: "link against shared libraries (comma-separated)." | link a consumer against a prebuilt `.so`/`.lib` pair, with and without the flag, compare | **no, in the ordinary sense** — hand-verified across four transcripts (same-directory, subdirectory + `--lib-path`, and a two-library case) that omitting `--link` never changes the outcome; see Discrepancy 1 | none | todo — the flag is real (the compiler accepts it and does not error) but **no case tried shows it changing behavior**; see Discrepancy 1 | |
| CLI-06 | 5151 | `--lib-path <paths>`: "additional library search paths (comma-separated)." | put a `.lib`/`.so` pair in a subdirectory, compile with and without `--lib-path` pointing at it, compare | yes — this one IS load-bearing, unlike CLI-05 | none | todo — hand-verified: fails with `could not find the library interface file` without it, succeeds and runs correctly with it | |
| CLI-07 | 5153 | `-o <file>`: output file name. | compile with a custom `-o` name distinct from the source stem, assert it exists and runs | yes | `test.sh:38` (`"$VOX" "$f" -o "$bin"`, every single test file) and `src/main.rs:77` (the crates.io launcher, building vox-fuzz's own embedded sources) — the single most heavily-exercised CLI flag in the whole repo | **exercised** by the harness itself, independent of this ledger's own probe | |
| CLI-08 | 5154 | `-v`, `--verbose`: verbose output — two spellings of one flag. | compile with each spelling, assert the pipeline log lines appear and are identical between spellings | yes | none — `grep -n '"-v"\|--verbose"'` in `src/*.vox` finds nothing (only `test.sh`'s own unrelated `-v` for its own verbosity) | todo — hand-verified: both spellings print the identical five-line `Compiling.../Generated.../Assembling.../Linking.../Created executable:.../Removed assembly file:...` log, and produce byte-identical binaries | |

The "Examples" subsection (5157–5175) that closes this section is **not a
separate claim set** — its four shell invocations (`vox hello.vox --run`;
`vox hello.vox -o myprogram`; `vox math.vox --shared -o libmath.so`;
`vox main.vox --link math --lib-path ./libs`) are literal demonstrations
of CLI-03, CLI-07, CLI-04, and CLI-05+CLI-06 respectively — each was
reproduced verbatim as part of hand-verifying its corresponding row above
(not as separate rows, matching the `BUF-28`-style fold in buffers.md for
a manual passage that restates an already-covered claim rather than
making a new one).

## Discrepancies

### 1. `--link <libs>` never observably changes the build, in every case tried

LANGUAGE.md:5150 documents `--link <libs>` as "link against shared
libraries (comma-separated)," and the worked example at :5169 pairs it
with `--lib-path`: `vox main.vox --link math --lib-path ./libs`. Minimal
repro (`D1.vox`; full four-transcript version in `CLI-05.vox`):

```
$ vox tally_lib.vox --shared -o libtally.so
$ vox tally_user.vox -o with_link --link tally
$ vox tally_user.vox -o without_link
$ ./with_link
42
$ ./without_link
42
```

Both binaries compile clean and print the identical `42`. The same holds
with the library in a subdirectory (`--lib-path` present in both runs,
`--link` varied) and with a second, unrelated library also on the search
path (still no ambiguity — `--link` omitted, still resolves correctly).

**The reading in which the compiler is correct.** The `see <lib> version
<v> from "<path>.lib"` statement already names the exact `.lib` file to
consume; that file's own contents evidently carry everything the
compiler needs to find and link the matching `.so` (same directory,
matching stem), so there is nothing left for `--link` to disambiguate in
this consumption path. LANGUAGE.md's own Shared Libraries chapter
(outside this section's line range) describes a second, `.lib`-free
consumption path — a foreign, hand-assembled program
(`mathkit_driver.asm`) linking directly against the `.so` with no Vox
`see` statement and no compiler-side auto-discovery to lean on. If
`--link`'s real job is enabling *that* path, every case this ledger could
test (an ordinary Vox `see`-based consumer) is exactly the case where it
would look like a no-op, which is consistent with what was observed. That
reading doesn't fully resolve the finding, though: the Compiler Usage
section's own worked example illustrates `--link` with a `see`-based
consumer (the same shape `mathkit_consumer.vox` and this ledger's
`tally_user.vox` use), which is either the wrong illustration for a
foreign-linking-only flag or evidence the flag is meant to matter here
too and currently doesn't. Not filed.

## Invariants this section justifies

None. This section documents the compiler's own CLI, not the Vox
language — it does not constrain what a *generated Vox program* looks
like, so it contributes no invariant to `scripts/invariants`' corpus
report. (Indirectly, `-o` is why every generated program's binary has a
predictable path — but that's a harness convention, not a language rule
a program could violate.)

## Report

**8 rows** (CLI-01 through CLI-08), all independently assertable via
shell transcript. **7 of 8 hand-verified to work exactly as documented**;
the eighth (CLI-05, `--link`) is hand-verified to have **no observable
effect** in every case tried — Discrepancy 1. **1 discrepancy**, not
filed, awaiting Josj.

**Biggest finding:** `--link` is very likely dead weight in the common
case (a `see`-based Vox consumer, which is also what the manual's own
worked example shows) — either the manual/example should be corrected to
show a case where it matters, or the flag should be documented as
mattering only for the foreign/non-`see` linking path described
elsewhere in the manual. This is squarely a "record and stop" case per
`PROCEDURE.md` §5, not something for a mapper to fix.

**For the next mapper (grammar-summary.md, this same worker's batch):**
`--lib-path`, by contrast, is genuinely load-bearing (Discrepancy-free) —
worth remembering that "the manual pairs two flags in one example" does
not mean both flags are independently necessary; test each alone before
writing the row. Also: this section's own claims are compiler-behavior
claims, not language claims, so `assertable?` here means "the shell
transcript predicts the result," not "the generator can emit an
assertion" — there is no generated-leaf angle at all for this ledger,
unlike every other one in `docs/ledger/`.
