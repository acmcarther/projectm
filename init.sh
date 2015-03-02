# this is used for storing the list of known projects as defined in ~/.projects
declare -A projects

# preserve old PS1 in case we need to drop out of project mode
OLD_PS1="$PS1"

# so PS1 is actually a function in command mode...
PROMPT_COMMAND=gen_ps1

gen_completions() {
  . ~/.projects
  echo "${!projects[@]}"
}

hash_util() {
  ([ -n "$(which sha256sum)" ] && echo "sha256sum") ||
  ([ -n "$(which md5sum)" ] && echo "md5sum") ||
  (echo "wc -l") # well if you don't have md5sum... not much I can do.
}

curr_git_branch() {
  echo $(git rev-parse --abbrev-ref HEAD)
}

grt() {
  echo $(git rev-parse --show-toplevel 2>/dev/null)
}

gen_ps1() {
  local t_rst='\[\e[00m\]'
  local t_sgu='\[\e[04;32m\]'
  local t_y='\[\e[00;33m\]'
  local t_bb='\[\e[00;36m\]'
  local t_yu='\[\e[04;33m\]'
  local t_lr='\[\e[01;35m\]'

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
    export project_hash=$(cat "$(grt)/.project" | $(hash_util))
    if [ "$project_hash" != "$old_project_hash" ]; then
      if [ "$PS1" != "$OLD_PS1" ]; then
        echo "Change to .project detected. Reinitializing your powers."
      fi
      reloadp
    fi
    export old_project_hash="$project_hash"

    curr_path=${curr_path#$git_root}
    export PS1="[${t_sgu}\D{%T}${t_rst}] $p_chroot${t_y}\u${t_rst} ${t_lr}$project_name${t_rst}[${t_yu}$(curr_git_branch)${t_rst}]@${t_bb}$curr_path${t_rst}> "
  fi
}

errcho() {
  >&2 echo "$@"
}

reloadp() {
  . "$(grt)"/.project
}

p() {
  project "$@"
}

project() {
  . ~/.projects
  if [ "$1" == "list" ]; then
    echo "${!projects[@]}"
  elif [ "$1" == "add" ]; then
    add_project "$2" "$3"
  elif [ "$1" == "import" ]; then
    add_project "$(pwd)" "$2"
  elif [ ${projects[$1]-"unset"} != "unset" ]; then
    cd ${projects[$1]}
  else
    echo "Unknown project: $1"
  fi
}

# $2 is the name of the project to be added, if also creating .project
# $1 is the directory of the project to be added
add_project() {
  if [ -n "$2" ]; then
    if [ -d "$1" ]; then
      echo "project_name=\"$2\"" >> "$1/.project"
    else
      errcho "not a dir. unable to create .project here."
      # not a dir, do nothing and fail below
    fi
  fi

  if [ -d "$1/.git" ]; then
    if [ -f "$1/.project" ]; then
      name=$(get_name "$1/.project")
      if [ "$name" != "_UNDEFINED" ]; then
        echo "projects[\"$name\"]=\"$1\"" >> ~/.projects
        . ~/.projects
      else
        errcho "No project_name defined for $1"
      fi
    else
      errcho "No .project in '$1'"
    fi
  else
    errcho "No .git in '$1'"
  fi
}

# gets the name of the project specified in the .project path given as the first argument
get_name() {
  name=$(bash -c ". $1 && echo \$project_name")
  if [ -z "$name" ]; then
    echo "_UNDEFINED"
  else
    echo "$name"
  fi
}

p_dir() {
  . ~/.projects
  echo ${projects[$1]}
}

_project_complete() {
  local completions="$(gen_completions)"
  local word="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "$completions" -- "$word"))
}

complete -F _project_complete p
