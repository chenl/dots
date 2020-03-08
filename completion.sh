# Do completion from a passed list of paths
#
# opt: The list of paths to complete from
# opt: The current word being completed
_dots_path_comp()
{
  # This forces readline to only display the last item separated by a slash
  compopt -o filenames

  local IFS=$'\n'
  local k="${#COMPREPLY[@]}"

  for path in $(compgen -W "$1" -- $2)
  do
    local trailing_trim

    # Determine what to trim from the end
    trailing_trim="${path#${2%/*}/}/"
    trailing_trim="${trailing_trim#*/}"
    trailing_trim="${trailing_trim%/}"

    # Don't add a space if there is more to complete
    [[ "$trailing_trim" != "" ]] && compopt -o nospace

    # Remove the slash if mark-directories is off
    if ! _rl_enabled mark-directories
    then
      # If The current typed path doesnt have a slash in it yet check if it is
      # the full first portion of a path and ignore everything after if it is.
      # We don't have to do this once the typed path has a slash in it as the
      # logic above will pick up on it
      [[ "$2" != */* && "$path" == ${2}/* ]] && path="$2/$trailing_trim"

      trailing_trim="/$trailing_trim"
    fi

    COMPREPLY[k++]="${path%%${trailing_trim}}"
  done
}

# Call a dots command without any stderr
_dots_call() {
  dots "$@" 2>/dev/null
}

# Handle completion of the diff command, pass flags to the git completion
# function, otherwise just complete using the files list
_dots_complete_diff() {
  if [[ "$cur" != -* ]]
  then
    __dots_path_comp "$(__dots_call files)" "$cur"
    return
  fi

  echo "DOING GIT STUFF"

  # Do git diff completion
  local git_comp_file="/usr/share/bash-completion/completions/git"

  # Load in the git completion file if nessicary
  if [[ -z "$__git_diff_common_options" && -e "$git_comp_file" ]]
  then
      source "$git_comp_file"
  fi

  # If we were able to load it do completion with common options
  if [[ -n "$__git_diff_common_options" ]]
  then
      COMPREPLY=( $(compgen -W "$__git_diff_common_options" -- "$cur") )
  fi
}


# Custom completion function used by cobra bash completion generation
_dots_custom_func() {
  case "${last_command}" in
    dots_diff)
      __dots_complete_diff
      ;;
    dots_files | dots_install)
      __dots_path_comp "$(__dots_call files)" "$cur"
      ;;
    dots_config_override)
      __dots_path_comp "$(__dots_call config groups)" "$cur"
      ;;
    dots_config_use)
      __dots_path_comp "$(__dots_call config profiles)" "$cur"
      ;;
    dots_config_active | dots_config_clear | dots_config_groups | dots_config_profiles)
      COMPREPLY=( "test" )
      return 0
      ;;
  esac
}
