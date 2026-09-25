# 00 — Getting Started

The recommended path to your first interactive training. It is "the hard way" — VS Code + GitHub — until the in-app training generator lands, but every step is doable in an afternoon, and after step 2 most of it will already make sense.

---

## 1. Install the app

Go to Orbital and **register your tenant with an account OAuth client** — the required scopes are listed on the page:

**[autonomous-enablements.whydevslovedynatrace.com/#register](https://autonomous-enablements.whydevslovedynatrace.com/#register)**

The app installs in your tenant as **Dynatrace Enablement**. Orbital uses the client once to install the app and store it in the tenant for token minting and self-updates; Orbital itself keeps nothing.

!!! tip "No tenant of your own?"
    Use the **SE sandbox tenant** — the app is already deployed there.

## 2. Do Kubernetes 101 as a learner

Open the app and run **Kubernetes 101** from start to finish. This is the most important step: it shows you the learner experience you are about to build — the terminal, the checks, the quizzes, the DQL validations and the progress tracking. (The *Show solution* / *Run solution* buttons appear for trainers; learners see them only when a tenant admin turns on **Enable solutions**.)

## 3. Look under the hood

Open the same training in a **GitHub Codespace** or a **VS Code Dev Container**. It is the same image, the same docs and the same pipeline — only the host differs.

**[github.com/dynatrace-wwse/enablement-kubernetes-101](https://github.com/dynatrace-wwse/enablement-kubernetes-101)**

The key files:

| File | What it is |
|---|---|
| `.devcontainer/post-create.sh` | **The most important file** — what gets provisioned when the environment starts. See [02 — Automate the Environment](02-automation.md). |
| `.devcontainer/util/my_functions.sh` | Your own functions: checks, scenario setup, solutions. |
| `.devcontainer/yaml/dt-tokens.yaml` | The tokens the app **mints** before the training starts — names, classic/platform, scopes per token. See [Tokens](02-automation.md#tokens-dt-tokensyaml). |
| `.devcontainer/yaml/dynakube-config.yaml` | Optional override of the default Dynatrace deployment. See [DynaKube](02-automation.md#the-dynakube-defaults-and-your-override). |
| `mkdocs.yaml` + `docs/*.md` | The steps: content, checks, quizzes and solutions. See [03 — Lesson Anatomy](03-lesson-anatomy.md). |
| `.assessment/*.json` | Scored assessments. |

## 4. Clone and adapt

Start from this template (**Use this template → Create a new repository**) or clone Kubernetes 101, then change `post-create.sh` to build *your* scenario. A typical Kubernetes lab with everything deployed automatically:

```bash title=".devcontainer/post-create.sh"
#!/bin/bash
source .devcontainer/util/source_framework.sh

setUpTerminal
startK3dCluster
installK9s

dynatraceDeployOperator
deployApplicationMonitoring   # AppOnly: CSI driver + webhook + log module

deployApp easytrade        # or deployTodoApp, or your own function from my_functions.sh

finalizePostCreation
```

For a worked example of exactly this change — Kubernetes 101 cloned, `post-create.sh` switched to install the operator, the DynaKube and EasyTrade automatically — see the [EasyTrade sample lab `post-create.sh`](https://github.com/sergiohinojosa/easytrade-sample-lab/blob/main/.devcontainer/post-create.sh).

## 5. Use the framework functions, add your own

Every time a shell opens inside the container, the [framework functions](https://dynatrace-wwse.github.io/codespaces-framework/functions/) **and** your `my_functions.sh` are loaded automatically, with autocomplete. The framework gives you `startCluster`, `stopCluster`, `deleteCluster`, `deployApp` (run it bare to list the available apps), `deployDynatrace` / `deployApplicationMonitoring`, and many more.

`my_functions.sh` is where your custom functions sit on top of the framework: deploying your own app, setting up a scenario, the solution for a step, the check for a step. Call them from `post-create.sh`, from the shell, from a check or from a solution — the same logic is reused everywhere, and the framework itself stays untouched.

## 6. Write the content, step by step

The training is just Markdown files. Markdown is the native language of AI tools, and it is also how trainings get imported into the app. Keep steps small, and give **every** step:

- a **validation** — a check against the container, a DQL assertion against Grail, or a quiz;
- a **solution** — so the nightly test can run the step, and so the environment can be recreated at that step.

That is what turns a lab into an **interactive, self-maintaining** training. See [03 — Lesson Anatomy](03-lesson-anatomy.md) and [04 — Interactive Blocks](04-interactive-blocks.md).

To preview the docs while you write, run **`installMkdocs`** in the shell: it installs MkDocs and serves the docs on port 8000 with live reload, so you see every Markdown change as you save.

## 7. Test it on your own

Run it in a **Codespace**, or locally in **VS Code with Dev Containers**. Tips:

- Use **k3d** — the default (`CLUSTER_ENGINE=k3d`), not Kind. Kind does not work in the Docker-in-Docker setup the platform uses to be fast and cheap.
- Locally there is no app to mint tokens: put `DT_ENVIRONMENT`, `DT_OPERATOR_TOKEN` and `DT_INGEST_TOKEN` in `.devcontainer/.env` (gitignored). In a Codespace, use Codespaces secrets.
- Rebuilding a k3d cluster takes seconds (`deleteCluster && startCluster`), so re-run `post-create.sh` often.

See [06 — Test, Publish & Ship](06-test-publish-ship.md).

## 8. Import and run it in the app

Import your repo into the app (**Import Lab** → the GitHub URL, `owner/repo`, or the GitHub Pages URL). Do it once as a **learner**, then run a **workshop** as the **trainer** with a second account — ideally on a second tenant too — so you see both sides: the roster and join code, the live board, and the questions.

## 9. Ship it

Once it is solid, bring the repo into the **dynatrace-wwse** organization so the nightly pipeline picks it up. Then decide how customers get it: self-service, a live workshop series, or both.

---

## First check: is your environment up?

This template is itself an interactive training. The check below runs in *your* container — it is the same `checkNodeReady` helper you will find in `my_functions.sh`:

<!-- LAB_QUESTION
type: shell-verification
question: "Verify the k3d cluster is running in your environment"
buttonText: "Check Cluster"
command: "source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && checkNodeReady"
expect:
  operator: exit-zero
hint: "The cluster is started by post-create.sh. Wait a minute after the environment starts and try again."
explanation: "The cluster is Ready — post-create.sh did its job."
-->

<!-- LAB_NO_SOLUTION: provisioning sanity check — post-create.sh builds the cluster, there is nothing for the learner to fix -->

<div class="grid cards" markdown>
- [01 — How It Works :octicons-arrow-right-24:](01-how-it-works.md)
</div>
