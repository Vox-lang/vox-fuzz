# Claim ledger: Directories, Mounting, and Process Control

Source: `../vox/LANGUAGE.md` lines **3873–4214**, manual version **Vox
0.4.10** (5545 lines, vox `527cb89`), re-pinned 2026-08-23 (previously
pinned to a 5611-line 0.4.10 manual) — Directories, Mounting Filesystems,
Device Nodes, Symbolic Links, Switching the Root Filesystem, Executing
Programs, Process Control: fork and reap, `without waiting`, the reaped
status, decoding the status, the supervisor loop, `Send signal`, System
Control.

Compiler used for the original pass: `vox v0.4.8`; re-verified against
`vox v0.4.9` on 2026-08-22
(`/home/josj/scr/english/vox/target/release/vox`), `VOX_CORE_PATH` pinned
to the sibling `coreasm`.

The 0.4.8→0.4.9 drift in this range is a uniform **+89 lines**,
confirmed against the manual text at five widely-spaced anchors (PRC-01,
20, 40, 60, 80) before applying it mechanically to every row.

**Historical note.** This section used to flag that the brief's original
line range (3658–3999, correct for 0.4.7) was stale by the time of the
0.4.8 mapping pass, and that `INDEX.md` needed re-pinning across every
ledger. `INDEX.md` re-pinning is addressed at the end of this whole
follow-up pass, not per-ledger.

Two smaller mismatches for the master, left as found rather than
"corrected" unilaterally: `INDEX.md` names this ledger `process-control.md`
while the brief specifies `map-process.md` (this file), and `INDEX.md`
still has no row filled in for **PRC** — mapped/rows/exercised/verified are
all blank. Both are the master's to reconcile, per PROCEDURE.md §7.

This is a **gap analysis**, not a from-scratch map. The `existing leaf`
column names the leaf that already emits the construct, or `none`.

## Existing coverage: there is none, and that is deliberate

Every row below reads `existing leaf: none`. This is not a skim of leaf
names — `grep -n -i -E "Create a directory|Remove the directory|Delete the
directory|Change directory|Mount|Unmount|device node|symbolic link|Pivot
root|Execute|fork|reap|Send signal|Shutdown|Reboot|Halt|Poweroff|Restart"
src/gen_*.vox` returns exactly two hits, both inside comments
(`src/gen_files.vox:46` mentions defect 7, `src/gen_core.vox:744` uses the
English word "executed"). **No leaf emits any construct from this section
into a generated program.** `src/harness.vox` and `src/sandbox.vox` use
`fork`, `reap`, `Execute` and `Send signal` heavily, but that is the
fuzzer's own machinery, not generated output.

Nothing in this ledger is therefore `exercised`, let alone `verified`.
Coverage of this section is **0 of 87 rows**.

## Before any leaf is built: this section is under a standing ban

`tests/200_never_emitted.vox` sweeps 2,000 generated programs at four
budgets and **fails the build** if any of them contains, case-insensitively,
`shutdown`, `poweroff`, `reboot`, `restart`, `halt`, `mount` (which also
catches `unmount`/`umount`), `pivot root`, `pivot_root`, or `device node`.
It implements plan 323's **Tier NEVER**, approved by TheJostler on
2026-08-19: *"turns off the host mid-run"*, *"corrupts or detaches real
filesystems"*, *"unrecoverable on a live machine"*, *"writes into /dev"*.

The brief for this mapping states the opposite policy — that these are safe
to emit because an unprivileged process gets EPERM. Both positions are
recorded here; **the mapper does not get to pick.** See *"A policy conflict
this map cannot resolve"* below. Rows PRC-12 … PRC-26, PRC-29 … PRC-32 and
PRC-78 … PRC-86 are under the ban and say `BANNED` in `leaf needed` for as
long as the guard test stands — all but PRC-83, which needs no leaf either
way. PRC-27/28 (symbolic links) sit inside that numeric span but are not
banned: `symlink(2)` needs no privilege and confines to the scratch
directory like any file-I/O leaf.

Plan 323's **Tier CONFINE** covers the rest of the section — directory
create/remove, `Execute`, `fork`/`reap`, `Send signal` — as legitimate once
confined. `src/sandbox.vox` already gives every generated program a
pid-and-seed-keyed scratch directory, which is the confinement the
directory and symlink rows need.

## Probes

Every hand-verified row's probe is retained, runnable, in
`docs/ledger/probes/process-control/`, one file per row named `PRC-NN.vox`
(a probe covering more than one row is named for the first and says so in
its own header). The six discrepancies have repros `D1.vox` … `D6.vox` in
the same directory. **49 probe files; `docs/check-probes.sh` reports 49
passed, 0 failed, 0 skipped.**

Probes are compiled and run **from the repo root** — the file-touching ones
create `vf_scratch/process-control/` themselves, work only inside it, and
delete everything they create, so the directory re-runs clean and leaves no
residue but the empty scratch directory (verified with `git status` after a
full pass, and by two consecutive sweeps: once from a wiped `vf_scratch/`,
once with it populated). `vf_scratch/` is gitignored (`vf_*`).

**Repaired 2026-08-21.** Sixteen probes wrote their scratch files to
`docs/ledger/probes/map-process/` — the directory's name before this ledger
was renamed to `process-control`. That parent no longer exists, so every
`mkdir` under it failed with ENOENT and the probes reported the failure
rather than the behaviour they were written to pin. Seven failed outright
(`D1`, `PRC-01`, `PRC-02`, `PRC-03`, `PRC-09`, `PRC-10`, `PRC-27`) and
several more **passed for the wrong reason**, because a probe whose recorded
outcome is "the operation failed" passes just as well when it failed for the
wrong errno: `PRC-05`, `PRC-06`, `PRC-11`, `PRC-12`, `PRC-14`, `PRC-15`,
`PRC-17`, `PRC-22`, `PRC-29` and `D2` were all in that class, testing ENOENT
where they meant to test EPERM or a real rmdir. Every one now works inside
`vf_scratch/process-control/`, which is where PROCEDURE.md §6's sandbox rule
says they belonged in the first place. `PRC-10` also had its `Change
directory to "../../../../.."` corrected to `"../../.."` for the new depth,
and `PRC-01`'s recorded exit code was re-spelled `(exit status 1)` so
`check-probes.sh` reads it as an annotation rather than as an output line.
No recorded output changed: the probes were right, the paths were not. Not
one of these was a compiler change. `fixtures/` holds `libprocess.lib` +
`libprocess.so`, copied from the local build of Vox-lang/vox-libs, and
`statusprobe.vox` + the `libstatusprobe.{lib,so}` built from it; two `.so`
binaries are committed so PRC-59 and PRC-64/65/66 stay runnable rather than
merely described. If the master would rather build them at check time than
carry binaries, that is a fair call and the sources are both present.

