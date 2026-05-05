#!/usr/bin/env bash
# Stage the ARM64EC sibling files into the ARM64 build's bin/<config>/arm64ec/
# directory so the runtime can load it as the implicit Vulkan layer for x64-emulated
# victims and the ARM64 renderdoccmd can farm off cross-arch capture inject to it.
#
# Usage: scripts/stage-arm64ec-sibling.sh [<config>]
#   <config> is one of Debug, Release, RelWithDebInfo, MinSizeRel
#   (default: Debug)
#
# Prereqs (build both trees first):
#   cmake -S . -B build-arm64    -A ARM64    -DENABLE_QRENDERDOC=ON
#   cmake -S . -B build-arm64ec  -A ARM64EC  -DENABLE_QRENDERDOC=OFF -DENABLE_PYRENDERDOC=OFF
#   cmake --build build-arm64    --config <config> --target renderdoc renderdoccmd qrenderdoc
#   cmake --build build-arm64ec  --config <config> --target renderdoc renderdoccmd
#
# After staging:
#   * Re-register the layer (admin):
#       renderdoccmd.exe vulkanlayer --register --system
#   * The ARM64 build's renderdoccmd will farm off to arm64ec/renderdoccmd.exe
#     when it detects an x64-emulated victim, and the Vulkan loader will pick the
#     ARM64EC sibling layer (different layer name from the ARM64 one) for x64
#     processes via the implicit-layer registry.

set -euo pipefail

CONFIG="${1:-Debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd -W)"

ARM64_BIN="${ROOT}/build-arm64/bin/${CONFIG}"
ARM64EC_BIN="${ROOT}/build-arm64ec/bin/${CONFIG}"
EC_JSON_SRC="${ROOT}/build-arm64ec/renderdoc/driver/vulkan/renderdoc.json"
DEST="${ARM64_BIN}/arm64ec"

if [ ! -f "${ARM64EC_BIN}/renderdoc.dll" ]; then
  echo "Missing ${ARM64EC_BIN}/renderdoc.dll - did you build the ARM64EC tree?" >&2
  exit 1
fi
if [ ! -f "${ARM64EC_BIN}/renderdoccmd.exe" ]; then
  echo "Missing ${ARM64EC_BIN}/renderdoccmd.exe - did you build the ARM64EC tree?" >&2
  exit 1
fi
if [ ! -f "${EC_JSON_SRC}" ]; then
  echo "Missing ${EC_JSON_SRC} - did the ARM64EC configure step run?" >&2
  exit 1
fi

mkdir -p "${DEST}"
cp -f "${ARM64EC_BIN}/renderdoc.dll"    "${DEST}/renderdoc.dll"
cp -f "${ARM64EC_BIN}/renderdoc.pdb"    "${DEST}/renderdoc.pdb"   2>/dev/null || true
cp -f "${EC_JSON_SRC}"                  "${DEST}/renderdoc.json"
cp -f "${ARM64EC_BIN}/renderdoccmd.exe" "${DEST}/renderdoccmd.exe"
cp -f "${ARM64EC_BIN}/renderdoccmd.pdb" "${DEST}/renderdoccmd.pdb" 2>/dev/null || true

echo "Staged ARM64EC sibling at ${DEST}"
echo "Layer name in JSON: $(grep '"name"' "${DEST}/renderdoc.json" | head -1 | sed -E 's/.*"name": "([^"]+)".*/\1/')"
