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
    if grep -qiE "compile error|compile failed" <<<"$expected"; then
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
    wantexit="$(grep -oE 'exit (status )?[0-9]+' <<<"$expected" | head -1 | grep -oE '[0-9]+$')"
    # annotation lines like "(exit status 3)", bare "exit 3", or
    # "(deterministic, 6/6 runs)" are notes, not output — strip both the
    # parenthesized and the bare-line spelling of the exit annotation
    expected="$(grep -vE '^\(exit( status)? [0-9]+\)' <<<"$expected" | grep -vE '^ *exit( status)? [0-9]+ *$' | grep -vE '^\(compile failed' | sed 's/[[:space:]]*$//')"
    # stdin: a "Ran:" header line of the form "... && printf '...' | ./p" feeds the probe
    feed="$(grep -m1 '^ *Ran:' "$probe" | sed -n "s/.*&& *\(printf [^|]*\)| *\.\/p.*/\1/p")"
    # argv: anything after "./p" (or "| ./p") on the Ran: line — e.g. "&& ./p alpha beta" -> "alpha beta"
    pargv="$(grep -m1 '^ *Ran:' "$probe" | sed -n 's#.*\./p##p' | sed 's/^ *//; s/ *$//')"
    # probes run from the REPO ROOT (fixture paths like docs/ledger/probes/<slug>/fixtures/... are relative to it)
    if [ -n "$feed" ]; then actual="$(cd "$root" && eval "$feed" | timeout 10 "$work/$name" $pargv 2>&1)"; status=${PIPESTATUS[1]:-$?}
    else actual="$(cd "$root" && timeout 10 "$work/$name" $pargv 2>&1)"; status=$?; fi
    actual="$(sed 's/[[:space:]]*$//' <<<"$actual")"
    if [ -n "$wantexit" ]; then
      # A crash/exit/error probe ASSERTS on its exit code. Its stdout is often
      # non-deterministic (a run-varying heap pointer, a core-dump/timeout
      # line, or genuinely clock-dependent output like a wall-clock read),
      # so an empty recorded block, a "Segmentation" line, or a block that
      # says its own output is clock-dependent is exit-only; any other
      # recorded block must still match stdout literally.
      if [ "$status" = "$wantexit" ] && { [ -z "$expected" ] || [ "$actual" = "$expected" ] || grep -qi "Segmentation\|clock-dependent" <<<"$expected"; }; then pass=$((pass+1)); echo "PASS  $probe (exit $status as recorded)"
      else fail=$((fail+1)); echo "FAIL  $probe (expected exit $wantexit, got $status)"; diff <(echo "$expected") <(echo "$actual") | sed 's/^/      /' | head -6; fi
    elif [ "$actual" = "$expected" ]; then pass=$((pass+1)); echo "PASS  $probe"
    else fail=$((fail+1)); echo "FAIL  $probe"; diff <(echo "$expected") <(echo "$actual") | sed 's/^/      /' | head -10; fi
  done
done
echo "probes: $pass passed, $fail failed, $skip skipped"
[ $fail -eq 0 ]
