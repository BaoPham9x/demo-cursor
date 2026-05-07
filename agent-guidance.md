# Agent Guidance: Build a Steep Semantic Layer

Attach this file in Cursor or Claude Code as `@agent-guidance.md`, then ask:

```text
Build the Steep semantic layer for this repo.
```

You are the implementation agent. Inspect the repo, collect missing business context, generate or update Steep-as-code YAML, validate it, commit it, push it, and tell the user how to sync it in Steep.

## Source of Truth

Read Steep's official docs before writing YAML:

- [Define in Code](https://help.steep.app/setup-and-manage/define-in-code) for GitHub connection and sync behavior.
- [Code Reference](https://help.steep.app/setup-and-manage/code-reference) for exact YAML structure for modules, dimensions, join paths, filters, slices, and metrics.
- [App-to-Code Migration Guide](https://help.steep.app/setup-and-manage/app-to-code-migration-guide) only when the client is moving existing Steep app definitions into code.

If this guidance conflicts with Steep's docs, follow Steep.

## First Decision

Decide which mode applies:

- Fresh build: create a new semantic layer from the repo's dbt star schema, warehouse metadata, and business context. This is the default.
- Existing-layer improvement: update existing `modules/*.yaml` already in the repo.
- App-to-code migration: preserve identifiers from existing Steep app definitions and follow the migration guide.

Do not assume every client is migrating. Many clients are starting from dbt marts plus optional MCP/database access.

## Inspect Before Asking

Before asking broad questions, inspect the repo for:

- Agent instructions: `AGENTS.md`, `README.md`, `.cursor/rules/*`, `.claude/*`, or similar files.
- Business context: questionnaires, KPI docs, analytics briefs, owners, teams, definitions, deny lists, or README sections.
- dbt files: `dbt_project.yml`, `models/**/schema.yml`, `models/**/*.sql`, `sources.yml`, seeds, tests, and artifacts such as `manifest.json` or `catalog.json`.
- Existing semantic definitions: `modules/*.yaml`, exported Steep YAML, MetricFlow, Cube, LookML, or BI metadata.
- Warehouse access: MCP/database tools that can list tables, columns, types, sample rows, and accepted values.

Prefer discovered facts over guesses. Use MCP/database access when available to verify physical names, types, nullability, distinct enum values, and examples. If MCP is not available, use dbt docs, model SQL, tests, and source definitions.

## Collect Business Context

If the repo does not already answer these, ask the user to fill them in before building important metrics:

- Company or product context.
- Teams or audiences who will use Steep.
- Top business questions per team.
- KPI definitions, including inclusions, exclusions, and edge cases.
- Metric owners, categories, and visibility.
- Sensitive fields to exclude from dimensions.
- Preferred time grains, timezone, currencies, units, and formats.
- Common slices such as country, plan, status, channel, segment, product, region, or lifecycle stage.
- Whether this is a fresh build, an update to existing code, or a migration from app-defined Steep metrics.

If the user cannot answer everything, build a small useful first version and list assumptions clearly.

## Translate Data Models Into Steep

Use dbt and the warehouse as the data contract. Use business context as the semantic contract.

For each candidate mart or table:

- Identify the physical schema and table name.
- Read model and column descriptions.
- Understand the grain: one row per what?
- Find primary time columns and which metrics they support.
- Identify numeric measures, counts, durations, amounts, rates, and scores.
- Identify safe categorical, boolean, geography, status, plan, channel, lifecycle, and time dimensions.
- Identify join keys, but do not expose them as normal business dimensions.
- Verify filter and slice values from dbt tests, accepted values, seeds, docs, or warehouse samples.

Build metrics that answer business questions. Do not aggregate every numeric column just because it exists.

## Module Rules

Use one YAML file per Steep module unless the repo already has a clear convention.

Each module should normally include:

- `identifier`: stable Steep handle, unique in the workspace.
- `schema`: physical database schema or dataset.
- `table`: physical table or view name.
- `label`: human-friendly name when useful.
- `description`: short table/grain explanation.
- `dimensions`: safe user-facing columns.
- `joinPaths`: confirmed joins to other modules.
- `metrics`: business metrics that naturally belong to the module's grain.

Keep module YAML strict. Do not put metric-only fields such as `filters`, `slices`, `category`, or `owner_emails` at the module root.

## Dimension Rules

Dimensions are columns users can filter or break down by.

Do:

- Use only Steep-supported dimension types from the Code Reference.
- Add business-readable labels.
- Copy dbt column descriptions when available.
- Add missing data descriptions in dbt docs or ask the user when the meaning is unclear.
- Prefer documented statuses, categories, segments, plans, channels, countries, cities, regions, lifecycle stages, and dates.

Do not expose these by default:

- PII or sensitive fields.
- Raw IDs, surrogate keys, foreign keys, technical keys, or join keys.
- Latitude/longitude unless explicitly approved.
- Free-text notes, case descriptions, comments, or support messages.
- Every string column just because it exists.

## Join Path Rules

Join paths are a common failure point. Validate each one carefully.

- Use only Steep-supported join path types from the Code Reference.
- Define each join path once; Steep can use it from both sides.
- `from.column` must exist on the current module's physical table.
- `to.table` and `to.column` must match real physical table and column names.
- Do not blindly copy SQL join direction. Represent the Steep cardinality correctly.
- If cardinality is unclear, ask the user or omit the join until confirmed.

Before writing YAML, list the intended join graph and confirm every referenced column exists.

## Metric Rules

Every metric must include:

- `identifier`: stable and unique.
- `name`: business-readable label.
- `description`: what it measures, counting logic, filters, and important caveats.
- `calculation`: valid Steep calculation type.
- `time`: one physical `table.column`.
- `dimensions`: a relevant non-empty list of business-useful slices.
- `category` and `owner_emails` when known.
- `filters`, `slices`, `time_grains`, and formatting when needed.

Pick dimensions that answer natural follow-up questions: by country, plan, segment, channel, status, payment method, product, lifecycle stage, risk level, merchant category, or similar business slices.

Do not:

- Leave metric descriptions blank.
- Leave metric dimensions empty.
- Invent filter values.
- Use IDs or join keys as default metric dimensions.
- Use vague catch-all dimensions when a focused list is clearer.
- Rename existing identifiers casually; identifier changes can recreate metrics and affect reports.

## Write Files

Write Steep code under `modules/*.yaml` unless the repo says otherwise.

Do not create extra demo examples, golden-output folders, validator scripts, generated data, or sales scaffolding unless the user explicitly asks. Keep the repo clean and make the semantic layer look generated from the client's actual models and business context.

Use two-space YAML indentation. Keep one module per file. Keep identifiers stable and readable.

## Validate Before Finishing

Check at minimum:

- YAML parses.
- Each YAML file has a valid `module:` root.
- Module root keys match the Code Reference.
- Each module has `identifier`, `schema`, and `table`.
- Every referenced schema, table, and column exists in dbt docs, SQL, artifacts, or the warehouse.
- Every dimension has `column` and a valid `type`.
- Every metric has `identifier`, `name`, `description`, `calculation`, `time`, and relevant `dimensions`.
- Calculation-specific fields are present, such as `value`, `distinct_on`, `numerator`, `denominator`, `sql_expression`, `numerator_sql`, or `denominator_sql`.
- Filter expressions use documented or verified values.
- Join paths use valid columns and confirmed cardinality.
- Sensitive fields are not exposed.
- Metric identifiers are unique.

Prefer real validation over reasoning only: run available tests, parse checks, YAML checks, dbt parse, or focused scripts already present in the repo. Do not install new frameworks just to validate unless the user approves.

## Git and Steep Sync

When in a git repo:

1. Create a branch before editing `modules/*.yaml`, unless the user explicitly told you to work directly on the current branch.
2. Commit the generated or updated YAML.
3. Push the branch to GitHub.
4. Tell the user the branch name.

Steep syncs from the repository and branch configured in its GitHub connection. If you push a different branch, the user must either select that branch in Steep or merge the PR into the branch Steep already watches.

## Reset or Delete Requests

If the user says restart, reset, delete all, clear modules, or rebuild from scratch, do not leave `modules/` empty by default.

Safer pattern:

- Leave exactly one valid module with exactly one simple metric.
- Prefer a harmless count metric on a stable dimension table if one exists.
- Commit and push that near-empty layer so Steep can sync an intentional cleanup.
- Only remove the final module/metric after the user confirms that is safe for their workspace.

## Final Response

Keep the final response short and actionable. Include:

- Branch name pushed.
- Files changed.
- Modules and metrics created or updated.
- Assumptions made.
- Validation performed.
- Whether MCP/database verification was used.
- What the user should do next in Steep: select the pushed branch or merge into the connected branch.
