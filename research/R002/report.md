# R002: Hermetic Builds, Spec-Driven Development, and Framework Robustness — Literature Review

## Summary

This report synthesises current scientific literature and authoritative technical sources on four questions relevant to the amonite project: (1) the robustness and reproducibility benefits of hermetic build systems, (2) the effectiveness of spec-driven development, (3) formal/mechanical verification compared to informal testing, and (4) methods for quantitatively comparing framework robustness. The literature consistently supports that hermetic builds deliver measurable reproducibility guarantees, that specification-driven approaches close critical gaps between design intent and implementation, and that formal verification finds classes of defect that conventional testing cannot reach. However, amonite-specific empirical claims will require purpose-designed studies; no existing paper directly benchmarks the amonite model.

---

## Hermetic Build Systems: What the Literature Says

Hermetic builds are defined as build processes that "always return the same output by isolating the build from changes to the host system" (Bazel documentation). The concept rests on two pillars: build-tool isolation (tools managed as source rather than host-installed software) and hash-based source identity (every input carries a cryptographic fingerprint). Kusari's learning-centre definition sharpens this further: hermetic builds require "complete network isolation during the build process itself," every input "explicitly declared, versioned, and cryptographically verified," and outputs that "produce bit-for-bit identical outputs when given identical inputs, regardless of when or where the build executes."

Eelco Dolstra's 2006 PhD thesis *The Purely Functional Software Deployment Model* (summarised in Wikipedia and in the Lila paper) introduced Nix as a realisation of these ideas. Nix treats packages as pure functions of their declared build- and run-time dependencies, evaluated into *derivations* — persistent data structures that specify exactly what goes into a build. Builds run in sandboxes "that prohibit access to anything but the explicitly specified input files and only allows writing to the designated output path." The practical result, per Dolstra's research, is atomic upgrades, efficient rollback, and elimination of *dependency hell* — the class of failure produced when conflicting library versions or inconsistent installations lead to unpredictable software environments.

The Bazel documentation identifies four derived benefits of hermeticity: speed (cached action outputs eliminate redundant work), parallel execution (deterministic inputs allow construction of efficient action graphs), support for multiple simultaneous builds using different tool versions, and reproducibility enabling reliable troubleshooting.

Thomas Lawless's analysis distinguishes three related but distinct properties: isolated builds (ephemeral per-build environments preventing cross-contamination), hermetic builds (immutable references for every input), and reproducible builds (identical outputs from identical definitions), concluding that "reproducible builds require both isolated and hermetic foundations first."

---

## Reproducibility as a Robustness Metric

Reproducible-builds.org defines the gold standard: "given the same source code, build environment and build instructions, any party can recreate bit-for-bit identical copies of all specified artifacts," verified through cryptographically secure hash comparison. This is not merely a convenience property — it is a trust and security mechanism.

The Lila paper (arXiv 2601.20662) provides the most concrete scale evidence: "the Nix ecosystem achieving over 90% reproducibility on more than 80,000 packages" demonstrates that high reproducibility rates are achievable across very large software collections. The paper frames reproducible builds as providing "a principled foundation for transparency and trust in software distribution," directly addressing increasingly sophisticated supply-chain attacks.

The reproducible-builds.org site documents specific quality-assurance benefits discovered through Debian's reproducibility testing: library ABI variations, encoding mismatches, missing translations, and dependency shifts — bugs that "emerge only through environmental variation testing" and would otherwise remain latent. It further argues that "reproducible builds are the only way to detect" subtle single-bit compiler-level tampering early, citing the XcodeGhost malware and the CIA "Strawhorse" program as real attacks on build infrastructure. The Kusari analysis notes that reproducibility enables "detection of unauthorized modifications to build outputs" and maintains "complete inventory of build inputs, creating an accurate software bill of materials" for vulnerability management.

---

## Spec-Driven vs. Informal Development: Evidence

Specification-driven development (SDD) elevates specifications to the role of primary engineering artifact, from which tests and implementations are derived. The literature records several advantages over informal approaches.

The Sedeve-Kit paper (arXiv 2509.11566) presents the clearest end-to-end framework: developers write TLA+ specifications, run model checking to "guaranteeing correctness," then use TraceGen to automatically generate test cases that "exhaustively cover the state space corresponding to the design." A D-Player component enforces predefined action sequences during testing, ensuring the implementation is validated against the same state space the specification verified. The key problem SDD solves is that "the final implementation may deviate from the original design as software evolves and iterates, leading to quality defects" — a gap informal processes do not close. For the Raft protocol, the Sedeve-Kit spec required 3,038 SLOC of TLA+ (including invariants), against Verdi's alternative approach needing 12,511 SLOC of Coq for specification alone and 36,925 SLOC for proofs, demonstrating substantially lower overhead for comparable coverage.

The Enhancing Formal Software Specification with AI paper (arXiv 2601.09745) reports that specification-guided development produced "correctness by design, while significantly reducing development effort and producing a correct implementation on the first attempt" in their case study, though industrial adoption has historically been limited by "high notation overhead and expertise requirements." AI assistance is proposed as a way to "retain many of the benefits of formal specification while substantially reducing these costs."

The BDD quality study (PMC7251619), with 56 practitioners across 5 continents, found broad agreement (≥75% respondents) on four quality principles for specification suites: conservation of steps, conservation of domain vocabulary, elimination of technical vocabulary, and conservation of proper abstraction. Practitioners consistently prioritised readability and clarity — indicating that spec quality is itself a measurable, practitioner-validated property. The study notes that "operationalizing these principles into measurable metrics requires future investigation."

