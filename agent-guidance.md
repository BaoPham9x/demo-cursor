# Agent Guidance: Build a Steep Semantic Layer

This is the one client-facing guidance file for this example repo. Open or
attach it in any coding agent the client uses, such as Claude Code, Codex,
Cursor, or another repo-aware assistant. If the agent supports file mentions,
reference it as `@agent-guidance.md`, then ask:

```text
Build the Steep semantic layer for this repo.
```

The agent should inspect the repo, collect any missing business context, generate
or update Steep-as-code YAML under `modules/`, validate it, commit it, push the
branch, and explain how to sync the branch in Steep.

## What To Send To A Client

Send the repo plus this file. The client can start a new agent chat with one
attachment or file reference:

```text
@agent-guidance.md

Build the Steep semantic layer for this repo. Inspect the repo first, ask for
missing business context only when it changes the metrics, generate or update
modules/*.yaml, validate the YAML, create a branch, commit, push, and tell me
which branch to select in Steep.
```

For this demo repo, the agent will use:

- `business-context.md` for the company story, teams, questions, owners, default
  slices, and sensitive-field deny list.
- `star-schema/models/marts/schema.yml` for dbt models, columns, descriptions,
  examples, join hints, module targets, and reference metric recipes.
- `star-schema/models/marts/*.sql` when column lineage or grain needs checking.
- `agent-playbook/generate-steep-modules/` as an optional visible helper
  playbook any agent can read.
- `modules/*.yaml` as the generated Steep-as-code output.

When adapting this example to a real client, replace the business context and dbt
schema with the client's materials. Do not keep this demo's Acme Pay story,
mart names, owners, or example values unless the client is intentionally testing
the demo unchanged.

## Source Of Truth

This file is the repo's source of truth for agent behavior. Steep's product docs
remain the source of truth for current YAML syntax and sync behavior:

