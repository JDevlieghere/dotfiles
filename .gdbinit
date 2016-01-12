set print pretty on
set print object on
set history save on
set history filename ~/.gdb_history

define frame
 info frame
 info args
 info locals
end
