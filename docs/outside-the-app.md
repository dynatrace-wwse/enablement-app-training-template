# Appendix — Working Outside the App

**Optional.** Everything in this training can be done in the app's editor. This page is for authors who prefer their own tools, or who need something the editor does not offer yet: the same repository opened in **VS Code**, a **GitHub Codespace** or a local **Dev Container**, and the MkDocs site built by hand. It is the same image, the same `post-create.sh`, the same docs — only the host differs (see [How It Works → Codespaces vs. Orbital](01-how-it-works.md#codespaces-vs-orbital-same-container-different-host)).

The editor's equivalents, for orientation:

| Outside the app | In the editor |
|---|---|
| a terminal in VS Code or the Codespace | **Open terminal** (Workspace tab) and the [Command center](command-center.md) |
| `.devcontainer/.env` / Codespaces secrets with your tokens | minted for you from `dt-tokens.yaml` when you press **Start environment** |
| `checkX; echo "exit=$?"` by hand | **Test step**, **Run test**, **Run validation** ([04](write-and-test.md)) |
| `deleteCluster && startCluster`, re-run `post-create.sh` | **Recreate container**, **Recreate from branch** ([05](recreate-environment.md)) |
| `git commit`, `git push`, a PR on GitHub | **Commit**, **Create PR** ([06](commit-and-pr.md)) |
| `installMkdocs`, port 8000 | **Preview** / **Split**, **Problems** |

---

## Open a training in a Codespace or a Dev Container

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

## Start a new training from the template

On GitHub, start from this template (**Use this template → Create a new repository**) or clone Kubernetes 101 — in the editor, **Fork to my account** does the same ([01 — Open or Fork a Training](open-a-training.md)), then change `post-create.sh` to build *your* scenario. A typical Kubernetes lab with everything deployed automatically:

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

## Run it in a Codespace or locally

Run it in a **Codespace**, or locally in **VS Code with Dev Containers**. Tips:

- Use **k3d** — the default (`CLUSTER_ENGINE=k3d`), not Kind. Kind does not work in the Docker-in-Docker setup the platform uses to be fast and cheap.
- Locally there is no app to mint tokens: put `DT_ENVIRONMENT`, `DT_OPERATOR_TOKEN` and `DT_INGEST_TOKEN` in `.devcontainer/.env` (gitignored). In a Codespace, use Codespaces secrets.
- Rebuilding a k3d cluster takes seconds (`deleteCluster && startCluster`), so re-run `post-create.sh` often.



## Preview and build the docs with MkDocs

Validate the rendered site **before** you publish — the same build GitHub Pages runs on merge. In the container's shell (the framework is loaded in every shell):

```bash
installMkdocs
```

That is the framework's `installMkdocs` (the version pinned in `.devcontainer/util/source_framework.sh`). It installs the pinned requirements (`pip install -r docs/requirements/requirements-mkdocs.txt`), fetches `mkdocs-base.yaml` — the shared theme and extensions your `mkdocs.yaml` inherits — and calls `exposeMkdocs`, which serves the docs on **port 8000** with live reload. In a Codespace, open port 8000 from the *Ports* tab; `exposeMkdocs` restarts the server if you need it again.

`installMkdocs` does not fetch the framework stylesheet the published site uses. Fetch it the way the publish workflow does, so the preview looks like GitHub Pages:

```bash
FRAMEWORK_VERSION=$(grep -oP ':-\K[^}"]+' .devcontainer/util/source_framework.sh | head -1)
mkdir -p docs/stylesheets
curl -fsSL "https://raw.githubusercontent.com/dynatrace-wwse/codespaces-framework/${FRAMEWORK_VERSION}/docs/stylesheets/extra.css" \
  -o docs/stylesheets/extra.css
```

(`mkdocs-base.yaml` and `docs/stylesheets/extra.css` are gitignored — never commit them.)

Then validate, in this order:

1. **Build** — the same command the publish workflow runs. It must finish without errors:

    ```bash
    mkdocs build
    ```

2. **Check the links** — MkDocs reports a link to a missing page as a `WARNING`, but a link to a missing *anchor* only as `INFO`, so search for both:

    ```bash
    mkdocs build 2>&1 | grep -E "WARNING|contains a link|anchor"
    ```

    Expect exactly one line, `Unrecognised configuration name: training_name` — the display name Orbital reads, harmless to MkDocs. Any other line is a broken link or anchor: fix it.

3. **Preview** — open port 8000 and read every page you changed: the navigation order, headings, code blocks, admonitions, tables and images.

Keep `installMkdocs` and `exposeMkdocs` **commented out** in `post-create.sh` / `post-start.sh` when the training goes live: learners use the app, and outside the app the published GitHub Pages site (it carries RUM).

!!! note "Interactive blocks do not show in MkDocs"
    `LAB_QUESTION`, `LAB_SOLUTION` and the rest are HTML comments: MkDocs hides them. The preview checks your prose, code, links and layout; the blocks are tested in the app (the editor's **Problems**, **Test step** and **Run validation**).

## Test every check and every solution by hand

In a **Codespace** or a **VS Code Dev Container** (use **k3d**, the default — Kind does not work in the Docker-in-Docker setup):

```bash
# Locally, provide the credentials the app would mint (.devcontainer/.env, gitignored):
#   DT_ENVIRONMENT=https://abc12345.apps.dynatrace.com
#   DT_OPERATOR_TOKEN=dt0c01....
#   DT_INGEST_TOKEN=dt0c01....

source .devcontainer/util/source_framework.sh

checkOperatorReady; echo "exit=$?"     # BEFORE the step: must FAIL (exit=1)
dynatraceDeployOperator                # the step's LAB_SOLUTION commands
LAB_WAIT=1 checkOperatorReady; echo "exit=$?"   # AFTER: must PASS (exit=0)
```

**A check that could never fail proves nothing.** Run each one before its step (it must say no) and after its solution (it must say yes).

For DQL checks: open a **Notebook** in your tenant, paste the query with your own session id in place of `{{DT_SESSION_ID}}` (`echo $DT_HOSTGROUP` in the container prints it), and confirm it returns rows *after* the step and none before.

The cluster is cheap to rebuild — `deleteCluster && startCluster`, then re-run `post-create.sh` — so replay the whole training from a clean state before you publish.

## Branch, PR and the integration test from the command line

`main` is protected. Work on a branch and open a PR (the editor's **Create PR** does the same, see [06 — Commit and Open a PR](commit-and-pr.md)) — the **integration test** runs `.devcontainer/test/integration.sh` on every PR:

```bash title=".devcontainer/test/integration.sh"
#!/bin/bash
source .devcontainer/util/source_framework.sh

assertRunningPod todoapp todoapp     # what post-create.sh must have built
assertRunningApp todoapp
```

The assertions (`assertRunningPod`, `assertRunningApp`, `assertRunningHttp`, …) come from the framework's `test_functions.sh`. Assert what `post-create.sh` builds — not what the learner does in the steps; that is the training-test's job.

Merging to `main` publishes GitHub Pages automatically (`.github/workflows/deploy-ghpages.yaml`); `deployGhdocs` does the same by hand.

<!-- LAB_NO_SOLUTION: optional reference for working outside the app — nothing in the environment changes -->

<div class="grid cards" markdown>
- [Back to the flow: 00 — Getting Started :octicons-arrow-right-24:](00-getting-started.md)
</div>
