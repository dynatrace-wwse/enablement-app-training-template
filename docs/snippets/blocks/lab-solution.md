```markdown
<!-- LAB_SOLUTION
reveal: |
  The TODO app started before the Dynatrace webhook existed, so it was never
  injected. Restart it: `kubectl rollout restart deployment -n todoapp`.
commands:
  - restartTodoApp
verify:
  - source .devcontainer/util/source_framework.sh >/dev/null 2>&1 && LAB_WAIT=1 checkOneAgentInjected
-->
```