**Everything was run as uid 1000 with `CapEff 0000000000000000`.** That is
what makes the mount, pivot_root, mknod and reboot probes inert: every one
of them returns EPERM before the kernel acts. `PRC-78.vox` issues five real
`reboot(2)` calls; its header says so in capitals and names the two
commands to check privilege with before running it.

## The rows

| id | line | claim | leaf needed | assertable? | existing leaf | status | verified by |
|---|---|---|---|---|---|---|---|
| PRC-01 | 4076–4078 | The section's constructs exist for early-userspace/init programs, and `examples/initramfs.vox` is a complete, working init sequence "exercising all of them together". | compile the example verbatim; running it unprivileged stops at the first `Mount` | partly — the composite compiles and its first two statements behave predictably (exit 1 via its own handler); "working" as an init cannot be checked outside an initramfs | none | todo — and see **Discrepancy 6**: the example uses no fork, reap, `the reaped status`, `Send signal` or system control | |
| PRC-02 | 4083, 4090 | `Create a directory called '<path>'.` performs `mkdir(2)`. | create a directory under the program's scratch dir, then `If "<path>" is not available then, Exit 95.` | yes — the generator picks the path, so it knows the answer | none | todo | |
| PRC-03 | 4090 | The directory is created with mode `0755`. | — | **no** from inside Vox — the language has no stat/mode accessor. Hand-checked outside with `stat -c '%a'`: 755 under `umask 0`, 700 under `umask 077`, i.e. 0755 is the mode argument and umask still applies, exactly as `mkdir(2)` specifies | n/a | not assertable | |
| PRC-04 | 4090–4091 | The article `a` is optional: `Create directory called '<path>'.` also parses. | emit both spellings, varying which | yes — same assertion as PRC-02 | none | todo | |
| PRC-05 | 4091 | `called` is required; omitting it is an error. | — | **no** at run time — it is a **compile** error (`Expected 'called' after directory`), so a generated program cannot carry it. Belongs to a negative-corpus harness, not a leaf | n/a | not assertable (compile-time) | |
| PRC-06 | 4084, 4092–4093 | `Remove the directory called '<path>'.` performs `rmdir(2)`. | create then remove, `If "<path>" is available then, Exit 95.` | yes | none | todo | |
| PRC-07 | 4085, 4092–4093 | `Delete` works as well as `Remove`. | emit both verbs, varying which | yes — same assertion | none | todo | |
| PRC-08 | 4093 | `the` and `called` are both optional in the remove/delete form. | emit all four combinations across programs | yes — same assertion; four spellings is the anti-invariant requirement | none | todo | |
| PRC-09 | 4092 | The removal is `rmdir(2)` — not recursive: a directory with a child cannot be removed. | remove a directory that still holds a child, assert the error flag fired and the child survives | yes — the generator created the child | none | todo — undocumented only in the sense that "rmdir(2)" is a citation rather than a sentence | |
| PRC-10 | 4086, 4094 | `Change directory to "<path>".` performs `chdir(2)`; later relative paths resolve from the new cwd. | chdir into the scratch dir, create a child by a bare relative name, chdir back, assert the child is at the composed path | yes | none | todo — **and this is the one directory construct a leaf must think hardest about**: it moves the cwd out from under every other leaf in the same program, including the file-I/O leaves' scratch paths | |
| PRC-11 | 4095 | All three directory statements set the error flag on failure and `On error` catches it. | force each failure (unwritable parent, absent path), assert each handler fired | yes — the generator chooses a path it knows is absent | none | todo | |
| PRC-12 | 4100, 4110–4111 | `Mount "<source>" at "<target>" with type "<fstype>".` lowers to `mount(2)`. | **BANNED** — `tests/200_never_emitted.vox` fails on the substring `mount`. If the ban is lifted: mount under the scratch dir and assert the error flag fired (unprivileged) | yes, but only on the ERROR path: `On error` fires, so a leaf could assert the handler ran. The success path needs CAP_SYS_ADMIN and is unreachable for the fuzzer | none | todo (banned) | |
| PRC-13 | 4101, 4110 | The `with options "<options>"` clause is optional. | **BANNED** (as PRC-12); emit both arities | yes — error-path only, as PRC-12 | none | todo (banned) | |
| PRC-14 | 4111–4113 | source, target, fstype and options each accept a string literal, a text variable, or a buffer, including a format-string-built buffer. | **BANNED** (as PRC-12); emit all four operands in each of the three forms | yes — error-path only. The format-built buffer is separately assertable by printing/comparing it, which is a buffer claim, not a mount one | none | todo (banned) | |
| PRC-15 | 4114–4119 | fstype `"none"` with options `"move"` is recognised and translated to `MS_MOVE`. | **BANNED** (as PRC-12) | **no** for the fuzzer — the translation is only observable if the mount succeeds, which needs CAP_SYS_ADMIN. Unprivileged it is indistinguishable from a plain failing mount | none | todo (banned, and not assertable unprivileged) | |
| PRC-16 | 4114–4116 | fstype `"none"` with options `"bind"` → `MS_BIND`. | **BANNED** (as PRC-12) | **no**, same as PRC-15 | none | todo (banned, and not assertable unprivileged) | |
| PRC-17 | 4104, 4120 | `Unmount "<target>".` performs `umount2(2)`. | **BANNED** — `unmount` contains `mount` | yes — error-path only | none | todo (banned) | |
| PRC-18 | 4120 | `umount` is an accepted alias for `Unmount`. | **BANNED** (as PRC-17); emit both spellings | yes — error-path only | none | todo (banned) | |
| PRC-19 | 4105, 4121 | Appending `lazily` requests `MNT_DETACH`. | **BANNED** (as PRC-17); emit with and without the suffix | yes that the suffix parses and reaches the syscall; **no** that it is MNT_DETACH — see PRC-20 | none | todo (banned) | |
| PRC-20 | 4121–4124 | `MNT_DETACH` detaches immediately and releases the mount once nothing uses it, instead of failing with "device busy" — needed to unmount the filesystem your own program was loaded from. | **BANNED** (as PRC-17) | **no** — needs a real mount to detach, therefore root | none | todo (banned, and not assertable unprivileged) | |
| PRC-21 | 4102, 4106, 4125 | Both Mount and Unmount set the error flag on failure. | **BANNED** (as PRC-12) | yes — this is the only mount/unmount behaviour an unprivileged fuzzer can assert, and it is worth a row | none | todo (banned) | |
| PRC-22 | 4130, 4134 | `Create a device node called "<path>" with type "c" major N minor M.` performs `mknod(2)`. | **BANNED** — the guard's needle is `device node` | yes — error-path only for `"c"`/`"b"` (needs CAP_MKNOD). **`"p"` is different: it succeeds unprivileged** and would create a real FIFO — see PRC-24 and D1 | none | todo (banned) | |
| PRC-23 | 4131, 4134 | `type "b"` is accepted (block device). | **BANNED** (as PRC-22) | yes — error-path only | none | todo (banned) | |
| PRC-24 | 4134 | The type is `"c"` (character) or `"b"` (block). | **BANNED** (as PRC-22) | yes, and the claim as written is **incomplete** — the compiler also accepts `"p"` (FIFO) and names it in its own diagnostic. See **Discrepancy 1** | none | todo (banned) | |
| PRC-25 | 4135–4136 | `major`/`minor` are the standard Linux device-driver identification numbers. | **BANNED** (as PRC-22) | **no** unprivileged — the numbers are only observable on a node that was actually created, i.e. with CAP_MKNOD | none | todo (banned, and not assertable unprivileged) | |
| PRC-26 | 4137 | The device-node statement sets the error flag on failure. | **BANNED** (as PRC-22) | yes for a *runtime* failure. Note that an invalid **type** is not a runtime failure at all but a compile error — see **Discrepancy 2** | none | todo (banned) | |
| PRC-27 | 4142, 4145 | `Create symbolic link from '<target>' to "<linkpath>".` performs `symlink(2)`: the second path is created and points at the first. | create a link inside the scratch dir to a file the program just wrote, read the file back through the link and assert the bytes; also link to an absent target and assert the link does not resolve | yes — the generator wrote the target and knows its contents | none | todo — **not banned**; `symlink(2)` needs no privilege and is confinable to the scratch dir exactly like the file-I/O leaves | |
| PRC-28 | 4145–4146 | The symbolic-link statement sets the error flag on failure. | create the same link twice, assert the second sets the flag (EEXIST) | yes | none | todo | |
| PRC-29 | 4151, 4154 | `Pivot root to "<new_root>" with old root "<put_old>".` performs `pivot_root(2)`. | **BANNED** — the guard's needles are `pivot root` and `pivot_root` | yes — error-path only (needs CAP_SYS_ADMIN) | none | todo (banned) | |
| PRC-30 | 4154–4156 | `put_old` must be a directory that already exists *inside* `new_root`, created after mounting the new root, not before. | **BANNED** (as PRC-29) | **no** — a precondition of the success path, which needs root | none | todo (banned, and not assertable unprivileged) | |
| PRC-31 | 4156–4159 | After a successful pivot the previous root is reachable at `put_old` relative to the new root and should be released with `Unmount "..." lazily` once the program has `chdir`'d away. | **BANNED** (as PRC-29) | **no** — success path, needs root | none | todo (banned, and not assertable unprivileged) | |
| PRC-32 | 4159 | Pivot root sets the error flag on failure. | **BANNED** (as PRC-29) | yes — error-path only | none | todo (banned) | |
| PRC-33 | 4164, 4173 | `Execute "<path>".` performs `execve(2)` and replaces the current process image entirely. | Tier CONFINE: fork first, `Execute` an **allowlisted** binary with a fixed argument list, reap, assert the child's exit code. Never a generated command line | yes — the generator chooses the binary and the exit code it will produce, so `If 'exit code of' of status is not 3 then, Exit 95.` | none | todo | |
| PRC-34 | 4175–4176 | The no-argument form synthesizes `argv = [path, NULL]` (argc 1). | exec a helper that reports its own argc, assert 1 | yes, but it needs a **helper binary** the fuzzer controls; with `/bin/echo` the observation is "one empty line", which is weaker | none | todo — a leaf needs an argv-reporting target; `/bin/echo` is the weak substitute | |
| PRC-35 | 4165, 4177–4178 | The literal-argument-list form builds argv at compile time. | `Execute "/bin/sh" with arguments ["-c", "<fixed script>"]` and assert the script's effect | yes | none | todo | |
| PRC-36 | 4167–4168, 4179–4182 | The list-variable form builds argv at runtime from the list's current length and contents. | build the list with `append`s so the length is only known at run time, then exec and assert | yes — the generator knows what it appended | none | todo | |
| PRC-37 | 4180–4182 | argv is sized and bounds-checked from that single length read, so it cannot be overrun regardless of the list's contents. | grow the list to a varying length (including 0), exec, assert no crash and the expected argc | yes for "no crash" and for argc; the *single length read* is an implementation detail underneath | none | todo — the empty-list case is confirmed to give argc 1 | |
| PRC-38 | 4184 | The environment is inherited from the calling process in all three forms. | set a known variable before exec'ing a helper that prints it back, assert the value | yes — but again needs a helper the fuzzer controls, or a shell one-liner over a variable known to exist | none | todo | |
| PRC-39 | 4185–4187 | `execve` only ever returns on failure, so `On error` after `Execute` is the normal and only way to detect that it did not work. | exec a path the generator knows is absent, assert the handler fired and the program continued | yes | none | todo | |
| PRC-40 | 4175–4182 (undocumented precision) | argv[0] is always the path; the argument list's elements land at argv[1..]. The manual states this only for the no-argument form and leaves the other two to inference. | assert `$0`/argc from an exec'd helper | yes | none | todo — hand-verified in all three forms | |
| PRC-41 | 4179–4182 (undocumented precision) | An argument list containing anything that is not text makes the exec fail and set the error flag — in both the literal and the list-variable form. Nothing crashes. | emit a mixed-type argument list, assert the error flag fired and the program survived | yes — the generator chose the element types | none | todo — see **Discrepancy 3** | |
| PRC-42 | 4201–4202 | `fork`/`reap` are **expressions**, not statements: they work anywhere an expression is valid, not only after `Set`. | emit a reap inside an `If` condition and a fork as a call argument, as well as the ordinary `Set` form | yes — the surrounding assertion is the same as PRC-43/46; what varies is the syntactic position | none | todo — a leaf that only ever emits the `Set` form is asserting an undeclared rule | |
| PRC-43 | 4192, 4204–4205 | `fork the process` performs `fork(2)`; the trailing `the process` is optional and bare `fork` works. | emit both spellings, varying which | yes — `If reaped is not pid then, Exit 95.` | none | todo | |
| PRC-44 | 4205–4206 | fork returns `0` in the child and the child's PID in the parent. | branch on the return, have the child `Exit` a known code, assert the parent reaps that pid and code | yes | none | todo | |
| PRC-45 | 4206 | fork returns a negative value on error and sets the error flag. | — | **no** in practice — reaching it means exhausting `RLIMIT_NPROC`, which a fuzzer must not do to its own host. A leaf that tried would be a fork bomb | none | not assertable (would require resource exhaustion) | |
| PRC-46 | 4198, 4207–4208 | `reap any child process` is `wait4(2)` with pid −1 and returns the reaped child's PID. | fork one child, reap any, assert the returned pid equals the forked pid | yes | none | todo | |
| PRC-47 | 4208 | reap returns a negative value on error. | reap a pid the program did not fork, assert the value is negative | yes — hand-verified as −10 (−ECHILD), though only "negative" is documented | none | todo | |
| PRC-48 | 4209–4210 | `reap process <pid>` and `reap child <pid>` both `wait4(2)` a specific PID. | emit both spellings against a known child, assert the returned pid | yes | none | todo | |
| PRC-49 | 4212–4213 | Both set the error flag on failure; `On error` after `reap process 999999` catches ECHILD. | reap a reserved-invalid pid, assert the handler fired | yes — and this is the safe shape: reaping can only ever touch the program's own children, so an invalid pid reaches nothing | none | todo | |
| PRC-50 | 4217–4224 | Any reap form takes a `without waiting` suffix, calling `wait4(2)` with `WNOHANG` instead of blocking. | emit the suffix on all three reap forms, varying which | yes, via the three outcome rows below | none | todo | |
| PRC-51 | 4229 | Non-blocking reap, a child that finished → its PID, error flag cleared. | fork a child that exits at once, poll until it is reaped, assert the pid and that no handler fired | yes | none | todo | |
| PRC-52 | 4230–4231 | Children exist but none has finished → `0`, error flag cleared. This is **not** an error — it is how "still running" is told from "gone". | fork a child that waits, poll immediately, assert exactly `0` and that no handler fired | yes — the generator controls the child's delay | none | todo — the "not an error" half is the one a naive leaf will get wrong | |
| PRC-53 | 4232–4233 | Genuine error, e.g. no such child (ECHILD) → negative, error flag set, catchable with `On error`. | poll with no children outstanding, assert negative and that the handler fired | yes | none | todo | |
| PRC-54 | 4235–4237 | A non-blocking reap that returns `0` reaps nothing, so it does **not** disturb `the reaped status`; only a reap that returns a child's PID changes it. | read `the reaped status` before and after a zero-returning poll, assert unchanged | yes — before any reap the value is the −1 sentinel, so the assertion is exact | none | todo | |
| PRC-55 | 4237–4240 | `without` is already reserved (the `print ... without newline` token), so the suffix cannot be confused with a call argument; `waiting` remains an ordinary identifier everywhere it is not this suffix. | declare a variable called `waiting` in the same program that uses the suffix | yes — `If waiting is not 11 then, Exit 95.` | none | todo — a good anti-invariant leaf: the fuzzer should be *trying* to collide with keywords | |
| PRC-56 | 4246, 4249–4250 | `the reaped status` is an expression yielding the raw `wait4` status word as a plain number, exactly the kernel's `int status`, undecoded. | reap a child that exited with a known code, assert the raw word equals code × 256 | yes — exit 7 gives 1792, hand-verified | none | todo | |
| PRC-57 | 4251 | It reflects the most recent **successful** reap in the current process. | do a failing reap between two successful ones, assert the value did not move on the failing one | yes | none | todo | |
| PRC-58 | 4252–4253 | Before any successful reap it is `-1`, a sentinel no real status can take, so "never reaped" is distinguishable from "exited 0". | read it as the program's first statement, `If the reaped status is not -1 then, Exit 95.` | yes — the strongest single assertion in this section, and free | none | todo | |
| PRC-59 | 4253–4257 | The sentinel lives in loader-initialized `.data`, not `.bss`, because `_start` is only emitted for executables — a `--shared` library would otherwise read `0` and report "exited cleanly" with no child ever reaped. | a `--shared` library that returns `the reaped status`, consumed by a program that asserts −1 | yes, but it needs a **two-artifact build** (a `.lib`/`.so` plus a consumer), which is the `.lib` surface, not this one. Hand-verified: a library reads −1 | none | todo — worth folding into whatever leaf work covers `see`/shared libraries | |
| PRC-60 | 4259–4261 | `reaped` stays an ordinary identifier: `the reaped status` is consumed only as that exact phrase, and `the reaped` followed by anything else is an ordinary variable reference. | declare `reaped` and `'the reaped'` as ordinary variables in a program that also reads `the reaped status` | yes | none | todo — same anti-invariant value as PRC-55 | |
| PRC-61 | 4261–4262 | `tests/102_fork_reap.vox` does `Set reaped to reap any child process.` and keeps passing. | reproduce that test's body | yes — it asserts by printing a fixed line; a leaf would `Exit 95` instead | none | todo | |
| PRC-62 | 4266–4269 | The compiler knows nothing about the wait-status encoding; a program decodes it with `divide`, `modulo` and `bit-and`, with nothing installed. | decode a known child's status in-line, assert the code and signal | yes | none | todo | |
| PRC-63 | 4272–4277 | The two decoder functions the manual gives (`'exit code of'`, `'signal of'`) compile and return the exit code and terminating signal. | emit both functions verbatim and call them on a status the generator produced | yes | none | todo | |
| PRC-64 | 4279–4286 | The `process` library at Vox-lang/vox-libs is installable as an ordinary shared library and consumed with `see process version "0.1" from "./libprocess.lib".` | — | **no** for the fuzzer — it depends on an artifact from another repository being present at a path the generated program names. A leaf must not depend on that; the in-line decoders of PRC-63 are the fuzzable form | none | not assertable (external artifact) | |
| PRC-65 | 4288–4292 | The library provides `'exit code of'` (bits 8–15), `'signal of'` (low 7 bits), `crashed` (a signal killed it), `'exited normally'` (no signal involved). | — | **no**, same as PRC-64. Hand-verified against the local build: all four behave as documented | n/a | not assertable (external artifact) | |
| PRC-66 | 4294–4299 | The call-site forms `crashed of status` / `'signal of' of status` read as English and work. | — | **no**, same as PRC-64 | n/a | not assertable (external artifact) | |
| PRC-67 | 4303–4343 | The supervisor snippet composes fork, non-blocking reap, a timer deadline, `Send signal` and status decoding into a complete supervisor, and runs. | the composite shape: poll a child, time it out, kill it, report how it died | yes as a shape — but the snippet as printed needs the external library (PRC-64), so a leaf builds the same loop over the in-line decoders | none | todo (composite; the sub-claims are PRC-43/50/52/56/69/71) | |
| PRC-68 | 4306–4308 | `examples/supervisor.vox` "is this loop as a runnable program", supervising both a job that finishes and a job that hangs. | reproduce the example | yes — the example is self-contained and deterministic (six lines of output) | none | todo — and see **Discrepancy 4**: it is *not* the snippet above it | |
| PRC-69 | 4345–4347 | `the clock's elapsed in milliseconds` reports true milliseconds, so a 5000-millisecond deadline fires accurately at the five-second mark. | start a timer, `Wait` a known interval, assert elapsed lands in a band around it | yes with a band — an exact equality would be a flake factory; a wrong *unit* is off by ×1000 and a band catches that | none (the timer leaf `gen leaf timer and clock` exists in `src/gen_misc.vox:203` but is a Time-and-Timers row, not this one) | todo — belongs to the TIM ledger; recorded here because this section makes the claim | |
| PRC-70 | 4351 | Unlike fork/reap, `Send signal` is a **statement**, not an expression. | — | **no** at run time — reading it for a value is a compile error (`Expected a statement, got IntegerLiteral(0)`). Negative-corpus material | n/a | not assertable (compile-time) | |
| PRC-71 | 4354, 4357–4358 | `Send signal <N-expr> to process <pid-expr>.` performs `kill(2)` (syscall 62), pid in `rdi`, signal in `rsi`. | Tier CONFINE: signal **only** a pid this program forked, or a reserved-invalid pid. Fork a child, signal it, reap it, assert the terminating signal | yes — `If the reaped status bit-and 127 is not 9 then, Exit 95.` | none | todo — see PRC-77 for the pid values a leaf must never generate | |
| PRC-72 | 4358–4362 | `child` is accepted as an alias for `process`, mirroring `reap process`/`reap child`. | emit both spellings, varying which | yes — same assertion as PRC-71 | none | todo | |
| PRC-73 | 4365 | On success `Send signal` clears the error flag. | set the flag with a failing reap, then send a successful signal, assert no handler fires afterwards | yes — hand-verified: the flag really is cleared, not merely left alone | none | todo | |
| PRC-74 | 4365–4367 | On failure (ESRCH, EINVAL, EPERM) it sets the flag, so `On error` catches it. | ESRCH via a reserved-invalid pid; EINVAL via an out-of-range signal number on the program's own child | yes for ESRCH and EINVAL. **EPERM must not be generated** — it means signalling another user's process | none | todo (ESRCH and EINVAL only) | |
| PRC-75 | 4370–4375 | Signal 0 delivers nothing but errors if no process has that PID — the standard existence check, and a safe way to probe the error path. | signal 0 to a reserved-invalid pid, assert the handler fired; signal 0 to the program's own live child, assert it did not | yes — and this is the safest construct in the whole section | none | todo | |
| PRC-76 | 4378–4387 | The worked pattern — fork, `Send signal 9`, `reap any child process`, `If reaped is pid` — works. | reproduce it | yes | none | todo (composite of PRC-43/46/71) | |
| PRC-77 | 4357–4358 (undocumented precision) | The pid expression reaches `kill(2)` unfiltered, so pid `0` (the caller's whole process group) and pid `-1` (every process the uid may signal) are reachable from an ordinary Vox program, with no diagnostic. | **a leaf must never emit a pid it did not fork.** Concretely: never a literal, never an arithmetic result, never `0`, never a negative — only a variable holding a pid this program's own `fork` returned, or a reserved-invalid constant | yes that both are accepted (with signal 0, which delivers nothing); asserting anything beyond that would mean actually broadcasting | none | todo — see **Discrepancy 5**. This is the single most dangerous row in the section | |
| PRC-78 | 4392, 4399, 4404 | `Shutdown.` performs `reboot(2)` with `LINUX_REBOOT_CMD_POWER_OFF` and requires `CAP_SYS_BOOT`. | **BANNED** — the guard's needle is `shutdown` | yes — error-path only, and only for an unprivileged process | none | todo (banned) | |
| PRC-79 | 4395, 4405 | `Reboot.` → `LINUX_REBOOT_CMD_RESTART`. | **BANNED** (needle `reboot`) | yes — error-path only | none | todo (banned) | |
| PRC-80 | 4396, 4406 | `Halt.` → `LINUX_REBOOT_CMD_HALT`. | **BANNED** (needle `halt`) | yes — error-path only | none | todo (banned) | |
| PRC-81 | 4404 | `Poweroff` is an alias for `Shutdown`. | **BANNED** (needle `poweroff`) | yes — error-path only | none | todo (banned) | |
| PRC-82 | 4405 | `Restart` is an alias for `Reboot`. | **BANNED** (needle `restart`) | yes — error-path only | none | todo (banned) | |
| PRC-83 | 4406 | `Halt` has no alias. | — | **no** — a claim about what the language does *not* accept; the only test is that some other spelling fails to compile, which is negative-corpus material, not a leaf | n/a | not assertable (compile-time, negative) | |
| PRC-84 | 4399–4400 | Each of the three calls `sync(2)` first, to flush filesystem buffers. | **BANNED** | **no** — `sync(2)` is not observable from inside Vox, and on the only path a fuzzer can reach (EPERM) the machine never goes down to reveal whether it flushed | n/a | not assertable | |
| PRC-85 | 4408 | On success, none of these return — the machine powers off, restarts or halts. | **BANNED** | **no** — verifying it means taking the machine down | n/a | not assertable | |
| PRC-86 | 4409–4412 | On failure (not root, no `CAP_SYS_BOOT`) the error flag is set instead of crashing or exiting, `On error` catches it and execution continues — an unprivileged or accidental invocation can never bring down the machine. | **BANNED** — and note the irony: this row is precisely the safety property the brief leans on. It is true (hand-verified, five aliases, all EPERM, execution continued) and the ban still stands, because the guard cannot tell an unprivileged run from a privileged one | yes — assert all five handlers fired and the program reached the line after them | none | todo (banned) | |
| PRC-87 | (undocumented precision) | Every path-taking statement in this section accepts an empty path and fails cleanly through the error flag: create/remove/change directory, symbolic link, mount, unmount, pivot root, execute. Nothing crashes. | emit an empty path to each unbanned statement, assert the handler fired and the program continued | yes | none | todo — not a manual claim; recorded because it is the memory-safety floor for the section and the first degenerate input a leaf will produce | |

## Discrepancies

Recorded, not adjudicated. Each has a runnable repro in
`docs/ledger/probes/process-control/`. None has been filed. **All six
re-verified against vox 0.4.9, 2026-08-22, via the full `docs/check-
probes.sh` sweep of this directory (49 passed, 0 failed) — every probe,
including all six `D*.vox` repros, reproduces its recorded output
byte-for-byte. No manual or compiler change found in this range.**

### 1. The device-node `type` set is larger than the manual's — and the extra one needs no privilege

LANGUAGE.md:4134: *"`type` is `"c"` (character device) or `"b"` (block
device)"*. The compiler accepts a third and names it in its own diagnostic:

