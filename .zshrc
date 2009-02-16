#!/bin/zsh
#
# Best Goddamn zshrc in the whole world (if you're obsessed with Vim).
# Author: Seth House <seth@eseth.com>
# Version: $LastChangedRevision$
# Modified: $LastChangedDate$
# thanks to Adam Spiers, Steve Talley
# and to Unix Power Tools by O'Reilly
#
# {{{ setting options

setopt                          \
        auto_cd                 \
        chase_links             \
        noclobber               \
        complete_aliases        \
        extended_glob           \
        hist_ignore_all_dups    \
        hist_ignore_space       \
        ignore_eof              \
        share_history           \
        no_flow_control         \
        list_types              \
        mark_dirs               \
        path_dirs               \
        rm_star_wait

# }}}
# {{{ environment settings

umask 027

PATH=$HOME/bin:/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/local/sbin:/usr/X11/bin:/bin:/sbin:/usr/bin:/usr/sbin:$PATH
MANPATH=$HOME/man:/opt/local/share/man:/usr/local/man:/usr/local/share/man:/usr/X11/man:/usr/man:/usr/share/man:$MANPATH
CDPATH=$CDPATH::$HOME:/usr/local

export PYTHONSTARTUP=$(echo $HOME)/.pythonrc.py

HISTFILE=$HOME/.zsh_history
HISTFILESIZE=65536  # search this with `grep | sort -u`
HISTSIZE=4096
SAVEHIST=4096

REPORTTIME=60       # Report time statistics for progs that take more than a minute to run
WATCH=notme         # Report any login/logout of other users
WATCHFMT='%n %a %l from %m at %T.'

# utf-8 in the terminal, will break stuff if your term isn't utf aware
LANG=en_US.UTF-8 
LC_ALL=$LANG
LC_COLLATE=C

EDITOR=vi
VISUAL=vi
PAGER='less -imJMW'
MANPAGER='less -imJMW'
BROWSER='firefox'

# Silence Wine debugging output (why isn't this a default?)
WINEDEBUG=-all

# Set grep to ignore SCM directories
if ! $(grep --exclude-dir 2> /dev/null); then
    GREP_OPTIONS="--color --exclude-dir=.svn --exclude=\*.pyc --exclude-dir=.hg --exclude-dir=.bzr --exclude-dir=.git"
else
    GREP_OPTIONS="--color --exclude=\*.svn\* --exclude=\*.pyc --exclude=\*.hg\* --exclude=\*.bzr\* --exclude=\*.git\*"
fi
export GREP_OPTIONS

# }}}
# {{{ completions

autoload -U compinit
compinit -C
zstyle ':completion:*' list-colors "$LS_COLORS"
zstyle ':completion:*:*:*:users' ignored-patterns adm apache bin daemon ftp games gdm halt ident junkbust lp mail mailnull mysql named news nfsnobody nobody nscd ntp operator pcap pop postgres radvd rpc rpcuser rpm shutdown smmsp squid sshd sshfs sync uucp vcsa xfs
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle -e ':completion:*:(ssh|scp|sshfs|ping|telnet|ftp|rsync):*' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,$HOME/.ssh/static_,$HOME/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# }}}
# {{{ prompt and theme

autoload -U promptinit
promptinit

prompt adam2 bg_grey green magenta white

# }}}
# {{{ vi mode, mode display and extra vim-style keybindings
# TODO: why is there a half-second delay when pressing ? to enter search?
#       Update: found out has something to do with $KEYTIMEOUT and that
#       command-mode needs to use the same keys as insert-mode
# TODO: bug when searching through hist with n and N, when you pass the EOF the
#       term decrements the indent of $VIMODE on the right, which will collide
#       with the command you're typing

bindkey -v
bindkey "^?" backward-delete-char
bindkey -M vicmd "^R" redo
bindkey -M vicmd "u" undo
bindkey -M vicmd "ga" what-cursor-position
bindkey -M viins '^p' history-beginning-search-backward
bindkey -M vicmd '^p' history-beginning-search-backward
bindkey -M viins '^n' history-beginning-search-forward
bindkey -M vicmd '^n' history-beginning-search-forward

