# SDAF documentation conventions

Use these conventions for repository documentation across the SAP Deployment
Automation Framework (SDAF) repositories. They keep the three execution models
comparable without implying that their automation is identical.

## Organize content by user outcome

Select an execution model from the unnumbered central hub. Then use this
lifecycle vocabulary for the ordered GitHub Actions, Azure DevOps, and local
journeys:

1. Plan architecture, access, networking, quota, cost, and support.
2. Bootstrap the deployment environment.
3. Configure, review, deploy, and validate the control plane.
4. Configure, review, deploy, and validate a workload zone.
5. Configure, review, deploy, and validate an SAP system.
6. Acquire SAP software and run configuration and installation.
7. Operate, update, troubleshoot, recover, and remove resources.

Keep platform-neutral concepts in `Azure/sap-automation`. Keep detailed
platform procedures with the repository that owns the executable asset.

## Use the common page structure

Every procedural page must include the sections that apply to its task:

1. **Outcome**: State what the user has when the procedure is complete.
2. **Before you begin**: List permissions, dependencies, and required state.
3. **Inputs**: Identify files, variables, names, credentials, and decisions.
4. **What the automation does**: Name the workflow, pipeline, or script and
   the artifacts that it changes.
5. **Review before execution**: Call out security, networking, cost, state,
   and destructive effects.
6. **Run**: Provide ordered actions with defined placeholders.
7. **Validate**: Provide observable evidence of success.
8. **If it fails**: Identify the first diagnostic location and safe retry
   behavior.
9. **Next step**: Link to one primary continuation.

Do not include an empty section. Combine short conceptual sections when doing
so improves scanning without hiding required information.

## Write procedures

Follow the
[Microsoft Learn style and voice quick start](https://learn.microsoft.com/contribute/content/style-quick-start):

- Focus on the user's intent and expected outcome.
- Use active voice and direct instructions.
- Use short sentences and consistent terminology.
- Use sentence case for titles and headings.
- Put important information first.
- Number ordered actions.
- Use one primary action per step.
- State the expected result after an action.
- Split a procedure that has more than approximately 12 steps.
- Put prerequisites, explanation, warnings, and decision criteria before the
  steps they affect.
- Do not interrupt steps with commentary or asides.
- Write for scanning, localization, and machine translation.

Define every placeholder before a command. State the directory or host where
the user runs the command. Do not publish a command until it has been checked
against the current source.

## Number journey pages

Use `NN-00-topic.md` for ordered top-level journey pages. For example, use
`03-00-control-plane.md`.

Insert pages within a stage in increments of ten:

- `03-10-review-control-plane-plan.md`
- `03-20-validate-control-plane.md`

Keep `README.md`, `index.md`, reference pages, and troubleshooting pages
unnumbered when they are not ordered steps. Avoid renumbering later stages
when you insert content.

## Document capability differences

Parity means that each supported execution model explains how to complete an
applicable lifecycle outcome. Parity does not require identical procedures or
automation.

For each capability, state:

- What the platform automates.
- What the user prepares or performs.
- Which source asset implements the behavior.
- Whether a direct equivalent exists in the other models.
- Whether the alternative is manual, sample-based, Web application-assisted,
  or owned by another repository.

Use factual labels such as **No direct equivalent**, **Manual preparation**,
or **Generated from samples**. Do not copy a platform-specific command into
another model to create artificial parity. Do not describe one supported
model as recommended, primary, modern, or best.

## Identify files and state

Distinguish the following items whenever they appear in a procedure:

- Source templates.
- Generated configuration.
- Customer-approved edits.
- Terraform state.
- Persistent logs and deployment outputs.
- Transient runner, agent, or workstation artifacts.

State which repository owns each item and whether the automation creates,
reads, updates, or deletes it.

## Validate documentation changes

Before you submit a documentation change:

1. Verify every workflow, pipeline, script, command, variable, and sample path
   against the current source.
2. Record the validation source in
   [Documentation source map](documentation-source-map.md) when the change
   affects a central capability statement.
3. Test every relative link and heading anchor.
4. Confirm that copied commands use valid syntax and defined placeholders.
5. Confirm that GitHub Actions, Azure DevOps, and local execution receive
   neutral treatment.
6. Review warnings at the point where the user makes the affected decision.
7. Review the diff for accidental source-code, generated-file, or support
   policy changes.

After these steps, each statement is traceable to an owning source asset and
the change is ready for technical and editorial review.
