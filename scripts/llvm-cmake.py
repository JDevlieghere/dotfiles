#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import platform

# Assumes that the build directory lives next to llvm-project.
ROOT = os.path.dirname(os.getcwd())
INSTALL_DIR = os.path.join(ROOT, "install")
LLVM_PROJECT_DIR = os.path.join(ROOT, "llvm-project")
LLVM_SOURCE_DIR = os.path.join(LLVM_PROJECT_DIR, "llvm")
CMARK_DIR = os.path.join(ROOT, "cmark")
SWIFT_DIR = os.path.join(ROOT, "swift")
PYTHON_PREFIX = sys.prefix


def get_sdk_path(sdk):
    return (
        subprocess.check_output(["xcrun", "--show-sdk-path", "--sdk", sdk])
        .decode()
        .strip()
    )


def get_cmake():
    return subprocess.check_output(["which", "cmake"]).decode().strip()


def get_clang_cache():
    try:
        clang = subprocess.check_output(["xcrun", "-f", "clang"]).decode().strip()
        clang_cache = (
            subprocess.check_output(["xcrun", "-f", "clang-cache"]).decode().strip()
        )
        return clang, clang_cache
    except subprocess.CalledProcessError:
        return None, None


def get_clang():
    if platform.system() == "Darwin":
        cmd = ["xcrun", "-f", "clang"]
    else:
        cmd = ["which", "clang"]
    try:
        return subprocess.check_output(cmd).decode().strip()
    except subprocess.CalledProcessError:
        return None


parser = argparse.ArgumentParser(
    description="CMake configuration options are relatively verbose and remembering the "
    "ones you don't use that often can be a real pain. This scripts attempts "
    "to reduce some of the most commonly used options to a few easy to "
    "remember mnemonic arguments."
)

parser.add_argument(
    "-s", "--shared", action="store_true", help="Build shared libraries"
)

parser.add_argument(
    "--swift", action="store_true", help="Include Swift and cmark as external projects"
)

parser.add_argument(
    "--no-swift",
    action="store_true",
    help="Disable Swift support in the downstream fork of LLDB",
)

parser.add_argument(
    "-r", "--ra", action="store_true", help="Release build with debug info and asserts"
)

parser.add_argument("-d", "--debug", action="store_true", help="Debug build")

parser.add_argument("-m", "--modules", action="store_true", help="Enable modules")

parser.add_argument("--host", action="store_true", help="Only build host architecutre")

parser.add_argument("--lto", nargs="?", const="", default=None, help="Enable LTO")

parser.add_argument("--sanitizers", nargs="*", help="Sanitizers to enable")

parser.add_argument(
    "--system-debugserver", action="store_true", help="Use system debug server"
)

parser.add_argument("--docs", action="store_true", help="Build the documentation")

parser.add_argument("--expensive", action="store_true", help="Enable expensive checks")

parser.add_argument("--fuzz", action="store_true", help="Enable fuzzers")

parser.add_argument("--sdk", help="Specify an Xcode SDK", type=str)

parser.add_argument(
    "--projects", nargs="*", help="Project to enable when using the monorepo"
)

parser.add_argument(
    "--runtimes", nargs="*", help="Runtimes to enable when using the monorepo"
)

args, extra_args = parser.parse_known_args()

xcrun_invocation = "xcrun -sdk {} ".format(args.sdk) if args.sdk else ""
cmake = get_cmake()

cmake_cmd = [
    "{}{} {}".format(xcrun_invocation, cmake, LLVM_SOURCE_DIR),
    "-G Ninja",
    "-DCMAKE_INSTALL_PREFIX='{}'".format(INSTALL_DIR),
]

if args.sdk:
    cmake_cmd.append("-DCMAKE_OSX_SYSROOT:PATH={}".format(get_sdk_path(args.sdk)))

if args.shared:
    cmake_cmd.append("-DBUILD_SHARED_LIBS:BOOL=ON")

if args.ra:
    cmake_cmd.append("-DCMAKE_BUILD_TYPE='RelWithDebInfo'")
    cmake_cmd.append("-DLLVM_ENABLE_ASSERTIONS:BOOL=ON")

