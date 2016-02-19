# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts
CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

## huh dont need this
collapse_pwd() {
   # echo $(pwd | sed -e "s,^$HOME,~,")
   echo $(pwd | sed -e "s,^$HOME,~," | sed "s@\(.\)[^/]*/@\1/@g")
}


# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
    # echo $(pwd | sed -e "s,^$HOME,~," | sed "s@\(.\)[^/]*/@\1/@g")
    # echo $(pwd | sed -e "s,^$HOME,~,")
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`
  local state=""

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    state=""

    #Custom
    local git_status="$(git status --porcelain 2> /dev/null)"

    if [[ $git_status =~ ($'\n'|^).M ]]; then local has_modifications=""; fi
    if [[ $git_status =~ ($'\n'|^)M ]]; then local has_modifications_cached=""; fi
    if [[ $git_status =~ ($'\n'|^)A ]]; then local has_adds=""; fi
    if [[ $git_status =~ ($'\n'|^).D ]]; then local has_deletions=""; fi
    if [[ $git_status =~ ($'\n'|^)D ]]; then local has_deletions_cached=""; fi
    if [[ $git_status =~ ($'\n'|^)[MAD] && ! $git_status =~ ($'\n'|^).[MAD\?] ]]; then local ready_to_commit=""; fi

 #Modification counts
    local number_of_modified_files=$(grep -c "^ M" <<< "${git_status}")
  [[ $number_of_modified_files -gt 1 ]] && has_modifications+=" :$number_of_modified_files"

  #Add counts
      local number_of_add_files=$(grep -c "^A" <<< "${git_status}")
  [[ $number_of_add_files -gt 1 ]] && has_adds+=" :$number_of_add_files"

      #Deletes counts
      local number_of_deleted_files=$(grep -c "^ D" <<< "${git_status}")
  [[ $number_of_deleted_files -gt 1 ]] && has_deletions+=" :$number_of_deleted_files"

  #Untracked files counts
      local number_of_untracked_files=$(\grep -c "^??" <<< "${git_status}")
    if [[ $number_of_untracked_files -gt 0 ]]; then local has_untracked_files=""; fi
    if [[ $number_of_untracked_files -gt 1 ]]; then  has_untracked_files+=":$number_of_untracked_files"; fi

    ##Tags
    local tag_at_current_commit=$(git describe --exact-match --tags $(git rev-parse HEAD 2> /dev/null) 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then local is_on_a_tag=""; fi

    ## Stashes
    local number_of_stashes="$(git stash list -n1 2> /dev/null | wc -l | sed -e 's/^[[:space:]]*//')"
    if [[ $number_of_stashes -gt 1 ]]; then local has_stashes=" +$number_of_stashes"; fi

      local content=" "
  #Filling
      [[ -n "$has_untracked_files" ]] && content+="$(prompt_segment black red "$has_untracked_files") "
      [[ -n "$has_stashes" ]] && content+="$(prompt_segment black yellow "$has_stashes") "
      [[ -n "$has_modifications" ]] && content+="$(prompt_segment black yellow "$has_modifications") "
      [[ -n "$has_deletions" ]] && content+="$(prompt_segment black red "$has_deletions") "
      [[ -n "$has_adds" ]] && content+="$(prompt_segment black yellow "$has_adds") "
      [[ -n "$has_modifications_cached" ]] && content+="$(prompt_segment black white "$has_modifications_cached") "
      [[ -n "$has_deletions_cached" ]] && content+="$(prompt_segment black white "$has_deletions_cached") "
      [[ -n "$ready_to_commit" ]] && content+="$(prompt_segment black green "$ready_to_commit") "
      [[ -n "$is_on_a_tag" ]] && content+="$(prompt_segment black green "$is_on_a_tag") "


    state+=" $(echo -ne "${content}" | sed -e 's/[[:space:]]*$//')"
  else
       state= prompt_segment  black cyan "☁"
  fi
      prompt_segment black default "%(!.%{%F{yellow}%}.)$state"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY='±'
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi
    echo -n "${ref/refs\/heads\// }"
fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue black '%~'
  # echo $(pwd | sed -e "s,^$HOME,~," | sed "s@\(.\)[^/]*/@\1/@g")
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙ "

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt)'