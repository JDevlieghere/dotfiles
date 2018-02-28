function mkscript -d "Create new script"
  echo '#!/usr/bin/env bash' > $argv
  chmod +x $argv
end
