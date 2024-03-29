#!/bin/zsh

setopt null_glob extended_glob

CYAN='\033[0;36m'
NC='\033[0m'  # No Color

DOT_DIR=${0:a:h}  # the directory of this script

pf_loc=()  # profile locations
pf_pat=()  # profile patterns

declare -A pf_map   # <pf-name> : <idxes>

_add-pf() {  # <pf-name> {<pf-loc> <pf-pat>}...
    local name=${1%.pf}
    for i in {2..$#@..2}; {
        pf_loc+=($@[i])
        pf_pat+=($@[i+1])
        pf_map[$name]+="$#pf_loc "
    }
}
alias -s pf='_add-pf'

_rsync-pat() {  # <src> <dst> <pat>
    cd $1 && rsync $=rsync_opt --relative $~=3 $2/
}

_sync() {  # <pf-name>
    for i in $=pf_map[$1]; {
        local changes=$(_rsync-pat $pf_loc[i] $DOT_DIR/$1 $pf_pat[i])
        if [[ $changes != '' ]] {
            echo $CYAN"$1 <- ${(D)pf_loc[i]}"$NC
            echo $changes
            echo
        }
    }
}

_apply() {  # <pf-name>
    for i in $=pf_map[$1]; {
        local changes=$(_rsync-pat $DOT_DIR/$1 $pf_loc[i] $pf_pat[i])
        if [[ $changes != '' ]] {
            echo $CYAN"$1 -> ${(D)pf_loc[i]}"$NC
            echo $changes
            echo
        }
    }
}

_for-each-pf() {  # <func> [--all | <pf-name>...]
    local func=$1; shift
    if [[ $1 == --all ]] {
        for i in ${(k)pf_map}; $func $i
    } else {
        for i in ${(u)@}; $func $i
    }
}

cute-dot-list()  { printf '%s\n' ${(ko)pf_map} }
cute-dot-sync()  { _for-each-pf _sync $@ }
cute-dot-apply() { _for-each-pf _apply $@ }

# =============================== Config Begin =============================== #

# Rsync Options
rsync_opt='-rci --mkpath'

# Profile List
#
# Example:
#
# zsh.pf \
#     ~ '.zshenv' \
#     ~/.config/zsh '.zshrc *.zsh */^*.zwc'

# ================================ Config End ================================ #

cute-dot-$1 ${@:2}