```
error: Invalid device type 'x' - expected "c" (character), "b" (block), or "p" (FIFO)
```

`D1.vox` creates one, unprivileged, and it appears on disk:

```
Create a device node called "…/scratch_fifo" with type "p" major 0 minor 0.
If "…/scratch_fifo" is available then, print "type p created a real node with no privilege at all".
```
→ `type p created a real node with no privilege at all`, and outside Vox
`ls -l` shows `prw-r--r--`.

Reading in the compiler's favour: `mknod(2)` really does make FIFOs, and
`"p"` is `mkfifo`'s own letter, so the compiler implements the syscall
faithfully and the manual describes only the two cases the section's
early-userspace framing cares about. On that reading the manual is
incomplete rather than the compiler wrong — but the omission matters *here*
specifically, because plan 323 banned device-node creation on the grounds
that it "writes into /dev", and the reasoning that makes the ban safe to
relax for `"c"`/`"b"` (EPERM without CAP_MKNOD) does **not** hold for `"p"`.

**Re-verified 2026-08-21 against vox 0.4.8: unchanged, still open.** `"p"`
still creates a real FIFO unprivileged (`prw-r--r--`). The probe had been
failing under `docs/check-probes.sh` for an unrelated reason — it wrote to
the ledger's pre-rename directory — and now runs inside
`vf_scratch/process-control/`. Nothing about the finding changed.

