function nh -d "Run without hangup signal"
    nohup $argv > /dev/null 2>&1 &
end
