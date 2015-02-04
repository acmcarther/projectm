# preserve old PS1 in case we need to drop out of project mode
OLD_PS1="$PS1"

# so PS1 is actually a function in command mode...
PROMPT_COMMAND=gen_ps1

hash_util() {
  ([ -n "$(which sha256sum)" ] && echo "sha256sum") ||
  ([ -n "$(which md5sum)" ] && echo "md5sum") ||
  (echo "wc -l") # well if you don't have md5sum... not much I can do.
}

gen_ps1() {
  curr_path=$(pwd)
  export project_hash=""
  git_root=$(grt)

  if [[ ! -d "$git_root/.git" || ! -f "$git_root/.project" ]]; then
    # this check is because we never really remove ourselves from PROMPT_COMMAND.
    # so this check is done on every prompt.
    # but we only want to inform the user on the falling edge of in_project -> out_of_project
    if [ "$PS1" != "$OLD_PS1" ]; then
      echo "No git present to root against, or no .project present. Your powers weaken!"
      export old_project_hash=""
      export PS1="$OLD_PS1"
    fi
  else
    # same idea as above, only inform the user on a rising edge out_of_project -> in_project
    if [ "$PS1" = "$OLD_PS1" ]; then
      echo ".project detected. Your powers grow!"
    fi

    # automagic project reloading if the .project file changes
    export project_hash=$(cat "$(grt)/.project" | hash_util)
    if [ "$project_hash" != "$old_project_hash" ]; then
      if [ "$PS1" != "$OLD_PS1" ]; then
        echo "Change to .project detected. Reinitializing your powers."
      fi
      reloadp
    fi
    export old_project_hash="$project_hash"

    curr_path=${curr_path#$git_root}
    export PS1="[${t_sgu}\D{%T}${t_rst}] $p_chroot${t_y}\u${t_rst} ${t_lr}$project_name${t_rst}@${t_bb}$curr_path${t_rst}> "
  fi
}

reloadp() {
  . "$(grt)"/.project
}

project() {
  . ~/.projects
  if [ "$1" == "list" ]; then
    echo "${!projects[@]}"
  elif [ ${projects[$1]-"unset"} != "unset" ]; then
    cd ${projects[$1]}
  else
    echo "Unknown project: $1"
  fi
}
