# Agent Guidance: Build a Steep Semantic Layer

You are an implementation agent working in a repository that should define a
Steep semantic layer as code. Inspect the repository, collect only the missing
business context that materially changes the output, generate or update
Steep-as-code YAML under `modules/`, validate it, commit it, push the branch, and
explain how to sync the branch in Steep.

## Outcome

Produce a small, useful, validated Steep semantic layer. Prefer real checks over
reasoning-only validation. Do not stop at a plan when files need to be written.

Expected output:

- One YAML file per Steep module under `modules/`.
- Metrics that answer stated business questions, not every numeric column.
- Safe, useful dimensions for filtering and slicing.
- Confirmed join paths with valid Steep cardinality.
- A branch, commit, and push when the repository uses git.
- A final explanation with assumptions, validation performed, and Steep sync
  instructions.

## Source Of Truth

This file is the repository's source of truth for agent behavior. Steep product
docs remain authoritative for YAML syntax and sync behavior:

- [Define in Code](https://help.steep.app/setup-and-manage/define-in-code):
  GitHub connection and sync behavior.
- [Code Reference](https://help.steep.app/setup-and-manage/code-reference):
  exact YAML structure for modules, dimensions, join paths, filters, slices, and
  metrics.
- [App-to-Code Migration Guide](https://help.steep.app/setup-and-manage/app-to-code-migration-guide):
  use only when existing Steep app definitions are being moved into code.

If this file conflicts with Steep's product docs, follow Steep for product
syntax and note the mismatch to the user.

## Repository Inputs

For this example repository, use:

- `star-schema/models/marts/schema.yml`: dbt model and column docs, example
  values, module targets, join hints, dimension metadata, and reference metric
  recipes.
- `star-schema/models/marts/*.sql`: mart SQL for grain, column lineage, and
  physical table names when the schema file is unclear.
- `star-schema/dbt_project.yml` and `star-schema/models/sources.yml`: dbt
  project and source context.
- `modules/*.yaml`: generated Steep-as-code output. Create `modules/` if it does
  not exist.

When adapting this workflow to another repository, use that repository's
business context, dbt docs, SQL, warehouse metadata, and existing semantic
definitions. Do not keep this repository's Acme Pay story, mart names, owners,
or example values unless the user explicitly wants to run the example unchanged.

## Technical Preflight

Before implementation:

- Check git status and current branch.
- Check whether a remote exists if the user expects a pushed branch.
- Use existing local tooling first. Do not install frameworks, global tools,
  hooks, SDKs, or background agents unless the user explicitly approves that
  exact change.
- If a required tool is missing, ask before installing it. For macOS setup, a
  reasonable checklist is: Xcode command line tools, Homebrew, git, GitHub CLI,
  Node.js, pnpm, Python 3, pipx, jq, yq, and optionally Docker.
- If `gh auth login` or another interactive auth step is needed, keep the human
  in the loop.

## First Decision

Decide which mode applies before editing files:

- Fresh build: create a semantic layer from dbt marts, warehouse metadata, and
  business context. This is the default.
- Existing-layer improvement: update existing `modules/*.yaml` without casually
  renaming stable identifiers.
- App-to-code migration: preserve identifiers from existing Steep app
  definitions and follow the migration guide.

Do not assume every workspace is migrating. Many projects start from dbt marts
plus optional MCP or database access.

## Inspect Before Asking

Before asking broad questions, inspect the repo for:

- Agent instructions: `README.md`, `CLAUDE.md`, `GEMINI.md`, tool-specific
  instructions, or similar files.
- Business context: questionnaires, KPI docs, analytics briefs, owners, teams,
  definitions, deny lists, README sections, or comments in schema files.
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

## Business Context To Collect

If the repository does not already answer these, ask the user for the smallest
useful set of answers before building important metrics. Accept partial answers
and use repo evidence for obvious gaps.

Ask:

```text
Company/product:
What does the business do, and what product or workflow does this data describe?

Metric audiences:
Who will use these metrics? Include teams, roles, or personas.

Top questions:
What are the most important questions those audiences need to answer? List 3-10.

KPI definitions:
Which metrics matter most, and how should each one be calculated? Include
filters, exclusions, edge cases, and whether it is a count, sum, rate, ratio,
average, or distinct count.

Metric ownership:
Who owns the metrics? Which categories or folders should appear in Steep?

Default slices:
Which dimensions should users commonly break metrics down by? Examples: country,
region, plan, product, channel, status, segment, customer type, lifecycle stage,
merchant category.

Time behavior:
Which date should each metric use? Which time grains matter? What timezone
should reporting use?

Units and formatting:
Which metrics are currency, percentages, counts, durations, or scores? Which
currency should be shown?

Sensitive fields:
Which fields must not be exposed as dimensions? Include PII, customer names,
emails, addresses, free-text notes, internal IDs, or restricted operational
fields.

Existing definitions:
Are there existing Steep metrics, BI dashboards, LookML, MetricFlow,
spreadsheets, or docs that should be preserved or matched?

Warehouse access:
Is MCP or database access available to verify table names, columns, data types,
and example values?
```

If the user cannot answer everything, build a small useful first version and
list assumptions clearly.

## Example Business Context

Use this context only when the user wants to run this repository's example as-is.
For a real workspace, replace it with the user's actual business context.

- Company: Acme Pay.
- Industry: B2B SMB neobank.
- Stage and scale: Series B, approximately $8M ARR, around 5,000 SMB customers,
  around 2M transactions per month.
- Geographies: US primary, plus GB, NL, SE, ES.
- Reporting currency: USD.
- Example personas: CFO, Head of Operations, Head of Risk, Head of Marketing.
- Default time grains: daily, weekly, monthly.
- Default slices: country, customer_tier, plan_name, transaction_type.
- Sensitive fields to exclude by default: email, last_name, first_name,
  latitude, longitude.
- Module identifier style: snake_case.
- Metric identifier prefix: none.
- BigQuery dataset for Steep YAML `schema`: `steep_demo_v2`.

Team questions and ownership:

- Finance:
  - Questions: MRR and ARR trend by plan; TPV growth month over month; revenue
    by country.
  - Category: Commercial.
  - Owner email: finance@acmepay.com.
- Operations:
  - Questions: transaction success rate; failed transaction concentration by
    geography and payment method; KYB approval duration.
  - Category: Operations.
  - Owner email: ops@acmepay.com.
- Risk:
  - Questions: fraud rate by geography and payment method; open high-severity
    risk events; risk event resolution speed.
  - Category: Risk.
  - Owner email: risk@acmepay.com.
- Marketing:
  - Questions: customer acquisition by channel; activation rate by registration
    source; ad spend ROI by network.
  - Category: Marketing.
  - Owner email: marketing@acmepay.com.

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

## Branch And Files

When in a git repo and editing `modules/*.yaml`:

1. Create a feature branch before editing YAML unless the user explicitly tells
   you to work directly on the current branch.
2. Commit the generated or updated YAML.
3. Push the branch to GitHub.
4. Tell the user the branch name.

Steep syncs from the repository and branch configured in its GitHub connection.
If you push a different branch, the user must either select that branch in Steep
or merge the PR into the branch Steep already watches.

Write output under `modules/*.yaml`. Use two-space YAML indentation. Keep one
module per file unless the repo already has a different convention.

## Module Rules

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

In this repository, follow `schema.yml` `meta.dimension_type`,
`meta.is_join_key`, and `example_values` when present.

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
- In this repository, use `schema.yml` `example_values` or values the user gave
  in chat. Do not invent enum values.

## YAML Shape Reference

Each `.yaml` file must have exactly one root key: `module`, `metric`, or
`dimension`. Module files are the normal output for this workflow.

```yaml
module:
  identifier: string
  schema: string
  table: string
  label: string
  description: string
  dimensions:
    - column: string
      label: string
      description: string
      type: categorical | city | country | h3-cell-index | time
  metrics:
    - identifier: string
      name: string
      description: string
      calculation: sum | count | count-distinct | ratio | custom-value | custom-ratio
      time: table.column
      dimensions:
        - country
  joinPaths:
    - from:
        column: string
      to:
        schema: string
        table: string
        column: string
      type: one-to-one | one-to-many
```

Calculation-specific fields:

- `sum`: requires `value: table.column`.
- `count`: no additional fields.
- `count-distinct`: requires `distinct_on: table.column`.
- `ratio`: requires `numerator`, `denominator`, and `format`.
- `custom-value`: requires `sql_expression`.
- `custom-ratio`: requires `numerator_sql`, `denominator_sql`, and `format`.

Filter shape:

```yaml
filters:
  - column: status
    operator: equals
    expression: completed
```

Slice shape:

```yaml
slices:
  - name: US
    filter:
      column: country
      operator: equals
      expression: US
```

Supported dimension types: `categorical`, `city`, `country`, `h3-cell-index`,
and `time`.

Common filter operators: `equals`, `not-equals`, `less-than`,
`less-than-or-equal`, `greater-than`, `greater-than-or-equal`, `in`, `not-in`,
`is`, `is-not`, `like`, and `not-like`.

## Metric Patterns

Count with filter:

```yaml
metrics:
  - identifier: completed_transactions
    name: Completed Transactions
    description: Count of transaction rows where processing status is completed.
    calculation: count
    time: fact_transactions.created_at
    filters:
      - column: status
        operator: equals
        expression: completed
    category: Operations
    dimensions:
      - country
      - transaction_type
      - payment_method
```

Sum with filter:

```yaml
metrics:
  - identifier: revenue
    name: Revenue
    description: Sum of completed transaction amount in USD, sliced by geography and merchant context.
    calculation: sum
    value: fact_transactions.amount
    time: fact_transactions.created_at
    filters:
      - column: status
        operator: equals
        expression: completed
    category: Commercial
    dimensions:
      - country
      - transaction_type
      - payment_method
      - merchant_category
```

Percentage via custom ratio:

```yaml
metrics:
  - identifier: success_rate
    name: Transaction Success Rate
    description: Share of transaction rows completed out of all transaction rows.
    calculation: custom-ratio
    numerator_sql: "SUM(CASE WHEN fact_transactions.status = 'completed' THEN 1 END)"
    denominator_sql: "COUNT(*)"
    format: percentage
    time: fact_transactions.created_at
    category: Operations
    dimensions:
      - country
      - payment_method
      - transaction_type
```

Average via custom value:

```yaml
metrics:
  - identifier: avg_kyb_completion_days
    name: Avg KYB Completion Days
    description: Average number of days between KYB start and approval for customer records.
    calculation: custom-value
    sql_expression: "AVG(dim_customer.kyb_completion_days)"
    time: dim_customer.created_at
    category: Operations
    dimensions:
      - country
      - kyb_status
      - customer_tier
```

Count distinct:

```yaml
metrics:
  - identifier: unique_customers
    name: Unique Customers
    description: Count of distinct customers represented in transaction activity.
    calculation: count-distinct
    distinct_on: fact_transactions.customer_id
    time: fact_transactions.created_at
    dimensions:
      - country
      - transaction_type
```

Monthly snapshot grains:

```yaml
time_grains:
  - monthly
  - quarterly
  - yearly
```

`in` operator:

```yaml
filters:
  - column: risk_flag
    operator: in
    expression: high_risk,suspicious,aml_review
```

Use comma-separated values in `expression` without spaces unless Steep's current
Code Reference says otherwise.

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
