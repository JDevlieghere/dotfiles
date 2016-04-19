# LLVM Configuration
BRANCH="release_38"
PREFIX="/opt/llvm"
TYPE="Release"

# Create directories
mkdir ~/clang-llvm; cd ~/clang-llvm

# Clone the source tree
git clone http://llvm.org/git/llvm.git
git checkout "$BRANCH"

cd llvm/tools
git clone http://llvm.org/git/clang.git
git checkout "$BRANCH"

cd clang/tools
git clone http://llvm.org/git/clang-tools-extra.git extra
git checkout "$BRANCH"

# Build
cd ~/clang-llvm
mkdir build; cd build
cmake -G Ninja ../llvm -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="$TYPE"
ninja

# Install
ninja install
