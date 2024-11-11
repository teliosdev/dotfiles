set -x PYENV_ROOT "$HOME/.pyenv"
if test -d $PYENV_ROOT
    if not contains "$PYENV_ROOT/bin" $PATH
        set -x PATH "$PYENV_ROOT/bin" $PATH
    end

    pyenv init - | source
end
