# 04 — Publishing & Validation

The steps to go from local edits to a working training inside the Dynatrace app.

---

## 1. Local content preview (MkDocs)

Verify your markdown renders correctly before publishing. Enable MkDocs in `post-create.sh` by uncommenting `installMkdocs`, then rebuild the Codespace. Once running, MkDocs serves on port 8000.

```bash
# In post-create.sh — uncomment for authoring mode:
installMkdocs
```

```bash
# In post-start.sh — uncomment to expose on each start:
exposeMkdocs
```

MkDocs will be visible on port 8000 in the Ports tab. Change any markdown file and the browser reloads automatically.

!!! warning "MkDocs in production"
    Comment `installMkdocs` and `exposeMkdocs` back out before going live. You want learners to hit the GitHub Pages URL (for RUM tracking), not the local MkDocs server.

---

## 2. Validate interactive blocks locally

You can validate `shell-verification` blocks by running the commands manually in the terminal:

```bash
# Run the command from a shell-verification block manually
kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready'
# Expect: integer > 0
```

```bash
# Test a custom function
source .devcontainer/util/source_framework.sh
customFunction
```

```bash
# Validate the DynaKube generation
dynatraceEvalReadSaveCredentials && generateDynakube
cat .devcontainer/yaml/gen/dynakube.yaml
```

---

## 3. Publish to GitHub Pages

Commit your changes to a branch, push, then deploy docs:

```bash
# Stage and commit your changes
git add docs/ .assessment/ mkdocs.yaml
git commit -m "feat: add lesson content for <topic>"
git push origin <your-branch>

# Deploy docs to gh-pages branch (from inside the Codespace)
deployGhdocs
```

`deployGhdocs` builds the MkDocs site and pushes to the `gh-pages` branch. The GitHub Actions workflow `deploy-ghpages.yaml` also triggers this automatically when a PR is merged to `main`.

<!-- LAB_QUESTION
type: shell-verification
question: "Verify your git remote is configured correctly"
buttonText: "Check Git Remote"
command: "git remote get-url origin 2>/dev/null | grep -c 'github.com/dynatrace-wwse'"
expect:
  operator: gt
  value: 0
hint: "Run `git remote -v` in the Terminal to check the remote URL. It should point to your training repo."
explanation: "Git remote is configured — you can push and deploy from this Codespace."
-->

---

## 4. Validate the GitHub Pages URL

After `deployGhdocs` completes, the docs are live at:

```
https://dynatrace-wwse.github.io/<your-repo-name>/
```

Open the URL and verify:
- Navigation menu matches your `mkdocs.yaml` `nav` section
- All pages render correctly
- Images load
- Code blocks are styled
- Admonitions display

!!! note "HTML comment blocks"
    `<!-- LAB_QUESTION ... -->` and `<!-- STEP_SETUP ... -->` blocks are not visible in MkDocs or GitHub Pages — they are invisible HTML comments. They only become interactive when the Dynatrace app parses them.

---

## 5. Register the training in the Dynatrace app

Contact the Orbital administrator to register your training:

1. Provide the **GitHub Pages URL** of your training docs
2. Provide the **container image tag** (if you modified the devcontainer)
3. Provide the **`mkdocs.yaml` nav structure** for lesson menu configuration
4. Specify **required credentials**: `DT_ENVIRONMENT`, `DT_OPERATOR_TOKEN`, `DT_INGEST_TOKEN`

The administrator will:
- Register the training in the Orbital training catalog
- Configure the container provisioning profile
- Wire the lesson URLs to the Dynatrace app enablement plugin
- Test the interactive blocks end-to-end

---

## 6. Validate the Orbital container

Once registered, test each interactive block from inside the Dynatrace app:

1. Open the Dynatrace app → Enablement → find your training
2. Click **Start Environment** — wait for the Orbital container to provision
3. Open each lesson page and click every check button
4. For `dql-verification` blocks: trigger the expected state in the tenant first, then validate
5. Complete the full assessment to verify scoring works
6. Note any failures and fix them in the markdown — redeploy with `deployGhdocs`

For shell command failures, SSH into the Orbital container for debugging:

```bash
# Ask your Orbital administrator for SSH access to the training container
# or use the Terminal tab in the Dynatrace app to run commands interactively
```

---

## 7. Protect `main` and use PRs

The `main` branch is protected — push directly to `main` is blocked. Always:

1. Create a branch: `git checkout -b feat/my-lesson`
2. Commit and push
3. Open a PR
4. Integration tests run automatically via GitHub Actions
5. Merge the PR → GitHub Pages deploys automatically

```bash
# Create a branch
git checkout -b feat/my-lesson

# Commit changes
git add docs/ .assessment/ mkdocs.yaml .devcontainer/util/my_functions.sh
git commit -m "feat: add <topic> lesson with shell/dql/assessment blocks"
git push origin feat/my-lesson

# Open PR via CLI
gh pr create --title "feat: <topic> lesson" --body "## Summary
- Added lesson pages: <list>
- Added assessment: <id>
- All shell-verification and dql-verification blocks tested

## Test plan
- [ ] MkDocs renders locally
- [ ] GitHub Pages updated
- [ ] All check buttons pass in Dynatrace app
- [ ] Assessment scoring works"
```

---

## 8. Branch protection and integration tests

The integration test workflow (`.github/workflows/integration-tests.yaml`) runs `.devcontainer/test/integration.sh` on every PR. Add assertions for your training's expected state:

```bash
# .devcontainer/test/integration.sh
source .devcontainer/util/source_framework.sh

assertRunningPod dynatrace operator
assertRunningPod todoapp todoapp

printInfoSection "Integration tests passed"
```

---

!!! success "Ready to ship"
    Your training is authored, deployed to GitHub Pages, registered with Orbital, and validated in the Dynatrace app. New learners can now find it in the Enablement catalog.

<div class="grid cards" markdown>
- [Resources :octicons-arrow-right-24:](resources.md)
</div>
