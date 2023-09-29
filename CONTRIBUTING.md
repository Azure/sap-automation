
# Table of contents

- [Building "in the Open"](#building-in-the-open)
- [Fully Maintained](#fully-maintained)
- [Execution-focused](#execution-focused)
- [Coding Guidelines](#coding-guidelines)
  - [PR Basics](#pr-basics)
    - [PR guidelines](#pr-guidelines)
    - [Terraform guidelines](#terraform-guidelines)
  - [PR reviews guidelines](#pr-reviews-guidelines)
  - [Release strategy](#release-strategy)

Thanks for taking the time to contribute!
This document summarizes the deployment principles which govern our project.

## Building 'in the open'

- Our users appreciate the transparency of our project; in this context, building "in the open" means that anyone can:
  1- see the individual pull requests this solution is comprised of;
  - understand particular changes by going back and forth between pull requests;
  - submit pull requests with their own changes following the [Coding Guidelines](#coding-guidelines).
- In addition, we use open-source software (OSS) tools rather than proprietary technology to build the solution.

## Fully Maintained

- Rather than providing a loose collection of scripts that are never updated, we fully maintain our project.
- We strive to provide a high-quality solution by:
  - continuously deploying it using an internal runner to ensure performance and stability;
  - detecting regressions introduced by code changes before merging them.

## Execution-focused

- We don't just work on some grand plan that may or never be completely executed;
  - It is encouraged to make changes to gradually improve old codebase to meet standards. However, we are not planning a refactor.
  - we start building out the solution and iterate towards a grand plan.

## Coding Guidelines

This repository integrates with [Azure Pipelines](https://azure.microsoft.com/en-us/services/devops/pipelines/), which invokes build checks on the submitted pull requests aginst defined branch(eg. master). :exclamation: All pull requests are required to pass the Azure pipelines test before it can be merged.

### PR Basics

This section captures fundamentals on how new features should be developed and fixes made to the codebase.

1. **Close on design before sending PRs**

- Add and describe design by creating an issue [here](https://github.com/Azure/sap-automation/issues). Discussions on the design will happen in the issue page.

1. **Design for modularity, easy versioning, easy deployment and rollback**

- The design has to make sure it is independent and has minimum impact on other modules.
- There should be a set of test cases in place to prove the design works and will not break existing code.

### PR guidelines

1. Required information in PR ([example](https://github.com/Azure/sap-automation/pull/480)):
     - Always link to the issue that is is trying to resolve with tag **Closes**.

- Describe the **Problem** that it tries to resolve.
- Provide the **Solution** that this PR contains.
- Provide **Tests** that have been done to make sure this PR does not break existing code (either in master or branch). If the test requires certain instructions, please add that information as well.

1. The PRs should be easily tested independent of other projects in progress.

1. Submit PRs with small commits with **descriptive but not random comments**, so that make it easier to rollback in case of problem.

1. While the commits being small, please also make sure **do not stack up too many commits** (do squash if needed).

#### Terraform guidelines

1. Use `//` for single line comment and `/* */` for block comment.
2. Try to handle complex logic in `variables_local.tf` which comes in every module.
3. Use underscore `_` instead of hyphen `-`. The only place hyphen is used is for resource naming convention.

### PR reviews guidelines

We need to ensure quality along with agility. We need to move to everyone agreeing on the base requirement and then relying on systems in place to catch and mitigate issues.

1. Focus on the [PR Basics](#pr-basics). PRs have to adhere to Basics with no exceptions.
2. In additional to Basics, PR reviews need to focus on the quality of a PR. eg. catching potential issues/bugs, semantic problems, nitpicks, etc...
3. Keep PRs in an open published state for at least one working day, which would allow everyone in other regions to review.
4. For hotfixes, keep PRs open for at least 4 business hrs.
5. The maintainer is [here](https://github.com/Azure/sap-automation/blob/main/CODEOWNERS).

### Release strategy

1. All features should stay in private_preview branch until stable before get into main (eg. `beta/v2.3`)

1. Only merge private_preview branches into master.

1. Create releases of current master before and after merge into master.

1. Releases naming convention: x.x.x-x (eg. `2.3.1-1`)
   - major version number
   - sub version number
   - maintainance version number
   - documentation number
