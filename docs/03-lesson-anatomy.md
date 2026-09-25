# 03 — Lesson Anatomy

A training is a MkDocs site: `mkdocs.yaml` says which pages exist and in what order, and each page is Markdown with interactive blocks written as HTML comments. This page covers the structure; [04 — Interactive Blocks](04-interactive-blocks.md) covers every block.

---

## `mkdocs.yaml` — the steps, in order

```yaml title="mkdocs.yaml"
INHERIT: mkdocs-base.yaml            # theme + extensions from the framework — keep it
training_name: "Kubernetes 101"      # the name Orbital shows for this training
site_name: "Dynatrace Enablement Lab: Kubernetes 101"
repo_name: "View Code on GitHub"
repo_url: "https://github.com/dynatrace-wwse/enablement-kubernetes-101"
nav:
  - "Welcome": index.md
  - "Prerequisites": prerequisites.md
  - "1. Deploy the Operator": 1-deploy-operator.md
  - "2. Deploy the DynaKube": 2-deploy-dynakube.md
  - "3. Restart Application Services": 3-restart-services.md
  - "Resources": resources.md
```

- **`nav` order is step order.** Each `nav` entry becomes one step in the app; a page that is not in `nav` is not imported.
- **One repo, several trainings:** if *every* top-level `nav` entry is a section (a group of pages), each section is imported as its own training.
- The app titles the training from `site_name`; Orbital's catalog prefers `training_name`. Set both. (MkDocs warns about the unknown `training_name` key — that is expected.)

## Front-matter — the catalog card

Put YAML front-matter on the **first** page (`index.md`). It feeds the catalog card and filters, and is invisible to the learner:

```yaml title="docs/index.md"
---
description: Instrument a live Kubernetes cluster with Dynatrace from scratch.
tags: [kubernetes, observability, operator]
difficulty: beginner        # beginner | intermediate | advanced | expert
duration: 90                # minutes
---
```

## The shape of a step

Every step follows the same rhythm — **tell, do, check, solve**:

--8<-- "snippets/blocks/step-anatomy.md"

Top to bottom: an optional `STEP_SETUP` (runs silently when the step opens), the **tell** and **do** in plain Markdown, then the **checks** — one against the container, one against the learner's understanding — and finally the **solution** that lets automation pass the step without a human.

Guidelines that make a training interactive **and** self-maintaining:

1. **Small steps.** One idea, one or two actions, one or more checks.
2. **Every step gets a validation** — a shell check, a DQL check, or a quiz.
3. **Every step that changes the environment gets a `LAB_SOLUTION`.** Without it the nightly test cannot run the step, and resume cannot rebuild the environment past it. A step that changes nothing (reading, a quiz, a provisioning sanity check) says so with a `LAB_NO_SOLUTION` marker.
4. **Put the logic in `my_functions.sh`.** The check calls `checkX`, the solution calls a function — the Markdown stays readable and the logic is reused.
5. **Scope every DQL check to the learner** with `{{DT_SESSION_ID}}` — see [template variables](04-interactive-blocks.md#template-variables-one-query-every-learner-isolated).

## Folder layout

```text
docs/
├── index.md                 ← front-matter + welcome (first nav entry)
├── 1-*.md, 2-*.md, …        ← one file per step
├── resources.md
├── img/                     ← images (referenced relatively: img/x.png)
├── snippets/                ← reusable MkDocs snippets (--8<--)
└── requirements/            ← MkDocs requirements (do not edit)
.assessment/
└── <id>.json                ← scored assessments (LAB_QUESTIONAIRE: <id>)
```

Images are imported with the training — reference them relatively (`img/x.png`) and keep them small.

## Never write a block inside a code example

The app finds interactive blocks by scanning the **raw Markdown** for `<!--` followed by a block name — it does **not** skip fenced code blocks. A "just an example" block inside a ```` ```markdown ```` fence therefore becomes a **real** question, setup or solution in your step. The same goes for inline code: writing a block's full opening comment in a sentence is enough to trigger it.

To show block syntax on a page (as this template does), keep the example in a file under `docs/snippets/` and include it with `--8<-- "snippets/…"`: MkDocs renders it on GitHub Pages, and the app strips snippet includes on import. In prose, name the block (`LAB_SOLUTION`) without its comment opener.

## MkDocs formatting

Admonitions (`!!! tip`, `!!! warning`, …), fenced code blocks, tables and images render both on GitHub Pages and in the app. A ```` ```dql ```` code block renders as a query the learner can open and run. `--8<--` snippet includes and `grid cards` navigation are stripped on import — they are for the GitHub Pages site only.

<!-- LAB_QUESTION
type: multiple-choice
question: "A step asks the learner to restart a deployment. What must it carry so the nightly test and resume can pass it?"
options:
  - "A LAB_SOLUTION whose commands perform the restart and whose verify proves it"
  - "A longer hint on the shell-verification block"
  - "A STEP_SETUP that performs the restart when the step opens"
  - "Nothing — the nightly test only reads the Markdown"
correct: 0
explanation: "Automation cannot click or type. The LAB_SOLUTION commands are what the nightly training-test and resume replay execute; verify proves they worked. A STEP_SETUP would do the learner's work for them."
-->

<!-- LAB_NO_SOLUTION: concept page — nothing in the environment changes -->

<div class="grid cards" markdown>
- [04 — Interactive Blocks :octicons-arrow-right-24:](04-interactive-blocks.md)
</div>
