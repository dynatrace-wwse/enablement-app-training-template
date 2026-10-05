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

The guide follows the app's **training editor**: a trainer builds, tests and ships a training entirely inside the app — no VS Code, no Codespace.

| | |
|---|---|
| **00 Getting Started** | install the app, turn on the Training Creator, connect GitHub, take Kubernetes 101 as a learner |
| **01 Open or Fork a Training** | the entry selector: branches, Fork, Create branch, Import from URL |
| **02 Start the Environment** | Start environment, the Workspace, Open terminal, the Provisioning Log |
| **03 Command Center** | run commands, framework functions and DQL against your environment |
| **04 Write and Test Steps** | Source / Preview / Split, Insert, Problems, Test step, Run test, Run validation |
| **05 Recreate the Environment** | Recreate container (replay the solutions up to a step), Recreate from branch, Restart |
| **06 Commit and Open a PR** | Commit, History, Create PR |
| **07 Test as a Learner** | Preview for learners, then the merged training |
| **Reference** | How It Works · Automate the Environment (`post-create.sh`, `my_functions.sh`, `dt-tokens.yaml`, `dynakube-config.yaml`) · Lesson Anatomy · Interactive Blocks · Example Lesson · Publish & Ship |
| **Appendix** | optional: VS Code, Codespaces, local Dev Containers, MkDocs |

## Use this template

1. In the app's **Editor**, open *App Training Template* and choose **Fork to my account** (or, on GitHub, **Use this template → Create a new repository**, `enablement-<topic>`).
2. Follow the guide in the editor; replace the example content with yours.
3. Validate, open a pull request, take it as a learner and as a trainer, then bring it into `dynatrace-wwse`.

Framework documentation: [dynatrace-wwse.github.io/codespaces-framework](https://dynatrace-wwse.github.io/codespaces-framework)
