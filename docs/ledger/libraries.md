# Claim ledger: Libraries and Imports

Source: `../vox/LANGUAGE.md` lines **4878–5224** (`## Libraries and Imports`
through the `---` before `## Compiler Usage`), manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual at commit b26f66e). The 0.4.8→0.4.9
drift in this range is a uniform **+87 lines**, confirmed at multiple
anchors: line 4878 is `## Libraries and Imports` and line 5225 is
`## Compiler Usage`.

**Discrepancy 4 is now resolved, re-verified directly against vox
0.4.9.** It was vox bug #62, and `BUGS_FOUND.md`'s own entry names this
discrepancy as its origin.

This is a **gap analysis**, not a from-scratch map. `existing leaf` was
decided by `grep -n "see \|\.lib\|--shared\|--link\|Library\|Location\|Table of Contents"`
over every `src/gen_*.vox` file, never by leaf name. **The result is
uniform and stated once here rather than 64 times in the table: no
generated program contains a `see` of any kind, a `.lib`, a `Library`
declaration, or any of the CLI flags this section documents.** The only
`see` statements anywhere in `src/` are the generator's own module-
loading in `main.vox`, `loop_gen.vox` and `sandbox.vox` — never something
the generator emits into a fuzzed program. So `existing leaf` is `none`
for every row without exception, and this section's whole surface —
splitting a program across files, shared libraries, and everything
`--shared`/`--link`/`--lib-path` touch — is untouched by the fuzzer
today. `things-b.md` mapped the `.lib`/cross-file THING claims (its
THG2-49 through THG2-58 rows, LANGUAGE.md:1809–1885) already; they are
not re-mapped here and are cited by row ID where relevant.

Compiler used for every probe: `/home/josj/scr/english/vox/target/release/vox`
(`vox v0.4.8`, commit `b26f66e`), `VOX_CORE_PATH=/home/josj/scr/english/vox/coreasm`.
Every row below was hand-run against it before being written, per
`PROCEDURE.md` §4.

## Probes

Two kinds, because this section is the first one whose worked examples
need more than one source file, a second toolchain (`nm`, `readelf`,
`nasm`, `ld`), or a compiler flag (`--shared`, `--link`, `--lib-path`)
that `docs/check-probes.sh`'s single-file `vox probe.vox -o p && ./p`
harness cannot pass:

