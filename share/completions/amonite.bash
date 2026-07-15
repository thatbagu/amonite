# bash completion for amonite

__amonite_subcommands() {
  echo "init task verify tui generations rollback status help"
}

__amonite_verify_targets() {
  echo "APP all"
  if [ -d tasks ]; then
    find tasks -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | grep -E '^[TC][0-9]+'
  fi
}

__amonite_complete() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "${COMP_WORDS[1]:-}" in
    verify)
      # shellcheck disable=SC2207
      COMPREPLY=( $(compgen -W "$(__amonite_verify_targets)" -- "$cur") )
      return
      ;;
    task)
      if [ "${COMP_WORDS[2]:-}" = "new" ]; then
        return
      fi
      COMPREPLY=( $(compgen -W "new" -- "$cur") )
      return
      ;;
    rollback)
      if [ -d .amonite/generations ]; then
        local gens
        # shellcheck disable=SC2207
        gens=( $(find .amonite/generations -maxdepth 1 -name '[0-9]*' ! -name '*.meta' -exec basename {} \; 2>/dev/null | sort -n) )
        # shellcheck disable=SC2207
        COMPREPLY=( $(compgen -W "${gens[*]:-}" -- "$cur") )
      fi
      return
      ;;
  esac

  case "$prev" in
    amonite)
      # shellcheck disable=SC2207
      COMPREPLY=( $(compgen -W "$(__amonite_subcommands)" -- "$cur") )
      ;;
    init)
      COMPREPLY=( $(compgen -W "--flow-only" -- "$cur") )
      ;;
  esac
}

complete -F __amonite_complete amonite
