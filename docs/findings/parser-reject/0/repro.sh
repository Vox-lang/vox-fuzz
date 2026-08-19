#!/bin/sh
# $VOX points at the vox binary under test (defaults to vox 0.4.2).
# VOX_CORE_PATH is pinned to the vox repo's coreasm directory below,
# unless already set in the environment - an unset one silently falls
# through to an installed /usr/share/vox/coreasm instead.
# This is a compile-time rejection: it never produces a binary to run.
VOX="${VOX:-vox}"
export VOX_CORE_PATH="${VOX_CORE_PATH:-../vox/coreasm}"
"$VOX" program.vox -o prog
echo "compiler exit: $?"
