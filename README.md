<!-- markdownlint-disable-next-line -->
# <img src="https://cdn.bfldr.com/B686QPH3/at/w5hnjzb32k5wcrcxnwcx4ckg/Dynatrace_signet_RGB_HTML.svg?auto=webp&format=pngg" alt="DT logo" width="30"> Enablement App Training Template

[![Dynatrace](https://img.shields.io/badge/Dynatrace-Intelligence-purple?logo=dynatrace&logoColor=white)](https://dynatrace-wwse.github.io/codespaces-framework/dynatrace-integration/#mcp-server-integration)
[![Mastering](https://img.shields.io/badge/Mastering-Complexity-8A2BE2?logo=dynatrace)](https://dynatrace-wwse.github.io)
[![Downloads](https://img.shields.io/docker/pulls/shinojosa/dt-enablement?logo=docker)](https://hub.docker.com/r/shinojosa/dt-enablement)
[![Integration tests](https://github.com/dynatrace-wwse/enablement-app-training-template/actions/workflows/integration-tests.yaml/badge.svg)](https://github.com/dynatrace-wwse/enablement-app-training-template/actions)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?color=green)](https://github.com/dynatrace-wwse/enablement-app-training-template/blob/main/LICENSE)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live-green)](https://dynatrace-wwse.github.io/enablement-app-training-template/)

[![Version](https://img.shields.io/github/v/release/dynatrace-wwse/enablement-app-training-template?color=blueviolet)](https://github.com/dynatrace-wwse/enablement-app-training-template/releases)
[![Commits](https://img.shields.io/github/commits-since/dynatrace-wwse/enablement-app-training-template/latest?color=ff69b4&include_prereleases)](https://github.com/dynatrace-wwse/enablement-app-training-template/graphs/commit-activity)
___

**The one place to learn how to build interactive trainings for the Dynatrace Enablement app — and how they work underneath.**

📖 **Read it here: [dynatrace-wwse.github.io/enablement-app-training-template](https://dynatrace-wwse.github.io/enablement-app-training-template/)**

Content matters most. A training built the interactive way — like [Kubernetes 101](https://github.com/dynatrace-wwse/enablement-kubernetes-101) — gives every step a check against the learner's container or Grail, and a solution. That lets you see how far each learner got, lets environments be shut down and recreated at the step a learner left off, and lets the platform test the whole training end to end every night.

## What the guide covers

| | |
|---|---|
| **00 Getting Started** | the path: install the app → do Kubernetes 101 → look under the hood → clone & adapt → write → test → import → ship |
| **01 How It Works** | import, token minting, the Orbital container, checks, resume, the nightly test, workshops |
| **02 Automate the Environment** | `post-create.sh`, framework functions, `my_functions.sh`, apps, **`dt-tokens.yaml`**, **`dynakube-config.yaml`** |
| **03 Lesson Anatomy** | `mkdocs.yaml`, front-matter, the shape of a step |
| **04 Interactive Blocks** | `shell-verification`, `dql-verification`, `multiple-choice`, `LAB_SOLUTION`, `STEP_SETUP`, `LAB_QUESTIONAIRE`, … |
| **05 Example Lesson** | a complete, runnable lesson |
| **06 Test, Publish & Ship** | `installMkdocs`, testing checks and solutions, the nightly pipeline, a review checklist |

## Use this template

1. **Use this template → Create a new repository** (`enablement-<topic>`).
2. Open it in a Codespace or a VS Code Dev Container.
3. Follow the guide; replace the example content with yours.
4. Import it into the app, test it as learner and trainer, then bring it into `dynatrace-wwse`.

Framework documentation: [dynatrace-wwse.github.io/codespaces-framework](https://dynatrace-wwse.github.io/codespaces-framework)
