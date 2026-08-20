#!/usr/bin/env bash
# Re-run every retained ledger probe and diff its output against the
# "Actual output:" block recorded in its header. A probe whose output has
# drifted means the compiler, the manual, or the ledger row has changed —
# which is exactly what the ledger exists to notice.
#   docs/check-probes.sh [docs/ledger/probes/<slug> ...]
set -u
VOX="${VOX:-$(dirname "$0")/../../vox/target/release/vox}"
export VOX_CORE_PATH="${VOX_CORE_PATH:-$(cd "$(dirname "$VOX")/../.." && pwd)/coreasm}"
[ -d "$VOX_CORE_PATH" ] || { echo "VOX_CORE_PATH '$VOX_CORE_PATH' is not a directory" >&2; exit 2; }
root="$(cd "$(dirname "$0")/.." && pwd)"
dirs=("$@"); [ ${#dirs[@]} -gt 0 ] || dirs=("$(dirname "$0")"/ledger/probes/*/)
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
pass=0; fail=0; skip=0
for d in "${dirs[@]}"; do
  for probe in "$d"/*.vox; do
    [ -e "$probe" ] || continue
    # expected = lines between "Actual output:" and the closing paren, de-indented
    # header label is "expected output:" or "Actual output:" (either case); the block
    # ends at a line that is just ")" (so printed parens survive); optional 3-space indent is stripped
    expected="$(awk 'tolower($0) ~ /(expected|actual) output:/{f=1;next} f&&/^[ ]*\)[ ]*$/{exit} f{print}' "$probe" | sed 's/^   //')"
    if [ -z "$expected" ]; then skip=$((skip+1)); echo "SKIP  $probe (no recorded output)"; continue; fi
    name="$(basename "$probe" .vox)"
    # Three kinds of recorded outcome:
    #   compile-error probe - the block mentions "compile error": PASS iff vox refuses
    #     AND its stderr contains the block's first line (minus a leading "error: ");
    #   crash/exit probe   - the block contains "exit NNN": PASS iff the binary exits NNN
    #     (a documented segfault repro records "exit 139");
    #   ordinary probe     - stdout+stderr must equal the block exactly.
    if grep -qi "compile error" <<<"$expected"; then
      want="$(head -1 <<<"$expected" | sed 's/^ *error: *//')"
      if "$VOX" "$probe" -o "$work/$name" >"$work/$name.cerr" 2>&1; then
        fail=$((fail+1)); echo "FAIL  $probe (expected a compile error, but it compiled)"
      elif grep -qF -- "$want" "$work/$name.cerr"; then pass=$((pass+1)); echo "PASS  $probe (compile error as recorded)"
      else fail=$((fail+1)); echo "FAIL  $probe (compile error differs)"; sed 's/^/      /' "$work/$name.cerr" | head -4; fi
      continue
    fi
    if ! "$VOX" "$probe" -o "$work/$name" >"$work/$name.cerr" 2>&1; then
      fail=$((fail+1)); echo "FAIL  $probe (did not compile)"; sed 's/^/      /' "$work/$name.cerr" | head -5; continue
    fi
    wantexit="$(grep -o 'exit [0-9]\+' <<<"$expected" | head -1 | awk '{print $2}')"
    # probes run from the REPO ROOT (fixture paths like docs/ledger/probes/<slug>/fixtures/... are relative to it)
    actual="$(cd "$root" && timeout 10 "$work/$name" 2>&1)"; status=$?
    if [ -n "$wantexit" ]; then
      if [ "$status" = "$wantexit" ]; then pass=$((pass+1)); echo "PASS  $probe (exit $status as recorded)"
      else fail=$((fail+1)); echo "FAIL  $probe (expected exit $wantexit, got $status)"; fi
    elif [ "$actual" = "$expected" ]; then pass=$((pass+1)); echo "PASS  $probe"
    else fail=$((fail+1)); echo "FAIL  $probe"; diff <(echo "$expected") <(echo "$actual") | sed 's/^/      /' | head -10; fi
  done
done
echo "probes: $pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ]