### 2. An invalid device type is a compile error, but the manual only documents a runtime error flag

LANGUAGE.md:4137 says the device-node statement *"Sets the error flag on
failure"*, which places every failure at run time where `On error` can see
it. `D2.vox`:

```
Create a device node called "…/scratch_weird" with type "x" major 1 minor 3.
On error print "this handler is never reached".
```

No binary is produced; the handler is unreachable and the program never
runs. Reading in the compiler's favour: rejecting a nonsense literal at
compile time is strictly better than failing at run time, and "sets the
error flag on failure" is about *syscall* failure, of which a malformed
literal is not an instance. The manual simply never says which failures are
which. This matters for a fuzzer because it decides whether a bad type
belongs in a leaf (runtime, catchable) or in a negative corpus (compile).

### 3. A non-text element in an `Execute` argument list fails the exec, and the manual's phrasing suggests otherwise

LANGUAGE.md:4179–4182 describes the list-variable form as sized and
bounds-checked *"from that single length read so the argv array cannot be
overrun **regardless of the list's contents**"*. `D3.vox`:

```
a list called 'the arguments' is [42].
Execute "/bin/echo" with arguments 'the arguments'.
On error print "one number in the list was enough to fail the exec".
```
→ the handler fires. The same happens with `true`, with `3.5`, and in the
compile-time literal form (`with arguments [42, "beta"]`). One text element
alongside them does not save it.

