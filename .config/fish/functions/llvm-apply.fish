function llvm-apply -d "Apply an LLVM patch"
  curl -L "https://github.com/llvm/llvm-project/pull/$argv.patch" | git apply -v
end