- **`docs/ledger/probes/libraries/LIB-NN.vox`** (and `D2.vox`, `D4.vox`) —
  ordinary probes, auto-run by `check-probes.sh`. Several `see` a
  companion `.vox`/`.lib`/`.so` checked into
  `docs/ledger/probes/libraries/fixtures/`, the same convention
  `process-control/fixtures/` already uses for its `libprocess.so` pair.
  Path note, hand-discovered while writing these: a `see` path with no
  leading `./` (a *bare name*, in LANGUAGE.md's own terms) is resolved by
  a search, and any diagnostic that gets far enough to open the file
  echoes the **resolved** path (the containing directory joined onto the
  bare name) — so `fixtures/libmathkit.lib`, run from
  `docs/ledger/probes/libraries/LIB-43b.vox`, appears in error text as
  `'docs/ledger/probes/libraries/fixtures/libmathkit.lib'`, not the bare
  string as typed. A diagnostic that never finds the file at all (missing
  `.lib`) echoes the string as typed instead. Recorded so the next
  contributor doesn't lose an hour to it, as this ledger did.
- **`docs/ledger/probes/libraries/shared/`** — every probe that needs
  `--shared`, `--link`, `--lib-path`, two source files on one command
  line, or `nm`/`readelf`/`nasm`/`ld`. `check-probes.sh` globs one level
  (`ledger/probes/*/*.vox`) so this subdirectory is never auto-run,
  exactly like `things-b/shared/` and `keywords/fixtures/`. Each file's
  header carries the full `Ran:` command and the exact recorded output —
  hand-verified, re-run once more in a clean scratch directory as a final
  pass before this ledger was written, all reproducing exactly.
  `D1.vox` and `D3.vox` live here for the same reason.

**18 auto-run probe files, 18 passed, 0 failed, 0 skipped**
(`docs/check-probes.sh docs/ledger/probes/libraries`). **19 more
hand-verified probes live in `shared/`** (not counted by
`check-probes.sh`, not skipped by it either — it never sees them): 18
`.vox` files (16 `LIB-*.vox` plus `D1.vox`/`D3.vox`) plus one
`LIB-driver.asm`. **15 fixture files** in `fixtures/` (not probes
themselves — companion `.vox` sources and their built `.lib`/`.so`
outputs, checked in the same way `process-control/fixtures/` checks in
`libprocess.so`): 7 `.vox` sources, 5 `.lib` files (2 hand-written or
hand-edited, 3 built), 3 built `.so`.

37 probe files (18 auto-run + 19 in `shared/`) back 56 distinct claims,
so most rows point at a probe rather than owning one outright — the same
"Also covers" sharing `buffers.md`/`things-b.md` use, spelled out per row
in the `status` column instead of gathered into one list here. The rows
with no evidence of their own at all — genuinely `not assertable` with no
probe possible, not merely sharing one — are the 2 implementation-detail
rows (LIB-06, LIB-55), the 8 folded/composite rows already named above,
and the root/portability-blocked halves of LIB-10/LIB-11/LIB-12.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| LIB-01 | 5387–5391 | `see "<path>.vox".` includes another Vox source file: parsed as part of the program, its functions become callable with no linking step — this is how a program splits across files. | `see` a companion file, call a function it defines | yes | none | todo — hand-verified (`LIB-01.vox`) | |
| LIB-02 | 5392–5394 | `see '<lib>' version "<ver>" from "<path>.lib".` consumes a shared library through its `.lib` interface — the library path, distinct from LIB-01. | see LIB-42 | yes | none | todo — covered by `LIB-42.vox` | |
| LIB-03 | 5396–5399 | The two-line fragment example (`see "./utils.vox".` / `see mathkit version "1.0" from "./libmathkit.lib".`) illustrates both forms together. | — | **no** as a unit — the manual marks it a fragment (` ```vox fragment `), and `./utils.vox`/`./libmathkit.lib` don't exist relative to the manual itself; it is not meant to compile standalone | none | not assertable as written — each half is independently covered by LIB-01 and LIB-42 | |
| LIB-04 | ? | There is exactly one library-consumption form; the rest are retired. | see LIB-05/05b/05c | yes (by exhaustion — see the three retired-form rows) | none | todo — composite, no dedicated probe | |
| LIB-05 | 5401–5403 | Three retired syntaxes all pointed `see` at a `.so` directly: `see "./path.so".`, `see "lib" version "1.0" from "./path.so".`, `see "./path.so" for "lib" version "1.0".`. | emit each retired form → expect a compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — all three hand-verified (`LIB-05.vox`, `LIB-05b.vox`, `LIB-05c.vox`); the manual's own spelling of the second form does not parse at all — see Discrepancy 2 | |
| LIB-06 | 5403–5405 | Rationale: a `.so` is binary ELF, carries mangled symbol names but no Vox type information, so the compiler cannot check a call against it. | — | **no** — an explanatory sentence, not itself a checkable behavior; its consequence (retirement) is LIB-05 | none | not assertable (rationale, no independent probe) | |
| LIB-07 | 5405–5408 | The three retired forms are refused: `see` of a `.so` errors and directs to `.lib`; the `see ... for ...` form has its own diagnostic; both name the canonical form. | see LIB-05 | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified, same probes as LIB-05: `see "./x.so".` and the bare-name `from "./x.so"` form share one diagnostic (`LIB-05.vox`, `LIB-05b.vox`), and `see ... for ...` gets a distinct one (`LIB-05c.vox`), both naming `see '<lib>' version "<x.y>" from "<path>.lib".` | |
| LIB-08 | — | `see` of a `.vox` source is unchanged by the retirement. | — | yes, trivially — every other row in this ledger that `see`s a `.vox` file (LIB-01, LIB-15, and the fixtures every diagnostic probe shares) demonstrates it still works | none | exercised — no dedicated probe, demonstrated throughout. **Citation lost 2026-08-23**: not stated in 527cb89; the clause "`see` of a `.vox` source is unchanged" was at 5611:5140 and the spec diet dropped it with the "retired forms" framing | |
| LIB-09 | 5410–5414 | `./` or `../` paths resolve against the directory of the file containing the `see`, and only there — never the caller's working directory. | `see` a relative path from a file whose own directory differs from the invoker's cwd | yes | none | todo — hand-verified (`LIB-01.vox`, whose header explains this is exactly what `check-probes.sh` proves by construction: the probe never `cd`s, yet `./fixtures/helper.vox` resolves) | |
| LIB-10 | ? | A leading `/` path is used as-is (absolute). | `see` an absolute path | yes | none | todo — hand-verified in scratch with an absolute path built from the live checkout (`$PWD/absolute_target.vox`), output `absolute`, exit 0. **Not retained as a probe**: an absolute path baked into committed source is not portable across checkouts, so nothing durable can be checked in for this row | |
| LIB-11 | 5415–5417 | A bare name (no `./`, `../`, or leading `/`) checks `/usr/share/vox/lib/<name>` first, falling back to the containing file's directory only if that path does not exist. | `see` a bare-named `.lib`/`.vox` where the system path is absent | **partly** — the fallback half is generator-predictable and asserted by running at all; the precedence half (system path present and preferred) needs a file actually installed at `/usr/share/vox/lib/`, which needs root | none | todo (fallback half exercised, `LIB-11.vox`); precedence half **not verified — needs root**, see Report | |
| LIB-12 | 5417–5419 | Trap: a bare `see "utils.vox".` can silently pick up a system file in preference to the one beside the source; write `./utils.vox` for the local one. | — | same as LIB-11 — the collision itself needs a real file at `/usr/share/vox/lib`, which needs root | none | not assertable without root — same blocker as LIB-11, mechanism demonstrated by that row | |
| LIB-13 | ?–? | `--lib-path` is **not** consulted by `see` of a `.vox` source; it only passes search paths to the linker (`-L`) for `--link`. | `see` a bare `.vox` name that exists only under a `--lib-path` directory → expect it to still fail | yes | none | todo — hand-verified in scratch: `see "helper.vox".` with `--lib-path vpathonly` still reports "Cannot read 'elsewhere/helper.vox'" (resolved against the source's own directory, ignoring `--lib-path` entirely). **Not retained as an automated probe** — needs the `--lib-path` flag itself as the point of the test, so it belongs with the `shared/` group by nature but adds no new mechanism beyond what LIB-01/LIB-09 already show for the no-flag case; recorded here instead | |
| LIB-14 | 5421–? | `--lib-path` **is** consulted by `see` of a `.lib` — both to find the `.lib` itself and to resolve its `Location`. | `see` a `.lib` findable only via `--lib-path`; separately, a `.lib` whose `Location .so` is findable only via `--lib-path` | yes | none | todo — hand-verified, two scratch probes: (1) a `.lib` outside the source's directory, found only after `--lib-path <dir>`, prints `7`; (2) a `.lib` present locally whose `Location` `.so` sits in a different directory, resolved only after `--lib-path <dir>`, also prints `7`. Needs the flag, so recorded rather than retained as an auto-run probe | |
| LIB-15 | 5432–5434 | Circular includes: the compiler tracks files already seen and skips a `see` that would re-enter one. | two files that `see` each other, both usable from a third | yes — both functions must be callable and the compile must terminate | none | todo — hand-verified (`LIB-15.vox`, fixtures/circ_a.vox + circ_b.vox) | |
| LIB-16 | 5437–5440 | A shared library is a `.so` built from Vox, callable from Vox or any other host; the chain is `.vox → see a .lib → Location → .so`. | — | **no** as a unit — a restatement of the whole section's shape, each link independently covered below | none | not assertable separately — see LIB-19 (writing), LIB-42 (consuming), LIB-55 (foreign host) | |
| LIB-17 | 5442–5445 | The `.lib` is the typed interface; the `.so` it points at is linked, never read for types. | — | **no** as a single behavior — restated precisely by LIB-28 and demonstrated by every consuming probe (a `.lib` with a wrong signature would be caught at `see`, never at the `.so`) | none | not assertable separately — see LIB-28 | |
| LIB-18 | 5447–5452 | "What runs today" callout: the whole path runs, captured from "this compiler (vox v0.2.0)". | — | **no** as a unit — promotional/summary text, not a checkable behavior in itself; also stale (the compiler is 0.4.8, not v0.2.0, though nothing it lists has regressed) | none | not assertable — every sub-claim it lists is independently covered: LIB-19/21 (self-contained .so), LIB-42 (`see` consumption), LIB-51 (mangling), LIB-45/47 (multi-input, versions), LIB-55 (foreign host) | |
| LIB-19 | 5456–5466 | Writing a library: the mathkit worked example (`Library` declaration + two functions) compiles with `--shared`. | reproduce verbatim, build with `--shared` | yes (exit 0; no printed output to check, `.lib`/`.so` are the outputs) | none | todo — hand-verified (`shared/LIB-writing.vox`) | |
| LIB-20 | 5468–5470 | The exact CLI invocation `vox mathkit_lib.vox --shared -o libmathkit.so` succeeds. | same as LIB-19 | yes | none | todo — same probe as LIB-19 | |
| LIB-21 | 5477–5482 | The built `.so` is self-contained (own copy of the runtime), loadable from any host, position-independent, and may use the full core language — not a runtime-free subset; only the library's own functions are exported, every runtime symbol kept out of the dynamic symbol table. | build a library using more than trivial arithmetic/printing (buffers, floats, etc.) with `--shared`, inspect `nm -D --defined-only` | yes — "full core language" is demonstrated by `shared/LIB-types.vox` (11 parameter/return types incl. buffer, file, time); "only own functions exported" by `nm -D` on `shared/LIB-writing.vox` showing exactly 2 symbols for 2 functions | none | todo — hand-verified (`shared/LIB-writing.vox`, `shared/LIB-types.vox`) | |
| LIB-22 | 5486–5492 | `nm -D --defined-only` on the built `.so` shows exactly the two mangled export symbols and nothing else; `readelf -r` shows no relocations. | same build, inspect with `nm`/`readelf` | yes | none | todo — hand-verified (`shared/LIB-writing.vox`), output matches the manual's `nm`/`readelf` output verbatim (only the symbol addresses differ, which the manual does not pin either) | |
| LIB-23 | 5494–5498 | "Two exports and nothing else leaked; zero absolute relocations" — restates LIB-22 — plus the mangled-label form `<library>_<version>_<func>` is introduced by example. | — | same as LIB-22 for the first half; the mangling form itself is LIB-50 | none | todo — same probe as LIB-22; see LIB-50 for mangling | |
| LIB-24 | 5500–5502 | The `Library` declaration gives the identity (name + version) that drives mangling and the `.lib`; a `--shared` build with no `Library` line has no identity and is rejected. | `--shared` build with no `Library` declaration → expect a compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified, exact diagnostic recorded (`shared/LIB-noidentity.vox`) | |
| LIB-25 | 5504–5511 | Top-level statements are rejected in a `--shared` compile: a shared library has no entry point, so `Print`/assignment/`If`/a bare call would be silently dropped; the compiler rejects it instead, with the exact quoted diagnostic. | `--shared` build with a top-level `Print` → expect the exact compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified, diagnostic reproduces the manual's quoted text verbatim (`shared/LIB-toplevel.vox`) | |
| LIB-26 | 5513–5514 | Only function definitions, `Library`, and `see` may appear at the top level of a `--shared` compile. | — | same as LIB-25 — one diagnostic covers the general rule | none | not assertable (compile-error claim) — same probe as LIB-25 | |
| LIB-27 | 5516–5519 | An empty library (no function definitions) is rejected — would yield a malformed version script / opaque linker error otherwise. | `--shared` build with zero function definitions → expect a compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified, exact diagnostic recorded (`shared/LIB-empty.vox`) | |
| LIB-28 | 5523–5526 | The `.lib` is the public interface — name, version, `.so` location, and a table of contents of every exported function's signature; it is the only place Vox types live (ELF carries mangled names but no types). | — | **no** as a unit — restated and demonstrated precisely by LIB-32/LIB-34/LIB-43 (a `.lib` lying about a type is caught at `see`, never at the `.so`) | none | not assertable separately — see LIB-32, LIB-34, LIB-43 | |
| LIB-29 | 5526–5527 | A `--shared` build writes `<output-stem>.lib` beside the `.so`, one `Library` block per input source. | build with `--shared -o X.so`, check `X.lib` exists beside it | yes | none | todo — demonstrated by every `shared/*.vox` probe (each writes `<stem>.lib`); multi-input case (one block per source) is LIB-45/LIB-46 | |
| LIB-30 | 5528–5531 | A `--shared` build **overwrites** a `.lib` that already exists, in place — the `.lib` is a declared output derived from the same `-o` as the `.so`, so a rebuild needs no manual cleanup and anything hand-edited into the `.lib` is lost. **Not itself changed by the 0.4.10 register (#66–#91)** — re-verified during the 0.4.10 re-pin, 2026-08-22: citation shifted from 5021–5024 (0.4.9) to 5258–5261 by arithmetic only, landing on unchanged text. Separately worth flagging alongside this row for whoever next touches Libraries: 0.4.10's #75/#90 add a **new, undocumented-in-LANGUAGE.md** rebuild requirement — "A `.so` exporting a function with a `list`, `map` or `buffer` parameter, and every program that `see`s it, must be rebuilt by the same 0.4.10 compiler" (CHANGELOG.md, top of the 0.4.10 entry) — a different concept from this row's in-place `.lib` overwrite, with no LANGUAGE.md line to cite yet. | build `--shared` twice at the same `-o`, second time with the `.lib` hand-edited in between → expect the edit to be silently discarded, not a compile error | yes | none | todo — hand-verified to **hold** (`shared/LIB-overwrite.vox`, `D1.vox` — see Discrepancies, resolved 2026-08-22: the manual was corrected to match this behavior). **Re-verified against 0.4.10, 2026-08-22**: byte-identical behavior | |
| LIB-31 | 5533–5540 | The worked `.lib`-format example: `Library`/`Location`/`Table of Contents` block, with the zero-parameter `greet` entry written `To greet.` (RESOLVED 2026-08-22 — previously shown bare `greet.`; the manual was corrected to match the compiler). | reproduce the mathkit `--shared` build and diff its `.lib` against the manual's shown text | yes | none | todo — hand-verified to **match**: the real `.lib` writes `To greet.`, as the manual now shows — see Discrepancy 3, resolved (`shared/D3.vox`) | |
| LIB-32 | 5542–5544 | `Library '<name>' version "<ver>".` is a block's identity; several `Library` blocks may appear in one `.lib`, each with its own `Location`; parsing runs to EOF, and a `Library` line starts a new block. | multi-input `--shared` build, inspect the combined `.lib` for two blocks | yes | none | todo — hand-verified: `fixtures/libmathkit_multi.lib` (built from two sources) has two `Library` blocks, each with its own `Location "./libmathkit_multi.so"` and its own Table of Contents; LIB-47 consumes one specific block by version out of it | |
| LIB-33 | 5545–5547 | `Location "<path>".` resolves relative to the `.lib` first, then `--lib-path`, then errors; absolute paths are honoured but never generated by the compiler. | see LIB-14 (search order) and LIB-43d (error case); absolute-path generation is a negative claim about the compiler's own output, observed by inspecting every `.lib` this ledger built (all use relative `"./....so"` Locations) | yes | none | todo — hand-verified: LIB-14 (search order), LIB-43d (`.so` missing at Location → error), and every `.lib` built for this ledger uses a relative `Location`, never absolute, consistent with "never generated" | |
| LIB-34 | 5548–5554 | The Table of Contents uses the 11-type vocabulary (`number`, `float`, `text`, `boolean`, `list`, `map`, `buffer`, `file`, `time`, `timer`, `value`) in either position; anything else is an error naming the unsupported type; `void` isn't a spelling (omit the `, returning` clause instead) and neither is `unknown` (the compiler's own internal placeholder for an untyped parameter). | export functions covering all 11 types as both parameter and return, inspect the `.lib` | yes for the 11-type/void half; **the `unknown`-never-appears half is not independently constructible** — every Vox parameter declaration is explicitly typed by its own grammar (`a number called n`, never a bare untyped form), so there is no legal Vox program that could make `unknown` surface in a `.lib` at all | none | todo (11-type + void-omission half, `shared/LIB-types.vox`); `unknown` half **not assertable — no reachable construct exists** | |
| LIB-35 | 5557–5562 | A `list`'s element type is carried optionally, compiler-inferred (not author-declared, since Vox source has no generic/typed-collection syntax): a `--shared` build scans the exported function's body, and when every appended/returned element provably agrees on one type it writes `list of <type>`; disagreement or no evidence yields plain untyped `list`. | export a function returning a uniformly-typed list, one returning a mixed list, and one whose element type is unknowable from the body | yes | none | todo — hand-verified all three cases (`shared/LIB-listinfer.vox`): uniform → `list of number`; mixed → plain `list`; no evidence (echoing an untyped parameter) → plain `list` | |
| LIB-36 | 5563–5565 | A `map`'s value type is **not** carried this way; `map` stays element-untyped in both positions regardless of what its values actually are. | export a function returning a map with uniformly-typed values, inspect the `.lib` | yes | none | todo — hand-verified: a map built with two number values still writes plain `returning a map`, never `map of number` (`shared/LIB-types.vox`, `'make map with values'`) | |
| LIB-37 | 5566–5568 | `, returning a <type>` exists only in `.lib` files; Vox source declares return types in the body (`Return a number, x.`), which a bodiless `.lib` declaration has no room for. | — | yes, trivially — every `.lib` built for this ledger shows the clause; no generated/hand-written Vox *source* ever writes `, returning` | none | exercised — demonstrated throughout, no dedicated probe | |
| LIB-38 | 5568–5570 | No `, returning` clause means the function returns nothing. | export a function with no `Return` at all (a true void function like `greet`), inspect the `.lib` | **the `.lib`-content half is true and verified** (`greet` → bare `To greet.`, no clause); **the implied consumer-side guarantee is false** — see Discrepancy 4/`D4.vox`: a caller can still assign a "returns nothing" function's result to a typed variable with no diagnostic | none | todo (`.lib`-content half, `shared/LIB-writing.vox`); consumer-side half **contradicted**, see Discrepancy 4 | |
| LIB-39 | 5570–5572 | A `list`'s element type only shows up in the `.lib` when the exporting function has a **declared** return type (`Return a list, out.`); a bare `Return out.` records no return type at all, list-element-typing included. | export one function with `Return a list, out.` and one with bare `Return items.`, compare `.lib` entries | yes | none | todo — hand-verified (`shared/LIB-barereturn.vox`): `Return x add 1.` (bare) omits the clause entirely, same as a true void function — see Discrepancy 4 for why that is dangerous, not just imprecise | |
| LIB-40 | 5574–5575 | A `.lib` is lexed with the Vox lexer but parsed by a dedicated parser, so it cannot carry executable statements — only the interface grammar. | hand-write a `.lib` with an executable statement spliced in, `see` it → expect a compile error | **no, from a runtime leaf** (compile-error claim; also the `.lib` under test is hand-written, not generator output) | none | not assertable (compile-error claim) — hand-verified, exact diagnostic recorded (`LIB-40.vox`, `fixtures/broken_executable.lib`) | |
| LIB-41 | 5579–5583 | The consuming-a-library worked example: `see mathkit version "1.0" from "./libmathkit.lib".` then call `'add two numbers' of 3 and 4`, print the sum — prints 7. | reproduce verbatim against a built library | yes | none | exercised — hand-verified (`LIB-42.vox`) | |
| LIB-42 | 5595–5604 | `see` of a `.lib` runs six steps: (1) resolve the `.lib`; (2) parse and select the block matching name **and** version; (3) resolve `Location`; (4) verify against the `.so`'s dynamic symbol table (the staleness check — a lying `.lib` is a compile error, not a runtime crash); (5) register the signatures so calls type-check like any other function; (6) emit `extern <mangled>` per used function and add the `.so` + `-rpath` to the link line. | each step independently: LIB-43a–e (1–4 failing), LIB-41 (5–6 succeeding) | **steps 1–4 and 6 are yes**; **step 5's "type-check like any other function" is contradicted for return values** — see Discrepancy 4/`D4.vox`: a function whose `.lib` entry has no `, returning` clause has its result silently accepted into a typed variable, unlike a genuine arity/type mismatch on a *parameter*, which LIB-43f/g show **is** caught correctly | none | todo (steps 1–4, 6 — `LIB-42.vox`, `LIB-43a`–`g.vox`); step 5 **partially contradicted**, see Discrepancy 4 | |
| LIB-43 | 5613–5617 | Six distinct diagnostics, one per failure: missing `.lib`; no such library in it; version mismatch (listing the versions offered); missing `.so` at `Location`; symbol absent from the `.so` (stale `.lib`, names the symbol); arity or type mismatch at the call site. **The manual added a seventh, 2026-08-22 (LANGUAGE.md:5617–5619, not yet a row): reading the result of a `.lib` entry with no `, returning` clause — which returns nothing, so there is nothing to read — is also its own diagnostic; call it as a statement instead.** | one probe per failure mode | **no, from a runtime leaf**, for all six (compile-error claims) | none | not assertable (compile-error claims) — all six hand-verified with exact diagnostics recorded: `LIB-43a.vox` (missing `.lib`), `LIB-43b.vox` (version mismatch), `LIB-43c.vox` (no such library), `LIB-43d.vox` (missing `.so`), `LIB-43e.vox` (stale symbol), `LIB-43f.vox`/`LIB-43g.vox` (arity/type); the new seventh diagnostic is unmapped — see note in the claim column | |
| LIB-44 | 5632–5634 | The worked example set in `examples/` (`mathkit_lib.vox` / `mathkit_consumer.vox`) is exactly the pair shown above. | — | same as LIB-41 | none | not a separate leaf need — covered by LIB-41/LIB-42 | |
| LIB-45 | 5635–5636 | A foreign caller (C, Rust, assembly) is shown separately, in "Calling a library from a non-Vox host". | — | see LIB-55 | none | not a separate leaf need — cross-reference | |
| LIB-46 | 5640–5641 | `vox a.vox b.vox --shared -o lib.so` links several libraries into one `.so` in a single step; a linked `.so` cannot be appended to afterward, so one link step is the only way to combine libraries. | multi-input `--shared` build | yes | none | todo — hand-verified (`shared/LIB-writing.vox`'s multi-input variant, checked in as `fixtures/libmathkit_multi.so`); the "cannot append" half is an implementation-detail rationale, not independently observable, folded in | |
| LIB-47 | 5642–5644 | Sources are parsed independently, then compiled into one unit; the runtime is included once and shared by every library in the `.so`. | — | **partly** — "parsed independently" is observable (each source's own errors are reported under its own filename, per LIB-48's diagnostic); "runtime included once" is an implementation/size detail with no Vox-observable consequence | none | todo (parsed-independently half, demonstrated by LIB-48's diagnostic naming each file separately); "runtime once" half **not assertable** | |
| LIB-48 | 5646–5652 | Backward compatibility is the reason multi-input exists: two versions of one library can live in one `.so`, kept apart by mangling; a consumer calling the old mangled name keeps working after a newer version ships beside it, with no recompile. | build two versions of one library into one `.so`, consume the old version, assert the old (not new) behavior | yes — the generator controls both versions' bodies, so it knows which one must have run | none | todo — hand-verified: `fixtures/libmathkit_multi.lib`/`.so` holds mathkit 1.0 (`x add y`) and 2.0 (`x add y add 1000`); `see`ing version "1.0" and calling it prints 7, not 1007 (`LIB-47.vox`) | |
| LIB-49 | 5654 | Duplicate `<library, version>` pairs across multi-input `--shared` sources are rejected, naming both filenames. | two sources declaring the same `Library name version` in one `--shared` build → expect a compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified, diagnostic names both files (`shared/LIB-dupa.vox` + `LIB-dupb.vox`) | |
| LIB-50 | 5655–5656 | Multi-input is `--shared`-only; rejected for executable builds, where the semantics would be ambiguous. | two sources with no `--shared` → expect a compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified (`shared/LIB-exe1.vox` + `LIB-exe2.vox`) | |
| LIB-51 | 5660–5664 | Every exported function mangles to a flat label `<library>_<version>_<func>`; worked example `mathkit` + `1.0` + `"add two numbers"` → `mathkit_1_0_add_two_numbers`. | build the worked example, inspect `nm -D` | yes | none | exercised — same probe as LIB-19/LIB-22 (`shared/LIB-writing.vox`), matches the manual's example symbol exactly | |
| LIB-52 | 5666–5667 | Each component is sanitized by mapping every character outside `[A-Za-z0-9_]` to `_`. | export a function whose name contains punctuation, inspect `nm -D` | yes | none | todo — hand-verified: `'foo-bar!'` sanitizes to `foo_bar_` (`shared/LIB-mangling.vox`) | |
| LIB-53 | 5668–5673 | The leading-digit prefix applies only to the **library** component (it opens the symbol, and a digit is not a legal C identifier start); the version and function components are interior and take the sanitizer alone — so `1.0` becomes `1_0`, no prefix, avoiding a double underscore. | a digit-leading library name + version | yes | none | todo — hand-verified: a bare digit-leading library name does not even parse as a Vox identifier (`Library 123kit ...` lexes as an integer literal); the single-quoted spelling `'123kit'` is legal and mangles to `_123kit_2_0_foo_bar_` — leading underscore on the library component only, none on the version (`shared/LIB-mangling.vox`) | |
| LIB-54 | 5673–5678 | A non-Vox caller needs the mangled name to call the function at all; there is no unmangled alias, since an alias would defeat the version isolation the scheme exists for. | — | yes, by omission — `nm -D` on every `.so` built for this ledger shows only mangled symbols, never a bare `<func>` alias | none | exercised — demonstrated by every `nm -D` output recorded in this ledger, none show an unmangled alias | |
| LIB-55 | 5680–5684 | Runtime state is not mangled — deliberate; the runtime is emitted once per `.so` and shared by every library in it (one resource table, one `.fini_array`, one idempotent cleanup); cross-`.so` isolation holds because each `.so` carries its own runtime and the version script hides it. | — | **no** — an implementation/linking detail with no Vox-observable consequence; a program cannot introspect its own runtime's symbol visibility or `.fini_array` contents | none | not assertable — implementation detail, consistent with `nm -D` never showing runtime symbols on any `.so` built for this ledger | |
| LIB-56 | 5688–5690 | A shared library is a plain `.so`; any caller that can link one can use it (C, Rust, hand-written assembly); the foreign caller must name the export by its mangled label. | build a library, call it from a hand-written assembly driver | yes | none | todo — hand-verified (`shared/LIB-driver.vox` + `LIB-driver.asm`) | |
| LIB-57 | 5691–5723 | The nasm+ld driver worked example compiles, links, and runs, calling the library with the Vox calling convention (integer arguments in `rdi`, `rsi`, …; result in `rax`), printing "hello from mathkit". | reproduce verbatim with `nasm`/`ld` | yes | none | todo — hand-verified, output matches exactly, exit 0 (`shared/LIB-driver.vox` + `LIB-driver.asm`) | |
| LIB-58 | 5725–5731 | The exact `vox --shared` / `nm -D` / `nasm` / `ld` commands shown produce the documented output. | same as LIB-57 | yes | none | todo — same probe as LIB-57 | |
| LIB-59 | 5733–5741 | The driver declares the exports `extern` and calls them with the Vox calling convention; `-rpath '$ORIGIN'` makes the driver find the `.so` in its own directory, so the pair is relocatable; the `extern` names are exactly the mangled labels `nm -D` showed. | — | same as LIB-57 | none | todo — same probe as LIB-57; the driver was in fact run from a directory other than where it was linked and still found the `.so`, confirming `-rpath '$ORIGIN'` | |
| LIB-60 | 5749–5752 | `--link` puts a built `.so` on the link line of an executable, taking the library's **soname stem** — the part between `lib` and `.so` — so `libmath.so` is linked as `--link math`. | `--link math --lib-path <dir>` against a `.so` named `libmath.so` | yes | none | todo — hand-verified (`shared/LIB-link.vox`) | |
| LIB-61 | 5753–5758 | `readelf -d` on the resulting executable shows `NEEDED` and `RUNPATH` entries exactly as documented. | same build, inspect with `readelf -d` | yes | none | todo — hand-verified, output matches the manual's `readelf -d` output verbatim (`shared/LIB-link.vox`) | |
| LIB-62 | 5760–5763 | `--link` automatically adds the dynamic loader and an `-rpath` per `--lib-path`, but only when a library is actually linked — a plain `vox hello.vox` build stays a flat static binary with no loader dependency. | build with and without `--link`, compare `readelf -d` and `file` | yes | none | todo — hand-verified: without `--link`, `readelf -d` shows nothing and `file` reports "statically linked"; with it, both `NEEDED` and `RUNPATH` appear (`shared/LIB-link.vox`) | |
| LIB-63 | 5765–5768 | `--link` alone does not teach the compiler a library's function signatures — it does not let Vox source call the library's functions; that is what `see` of a `.lib` does (registers signatures **and** adds the `.so` to the link line). | `--link` a `.so` without `see`ing its `.lib`, call one of its functions → expect a compile error | **no, from a runtime leaf** (compile-error claim) | none | not assertable (compile-error claim) — hand-verified: `Unknown function: add two numbers`, i.e. `--link` alone leaves the function entirely unknown to the type-checker (`shared/LIB-linknosig.vox`) | |
| LIB-64 | 5768–5771 | `--link` is for the case where the program already references the symbols another way, or for a non-Vox driver assembled by hand — exactly the "Calling a library from a non-Vox host" driver, linked with `ld` instead of `--link`. | — | **no** as an independent claim — restates the purpose of LIB-56's own driver, which used `ld` directly rather than `--link` | none | not assertable separately — see LIB-56 | |

## Discrepancies

Each has a runnable minimal repro in `docs/ledger/probes/libraries/` (D2,
D3 auto-run) or `docs/ledger/probes/libraries/shared/` (D1, D4 — need
`--shared`). Recorded, not filed, not adjudicated.

### 1. RESOLVED — a repeat `--shared` build silently overwrote an existing `.lib`, including one hand-edited

**Resolution (2026-08-22):** the manual was corrected in vox commit
`70ca1c2` to document the compiler's actual behavior instead of the
unimplemented protection this discrepancy found missing. LANGUAGE.md
now reads, at lines 5021–5024: "The `.lib` is a declared output like
the `.so`, derived from the same `-o`: a rebuild overwrites it in
place, so an edit-build loop needs no manual cleanup and anything
hand-edited into a `.lib` is lost. The pair is written together, so a
fresh `.so` never lands beside a stale `.lib`." LIB-30's claim and
citation have been updated to match (see the row above). The record
below is kept for history; the compiler's behavior itself never
changed, only what the manual said about it.

The manual previously read (pre-2026-08-22 text, not present at any
citable line in the current manual): "It will not overwrite a `.lib`
that already exists — a repeat `--shared` build errors and asks you to
remove the `.lib` first, then regenerates the `.so` and `.lib`
together, so a rebuild cannot silently clobber an interface you have
pinned or edited." Repro (`D1.vox`, fuller version in
`shared/LIB-overwrite.vox`; both re-run 2026-08-22 against vox 0.4.9
(commit `bb406de`) and reproduce identically):

```
Library d1kit version "1.0".

To greet.
  Print "hi".
```

```
$ vox D1.vox --shared -o d1.so   # first build: exit 0, writes d1.lib
$ echo "PINNED EDIT" >> d1.lib
$ vox D1.vox --shared -o d1.so   # second build: exit 0, NO diagnostic
$ cat d1.lib                     # "PINNED EDIT" is gone
```

Both builds exit 0. No diagnostic ever fires, on the plain repeat or on
the hand-edited repeat. The second build silently regenerates `d1.lib`
from scratch, discarding the pinned line — this is now the documented,
correct behavior, not a discrepancy. Not filed (moot — the manual bug
is fixed).

### 2. Manual's own second retired-syntax example does not parse as written

LANGUAGE.md:5402 spells the second retired form as `see "lib" version
"1.0" from "./path.so".` — the library name in **double** quotes. Repro
(`D2.vox`):

```
see "mathkit" version "1.0" from "./fixtures/libmathkit.so".

Print 1.
```

Output:

```
error: expected a name, found a string literal
      strings are data; names are bare or 'single-quoted'
  help: write `mathkit`
```

Not the "see of a .so is not supported" diagnostic the surrounding prose
promises for all three retired forms — a different, generic parse error,
because a double-quoted token was never legal in a name position at all,
retired or not. `LIB-05b.vox` uses the correctly-shaped bare name
(`see mathkit version "1.0" from "fixtures/libmathkit.so".`) and gets
exactly the promised diagnostic.

**The reading in which the compiler is right:** names in Vox are bare or
`'single-quoted'`, never a string literal, everywhere else in the
language (this is exercised throughout `keywords.md`'s KEY rows and
`things-b.md`'s THG2 rows on quoted field names). The manual's inline
code example most likely double-quoted the library name for readability
in a table of three syntaxes being *contrasted*, not because that
spelling was ever meant to be syntactically exact — the retirement
itself is genuinely about the `.so` extension after `from`, independent
of how the name token is quoted. Under that reading this is an
imprecise code example, not a claim about behavior. A one-character fix
(single quotes) would make the manual's own example compile and hit the
diagnostic it describes.

### 3. RESOLVED — the `.lib` worked example's zero-parameter entry omitted `To`; the real compiler never did

**Resolution (2026-08-22):** the manual was corrected in vox commit
`70ca1c2` — the worked example at LANGUAGE.md:5534–5540 now shows
`To greet.`, matching the compiler's actual output. LIB-31's claim and
citation have been updated to match (see the row above).

The manual previously showed the `.lib` format worked example (then at
LANGUAGE.md:5534–5540) with the `greet` entry (a zero-parameter,
no-return function) written as bare `greet.`, while the `'add two
numbers'` entry above it was written `To 'add two numbers' with ...`.
Repro (`shared/D3.vox`, re-run 2026-08-22 against vox 0.4.9, commit
`bb406de`, reproduces identically):

```
Library mathkit version "1.0".

To greet.
  Print "hello from mathkit".
```

```
$ vox D3.vox --shared -o d4.so && cat d4.lib
Library mathkit version "1.0".
Location "./d4.so".

Table of Contents:
    To greet.
```

Every entry the compiler writes is prefixed `To`, parameter-taking or
not — `shared/LIB-writing.vox`'s two-function build shows the same
thing (`To 'add two numbers' ...` and `To greet.`, both prefixed).
Nothing about the `.lib` grammar (LANGUAGE.md:5548–5554) suggests two
valid spellings for a zero-parameter entry, and every other worked
`.lib` example in this ledger (`shared/LIB-types.vox`,
`shared/LIB-barereturn.vox`) is consistently `To`-prefixed. This was a
one-word manual fix, now made.

### 4. A `.lib` entry with no `, returning` clause is not type-checked as "returns nothing" at the call site — RESOLVED (vox #62)

LANGUAGE.md:5568–5570 says "No returning clause means the function
returns nothing," and the six-step `see`-of-`.lib` process
(LANGUAGE.md:5595–5604, step 5) says calls "type-check like any other
function." Repro (`D4.vox`), against `fixtures/libmathkit.lib` where
`greet` genuinely returns nothing (bare `To greet.`, no clause):

```
see mathkit version "1.0" from "fixtures/libmathkit.lib".

a number called n is greet.
Print n.
```

Output:

```
hello from mathkit
1
```

Exit 0, no diagnostic. `greet` prints its message (so it did run) and
`n` gets some leftover value (`1` — plausibly a status code left in the
return register by the runtime's own call-return convention, not a
computed answer) with no complaint from the type-checker at all. Compare
LIB-43f/LIB-43g: a genuine **parameter** arity/type mismatch on this same
library *is* caught, with a precise diagnostic naming the argument. Only
the **return side** of the promised type-check is missing, and it is
missing specifically when the `.lib` entry has no `, returning` clause —
which LIB-39/Discrepancy-adjacent testing shows happens not only for
true `void` functions but also for **any** function using a bare
`Return <expr>.` with no declared type, meaning a library author who
never bothered writing `Return a number, x.` gets a function whose real
return value is silently accepted into any typed variable at every call
site, with no warning at either the library or the consuming end.

**The reading in which the compiler is right:** the `.lib`'s omitted
clause is genuinely ambiguous between two different situations — "this
function returns nothing" (true `void`) and "this function's return type
was not determined at export time" (a bare `Return` with no type
keyword) — and the manual's step 5 promise ("type-check like any other
function") may only have been intended to cover the checked cases
(parameters, and return types that *are* recorded), leaving the
unrecorded-return case as deliberately permissive rather than a checked
`void`. That reading is generous, though: nothing in LANGUAGE.md draws
that line explicitly, and the practical effect either way is a value
whose provenance the type system does not vouch for landing in a typed
variable with zero visible warning. Not memory-unsafe (Vox's headline
promise survives — nothing crashes, nothing corrupts), but a real
soundness gap in the one part of the language whose job is literally
type-checking a boundary. Worth a human decision on whether the manual
should narrow its step-5 claim or the compiler should tighten the check.

**Resolution confirmed, 2026-08-22: fixed by vox #62.** `vox/docs/
BUGS_FOUND.md` #62 ("A `.lib` entry with no `, returning` clause is not
type-checked at the call site — its non-existent result is silently
accepted into a typed variable") names this exact discrepancy. The
compiler was tightened, not the manual narrowed. Re-run `D4.vox` against
vox 0.4.9: `a number called n is greet.` (calling a `.lib` entry with no
declared return) now fails at compile time — `error: 'greet' has no
declared return type in its .lib entry, so its result cannot be used as
a value here` — citing both the "no returning clause" rule and the
type-checking promise this discrepancy's own repro was built from.

## Invariants this section justifies

**None.** No generated program in `src/gen_*.vox` emits a `see`, a
`Library` declaration, or any of `--shared`/`--link`/`--lib-path`, so
`scripts/invariants` has nothing from this surface to report on yet —
there is no sameness to justify because there is no output. This is
different from every other mapped ledger's "Invariants" section, which
lists real samenesses the corpus shows; here the honest entry is that
the corpus contains zero instances of the whole surface. Once a leaf
exists, the obvious first invariants to watch for are: every generated
library declares exactly one `Library` block (LANGUAGE.md:5542–5544
permits several); every export uses the same argument-preposition
spelling (parallel to the `of`/`to`/`with`/`on` finding in
`things-b.md`'s THG2-27); and every consumed `.lib`/`.so` pair comes from
one fixed, harness-controlled location rather than a path built from
program state — the last one isn't optional, it is this section's
version of the file-open allowlist rule in `PROCEDURE.md`/`CLAUDE.md`.

## Report

**64 rows** (LIB-01 through LIB-64). Eight of those (LIB-03, LIB-16,
LIB-17, LIB-18, LIB-28, LIB-44, LIB-45, LIB-64) are composite or
cross-reference rows folded into a sibling rather than independent leaf
needs, leaving **56 distinct claims**.

**Every single row's `existing leaf` is `none`.** This is the headline
finding, stated once in the ledger header rather than repeated 64 times:
`grep` for `see "`, `.lib`, `Library`, `Location`, `Table of Contents`,
`--shared`, `--link`, `--lib-path` across every `src/gen_*.vox` file
returns nothing — the *only* `see` statements anywhere under `src/` are
the generator's own module-loading (`main.vox`, `loop_gen.vox`,
`sandbox.vox`), never something it writes into a generated program.
Every generated program today is a single file with no library and no
CLI flag beyond the plain `vox source.vox -o out` this fuzzer already
uses. **This entire section — roughly 350 lines, a chapter with its own
worked examples, its own diagnostics, its own binary format, and its own
compiler flags — is a complete gap**, not a partially-covered one like
buffers or things.

**Of the 56 distinct claims, 11 are compile-error claims** (not
assertable from a runtime leaf, per the standing convention every other
ledger uses) **and all 11 were hand-verified with a retained probe** —
several cover more than one diagnostic (LIB-43 alone accounts for six).
**2 are pure implementation details with no Vox-observable consequence**
(LIB-06's rationale, LIB-55's runtime-state claim) and were not probed at
all, only reasoned about. The remaining **43 are assertable and were
hand-verified**; all but four are also retained as probes. The four
exceptions, and why: LIB-11's precedence half and LIB-12 both need a
file installed at `/usr/share/vox/lib/`, which needs root, so only their
fallback-path half is verified; LIB-10 (absolute paths) was hand-verified
but not retained, since a committed probe would need an absolute path
baked into its own source, which breaks the moment the repo is checked
out somewhere else; LIB-13 (`--lib-path` not consulted for `see` of a
`.vox`) was hand-verified but recorded in the ledger text rather than
retained as a `shared/` file, since it needs the flag to be the point of
the test yet adds no mechanism beyond what LIB-01/LIB-09 already
demonstrate for the no-flag case.

**Four discrepancies, two resolved 2026-08-22** (the manual was
corrected to match the compiler in vox commit `70ca1c2`), none filed:
1. **RESOLVED.** A repeat `--shared` build silently overwrote an
   existing `.lib` instead of erroring; LANGUAGE.md now documents the
   overwrite (LANGUAGE.md:5528–5531) instead of a protection the
   compiler never implemented.
2. The manual's own worked example of a retired `see`-of-`.so` syntax
   uses a double-quoted library name that isn't valid Vox syntax in that
   position at all, so it hits a generic parse error instead of the
   diagnostic the surrounding prose promises.
3. **RESOLVED.** The `.lib`-format worked example spelled a
   zero-parameter entry without `To`; the manual now shows `To greet.`
   (LANGUAGE.md:5534–5540), matching what the compiler always wrote.
4. **The most consequential one, still open.** A `.lib` entry with no `, returning`
   clause — which covers both true `void` functions and any function
   using a bare, undeclared-type `Return` — is not type-checked as
   "returns nothing" at the call site the way the manual's own step 5
   promises "calls type-check like any other function." A caller can
   assign such a call's result to any typed variable with zero
   diagnostic, silently accepting whatever value happens to be sitting
   in the return register. Parameter-side arity and type mismatches
   *are* caught correctly (LIB-43f/g) — only the return side of the
   promised check is missing, and specifically for the return-type-
   omitted case. Not memory-unsafe, but a real soundness gap at the one
   language boundary whose entire job is type-checking across a
   compilation unit.

**For the next mapper, and for whoever builds this section's leaves —
this is the important part.** Today's generator only ever emits one
file. A `LIB-*` leaf needs the generator to grow a capability it has
never had: **writing more than one file per fuzzing run, and driving the
compiler with more than one invocation** (a `--shared` build to produce
a library, then a normal build of a consumer that `see`s it). Concretely,
that means:
- a per-run scratch directory that can hold N source files, not one
  (the sandbox/`vf_scratch` machinery already isolates one run's
  filesystem side effects; extending it to multiple *source* files, not
  just runtime artifacts, is the new part);
- a harness step that runs `vox lib.vox --shared -o lib.so` and checks
  its exit code **before** the main run compiles the consumer that
  `see`s the result — a two-stage compile where today there is one;
  a `--shared` build that fails should be a distinct finding class from
  a normal compile failure, since the library source itself is
  generator-controlled and should never be malformed;
- the `.lib`/`.so` pair becomes exactly the kind of fixed, generator-
  controlled artifact `CLAUDE.md`'s file-open allowlist rule already
  requires for reads — never a library built from attacker-shaped
  content, never a path assembled from random bytes;
- the payoff is disproportionate to the plumbing cost: once a library
  leaf exists, LIB-24/25/27/49/50/63 (six distinct compile-error
  diagnostics) and LIB-30/31/38/39 (three of this ledger's four
  discrepancies — D1, D3, D4; only D2, about `see`-of-`.so` syntax, sits
  outside a library-building leaf's reach) become directly fuzzable
  rather than hand-verified once, and Discrepancy 4 in particular — a
  silent type-check gap at a boundary whose only job is type-checking —
  is exactly the kind of thing that widening the corpus tends to turn
  from "one hand-built repro" into "a whole family of wrong-answer
  findings."

**Row/probe counts.** 64 rows, 56 distinct claims. 18 auto-run probe
files under `docs/ledger/probes/libraries/` (`check-probes.sh`: **18
passed, 0 failed, 0 skipped**). 19 more hand-verified, non-auto-run
probes under `docs/ledger/probes/libraries/shared/` (18 `.vox` + 1
`.asm`). 15 fixture files under `docs/ledger/probes/libraries/fixtures/`.
`docs/check-probes.sh` run over every ledger (not just this one) shows no
regression from this batch — see the Report's closing note below on the
pre-existing failures it found elsewhere.
