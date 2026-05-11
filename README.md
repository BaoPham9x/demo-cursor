# Steep-as-code Agent Example

This repo is a compact example showing how an AI coding agent with repository
access can generate Steep-as-code YAML from dbt-style marts, business context,
and optional warehouse access.

## Start Here

Use one guidance file: [agent-guidance.md](agent-guidance.md). It is written for
the agent to follow directly.

Open this repo in your coding agent, point it at `agent-guidance.md`, and ask:

```text
Build the Steep semantic layer for this repo. Inspect the repo first, ask for
missing business context only when it changes the metrics, generate or update
modules/*.yaml, validate the YAML, create a branch, commit, push, and tell me
which branch to select in Steep.
```

`agent-guidance.md` is intentionally the source of truth. The rest of the repo is
example input data for the agent.

## What To Customize

- [business-context.md](business-context.md): company story, teams, KPI
  questions, owners, categories, default slices, and sensitive-field deny list.
- [star-schema/models/marts/schema.yml](star-schema/models/marts/schema.yml):
  dbt model and column docs, examples, join hints, and reference metric recipes.
- [star-schema/models/marts/](star-schema/models/marts): mart SQL when the agent
  needs to inspect grain or column lineage.
- [modules/](modules): Steep-as-code YAML output. This repo tracks only
  `modules/.gitkeep` until an agent generates actual modules.
- [agent-playbook/generate-steep-modules/](agent-playbook/generate-steep-modules):
  optional visible helper playbook for agents that benefit from a step-by-step
  execution guide.

## Notes

- Official Steep product links and YAML rules are listed in
  [agent-guidance.md](agent-guidance.md).
- For a real workspace, replace the example business context and schema details
  before asking the agent to generate metrics.
