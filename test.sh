#!/bin/bash
# vox-fuzz test runner — compiles and runs each tests/NNN_*.vox and
# diffs its output against the matching .expected file.

VOX="${VOX:-../vox/target/release/vox}"
VOX_REPO_ROOT="$(cd "$(dirname "$VOX")/../.." && pwd)"
# Pin the runtime to the repo's coreasm. Without this an installed
# /usr/share/vox/coreasm silently shadows it and we would be testing the
# packaged compiler runtime instead of the one under development.
export VOX_CORE_PATH="${VOX_CORE_PATH:-$VOX_REPO_ROOT/coreasm}"
# FAIL if the directory does not exist. vox does not error on a bad
# VOX_CORE_PATH - it falls silently through to /usr/share/vox/coreasm,
# so a wrong derivation here (an absolute $VOX, a snapshot binary) would
# have every test quietly exercise the installed packaged runtime.
if [[ ! -d "$VOX_CORE_PATH" ]]; then
    echo "VOX_CORE_PATH '$VOX_CORE_PATH' is not a directory (set VOX_CORE_PATH explicitly)" >&2
    exit 2
fi
VERBOSE=0
[[ "$1" == "-v" || "$1" == "--verbose" ]] && VERBOSE=1 && shift
TARGET="${1:-tests}"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
PASSED=0; FAILED=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [[ ! -x "$VOX" ]]; then
    echo "vox binary not found at $VOX (set VOX=...)" >&2
    exit 2
fi

if [[ -f "$TARGET" ]]; then
    FILES=("$TARGET")
else
    mapfile -t FILES < <(find "$TARGET" -name '*.vox' | sort)
fi

# CI runs the deterministic gate only: the soak tests are local-master
# work (200 generates 2000 programs at budgets to 300, 270_layout re-runs
# the corpus through every layout) and a shared runner kills or starves
# them; the full suite remains the acceptance gate the master runs before
# any merge (PROCEDURE 9). VOX_FUZZ_CI=1 is set by the workflow, never
# locally.
SOAK_TESTS="200_never_emitted 270_layout"

for f in "${FILES[@]}"; do
    name="$(basename "$f" .vox)"
    if [[ ${VOX_FUZZ_CI:-0} == 1 ]] && [[ " $SOAK_TESTS " == *" $name "* ]]; then
        echo "SKIP $name (soak test, local gate only)"
        continue
    fi
    exp="$(dirname "$f")/$name.expected"
    [[ -f "$exp" ]] || continue
    bin="$WORK/$name"
    COMPILE_START=$SECONDS
    if ! "$VOX" "$f" -o "$bin" > "$WORK/$name.cerr" 2>&1; then
        echo -e "${RED}COMPILE FAIL${NC} $name"
        [[ $VERBOSE == 1 ]] && cat "$WORK/$name.cerr"
        FAILED=$((FAILED+1)); continue
    fi
    COMPILE_ELAPSED=$((SECONDS-COMPILE_START))
    # Run from the REPO ROOT: tests reach fixtures (tests/fixtures/...)
    # and the compiler (../vox/...) by repo-relative paths, and their
    # ./vf_* scratch files land here, gitignored and swept after each
    # test. The cap is here to catch a genuine hang, not to bound how
    # long a legitimately long test may take, so it outlasts both the
    # longest deadline any test passes to 'run shell' (070's 120s) and
    # the longest sweep any test does. 200_never_emitted generates 2000
    # programs at budgets up to 300 and took 2m12 before the prelude was
    # randomised; on this machine it now runs in about 2m25, and it ran
    # long enough on a loaded one to be killed by the old 150s cap
    # intermittently. 420s is not killing it and still catches a hang
    # inside one suite run.
    #
    # A cap that generous no longer catches a SLOWDOWN, only a hang, so
    # every result line carries its own seconds -- compile and run kept
    # apart, because they lengthen for different reasons: a bigger
    # GENERATOR lengthens the compile, a wordier GENERATED PROGRAM
    # lengthens the run. A test that has doubled since the times in the
    # branch report says so on its own line, with no stopwatch.
    START=$SECONDS
    timeout 420 "$bin" > "$WORK/$name.out" 2>&1
    ELAPSED=$((SECONDS-START))
    rm -rf ./vf_*
    if diff -q "$exp" "$WORK/$name.out" > /dev/null; then
        echo -e "${GREEN}PASS${NC} $name (compile ${COMPILE_ELAPSED}s, run ${ELAPSED}s)"
        PASSED=$((PASSED+1))
    else
        echo -e "${RED}FAIL${NC} $name (compile ${COMPILE_ELAPSED}s, run ${ELAPSED}s)"
        [[ $VERBOSE == 1 ]] && diff -u "$exp" "$WORK/$name.out"
        FAILED=$((FAILED+1))
    fi
done

echo "passed: $PASSED  failed: $FAILED"

# LANGUAGE.md:N citations in docs/ledger/ are the ledger's whole point —
# a stale one is a false claim about what the manual says. Fast enough
# (well under a second) to gate every run; src/ and tests/ are checked
# separately (their citations belong to the generator authors, not this
# gate) via `scripts/check-citations.sh src tests`.
if [[ -x scripts/check-citations.sh ]]; then
    LANGUAGE_MD="${LANGUAGE_MD:-$VOX_REPO_ROOT/LANGUAGE.md}" scripts/check-citations.sh docs || FAILED=$((FAILED+1))
fi

[[ $FAILED -eq 0 ]]