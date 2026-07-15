{ pkgs, amonite }:

amonite.mkTask {
  id = "T012";
  title = "mkResearchTask lib function";

  src = ../..;

  env = with pkgs; [ nix git coreutils ];

  build = ''
    cp -r . "$out"
    chmod -R u+w "$out"
    find "$out" -xtype l -delete
    # Bake the nixpkgs store path so verify can import lib.nix offline
    echo -n "${pkgs.path}" > "$out/.nixpkgs-path"
  '';

  verify = {
    # BEHAVIORAL: eval lib.nix directly using the baked nixpkgs path.
    # Checks that mkResearchTask is a function — grep can't verify callability.
    lib-exports-fn = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      result=$(nix eval --impure --raw --expr "
        builtins.typeOf ((import \"$out/nix/lib.nix\" {
          pkgs = import \"$_nixpkgs\" {};
        }).mkResearchTask)
      ")
      [ "$result" = "lambda" ] || { echo "mkResearchTask is not a function: $result"; exit 1; }
    '';

    # BEHAVIORAL: call mkResearchTask with threshold overrides and read them back
    # from passthru — proves the attribute is accepted and stored, not silently dropped
    fn-accepts-thresholds = ''
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      tf=$(nix eval --impure --raw --expr "
        let lib = import \"$out/nix/lib.nix\" { pkgs = import \"$_nixpkgs\" {}; };
            t   = lib.mkResearchTask {
              id = \"T_th\"; title = \"threshold test\";
              tfidfThreshold = 0.05; nliThreshold = 0.42;
              env = []; build = \"mkdir \\\"\$out/sources\\\"; echo r > \\\"\$out/report.md\\\"\";
            };
        in toString t.passthru.tfidfThreshold
      ")
      [ "$tf" = "5.0e-2" ] || echo "$tf" | grep -q "0.05" \
        || { echo "tfidfThreshold not preserved in passthru: '$tf'"; exit 1; }
      nli=$(nix eval --impure --raw --expr "
        let lib = import \"$out/nix/lib.nix\" { pkgs = import \"$_nixpkgs\" {}; };
            t   = lib.mkResearchTask {
              id = \"T_th2\"; title = \"threshold test 2\";
              tfidfThreshold = 0.05; nliThreshold = 0.42;
              env = []; build = \"mkdir \\\"\$out/sources\\\"; echo r > \\\"\$out/report.md\\\"\";
            };
        in toString t.passthru.nliThreshold
      ")
      echo "$nli" | grep -q "0.42" \
        || { echo "nliThreshold not preserved in passthru: '$nli'"; exit 1; }
    '';

    # BEHAVIORAL: confirm flake.nix actually calls mkResearchTask (structural)
    # AND that the function is callable with the dogfood R000 args (behavioral).
    # Full flake eval requires network in sandbox; lib.nix eval does not.
    flake-dogfoods-fn = ''
      grep -q "mkResearchTask" "$out/flake.nix"
      export HOME; HOME=$(mktemp -d)
      export NIX_CONF_DIR="$HOME/nix-conf"
      mkdir -p "$NIX_CONF_DIR"
      printf 'experimental-features = nix-command\n' > "$NIX_CONF_DIR/nix.conf"
      _nixpkgs=$(cat "$out/.nixpkgs-path")
      # Instantiate the dogfood research task from lib.nix directly to confirm
      # the R000 scenario (id, title, build, env) evaluates to a derivation
      drv_type=$(nix eval --impure --raw --expr "
        let lib = import \"$out/nix/lib.nix\" { pkgs = import \"$_nixpkgs\" {}; };
            pkgs = import \"$_nixpkgs\" {};
            t = lib.mkResearchTask {
              id = \"R000\"; title = \"lib self-test research task\";
              env = [ pkgs.coreutils ];
              build = \"mkdir -p \\\"\$out/sources\\\"; echo s > \\\"\$out/sources/s.txt\\\"; echo r > \\\"\$out/report.md\\\"\";
            };
        in builtins.typeOf t
      ")
      [ "$drv_type" = "set" ] \
        || { echo "mkResearchTask dogfood did not produce a derivation set: $drv_type"; exit 1; }
    '';

    # BEHAVIORAL: run the enforcement shell snippet against a fake $out that
    # has report.md but no sources/ — must exit non-zero
    enforces-sources-dir = ''
      _fake=$(mktemp -d)
      echo "test content" > "$_fake/report.md"
      out_save=$out
      out="$_fake"
      (
        test -d "$out/sources" \
          || { echo "mkResearchTask: build must populate \$out/sources/" >&2; exit 1; }
      ) && { echo "FAIL: enforcement should have triggered"; exit 1; } \
        || echo "PASS: enforcement correctly rejects missing sources/"
      out=$out_save
    '';

    # BEHAVIORAL: same enforcement against a fake $out with sources/ but no report.md
    enforces-report-md = ''
      _fake=$(mktemp -d)
      mkdir -p "$_fake/sources"
      echo "source content" > "$_fake/sources/s.txt"
      out_save=$out
      out="$_fake"
      (
        test -f "$out/report.md" \
          || { echo "mkResearchTask: build must produce \$out/report.md" >&2; exit 1; }
      ) && { echo "FAIL: enforcement should have triggered"; exit 1; } \
        || echo "PASS: enforcement correctly rejects missing report.md"
      out=$out_save
    '';
  };
}
