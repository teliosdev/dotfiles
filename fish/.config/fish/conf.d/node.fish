if command -v fnm >/dev/null
    fnm env --use-on-cd | source
else
    set -x NVM_DIR "$HOME/.nvm"
    if test -s $NVM_DIR/nvm.sh
        source $NVM_DIR/nvm.sh
    end
end

set -x PNPM_HOME "$HOME/.local/share/pnpm"
if test -d $PNPM_HOME
    if not contains $PNPM_HOME $PATH
        set -x PATH $PNPM_HOME $PATH
    end
end

set -x BUN_INSTALL "$HOME/.bun"
if test -d $BUN_INSTALL
    if not contains $BUN_INSTALL/bin $PATH
        set -x PATH "$BUN_INSTALL/bin" $PATH
    end
end

set -x DENO_INSTALL "$HOME/.deno"
if test -d $DENO_INSTALL
    if not contains $DENO_INSTALL/bin $PATH
        set -x PATH $DENO_INSTALL/bin $PATH
    end
end
