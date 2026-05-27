# Enablement App Training Template

Welcome to the **Dynatrace Enablement App Training Template** — a trainer-facing scaffold for building interactive, scored trainings that run on the **Orbital Operations server** and render inside the **Dynatrace app**.

[hs-video](https://autonomous-enablements.whydevslovedynatrace.com/videos/enablement/app/authoring-overview.mp4%7CEnablement%20Authoring%20Overview%7CHow%20to%20build%20interactive%20Dynatrace%20in-app%20trainings%20with%20this%20template.)

## What you will build

A complete interactive lesson that:

| Capability | How |
|---|---|
| Runs shell commands against a live Kubernetes cluster | `shell-verification` blocks |
| Runs `kubectl` commands interactively and non-interactively | Terminal tab + `shell-verification` |
| Validates state in the learner's Dynatrace tenant | `dql-verification` blocks |
| Scores the learner with a timed, multi-question assessment | `.assessment/*.json` + `boundScenarioId` |
| Exposes custom helper functions trainers can extend | `.devcontainer/util/my_functions.sh` |
| Renders inside the Dynatrace app connected to a live Orbital container | Orbital runtime wiring |

## Follow this menu in order

| Step | Topic | What you get |
|---|---|---|
| `00` | Getting Started for Trainers | How Orbital + the Dynatrace app work, what the authoring loop looks like |
| `01` | Lesson Anatomy | Frontmatter, markdown structure, block types, lifecycle |
| `02` | Interactive Building Blocks | One runnable example per block type |
| `03` | Example Lesson | A complete minimal lesson using everything |
| `04` | Publishing & Validation | Local testing, Orbital validation, shipping to the Dynatrace app |

!!! tip "30-minute path to your first lesson"
    A trainer who follows this menu in order will have a working interactive lesson — running on Orbital, rendered inside the Dynatrace app — within approximately 30 minutes.

!!! info "Reference doc"
    See `docs/REFERENCE_KUBERNETES_101.md` for the complete inventory of every interactive mechanism extracted from the `enablement-kubernetes-101` reference training.

<div class="grid cards" markdown>
- [Start here: 00 — Getting Started :octicons-arrow-right-24:](00-getting-started.md)
</div>
