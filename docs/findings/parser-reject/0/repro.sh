#!/bin/sh
# Requires VOX_CORE_PATH set to the vox repo's coreasm directory, and
# $VOX pointing at the vox binary under test (defaults to vox 0.4.2).
# This is a compile-time rejection: it never produces a binary to run.
VOX="${VOX:-vox}"
"$VOX" program.vox -o prog
echo "compiler exit: $?"
