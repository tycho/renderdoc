#!/usr/bin/env bash
# Link the ARM64 + ARM64EC build trees into a single ARM64X renderdoc.dll.
#
# Usage: scripts/link-arm64x.sh [<config>]
#   <config> is one of Debug, Release, RelWithDebInfo, MinSizeRel
#   (default: Debug)
#
# Prereqs:
#   * cmake build tree at build-arm64/    (-A ARM64    -DENABLE_QRENDERDOC=ON)
#   * cmake build tree at build-arm64ec/  (-A ARM64EC  -DENABLE_QRENDERDOC=OFF -DENABLE_PYRENDERDOC=OFF)
#   * Both trees built with `cmake --build ... --target renderdoc` for the chosen config.
#
# Result lands at build-arm64/bin/<config>/renderdoc.dll (overwrites the
# ARM64-only artifact). The original is preserved as renderdoc.dll.arm64-only.

set -euo pipefail

CONFIG="${1:-Debug}"
ROOT="$(cd "$(dirname "$0")/.." && pwd -W)"

ARM64="${ROOT}/build-arm64/renderdoc"
ARM64EC="${ROOT}/build-arm64ec/renderdoc"
OUT="${ROOT}/build-arm64/bin/${CONFIG}/renderdoc.dll"
PDB="${ROOT}/build-arm64/bin/${CONFIG}/renderdoc.pdb"
DEF="${ROOT}/renderdoc/os/win32/comexport.def"

# Locate MSVC + SDK by looking under VS18 Enterprise. Adjust the version stem
# if you upgrade.
MSVC_BASE="/c/Program Files/Microsoft Visual Studio/18/Enterprise/VC/Tools/MSVC"
MSVC_VER="$(ls "${MSVC_BASE}" | sort -V | tail -1)"
LINK="${MSVC_BASE}/${MSVC_VER}/bin/Hostarm64/arm64/link.exe"
LIB_EXE="${MSVC_BASE}/${MSVC_VER}/bin/Hostarm64/arm64/lib.exe"
SDK_BASE="/c/Program Files (x86)/Windows Kits/10/Lib"
SDK_VER="$(ls "${SDK_BASE}" | sort -V | tail -1)"

# link.exe LIB env. ARM64EC libs come first so ARM64EC-flavoured CRT helpers
# resolve preferentially when linking the EC view.
export LIB="C:\\Program Files\\Microsoft Visual Studio\\18\\Enterprise\\VC\\Tools\\MSVC\\${MSVC_VER}\\lib\\arm64ec;\
C:\\Program Files\\Microsoft Visual Studio\\18\\Enterprise\\VC\\Tools\\MSVC\\${MSVC_VER}\\lib\\arm64;\
C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\${SDK_VER}\\um\\arm64;\
C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\${SDK_VER}\\ucrt\\arm64"

# Both ARM64 and ARM64EC rdoc.lib include renderdoc.res (compiled from a
# version-info .rc). The linker rejects a duplicate .res across inputs, so
# strip it from the ARM64EC copy. Keep the original around in case the EC
# version was rebuilt.
STRIP_LIB="${ARM64EC}/rdoc.dir/${CONFIG}/rdoc.lib"
NORES_LIB="${ARM64EC}/rdoc.dir/${CONFIG}/rdoc-nores.lib"
cp "${STRIP_LIB}" "${NORES_LIB}"
"${LIB_EXE}" "-REMOVE:rdoc.dir\\${CONFIG}\\renderdoc.res" "${NORES_LIB}" >/dev/null

# Each side's static archives. WHOLEARCHIVE on every input so neither side's
# symbols get short-circuited by the other.
WHOLE=()
WHOLE+=("-WHOLEARCHIVE:${ARM64}/rdoc.dir/${CONFIG}/rdoc.lib")
WHOLE+=("-WHOLEARCHIVE:${ARM64EC}/rdoc.dir/${CONFIG}/rdoc-nores.lib")
for sub in rdoc_version.dir driver/ihv/amd/rdoc_amd.dir driver/ihv/nv/rdoc_nv.dir \
           driver/shaders/spirv/rdoc_spirv.dir driver/vulkan/rdoc_vulkan.dir; do
  WHOLE+=("-WHOLEARCHIVE:${ARM64}/${sub}/${CONFIG}/$(basename ${sub} .dir).lib")
  WHOLE+=("-WHOLEARCHIVE:${ARM64EC}/${sub}/${CONFIG}/$(basename ${sub} .dir).lib")
done
WHOLE+=("-WHOLEARCHIVE:${ARM64}/${CONFIG}/renderdoc_libentry.lib")
WHOLE+=("-WHOLEARCHIVE:${ARM64EC}/${CONFIG}/renderdoc_libentry.lib")

if [ -f "${OUT}" ] && [ ! -f "${OUT}.arm64-only" ]; then
  cp "${OUT}" "${OUT}.arm64-only"
fi
rm -f "${OUT}"

"${LINK}" -DLL -MACHINE:ARM64X -OUT:"${OUT}" -DEF:"${DEF}" \
  -SUBSYSTEM:CONSOLE -DEBUG -PDB:"${PDB}" \
  "${WHOLE[@]}" \
  ws2_32.lib kernel32.lib user32.lib shlwapi.lib setupapi.lib version.lib \
  iphlpapi.lib psapi.lib gdi32.lib winspool.lib shell32.lib ole32.lib \
  oleaut32.lib uuid.lib comdlg32.lib advapi32.lib

echo "ARM64X DLL produced: ${OUT}"