autoload edit-command-line
zle -N edit-command-line
bindkey -M vicmd "v" edit-command-line

showmode() { # may need adjustment with non adam2 themes
    RIGHT=$[COLUMNS-11]
    echo -n "7[$RIGHT;G" # one line down, right side
    echo -n "--$VIMODE--" # will be overwritten during long commands
    echo -n "8" # returns cursor to last position (normal prompt position)
}
makemodal () {
    eval "$1() { zle .'$1'; ${2:+VIMODE='$2'}; showmode }"
    zle -N "$1"
}
makemodal vi-add-eol           INSERT
makemodal vi-add-next          INSERT
makemodal vi-change            INSERT
makemodal vi-change-eol        INSERT
makemodal vi-change-whole-line INSERT
makemodal vi-insert            INSERT
makemodal vi-insert-bol        INSERT
makemodal vi-open-line-above   INSERT
makemodal vi-substitute        INSERT
makemodal vi-open-line-below   INSERT
makemodal vi-replace           REPLACE
makemodal vi-cmd-mode          NORMAL
unfunction makemodal

# }}}
# {{{ aliases

alias vi='vim'

alias ls='ls -F --color'
alias la='ls -A'
alias ll='ls -lh'

alias less='less -imJMW'
alias cls='clear' # note: ctrl-L under zsh does something similar
alias ssh='ssh -X -C'
alias locate='locate -i'
alias lynx='lynx -cfg=$HOME/.lynx.cfg -lss=$HOME/.lynx.lss'
alias ducks='du -cks * | sort -rn | head -15'
alias tree="ls -R | grep \":$\" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'"
alias ps='ps -opid,uid,cpu,time,stat,command'
alias du='du -sh'
alias df='df -h'
alias cal='cal -3 -m'

# OS X versions
if [[ $(uname) == "Darwin" ]]; then
    alias ls='ls -FG'
    unalias locate
    alias lynx='lynx -cfg=$HOME/.lynx.cfg'
    alias top='top -ocpu'
fi

# Integrate ssh-agent with GNU Screen:
######################################
#
# ssh-agent varies the location of the socket pointed to by SSH_AUTH_SOCK; to
# avoid having to update that variable in every terminal running in Screen
# every time we reattach we create a permanent pointer that is easier to update
SCREEN_AUTH_SOCK=$HOME/.screen/ssh-auth-sock
#
# For local Screen sessions, start ssh-agent and update SCREEN_AUTH_SOCK to
# point to the new ssh-agent socket. Bonus: when the screen session is detached
# the agent will be killed, securing your session. Simply run ssh-add every
# time you start a new screen session or reattach.
alias sc="exec ssh-agent sh -c 'ln -sfn \$SSH_AUTH_SOCK $SCREEN_AUTH_SOCK; SSH_AUTH_SOCK=$SCREEN_AUTH_SOCK exec screen -e\"^Aa\" -S main -DRR'"
#
# For remote Screen sessions (e.g. ssh-ed Screen inside local Screen), update
# SCREEN_AUTH_SOCK to point at the (hopefully) existing forwarded SSH_AUTH_SOCK
# that points to your locally running agent. (For more info see ForwardAgent in
# the ssh_config manpage.)
alias rsc="exec sh -c 'ln -sfn \$SSH_AUTH_SOCK $SCREEN_AUTH_SOCK; SSH_AUTH_SOCK=$SCREEN_AUTH_SOCK exec screen -e\"^Ss\" -S main -DRR'"

# }}}
# Miscellaneous Functions:
# {{{ calc()
# Command-line calculator (has some limitations...not sure the extent)(based on zsh functionality)

alias calc="noglob _calc"
function _calc() {
    echo $(($*))
}

# }}}
# {{{ genpass()
# Generates a tough password of a given length

function genpass() {
    if [ ! "$1" ]; then
        echo "Usage: $0 20"
        echo "For a random, 20-character password."
        return 1
    fi
    dd if=/dev/urandom count=1 2>/dev/null | tr -cd 'A-Za-z0-9!@#$%^&*()_+' | cut -c-$1
}

# }}}
# {{{ bookletize()
# Converts a PDF to a fold-able booklet sized PDF
# Print it double-sided and fold in the middle

