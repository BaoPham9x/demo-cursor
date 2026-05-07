# Client Guide: Build a Steep Semantic Layer with Cursor or Claude Code

This guide is for a client’s Cursor or Claude Code session. It explains how the agent should read a dbt project, ask for missing business context, optionally verify against a database through MCP, and generate Steep-as-code YAML without copying this demo’s company-specific details.

## Read These First

Treat Steep’s docs as the source of truth for product behavior and YAML syntax:

- [Define in Code](https://help.steep.app/setup-and-manage/define-in-code) — connect a GitHub repository and sync YAML definitions.
- [Code Reference](https://help.steep.app/setup-and-manage/code-reference) — full YAML syntax for modules, dimensions, join paths, filters, slices, and metrics.
- [App-to-Code Migration Guide](https://help.steep.app/setup-and-manage/app-to-code-migration-guide) — migrate existing app-defined Steep modules to code.

If this guide conflicts with Steep’s docs, follow Steep.

## Copy-Paste Prompt

Use this in a new Cursor or Claude Code chat after opening the client repo:

```text
Build a Steep-as-code semantic layer for this repo.

First inspect the repo and identify the dbt project, marts, schema.yml files, model SQL, sources, and any existing semantic-layer YAML. Then ask me for missing business context before writing YAML.

Use Steep’s Define in Code, Code Reference, and App-to-Code Migration Guide as the product source of truth. Generate one YAML file per Steep module under modules/.

Important requirements:
- Prefer business questions and dbt documentation over guessing from column names.
- If business context is missing, ask me to fill it in.
- If database MCP or warehouse access is available, use it to verify table names, columns, types, and example values.
- Every metric must have a clear business description and relevant dimensions.
- Dimension descriptions should come from dbt column descriptions when available.
- Do not expose sensitive fields, IDs, join keys, lat/long, or free-text notes as default dimensions.
- Create a branch, commit the generated YAML, and push the branch to GitHub. Tell me the branch name so I can select it in Steep and sync it.
```

## What the Agent Should Read

The agent should inspect the repo before asking broad questions. Prefer discovered facts over guesses.

Read, in this order:

1. **Project instructions**: `README.md`, `AGENTS.md`, `.cursor/rules/*`, `.claude/*`, or similar agent guidance.
2. **Business context**: a questionnaire, KPI document, analytics brief, README section, or any docs that explain teams, business questions, metric definitions, ownership, sensitive fields, and preferred slices.
3. **dbt structure**: `dbt_project.yml`, `models/**/schema.yml`, `models/**/*.sql`, `sources.yml`, and generated dbt artifacts like `manifest.json` or `catalog.json` if present.
4. **Existing semantic layer**: `modules/*.yaml`, exported Steep code, MetricFlow/Semantic Layer files, LookML, Cube, or BI metadata if present.
5. **Warehouse metadata**: use MCP or warehouse tools when available to verify live table names, column names, types, row samples, and distinct enum values.

Only ask the user after this inspection, unless the repo has no useful business context at all.

## Business Context to Collect

If the repo does not already contain this, the agent should ask the user to provide it before generating important metrics:

- Company or product context.
- Teams or audiences using Steep.
- Top business questions per team.
- KPI definitions, including inclusions/exclusions.
- Metric owners or categories.
- Sensitive fields to exclude from dimensions.
- Preferred time grains and reporting timezone.
- Currencies, units, and formatting expectations.
- Common slices, such as country, plan, channel, segment, status, or product line.
- Whether this is a fresh code-defined layer or a migration from existing Steep app definitions.

If the user cannot answer everything, generate a small useful first version and clearly list assumptions.

## How to Translate dbt to Steep

Use dbt as the data contract, but do not treat SQL names as business truth by themselves.

For each candidate mart:

- Identify the physical table or view name.
- Read model and column descriptions.
- Understand grain: one row per what?
- Identify primary time columns and which metrics they support.
- Identify safe dimensions from documented categorical, geography, status, date/time, and segmentation columns.
- Identify measures from numeric amount, count, duration, score, quantity, or rate columns.
- Identify join keys, but do not expose them as default user-facing dimensions.
- Verify filters and enum values from dbt docs, tests, accepted values, seeds, or the warehouse.

When dbt metadata is thin, inspect model SQL and ask business questions instead of inventing semantics.

## Module Rules

Steep modules represent database tables. Use one YAML file per module unless the client has a clear alternative convention.

Each module should include:

- `identifier`: stable Steep handle, unique in the workspace.
- `schema`: database schema or dataset.
- `table`: physical table or view name.
- `label`: human-friendly module name when useful.
- `description`: short description of the table and grain.
- `dimensions`: safe user-facing columns.
- `joinPaths`: needed joins to other modules.
- `metrics`: metrics that naturally belong to the module’s grain.

Keep module YAML strict. Do not put metric-only fields such as `filters`, `slices`, `category`, or `owner_emails` at the module root.

## Dimension Rules

Dimensions are columns users can filter or break down by.

Do:

- Use Steep-supported dimension types from the Code Reference.
- Add labels that business users understand.
- Copy dimension descriptions from dbt column descriptions when available.
- Use country/city/H3/time types only when the underlying data truly matches.
- Prefer documented statuses, categories, segments, plans, channels, regions, and lifecycle states.

Do not:

- Expose PII by default.
- Expose raw IDs, surrogate keys, foreign keys, or join keys as normal dimensions.
- Expose latitude/longitude unless explicitly approved.
- Expose free-text notes or descriptions as dimensions.
- Turn every string column into a dimension just because it exists.

## Join Path Rules

Join paths are easy to get wrong, so the agent should slow down here.

- Use only Steep-supported join path types from the Code Reference.
- Define a join path once; Steep can use it from both sides.
- `from.column` must exist on the current module’s physical table.
- `to.table` and `to.column` must match real physical table and column names.
- Do not copy SQL mental models blindly. A fact-to-dimension relationship in SQL often needs to be represented from the parent/dimension module to the fact with the correct Steep cardinality.
- If unsure about cardinality, ask the user or omit the join until it is confirmed.

Before writing YAML, draw or list the join graph in plain text and check that every column exists.

## Metric Rules

Metrics should answer business questions, not merely aggregate every numeric column.

Every metric should include:

- `identifier`: stable and unique.
- `name`: business-readable label.
- `description`: what it measures, grain/counting logic, and important filters.
- `calculation`: valid Steep calculation type.
- `time`: one physical `table.column`.
- `dimensions`: a relevant non-empty list of business-useful slices.
- `category` and `owner_emails` when known.
- `filters`, `slices`, `time_grains`, or formatting when needed.

Good metric dimensions answer: “What would users naturally ask this metric by?” Examples include country, plan, segment, status, channel, payment method, product area, lifecycle stage, or risk severity. Prefer explicit dimension lists over broad shortcuts so reviewers can see the intent.

Do not:

- Leave metric descriptions blank.
- Leave metric dimensions empty.
- Use invented filters or enum values.
- Use IDs or join keys as default metric dimensions.
- Use a daily time grain for monthly snapshot facts unless that is truly meaningful.
- Change an existing metric identifier casually; identifier changes can recreate metrics and affect reports.

## Migration from Existing Steep Definitions

If the client already has definitions in Steep:

1. Follow the App-to-Code Migration Guide.
2. Export one module at a time.
3. Keep existing module and metric identifiers when replacing app-defined definitions.
4. Review exported YAML for structure, naming, descriptions, ownership, joins, and dimensions.
5. Move gradually through pull requests so changes are reviewable.

The goal is not to rewrite everything at once. Preserve working identifiers and improve clarity over time.

## Git and Sync Workflow

Use the workflow the client’s Steep workspace expects.

Recommended flow:

1. Create a branch before editing YAML.
2. Generate or update `modules/*.yaml`.
3. Validate YAML shape against Steep Code Reference.
4. Commit changes.
5. Push the branch to GitHub.
6. Tell the user the branch name.
7. Either select that branch in Steep or open a PR into the branch Steep already watches.

Steep syncs from the repository and branch configured in the GitHub connection. If the branch pushed by the agent is not the branch selected in Steep, it may not sync until merged.

## Reset or Delete Workflow

If the user asks to delete, reset, restart, clear, or rebuild the semantic layer, do not leave the YAML tree empty unless Steep support or product docs explicitly say that is safe for their workspace.

Use the safer cleanup pattern:

- Remove generated modules and metrics except one intentionally kept module.
- Leave exactly one module with exactly one simple metric.
- Commit and push that near-empty semantic layer.
- Sync it in Steep.
- Remove the final metric later only after the user confirms the workspace behavior.

This avoids accidental empty-sync behavior and makes the cleanup intentional.

## Validation Checklist

Before finishing, the agent should verify:

- Every YAML file has a valid root key and one module per file.
- Module root keys match the Code Reference.
- Every module has `schema`, `table`, and `identifier`.
- Every dimension has `column` and valid `type`.
- Every metric has `identifier`, `name`, `description`, `calculation`, `time`, and relevant `dimensions`.
- Calculation-specific fields exist, such as `value`, `distinct_on`, `numerator`, `denominator`, `sql_expression`, `numerator_sql`, or `denominator_sql`.
- Metric references use physical `table.column` names.
- Filter literals are documented or verified.
- Join path columns exist and cardinality is known.
- Sensitive fields are not exposed.
- Metric identifiers are unique across the workspace.
- Changes are committed and pushed to the branch Steep can sync.

## Final Response the Agent Should Give

After generating or updating YAML, the agent should tell the user:

- Branch name pushed to GitHub.
- Files created or changed.
- Modules and metrics generated.
- Important assumptions.
- Any user decisions still needed.
- Whether warehouse/MCP verification was used.
- How to trigger Steep sync: select the pushed branch or merge the PR into the connected branch.

Keep the response short enough for non-technical users to act on.
