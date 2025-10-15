export PATH="$PATH:$HOME/.pub-cache/bin"
export JAVA_HOME=$(/usr/libexec/java_home -v 22.0.2)
export PATH=$JAVA_HOME/bin:$PATH
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$PATH:/Users/macbook/.dotnet/tools"
export PATH="$PATH:/Users/macbook/mongodb-macos-aarch64-8.0.3/bin"


# Load Angular CLI autocompletion.
source <(ng completion script)

# >>> Added by Spyder >>>
alias uninstall-spyder=/Users/macbook/Library/spyder-6/uninstall-spyder.sh
# <<< Added by Spyder <<<

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

