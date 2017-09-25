# Personal presets for quickly configuring LLVM with CMake.
function cmake-llvm -d "Configure CMake for LLVM"
    switch $argv[1]
    case x86rel
        cmake "$argv[2]" \
            -G Ninja \
            -DLLVM_TARGETS_TO_BUILD="X86" \
            -DCMAKE_INSTALL_PREFIX="../install" \
            -DCMAKE_BUILD_TYPE="RelWithDebInfo" \
            -DBUILD_SHARED_LIBS=On \
            -DLLVM_ENABLE_ASSERTIONS=On
    case x86deb
        cmake $argv[2] \
            -G Ninja \
            -DLLVM_TARGETS_TO_BUILD="X86" \
            -DCMAKE_INSTALL_PREFIX="../install" \
            -DCMAKE_BUILD_TYPE="Debug" \
            -DBUILD_SHARED_LIBS=On
    case rel
        cmake $argv[2] \
            -G Ninja \
            -DCMAKE_INSTALL_PREFIX="../install" \
            -DCMAKE_BUILD_TYPE="RelWithDebInfo" \
            -DBUILD_SHARED_LIBS=On \
            -DLLVM_ENABLE_ASSERTIONS=On
    case deb
        cmake $argv[2] \
            -G Ninja \
            -DCMAKE_INSTALL_PREFIX="../install" \
            -DCMAKE_BUILD_TYPE="Debug" \
            -DBUILD_SHARED_LIBS=On
    case '*'
        echo "Unknown preset!"
    end
    ninja
end
