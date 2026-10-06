# Reference — Publish & Ship

From a merged pull request to a training the dynatrace-wwse nightly pipeline keeps green. Testing and the pull request itself happen in the editor: [04 — Write and Test Steps](write-and-test.md), [06 — Commit and Open a PR](commit-and-pr.md) and [07 — Test as a Learner](test-as-learner.md). Building the MkDocs site and testing in a Codespace are in the [appendix](outside-the-app.md).

---

## What happens on merge

`main` is protected: every change reaches it through a pull request. On the pull request the repository's **integration test** runs `.devcontainer/test/integration.sh` — it builds the environment and asserts what `post-create.sh` must have built (`assertRunningPod`, `assertRunningApp`, … from the framework's `test_functions.sh`; see the [appendix](outside-the-app.md#branch-pr-and-the-integration-test-from-the-command-line)). Merging to `main` publishes the GitHub Pages site automatically (`.github/workflows/deploy-ghpages.yaml`).

A training that is not in the app yet is brought in with **Import Lab** — `owner/repo`, the GitHub URL or the GitHub Pages URL; the app reads `main`. (Private repos import through the catalog's content service; a hand import of a private repo needs a GitHub token.)

## After every publish: refresh the app and verify

**After publishing, open the Enablement App workspace, refresh the application, and verify that the documentation reflects the latest changes.** A merge to `main` updates GitHub Pages, but a training that is already in the app keeps the content it was imported with until it is refreshed. The app imports the raw Markdown at a commit, not the Pages site.

1. Open the **Dynatrace Enablement** app in your tenant and go to **Administration** (the gear icon in the header).
2. Refresh the training:
    - **Delivered by the catalog** (a dynatrace-wwse repo in `repos.yaml`): press **Refresh content**. It re-imports every training whose commit changed and skips the rest. Orbital sees a new commit within about a minute of the merge; if the summary says your repo was skipped as unchanged, wait a minute and press it again.
    - **Imported by hand**: under **Import your own lab**, enter the same repository URL and press **Import lab**. The existing training is updated in place. If `main` has not moved since the last import, the import is skipped as unchanged.
    - **Force re-import** re-imports every catalog training, changed or not. Use it only if a refresh did not pick up a change you can see on `main`.
3. Open the training from the **Catalog** and go to the step you changed.
4. Confirm that the step shows the new content: the text, the checks, the solution and, on the last page, the assessment. If it still shows the old version, check that the merge landed on `main`, then refresh again.

Also check that the **deploy mkdocs to github pages** workflow run for the merge is green and that the published site shows the change. That site is what learners see outside the app.

## Ship it into dynatrace-wwse

When it is solid, bring the repo into the **dynatrace-wwse** organization and ask for it to be added to the catalog ([`repos.yaml`](https://github.com/dynatrace-wwse/codespaces-framework/blob/main/repos.yaml)). From then on:

- the nightly **integration-test** builds the environment and runs `integration.sh`;
- a repo tagged **`enablement-app`** also gets the nightly **training-test**: a real session with minted tokens, every section's `STEP_SETUP` → `LAB_SOLUTION` → `verify` → shell **and** DQL checks, section by section;
- framework updates reach your repo as automatic sync PRs.

Then decide how customers get it: **self-service**, a **workshop series**, or both.

## Before you ask for review

- [ ] Every step has a check (shell, DQL or quiz)
- [ ] Every step that changes the environment has a `LAB_SOLUTION` whose `verify` proves it; every other step has `LAB_NO_SOLUTION`
- [ ] Every check fails before its step and passes after its solution (Command center, then **Test step**)
- [ ] **Recreate container** on the last step replays every earlier solution without a stop
- [ ] Every DQL check has `from:` and `endsWith(k8s.cluster.name, "{{DT_SESSION_ID}}")`
- [ ] No interactive block sits inside a code fence
- [ ] `dt-tokens.yaml` (if any) lists **every** token, including operator and ingest
- [ ] `.assessment/*.json` is valid JSON, its `id` matches the `LAB_QUESTIONAIRE` line, and it is bound once, on the last page
- [ ] **Problems** shows no errors, and the head is **Validated ✓**
- [ ] `installMkdocs` / `exposeMkdocs` are commented out in `post-create.sh` / `post-start.sh`
- [ ] Taken once as a learner (**Preview for learners**) and once as a workshop trainer
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
- [Appendix — Working Outside the App :octicons-arrow-right-24:](outside-the-app.md)
- [Final Assessment :octicons-arrow-right-24:](07-final-assessment.md)
</div>
