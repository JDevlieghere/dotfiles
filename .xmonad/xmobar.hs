-- xmobar config used by Vic Fryzel
-- Author: Vic Fryzel
-- http://github.com/vicfryzel/xmonad-config

-- Altered by Jonas Devlieghere
-- https://github.com/JDevlieghere/dotfiles

Config {
    font = "xft:Fixed-8",
    bgColor = "#002b36",
    fgColor = "#839496",
    position = Static { xpos = 1920, ypos = 0, width = 1920, height = 25 },
    lowerOnStart = True,
    commands = [
        Run Weather "EBBR" ["-t","<tempC>°C <skyCondition>","-L","64","-H","77","-n","#859900","-h","#dc322f","-l","#268bd2"] 36000,
        Run Com "volume" [] "volume" 10,
        Run MultiCpu ["-t","Cpu: <total0> <total1> <total2> <total3>","-L","30","-H","60","-h","#dc322f","-l","#859900","-n","#b58900","-w","3"] 10,
        Run Memory ["-t","Mem: <usedratio>%","-H","8192","-L","4096","-h","#dc322f","-l","#859900","-n","#b58900"] 10,
        Run Swap ["-t","Swap: <usedratio>%","-H","1024","-L","512","-h","#dc322f","-l","#859900","-n","#b58900"] 10,
        Run Network "eth0" ["-t","Net: <rx>, <tx>","-H","200","-L","10","-h","#dc322f","-l","#859900","-n","#b58900"] 10,
        Run Date "%a %b %_d %H:%M" "date" 10,
        Run StdinReader
    ],
    sepChar = "%",
    alignSep = "}{",
    template = " %StdinReader% }{ %multicpu%   %memory%   %swap%   %eth0%   %volume%   %date%   %EBBR% "
}