Reading in the compiler's favour: the sentence is about **bounds**, not
types — it promises the argv array cannot be overrun, and that promise is
kept exactly: nothing crashes, the exec merely fails and the program
continues. A list element that is not text has no NUL-terminated string to
point at, so `execve` gets a bad pointer and returns EFAULT, which is the
error flag doing its job. On that reading nothing is wrong; the manual just
never states that argv elements must be text, and "regardless of the list's
contents" is the kind of phrase a reader generalises past its scope.

### 4. `examples/supervisor.vox` is not the supervisor loop the manual prints

LANGUAGE.md:4306–4308: *"[`examples/supervisor.vox`](examples/supervisor.vox)
is this loop as a runnable program, supervising both a job that finishes and
a job that hangs"*. The snippet immediately below opens with

```
see process version "0.1" from "./libprocess.lib".
```

and calls `crashed`, `'signal of'` and `'exited normally'` from that
library. The example file does none of that. Its own comment reads:

> Deliberately no `see`: `the reaped status` is a complete compiler
> feature, and this test must pass with nothing installed at all.

It defines its own decoders, supervises **two** jobs rather than the
snippet's one, and prints six lines where the snippet prints one.
`D4.vox` is the manual's snippet with the `see` line removed — which is
what "the example is this loop" would have to mean, since the example has
no `see` line — and it does not compile:

