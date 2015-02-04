# use the defined project name in the shell
PS1="{${t_y}$project_name${t_rst}} $PS1"

preload() {
  . "$project_root"/.project
}
