# Brief: map every claim in the {SECTION} section to the leaf that would prove it

You are the WORKER. Work in THIS worktree on the branch you are on. Do
NOT spawn agents. Do NOT commit and do NOT push — stop and report.

**You are writing a document and probe programs, not generator code. Do
not modify `src/`.** Read `CLAUDE.md` and `docs/ledger/PROCEDURE.md`
first; the reference ledger you are imitating line for line is
`docs/ledger/buffers.md` with its probes in `docs/ledger/probes/buffers/`.

## Your section

**{SECTION}**, `../vox/LANGUAGE.md` lines **{FROM}–{TO}** (manual version
{VERSION}). Row prefix **`{PREFIX}`**. Output file
`docs/ledger/{SLUG}.md`, probes in `docs/ledger/probes/{SLUG}/`.

## What to produce

1. `docs/ledger/{SLUG}.md` — header (section, line range, manual version,
   "gap analysis, not a rewrite"), then the table with exactly these
   columns in this order: `id | line | claim | leaf needed | assertable? |
   existing leaf | status | verified by`. One row per claim; what a claim
   is, and the status vocabulary, are defined in PROCEDURE.md §2–3.
   Leave `verified by` blank.
2. One retained probe per hand-verified row, `probes/{SLUG}/{PREFIX}-NN.vox`,
   in the format of PROCEDURE.md §4 (comment header with the command and
   the ACTUAL output). Run every probe with
   `VOX_CORE_PATH=/home/josj/scr/english/vox/coreasm
   /home/josj/scr/english/vox/target/release/vox probe.vox -o p && ./p`.
3. A **Discrepancies** section: numbered, minimal repro saved as
   `probes/{SLUG}/D<n>.vox`, the lines cited, and the strongest reading
   under which the compiler is CORRECT. Record and stop — do not file, do
   not decide. A manual that contradicts itself is a discrepancy too.
4. **Invariants this section justifies**: every sameness the manual
   requires of generated programs in this area (blank line closes a
   function; index starts at 1; …) with line and row ID.
5. A short **Report** at the end: row count, how many assertable, the
   biggest finding, advice for the next section's mapper.

## How to find the existing leaf

`grep -n` the accessor or keyword in `src/gen_*.vox` (`'s capacity`,
`shrink`, `Set byte`) — never judge by leaf name. Say precisely what is
missing when a leaf covers a claim partially.

## Traps this repo has actually sprung

- Without `VOX_CORE_PATH` you silently test the installed runtime.
- `On error` binds to the statement BEFORE it and consumes its whole
  sentence — a comma after the handler's action pulls the next action
  into the handler (LANGUAGE.md ~3564). A handler placed before the
  operation catches the previous statement.
- A blank line closes every open block at once; function bodies end at a
  blank line, not a period.
- Your surprise is not evidence: on 2026-08-20 three confident
  misreadings of the buffer section happened in an hour. Run the probe.

## Report what you could not do

If a claim cannot be probed (needs root, a device, a second process),
say so in the row rather than guessing. If this brief is wrong about the
line range or the section's contents, say so and map what is really
there.
