# fish completion for amonite

set -l subcommands init task verify tui generations rollback status help

function __amonite_verify_targets
    echo APP
    echo all
    if test -d tasks
        find tasks -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | grep -E '^[TC][0-9]+'
    end
end

function __amonite_generations
    if test -d .amonite/generations
        find .amonite/generations -maxdepth 1 -name '[0-9]*' ! -name '*.meta' -exec basename {} \; 2>/dev/null | sort -n
    end
end

# disable file completion by default
complete -c amonite -f

# subcommands
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a init        -d 'scaffold a project'
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a task        -d 'manage task capsules'
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a verify      -d 'build and verify a target'
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a tui         -d 'interactive derivation-hierarchy viewer'
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a generations -d 'list APP generations'
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a rollback    -d 'switch to a previous generation'
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a status      -d 'show flow artifacts and current generation'
complete -c amonite -n "not __fish_seen_subcommand_from $subcommands" -a help        -d 'show usage'

# init flags
complete -c amonite -n "__fish_seen_subcommand_from init" -l flow-only -d 'scaffold only the flow layer'

# task subcommands
complete -c amonite -n "__fish_seen_subcommand_from task" -a new -d 'spawn a new task capsule'

# verify targets
complete -c amonite -n "__fish_seen_subcommand_from verify" -a '(__amonite_verify_targets)'

# rollback generations
complete -c amonite -n "__fish_seen_subcommand_from rollback" -a '(__amonite_generations)'
