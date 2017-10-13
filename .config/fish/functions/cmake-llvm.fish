# Personal presets for quickly configuring LLVM with CMake.
function cmake-llvm -d "Configure CMake for LLVM"
    echo "cmake $argv[1] \\"
    echo "  -G Ninja \\"
    echo "  -DBUILD_SHARED_LIBS=On \\"
    echo "  -DCMAKE_BUILD_TYPE='RelWithDebInfo' \\"
    echo "  -DCMAKE_INSTALL_PREFIX='../install'\\"
    echo "  -DLLVM_ENABLE_ASSERTIONS=On \\"
    echo "  -DLLVM_ENABLE_MODULES=On \\"
    echo "  -DLLVM_TARGETS_TO_BUILD='X86' \\"
    echo "  -DLLVM_USE_SANITIZER='Address'"
end
