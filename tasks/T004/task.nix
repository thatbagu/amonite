{ pkgs, amonite }:

amonite.mkTask {
  id = "T004";
  title = "Shell completions bash zsh fish";

  src = ../..;

  env = with pkgs; [ bash zsh fish coreutils ];

  build = ''
    mkdir -p "$out/share/completions"
    cp "$src/share/completions/amonite.bash" "$out/share/completions/amonite.bash"
    cp "$src/share/completions/_amonite"     "$out/share/completions/_amonite"
    cp "$src/share/completions/amonite.fish" "$out/share/completions/amonite.fish"
  '';

  verify = {
    bash-syntax = ''bash -n "$out/share/completions/amonite.bash"'';

    zsh-syntax = ''
      zsh --no-exec "$out/share/completions/_amonite"
    '';

    fish-syntax = ''
      fish --command "source $out/share/completions/amonite.fish"
    '';

    bash-subcommands = ''
      script=$(mktemp)
      cat > "$script" <<'BASH'
      COMP_WORDS=(amonite "")
      COMP_CWORD=1
      # shellcheck source=/dev/null
      source "$1"
      __amonite_complete
      printf '%s\n' "''${COMPREPLY[@]}"
      BASH
      result=$(bash "$script" "$out/share/completions/amonite.bash")
      echo "$result" | grep -q 'init'
      echo "$result" | grep -q 'verify'
      echo "$result" | grep -q 'status'
    '';
  };
}
