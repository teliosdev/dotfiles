function tmux-here
        set AT $argv[1]
        if test -z $AT
            set AT (pwd)
        end
        cd $AT; and tmux new -A -s (basename $AT)
    
end
