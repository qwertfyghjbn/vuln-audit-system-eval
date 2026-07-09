# LLM Audit System Learning

This repository is a benchmark and learning workspace for evaluating LLM-driven code auditing systems. Its language distinguishes between learning a system's mechanism, running a constrained smoke experiment, and conducting a frozen formal evaluation.

## Language

**Learning Run**:
A run whose purpose is to understand a system's mechanism, outputs, and failure modes rather than to produce a comparable score.
_Avoid_: Formal evaluation, benchmark run

**Smoke Experiment**:
A minimal learning run over a very small case set used to prove that a candidate system can run, produce usable output, and justify deeper study.
_Avoid_: Full evaluation, diagnosis batch

**Diagnostic Evaluation**:
A frozen run over a larger case set whose purpose is to characterize failure modes after the smoke experiment has already proven the system worth studying.
_Avoid_: Smoke experiment, full benchmark

**Boundary-Condition Diagnostic Expansion**:
A narrow, constrained learning-stage extension that varies input shape and boundary conditions to quantify where a candidate system remains usable, without turning into a frozen larger-case diagnostic evaluation.
_Avoid_: Diagnostic evaluation, full benchmark expansion

**Contrast Diagnostic Batch**:
A `Learning Run` that keeps one frozen runtime boundary and compares `Official Asset-Chain Case` behavior against `Self Comparison Case` behavior in order to explain where failure layers diverge before any capability-changing variant is introduced.
_Avoid_: Diagnostic evaluation, boundary-condition expansion, formal benchmark batch

**Case**:
One benchmark sample directory under `datasets/` that defines a single target vulnerability scenario.
_Avoid_: Repo, task, sample pack

**Target Vulnerability**:
The primary benchmark vulnerability that a case is designed to represent and that evaluation is aligned against.
_Avoid_: Any finding, general security issue

**Off-target Finding**:
A finding that may describe a real security problem but does not align to the case's target vulnerability.
_Avoid_: Hit, target finding

**Near-miss**:
A case that appears risky on the surface but whose protection or fix should prevent a vulnerability finding.
_Avoid_: Weak hit, partial vulnerability

**Clean Input**:
The benchmark-derived code input prepared for a system under test after removing labels, ground truth, and answer-bearing files.
_Avoid_: Raw case directory, benchmark folder

**Compile Recipe**:
A benchmark-provided build contract that tells the evaluator which Java source files and stub roots belong in a stable code-analysis build for a case.
_Avoid_: Optional hint, build note, full-repo default scan

**Preflight**:
The environment validation stage that must pass before any smoke case is allowed to run.
_Avoid_: Smoke run, case execution

**Native Evaluation Environment**:
The evaluator-controlled local runtime used to prepare clean input, run preflight, and execute a system under evaluation without treating container packaging as the primary orchestration boundary.
_Avoid_: Production deployment, demo container, hosted environment

**Official Version**:
The upstream DeepAudit release and default product flow used without local feature modification.
_Avoid_: Local fork, patched version

**Official Reproduction Learning Batch**:
A small `Learning Run` over upstream, unmodified system behavior whose purpose is to verify whether official cases, assets, and reported outcomes can be reproduced locally before any capability modification or larger diagnostic evaluation.
_Avoid_: Diagnostic evaluation, patched-system experiment, full benchmark reproduction

**Official Asset-Chain Case**:
A case that exists in the upstream IRIS v2 dataset and can be pointed to directly by official metadata or official result assets, so that local reproduction stays within the same provenance chain as the upstream report.
_Avoid_: Locally adapted case, benchmark-derived custom case, mixed-source reproduction case

**Case Role**:
The diagnostic role assigned to a case inside an `Official Reproduction Learning Batch`, such as `anchor`, `contrast`, `differential`, or `control`, so that each selected case answers a distinct reproduction question.
_Avoid_: Generic quota slot, interchangeable sample

**Reproduction Evidence Package**:
The two-layer per-case artifact set that preserves both upstream-produced outputs and evaluator-side reproduction metadata so that local reproduction claims remain auditable.
_Avoid_: Minimal screenshot set, results-only archive, ad hoc log bundle

**Self Comparison Case**:
A locally curated benchmark case from this repository that is intentionally run beside upstream official cases under the same system and model configuration in order to test whether official-case conclusions generalize beyond the upstream asset chain.
_Avoid_: Official case, mixed-provenance case, ad hoc extra sample

**Case Family**:
The stable vulnerability scenario identity used to group multiple runs, reruns, or variants of the same target case so that failure analysis does not over-count high-variance repetitions.
_Avoid_: Single run, duplicate case, per-rerun sample

