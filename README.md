# ProjectM

ProjectM is a tool to help manage switching between various projects.
It does this by intelligently detecting the "root" of the project, and making various files available, such as a project-specific .gitignore, .ackignore, and other configs.
It also sources a .project file to find the name of the project and allow definition and presence of project-specific aliases and helpers. All availble only when you'd need them!

# Usage
* Add `. ~/utils/tools/projectm/init.sh` to your bashrc.
  * I strongly doubt it works in other shells, but shouldn't rely on too many bash-isms.
* In a project you'd like to make visible to ProjectM, ensure you have a git repository and a .project file in the same directory as .git
* Add `project_name="my project's name here"` to your .project
* ProjectM should detect the presence of a git repository and a .project, and automagically initialize and tweak your `$PS1`!

### Custom PS1
By default ProjectM will overwrite your PS1 when in a ProjectM directory with the PS1 I happen to find useful, in the general form
```
[hh:mm:ss] username project_name[branch_name]@relative/path/from/project/root> prompt
```

If this is disagreeable, you can provide an alternative ProjectM PS1 string by defining a `PROJECTM_PS1` function in `~/.projectmrc`. This function should echo out the true PS1 you want, so that you can use values provided by ProjectM:
* `${project_name}`: name of the current project as defined in `.project`
* `$(curr_git_branch)`: name of the currently checked out git branch. If in detached mode, `HEAD`
* `${curr_path}`: relative path from the root of the project's git repositorty
* And of course, any other visible variables or functions. `\u` for username, `\D{%T}` for time in hh:mm:ss, etc
* And colors!
  * `t_sgu`: green text, with underline
  * `t_y`: yellow text
  * `t_bb`: light blue text
  * `t_yu`: yellow text, with underline
  * `t_lr`: lavender text, bold
  * `t_rst`: reset color/style to defaults

## Todo
* Per-project notes and todo lists.
* Actually handling a custom .gitignore, figuring out how to make .ackignore work right on directories.
* Finding other interesting tools to drag into this.
* Setting only trusted projects to be used.

### Why?
I end up switching between contexts pretty frequently, both for work and my own side projects. ProjectM came out of wanting my computer to help remind me what I was looking at, and provide helpers only when contextually relevant.
