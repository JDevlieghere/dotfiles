# Convenience function to build all outdated CMake projects over night.
function cmake-build-all -d "Build all CMake projects in batch"
  set -lx cwd (pwd)
  for i in (find . -type f -name "CMakeCache.txt")
    cd (dirname "$i")
    printf 'Building %s' (pwd)
    time cmake --build .
    cd "$cwd"
  end
end