```
error: Unknown function: crashed
error: Unknown function: signal of
error: Unknown function: exited normally
```

Reading in the manual's favour: "is this loop" plainly means *the same
algorithm*, not the same characters, and the example is a faithful, richer
instance of it. That reading is entirely reasonable — but the two programs
have different dependencies (one needs an external library, one needs
nothing), which is exactly the distinction a reader following the pointer
is trying to settle, and the pointer erases it. Both PRC-67 and PRC-68 are
retained as separate probes for this reason.

### 5. `Send signal` passes the pid to `kill(2)` unfiltered, so the broadcast pids are one typo away

LANGUAGE.md:4357–4358 documents the lowering precisely — *"`<pid-expr>` is
the target PID (loaded into `rdi`), `<N-expr>` is the signal number (loaded
into `rsi`)"* — and says nothing about `kill(2)`'s two special pids.
`D5.vox`, with signal 0, which the kernel never delivers:

```
Send signal 0 to process -1.
On error print "pid -1 was rejected".
print "kill(2) accepted the broadcast pid".
```
→ `kill(2) accepted the broadcast pid`. `Send signal 0 to process 0.`
behaves the same.

Reading in the compiler's favour, and it is a strong one: this **is**
`kill(2)`, the manual says so, and `kill(2)`'s pid semantics — 0 for the
process group, −1 for everything signallable — are the kernel's, not Vox's.
Filtering them would make `Send signal` something other than the syscall it
claims to be, and would take away the only way to signal a process group.
Nothing here is a bug.

