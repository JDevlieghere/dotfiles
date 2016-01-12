set print pretty on
set print object on

set history save on
set history filename ~/.gdb_history

set height 0
set width 0

define argv
 show args
end

define frame
 info frame
 info args
 info locals
end

define func
 info functions
end

define var
 info variables
end

define lib
 info sharedlibrary
end

define sig
 info signals
end

define thread
 info threads
end
