---
name: generate-steep-modules
description: Generate Steep-as-code YAML modules from this repo's dbt schema.yml, business context, and optional warehouse checks. Use when the user asks for Steep metrics, semantic YAML, join paths, KPIs, or modules under modules/.
argument-hint: optional team name or table, for example Finance or transactions
---

# Generate Steep Modules

This skill is an execution helper for the demo workspace. The canonical guidance
is [agent-guidance.md](../../../agent-guidance.md); read it first and defer to it
if anything here feels incomplete.

## Required Inputs

- [agent-guidance.md](../../../agent-guidance.md) - source-of-truth workflow and
  client handoff instructions.
- [business-context.md](../../../business-context.md) - teams, questions,
  categories, owners, default slices, and sensitive-field deny list.
- [star-schema/models/marts/schema.yml](../../../star-schema/models/marts/schema.yml)
  - dbt models, columns, descriptions, example values, join hints, target module
  metadata, and reference metric recipes.
- [references/yaml-schema-reference.md](references/yaml-schema-reference.md) -
  local mirror/checklist for Steep YAML shape.
- [references/metric-patterns.md](references/metric-patterns.md) - example metric
  snippets.

For current product syntax, validate against Steep's Code Reference linked from
`agent-guidance.md`.

## Workflow

1. Resolve scope from the user message.
   - Team request: map to the team's top questions in `business-context.md`.
   - Table request: map to `schema.yml` `meta.steep.module_identifier` or
     physical `target_table`.
   - Bootstrap request: create modules for marts with `meta.steep` metadata and
     useful reference metrics.
   - Reset/delete request: do not leave `modules/` empty. Keep exactly one valid
     module with exactly one simple metric unless the user confirms a full
     removal is safe.

2. If editing `modules/*.yaml` in a git repo, create a feature branch before
   editing unless the user explicitly tells you to work on the current branch.
   Use a short topic such as `steep/finance`, `steep/transactions`, or
   `steep/bootstrap-modules`.

3. Load `business-context.md`.
   - Build a deny list of sensitive fields.
   - Map teams to metric `category` and `owner_emails`.
   - Capture default slices such as country, plan, channel, status, segment, and
     lifecycle stage.

4. Load target models from `schema.yml`.
   - Use physical `target_schema` and `target_table` for module `schema` and
     `table`.
   - Use `module_identifier` for module `identifier`.
   - Use `default_time_column` for metric `time` as `<physical_table>.<column>`.
   - Use `example_values` for filters and slices. Do not invent literals.
   - Copy dbt column descriptions verbatim into Steep dimension descriptions
     when present.

5. Compose `modules/<module_identifier>.yaml`.
   - Module root keys should stay strict: `identifier`, `schema`, `table`,
     `label`, `description`, `dimensions`, `metrics`, and `joinPaths`.
   - Dimensions should be safe business slices, not raw keys, PII, lat/long,
     free text, or every string column.
   - Join paths may use only Steep-supported cardinality values. Do not emit
     `many-to-one`.
   - Every metric needs `identifier`, `name`, `description`, `calculation`,
     `time`, and a relevant non-empty `dimensions` list.
   - Prefer focused metric dimension lists over `"this.*"` for client demos.

6. Validate before returning.
   - YAML parses.
   - Every generated file has a `module:` root.
   - Referenced tables and columns exist in dbt docs, SQL, or the warehouse.
   - Filter values are documented or user-provided.
   - Sensitive fields are not exposed.
   - Metric identifiers are unique across generated files.

7. Commit, push, and summarize.
   - Include the branch name.
   - List files written and metric counts.
   - State assumptions and validation performed.
   - Tell the user to select the pushed branch in Steep or merge into the branch
     Steep already watches.

## Guardrails

- Do not create extra demo outputs, generated data, or sales scaffolding unless
  the user asks.
- Do not rename existing metric or module identifiers casually.
- Do not install new frameworks, global tools, hooks, or SDKs unless the user
  approves that exact change.
- Prefer a small useful layer that validates over a broad speculative layer.
