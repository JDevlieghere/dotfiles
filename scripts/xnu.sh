#!/usr/bin/env bash

# From https://0xcc.re/building-xnu-kernel-macosx-sierrra-10-12-x/

DTRACE="dtrace-209.50.12"
AVAILABILITYVERSIONS="AvailabilityVersions-26.50.4"
LIBDISPATCH="libdispatch-703.50.37"
LIBPLATFORM="libplatform-126.50.8"
XNU="xnu-3789.51.2"

ROOT=$(pwd)
SDKPATH=$(xcrun -sdk macosx -show-sdk-path)

# Download sources
[[ -d $DTRACE ]] || curl -O "https://opensource.apple.com/tarballs/dtrace/$DTRACE.tar.gz" || exit 1
[[ -d $AVAILABILITYVERSIONS ]] || curl -O "https://opensource.apple.com/tarballs/AvailabilityVersions/$AVAILABILITYVERSIONS.tar.gz" || exit 1
[[ -d $LIBDISPATCH ]] || curl -O "https://opensource.apple.com/tarballs/libdispatch/$LIBDISPATCH.tar.gz" || exit 1
[[ -d $LIBPLATFORM ]] || curl -O "https://opensource.apple.com/tarballs/libplatform/$LIBPLATFORM.tar.gz" || exit 1
[[ -d $XNU ]] || curl -O "https://opensource.apple.com/tarballs/xnu/$XNU.tar.gz" || exit 1

# Extract
for file in *.tar.gz; do tar -zxf $file; done && rm -f *.tar.gz

# Dtrace
cd $ROOT/$DTRACE
mkdir -p obj sym dst
xcodebuild install -target ctfconvert -target ctfdump -target ctfmerge ARCHS="x86_64" SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=$PWD/dst
sudo ditto $PWD/dst/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain

# AvailabilityVersions
cd $ROOT/$AVAILABILITYVERSIONS
mkdir -p dst
make install SRCROOT=$PWD DSTROOT=$PWD/dst
sudo ditto $PWD/dst/usr/local $SDKPATH/usr/local

# XNU Headers
cd $ROOT/$XNU
mkdir -p BUILD.hdrs/obj BUILD.hdrs/sym BUILD.hdrs/dst
make installhdrs SDKROOT=macosx ARCH_CONFIGS=X86_64 SRCROOT=$PWD OBJROOT=$PWD/BUILD.hdrs/obj SYMROOT=$PWD/BUILD.hdrs/sym DSTROOT=$PWD/BUILD.hdrs/dst
sudo xcodebuild installhdrs -project libsyscall/Libsyscall.xcodeproj -sdk macosx ARCHS='x86_64 i386' SRCROOT=$PWD/libsyscall OBJROOT=$PWD/BUILD.hdrs/obj SYMROOT=$PWD/BUILD.hdrs/sym DSTROOT=$PWD/BUILD.hdrs/dst
sudo ditto BUILD.hdrs/dst $SDKPATH

# Libplatform
cd $ROOT/$LIBPLATFORM
sudo ditto $PWD/include $SDKPATH/usr/local/include

# Libdispatch
cd $ROOT/$LIBDISPATCH
mkdir -p BUILD.hdrs/obj BUILD.hdrs/sym BUILD.hdrs/dst
sudo xcodebuild install -project libdispatch.xcodeproj -target libfirehose_kernel -sdk macosx ARCHS='x86_64 i386' SRCROOT=$PWD OBJROOT=$PWD/obj SYMROOT=$PWD/sym DSTROOT=$PWD/dst
sudo ditto $PWD/dst/usr/local $SDKPATH/usr/local

# XNU
cd $ROOT/$XNUPATH
make SDKROOT=macosx ARCH_CONFIGS=X86_64 KERNEL_CONFIGS="RELEASE DEVELOPMENT DEBUG"

# Install
# sudo cp BUILD/obj/RELEASE_X86_64/kernel /System/Library/Kernels/
# sudo kextcache -invalidate /
