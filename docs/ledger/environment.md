# Claim ledger: Environment Variables

Source: `../vox/LANGUAGE.md` lines **4558–4632**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5240-line 0.4.8+ manual at commit b26f66e). The 0.4.8→0.4.9
drift in this range is a uniform **+87 lines**, confirmed at multiple
anchors.

**The one discrepancy is now resolved, re-verified directly against vox
0.4.9 — see below.** It was vox bug #58, and this ledger is literally
where it was found and named in `BUGS_FOUND.md`'s own entry.

This is a **gap analysis**, not a from-scratch map. `src/gen_misc.vox`
already has two leaves that touch this surface — `'gen leaf environment
inrange'` and `'gen leaf environment oob'` — both hardened against two
real historical bugs (#24: an unset lookup used to segfault,
uncatchable by `On error`; #26: out-of-range positional reads on an
empty environment used to crash) and both now deliberately collapse
everything they read to a boolean before printing, because an earlier
version printed raw host environment state (`environment's "PATH"`,
`environment's count`) directly and one such printout landed in a
checked-in test fixture on a public repo — see `gen_misc.vox:39–101` for
the full incident writeup. That history matters here: it's *why*
existing coverage on this surface is unusually shallow even by this
project's low bar — every existing read is deliberately reduced to a
boolean the moment it's read, so **no leaf has ever asserted an actual
value**, not even the loose "does the property exist" kind of check
other sections' `exercised` rows get credit for.

## Probes

