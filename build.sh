#!/usr/bin/env bash
# Build odin-bytes. Odin links via clang; ~/.local/bin holds the clang->gcc
# wrapper, so it MUST be on PATH.
set -euo pipefail
cd "$(dirname "$0")"
export TC="$HOME/.local/toolchains"
export PATH="$TC/odin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
mkdir -p bin
odin build src -out:bin/odin-bytes
echo "built bin/odin-bytes"