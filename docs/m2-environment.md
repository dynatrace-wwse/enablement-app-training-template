# 09 — The Environment: post-create, Functions and the Ingress

A hands-on training's environment is **code in `.devcontainer/`**, built the same way in the app (Orbital), a Codespace or a local Dev Container. Three files carry it; the full reference is [Automate the Environment](02-automation.md).

| File | Runs | Your job |
|---|---|---|
| `post-create.sh` | once, when the environment is created — on Orbital before the learner sees anything | call functions: cluster, Dynatrace, apps, scenario. End with `finalizePostCreation` |
| `post-start.sh` | after post-create, and on every restart | bring back what a restart loses |
| `util/my_functions.sh` | **sourced** into every shell: post-create, the terminal, every check and every solution | your training's functions — checks (`checkX`), solutions, scenarios |

The framework's own functions (`functions.sh`, pinned by `FRAMEWORK_VERSION` in `util/source_framework.sh`) are loaded first, so `my_functions.sh` can call them and **override** one with a function of the same name. Never edit the framework's file in your repo — `sync push-update` replaces it.

!!! warning "`return`, never `exit`"
    `my_functions.sh` is *sourced*. An `exit` in a function closes the learner's shell — and fails the check that called it. Use `return 1`.

## What this training's `post-create.sh` builds

```bash title=".devcontainer/post-create.sh (the active lines)"
source .devcontainer/util/source_framework.sh
setUpTerminal          # zsh, the prompt, the greeting
startK3dCluster        # a one-node k3d Kubernetes cluster
installK9s
deployTodoApp          # the demo app — ends with registerApp, so it gets an ingress
finalizePostCreation   # installDevTools (dtctl + Monaco), log check, tracker — do not remove
```

`finalizePostCreation` is the line every repo keeps: it installs the dev tools ([next module](m3-dtctl-monaco.md)), scans the creation log for errors (shown in the greeting) and records the instantiation.

## Apps are published through the ingress

Every app is reachable in the browser the same way everywhere because the framework exposes it through an **nginx ingress**, never a NodePort. One call does it:

```bash
registerApp <app-name> <namespace> <service> <port>   # e.g. registerApp "todoapp" "todoapp" "todoapp" 8080
```

`registerApp` creates the Ingress and adds the app to the app registry. The URL depends on where the environment runs: on Orbital a per-environment subdomain (`<app>--<job>.autonomous-enablements…`), in a Codespace the forwarded port, locally a magic-DNS `sslip.io` name. The editor's Workspace tab lists them under **Registered apps**, each with **Open App** — you never hard-code a URL in a step.

## Check: the cluster and the app

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the TODO app is running"
buttonText: "Check TODO app"
command: "checkTodoAppRunning"
expect:
  operator: exit-zero
hint: "post-create.sh deploys the TODO app; it may still be starting. Wait a minute and check again."
explanation: "deployTodoApp ran in post-create.sh and its pods are Running."
-->

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the TODO app is published through the ingress"
buttonText: "Check ingress"
command: "checkTodoAppIngress"
expect:
  operator: exit-zero
hint: "deployTodoApp ends with registerApp, which creates the Ingress. If the app is still starting, wait and check again."
explanation: "registerApp created an Ingress in the todoapp namespace — that is how the app opens in the browser."
-->

<!-- LAB_QUESTION
type: multiple-choice
question: "Where should a check that a learner's step worked live?"
options:
  - "Inline in the Markdown, as a long kubectl pipeline"
  - "In my_functions.sh, as a function the check's command calls"
  - "In the framework's functions.sh"
  - "In post-start.sh"
correct: 1
explanation: "A function in my_functions.sh keeps the page readable and is reused by the check, the solution's verify and the nightly test. The framework's file is replaced on every sync."
-->

<!-- LAB_NO_SOLUTION: read-only checks of what post-create.sh built — nothing to solve -->
