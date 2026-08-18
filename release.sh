#!/bin/bash
# vox-fuzz release driver — same contracts as the vox and vox-libs ones:
# a bump asks safeguarding questions, refuses a dirty tree, rewrites every
# version mirror from ONE list, verifies they agree, and never commits (the
# owner reviews and signs). --publish builds, archives, and pushes to
# crates.io, Copr, and a GitHub release; the Nix flake ships from the repo
# itself and needs no push step beyond the tag.

set -e

PUBLISH=0
FORCE_COPR=0
BUMP=""
SET_VERSION=""
SHOW_VERSIONS=0
_expect=""
for arg in "$@"; do
    if [ -n "$_expect" ]; then
        SET_VERSION="$arg"; _expect=""; continue
    fi
    case "$arg" in
        --set-version) _expect=set ; continue ;;
        --set-version=*) SET_VERSION="${arg#*=}" ; continue ;;
        --show-versions) SHOW_VERSIONS=1 ;;
        --publish) PUBLISH=1 ;;
        --force-copr) FORCE_COPR=1 ;;
        --bump-patch) [ -n "$BUMP" ] && { echo "Only one --bump-* flag at a time." >&2; exit 1; }; BUMP=patch ;;
        --bump-minor) [ -n "$BUMP" ] && { echo "Only one --bump-* flag at a time." >&2; exit 1; }; BUMP=minor ;;
        --bump-major) [ -n "$BUMP" ] && { echo "Only one --bump-* flag at a time." >&2; exit 1; }; BUMP=major ;;
        --help|-h)
            cat <<'USAGE'
./release.sh [flags]

  (no flags)          nothing (a bare run neither builds nor publishes)
  --show-versions     print what every version mirror currently says
  --publish           build + test, archive the .7z, then publish:
                      crates.io, Copr, GitHub release
  --bump-patch        0.1.0 -> 0.1.1   all mirrors
  --bump-minor        0.1.1 -> 0.2.0
  --bump-major        0.9.4 -> 1.0.0
  --set-version X.Y.Z force every mirror to X.Y.Z (repairs drift)
  --force-copr        trigger a Copr rebuild even if already sent

Version places: Cargo.toml (authoritative), Cargo.lock, vox-fuzz.spec,
flake.nix, src/version.vox (the 'fuzz version' line).

A bump refuses on a dirty tree, asks safeguarding questions, verifies
every mirror agrees afterwards, and never commits — you review and sign.
USAGE
            exit 0 ;;
    esac
done

MIRROR_LIST="Cargo.toml (authoritative), Cargo.lock, vox-fuzz.spec, flake.nix, src/version.vox"

write_version_everywhere() {
    local new="$1"
    sed -i "0,/^version = \".*\"/s//version = \"$new\"/" Cargo.toml
    sed -i "0,/^Version:\( *\).*/s//Version:\1$new/" vox-fuzz.spec
    sed -i "0,/version = \".*\";/s//version = \"$new\";/" flake.nix
    sed -i "s/vox-fuzz [0-9][0-9.]*/vox-fuzz $new/" src/version.vox
    # Refresh Cargo.lock's record of this package.
    cargo check --quiet >/dev/null 2>&1 || true
    verify_version_consistency "$new"
}

mirror_value() {
    case "$1" in
        cargo) grep -m1 '^version' Cargo.toml | sed 's/.*"\(.*\)".*/\1/' ;;
        lock)  grep -A1 'name = "vox-fuzz"' Cargo.lock 2>/dev/null | grep -m1 '^version' | sed 's/.*"\(.*\)".*/\1/' ;;
        spec)  grep -m1 '^Version:' vox-fuzz.spec | awk '{print $2}' ;;
        flake) grep -m1 'version = "' flake.nix | sed 's/.*"\(.*\)".*/\1/' ;;
        vox)   grep -o 'vox-fuzz [0-9][0-9.]*' src/version.vox | awk '{print $2}' ;;
    esac
}

show_version_mirrors() {
    echo "Current version in each place:"
    printf '  %-18s %s\n' "Cargo.toml"     "$(mirror_value cargo)  <- authoritative"
    printf '  %-18s %s\n' "Cargo.lock"     "$(mirror_value lock)"
    printf '  %-18s %s\n' "vox-fuzz.spec"  "$(mirror_value spec)"
    printf '  %-18s %s\n' "flake.nix"      "$(mirror_value flake)"
    printf '  %-18s %s\n' "src/version.vox" "$(mirror_value vox)"
}

verify_version_consistency() {
    local want="$1" bad=0
    for m in cargo lock spec flake vox; do
        v=$(mirror_value "$m")
        if [ "$v" != "$want" ]; then
            echo "MISMATCH: $m says '$v', expected '$want'" >&2; bad=1
        fi
    done
    if [ "$bad" -eq 1 ]; then
        echo "Version mirrors disagree after the bump -- fix them before releasing." >&2
        exit 1
    fi
    echo "All version mirrors agree on $want."
}

