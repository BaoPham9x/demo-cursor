# Steep-as-code Agent Example

This repository is a compact example showing how an AI coding agent with
repository access can generate Steep-as-code YAML from dbt-style marts, business
context, and optional warehouse access.

## Start Here

Open this repository in your coding agent, point it at
[agent-guidance.md](agent-guidance.md), and ask:

```text
Build the Steep semantic layer for this repo. Inspect the repo first, ask for
missing business context only when it changes the metrics, generate or update
modules/*.yaml, validate the YAML, create a branch, commit, push, and tell me
which branch to select in Steep.
```

`agent-guidance.md` is the only agent instruction file. It includes the workflow,
business-context questions, example Acme Pay context, technical setup notes,
Steep YAML rules, join-path guidance, metric patterns, validation checklist, and
final-response expectations.

## Repository Map

- [agent-guidance.md](agent-guidance.md): full instructions for the agent.
- [star-schema/models/marts/schema.yml](star-schema/models/marts/schema.yml):
  dbt model and column docs, examples, join hints, and reference metric recipes.
- [star-schema/models/marts/](star-schema/models/marts): mart SQL when the agent
  needs to inspect grain or column lineage.
- [star-schema/dbt_project.yml](star-schema/dbt_project.yml): dbt project
  configuration.
- [star-schema/models/sources.yml](star-schema/models/sources.yml): source
  table definitions.
- `modules/`: Steep-as-code YAML output created by the agent.

## Customize For A Real Workspace

Before asking the agent to generate metrics for a real workspace, replace the
example business context and schema details in [agent-guidance.md](agent-guidance.md)
and [star-schema/models/marts/schema.yml](star-schema/models/marts/schema.yml).
The example currently uses Acme Pay, a B2B SMB neobank.

Mart SQL under `star-schema/models/marts/` references the example BigQuery
project and dataset `steep-demo.steep_demo_v2`. Replace those names before
running dbt against your own warehouse. For an example run without BigQuery, the
agent can rely on `schema.yml` and the mart SQL files.

## Technical Setup

For a fresh macOS machine, ask the agent:

```text
Audit this machine and install missing developer requirements so an AI coding
agent can run this repo. Ask before each install step. Prefer Homebrew. Do not
modify project code, commit, or push anything. Check Xcode command line tools,
Homebrew, git, GitHub CLI, Node.js, pnpm, Python 3, pipx, jq, yq, and optionally
Docker. Authenticate interactive tools with me in the loop, especially gh auth
login. Print installed versions, skipped or failed steps, and manual follow-up
commands.
```

## Steep Help Center

- [Define in Code](https://help.steep.app/setup-and-manage/define-in-code):
  GitHub connection and sync behavior.
- [Code Reference](https://help.steep.app/setup-and-manage/code-reference):
  module, dimension, join path, filter, slice, and metric YAML.
- [App-to-Code Migration Guide](https://help.steep.app/setup-and-manage/app-to-code-migration-guide):
  preserve identifiers when moving existing Steep app definitions into code.
