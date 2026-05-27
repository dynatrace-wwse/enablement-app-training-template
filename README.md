<!-- markdownlint-disable-next-line -->
# <img src="https://cdn.bfldr.com/B686QPH3/at/w5hnjzb32k5wcrcxnwcx4ckg/Dynatrace_signet_RGB_HTML.svg?auto=webp&format=pngg" alt="DT logo" width="30"> Enablement App Training Template

[![Dynatrace](https://img.shields.io/badge/Dynatrace-Intelligence-purple?logo=dynatrace&logoColor=white)](https://dynatrace-wwse.github.io/codespaces-framework/dynatrace-integration/#mcp-server-integration)
[![Mastering](https://img.shields.io/badge/Mastering-Complexity-8A2BE2?logo=dynatrace)](https://dynatrace-wwse.github.io)
[![Downloads](https://img.shields.io/docker/pulls/shinojosa/dt-enablement?logo=docker)](https://hub.docker.com/r/shinojosa/dt-enablement)
[![Integration tests](https://github.com/dynatrace-wwse/enablement-app-training-template/actions/workflows/integration-tests.yaml/badge.svg)](https://github.com/dynatrace-wwse/enablement-app-training-template/actions)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?color=green)](https://github.com/dynatrace-wwse/enablement-app-training-template/blob/main/LICENSE)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live-green)](https://dynatrace-wwse.github.io/enablement-app-training-template/)

___

**Trainer-authoring scaffold for building interactive Dynatrace in-app enablement trainings.**

This template lets Solutions Engineers and content authors create scored, interactive trainings that run on the **Orbital Operations server** and render inside the **Dynatrace app** — without reverse-engineering an existing training.

## What this template gives you

- **5-lesson trainer guide** — follow in order to understand the authoring model and produce your first lesson in ~30 minutes
- **Working examples** of every interactive block type: shell verification, kubectl (interactive + non-interactive), custom helper functions, DQL queries, DQL validation, and scored assessments
- **Docs** — `docs/AUTHORING.md` (schema reference), `docs/ORBITAL_AND_APP.md` (runtime architecture), `docs/REFERENCE_KUBERNETES_101.md` (mechanism inventory from the reference training)
- **Example assessment** — `.assessment/template-authoring-fundamentals.json` — a live, scored quiz the trainer can use as a pattern
- **Full devcontainer** — same k3d + Dynatrace Operator environment as all other enablement repos

## How to use this template

1. Click **Use this template** → **Create a new repository**
2. Name your repo `enablement-<topic>` in the `dynatrace-wwse` org
3. Open in GitHub Codespaces
4. Follow the lesson menu in order: `00 → 04`
5. Replace the example content with your training's content
6. Deploy to GitHub Pages with `deployGhdocs`
7. Contact the Orbital administrator to register your training

## Reference training

The mechanisms in this template were extracted from [`enablement-kubernetes-101`](https://github.com/dynatrace-wwse/enablement-kubernetes-101) — the canonical example of an interactive Dynatrace in-app training. See `docs/REFERENCE_KUBERNETES_101.md` for the complete inventory.

## Framework documentation

Full framework docs: [https://dynatrace-wwse.github.io/codespaces-framework](https://dynatrace-wwse.github.io/codespaces-framework)

<p align="center">
<img src="docs/img/dt_professors.png" alt="Trainers" width="400"/>
</p>

## [🎓 Start authoring: Open the template guide](https://dynatrace-wwse.github.io/enablement-app-training-template)