**Experiment-side Configuration**:
The single authoritative LLM configuration used to drive a run, sourced here from `.env_deepseek` and recorded with the resulting evidence.
_Avoid_: Local override, ad hoc model setting

**Derived System Configuration**:
A system-specific configuration materialization derived from the Experiment-side Configuration so that different systems under evaluation share one authoritative model source while keeping their runtime wiring separate.
_Avoid_: Independent system config, ad hoc env file, second source of truth

**Candidate-selection Dominant**:
A failure classification stating that the decisive blockage occurs because target-adjacent APIs never enter the Stage 3 candidate set, so later LLM labeling and CodeQL path formation never receive the minimum required semantic anchors.
_Avoid_: General model failure, pure query failure, vague no-signal case

**Minimal Target-adjacent Oracle**:
A manually supplied smallest-possible source/sink/summary label set that closes the target vulnerability path for a case family, used to test whether later stages can work once the minimum necessary semantics are present.
_Avoid_: Maximal manual rescue, full handcrafted query, broad expert override

**Architecture Attribution Experiment**:
An independent experiment line, at the same organizational level as a system evaluation line, that isolates workflow-architecture variables such as how strongly static-tool evidence constrains LLM reasoning.
_Avoid_: IRIS variant result, DeepAudit result, system capability score

**Static-tool Constraint Strength**:
The degree to which static-analysis output determines what code, evidence, vulnerability type, or candidate set an LLM is allowed to inspect and reason about during an audit experiment.
_Avoid_: Static tool quality, model quality, general workflow complexity

**Differential Semantic Evaluation**:
An evaluation axis that judges whether a system can explain why a vulnerable/fixed case pair differs, including the vulnerable path, the fixed-side guard or sanitizer, and the minimum semantic change that blocks the target vulnerability.
_Avoid_: Clean negative, no-path success, generic patch summary

## Example Dialogue

Dev: "We are still in a learning run, so this DeepAudit smoke experiment only needs five core cases."

Domain Expert: "Right. Prepare clean input for each case, pass preflight first, and do not confuse an off-target finding with a target vulnerability hit."

Dev: "If DeepAudit reports a real issue outside the benchmark target, I will record it as an off-target finding rather than a successful case result."

Domain Expert: "Exactly. Near-miss cases matter just as much, because they test whether the system understands the guard instead of only spotting dangerous-looking APIs."

Dev: "For IRIS I will use the Native Evaluation Environment, but still generate a Derived System Configuration from the same Experiment-side Configuration."

Domain Expert: "Good. That keeps the runtime controllable without introducing a second model source of truth."

Dev: "This next IRIS batch is an Official Reproduction Learning Batch, not a diagnostic evaluation, because I am only validating whether upstream behavior and official assets reproduce locally."

Domain Expert: "Right. Reproduction comes before judging whether the system is worth a larger frozen diagnostic evaluation."

Dev: "And every selected case must be an Official Asset-Chain Case, otherwise the reproduction claim would mix upstream and local provenance."

Domain Expert: "Exactly. If the case cannot be traced through upstream metadata or official results, it belongs in a different batch."

Dev: "Within that batch, each case also needs a Case Role: one anchor, one contrast, two differential winners, and one control success."

Domain Expert: "Right. Otherwise five official cases just become a grab bag and the reproduction report loses its explanatory power."

Dev: "And each case needs the same Reproduction Evidence Package, not just the final SARIF or results CSV."

Domain Expert: "Exactly. Otherwise you cannot separate LLM behavior from build, database, or metadata drift."

Dev: "For the trustworthiness batch I also need a few Self Comparison Cases, so I can compare official behavior against the cases we actually care about."

Domain Expert: "Right. Without that contrast set, a successful official case only proves that IRIS can handle the upstream asset chain."

Dev: "And when a Java case provides a Compile Recipe, I will treat it as the build contract instead of scanning the whole curated repo by default."

Domain Expert: "Right. Otherwise you would blur the boundary between benchmark intent and accidental repository residue."

Dev: "For the next IRIS learning run, I will score missed results by Case Family rather than by every rerun, so a high-variance case does not dominate the diagnosis."

Domain Expert: "Right. Then you can still annotate rerun variance without confusing repetition with coverage."

Dev: "And I will only call a family Candidate-selection Dominant if the missing target-adjacent APIs never reached Stage 3, but a Minimal Target-adjacent Oracle can restore target-aligned results afterward."

Domain Expert: "Exactly. That separates a candidate boundary failure from a later query-semantics failure."
