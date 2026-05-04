# =====================================================================
# WIP STATUS — phase 2 of the Windows ARM64 port.
# =====================================================================
#
# Configure works. Build does not yet succeed: the qrenderdoc source assumes
# Qt 5 APIs that are removed in Qt 6, and converting all of them is a
# substantial port (multiple dozen sites) that hasn't been done yet.
#
# Already-applied mechanical renames (committed):
#   Qt::MidButton, QString::Skip/KeepEmptyParts, QString::null,
#   QPalette::Foreground/Background, QFileDialog::DirectoryOnly,
#   QStyle::PE_IndicatorViewItemCheck, Qt::ImMicroFocus.
#
# Remaining Qt 5 -> Qt 6 work (sketch — actual fix in source needed):
#
#   Removed includes:
#     <QDesktopWidget>     - use QGuiApplication::screenAt() / QScreen
#     <QRegExp>            - use <QRegularExpression>
#     <QTextCodec>         - use <QStringConverter> (Qt 6.0+) or QStringDecoder
#                            / QStringEncoder
#
#   Event handler signature changes (header changes too):
#     enterEvent(QEvent *)    -> enterEvent(QEnterEvent *)
#     wheelEvent QWheelEvent::delta()/x()/y()/pos()/orientation()
#                             -> angleDelta(), position(), pixelDelta()
#
#   Removed/replaced APIs:
#     QTime::start(), QTime::elapsed()  -> QElapsedTimer
#     QLayout::setMargin(N)             -> setContentsMargins(N, N, N, N)
#     QFontMetrics::width()             -> horizontalAdvance()
#     QComboBox::setAutoCompletion()    -> remove (always on now)
#     QModelIndex::child(r, c)          -> idx.model()->index(r, c, idx)
#     QSet::toList()                    -> QList<T>(set.begin(), set.end())
#     QStyleOption::init(widget)        -> initFrom(widget)
#     QTableView::viewOptions()         -> initViewItemOption(QStyleOptionViewItem*)
#     QMetaType::registerComparators<T>() -> not portable; either remove
#                                            (only used for sorting) or fall
#                                            back to a manual comparator
#     QAtomicInteger<T>::store(v)       -> storeRelaxed(v)
#     QString::midRef                   -> QStringView::mid or QString::mid
#     QPalette::foreground (the function, lowercase)
#                                       -> use ::brush(QPalette::WindowText)
#     Qt::AA_X11InitThreads             -> remove (Qt 6 always enabled)
#     QStandardPaths::HomeLocation case label
#                                       -> uses an enum that's no longer constexpr
#                                          in switch contexts; rewrite as if/else
#                                          chain
#     QPair<...> implicit + concatenation -> use std::pair / explicit conversion
#
#   Scintilla version mismatch:
#     The bundled qrenderdoc/3rdparty/scintilla appears to be built against an
#     older Scintilla API; ScintillaBase::ButtonDown(2 args) and similar fail
#     against the source files included. Either update Scintilla or write
#     compatibility shims at the call sites.
#
#   SWIG bindings:
#     The bundled swig.exe regenerates fine under XTAJIT32, but the SWIG output
#     contains "#error SWIG wrapped code invalid in 32 bit architecture" because
#     SWIG hasn't been told this is a 64-bit build. Pass -DSWIGWORDSIZE64 to
#     swig.exe (already done in the swig command above, but worth verifying it
#     reaches all paths once a real build is attempted).
#
#   Static analysis:
#     QFlags<T> is much stricter about implicit int conversions. Several places
#     return `int` where `QFlags<Qt::ItemFlag>` is expected; must use the named
#     enum value or explicit construction.
#
# Recommended next steps when picking this up:
#   1. Add the trivial mechanical renames first (setMargin, MidButton in any
#      remaining sites, QSet::toList, etc).
#   2. Fix the enterEvent signature in PixelHistoryView, ResourceInspector,
#      TextureViewer (header + cpp).
#   3. Convert QTime::start/elapsed sites to QElapsedTimer.
#   4. Wholesale port QWheelEvent users to the position()/angleDelta() API.
#   5. Replace QDesktopWidget, QRegExp, QTextCodec with their Qt 6 equivalents.
#   6. Audit Scintilla — likely the simplest fix is to drop in the matching
#      Scintilla version that ScintillaEditBase.cpp expects (look at the
#      function signatures it calls into).
#   7. Iterate on the remaining errors until qrenderdoc.exe links.
#
# Until then, the working ARM64 phase 1 deliverable is renderdoccmd.exe; UI
# users should keep using the existing x64 qrenderdoc.exe (it can replay
# captures from any architecture, just not capture from ARM64 victims).
# =====================================================================