---

## Formal/Mechanical Verification vs. Informal Testing

The empirical literature consistently shows that formal and informal approaches catch different classes of defect, and are "consistently much more effective when used in combination" (Springer empirical studies, from a controlled experiment with 47–50 subjects using three defect-detection techniques).

Unit proofs for embedded operating systems demonstrated that formal proofs were "cost-effective, detecting 74% of recreated defects, with an additional 9% found with increased bounds, and 19 new defects exposed" — a concrete defect-detection rate for a formal technique on real code.

In distributed systems, model checking's advantage is particularly stark. The Mocket paper (EuroSys 2023, ACM doi:10.1145/3552326.3587442) applied model-checking-guided testing to the Raft, XRaft, and Zab protocols, finding 3 previously unknown bugs that conventional testing had missed. The Splunk/Maas TLA+ series reports that model checkers perform "brute force search of all the possible interactions," a coverage capability testing cannot match, and that "the very process of formalising a design into a TLA+ specification helps the design process by forcing those involved to think and communicate more clearly." Datadog's engineering blog documents a specific race condition found by TLA+ model checking in Courier's sequencer architecture — "a failure mode the informal design review had missed" — which was only detectable because the model exhaustively explored sequencer invocation timing.

The critical qualification is that formal methods verify designs, not implementations: "TLA+ only tests system design and has no knowledge of the actual code used to implement it." This is precisely why frameworks like Sedeve-Kit and Mocket exist — to bridge the specification-to-implementation gap and propagate verification coverage into the code.

Industry adoption confirms practical value: TLA+ and TLC are used by distributed-systems engineers at AWS, Azure, MongoDB, and Elasticsearch for formal design verification.

---

## How to Quantify Amonite's Robustness Advantage (Proposed Metrics)

Based on the literature, the following metrics are most defensible for comparing amonite (hermetic, spec-driven) against conventional frameworks:

1. **Reproducibility rate**: Percentage of builds producing bit-for-bit identical outputs across independent machines or environments. The Nix ecosystem's 90%+ rate on 80,000+ packages (Lila, arXiv 2601.20662) provides a benchmark. Content hashes of build outputs provide the measurement instrument (PMC5706697).

2. **Phantom-dependency rate**: Count of undeclared transitive dependencies detected per project, measurable by running builds with and without network isolation and comparing dependency graphs (Kusari, Lawless).

3. **Environment-induced build failures**: Number of failures attributable to host-system variation rather than source change. Conventional build systems accumulate these; hermetic systems eliminate them by definition (Bazel documentation, reproducible-builds.org).

4. **Defect escape rate by phase**: Using the Sedeve-Kit framework's approach, track what fraction of total defects are caught at specification/model-check phase vs. implementation testing vs. production. The expected distribution shifts left under SDD.

5. **Specification-to-implementation divergence score**: Measure how often an implementation's observable behaviour deviates from its formal spec, using model-checking-guided test harnesses (Mocket approach).

6. **Mean time to failure / mean time to repair**: Standard reliability metrics (noted in the systematic robustness review search results) can be compared between hermetic-build and non-hermetic-build deployments.

The CURRANTE/SANER 2026 study design provides a reusable empirical framework: PassAll, PassRate, TestCoverage, TestDiversity, TimeToPass, and IterationsToPass metrics (arXiv 2601.03878) are directly applicable to comparing spec-driven versus ad-hoc amonite task implementations.

---

## Gaps: What We Cannot Claim Yet Without Empirical Study

The literature establishes the *properties* of hermetic and spec-driven systems in general, but does not directly measure amonite. The following claims would require original empirical work:

- **Amonite's actual reproducibility rate**: The 90%+ Nix figure applies to Nixpkgs packages, not to amonite task capsules, which add a layer of task-specific Nix expressions.
- **Defect detection improvement attributable to amonite's spec-first workflow**: No controlled study compares amonite's spec → task → capsule pipeline against informal alternatives.
- **Developer productivity delta**: The BDD quality study and SANER 2026 design both call out that specification overhead must be weighed against defect-reduction benefits; no amonite data exists.
- **Generalisation of formal methods advantage**: The TLA+ and Mocket results are from distributed protocol verification. Their quantitative defect-detection rates do not automatically transfer to build-system or task-orchestration correctness properties.
- **Long-term maintenance cost**: The Datadog blog acknowledges formal models "require ongoing maintenance as systems evolve"; no amonite longitudinal data exists.

---

## Conclusion

The literature provides a strong theoretical and empirical foundation for three of the four research questions. Hermetic build systems — exemplified by Nix (Dolstra 2006) and Bazel — provably eliminate environment-induced variation, eliminate phantom dependencies, and, in the Nix ecosystem specifically, achieve over 90% bit-for-bit reproducibility across more than 80,000 packages. Reproducibility is the correct primary robustness metric, verified via cryptographic hash comparison. Specification-driven development, backed by formal model checking (TLA+ as used by Sedeve-Kit, Mocket, Splunk, and Datadog), catches classes of design-level defect that testing cannot reach, and reduces implementation drift from design intent. The most defensible quantitative comparison framework for amonite combines reproducibility rate, phantom-dependency rate, and specification-to-implementation divergence — but collecting these figures requires an empirical study designed specifically around amonite's task-capsule model.