It is recorded anyway because of what it means for **this** repository. A
generator that picks a pid from anywhere other than its own `fork` return —
a literal, an arithmetic result, a value that happened to reach 0 — will
eventually send a real signal to every process this user owns, which
includes the fuzzer, the campaign, and the session running it. That is why
PRC-77's `leaf needed` is written as a prohibition rather than a
construction.

### 6. `examples/initramfs.vox` does not exercise "all of them"

LANGUAGE.md:4076–4078 opens the section: *"These constructs were added for
writing early-userspace/init-style programs in Vox - see
examples/initramfs.vox for a complete, working early-userspace init
sequence exercising **all of them** together."*

The example uses directories, mount, device nodes, symlinks, pivot_root and
`Execute`. It uses no `fork`, no `reap`, no `the reaped status`, no
`without waiting`, no `Send signal` and none of the system-control
statements — all of which are in this same section:

```
$ grep -ci -E 'fork|reap|Send signal|Shutdown|Reboot|Halt' examples/initramfs.vox
0
```

`D6.vox` is a program built only from the six constructs the example never
touches, showing they compose fine — the gap is in the sentence, not the
language.

Reading in the manual's favour: "these constructs" may bind only to the
subsections that existed when that sentence was written — the section grew
`fork`/`reap`/`Send signal` and the supervisor material later, and the
intro was not revisited. "all of them" would then mean all the *mounting*
constructs, which is true. The sentence as it now stands is still wrong for
a reader arriving at the section today, and "working" is doing quiet work
too: run outside an initramfs the example gets two statements in before its
own handler exits 1.

## A policy conflict this map cannot resolve

The brief says privileged syscalls are safe to emit because an unprivileged
process gets EPERM and nothing happens, and asks for that safety to be
noted in the ledger. It is noted, and it is **true** — PRC-78's probe issues
five real `reboot(2)` calls and the machine is still here, and PRC-86 is
exactly that guarantee stated by the manual.

But `tests/200_never_emitted.vox` — the guard test plan 323 called *"the
real safeguard: it survives someone later 'improving' the generator"* —
fails the build if a generated program so much as contains the substring
`mount` or `halt`. A leaf written to the brief's policy does not fail a
campaign; it fails `./test.sh`.

Three things a mapper cannot decide, all needing the master and Josj:

1. **Is the ban lifted, narrowed, or kept?** Plan 323's stated reasons are
   about a privileged run ("turns off the host mid-run"). The brief's
   reason is about an unprivileged one. Both are right about their own
   case, and the guard cannot tell them apart — it reads source text, at
   generation time, before anything runs.
2. **If narrowed, `"p"` is a real exception.** Discrepancy 1: every
   device-node form is EPERM-safe *except* `type "p"`, which creates a FIFO
   with no privilege at all. A relaxation reasoned from EPERM must exclude
   it explicitly.
3. **Nothing protects the fuzzer from `Send signal`.** No EPERM saves you:
   pid 0 and pid −1 are same-uid broadcasts (Discrepancy 5) and pid reuse
   makes any unowned pid a live target. This one needs a construction rule
   in the leaf — "the pid variable must be a `fork` return in this
   program" — not a policy decision.

