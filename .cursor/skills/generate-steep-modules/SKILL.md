---
name: generate-steep-modules
description: Generate Steep-as-code YAML modules from this repo's enriched dbt schema.yml (and optional BigQuery MCP if the user asks). Use when the user asks for Steep metrics, semantic YAML, join paths, KPIs, or modules under modules/.
argument-hint: optional team name or table (e.g. Finance, transactions)
---

# Generate Steep modules (demo workspace)

Produce **Steep-as-code** `module` YAML files for this fintech demo. **Primary source of truth:** repo files (`business-context.md`, `schema.yml`). BigQuery MCP is optional for cross-checking the warehouse when the user requests it.

**Template handoff:** This repo is a template — this skill and [references/yaml-schema-reference.md](references/yaml-schema-reference.md) are portable; mart names, join graph, and `business-context.md` are examples until the user replaces them.

**Before modeling joins or metrics:** read [docs/cursor-steep-guidance.md](../../docs/cursor-steep-guidance.md) — Steep’s allowed join `type` values and “where to declare paths” differ from raw SQL many-to-one thinking; that doc prevents systematic mistakes.

## Prerequisites (read-only)

- [docs/cursor-steep-guidance.md](../../docs/cursor-steep-guidance.md) — canonical conventions (join paths, time columns, cross-table metrics, bias guards)
- [business-context.md](../../business-context.md) at repo root
- [star-schema/models/marts/schema.yml](../../star-schema/models/marts/schema.yml)
- [references/yaml-schema-reference.md](references/yaml-schema-reference.md) (local mirror of Steep’s module YAML shape)
- [references/metric-patterns.md](references/metric-patterns.md)
- **Steep Help Center (canonical):** [Code Reference](https://help.steep.app/setup-and-manage/code-reference) · [Define in Code](https://help.steep.app/setup-and-manage/define-in-code) (GitHub + sync) · [App-to-Code Migration](https://help.steep.app/setup-and-manage/app-to-code-migration-guide). Repo index: [docs/README.md](../../docs/README.md).

If the local YAML reference and Steep’s Code Reference disagree, **follow Steep’s Code Reference**.

## Step 1 — Read business-context.md

Parse sections 1–4. Build:

- **Deny list** of dimension columns (section 3, sensitive / excluded fields).
- **Team → category + owner email** map from section 2.
- **Default slices** (section 3) to prefer on revenue/volume style metrics when the user does not specify otherwise.

If critical fields are blank and the user did not give alternatives in chat, ask once in chat; optionally offer to write answers back into `business-context.md`.

## Step 2 — Resolve scope from the user message and $ARGUMENTS

- If the user names a **team** (Finance, Operations, Risk, Marketing), map to that team's top questions in `business-context.md` and plan roughly **one metric per question** (merge overlapping questions).
- If the user names a **table / module** (transactions, subscriptions, agg_arr, …), map to the dbt model name via `schema.yml` `meta.steep.module_identifier` / `target_table`.
- If the user says **bootstrap everything**, create modules for every model in `schema.yml` that has `meta.steep.module_identifier` and at least one `reference_metrics` or obvious count metric on `default_time_column`.

## Step 3 — Load schema.yml

For each target mart model, read:

- `meta.steep.module_identifier`, `label`, `target_schema`, `target_table`, `default_time_column`
- `meta.steep.join_paths` — semantic graph (from_column, to_table, to_column, join_type). Map into Steep `joinPaths` on the YAML module whose `table:` matches the dbt model you are authoring.
- `meta.steep.reference_metrics` — recipes for identifiers, calculations, filters, time, categories.
- Per-column `meta.dimension_type`, `meta.is_join_key`, `meta.example_values`, `meta.sensitive`

**Filters and slices:** use only values documented under `meta.example_values` in `schema.yml` (or that the user stated explicitly in chat). If BigQuery MCP is available and the user asked to verify enums, you may cross-check distinct values in the warehouse — still prefer `schema.yml` for Steep module shape.

**Join paths (Steep only allows `one-to-one` or `one-to-many`):**

- On **dimension** modules (for example `dim_customer` → module `customers`), express paths **from** the dimension key **to** each fact: one customer → many fact rows → use `type: one-to-many`.
- On **account** module, `from.account_id` → `fact_transactions.account_key`, `type: one-to-many`.
- On **visitor** module, `from.visitor_key` → `fact_ad_spend.visitor_key`, `type: one-to-many`.
- On **risk_events** fact module, optional `from.transaction_id` → `fact_transactions.transaction_id`, `type: one-to-one` when appropriate.
- Fact modules such as `transactions` may ship **metrics only** and rely on dimension modules for join discovery — acceptable if you mirror the reference repo.

## Step 4 — Compose each `modules/<module_identifier>.yaml`

**Module root keys:** `identifier`, `schema`, `table`, `label`, `description`, `dimensions`, `metrics`, `joinPaths` only — no `slices` or `filters` at module level (Steep rejects them); put `filters` / `slices` on metrics per [yaml-schema-reference.md](references/yaml-schema-reference.md) and Steep Code Reference.

```yaml
module:
  identifier: <meta.steep.module_identifier>
  schema: <meta.steep.target_schema>
  table: <meta.steep.target_table>
  label: <meta.steep.label>
  description: <first sentence of model description from schema.yml>
  dimensions:
    - column: <col>
      label: <Human label>
      type: <categorical|city|country|h3-cell-index|time>
  metrics:
    - identifier: <unique>
      name: <string>
      calculation: ...
      time: <table>.<default_time_column>
      ...
  joinPaths: ...
```

**Dimension rules:**

- Include a dimension for every column with `meta.dimension_type` in `categorical`, `city`, `country`, `h3-cell-index`, `time`.
- Skip columns in the deny list from `business-context.md`.
- Skip `meta.dimension_type: none` unless `schema.yml` marks a key as intentionally exposed for slicing.
- For surrogate keys, follow `schema.yml` (`dimension_type` + `is_join_key`).

**Metric rules:**

- Every metric needs `time:` as `<physical_table_name>.<default_time_column>` where `physical_table_name` equals `target_table` (e.g. `fact_transactions.created_at`).
- Prefer `reference_metrics` from `schema.yml` when they match the user's ask.
- Use [metric-patterns.md](references/metric-patterns.md) for structure (filters, slices, custom-ratio, time_grains).
- Set `category` and `owner_emails` from the active team in `business-context.md` when applicable.

**Uniqueness:** `identifier` values must be unique across **all** files you write in this workspace in the session.

## Step 5 — Validate

Before returning to the user, re-read each written YAML and check against [yaml-schema-reference.md](references/yaml-schema-reference.md): allowed keys, calculation variants, filter operators, joinPath shape.

## Step 6 — Present

Summarize files written, metric count per module, join paths added, and any columns skipped due to the deny list.

## Important rules

- **Never invent columns or tables** — only names present in `schema.yml` (and mart SQL under `star-schema/models/marts/` if you need to disambiguate).
- **Never invent categorical filter values** — use `schema.yml` `example_values` or explicit user-provided literals.
- Prefer **2-space** indentation and no trailing spaces in YAML.
