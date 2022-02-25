#!/usr/bin/env python3

import argparse
import os
import six
import subprocess

# Assumes that the build directory lives next to llvm-project.
ROOT = os.path.dirname(os.getcwd())
INSTALL_DIR = os.path.join(ROOT, 'install')
LLVM_PROJECT_DIR = os.path.join(ROOT, 'llvm-project')
CMARK_DIR = os.path.join(ROOT, 'cmark')
SWIFT_DIR = os.path.join(ROOT, 'swift')


def parallel_link_jobs():
    try:
        import multiprocessing
        cpus = multiprocessing.cpu_count()
        return max(cpus / 4, 2)
    except:
        return 2


parser = argparse.ArgumentParser(
    description=
    "CMake configuration options are relatively verbose and remembering the "
    "ones you don't use that often can be a real pain. This scripts attempts "
    "to reduce some of the most commonly used options to a few easy to "
    "remember mnemonic arguments.")

parser.add_argument('-s',
                    '--shared',
                    action='store_true',
                    help="Build shared libraries")

parser.add_argument('--clang-light',
                    action='store_true',
                    help="No ARC, Static Anaylzer or plugins")

parser.add_argument('--swift',
                    action='store_true',
                    help="Include Swift and cmark as external projects")

parser.add_argument('-r',
                    '--ra',
                    action='store_true',
                    help="Release build with debug info and asserts")

parser.add_argument('-d', '--debug', action='store_true', help="Debug build")

parser.add_argument('-m',
                    '--modules',
                    action='store_true',
                    help="Enable modules")

parser.add_argument('-x',
                    '--x86',
                    action='store_true',
                    help="Only build x86 target")

parser.add_argument('--lto',
                    nargs='?',
                    const='',
                    default=None,
                    help="Enable LTO")

parser.add_argument('--sanitizers', nargs='*', help="Sanitizers to enable")

parser.add_argument('--system-debugserver',
                    action='store_true',
                    help="Use system debug server")

parser.add_argument('--docs',
                    action='store_true',
                    help="Build the documentation")

parser.add_argument('--expensive',
                    action='store_true',
                    help="Enable expensive checks")

parser.add_argument('--launcher', help="Specify launcher", type=str)

parser.add_argument('--extra', help="Specify extra C/CXX flags", type=str)

parser.add_argument('--projects',
                    nargs='*',
                    help="Project to enable when using the monorepo")

parser.add_argument('--runtimes',
                    nargs='*',
                    help="Runtimes to enable when using the monorepo")

args = parser.parse_args()

cmake_cmd = [
    "cmake {}".format(os.path.join(LLVM_PROJECT_DIR, 'llvm')), "-G Ninja",
    "-DCMAKE_INSTALL_PREFIX='{}'".format(INSTALL_DIR)
]

cmake_cmd.append("-DLLVM_PARALLEL_LINK_JOBS:INT={}".format(
    parallel_link_jobs()))

if args.shared:
    cmake_cmd.append("-DBUILD_SHARED_LIBS:BOOL=ON")

if args.clang_light:
    cmake_cmd.append("-DCLANG_ENABLE_ARCMT:BOOL=OFF")
    cmake_cmd.append("-DCLANG_ENABLE_STATIC_ANALYZER:BOOL=OFF")
    cmake_cmd.append("-DCLANG_PLUGIN_SUPPORT:BOOL=OFF")

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

if args.x86:
    cmake_cmd.append("-DLLVM_TARGETS_TO_BUILD='X86'")

if args.sanitizers:
    sanitizers = ';'.join(args.sanitizers)
    cmake_cmd.append("-DLLVM_USE_SANITIZER='{}'".format(sanitizers))

if args.system_debugserver:
    cmake_cmd.append("-DLLDB_USE_SYSTEM_DEBUGSERVER:BOOL=ON")

if 'lldb' in args.projects:
    cmake_cmd.append("-DLLDB_ENABLE_PYTHON=ON")

if args.docs:
    cmake_cmd.append("-DLLVM_ENABLE_SPHINX:BOOL=ON")

if args.expensive:
    cmake_cmd.append("-DLLVM_ENABLE_EXPENSIVE_CHECKS:BOOL=ON")
    cmake_cmd.append("-DLLVM_ENABLE_REVERSE_ITERATION:BOOL=ON")

if args.launcher:
    cmake_cmd.append("-DCMAKE_C_COMPILER_LAUNCHER='{}'".format(args.launcher))
    cmake_cmd.append("-DCMAKE_CXX_COMPILER_LAUNCHER='{}'".format(
        args.launcher))

if args.extra:
    cmake_cmd.append("-DCMAKE_C_FLAGS='{}'".format(args.extra))
    cmake_cmd.append("-DCMAKE_CXX_FLAGS='{}'".format(args.extra))

if args.projects:
    projects = ';'.join(args.projects)
    cmake_cmd.append("-DLLVM_ENABLE_PROJECTS='{}'".format(projects))

if args.runtimes:
    runtimes = ';'.join(args.runtimes)
    cmake_cmd.append("-DLLVM_ENABLE_RUNTIMES='{}'".format(runtimes))

if args.swift:
    cmake_cmd.append("-DLLVM_EXTERNAL_SWIFT_SOURCE_DIR='{}'".format(SWIFT_DIR))
    cmake_cmd.append("-DLLVM_EXTERNAL_CMARK_SOURCE_DIR='{}'".format(CMARK_DIR))
    cmake_cmd.append("-DLLVM_EXTERNAL_PROJECTS='cmark;swift'")

try:
    print(' \\\n    '.join(cmake_cmd))
    six.moves.input("Press Enter to run CMake or ^C to abort...")
except KeyboardInterrupt:
    exit(1)

subprocess.call(' '.join(cmake_cmd), shell=True)
subprocess.call('ninja', shell=True)