# Native Qt6 CMake build for qrenderdoc on Windows.
#
# This file replaces the qmake-driven path in qrenderdoc/CMakeLists.txt for
# Windows. The qmake path expects bundled Qt5/Python/PySide2 binaries which
# don't exist for ARM64; this path uses externally-installed Qt6 and the
# system-installed Python.
#
# Required prerequisites:
#   - Qt 6.x SDK with the host arch's Widgets / Svg / Network / Gui modules.
#     CMAKE_PREFIX_PATH should point at it, e.g.
#         -DCMAKE_PREFIX_PATH=C:/Qt/6.11.0/msvc2022_arm64
#   - Python 3.x (8 or newer) with development headers + libs (the standard
#     python.org installer ships these). find_package(Python3) picks up the
#     one in PATH; override with -DPython3_ROOT_DIR=... to pick another.
#   - The bundled SWIG binary at qrenderdoc/3rdparty/swig/swig.exe — even on
#     ARM64 this is an x86 binary that runs under XTAJIT32 emulation. SWIG is
#     only run at build time for code generation, so the perf cost is a few
#     seconds per regenerate.

set(QRD_SRC ${CMAKE_CURRENT_SOURCE_DIR})

#
# Qt6
#

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Svg Network Core5Compat)
# Core5Compat ships QTextCodec, QRegExp, QStringRef etc. as drop-in shims for
# Qt-5 code that hasn't been ported yet. We use this to keep the bundled
# Scintilla source compiling without surgery.

# Qt6 requires C++17 minimum
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Where AUTOUIC drops generated headers — make UI files findable from anywhere.
set(CMAKE_AUTOUIC_SEARCH_PATHS
    ${QRD_SRC}/Windows
    ${QRD_SRC}/Windows/Dialogs
    ${QRD_SRC}/Windows/PipelineState
    ${QRD_SRC}/Widgets
    ${QRD_SRC}/Widgets/Extended)

#
# Python
#

# Allow overriding via Python3_ROOT_DIR (-DPython3_ROOT_DIR=C:/Python313-arm64
# is a common one). Components Interpreter+Development pulls in Python3::Python
# (the import library) and Python3_INCLUDE_DIRS.
find_package(Python3 3.8 REQUIRED COMPONENTS Interpreter Development)

# Python.org Windows distributions ship only the release library
# (python3xx.lib), not a debug variant (python3xx_d.lib). pyconfig.h on
# Windows emits `#pragma comment(lib, "python313_d.lib")` when _DEBUG is set.
# Suppress that auto-link by telling MSVC to ignore python3xx_d.lib and
# substitute the release one. This means our Debug build links against the
# release Python — which is fine because Debug Python ABI isn't compatible
# anyway and most extensions ship release-only.

message(STATUS "qrenderdoc: using Python ${Python3_VERSION} from ${Python3_EXECUTABLE}")
message(STATUS "qrenderdoc: Python include dir: ${Python3_INCLUDE_DIRS}")
message(STATUS "qrenderdoc: Python library: ${Python3_LIBRARIES}")

