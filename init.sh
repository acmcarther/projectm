# this is used for storing the list of known projects as defined in ~/.projects
declare -A projects

if [ -f "~/.projectmrc" ]; then
  . ~/.projectmrc
fi

old_project_hash=""
project_loaded=false

# preserve old PS1 in case we need to drop out of project mode
OLD_PS1="$PS1"

# so PS1 is actually a function in command mode...
PROMPT_COMMAND=gen_ps1

list_project_names() {
  declare -A projects
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

is_projectm_dir() {
  [[ -d "$(grt)/.git" && -f "$(grt)/.project" ]]
}

is_reload_necessary() {
  local project_hash="$(cat "$(grt)/.project" | $(hash_util))"
  local reload="no"
  if [ "$project_hash" != "$old_project_hash" ]; then
    reload="yes"
  fi
  old_project_hash="$project_hash"
  [ "$reload" = "yes" ]
}

gen_ps1() {
  local t_rst='\[\e[00m\]'
  local t_sgu='\[\e[04;32m\]'
  local t_y='\[\e[00;33m\]'
  local t_bb='\[\e[00;36m\]'
  local t_yu='\[\e[04;33m\]'
  local t_lr='\[\e[01;35m\]'

  project_hash=""

  if is_projectm_dir; then
    if is_reload_necessary; then
      if $project_loaded; then
        echo "Change to .project detected. Reinitializing your powers."
      else
        echo ".project detected. Your powers grow!"
      fi
      reloadp
      project_loaded=true
    fi

    curr_path="$(pwd)"
    git_root="$(grt)"
    curr_path="${curr_path#$git_root}"
    if [ "$(type -t "PROJECTM_PS1")" = "function" ]; then
      PS1="$(PROJECTM_PS1)"
    else
      PS1="[${t_sgu}\D{%T}${t_rst}] $p_chroot${t_y}\u${t_rst} ${t_lr}$project_name${t_rst}[${t_yu}$(curr_git_branch)${t_rst}]@${t_bb}$curr_path${t_rst}> "
    fi
  else
    # this check is because we never really remove ourselves from PROMPT_COMMAND.
    # so this check is done on every prompt. only take action when leaving a project.
    if $project_loaded; then
      echo "No git present to root against, or no .project present. Your powers weaken!"
      old_project_hash=""
      PS1="$OLD_PS1"
      project_loaded=false
    fi
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
  declare -A projects
  . ~/.projects
  if [ "$1" == "list" ]; then
    list_project_names
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
  if [ -z "$1" ]; then
    errcho "Directory to add cannot be empty"; return 1
  fi

  if [ -n "$2" ]; then
    if ! [ -d "$1" ]; then
      errcho "not a dir. unable to create .project here."; return 1
    fi
    echo "project_name=\"$2\"" >> "$1/.project"
  fi

  if ! [ -d "$1/.git" ]; then
    errcho "No .git in '$1'"; return 1
  fi

  if ! [ -f "$1/.project" ]; then
    errcho "No .project in '$1'"; return 1
  fi

  name=$(get_name "$1/.project")
  if [ "$name" != "_UNDEFINED" ]; then
    errcho "No project_name defined for $1"; return 1
  fi

  echo "projects[\"$name\"]=\"$1\"" >> ~/.projects
  declare -A projects
  . ~/.projects
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
  declare -A projects
  . ~/.projects
  echo ${projects[$1]}
}

_project_complete() {
  local completions="$(list_project_names)"
  local word="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "$completions" -- "$word"))
}

complete -F _project_complete p