`docs/ledger/probes/environment/`. Every property row got a fresh hand
run because none had one before. For the rows whose behavior depends on
a variable being **set** (`ENV-06`, the named lookup; `ENV-10`, the
exists predicate; `ENV-11`, the composite precedence example),
`check-probes.sh` only re-runs a probe's `Ran:` line as written for
**stdin-feed** probes (see `docs/check-probes.sh`'s own comment) — so
each of those files records the **unset/default** run as its checked
`expected output:` block (the one `check-probes.sh` verifies) and the
**set** run(s) as a second, unchecked comment block beneath it, exactly
as the brief specifies. `D1.vox`/`D1b.vox` are the minimal repros for
the one discrepancy — a buffer declared directly from an `environment's
<property>` expression never receives the string's content, which is
why `ENV-03`/`ENV-04` route through an intermediate `text` variable
instead (see their own header comments), and why `ENV-06`'s row above
flags that the *existing* leaf reads straight into a buffer, the broken
path.

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| ENV-01 | 4886 | Environment variables are accessed "using the `'s` property syntax." | — | **no** — a framing statement about *how* the rest of the section's properties are spelled, not itself a fact with a value; exercised by every row below that uses `'s` | every row below | not assertable (framing) | |
| ENV-02 | 4890–4892 | `count` — `environment's count` — "Total number of environment variables." | read `count`, and cross-check it against `empty` on the same process (count is 0 iff empty is true — the two properties can't disagree about the same environment) | yes — `If (env's count is 0) is not (env's empty) then, Exit 95.` — a real oracle with no reference implementation, since the generator never needs to know the *actual* count, only that the two agree | `gen leaf environment inrange` reads count but immediately collapses it `as a boolean` (nonzero → true) and never reads `empty` in the same leaf to cross-check | **verified** — `gen leaf environment agreement` asserts count 0 ⇔ empty, both directions (batch A, 2026-08-21) | `gen leaf environment agreement` (ASSERT ENV-02) |
| ENV-03 | 4890, 4893 | `first` — `environment's first` — "First env var (full `"NAME=value"` string)." | read `first`, assert it is well-formed: scan its bytes for a `=` (buffer byte-scan, the same construct `BUF`'s byte-access rows establish) | yes, via a byte scan — heavier than a one-line assertion but doable with existing constructs; on an **empty** environment (`env -i`) `first` returns an empty string with no error, which the scan must special-case as vacuously fine, not a failure. **Must read into a `text` first, then a buffer from that `text` — a buffer declared directly from `environment's first` is broken, see Discrepancy 1** | none — no leaf reads `first` at all | **verified** — `gen leaf environment entry scan` asserts a non-empty `first` contains `=`; `gen leaf environment lookup` asserts two readings of `first` agree in size/empty (batch A) | `gen leaf environment entry scan`, `gen leaf environment lookup` (ASSERT ENV-03) |
| ENV-04 | 4890, 4894 | `last` — `environment's last` — "Last env var." | same as `ENV-03`, on `last` | yes, same construct, same two-step caveat | none | **verified** — same two leaves, on `last` (batch A) | `gen leaf environment entry scan`, `gen leaf environment lookup` (ASSERT ENV-04) |
| ENV-05 | 4890, 4895 | `empty` — `environment's empty` — "True if no environment variables." | see `ENV-02` — this is the same cross-check, filed from the other side | yes — same assertion as `ENV-02` | `gen leaf environment inrange` reads `empty` and prints it directly, unasserted | **verified** — `gen leaf environment agreement` asserts empty ⇔ count 0 (batch A); the buffer-direct `empty` read D1 describes is now asserted against the text copy by `gen leaf environment lookup` and FIRES (see Discrepancy 1) | `gen leaf environment agreement` (ASSERT ENV-05) |
| ENV-06 | 4890, 4896 | `"NAME"` — `environment's "HOME"` — "Value of specific env var by name." | look up a variable whose value the generator itself controls, assert an exact match | yes, and exactly — `If v is not "expected" then, Exit 95.` — but this needs a companion to `gen_argv` (the argv oracle, `gen_misc.vox:7–25`) that does not exist today: something that lets the generator choose a `NAME=value` pair and have the **harness** set it before `exec`ing the generated binary, the same way `gen_argv` is chosen by the generator and handed to the run. No such mechanism exists for environment variables — `runner.vox`'s `'run program'` family execs the binary inheriting whatever environment the harness process itself has, uncontrolled by the generator. `PATH` (what the existing leaf reads) is real host state, not a generator-chosen value, which is exactly why the leaf can only check `empty`, never a value | `gen leaf environment inrange` reads `environment's "PATH"` but immediately routes it through a buffer's `empty` property, never comparing content; `gen leaf environment oob` reads a **guaranteed-unset** name (`VOXFUZZ_UNSET_<random>`), which exercises the miss path, not the hit path | **verified (agreement)** — `gen leaf environment lookup` asserts the same name read into text/buffer/value agrees in size, empty and value; the exact value still needs an env oracle in the harness (gap). Campaign 2026-08-21: 16/300 seeds fire ASSERT ENV-03/06 — Discrepancy 1 | `gen leaf environment lookup` (ASSERT ENV-06) |
| ENV-07 | 4898–4907 | Worked example "Reading Environment Variables": `HOME`/`USER`/`SHELL` read by name and printed. | — | yes, same construct as `ENV-06` | none | folded into `ENV-06` — same construct, three fixed names instead of a generator-chosen one; also note the manual assumes these three are always set, which held on the probe host but is not guaranteed by anything in this section | |
| ENV-08 | 4909–4915 | Worked example "Environment Variable Count": reads `count` into a quoted multi-word name (`'env count'`) and prints it. | — | yes | none | folded into `ENV-02` — same construct, notable only for using a quoted multi-word local name (`'env count'`), a form no *environment* leaf currently emits (see `VAR-51`, which already flags this as the one leaf-wide instance of a quoted variable name, on the sibling `oob` leaf, not this one) | |
| ENV-09 | 4917–4923 | Worked example "Iterating Environment Variables": reads `first` once and prints it. | — | yes, same construct as `ENV-03` | `gen leaf environment inrange` reads `first`? no — see `ENV-03`, nothing does | folded into `ENV-03` — and worth flagging: the heading says "Iterating" but the body reads `first` exactly once; there is no `second`/index/`all` for `environment` anywhere in this section (checked: `grep -n "environment"` across the whole manual finds nothing beyond this section and one Keywords cross-reference), so there is no actual iteration construct to map. Not a contradiction — the heading is just loosely named after "the first thing you'd read in a loop" — noted here so the next reader doesn't go looking for an `environment's second` that isn't documented anywhere | |
| ENV-10 | 4925–4930 | "Checking if Variable Exists": `If the environment variable "DEBUG" exists then,` is a predicate, true iff the named variable is set. | emit the predicate against both a set and an unset name, assert both branches | yes — the generator controls which case it's testing (a var it happens to control the presence of, vs. the guaranteed-unset `VOXFUZZ_UNSET_<random>` name the `oob` leaf already draws) | **none** — `gen leaf environment oob` tests the *lookup* form (`environment's "NAME"`) wrapped in `On error`, which is a different construct from this section's documented `exists` predicate; `grep -n "environment variable.*exists"` across `src/*.vox` finds this predicate only in `runner.vox` (the harness's own bootstrap code, not a generated-program leaf) | **verified** — `gen leaf environment exists` asserts two readings agree and an invented name does not exist; `gen leaf environment lookup` asserts `exists` false on its invented names (batch A) | `gen leaf environment exists` (ASSERT ENV-10) |
| ENV-11 | 4932–4953 | "Complete Example": composite — argument-count check, `arguments's first` vs. the `GREET_NAME` exists-and-lookup fallback, then a plain `USER` lookup. | reproduce verbatim under three conditions: no args/no env, `GREET_NAME` set, an argument passed | yes, entry-wise (each sub-claim is `ARG`'s or this ledger's own row) | none reproduces the composite as one program | **exercised** — `gen leaf environment exists` emits the Complete Example's shape (argument check, `But if … exists` fallback, lookup) with an invented fallback name; entry-wise assertions are ENV-10's (batch A) | `gen leaf environment exists` |
| ENV-12 | 4955 | "The argument and environment variable functions are only included in the binary when used, keeping programs that don't need them small and efficient." | — | **no** — not observable from inside a Vox program; requires comparing two compiled binaries from outside | n/a | not assertable — hand-verified externally anyway: a program using only `Print "hello".` compiled to 6640 bytes, a program that additionally reads `environment's count` compiled to 7200 bytes (+560), confirming the feature is not always linked in | |

## Discrepancies

### 1. A buffer declared directly from an `environment's <property>` expression never receives the string's bytes — `'s size` is `-1` and `'s empty` reports `false` on a buffer that prints as empty — RESOLVED (vox #58)

None of this section's own prose is contradicted — `environment's
"PATH"`, `first`, and `last` all return the right *text* when read
into a `text`-typed variable (confirmed for every property row above).
The bug is one property-copy step later: LANGUAGE.md never says a
buffer can be declared directly from a `'s` property read at all, but
the general declaration-form claim it inherits from `BUF-01`/`BUF-25`
("a buffer accepts any value type on every write", `VAR-40`, and the
buffer-from-string-literal worked example) implies it should — buffers
are documented to accept text from *any* expression that produces text,
not just a literal or a plain variable. It doesn't:

Repro (`D1.vox`):
```
a buffer called pathbuf is environment's "PATH".
print "content:". print pathbuf.
print "size:". print pathbuf's size.
print "capacity:". print pathbuf's capacity.
print "empty:". print pathbuf's empty.
```
Output:
```
content:

size:
-1
capacity:
4096
empty:
0
```

The buffer's content is empty (nothing was copied in), its `size` is
`-1` (never documented as a possible value — `BUF-10` says `size` is
"current bytes stored", a count of bytes, which cannot be negative),
its `capacity` is the ordinary dynamic-buffer initial reserve (the same
4096 `BUF` Discrepancy 1 already flags — consistent with a normal empty
dynamic buffer having been allocated), and `empty` reports **false**
even though the content is visibly empty and the size is negative — the
one property this section's own leaf actually reads is the one that
lies. Declaring a `text` from the same expression first, then a buffer
from that `text` (two steps instead of one), works correctly in every
case — see `ENV-03.vox`. `D1b.vox` reproduces the identical failure on
`arguments's first`, confirming the bug is "declare a buffer directly
from a `'s` property-read expression", not anything specific to
`environment` — this section just happens to be where the existing
leaf (`gen leaf environment inrange`, `gen_misc.vox:82–90`) does exactly
that and has been silently exercising the broken path since it was
written, without ever noticing because the one property it checks
(`empty`) is the one that reports the wrong answer.

**Strongest reading under which the compiler is correct:** a buffer's
documented initializer forms (`LANGUAGE.md:3727–3732`'s worked example,
`BUF-25`) are all either a byte count or a plain string *literal* — the
manual never actually shows a buffer declared from an arbitrary
*expression*, let alone a `'s` property read specifically. Under a
narrow reading, `a buffer called X is <expression>.` for a non-literal,
non-plain-variable expression is simply outside every example the
manual gives, so nothing guarantees it copies the expression's value
at all — the compiler could be silently taking a fast/lazy path here
(allocate storage, defer the copy, and something in that deferral is
what leaves `size` at a sentinel `-1` and never runs to set `empty`
correctly) rather than plainly failing to implement the documented
value-copy semantics. That reading is generous, though: `pathbuf's
type` in this same repro correctly reports `Buffer (static)` and its
`capacity` is a plausible real allocation, so *something* ran the normal
buffer-construction path — it just never ran the *copy*. Not filed at
the time; repros retained in `D1.vox`/`D1b.vox`.

**Resolution confirmed, 2026-08-22: fixed by vox #58.** `vox/docs/
BUGS_FOUND.md` #58 ("A buffer declared from a text-valued property...
is silently re-typed as text — size -1, prints nothing, and on `Set`
loses its bounds") names this exact discrepancy as its origin — found
by this ledger, re-found by the environment leaves' own assertions (2 of
40 seeds), master-reproduced on 0.4.8, and fixed as a memory-safety
issue (the `Set` half dropped a fixed buffer's bounds check). Re-run
directly against vox 0.4.9: `D1.vox`'s `pathbuf` now receives the real
`PATH` content (`'s size` matches the real string length, no longer
`-1`; `'s empty` correctly reports `false` only because there
genuinely is content now) and `D1b.vox`'s `ab` correctly holds `"hello"`
(size 5) when run with that argument. Both probes re-recorded with
sizes/booleans only, per this project's own rule against printing raw
host state into a checked-in file (`gen_misc.vox:39–101`'s incident) —
`PATH`'s actual byte count varies by host and was not itself asserted
against a fixed value, only checked as non-negative and matching a
second reading.

The other thing worth recording without a full Discrepancy entry is
`ENV-09`'s note above: the "Iterating" heading has no iteration
construct behind it in this section — a documentation-clarity
observation, not a manual-vs-compiler conflict, so it doesn't get a
numbered entry of its own.

## Invariants this section justifies

None yet — no leaf on this surface asserts anything today (see Report),
so there is nothing here for `scripts/invariants` to have flagged as a
pattern this section's leaves are responsible for. Once `ENV-02`/`05`'s
cross-check and `ENV-06`'s named-lookup assertion are built, the
`ASSERT ENV-NN` exit-95 message format itself becomes the first
justified invariant (cite this ledger + `PROCEDURE.md` §6).

## Report

**12 rows** (`ENV-01` through `ENV-12`). Three fold into another row in
this same ledger (`ENV-07`/`ENV-08`/`ENV-09` are the section's own
worked examples, each restating a property row above with fixed names
instead of generator-chosen ones); two are not assertable from inside
Vox (`ENV-01`, framing; `ENV-12`, a binary-size claim, hand-verified
externally instead). That leaves **7 independently assertable rows**,
and every one of them is a real gap: `count`/`empty` are read but never
cross-checked (`ENV-02`/`ENV-05`); `first`/`last` are never read at all
(`ENV-03`/`ENV-04`); the named lookup is read only for uncontrolled host
state (`PATH`) and only ever collapsed to a boolean, never compared
against a known value (`ENV-06`); the `exists` predicate this section
documents is never emitted by any leaf — the existing `oob` leaf tests a
different construct entirely, a direct lookup wrapped in `On error`
(`ENV-10`); and the Complete Example's three-way precedence is untested
by any leaf even though it's a real, fully worked oracle (`ENV-11`).

**Biggest finding — the one discrepancy**: it was hiding directly
underneath this section's one existing leaf. `gen leaf environment
inrange` declares a buffer directly from `environment's "PATH"` and
asserts only that buffer's `empty` property — and that specific
property is the one that silently lies (`false`, on a buffer whose
content is empty and whose `size` is `-1`). The leaf has been
"exercising" this construct without ever detecting that the copy it
depends on never happens. This isn't environment-specific at the
implementation level (`D1b.vox` reproduces it on `arguments's first`),
but it's this section's leaf that has been running on the broken path
the whole time — exactly the kind of thing hand-verifying a claim
instead of trusting a comment is supposed to catch (see `CLAUDE.md`'s
own three-wrong-claims-in-an-hour warning — this is a fourth, later,
different flavor of the same lesson).

**Second finding, infrastructure rather than a bug**: unlike every
other row, `ENV-06` (the named lookup) can't be closed by writing a
leaf alone — asserting an exact value requires the generator to
*choose* the value, which requires a harness-level mechanism to set
that variable before the generated binary execs, and no such mechanism
exists. `gen_argv` already solves exactly this problem for
command-line arguments (`gen_misc.vox:7–25`); the natural fix is a
parallel `gen_envvars`-style list that `loop_gen` reads and applies the
same way it applies `gen_argv` to both of the oracle's runs. Until that
lands, `ENV-06`, `ENV-07`, and `ENV-11`'s env-var half are all blocked
on the same missing piece of infrastructure, not on leaf-writing
effort.

**For the next section's mapping:** when a section's existing leaves
were built specifically to fix a leaked-secrets incident
(`gen_misc.vox:39–101`), read that incident writeup before touching
anything — it explains real, load-bearing design constraints (never
print raw host state, always counter-suffix local names even in a
"safe closer" leaf) that look like arbitrary caution until you know
what they're defending against. Also worth carrying forward: before
concluding a construct "needs a new harness mechanism," check whether
an existing mechanism (`gen_argv`) already solves the identical shape
of problem for a different surface — `ENV-06`'s gap is not a new kind of
problem, it's the same argv-oracle problem this project already solved
once, unapplied to a second construct.