#
# SWIG bindings
#
# The bundled swig.exe at 3rdparty/swig/swig.exe is x86 but works under
# emulation on ARM64. We invoke it directly rather than building a custom
# SWIG (which would require autotools and isn't a Windows-friendly path).

set(BUNDLED_SWIG ${QRD_SRC}/3rdparty/swig/swig.exe)
if(NOT EXISTS ${BUNDLED_SWIG})
    message(FATAL_ERROR "qrenderdoc: bundled swig not found at ${BUNDLED_SWIG}")
endif()

set(swig_interfaces
    Code/pyrenderdoc/renderdoc.i
    Code/pyrenderdoc/qrenderdoc.i)

set(swig_output)
file(GLOB RDOC_REPLAY_FILES ${CMAKE_SOURCE_DIR}/renderdoc/api/replay/*.h)
file(GLOB QRD_INTERFACE_FILES ${QRD_SRC}/Code/Interface/*.h)
list(SORT RDOC_REPLAY_FILES)
list(SORT QRD_INTERFACE_FILES)

foreach(swig_in ${swig_interfaces})
    get_filename_component(swig_file ${swig_in} NAME_WE)

    # On Windows LLP64, long is 32-bit even on 64-bit targets. SWIG's
    # SWIGWORDSIZE64 mode (LP64) generates a self-check that fails on Windows;
    # SWIGWORDSIZE32 is the correct setting since `long` matches that here.
    add_custom_command(
        OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/${swig_file}_python.cxx
                ${CMAKE_CURRENT_BINARY_DIR}/${swig_file}.py
        COMMAND ${BUNDLED_SWIG} -v -Wextra -Werror -DSWIGWORDSIZE32 -O -c++ -python
                -interface ${swig_file} -modern -modernargs -enumclass
                -fastunpack -py3 -builtin
                -I${QRD_SRC}
                -I${CMAKE_SOURCE_DIR}/renderdoc/api/replay
                -outdir ${CMAKE_CURRENT_BINARY_DIR}
                -o ${CMAKE_CURRENT_BINARY_DIR}/${swig_file}_python.cxx
                ${QRD_SRC}/${swig_in}
        DEPENDS ${QRD_SRC}/${swig_in}
                ${RDOC_REPLAY_FILES}
                ${QRD_INTERFACE_FILES}
        COMMENT "SWIG ${swig_in}"
        VERBATIM)
    list(APPEND swig_output ${CMAKE_CURRENT_BINARY_DIR}/${swig_file}_python.cxx)
endforeach()

add_custom_target(swig-bindings DEPENDS ${swig_output})

# SWIG generates plain C++ source — it doesn't contain Q_OBJECT and there's
# nothing for AUTOMOC/AUTOUIC to do. Skip them explicitly to silence CMP0071
# and to avoid a redundant moc pass that would re-trigger every reconfigure.
set_source_files_properties(${swig_output} PROPERTIES
    SKIP_AUTOGEN ON
    GENERATED ON)

#
# Sources — translated from qrenderdoc.pro
#

set(QRD_SOURCES
    Code/qrenderdoc.cpp
    Code/qprocessinfo.cpp
    Code/ReplayManager.cpp
    Code/CaptureContext.cpp
    Code/ScintillaSyntax.cpp
    Code/QRDUtils.cpp
    Code/MiniQtHelper.cpp
    Code/BufferFormatter.cpp
    Code/Resources.cpp
    Code/RGPInterop.cpp
    Code/pyrenderdoc/PythonContext.cpp
    Code/Interface/QRDInterface.cpp
    Code/Interface/Analytics.cpp
    Code/Interface/ShaderProcessingTool.cpp
    Code/Interface/PersistantConfig.cpp
    Code/Interface/RemoteHost.cpp
    Styles/StyleData.cpp
    Styles/RDStyle/RDStyle.cpp
    Styles/RDTweakedNativeStyle/RDTweakedNativeStyle.cpp
    Windows/Dialogs/AboutDialog.cpp
    Windows/Dialogs/CrashDialog.cpp
    Windows/Dialogs/UpdateDialog.cpp
    Windows/MainWindow.cpp
    Windows/EventBrowser.cpp
    Windows/TextureViewer.cpp
    Windows/ShaderViewer.cpp
    Windows/ShaderMessageViewer.cpp
    Windows/DescriptorViewer.cpp
    Widgets/Extended/RDLineEdit.cpp
    Widgets/Extended/RDTextEdit.cpp
    Widgets/Extended/RDLabel.cpp
    Widgets/Extended/RDMenu.cpp
    Widgets/Extended/RDHeaderView.cpp
    Widgets/Extended/RDToolButton.cpp
    Widgets/Extended/RDDoubleSpinBox.cpp
    Widgets/Extended/RDListView.cpp
    Widgets/ComputeDebugSelector.cpp
    Widgets/CustomPaintWidget.cpp
    Widgets/ResourcePreview.cpp
    Widgets/ThumbnailStrip.cpp
    Widgets/ReplayOptionsSelector.cpp
    Widgets/TextureGoto.cpp
    Widgets/RangeHistogram.cpp
    Widgets/AnnotationDisplay.cpp
    Widgets/CollapseGroupBox.cpp
    Windows/Dialogs/TextureSaveDialog.cpp
    Windows/Dialogs/CaptureDialog.cpp
    Windows/Dialogs/LiveCapture.cpp
    Widgets/Extended/RDListWidget.cpp
    Windows/APIInspector.cpp
    Windows/PipelineState/PipelineStateViewer.cpp
    Windows/PipelineState/VulkanPipelineStateViewer.cpp
    Windows/PipelineState/D3D11PipelineStateViewer.cpp
    Windows/PipelineState/D3D12PipelineStateViewer.cpp
    Windows/PipelineState/GLPipelineStateViewer.cpp
    Widgets/Extended/RDTreeView.cpp
    Widgets/Extended/RDTreeWidget.cpp
    Widgets/BufferFormatSpecifier.cpp
    Windows/BufferViewer.cpp
    Widgets/Extended/RDTableView.cpp
    Windows/DebugMessageView.cpp
    Windows/LogView.cpp
    Windows/CommentView.cpp
    Windows/StatisticsViewer.cpp
    Windows/TimelineBar.cpp
    Windows/Dialogs/SettingsDialog.cpp
    Widgets/OrderedListEditor.cpp
    Widgets/MarkerBreadcrumbs.cpp
    Widgets/Extended/RDTableWidget.cpp
    Windows/Dialogs/SuggestRemoteDialog.cpp
    Windows/Dialogs/VirtualFileDialog.cpp
    Windows/Dialogs/RemoteManager.cpp
    Windows/Dialogs/ExtensionManager.cpp
    Windows/PixelHistoryView.cpp
    Widgets/PipelineFlowChart.cpp
    Windows/Dialogs/EnvironmentEditor.cpp
    Widgets/FindReplace.cpp
    Widgets/Extended/RDSplitter.cpp
    Windows/Dialogs/TipsDialog.cpp
    Windows/Dialogs/ConfigEditor.cpp
    Windows/PythonShell.cpp
    Windows/Dialogs/PerformanceCounterSelection.cpp
    Windows/PerformanceCounterViewer.cpp
    Windows/ResourceInspector.cpp
    Windows/Dialogs/AnalyticsConfirmDialog.cpp
    Windows/Dialogs/AnalyticsPromptDialog.cpp
    Windows/Dialogs/AxisMappingDialog.cpp
    Windows/Dialogs/CameraControlsDialog.cpp
    Windows/Dialogs/ProjectionGuessDialog.cpp

    # ToolWindowManager
    3rdparty/toolwindowmanager/ToolWindowManager.cpp
    3rdparty/toolwindowmanager/ToolWindowManagerArea.cpp
    3rdparty/toolwindowmanager/ToolWindowManagerSplitter.cpp
    3rdparty/toolwindowmanager/ToolWindowManagerTabBar.cpp
    3rdparty/toolwindowmanager/ToolWindowManagerWrapper.cpp

    # FlowLayout
    3rdparty/flowlayout/FlowLayout.cpp)

# UI forms — AUTOUIC handles these
file(GLOB_RECURSE QRD_UIS RELATIVE ${QRD_SRC}
    Windows/*.ui
    Windows/Dialogs/*.ui
    Windows/PipelineState/*.ui
    Widgets/*.ui)

# Resource files — AUTORCC handles these
set(QRD_RESOURCES
    Resources/resources.qrc
    Resources/qtconf.qrc)

# Scintilla source
file(GLOB_RECURSE SCINTILLA_LEXLIB ${QRD_SRC}/3rdparty/scintilla/lexlib/*.cxx)
file(GLOB_RECURSE SCINTILLA_LEXERS ${QRD_SRC}/3rdparty/scintilla/lexers/*.cxx)
file(GLOB_RECURSE SCINTILLA_SRC    ${QRD_SRC}/3rdparty/scintilla/src/*.cxx)
file(GLOB_RECURSE SCINTILLA_QT_EDIT ${QRD_SRC}/3rdparty/scintilla/qt/ScintillaEdit/*.cpp)
file(GLOB_RECURSE SCINTILLA_QT_BASE ${QRD_SRC}/3rdparty/scintilla/qt/ScintillaEditBase/*.cpp)
list(SORT SCINTILLA_LEXLIB)
list(SORT SCINTILLA_LEXERS)
list(SORT SCINTILLA_SRC)
list(SORT SCINTILLA_QT_EDIT)
list(SORT SCINTILLA_QT_BASE)

# Scintilla's Qt headers contain Q_OBJECT classes — AUTOMOC needs to see them.
# Rather than disabling MOC for the Scintilla TU we let AUTOMOC scan everything.

# Windows resource (icons + version info)
set(QRD_RC ${QRD_SRC}/Resources/qrenderdoc.rc)

#
# Target
#

add_executable(qrenderdoc WIN32
    ${QRD_SOURCES}
    ${QRD_UIS}
    ${QRD_RESOURCES}
    ${QRD_RC}
    ${swig_output}
    ${SCINTILLA_LEXLIB}
    ${SCINTILLA_LEXERS}
    ${SCINTILLA_SRC}
    ${SCINTILLA_QT_EDIT}
    ${SCINTILLA_QT_BASE})

add_dependencies(qrenderdoc swig-bindings renderdoc)

target_include_directories(qrenderdoc PRIVATE
    ${QRD_SRC}
    ${QRD_SRC}/3rdparty
    ${QRD_SRC}/3rdparty/scintilla/include
    ${QRD_SRC}/3rdparty/scintilla/include/qt
    ${QRD_SRC}/3rdparty/scintilla/qt/ScintillaEdit
    ${QRD_SRC}/3rdparty/scintilla/qt/ScintillaEditBase
    ${QRD_SRC}/3rdparty/scintilla/src
    ${QRD_SRC}/3rdparty/scintilla/lexlib
    ${CMAKE_SOURCE_DIR}/renderdoc/api
    ${CMAKE_SOURCE_DIR}/renderdoc/api/replay
    ${CMAKE_CURRENT_BINARY_DIR}
    ${Python3_INCLUDE_DIRS})

target_compile_definitions(qrenderdoc PRIVATE
    RENDERDOC_PLATFORM_WIN32
    RENDERDOC_SUPPORT_VULKAN
    QT_NO_CAST_FROM_ASCII
    QT_NO_CAST_TO_ASCII
    QT_NO_DEPRECATED_WARNINGS
    SCINTILLA_QT=1
    MAKING_LIBRARY=1
    SCI_LEXER=1
    PYSIDE2_ENABLED=0)
# Note on SWIG word-size:
#   We pass -DSWIGWORDSIZE32 to SWIG (in the swig command above) because
#   Windows LLP64 has `long == 32 bit`, which is what SWIGWORDSIZE32 actually
#   models. The generated code's self-check `(__WORDSIZE == 64) || (LONG_MAX != INT_MAX)`
#   then evaluates false on Windows since __WORDSIZE isn't defined here and
#   LONG_MAX == INT_MAX. Don't define __WORDSIZE - that breaks the check.
# Note: RENDERDOC_QT_COMPAT is intentionally NOT defined globally - it gates
# rdcstr->QString conversion operators that need Qt headers to already be in
# scope. The original qmake build defined it via QRDInterface.h which is
# always included after Qt headers; replicating that scoping is fragile, so
# we leave it to QRDInterface.h to enable per-translation-unit.

# Don't apply the renderdoc-internal /FI core/precompiled.h — qrenderdoc isn't
# in that translation unit world.

target_link_libraries(qrenderdoc PRIVATE
    renderdoc
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Svg
    Qt6::Network
    Qt6::Core5Compat
    Python3::Python
    user32
    shell32
    advapi32
    version)

# Note on the Python debug library:
#   pyconfig.h on Windows emits `#pragma comment(lib, "python3xx_d.lib")` when
#   _DEBUG is defined (i.e. /MDd builds). Stock python.org distributions ship
#   only python3xx.lib, no _d variant. Two workable approaches:
#     1. Side-by-side a copy of python3xx.lib named python3xx_d.lib so the
#        auto-link finds *something* (the .lib content is identical for the
#        purposes of linking against python3xx.dll).
#     2. Force the qrenderdoc target onto the release CRT (/MD) so _DEBUG is
#        never set when Python.h is processed.
#
# We previously did (2) but that mixed the release CRT in qrenderdoc.exe with
# debug-CRT Qt6Cored.dll. When Qt-allocated objects (e.g. Scintilla widgets
# parented through Qt, or QString internals) flow into qrenderdoc.exe destructors
# they hit a different heap on free() - the debug CRT's heap-validation pops a
# MessageBox, which during shutdown re-enters the Qt event loop into a slot on
# a partially-destroyed BufferViewer, which Qt 6's assertObjectType<> turns into
# a fatal log, which RenderDoc's logger turns into ForceCrash().
#
# Approach (1) is more robust. We assume the user has either copied
# python3xx.lib -> python3xx_d.lib themselves, or runs CMake with a Python
# distribution that includes _d.lib. The qrenderdoc target uses the same CRT
# as its dependencies (debug Qt -> /MDd) and Python.h's auto-link finds the
# _d variant.

# Output goes to the same per-config bin/ directory as renderdoc.dll so the
# UI and the capture DLL sit next to each other and the loader picks up
# renderdoc.dll automatically.
set_target_properties(qrenderdoc PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY         ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    RUNTIME_OUTPUT_DIRECTORY_DEBUG   ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Release)

# Deploy Qt runtime DLLs alongside the executable so qrenderdoc.exe runs out
# of the build directory without needing Qt6_BIN on PATH.
get_target_property(_qmake_executable Qt6::qmake IMPORTED_LOCATION)
get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${_qt_bin_dir}")

if(WINDEPLOYQT_EXECUTABLE)
    add_custom_command(TARGET qrenderdoc POST_BUILD
        COMMAND "${WINDEPLOYQT_EXECUTABLE}"
                --no-translations
                --no-system-d3d-compiler
                --no-opengl-sw
                "$<TARGET_FILE:qrenderdoc>"
        COMMENT "Running windeployqt for qrenderdoc"
        VERBATIM)
else()
    message(WARNING "qrenderdoc: windeployqt not found — Qt DLLs won't be staged. "
                    "qrenderdoc.exe won't run without Qt6 bin on PATH.")
endif()
