# amonite architecture

## Design position

Spec frameworks (Spec Kit, Kiro, OpenSpec) got the *flow* right — persistent
constitution → spec → plan → tasks — and verification wrong: "does the code
satisfy the spec?" is answered by an LLM re-reading markdown. amonite keeps
the flow and replaces the answer with the Nix build graph. The spec's
verifiable core compiles to derivations; a derivation either builds or it
doesn't; an agent inside a no-network sandbox with pinned inputs cannot talk
its way past that.

## Layers

### 1. Flow layer (markdown, persistent)

`.amonite/{principles,spec,plan,tasks}.md`, driven by the `/amonite.*`
commands. Adapted from Spec Kit with three amonite-specific obligations:

- every "done when" must be observable (it will become a `verify` entry);
- every plan declares its verification strategy per layer, including the
  explicit impure remainder (`gate.live`);
- every task row carries its minimal env grants.

### 2. Meta flake (project root)

Minimal at init. `/amonite.plan` writes the project-wide toolchain at the
`# amonite:toolchain` marker once the stack is fixed. It aggregates —
`loadTasks` imports every `tasks/*/task.nix`, `clusters.nix` composes them —
and exposes:

- `packages.task-TNNN` / `packages.cluster-CNNN` / `packages.default` (APP)
- `checks.*` = all of the above → `nix flake check` is total verification.

### 3. Task capsules (`tasks/TNNN/`)

Encapsulation for implementation. `task.nix` is the single source of truth
(env grants, build, verify); the capsule `flake.nix` wraps it to give an
implementing agent `nix develop` with exactly the granted env. The project
flake imports the same `task.nix`, so capsule and aggregate can never
disagree.

### 4. Derivation semantics (nix/lib.nix)

Five public functions — no more without a spec amendment (N2):

- `mkTask`: build runs, then every `verify` snippet must exit 0, inside the
  same derivation. Existence in the store ⇒ verified. The verification
  trail is written to `$out/.amonite/verified` so it ships with the artifact.
- `mkCluster`: member tasks are `buildInputs` — Nix's dependency resolution
  *is* the orchestrator; a cluster cannot realise before its members verify.
  `integrate` assembles member outputs; cluster-level `verify` runs
  integration criteria.
- `mkApplication` = `mkCluster`, vocabulary for the root: the final
  derivation aka the working application.
- `mkResearchTask`: wraps `mkTask` and enforces that the build produces
  `$out/sources/` (collected evidence) and `$out/report.md` (synthesis).
  After the build, two offline verification tiers run automatically: TF-IDF
  cosine similarity (fast lexical gate) and AlignScore NLI entailment
  (claim-level faithfulness against sources). No network at verify time;
  model weights are a fixed-output Nix derivation.
- `mkVmVerify`: wraps `pkgs.testers.runNixOSTest` so a full NixOS VM
  integration test is just another derivation in a cluster's member list.
  Linux builders required (x86_64-linux or aarch64-linux); on darwin,
  configure a linux-builder or remote builder.

## Verification ladder

```
task.verify        unit criteria            hermetic   in-derivation
cluster.verify     integration criteria     hermetic   in-derivation (nixosTest capable)
APP.verify         end-to-end smoke         hermetic   in-derivation
gate.live          real-world checks        IMPURE     human-gated, listed in plan.md
```

The ladder's honesty property: everything below `gate.live` is provably
hermetic, so when something fails at `gate.live` you know it's the world,
not the toolchain.

## Tooling surface

- `graph.<system>` flake output (`lib.mkGraph`): serializable node list —
  id, title, kind, store path (unbuilt), members. Store-path existence is
  the verified/pending signal; no daemon, no state file.
- `amonite tui` (Go, bubbletea/lipgloss): renders that graph as a tree,
  verifies nodes interactively. `--dump` for headless rendering.
- Generations: see below; `amonite generations` / `amonite rollback`.

## Deliberate non-goals

- No orchestrator daemon, no state DB: the Nix store is the state.
- No LLM-judged compliance: if a criterion can't be mechanical it goes to
  `gate.live` where a human owns it.
- No framework growth: the surface is one lib (5 functions), 4 templates,
  5 commands, 1 CLI. If it needs plugins, it has failed.

## Generations

`amonite verify APP` records each successful build as a generation:
`.amonite/generations/N` is a GC-rooted symlink (created via
`nix build --out-link`, so the store path cannot be garbage-collected)
plus an `N.meta` file carrying the producing git rev and timestamp.
`current` is a relative symlink to a generation number. `rollback` flips
`current` — instant, and always to an artifact that already passed the
full verification tree. Generations are machine-local (gitignored);
reproducing one elsewhere = checking out its rev and building, which the
committed locks make bit-identical.

## Verification quality

`verify` entries must exercise behavior, not file presence:

| Pattern | Verdict | Note |
|---|---|---|
| `"$out/bin/tool" --help \| grep -q expected` | ✓ behavioral | invokes the binary |
| `shellcheck --shell=bash "$out/bin/amonite"` | ✓ behavioral | runs the checker |
| `python3 verify_tfidf.py --report ... --threshold 0.08` | ✓ behavioral | executes script |
| `nix build .#research-fixture --no-link` | ✓ behavioral | proves derivation builds |
| `test -f "$out/bin/tool"` | ✗ weak | passes for empty/broken files |
| `grep -q "keyword" "$out/src/file.nix"` | ✗ weak | passes even if logic is dead |

The only acceptable `test -f` / `grep -q` uses: static assets (license files,
workflow YAML that can't be run hermeticallay) where there is no runnable form.
Always note why in a comment when using them.

## Known limitations

- `mkVmVerify` requires Linux builders; on darwin configure a linux-builder or
  remote builder before using it in a cluster.
- Live-infra work (terraform against real state) only benefits at the
  toolchain + plan-policy layers; the final verdict stays impure by nature.
- `verify` snippets run as part of the build, so they cannot use the
  network — that is the point, but it means e.g. "call the staging API"
  is structurally excluded (gate.live).
- AlignScore NLI threshold calibration: synthesis research tasks (analytical
  conclusions drawn from sources) naturally score lower than extraction tasks
  (sentences copied verbatim from sources). Default threshold 0.35 is
  calibrated for synthesis; adjust per task based on observed mean scores.
