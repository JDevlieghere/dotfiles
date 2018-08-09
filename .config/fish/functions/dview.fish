function dview -d "View dot file as PDF"
    set -lx output "$argv[1].pdf"
    dot $argv[1] -T pdf -o $output
    open $output
end
