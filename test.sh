#!/bin/bash
# vox-fuzz test runner — compiles and runs each tests/NNN_*.vox and
# diffs its output against the matching .expected file.

VOX="${VOX:-../vox/target/release/vox}"
# Pin the runtime to the repo's coreasm. Without this an installed
# /usr/share/vox/coreasm silently shadows it and we would be testing the
# packaged compiler runtime instead of the one under development.
export VOX_CORE_PATH="${VOX_CORE_PATH:-$(cd "$(dirname "$VOX")/../.." && pwd)/coreasm}"
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

for f in "${FILES[@]}"; do
    name="$(basename "$f" .vox)"
    exp="$(dirname "$f")/$name.expected"
    [[ -f "$exp" ]] || continue
    bin="$WORK/$name"
    if ! "$VOX" "$f" -o "$bin" > "$WORK/$name.cerr" 2>&1; then
        echo -e "${RED}COMPILE FAIL${NC} $name"
        [[ $VERBOSE == 1 ]] && cat "$WORK/$name.cerr"
        FAILED=$((FAILED+1)); continue
    fi
    # Run from the REPO ROOT: tests reach fixtures (tests/fixtures/...)
    # and the compiler (../vox/...) by repo-relative paths, and their
    # ./vf_* scratch files land here, gitignored and swept after each
    # test. 150s outlasts the longest per-test deadline any test passes
    # to 'run shell' (070's 120s).
    timeout 150 "$bin" > "$WORK/$name.out" 2>&1
    rm -rf ./vf_*
    if diff -q "$exp" "$WORK/$name.out" > /dev/null; then
        echo -e "${GREEN}PASS${NC} $name"
        PASSED=$((PASSED+1))
    else
        echo -e "${RED}FAIL${NC} $name"
        [[ $VERBOSE == 1 ]] && diff -u "$exp" "$WORK/$name.out"
        FAILED=$((FAILED+1))
    fi
done

echo "passed: $PASSED  failed: $FAILED"
[[ $FAILED -eq 0 ]]