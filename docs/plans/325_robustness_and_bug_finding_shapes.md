# Plan 325 — robustness, and the shapes that actually find bugs

**Status:** approved by TheJostler, 2026-08-19 (night), from the
evening's audit — full record in
`~/scr/english/vox-notes/2026-08-19-evening-bug-audit.md`.
**Relation to other plans:** 323 is *breadth* (emit every construct),
324 is *shape* (vary the skeleton, add I/O). This plan is the rest: two
robustness defects the fuzzer has in itself, and the specific generator
shapes that would have caught the compiler bugs found tonight.

The organising fact of the evening: **the fuzzer found none of the three
compiler bugs.** #28, #29 and #30 all came from auditing why it *could
not* reach them. This plan closes those specific blind spots and hardens
the tool against reporting work it did not do.

---

## Task 1 — finish the concurrency fix (defect D1)

**This is the top priority; it makes the tool trustworthy or not.**

Two `gen` runs from the same directory fabricate findings: measured at
**1,260 false findings** across two campaigns on 2026-08-19, every one a
program that compiles cleanly by hand. A partial fix
(`fix/fuzzer-defects-worker`, unmerged) adds a per-run scratch directory
`vf_scratch/run_{pid}_{seed}` and cuts it to ~40 per concurrent run —
**but does not eliminate it, and now produces ~1 false finding even in a
solo run** (audit finding N). So the residual cause is *not* scratch
collision; concurrent compiles of identically-named sources in separate
directories were tested directly and do not collide.

- [ ] Find the residual cause. Prime suspect from the audit: scratch
      directory creation (`make directories`) failing or racing, so
      `vox` cannot write its output and exits non-zero, which the
      classifier then correctly reports. Confirm by compiling the exact
      `program.vox` of a fabricated finding by hand — it will pass —
      then instrumenting the fuzzer's own compile step to capture what
      `vox` actually saw.
- [ ] The fix must satisfy the real gate: **two simultaneous runs of
      ~60 seeds each, zero findings**, AND **a solo run of 60 seeds,
      zero findings** on a compiler known good. The partial fix meets
      neither.
- [ ] Salvage the good parts of the unmerged branch (per-run scratch
      dir, per-seed cerr path, shell-quoting) — they are correct and
      worth keeping; do not start from scratch.

## Task 2 — abort loudly on an unusable scratch directory (defect D2)

A run whose working directory was deleted mid-flight completed through
**2,817 `getcwd` errors**, compiled nothing, and reported `findings: 0`.
A fuzzer that cannot compile must not report a clean sweep.

- [ ] At startup, probe the scratch directory: write a file, read it
      back, delete it. Exit non-zero with a clear message on failure.
- [ ] Consider a mid-run guard too: if the compile step's stderr file
      cannot be read at all (not "compile failed" but "could not run
      the compile"), treat it as fatal, not as a finding.
- [ ] Test: point a run at an unwritable location; assert non-zero exit
      and a message, not `findings: 0`.

## Task 3 — emit the shapes that find the bugs we actually hit

Each of these is a construct the generator cannot currently produce, and
each maps to a real compiler bug it therefore could not find.

- [ ] **A string literal that spells an in-scope variable name.** THE
      highest-value shape: it would have found compiler bugs **#29 and
      #30 unaided** (a list-element literal colliding with a list/number
      variable → segfault or silent wrong data; a buffer initialiser
      colliding with a buffer variable → silent wrong data). Emit at a
      modest rate, as a list element and as a buffer initialiser. Note
      the compiler fixes are now on `main`, so these programs should
      pass — a finding here is a *new* bug, reported with its seed.
- [ ] **`Break` and `Continue`.** Measured 0 of 40 programs — the only
      construct at literally zero. Emit inside `For each` and `While`
      bodies, termination bounded by construction.
