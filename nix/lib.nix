# amonite core library.
#
# The model:
#   task     = derivation that builds one unit of work and runs its
#              verifications inside the build. Building IS verifying:
#              a task that exists in the store has passed its checks.
#   cluster  = derivation aggregating verified tasks (or other clusters)
#              plus integration-level verifications across their outputs.
#   application = the top cluster; `nix build` on it realises the whole
#              verified tree or fails at the first unverified node.
#
# Because tasks are inputs (buildInputs) of their cluster, Nix's own
# dependency semantics enforce the flow: a cluster cannot be built until
# every member task has built and verified. No orchestrator needed.
{ pkgs }:

let
  inherit (pkgs) lib;

  # Render an attrset of { name = shellSnippet; } into a fail-fast
  # verification script. Each snippet runs in a subshell; non-zero exit
  # fails the whole derivation. Results are recorded in the output so
  # the verification trail ships with the artifact.
  renderVerify = verify: ''
    mkdir -p "$out/.amonite"
    : > "$out/.amonite/verified"
  '' + lib.concatStringsSep "\n" (lib.mapAttrsToList (name: snippet: ''
    echo "amonite ▶ verify:${name}"
    if ( ${snippet} ); then
      echo "${name}=pass" >> "$out/.amonite/verified"
    else
      echo "amonite ✗ verify:${name} FAILED"
      exit 1
    fi
  '') verify);

