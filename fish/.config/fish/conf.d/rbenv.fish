if test -d "$HOME/.rbenv"
    set RBENV (command -v rbenv)
    if test -f "$RBENV"
        set RBENV "$HOME/.rbenv/bin/rbenv"
    end
    "$RBENV" init - fish | source
end
