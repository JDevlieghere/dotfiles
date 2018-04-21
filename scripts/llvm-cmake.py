#!/usr/bin/env python

import argparse
import subprocess


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

parser.add_argument("source", help="LLVM source path", type=str)

parser.add_argument(
    '-s', '--shared', action='store_true', help="Build shared libraries")
parser.add_argument(
    '-c',
    '--clang-light',
    action='store_true',
    help=
    "Build a light version of clang, which means no ARC, Static Anaylzer or plugins"
)
parser.add_argument(
    '-r',
    '--ra',
    action='store_true',
    help="Release build with debug info and asserts")
parser.add_argument('-d', '--debug', action='store_true', help="Debug build")
parser.add_argument(
    '-m', '--modules', action='store_true', help="Enable modules")
parser.add_argument(
    '-x', '--x86', action='store_true', help="Only build x86 target")

parser.add_argument('--sanitizers', nargs='*', help="Sanitizers to enable")
parser.add_argument(
    '--system-debugserver',
    action='store_true',
    help="Use system debug server")

parser.add_argument(
    '-p',
    '--projects',
    nargs='*',
    help="Project to enable when using the monorepo")

args = parser.parse_args()

cmake_cmd = [
    "cmake {}".format(args.source), "-G Ninja",
    "-DCMAKE_INSTALL_PREFIX='../install'"
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

if args.modules:
    cmake_cmd.append("-DLLVM_ENABLE_MODULES:BOOL=ON")

if args.x86:
    cmake_cmd.append("-DLLVM_TARGETS_TO_BUILD='X86'")

if args.sanitizers:
    sanitizers = ';'.join(args.sanitizers)
    cmake_cmd.append("-DLLVM_USE_SANITIZER='{}'".format(sanitizers))

if args.system_debugserver:
    cmake_cmd.append("-DLLDB_CODESIGN_IDENTITY=\"\"")

if args.projects:
    projects = ';'.join(args.projects)
    cmake_cmd.append("-DLLVM_ENABLE_PROJECTS='{}'".format(projects))

try:
    print(' \\\n    '.join(cmake_cmd))
    raw_input("Press Enter to run CMake or ^C to abort...")
except KeyboardInterrupt:
    exit(1)

subprocess.call(' '.join(cmake_cmd), shell=True)
subprocess.call('ninja', shell=True)