ask() {
    local prompt="$1" ans
    if ! read -r -p "$prompt (y) " ans; then
        echo >&2; echo "No answer (non-interactive?). Aborting." >&2; exit 1
    fi
    case "$ans" in [Yy]|[Yy][Ee][Ss]) ;; *) echo "Aborting -- nothing changed." >&2; exit 1 ;; esac
}

bump_version() {
    local kind="$1" cur major minor patch new
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "Working tree is not clean. Commit or stash first -- a version bump" >&2
        echo "must be reviewable on its own." >&2
        exit 1
    fi
    cur=$(mirror_value cargo)
    if ! [[ "$cur" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Cannot parse current version from Cargo.toml: '$cur'" >&2; exit 1
    fi
    IFS=. read -r major minor patch <<<"$cur"
    case "$kind" in
        patch) new="$major.$minor.$((patch+1))" ;;
        minor) new="$major.$((minor+1)).0" ;;
        major) new="$((major+1)).0.0" ;;
    esac
    echo "Version bump: $cur -> $new ($kind)"
    echo
    ask "Have README.md and the plan documents been checked for stale sections?"
    ask "Does the CHANGELOG (or release notes source) have a $new entry?"
    write_version_everywhere "$new"
    echo
    echo "Bumped to $new in: $MIRROR_LIST"
    echo "Not committed -- review the diff, then commit and sign it yourself."
}

set_version() {
    local new="$1"
    if ! [[ "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Not a semver version: '$new' (expected X.Y.Z)" >&2; exit 1
    fi
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "Working tree is not clean. Commit or stash first." >&2; exit 1
    fi
    echo; show_version_mirrors; echo
    ask "Set every place above to $new?"
    write_version_everywhere "$new"
    echo "Set to $new. Not committed -- review, then commit and sign."
}

if [ "$SHOW_VERSIONS" -eq 1 ]; then show_version_mirrors; exit 0; fi
if [ -n "$BUMP" ] && [ -n "$SET_VERSION" ]; then
    echo "--bump-* and --set-version do the same job differently; pick one." >&2; exit 1
fi
[ -n "$SET_VERSION" ] && set_version "$SET_VERSION"
[ -n "$BUMP" ] && bump_version "$BUMP"

if [ "$PUBLISH" -eq 0 ]; then
    if [ -z "$BUMP" ] && [ -z "$SET_VERSION" ]; then
        echo "Nothing to do. See ./release.sh --help (a bare run neither builds nor publishes)."
    fi
    exit 0
fi

# ---- publish -----------------------------------------------------------

VERSION=$(mirror_value cargo)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
DIST_DIR="build/dist"
mkdir -p "$DIST_DIR"
ARCHIVE_NAME="$DIST_DIR/vox-fuzz.${VERSION}.${OS}.${ARCH}.7z"

# Build the real Vox binary and prove the suite against it before anything
# ships. VOX/VOX_CORE_PATH come from the environment or an installed vox.
echo "Building via make..."
make build VOX="${VOX:-vox}"
echo "Running the gate..."
./test.sh

if [ ! -f build/vox-fuzz ]; then
    echo "build/vox-fuzz missing after make -- aborting before packaging." >&2
    exit 1
fi

7z a "$ARCHIVE_NAME" \
    build/vox-fuzz \
    src/ \
    tests/ \
    test.sh \
    Makefile \
    LICENSE \
    README.md

echo "Created: $ARCHIVE_NAME"

# Independent targets; one failure shouldn't block the rest.
FAILED=()

echo "Publishing to crates.io..."
if ! cargo publish; then
    echo "FAILED: crates.io" >&2
    FAILED+=("crates.io")
fi

echo "Triggering Copr build..."
COPR_MARKER="$DIST_DIR/.copr-last-version"
if ! command -v copr-cli >/dev/null 2>&1; then
    echo "copr-cli not found (sudo dnf install copr-cli). Skipping Copr rebuild." >&2
    FAILED+=("Copr (copr-cli missing)")
elif [ "$FORCE_COPR" -eq 0 ] && [ -f "$COPR_MARKER" ] && [ "$(cat "$COPR_MARKER")" = "$VERSION" ]; then
    echo "Copr already triggered for $VERSION (--force-copr to resend)."
elif copr-cli build-package vox-lang/Vox --name vox-fuzz --nowait; then
    echo "$VERSION" > "$COPR_MARKER"
else
    echo "FAILED: Copr" >&2
    FAILED+=("Copr")
fi

echo "Creating GitHub release v$VERSION..."
NOTES_SOURCE="README.md"
if ! gh release create "v$VERSION" "$ARCHIVE_NAME" \
        -R Vox-lang/vox-fuzz \
        --title "${RELEASE_TITLE:-vox-fuzz $VERSION}" \
        --generate-notes; then
    echo "FAILED: GitHub release (it may already exist for v$VERSION)" >&2
    FAILED+=("GitHub release")
fi

echo
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "Failed: ${FAILED[*]}" >&2
    exit 1
fi
echo "Published $VERSION: crates.io, Copr, GitHub release."
echo "Nix ships from the repo itself: nix run github:Vox-lang/vox-fuzz"