- [ ] **Declarations in varied order** — deferred to plan 324 Part A,
      cross-referenced here so the connection to bug #28 is not lost:
      #28 turned entirely on a conditional declaration *preceding* a
      top-level one, an order the generator never emits.
- [ ] **A flag schema, parsed and read from inside a function.**
      (added 2026-08-20) Would have found #31 and #32 unaided: declare
      one flag of each value type, some with defaults and some without,
      `Parse flags.`, then read every flag *both* at top level *and*
      inside a called function — #32 was invisible at top level. The
      harness runs programs with no arguments, so undefaulted flags
      exercise the "unsupplied" path (#31's crash site) for free; a
      later variant can pass seeded flag values once plan 324 T3's
      input axis lands.
- [ ] **Predicates with knowable answers.** (added 2026-08-20) `is
      empty` on a freshly-declared `""` text, an `[]` list, a new
      buffer — and their non-empty twins — plus `even`/`odd`/
      `positive`/`negative`/`zero` on constants. #33 (`is empty` on a
      text always false) was a wrong-answer bug, not a crash: no
      signal-death oracle can see it. Where the generator knows the
      truth value at emission time, it can branch to `Exit` with a
      distinct code on the wrong answer, turning a silent lie into a
      detectable exit — a poor man's output oracle that needs no
      harness change.

## Task 4 — emission-rate reporting

Nobody knew until 2026-08-19 that buffers appear in 37/40 programs and
`Break` in 0/40. A construct emitted 1-in-1000 is nearly as invisible as
one never emitted, and today that measurement was done by hand.

- [ ] A `vox-fuzz coverage` subcommand (or a script) that generates N
      programs and reports, per construct, how many contained it.
- [ ] Check it in as a report and refresh it per release, so a coverage
      regression (a construct that quietly stops being emitted) is
      visible. This is the generator-side complement of `SEEDS.md`.

## Task 5 — the remaining red-team coverage gaps (breadth)

Beyond the four highest-value gaps closed under 323, the 2026-08-19
generator red team catalogued these, still open, verified against
current `main`. Rank by crash-likelihood; none is urgent, all are
insurance. Full findings + PoCs:
`~/scr/english/vox-notes/2026-08-19-generator-redteam/`.

- [ ] **Nested collections** — lists inside lists, maps inside lists,
      whole-collection printing (finding 02).
- [ ] **Buffer surface beyond fixed byte access** — resize, copy,
      append, `as text` (finding 03).
- [ ] **`value` across a function boundary** — passed as a parameter,
      returned (finding 04).
- [ ] **`nothing`** — the null literal, in list slots and returns
      (finding 05).
- [ ] **Thing equality, free-function calls, non-number fields**
      (finding 06).
- [ ] **Type predicates** — `is a number` etc. on mixed-list elements
      (finding 07).
- [ ] **`.lib` libraries / multi-file programs** — the whole
      `Library`/`see` surface (finding 08; note bug #18 lived here).
- [ ] **Format-string specifiers and escapes** — `\n`, `\t`, `{{`/`}}`
      (finding 18; note bug #10 lived here).
- [ ] **Comments** — generated programs never contain `(a comment)`
      (finding 16).

## Explicitly NOT in this plan

- **The compiler-side string-literal-as-name audit.** That is a *vox*
  ticket, not a vox-fuzz one — the fuzzer finding the bugs is Task 3
  here; fixing the family in the compiler is
  `vox/docs/plans/` (filed separately, 2026-08-19).
- **The unreproduced test flake** — tracked in `FUZZER_DEFECTS.md`
  entry 4, not here; it needs a reproduction before it needs a plan.

## Acceptance for the plan as a whole

Tasks 1 and 2 are the gate on calling the tool "tamed": the fuzzer must
never report a finding it cannot reproduce by re-compiling the program,
whether run once or ten times over. Tasks 3–5 are measured by the
coverage report from Task 4 showing each construct emitted at a
non-trivial rate, and by the string-collision shape being present —
because that shape is the one the whole evening argues for.
