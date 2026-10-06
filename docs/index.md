---
description: How to build interactive, self-testing Dynatrace trainings for the Dynatrace Enablement app — from post-create automation and tokens to checks, solutions and workshops.
tags: [interactive, authoring, orbital, enablement-app]
difficulty: intermediate
duration: 60
---

## Build interactive trainings for the Dynatrace Enablement app

--8<-- "snippets/disclaimer.md"

This is the one place that explains **how to create a training** for the Dynatrace Enablement app *and* **how it works underneath**: what runs when a learner clicks *Start*, where the Dynatrace tokens come from, how the Kubernetes cluster and the DynaKube get built, and how every step becomes a check the platform can verify — for a learner, and for itself every night.

## Content matters most

The platform is the vehicle; the value is in **curated, interactive content**. A training built the interactive way — like the golden example, [Kubernetes 101](https://github.com/dynatrace-wwse/enablement-kubernetes-101) — gives every step a **check, a quiz or an assertion**. The learner is validated against the running container, and against Grail with DQL. That buys three things a slide deck or a static lab never will:

| | What you get |
|---|---|
| **You see who got how far** | Every check, answer and completed step is recorded per learner. You see exactly how far each customer got and whether they understood the concept — not just whether they showed up. |
| **Environments are disposable** | Because every step carries its **solution**, an environment can be shut down to save cost and **recreated at the step where the learner left off**: the platform replays the solutions of the completed steps into a fresh container. |
| **Content stays valid** | Because the solutions are baked into the steps, a pipeline can run the **whole training end to end** — solutions, shell checks and DQL checks against a real tenant — every night. You build it once; the platform keeps proving it still works. |

## How it is delivered

You decide how, and to whom, a training is delivered — per training, and it can be mixed:

- **Self-service** — customers open the app in their own tenant and do the training on their own, at their own pace.
- **Instructor-led workshops** — a roster by email or a workshop join code, a **live board** showing every learner's progress, **chat and raise-hand** for questions, and a shared **Workshop Pad** (welcome notes, solutions, Q&A). Workshops work **across tenants**, so customers join from their own environments.

This is not theoretical: four bootcamps have been delivered with it — one in APAC, two in EMEA and one in NORAM — each with 50 to 100 attendees across multiple tenants.

## Where things stand

Every repository in the worldwide SE GitHub organization ([dynatrace-wwse](https://github.com/dynatrace-wwse)) is already imported into the app — but most are **not interactive yet**. That is the gap this template closes.

You build a training **inside the app**, in its **training editor** (the **Editor** entry in the app's header, *Training Creator*): open or fork the repository, start a live environment, write the steps, test every check and solution, recreate the environment, commit and open a pull request — and then take the training as a learner. No VS Code, no Codespace, no second application. This site follows that flow, one page per step.

VS Code, Codespaces and local Dev Containers still work — the repository is the same — but they are optional. They are collected in one place: [Appendix — Working Outside the App](outside-the-app.md).

## The whole picture in one diagram

```text
 YOUR TRAINING REPO (GitHub)                 DYNATRACE ENABLEMENT APP (learner's tenant)
 ─────────────────────────────               ───────────────────────────────────────────
 mkdocs.yaml + docs/*.md  ── import ───────► steps, quizzes, checks, solutions (UI)
 .assessment/*.json       ── import ───────► scored assessments
 .devcontainer/yaml/dt-tokens.yaml ────────► mints tokens in the learner's tenant
                                                    │
                                                    ▼  (tokens + DT_HOSTGROUP)
                                             ORBITAL — one container per learner
                                             ───────────────────────────────────
 .devcontainer/post-create.sh ─────────────► runs post-create.sh, then post-start.sh
 .devcontainer/util/my_functions.sh ───────► your functions, loaded in every shell
 .devcontainer/yaml/dynakube-config.yaml ──► k3d cluster + Dynatrace Operator + DynaKube + apps
                                                    │
   shell checks / solutions  ◄── terminal ──────────┤
   DQL checks  ◄── Grail ◄── logs, traces, metrics ─┘
```

## Follow the menu in order

The numbered pages are the editor flow, in the order you work:

| Step | Page | What you do |
|---|---|---|
| `00` | [Getting Started](00-getting-started.md) | Install the app, turn on the Training Creator, connect GitHub, take Kubernetes 101 as a learner |
| `01` | [Open or Fork a Training](open-a-training.md) | Pick a training in the editor, fork it or start a branch |
| `02` | [Start the Environment](start-environment.md) | One live container for your branch: terminal, apps, provisioning log |
| `03` | [Command Center](command-center.md) | Run any command, framework function or DQL against that environment |
| `04` | [Write and Test Steps](write-and-test.md) | Source / Preview / Split, Insert, Problems, **Test step**, **Run test**, **Run validation** |
| `05` | [Recreate the Environment](recreate-environment.md) | Rebuild from the branch and replay the solutions up to a step |
| `06` | [Commit and Open a PR](commit-and-pr.md) | Commit to your branch, validate, open the pull request |
| `07` | [Test as a Learner](test-as-learner.md) | Preview for learners, then the real thing after the merge |

The **Reference** pages explain what you write — keep them open beside the editor:

| Page | What it covers |
|---|---|
| [How It Works](01-how-it-works.md) | The app, Orbital and the container — what happens when a learner clicks *Start* |
| [Automate the Environment](02-automation.md) | `post-create.sh`, framework functions, `my_functions.sh`, apps, **tokens** and the **DynaKube** |
| [Lesson Anatomy](03-lesson-anatomy.md) | `mkdocs.yaml`, front-matter, and the shape of a step: content → check → solution |
| [Interactive Blocks](04-interactive-blocks.md) | Every block type: shell and DQL checks, quizzes, solutions, assessments |
| [Example Lesson](05-example-lesson.md) | A complete lesson that uses all of it |
| [Publish & Ship](06-test-publish-ship.md) | Refresh the app after a merge, bring the training into the org |
| [Appendix — Working Outside the App](outside-the-app.md) | Optional: VS Code, Codespaces, local Dev Containers, MkDocs preview |
| [Final Assessment](07-final-assessment.md) | The scored assessment that closes the training |

<div class="grid cards" markdown>
- [Start here: 00 — Getting Started :octicons-arrow-right-24:](00-getting-started.md)
</div>
