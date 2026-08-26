# State-management safety

Use `docs/local/07-00-operations.md § Manage state safely` and
`docs/local/troubleshooting.md § Terraform reports a state lock`.

## Required sequence

1. Back up the authoritative remote-state blob.
2. Back up local backend metadata.
3. Confirm subscription, resource group, storage account, container, and key.
4. Preserve lock details and prove no concurrent process owns the state.
5. Review the checked-out state-management command's help.
6. List state before considering import or remove.
7. Confirm the exact Terraform address and Azure resource ID.
8. Re-list state after an approved repair and retain all evidence.

## Boundaries

- State removal stops Terraform managing an object; it does not delete Azure resources.
- Teardown belongs to `sdaf-safe-removal`.
- An ambiguous failed run belongs to `sdaf-failure-triage`.
- Never use state edits to hide an unexpected replacement or incomplete removal.
- If documentation, state output, and Azure identity do not agree, stop.
