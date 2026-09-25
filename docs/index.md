---
description: How to build interactive, self-testing Dynatrace trainings for the Dynatrace Enablement app — from post-create automation and tokens to checks, solutions and workshops.
tags: [authoring, orbital, enablement-app]
difficulty: intermediate
duration: 60
---

# Build interactive trainings for the Dynatrace Enablement app

--8<-- "snippets/disclaimer.md"

This is the one place that explains **how to create a training** for the Dynatrace Enablement app *and* **how it works underneath**: what runs when a learner clicks *Start*, where the Dynatrace tokens come from, how the Kubernetes cluster and the DynaKube get built, and how every step becomes a check the platform can verify — for a learner, and for itself every night.

[hs-video](https://autonomous-enablements.whydevslovedynatrace.com/videos/enablement/app/authoring-overview.mp4%7CEnablement%20Authoring%20Overview%7CHow%20to%20build%20interactive%20Dynatrace%20in-app%20trainings%20with%20this%20template.)

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

Every repository in the worldwide SE GitHub organization ([dynatrace-wwse](https://github.com/dynatrace-wwse)) is already imported into the app — but most are **not interactive yet**. That is the gap this template closes. An in-app training generator is on the way; until it lands, a training is built "the hard way" — VS Code + GitHub — and this site walks you through it.

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

| Step | Page | What you get |
|---|---|---|
| `00` | [Getting Started](00-getting-started.md) | The recommended path, from installing the app to shipping your training |
| `01` | [How It Works](01-how-it-works.md) | The app, Orbital and the container — what happens when a learner clicks *Start* |
| `02` | [Automate the Environment](02-automation.md) | `post-create.sh`, framework functions, `my_functions.sh`, apps, **tokens** and the **DynaKube** |
| `03` | [Lesson Anatomy](03-lesson-anatomy.md) | `mkdocs.yaml`, front-matter, and the shape of a step: content → check → solution |
| `04` | [Interactive Blocks](04-interactive-blocks.md) | Every block type, live: shell and DQL checks, quizzes, solutions, assessments |
| `05` | [Example Lesson](05-example-lesson.md) | A complete lesson that uses all of it |
| `06` | [Test, Publish & Ship](06-test-publish-ship.md) | Preview live, test locally and in the app, bring it into the org |

<div class="grid cards" markdown>
- [Start here: 00 — Getting Started :octicons-arrow-right-24:](00-getting-started.md)
</div>
