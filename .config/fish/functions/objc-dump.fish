function objc-dump -d "Class dump for Objective-C"
    class-dump $argv  | highlight -S objc -O ansi | less
end
