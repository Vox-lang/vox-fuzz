#!/bin/bash
# scripts/fuzz-confined.sh — run vox-fuzz confined inside bubblewrap.
#
# Plan 323 T2. A generated program's path handling is the thing under
# test - not a boundary to trust (compiler bug #19 was exactly this
# class of bug: string literal content resolved wrong at codegen time,
# silently). So confinement here is external and OS-enforced, not a
# convention the generated program is expected to follow.
#
# This confines the whole vox-fuzz PROCESS, not each generated program
# individually. That was the first design and it was rejected after
# measuring it: wrapping each program in its own bwrap invocation
# flattens a real signal death into a plain exit code -
#
#   native:  a segfaulting binary   -> WIFSIGNALED, signal 11
#   in bwrap: the SAME binary       -> WIFEXITED, code 139
#
# - which destroys the exact distinction src/harness.vox's 'supervise'
# exists to preserve (its own header: "reading the true wait status is
# the only way to tell exit 139 from signal 11"). Every crash would be
# silently reclassified as an ordinary nonzero exit - this fuzzer's
# founding bug (finding 01) all over again.
#
# Confining the fuzzer process instead sidesteps this entirely: every
# generated program is forked and exec'd *inside* this sandbox by
# vox-fuzz itself, so it is confined as a side effect of being a
# descendant process, while wait4()/the raw wait status stay completely
# untouched by bwrap - verified: inside bwrap, a forked child's segfault
# is still seen natively as WIFSIGNALED/signal 11.
#
# What's confined:
#   - The entire filesystem is bound READ-ONLY ('--ro-bind / /').
#   - The ONE exception is the scratch root src/sandbox.vox's
#     'scratch dir path' creates every per-program directory under
#     (./vf_scratch, relative to the repo root) - bound READ-WRITE.
#     Every subdirectory vox-fuzz creates under it at runtime (one per
#     generated program, per plan 323 T2) inherits that same
#     read-write bind automatically; nothing here needs to know their
#     names in advance.
#   - No network ('--unshare-net').
#   - /proc and /dev are the ordinary sandboxed kind bwrap provides -
#     harness.vox's 'self pid' and 'kill grandchild of' both read from
#     /proc, so it must exist inside the sandbox.
#
# What this deliberately does NOT confine: findings output
# (--out, default ./findings) is NOT bound read-write here, on the
# theory that findings are real output the run is meant to keep, not
# scratch. If a run needs a non-default --out path, that path needs
# its own --bind added below (or pass --out pointing somewhere already
# under the scratch root). This is a real open question, not an
# oversight - see the T2 report for the tradeoff.
#
# KNOWN GAP, measured, not hypothetical: the CURRENT harness writes its
# own bookkeeping files - ./vf_gen.vox (loop_gen.vox), ./vf_gen_bin
# (loop_gen.vox), ./vf_cerr (runner.vox's 'compile vox') - to the repo
# root, not under the scratch root. Under this script's exact "only
# vf_scratch is writable" confinement, EVERY compile attempt in a real
# `gen` run fails with "Read-only file system" and the run reports
# 0 compiled, 0 findings, for every seed. Confirmed by running this
# script's own bwrap invocation against `gen --count 5`. Fixing this
# means moving those paths under the scratch root, which touches
# runner.vox and loop_gen.vox - out of scope for plan 323 T2 (told not
# to touch runner.vox's behavior), and left for whoever picks up
# T4/T5/T6. Until then, this script confines `vox-fuzz version` and any
# future call that only reads (never writes outside vf_scratch), but
# NOT a real `gen` run - see the T2 report for the tradeoff this raises
# for T4-T6 (loosen the bind now vs. fix the harness paths first).
#
# Usage:
#   scripts/fuzz-confined.sh [gen args passed straight to vox-fuzz]
#
# Example:
#   scripts/fuzz-confined.sh gen --seed 1 --count 2000 --budget 40 \
#       --timeout 10000 --out ./findings

set -euo pipefail

if ! command -v bwrap >/dev/null 2>&1; then
    echo "fuzz-confined.sh: bwrap (bubblewrap) not found on PATH." >&2
    echo "Install it (e.g. 'dnf install bubblewrap' / 'apt install bubblewrap')," >&2
    echo "or run ./build/vox-fuzz directly if you accept running unconfined." >&2
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -x ./build/vox-fuzz ]]; then
    echo "fuzz-confined.sh: ./build/vox-fuzz not found - run 'make build' first." >&2
    exit 2
fi

SCRATCH_ROOT="$REPO_ROOT/vf_scratch"
mkdir -p "$SCRATCH_ROOT"

exec bwrap \
    --ro-bind / / \
    --dev /dev \
    --proc /proc \
    --bind "$SCRATCH_ROOT" "$SCRATCH_ROOT" \
    --unshare-net \
    --die-with-parent \
    --chdir "$REPO_ROOT" \
    ./build/vox-fuzz "$@"