- [Define in Code](https://help.steep.app/setup-and-manage/define-in-code) for
  GitHub connection and sync behavior.
- [Code Reference](https://help.steep.app/setup-and-manage/code-reference) for
  exact YAML structure for modules, dimensions, join paths, filters, slices, and
  metrics.
- [App-to-Code Migration Guide](https://help.steep.app/setup-and-manage/app-to-code-migration-guide)
  only when the client is moving existing Steep app definitions into code.

If this file conflicts with Steep's product docs, follow Steep for product
syntax and note the mismatch to the user.

## First Decision

Decide which mode applies before editing files:

- Fresh build: create a semantic layer from dbt marts, warehouse metadata, and
  business context. This is the default.
- Existing-layer improvement: update existing `modules/*.yaml` already in the
  repo without renaming stable identifiers casually.
- App-to-code migration: preserve identifiers from existing Steep app
  definitions and follow the migration guide.

Do not assume every client is migrating. Many clients are starting from dbt marts
plus optional MCP or database access.

## Inspect Before Asking

Before asking broad questions, inspect the repo for:

- Agent instructions: `AGENTS.md`, `README.md`, `CLAUDE.md`, `GEMINI.md`,
  tool-specific instructions, or similar files.
- Business context: questionnaires, KPI docs, analytics briefs, owners, teams,
  definitions, deny lists, or README sections.
- dbt files: `dbt_project.yml`, `models/**/schema.yml`, `models/**/*.sql`,
  `sources.yml`, seeds, tests, and artifacts such as `manifest.json` or
  `catalog.json`.
- Existing semantic definitions: `modules/*.yaml`, exported Steep YAML,
  MetricFlow, Cube, LookML, or BI metadata.
- Warehouse access: MCP or database tools that can list tables, columns, types,
  sample rows, and accepted values.

Prefer discovered facts over guesses. Use MCP or database access when available
to verify physical names, types, nullability, distinct enum values, and examples.
If MCP is not available, use dbt docs, model SQL, tests, and source definitions.

## Collect Business Context

If the repo does not already answer these, ask the user for the smallest useful
set of answers before building important metrics:

```text
Company/product:
What does the business do, and what product or workflow does this data describe?

Teams/audiences:
Who will use these metrics in Steep? Example: Finance, Sales, Marketing,
Product, Operations, Support, Risk.

Top questions:
What are the most important questions these teams want to answer? List 3-10.

KPI definitions:
Which metrics matter most, and how should each one be calculated? Include
filters, exclusions, edge cases, and whether it is a count, sum, rate, ratio,
average, or distinct count.

Default slices:
Which dimensions should users commonly break metrics down by? Example: country,
region, plan, product, channel, status, segment, customer type, lifecycle stage,
merchant category.

Time behavior:
Which date should each metric use? What time grains matter? Example: daily,
weekly, monthly, quarterly. What timezone should reporting use?

Units and formatting:
Which metrics are currency, percentages, counts, durations, or scores? Which
currency should be shown?

Sensitive fields:
Which fields must not be exposed as dimensions? Include PII, customer names,
emails, addresses, free-text notes, internal IDs, or restricted operational
fields.

Owners and categories:
Who owns the metrics? Which categories should appear in Steep?

Existing definitions:
Are there existing Steep metrics, BI dashboards, Looker/LookML, MetricFlow,
spreadsheets, or docs that should be preserved or matched?

Warehouse access:
Is MCP or database access available to verify table names, columns, data types,
and example values?
```

Accept partial answers. If the user cannot answer everything, build a small
useful first version and list assumptions clearly.

## Translate Data Models Into Steep

Use dbt and the warehouse as the data contract. Use business context as the
semantic contract.

For each candidate mart or table:

- Identify the physical schema and table name.
- Read model and column descriptions.
- Understand the grain: one row per what?
- Find primary time columns and which metrics they support.
- Identify numeric measures, counts, durations, amounts, rates, and scores.
- Identify safe categorical, boolean, geography, status, plan, channel,
  lifecycle, and time dimensions.
- Identify join keys, but do not expose them as normal business dimensions.
- Verify filter and slice values from dbt tests, accepted values, seeds, docs, or
  warehouse samples.

Build metrics that answer business questions. Do not aggregate every numeric
column just because it exists.

## Module Rules

Use one YAML file per Steep module unless the repo already has a clear
convention. Write files under `modules/*.yaml`.

Each module should normally include:

- `identifier`: stable Steep handle, unique in the workspace.
- `schema`: physical database schema or dataset.
- `table`: physical table or view name.
- `label`: human-friendly name when useful.
- `description`: short table or grain explanation.
- `dimensions`: safe user-facing columns.
- `joinPaths`: confirmed joins to other modules.
- `metrics`: business metrics that naturally belong to the module's grain.

Keep module YAML strict. Do not put metric-only fields such as `filters`,
`slices`, `category`, or `owner_emails` at the module root.

## Identifier Versus Table

This is a common source of broken YAML:

- `module.identifier` is the stable Steep handle, such as `transactions` or
  `customers`.
- `module.table` is the physical warehouse table or view, such as
  `fact_transactions` or `dim_customer`.
- Metric `time`, `value`, `distinct_on`, `numerator_sql`, `denominator_sql`, and
  `sql_expression` should use physical table names as Steep expects in SQL, such
  as `fact_transactions.created_at`, unless Steep's current Code Reference says
  otherwise.

Never assume the identifier equals the warehouse table name. Copy physical names
from dbt docs, `meta.steep.target_table`, SQL, or the warehouse.

## Dimension Rules

Dimensions are columns users can filter or break down by.

Do:

- Use only Steep-supported dimension types from the Code Reference.
- Add business-readable labels.
- Copy dbt column descriptions verbatim when available.
- Add missing data descriptions in dbt docs or ask the user when meaning is
  unclear.
- Prefer documented statuses, categories, segments, plans, channels, countries,
  cities, regions, lifecycle stages, and dates.

Do not expose these by default:

- PII or sensitive fields.
- Raw IDs, surrogate keys, foreign keys, technical keys, or join keys.
- Latitude or longitude unless explicitly approved.
- Free-text notes, case descriptions, comments, or support messages.
- Every string column just because it exists.

In this repo, follow `business-context.md` for the sensitive-field deny list and
`schema.yml` `meta.dimension_type`, `meta.is_join_key`, and `example_values`
when present.

## Join Path Rules

Join paths are a common failure point. Validate each one carefully.

- Use only Steep-supported join path types from the Code Reference.
- Steep YAML supports `one-to-one` and `one-to-many`; do not emit
  `many-to-one`.
- Define each join path once when possible; Steep can use it from both sides.
- `from.column` must exist on the current module's physical table.
- `to.table` and `to.column` must match real physical table and column names.
- Do not blindly copy SQL join direction. Represent the Steep cardinality from
  the module file where the path is declared.
- If cardinality is unclear, ask the user or omit the join until confirmed.

Practical mapping:

- Dimension to fact: one dimension row usually reaches many fact rows, so declare
  `one-to-many` from the dimension module to the fact table.
- Fact to dimension: SQL often feels like many-to-one, but Steep does not accept
  `many-to-one`. Prefer declaring the inverse dimension-to-fact path, or rely on
  an existing path.
- Child fact to parent fact: if each child row reaches at most one parent row,
  use `one-to-one`.

Before writing YAML, list the intended join graph and confirm every referenced
column exists.

## Metric Rules

Every metric must include:

- `identifier`: stable and unique across the workspace.
- `name`: business-readable label.
- `description`: what it measures, counting logic, filters, and important
  caveats.
- `calculation`: valid Steep calculation type.
- `time`: one physical `table.column`.
- `dimensions`: a relevant non-empty list of business-useful slices.
- `category` and `owner_emails` when known.
- `filters`, `slices`, `time_grains`, and formatting when needed.

Pick dimensions that answer natural follow-up questions: by country, plan,
segment, channel, status, payment method, product, lifecycle stage, risk level,
merchant category, or similar business slices.

Do not:

- Leave metric descriptions blank.
- Leave metric dimensions empty.
- Invent filter values.
- Use IDs or join keys as default metric dimensions.
- Use vague catch-all dimensions when a focused list is clearer.
- Rename existing identifiers casually; identifier changes can recreate metrics
  and affect reports.

For monthly snapshots or rollups, restrict `time_grains` to grains that make
business sense. Do not default every metric to daily.

## Filters And Slices

- Filter expressions must use documented or verified values.
- For `in`, follow the current Steep Code Reference for expression format.
- Put `filters` and `slices` on metrics, not at the module root.
- In this demo repo, use `schema.yml` `example_values` or values the user gave
  in chat. Do not invent enum values.

## Git And Steep Sync

When in a git repo and editing `modules/*.yaml`:

1. Create a feature branch before editing YAML unless the user explicitly tells
   you to work directly on the current branch.
2. Commit the generated or updated YAML.
3. Push the branch to GitHub.
4. Tell the user the branch name.

Steep syncs from the repository and branch configured in its GitHub connection.
If you push a different branch, the user must either select that branch in Steep
or merge the PR into the branch Steep already watches.

## Reset Or Delete Requests

If the user says restart, reset, delete all, clear modules, or rebuild from
scratch, do not leave `modules/` empty by default.

Safer pattern:

- Leave exactly one valid module with exactly one simple metric.
- Prefer a harmless count metric on a stable dimension table if one exists.
- Commit and push that near-empty layer so Steep can sync an intentional cleanup.
- Only remove the final module or metric after the user confirms that is safe for
  their workspace.

## Validate Before Finishing

Check at minimum:

- YAML parses.
- Each YAML file has a valid `module:` root.
- Module root keys match the Code Reference.
- Each module has `identifier`, `schema`, and `table`.
- Every referenced schema, table, and column exists in dbt docs, SQL, artifacts,
  or the warehouse.
- Every dimension has `column` and a valid `type`.
- Every metric has `identifier`, `name`, `description`, `calculation`, `time`,
  and relevant `dimensions`.
- Calculation-specific fields are present, such as `value`, `distinct_on`,
  `numerator`, `denominator`, `sql_expression`, `numerator_sql`, or
  `denominator_sql`.
- Filter expressions use documented or verified values.
- Join paths use valid columns and confirmed cardinality.
- Sensitive fields are not exposed.
- Metric identifiers are unique.

Prefer real validation over reasoning only: run available tests, parse checks,
YAML checks, dbt parse, or focused scripts already present in the repo. Do not
install new frameworks just to validate unless the user approves.

## Final Response

Keep the final response short and actionable. Include:

- Branch name pushed.
- Files changed.
- Modules and metrics created or updated.
- Assumptions made.
- Validation performed.
- Whether MCP or database verification was used.
- What the user should do next in Steep: select the pushed branch or merge into
  the connected branch.
