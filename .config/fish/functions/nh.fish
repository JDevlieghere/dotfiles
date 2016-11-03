function nh -d "run without hangup signal"
    nohup $argv > /dev/null 2>&1 &
end