if args.debug:
    cmake_cmd.append("-DCMAKE_BUILD_TYPE='Debug'")
    cmake_cmd.append("-DLLVM_OPTIMIZED_TABLEGEN:BOOL=ON")

if args.lto is not None:
    lto = args.lto if args.lto else "ON"
    cmake_cmd.append("-DLLVM_ENABLE_LTO={}".format(lto))

if args.modules:
    cmake_cmd.append("-DLLVM_ENABLE_MODULES:BOOL=ON")

if args.host:
    machine = platform.machine()
    if machine == "arm64":
        cmake_cmd.append("-DLLVM_TARGETS_TO_BUILD='AArch64'")
    elif machine == "x86_64":
        cmake_cmd.append("-DLLVM_TARGETS_TO_BUILD='X86'")

if args.sanitizers:
    sanitizers = ";".join(args.sanitizers)
    cmake_cmd.append("-DLLVM_USE_SANITIZER='{}'".format(sanitizers))

if args.system_debugserver:
    cmake_cmd.append("-DLLDB_USE_SYSTEM_DEBUGSERVER:BOOL=ON")

if args.projects and "lldb" in args.projects:
    cmake_cmd.append("-DLLDB_ENABLE_PYTHON=ON")
    if platform.system() == "Darwin":
        cmake_cmd.append(
            "-DPython3_EXECUTABLE={}".format(
                os.path.join(PYTHON_PREFIX, "bin", "python3")
            )
        )
        cmake_cmd.append(
            "-DPython3_INCLUDE_DIR={}".format(os.path.join(PYTHON_PREFIX, "Headers"))
        )

if args.docs:
    cmake_cmd.append("-DLLVM_ENABLE_SPHINX:BOOL=ON")

if args.expensive:
    cmake_cmd.append("-DLLVM_ENABLE_EXPENSIVE_CHECKS:BOOL=ON")
    cmake_cmd.append("-DLLVM_ENABLE_REVERSE_ITERATION:BOOL=ON")

if args.projects:
    projects = ";".join(args.projects)
    cmake_cmd.append("-DLLVM_ENABLE_PROJECTS='{}'".format(projects))

if args.runtimes:
    runtimes = ";".join(args.runtimes)
    cmake_cmd.append("-DLLVM_ENABLE_RUNTIMES='{}'".format(runtimes))

if args.fuzz:
    cmake_cmd.append("-DLLVM_USE_SANITIZER='Address'")
    cmake_cmd.append("-DLLVM_USE_SANITIZE_COVERAGE:BOOL=ON")
    cmake_cmd.append("-DLLVM_BUILD_RUNTIME:BOOL=OFF")

if args.swift:
    cmake_cmd.append("-DLLVM_EXTERNAL_SWIFT_SOURCE_DIR='{}'".format(SWIFT_DIR))
    cmake_cmd.append("-DLLVM_EXTERNAL_CMARK_SOURCE_DIR='{}'".format(CMARK_DIR))
    cmake_cmd.append("-DLLVM_EXTERNAL_PROJECTS='cmark;swift'")

if args.no_swift:
    cmake_cmd.append("-DLLDB_ENABLE_SWIFT_SUPPORT=OFF")

if os.environ.get("LLVM_CACHE_CAS_PATH") is not None:
    clang, clang_cache = get_clang_cache()
    if clang and clang_cache:
        cmake_cmd.append("-DCMAKE_C_COMPILER='{}'".format(clang))
        cmake_cmd.append("-DCMAKE_C_COMPILER_LAUNCHER='{}'".format(clang_cache))
        cmake_cmd.append("-DCMAKE_CXX_COMPILER='{}++'".format(clang))
        cmake_cmd.append("-DCMAKE_CXX_COMPILER_LAUNCHER='{}'".format(clang_cache))

if "linux" in sys.platform:
    cmake_cmd.append("-DLLVM_USE_SPLIT_DWARF:BOOL=ON")

if extra_args:
    cmake_cmd.extend(extra_args)

try:
    print(" \\\n    ".join(cmake_cmd))
    input("Press Enter to run CMake or ^C to abort...")

    subprocess.call(" ".join(cmake_cmd), shell=True)
    subprocess.call("ninja", shell=True)
except KeyboardInterrupt:
    try:
        sys.exit(130)
    except SystemExit:
        os._exit(130)
