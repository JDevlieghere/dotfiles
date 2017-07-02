function dump-ast --description "dump clang ast"
  clang -Xclang -ast-dump -fsyntax-only $argv
end
