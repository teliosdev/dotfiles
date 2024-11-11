if status is-interactive
    if command -v eza >/dev/null
        alias ls=eza
    end
    if command -v bat >/dev/null
        alias cat=bat
    end

    function tmux-here
        set AT $argv[1]
        if test -z $AT
            set AT (pwd)
        end
        cd $AT; and tmux new -A -s (basename $AT)
    end

    set -x PATH "$HOME/.local/bin" $PATH
end

if command -v keychain >/dev/null
    SHELL=fish keychain --eval --noinherit -q | source
end
