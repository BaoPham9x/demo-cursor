# Demo Cursor - Steep-as-code Client Example

This repo is a compact example for showing a client how an agent can generate
Steep-as-code YAML from dbt-style marts, business context, and optional warehouse
access.

## Start Here

Use one guidance file: [agent-guidance.md](agent-guidance.md).

In Cursor or Claude Code, attach it as `@agent-guidance.md` and send:

```text
Build the Steep semantic layer for this repo. Inspect the repo first, ask for
missing business context only when it changes the metrics, generate or update
modules/*.yaml, validate the YAML, create a branch, commit, push, and tell me
which branch to select in Steep.
```

`agent-guidance.md` is intentionally the source of truth. The rest of the repo is
example input data for the agent.

## What To Customize For A Client

- [business-context.md](business-context.md): company story, teams, KPI
  questions, owners, categories, default slices, and sensitive-field deny list.
- [star-schema/models/marts/schema.yml](star-schema/models/marts/schema.yml):
  dbt model and column docs, examples, join hints, and reference metric recipes.
- [star-schema/models/marts/](star-schema/models/marts): mart SQL when the agent
  needs to inspect grain or column lineage.
- [modules/](modules): Steep-as-code YAML output. This repo tracks only
  `modules/.gitkeep` until an agent generates actual modules.
- [.cursor/skills/generate-steep-modules/](.cursor/skills/generate-steep-modules):
  optional Cursor helper skill for this demo workspace.

## Notes

- Official Steep product links and YAML rules are listed in
  [agent-guidance.md](agent-guidance.md).
- The old duplicate docs have been removed so future edits happen in one place.
- For a real client, replace the demo business context and schema details before
  asking the agent to generate metrics.