bookletize ()
{
    if which pdfinfo && which pdflatex; then
        pagecount=$(pdfinfo $1 | awk '/^Pages/{print $2+3 - ($2+3)%4;}')

        # create single fold booklet form in the working directory
        pdflatex -interaction=batchmode \
        '\documentclass{book}\
        \usepackage{pdfpages}\
        \begin{document}\
        \includepdf[pages=-,signature='$pagecount',landscape]{'$1'}\
        \end{document}' 2>&1 >/dev/null
    fi
}

# }}}
# {{{ joinpdf()
# Merges, or joins multiple PDF files into "merged.pdf"

joinpdf () {
    gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=merged.pdf "$@"
}

# }}}
# Django functions djedit & djsetup {{{

alias djrunserver="django-admin.py runserver >&! /tmp/django.log &"

# For a monolithic project, just run the function from the project folder.
# For a reusable app, run the function from the folder containing the settings
# file, and pass the settings file as an argument.
djsetup()
{
    if [ x"$1" != x ]; then
        export PYTHONPATH=$PWD:$PYTHONPATH
        export DJANGO_SETTINGS_MODULE=$(basename $1 .py)
    else
        cd ..
        export PYTHONPATH=$PWD:$PYTHONPATH
        export DJANGO_SETTINGS_MODULE=$(basename $OLDPWD).settings
        cd $OLDPWD
    fi
}

# }}}
# Displays the titles and their length in a VIDEO_TS folder {{{

dvdinfo()
{
    mplayer dvd:// -dvd-device $1 -identify -ao null -vo -null -frames 0 | grep '^ID_DVD'
}

# }}}
# 256-colors test {{{

256test()
{
    echo -e "\e[38;5;196mred\e[38;5;46mgreen\e[38;5;21mblue\e[0m"
}

# }}}
# TRAPUSR2 for the allsh script {{{1
# http://sial.org/howto/shell/allsh/

TRAPUSR2() {
      [ -f ~/.sh-sourceall ] && . ~/.sh-sourceall
}

# }}}
# Dictionary lookup {{{1
# Many more options, see:
# http://linuxcommando.blogspot.com/2007/10/dictionary-lookup-via-command-line.html

dict (){
    curl 'dict://dict.org/d:$1:*'
}

spell (){
    echo $1 | aspell -a
}

# }}}
# CSS Minifier {{{1

cssmin (){
    sed -e '
s/^[ \t]*//g;         # remove leading space
s/[ \t]*$//g;         # remove trailing space
s/\([:{;,]\) /\1/g;   # remove space after a colon, brace, semicolon, or comma
s/ {/{/g;             # remove space before a semicolon
s/\/\*.*\*\///g;      # remove comments
/^$/d                 # remove blank lines
' < $1 | sed -e :a -e '$!N; s/\n\(.\)/\1/; ta # remove all newlines
s/}/}\n/g;            # put each rule on a new line
'
}

# }}}
# iwlist scan formatter {{{1

wifiscan (){
    iwlist scan 2> /dev/null | awk '
    # skip first line
    NR==1{ next }
    {
        # left-justify
        sub(/^[ \t]+/, "");
        # seperate records with newlines
        sub(/^Cell.*/,"");
        print;
    }
    ' | awk '
    # Trim leading labels
    !/^Quality/{ gsub(/^.*:/, "") };
    /^Quality/{
        gsub(/^.*=/, "");
        gsub(/  .*$/, "")
    };
    { print }
    ' | awk '
    BEGIN {
        RS=""; FS="\n"; ORS="\n"; OFS="\t"
        print "ESSID", "Mode", "Channel", "Quality", "Encryption";
    }
    {
        if ($7 ~ /WPA/) {
            print $1, $2, $3, $5, $7;
        } else {
            print $1, $2, $3, $5, $6;
        }
    }
    ' | column -tx
}

# }}}
# Output total memory currently in use by you {{{1

memtotaller() {
    /bin/ps -u $(whoami) -o pid,rss,command | awk '{sum+=$2} END {print "Total " sum / 1024 " MB"}'
}

# }}}
