# LLVM Configuration
BRANCH="$1"
PREFIX="/opt/llvm"
TYPE="Release"

# Create directories
mkdir ~/clang-llvm; cd ~/clang-llvm

# Clone the source tree
git clone http://llvm.org/git/llvm.git
cd llvm
git checkout "$BRANCH"

cd tools
git clone http://llvm.org/git/clang.git
cd clang
git checkout "$BRANCH"

cd tools
git clone http://llvm.org/git/clang-tools-extra.git extra
cd extra
git checkout "$BRANCH"

# Build
cd ~/clang-llvm
mkdir build; cd build
cmake -G Ninja ../llvm -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="$TYPE"
ninja

# Install
ninja install
