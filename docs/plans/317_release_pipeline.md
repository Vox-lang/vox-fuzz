# 317 — vox-fuzz release pipeline

**Status:** staged by TheJostler (2026-08-18). **Not started** — gated on
a working initial release (the CLI of plan Task 8, at minimum, so the
shipped binary has a user interface).

**Goal:** a `release.sh` with the same shape and safeguards as the vox
and vox-libs ones — version bump across every mirror, safeguarding
questions, refuses a dirty tree, never commits (the owner signs), and a
`--publish` that pushes the release everywhere it belongs.

## Where it publishes — and one correction

| Channel | Ships? | Notes |
|---|---|---|
| **GitHub release** | yes | notes from CHANGELOG.md's section for the version, exactly as the other repos |
| **Copr (RPM)** | yes | see the spec notes below |
| **Nix flake** | yes | flake in-repo like vox's; `nix run github:Vox-lang/vox-fuzz` |
| **crates.io** | **no — flagged** | vox-fuzz contains no Rust: it is a Vox program, and crates.io publishes Cargo crates only. There is nothing to upload without wrapping the tool in a fake crate, which is the vox-libs lesson from this morning (that crate was judged pointless and torn down). If a cargo-side presence is ever wanted, the honest route is a note in the vox-lang crate's README pointing here. Awaiting TheJostler's confirmation to drop the channel. |

## The spec file (Copr)

Follows vox-libs.spec's model, because the build shape is identical —
a Vox program compiled by the vox compiler:

- `BuildRequires: vox, nasm, binutils, make` (vox is in the same Copr
  project, so the buildroot resolves it).
- **`ExclusiveArch: x86_64`** from day one — vox emits x86_64 NASM only;
  vox-libs burned 28 chroots learning this today (evidence:
  `ld: i386:x86-64 architecture of input file … incompatible`, verified
  from the failed build logs). Do not repeat it.
- Runtime `Requires:` nothing beyond glibc-free reality — the binary is
  static; `Recommends: vox` at most, since fuzzing needs a compiler to
  fuzz.
- `%check` runs `./test.sh` with the buildroot's vox.

## The flake

Mirror vox's flake.nix: build the vox compiler as an input (flake input
on `github:Vox-lang/vox`), then `make build VOX=… VOX_CORE_PATH=…`,
install `build/vox-fuzz` to `$out/bin`. `SHELL := /bin/sh` discipline in
the Makefile already holds (vox-libs' Nix lesson).

## Version places

`src/version.vox` (the `'fuzz version'` line) is authoritative; the spec
and flake mirror it. `release.sh --show-versions` lists all three, the
bump rewrites all three, and the post-bump check refuses drift — same
contract as vox's release.sh.

## Prerequisites before starting

1. Plan Task 8 (CLI) merged — a release without a CLI has nothing to
   ship.
2. TheJostler's ruling on the crates.io row above.
3. The Copr project webhook/package entry for vox-fuzz (same
   `.copr/Makefile make_srpm` arrangement as the other repos).

## Verification

1. `./release.sh --bump-patch` from a clean tree bumps all three places
   and they agree; from a dirty tree it refuses.
2. `--publish` produces: a GitHub release whose notes match the
   changelog section; a Copr build that goes green on every x86_64
   chroot and **skips** (not fails) everything else; `nix run` of the
   tagged rev prints the version.
3. The 7z archive carries the binary, README, LICENSE, and CHANGELOG —
   same manifest style as vox's.
