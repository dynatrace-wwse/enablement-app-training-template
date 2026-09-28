# 06 — Test, Publish & Ship

From your first draft to a training the dynatrace-wwse nightly pipeline keeps green.

---

## 1. Preview and validate the docs locally

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
    `LAB_QUESTION`, `LAB_SOLUTION` and the rest are HTML comments: MkDocs hides them. The preview checks your prose, code, links and layout; the blocks are tested in the steps below.

## 2. Test every check and every solution by hand

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

## 3. Branch, PR, publish

`main` is protected. Work on a branch and open a PR — the **integration test** runs `.devcontainer/test/integration.sh` on every PR:

```bash title=".devcontainer/test/integration.sh"
#!/bin/bash
source .devcontainer/util/source_framework.sh

assertRunningPod todoapp todoapp     # what post-create.sh must have built
assertRunningApp todoapp
```

The assertions (`assertRunningPod`, `assertRunningApp`, `assertRunningHttp`, …) come from the framework's `test_functions.sh`. Assert what `post-create.sh` builds — not what the learner does in the steps; that is the training-test's job.

Merging to `main` publishes GitHub Pages automatically (`.github/workflows/deploy-ghpages.yaml`); `deployGhdocs` does the same by hand.

## 4. Import and run it in the app

1. In the app, **Import Lab** and give it the repo — `owner/repo`, the GitHub URL, or the GitHub Pages URL. The app reads `main`. (Private repos import through the catalog's content service; a hand import of a private repo needs a GitHub token.)
2. Run it once as a **learner**, start to finish: every button, every quiz, and the final assessment.
3. Run a **workshop** as the **trainer** with a second account — ideally on a second tenant — so you see both sides: the roster and join code, the live board, chat and questions, and *Run solution* on a stuck learner.
4. Fix, merge, import again.

## 5. After every publish: refresh the app and verify

**After publishing, open the Enablement App workspace, refresh the application, and verify that the documentation reflects the latest changes.** A merge to `main` updates GitHub Pages, but a training that is already in the app keeps the content it was imported with until it is refreshed. The app imports the raw Markdown at a commit, not the Pages site.

1. Open the **Dynatrace Enablement** app in your tenant and go to **Administration** (the gear icon in the header).
2. Refresh the training:
    - **Delivered by the catalog** (a dynatrace-wwse repo in `repos.yaml`): press **Refresh content**. It re-imports every training whose commit changed and skips the rest. Orbital sees a new commit within about a minute of the merge; if the summary says your repo was skipped as unchanged, wait a minute and press it again.
    - **Imported by hand**: under **Import your own lab**, enter the same repository URL and press **Import lab**. The existing training is updated in place. If `main` has not moved since the last import, the import is skipped as unchanged.
    - **Force re-import** re-imports every catalog training, changed or not. Use it only if a refresh did not pick up a change you can see on `main`.
3. Open the training from the **Catalog** and go to the step you changed.
4. Confirm that the step shows the new content: the text, the checks, the solution and, on the last page, the assessment. If it still shows the old version, check that the merge landed on `main`, then refresh again.

Also check that the **deploy mkdocs to github pages** workflow run for the merge is green and that the published site shows the change. That site is what learners see outside the app.

## 6. Ship it into dynatrace-wwse

When it is solid, bring the repo into the **dynatrace-wwse** organization and ask for it to be added to the catalog ([`repos.yaml`](https://github.com/dynatrace-wwse/codespaces-framework/blob/main/repos.yaml)). From then on:

- the nightly **integration-test** builds the environment and runs `integration.sh`;
- a repo tagged **`enablement-app`** also gets the nightly **training-test**: a real session with minted tokens, every section's `STEP_SETUP` → `LAB_SOLUTION` → `verify` → shell **and** DQL checks, section by section;
- framework updates reach your repo as automatic sync PRs.

Then decide how customers get it: **self-service**, a **workshop series**, or both.

## Before you ask for review

- [ ] Every step has a check (shell, DQL or quiz)
- [ ] Every step that changes the environment has a `LAB_SOLUTION` whose `verify` proves it; every other step has `LAB_NO_SOLUTION`
- [ ] Every check fails before its step and passes after its solution
- [ ] Every DQL check has `from:` and `endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")`
- [ ] No interactive block sits inside a code fence
- [ ] `dt-tokens.yaml` (if any) lists **every** token, including operator and ingest
- [ ] `.assessment/*.json` validates (`python3 -m json.tool`) and its `id` matches the `LAB_QUESTIONAIRE` line
- [ ] `mkdocs build` passes and the link check finds nothing but `training_name`
- [ ] `.assessment/*.json` is bound once, on the last page
- [ ] `installMkdocs` / `exposeMkdocs` are commented out in `post-create.sh` / `post-start.sh`
- [ ] Run once as a learner and once as a trainer in the app
- [ ] After the merge: refreshed in the app, and the changed steps show the latest content

<!-- LAB_QUESTION
type: multiple-choice
question: "Your training passes every check in a Codespace. What does the nightly training-test add?"
options:
  - "It provisions a real session, runs every step's solution and verify, then every shell and DQL check against a real tenant — every night"
  - "It only checks that the Markdown renders on GitHub Pages"
  - "It validates the DQL syntax without running the queries"
  - "Nothing — the integration test already covers the steps"
correct: 0
explanation: "The training-test drives the whole training end to end with the solutions, so a Dynatrace or framework change that breaks a step is caught the next morning."
-->

<!-- LAB_NO_SOLUTION: publishing guide — nothing in the environment changes -->

<div class="grid cards" markdown>
- [Resources :octicons-arrow-right-24:](resources.md)
- [07 — Final Assessment :octicons-arrow-right-24:](07-final-assessment.md)
</div>