in
rec {
  # One unit of work with a clear outcome.
  #
  #   id     : "T001" — stable identifier from tasks.md
  #   title  : human description
  #   src    : optional source tree the build starts from
  #   env    : packages granted to this task (encapsulation boundary:
  #            the task sees these and nothing else)
  #   build  : shell script producing artifacts under $out
  #   verify : attrset of named acceptance criteria; every one must pass
  #            for the derivation to exist
  mkTask =
    { id
    , title
    , src ? null
    , env ? [ ]
    , build
    , verify ? { }
    # Informational dependency list: other task IDs that must be done before
    # this one. Not enforced by Nix (clusters handle build ordering); used by
    # `amonite waves` and the TUI to compute parallel execution waves.
    , depends ? [ ]
    }:
    pkgs.stdenvNoCC.mkDerivation {
      name = "amonite-task-${id}";
      inherit src;
      dontUnpack = src == null;
      nativeBuildInputs = env;
      passthru = { amonite = { inherit id title depends; kind = "task"; }; };
      buildPhase = ''
        runHook preBuild
        mkdir -p "$out"
        ${build}
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        ${renderVerify verify}
        {
          echo "id=${id}"
          echo "title=${title}"
          echo "kind=task"
        } > "$out/.amonite/meta"
        runHook postInstall
      '';
    };

  # Aggregate verified tasks (or clusters) into a higher abstraction.
  #
  #   tasks     : list of mkTask/mkCluster derivations
  #   integrate : optional shell script combining member outputs into
  #               something new under $out (defaults to linking members)
  #   verify    : integration-level acceptance criteria over $out
  mkCluster =
    { id
    , title
    , tasks
    , env ? [ ]
    , integrate ? ""
    , verify ? { }
    }:
    let
      memberLinks = lib.concatMapStringsSep "\n"
        (t: ''ln -s ${t} "$out/tasks/${t.amonite.id or t.name}"'')
        tasks;
    in
    pkgs.stdenvNoCC.mkDerivation {
      name = "amonite-cluster-${id}";
      dontUnpack = true;
      nativeBuildInputs = env;
      # Members are real dependencies: this cluster is unbuildable until
      # every member task has built (and therefore verified).
      buildInputs = tasks;
      passthru = { amonite = { inherit id title tasks; kind = "cluster"; }; };
      buildPhase = ''
        runHook preBuild
        mkdir -p "$out/tasks"
        ${memberLinks}
        ${integrate}
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        ${renderVerify verify}
        {
          echo "id=${id}"
          echo "title=${title}"
          echo "kind=cluster"
          echo "members=${lib.concatMapStringsSep "," (t: t.amonite.id or t.name) tasks}"
        } > "$out/.amonite/meta"
        runHook postInstall
      '';
    };

  # The final derivation aka working application: a cluster whose output
  # is the deliverable itself. Alias kept for vocabulary clarity.
  mkApplication = mkCluster;

  # A task specialised for research work: wraps mkTask and enforces that
  # the build produces a structured output with collected source materials
  # and a synthesis report.
  #
  #   id              : "R001" — stable identifier
  #   title           : human description
  #   src             : optional source tree
  #   env             : packages granted to this task
  #   build           : shell script producing artifacts under $out.
  #                     MUST populate $out/sources/ and $out/report.md.
  #   depends         : informational list of prerequisite task IDs (default [])
  #   tfidfThreshold  : minimum TF-IDF relevance score for a source to be
  #                     included (default 0.10). Stored in passthru for
  #                     downstream verify scripts.
  #   nliThreshold    : minimum NLI entailment confidence threshold (default
  #                     0.65). Stored in passthru for downstream verify scripts.
  #   sources         : structural marker / list of paths for tooling (optional)
  mkResearchTask =
    { id
    , title
    , src ? null
    , env ? [ ]
    , build
    , depends ? [ ]
    , tfidfThreshold ? 0.10
    , nliThreshold ? 0.65
    , sources ? [ ]
    , verify ? { }
    }:
    let
      # Enforcement checks appended after the user's build script.
      enforcementChecks = ''
        test -d "$out/sources" || { echo "mkResearchTask: build must populate \$out/sources/" >&2; exit 1; }
        test -f "$out/report.md" || { echo "mkResearchTask: build must produce \$out/report.md" >&2; exit 1; }
      '';
      drv = mkTask {
        inherit id title src env depends verify;
        build = build + "\n" + enforcementChecks;
      };
    in
    drv.overrideAttrs (_: {
      passthru = {
        amonite = { inherit id title depends; kind = "research-task"; };
        inherit tfidfThreshold nliThreshold sources;
      };
    });

  # Services-in-VMs integration verification for a cluster: wraps
  # pkgs.testers.runNixOSTest so the result is an ordinary derivation you
  # can put in a cluster's `tasks` list — the cluster then cannot build
  # until the VM test passes. Linux only (needs a Linux builder on darwin).
  #
  #   nodes / testScript: as in runNixOSTest.
  mkVmVerify = { id, nodes, testScript }:
    (pkgs.testers.runNixOSTest {
      name = "amonite-vm-${id}";
      inherit nodes testScript;
    }).overrideAttrs (_: {
      passthru = { amonite = { inherit id; title = "VM verification ${id}"; kind = "vm-verify"; }; };
    });

  # Serializable task/cluster graph for tooling (amonite tui).
  # outPath is the derivation's store path WITHOUT building it, so a
  # consumer can test existence to learn verified-vs-pending.
  #
  # mkGraph recurses into cluster members so sub-clusters at any nesting
  # depth appear as first-class nodes. A cluster can appear as a member of
  # multiple parents; deduplication by id keeps the flat node list clean.
  mkGraph = { tasks, clusters }:
    let
      nodeOf = d: {
        id    = d.amonite.id or d.name;
        title = d.amonite.title or d.name;
        kind  = d.amonite.kind or "task";
        # NOT named outPath: that would make nix eval --json collapse the
        # node to a bare string (derivation-like attrset semantics).
        store   = "${d}";
        members = map (m: m.amonite.id or m.name) (d.amonite.tasks or [ ]);
        # Informational task dependencies for wave computation (tasks only).
        depends = d.amonite.depends or [ ];
      };
      # Depth-first walk: yields this node then all descendant nodes.
      collectAll = d:
        [ (nodeOf d) ] ++
        lib.concatMap collectAll (d.amonite.tasks or [ ]);
      # Deduplicate by id (fold preserves last-wins; all copies are identical).
      dedup = ns:
        lib.attrValues
          (lib.foldl' (acc: n: acc // { ${n.id} = n; }) { } ns);
    in
    {
      nodes = dedup (lib.concatMap collectAll (lib.attrValues (tasks // clusters)));
    };

  # Load every tasks/*/task.nix under a project root and return
  # { T001 = <derivation>; ... }. Task flakes stay individually usable;
  # the project flake aggregates them through this without flake-input
  # plumbing.
  loadTasks = { root, amonite ? null }:
    let
      self = if amonite == null then (import ./lib.nix { inherit pkgs; }) else amonite;
      tasksDir = root + "/tasks";
      entries =
        if builtins.pathExists tasksDir
        then lib.filterAttrs (_: type: type == "directory") (builtins.readDir tasksDir)
        else { };
      hasTaskNix = name: builtins.pathExists (tasksDir + "/${name}/task.nix");
    in
    lib.mapAttrs
      (name: _: import (tasksDir + "/${name}/task.nix") { inherit pkgs; amonite = self; })
      (lib.filterAttrs (name: _: hasTaskNix name) entries);
}
