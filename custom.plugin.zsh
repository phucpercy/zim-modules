#
# My custom configuration and aliases
#

############################
# Configuration
#

export EDITOR='nvim'
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
setopt no_share_history

# bindkey -v # use like vim editor
bindkey "\e." insert-last-word

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^i^e' edit-command-line

zle-line-init () {
  zle -K viins
  #echo -ne "\033]12;Grey\007"
  #echo -n 'grayline1'
  echo -ne "\033]12;Gray\007"
  echo -ne "\033[5 q"
  #print 'did init' >/dev/pts/16
}
zle -N zle-line-init
zle-keymap-select () {
  if [[ $KEYMAP == vicmd ]]; then
    if [[ -z $TMUX ]]; then
      printf "\033]12;Green\007"
      printf "\033[2 q"
    else
      printf "\033Ptmux;\033\033]12;red\007\033\\"
      printf "\033Ptmux;\033\033[2 q\033\\"
    fi
  else
    if [[ -z $TMUX ]]; then
      printf "\033]12;Grey\007"
      printf "\033[5 q"
    else
      printf "\033Ptmux;\033\033]12;grey\007\033\\"
      printf "\033Ptmux;\033\033[5 q\033\\"
    fi
  fi
  #print 'did select' >/dev/pts/16
}
zle -N zle-keymap-select

export VISUAL='nvim'
export FZF_COMPLETION_OPTS='+c -x'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--layout=reverse --inline-info"
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)


############################
# Aliases
#

alias c='cat'
alias tx='tmux'
alias tcpu='top -o cpu'
alias tmem='top -o mem'
alias nv='nvim'
alias cat='bat'
alias pwdx="pwd | xclip -sel clip"
alias jqc='jq -C'

GITHUB_HOME="$HOME/github"

jprofiler() {
    echo $1
    id=`jps | awk -v name=$1 '{ if ($2 == name) { print $1; } }' - `
    echo "Profiling pid = $id"
    shift
    ${GITHUB_HOME}/async-profiler/profiler.sh $@ $id 
}

#
# Git
#
alias gfmb='git pull origin "$(git-branch-current 2> /dev/null)"'
alias gloa='glo --all'
alias gcom='git co master'
alias gcod='git co develop'
alias gcoad='git co anh/develop'
alias gcost='git co staging'
alias grbd='git rb develop'
alias grbm='git rb master'

#
# Maven
#
alias mpackTest='mvn package'
alias mpack='mvn package -DskipTests=True'
alias mrepackTest='mvn clean package'
alias mrepack='mvn clean package -DskipTests=True'

#
# Gradle
#
alias grl='gradle'
alias grlb='gradle build'
alias grlcb='gradle clean build'
alias grlt='gradle test'
alias grlct='gradle clean test'

#
# curl
#
mcurl() {
    curl $@ 2>/dev/null
}
alias cput='mcurl -X PUT'
alias cdel='mcurl -X DELETE'
export HJSON='Content-Type: application/json'
alias rget='mcurl -X GET -H $HJSON'
alias rpost='mcurl -X POST -H $HJSON'
alias rput='mcurl -X PUT -H $HJSON'

# python
alias py3='python3'
alias ipython='ipython --TerminalInteractiveShell.editing_mode=vi'
alias ipy='ipython'
alias vpy='source .venv/bin/activate'

#
# kafka tools
#

KAFKA_BIN_DIR=${GITHUB_HOME}'/kafka/bin'
alias kk-consumer-grp="$KAFKA_BIN_DIR/kafka-consumer-groups.sh"
alias kk-cmd-consumer="$KAFKA_BIN_DIR/kafka-console-consumer.sh"
alias kk-cmd-producer="$KAFKA_BIN_DIR/kafka-console-producer.sh"
alias kk-tpc="$KAFKA_BIN_DIR/kafka-topics.sh"

#
# docker
#

alias dk='docker'
alias dkimg='docker image'
alias dkct='docker container'
alias dkb='docker build'
alias dkr='docker run'
alias dkex='docker exec'
alias dks='docker start'
alias dks='docker stop'

dk_ps() {
  docker ps | awk '{ if (NR != 1) print $0, "\t",  NR-1; else print $0; } '
}


get_docker_id() {
  docker ps -q | awk -v n=$1 'NR == n {print $0}'
}

dksId() {
  docker stop `get_docker_id $1`
}

dkssh() {
  docker exec -it `get_docker_id $1` /bin/bash
}

cd () {
    if [[ -n $VIRTUAL_ENV ]]; then
        deactivate
    fi
    builtin cd "$@"
    if [[ -d .venv ]]; then
        source .venv/bin/activate
    fi
}

# alias cclip='xclip -sel clip'
# alias vclip='xclip -o -sel clip'

alias cclip='wl-copy'
alias vclip='wl-paste'

alias gds='forgit::diff --staged'
export FORGIT_COPY_CMD='xclip -selection clipboard'
export FORGIT_ADD_FZF_OPTS="--preview-window=bottom:90%"

function fmn() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

function grtb() {
  # Default to 'develop' if no argument is provided
  local target_branch="${1:-develop}"
  git reset $(git merge-base "$target_branch" $(git branch --show-current))
}

function gc-ticket() {
    # 1. Get the current branch name
    local branch_name=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    # 2. Extract the SPDT-XXXXX pattern
    local ticket=$(echo "$branch_name" | grep -oE 'SPDT-[0-9]+')
    
    # 3. Strict Check: If no ticket is found, BLOCK the commit
    if [ -z "$ticket" ]; then
        echo "❌ ERROR: No 'SPDT-XXXXX' ticket found in branch name '$branch_name'."
        echo "   Commit aborted! Please switch to a ticket branch or rename this branch."
        return 1  # Exits the function with a failure code without committing
    else
        # 4. Proceed with commit if ticket exists
        echo "🚀 Committing with ticket: $ticket"
        git commit -m "$ticket $*"
    fi
}
alias gcmt='gc-ticket'