Until that is settled there is no need to wait. The part of this section
that is neither banned nor privileged is **PRC-02 … PRC-11** (directories,
confined to the scratch dir), **PRC-27/28** (symlinks, same confinement),
and **PRC-42 … PRC-63** (fork, reap, `without waiting`, the reaped status,
in-line decoding) — **34 rows**, all Tier CONFINE, all with concrete
assertions already written in the `assertable?` column above, and all of
them needing no privilege and no policy change. `Execute` (PRC-33 … PRC-41)
and `Send signal` (PRC-71 … PRC-77) are unbanned too, but each needs a
construction rule agreed first — an allowlisted target, and a pid that came
from this program's own `fork` — so they belong to a later batch, not the
first.

## Invariants this section justifies

Not one. Every sameness this section could contribute to a corpus is a
defect, because nothing here has a fixed form:

- `Create`/`Remove`/`Delete` — LANGUAGE.md:4092–4093, PRC-07/PRC-08: the
  verb, `the`, and `called` are each independently optional, so **four
  spellings of directory removal must appear** across a corpus, not one.
- `fork the process` vs bare `fork` — LANGUAGE.md:4204, PRC-43: both are
  correct, so both must appear.
- `reap any child process` vs `reap process <pid>` vs `reap child <pid>`,
  each with and without `without waiting` — LANGUAGE.md:4207–4224,
  PRC-46/48/50: six forms, all required to vary.
- `to process` vs `to child` in `Send signal` — LANGUAGE.md:4359, PRC-72.
- `Unmount` vs `umount`, with and without `lazily` — LANGUAGE.md:4120–4121,
  PRC-17/18/19 (moot while banned).
- `Shutdown`/`Poweroff`, `Reboot`/`Restart` — LANGUAGE.md:4404–4405,
  PRC-81/82 (moot while banned).

The only justifiable invariants a leaf from this section may introduce are
**safety constructions, not language rules**, and each needs saying out
loud so the invariant report can cite it rather than flag it:

- every `Execute` target comes from a fixed allowlist — no LANGUAGE.md
  citation; plan 323 Tier CONFINE, PRC-33;
- every `Send signal` pid is a variable holding this program's own `fork`
  return — no LANGUAGE.md citation; PRC-77 / Discrepancy 5;
- every path is under the program's per-run scratch directory — no
  LANGUAGE.md citation; plan 323 Tier CONFINE, `src/sandbox.vox`.

Three deliberate, declared invariants is the right number for this section.
Anything else that stops varying is a bug in the rule layer.

## Report

**87 rows** (PRC-01 … PRC-87), covering LANGUAGE.md 3784–4125.

- **0 exercised, 0 verified.** No leaf emits any construct from this
  section. This is the only ledger so far that starts from literal zero —
  buffers had 6 of 39 exercised.
- **52 rows are fully assertable** — the generator can predict the exact
  result and emit a failing-exit check, named in each row.
- **19 rows are assertable only on the error path**: the mount, unmount,
  device-node and system-control families, whose success paths need
  privileges the fuzzer must never have. `On error` firing is a real
  assertion and worth having; it is all these rows can offer.
- **16 rows are not assertable at all**: 3 compile-time (PRC-05, PRC-70,
  PRC-83), 3 external-artifact (PRC-64/65/66), 3 external-privilege
  success paths within the banned families that the error path cannot even
  reach (PRC-25, PRC-84, PRC-85), 3 more of the same kind (PRC-15/16 flag
  translation, PRC-20 MNT_DETACH semantics), 2 pivot_root preconditions
  (PRC-30, PRC-31), 1 resource-exhaustion (PRC-45, which is a fork bomb),
  and 1 unobservable from inside Vox (PRC-03, the directory mode).
- **27 of the 87 are banned** by `tests/200_never_emitted.vox`; the other
  **60** are not, and **52 of those carry a concrete assertion and status
  `todo`** — a full leaf programme without touching the ban at all.

**The biggest finding is not in the manual — it is the standing ban.**
Half of this section is forbidden from generated programs by
`tests/200_never_emitted.vox`, which enforces plan 323's Tier NEVER and
would fail `./test.sh` the moment a leaf emitted `mount` or `halt`. The
brief instructs the opposite. That conflict has to be settled by Josj
before a single leaf is written for PRC-12 … PRC-32 or PRC-78 … PRC-86;
until it is, the 34 safest unbanned rows named above are a full batch's
work and then some, and 52 unbanned rows are actionable in total.

**Six discrepancies**, all with repros, none filed. The one that matters
most for this repository is Discrepancy 5: `Send signal` hands the pid to
`kill(2)` unfiltered, so `0` and `-1` are same-uid broadcasts reachable
from a generated program, and no EPERM argument protects against it. That
is not a compiler bug — it is `kill(2)` behaving as documented — but it
means a `Send signal` leaf needs a *construction* rule, not just a
confinement rule.

**What I could not do.** The success paths of `mount`, `umount2`,
`pivot_root` and `mknod` for `"c"`/`"b"`, and of `reboot(2)`, all need root
or a user namespace; I had neither and did not create one, so PRC-15/16/20/
25/30/31/84/85 are mapped from the text and marked accordingly rather than
guessed at. PRC-45 (fork returning negative) needs `RLIMIT_NPROC`
exhaustion, which I would not do to this host. `examples/initramfs.vox`
(PRC-01) was compiled and run, but it only gets as far as its first `Mount`
before exiting 1, so the rest of that file is verified as *parsing*, not as
*working*.

**For the next mapper.** Four things this section taught that are not
specific to it:

1. **Re-pin `INDEX.md` before you start.** Every line range in it is from
   manual 0.4.7; 0.4.8 moved this section down 126 lines. A mapper working
   from the stale range maps the wrong text.
2. **Check the guard tests, not just `src/`.** `tests/200_never_emitted.vox`
   silently governs what any leaf for this section may contain, and it is
   not reachable by grepping `gen_*.vox` — which is where the brief points
   you.
3. **A compiler diagnostic is a source of claims.** Discrepancy 1 (`"p"`)
   came out of an error message listing a third option the manual does not
   mention. It is worth deliberately feeding each enumerated literal a bad
   value just to read what the compiler says the valid set is.
4. **Separate "the manual's snippet" from "the file the manual points at".**
   Discrepancy 4 exists because they were assumed identical. Compile both.
