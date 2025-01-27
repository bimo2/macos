#!/bin/zsh

unsetopt PROMPT_SP
autoload -Uz vcs_info
zstyle ':vcs_info:git*' formats "%b"

precmd () {
  vcs_info

  if [[ -z ${vcs_info_msg_0_} ]]; then
    PS1="#%n: "
  else
    PS1="#%n: %F{yellow}${vcs_info_msg_0_}%f "
  fi
}

MYSQL_PATH=/usr/local/mysql/bin

if [ -d $MYSQL_PATH ]; then
  PATH=$PATH:$MYSQL_PATH
fi
