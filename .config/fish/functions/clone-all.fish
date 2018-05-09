function clone-all -d "Clone multiple repositories in parallel"
  set -lx cpus (getconf _NPROCESSORS_ONLN)
  printf "%s\n" $argv | xargs -I"{}" -P"$cpus" git clone "{}"
end
