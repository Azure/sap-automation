# Plan, test, and apply by execution surface

Use the documented behavior for the operator's selected surface and stage.

| Stage | Local | Azure DevOps | GitHub Actions |
| --- | --- | --- | --- |
| Control plane | The documented command displays plans and asks for approval before apply. | Current docs do not treat the `test` input as a verified plan-only gate. | Current docs do not treat the dry-run input as a verified plan-only gate. |
| Workload zone | The documented command displays the plan and asks for approval. | `test: true` produces a plan-only run; rerun with test disabled to apply. | Enable the test option, review the plan, then rerun with test disabled. |
| SAP system | The documented command displays the plan and asks for approval. | `test: true` produces a plan-only run; rerun with test disabled to apply. | Enable the test option, review the plan, then rerun with test disabled. |

Sources:

- `docs/deployment-options.md`
- `docs/local/03-00-control-plane.md`
- `docs/local/04-00-workload-zone.md`
- `docs/local/05-00-sap-system.md`
- The matching Azure DevOps or GitHub Actions operator guide

Do not infer one surface's plan behavior from another surface.
