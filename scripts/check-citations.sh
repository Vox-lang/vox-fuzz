#!/usr/bin/env bash
# Every `LANGUAGE.md:N` / `LANGUAGE.md:N-M` citation in src/, tests/,
# docs/ and scripts/ (plus CLAUDE.md) is a claim that line N of the
# manual holds the text being cited. A citation is only MECHANICALLY
# checkable — this script cannot tell you the cited line supports the
# claim, only that it exists and isn't obviously nothing (blank, a code
# fence, a bare heading). Landing on real prose is necessary, not
# sufficient; the ledger's own "read the claim, search the manual, land
# on it" rule is what makes a citation actually correct.
#
#   scripts/check-citations.sh [--show] [path ...]
#
# --show prints the cited line next to each citation, for eyeballing.
# With no paths, walks src/ tests/ docs/ scripts/ CLAUDE.md from the repo
# root. Exits non-zero iff any citation is stale.
set -u

show=0
if [ "${1:-}" = "--show" ]; then show=1; shift; fi

root="$(cd "$(dirname "$0")/.." && pwd)"
LANGUAGE_MD="${LANGUAGE_MD:-$root/../../vox/LANGUAGE.md}"
if [ ! -f "$LANGUAGE_MD" ]; then
  echo "LANGUAGE.md not found at '$LANGUAGE_MD' (set LANGUAGE_MD explicitly)" >&2
  exit 2
fi

paths=("$@")
[ ${#paths[@]} -gt 0 ] || paths=(src tests docs scripts CLAUDE.md)

# One process, two inputs: LANGUAGE.md (to build the line table) then
# every "file:lineno:match" grep hit (to check against it). Doing the
# line lookup in-process instead of shelling out to sed once per
# citation is what keeps this fast enough to be worth running often.
grep -rnoE 'LANGUAGE\.md:[0-9]+([-–][0-9]+)?' "${paths[@]}" 2>/dev/null | \
awk -v show="$show" -v manualpath="$LANGUAGE_MD" '
  BEGIN {
    while ((getline line < manualpath) > 0) {
      n++
      manual[n] = line
    }
    close(manualpath)
  }
  {
    # each input line: "path:lineno:LANGUAGE.md:N" or "...:LANGUAGE.md:N-M"
    line = $0
    colon1 = index(line, ":")
    rest = substr(line, colon1 + 1)
    colon2 = index(rest, ":")
    file = substr(line, 1, colon1 - 1)
    srcline = substr(rest, 1, colon2 - 1)
    cite = substr(rest, colon2 + 1)

    num = cite
    sub(/^LANGUAGE\.md:/, "", num)
    first = num
    # strip everything from the first dash (ascii "-" or en dash "–") onward
    dash = index(first, "-")
    endash = index(first, "\xe2\x80\x93")
    cut = 0
    if (dash > 0 && (endash == 0 || dash < endash)) cut = dash
    else if (endash > 0) cut = endash
    if (cut > 0) first = substr(first, 1, cut - 1)
    first = first + 0

    count++
    target = (first >= 1 && first <= n) ? manual[first] : ""
    trimmed = target
    gsub(/^[ \t]+|[ \t]+$/, "", trimmed)

    reason = ""
    if (trimmed == "") reason = "blank line"
    else if (trimmed ~ /^```/) reason = "code fence"
    else if (trimmed ~ /^#+[ \t]/) reason = "heading-only line"

    if (reason != "") {
      stale++
      shown = (trimmed == "") ? "empty" : "\"" trimmed "\""
      printf "STALE %s:%s  %s  (%s: LANGUAGE.md:%s is %s)\n", file, srcline, cite, reason, first, shown
    } else if (show == "1") {
      printf "OK    %s:%s  %s  -> LANGUAGE.md:%s: %s\n", file, srcline, cite, first, trimmed
    }
  }
  END {
    printf "citations: %d checked, %d stale\n", count, stale
    exit (stale > 0)
  }
'
