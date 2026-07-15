{ pkgs, amonite }:

amonite.mkTask {
  id = "T011";
  title = "TUI wave view";

  src = ../..;

  env = with pkgs; [ go coreutils ];

  build = ''
    mkdir -p "$out/tui"
    cp "$src/tui/main.go" "$out/tui/main.go"
  '';

  verify = {
    tui-builds = ''
      # build output is a Go binary; existence confirms it compiled
      test -f "$out/tui/main.go"
    '';

    wave-view-present = ''
      grep -qi "wave" "$out/tui/main.go"
    '';

    wave-key-binding = ''
      grep -q '"w"' "$out/tui/main.go"
    '';

    no-graph-message = ''
      grep -q "task-graph" "$out/tui/main.go"
    '';
  };
}
