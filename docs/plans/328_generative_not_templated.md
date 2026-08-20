# Plan 328 — work backwards from chaos

**Origin:** Josj, 2026-08-20. First the diagnosis, after reading forty
generated programs: *"Each and every file has the same three flags set.
Each and every time... We need to stop asking how else can we follow the
language rules. We need to start asking, how can we generate properly
random Vox?"*

Then the method, which is the important half: *"We create completely
nonsense vox programs that don't compile. We keep on adding the needed
rules to the gen script so that less and less uncompilable programs come
out. We should work backwards from chaos, not slowly trying to add
little bits of controlled chaos here and there."*

---

## The measurement that prompted it

Across 40 generated programs:

| | |
|---|---|
| flags per program | **4, in every single one** |
| flag names, aliases, types | identical in every program |
| `Parse flags.` present | **40 of 40** — the auto-insert path has never run |
| `and is required` | **0 of 40** — never generated |
| flag block contiguous | **40 of 40** |

The entire flag surface varies by **one bit**: whether one flag carries
a default.

## Why the current approach has a ceiling

The generator is ~45 hand-written leaf templates. Each emits a FIXED
statement shape with randomised fillings — a random buffer size, a
random literal, a random name suffix. A program is a fixed skeleton plus
N leaves drawn from a menu.

It can only ever produce shapes someone already thought to write down.
Every improvement is another template. Randomising the fillings is not
randomising the program, and the count of distinct STRUCTURES stays
roughly constant however many templates accumulate.

Worse, it is additive-from-safety: each step starts from what is known
to compile and adds a little variation that is also known to compile. It
can never reach a shape nobody imagined, because nobody imagined it.

## The inversion

**Start from nonsense. Add rules until it compiles.**

Generate arbitrary Vox-ish token soup, which compiles essentially never.
Then add, one at a time, the rules the language actually requires —
statements terminate, names are declared before use, a flag read follows
the parse point — and watch the compile rate climb.

Three properties this has that the additive approach cannot:

**The rule set becomes the artifact.** At the end, the generator
contains an executable description of what Vox requires, discovered
empirically. That is worth more than a pile of templates, and it is
checkable against LANGUAGE.md — a rule the generator needs that the
manual does not state is a documentation gap; a rule the manual states
that the generator does not need is a claim worth testing.

**The failures are the work queue.** Every rejected program is either a
rule not yet encoded or a compiler bug, and the compiler TELLS you which
via its diagnostic. Group rejections by error message and the largest
bucket is the next rule to add. This turns "generate better programs"
from a matter of taste into a measurable loop with an obvious next step.

**It covers what nobody thought of.** The space starts as everything and
is narrowed. Shapes no human would write are in it by default rather
than by inspiration.

## Chaos is not a mode

This supersedes plan 326's design, where chaos was a knob that added
mutations on top of valid output. That had the arrow pointing the wrong
way. Chaos is the STARTING POINT and rules are what reduce it; "chaos
level" is really "how many rules are switched off".

That also means the two oracles coexist naturally rather than needing a
mode switch:

| Program compiles? | What counts as a finding |
|---|---|
| no, with a clean diagnostic | **nothing** — this is the happy path, and the diagnostic names the next rule |
| no, with an ICE, panic, or crash | **a finding** — a compiler must diagnose bad input, never die on it |
| no, but the program was LEGAL | **a finding** — the rule set says it should compile, so either the rule is wrong or the compiler is |
| yes | the existing oracles apply: signal death, hang, wrong argv assertion, output disagreeing with itself |

The third row is the interesting one and only exists in this design: it
turns the generator's own rule set into a claim about the language that
the compiler can contradict.

## What does not change

The harness, the confinement, the per-run isolation, the differential
oracle, the argv assertions, the finding pipeline — all of yesterday's
and today's work is untouched. This replaces the generator's middle: the
part that decides what a program contains. It is not a rewrite of the
tool.

## Ordering

1. **A rejection classifier first.** Before generating any nonsense,
   the harness must group compile failures by diagnostic and report the
   histogram. Without it this plan is a slog; with it, it is a queue.
   This is small and it is the thing that makes the rest tractable.
2. **A minimal soup generator** behind a flag, so the existing generator
   keeps working and keeps finding what it finds. Measure the compile
   rate. It will be near zero, which is correct.
3. **Add rules, largest bucket first**, measuring the rate after each.
   Each rule is a commit with a before/after number.
4. **Cross-check the accumulated rules against LANGUAGE.md** and report
   both kinds of disagreement.
5. Retire template leaves as the soup generator subsumes them — not
   before, and one at a time, with the corpus measurements to show
   nothing was lost.

## Acceptance

- The rejection histogram exists and names the top diagnostics.
- Compile rate is tracked per commit as rules accumulate, and the
  numbers appear in commit messages.
- Programs with 0 flags and 8 flags both occur; names, aliases, types,
  optional clauses, placement and parse point all vary.
- An ICE or compiler crash on nonsense input is reported as a finding,
  distinctly from a clean rejection.
- The existing valid-mode campaign still compiles every program and
  finds nothing — the old generator keeps working until it is
  deliberately retired.
