function objc-dump -d "class dump for objective-c"
    class-dump $argv  | highlight -S objc -O ansi | less
end
