---
name: generate-steep-modules
description: Generate Steep-as-code YAML modules from this repo's enriched dbt schema.yml (and optional BigQuery MCP if the user asks). Use when the user asks for Steep metrics, semantic YAML, join paths, KPIs, or modules under modules/. Proactively create a git feature branch before editing modules/ when in a git repo.
argument-hint: optional team name or table (e.g. Finance, transactions)
---

# Generate Steep modules (demo workspace)

Produce **Steep-as-code** `module` YAML files for this fintech demo. **Primary source of truth:** repo files (`business-context.md`, `schema.yml`). BigQuery MCP is optional for cross-checking the warehouse when the user requests it.

**Template handoff:** This repo is a template — this skill and [references/yaml-schema-reference.md](references/yaml-schema-reference.md) are portable; mart names, join graph, and `business-context.md` are examples until the user replaces them.

**Before modeling joins or metrics:** read [docs/cursor-steep-guidance.md](../../docs/cursor-steep-guidance.md) for edge cases and bias guards. **Join and slice rules for generated YAML are summarized in this skill (Step 3–4)** — do not repeat them as comments inside `modules/*.yaml`.

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

## Step 2b — Proactively create a git branch before any `modules/` work (default)

**Do not wait for the user to say “create a branch”.** If the workspace is a git repo and you are about to add or change anything under `modules/`, **run git yourself first**: create and check out a short-lived feature branch, then edit YAML on that branch only.

1. **Immediately** (before opening or writing module files): `git fetch origin` if remote exists; ensure you branch off the default branch (usually `git checkout main` then `git pull --ff-only` when safe, or stay on latest `main`).
2. **Create and switch**: `git checkout -b steep/<short-topic>` (or `feat/steep-<team>-<date>`). Pick `<short-topic>` from the user request (team name, mart, or “modules”).
3. If you are **already** on a non-`main` branch created for this same task, you may continue on it instead of spawning another branch.
4. Perform **all** `modules/*.yaml` reads/writes only after you are on that branch.
5. After edits: **commit and push** that branch when repo policy allows (see user rules on commits); tell the user the branch name, suggest **Steep manual sync** on the branch, then **PR → merge to `main`** after checks. Never assume you can push module work straight to `main` when protection requires PRs.

**Skip branch creation only** if the user explicitly forbids git, or there is no `.git` directory.

## Step 3 — Load schema.yml

For each target mart model, read:

- `meta.steep.module_identifier`, `label`, `target_schema`, `target_table`, `default_time_column`
- `meta.steep.join_paths` — semantic graph (`from_column`, `to_table`, `to_column`, `join_type`). Map into Steep `joinPaths` only where the rules below allow; do not copy `many-to-one` as a Steep `type` (it is not valid).
- `meta.steep.reference_metrics` — recipes for identifiers, calculations, filters, time, categories.
- Per-column `meta.dimension_type`, `meta.is_join_key`, `meta.example_values`, `meta.sensitive`

**Filters and slices:** use only values documented under `meta.example_values` in `schema.yml` (or that the user stated explicitly in chat). If BigQuery MCP is available and the user asked to verify enums, you may cross-check distinct values in the warehouse — still prefer `schema.yml` for Steep module shape.

**Join paths — Steep-as-code allows only `one-to-one` and `one-to-many`:**

There is **no** `many-to-one` value in Steep YAML. Use this mapping from `schema.yml` `join_type` when authoring `joinPaths`:

| `schema.yml` (declaring side → target) | Steep `type` on that module | Where to declare |
|----------------------------------------|----------------------------|------------------|
| `one-to-many` | `one-to-many` | Usually on the **dimension** (or parent) module: one row here → many rows on the fact. |
| `one-to-many` from a **fact** to another table (e.g. `fact_transactions` → `fact_risk_events`) | `one-to-many` | On that **fact** module. |
| `many-to-one` (typical fact → dimension FK) | Do **not** emit as `one-to-one` on the fact. | Declare the inverse on the **dimension** module as `one-to-many` toward the fact, or rely on an existing path there; omit redundant fact→dim `joinPaths`. |
| `many-to-one` fact → fact (e.g. many risk rows → one transaction) | On the **child** fact, one row → at most one parent row: use `one-to-one` to the parent fact. |

Keep join-path prose in this skill and in [docs/cursor-steep-guidance.md](../../docs/cursor-steep-guidance.md) only — **do not** paste cardinality explanations into generated module files.

## Step 4 — Compose each `modules/<module_identifier>.yaml`

**Module root keys:** `identifier`, `schema`, `table`, `label`, `description`, `dimensions`, `metrics`, `joinPaths` only — no `slices` or `filters` at module level (Steep rejects them). Put **`filters` and `slices` on individual metrics** only ([yaml-schema-reference.md](references/yaml-schema-reference.md), [metric-patterns.md](references/metric-patterns.md), Steep Code Reference). Example: a saved “US” slice belongs under each metric that should offer it, not under `module`.

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
      description: <verbatim dbt column description when present>
      type: <categorical|city|country|h3-cell-index|time>
  metrics:
    - identifier: <unique>
      name: <string>
      description: <one sentence: business meaning, calculation grain, important filter if any>
      calculation: ...
      time: <table>.<default_time_column>
      dimensions:
        - <focused dimension column>
      ...
  joinPaths: ...
```

**Dimension rules:**

- Include a dimension for every column with `meta.dimension_type` in `categorical`, `city`, `country`, `h3-cell-index`, `time`.
- Skip columns in the deny list from `business-context.md`.
- Skip `meta.dimension_type: none` unless `schema.yml` marks a key as intentionally exposed for slicing.
- For surrogate keys, follow `schema.yml` (`dimension_type` + `is_join_key`).
- Set **`dimensions[].description`** in Steep YAML whenever the column has a dbt **`description`** in `schema.yml`; copy that text **verbatim**. This is especially useful for tricky dimensions such as country codes, H3 cells, lifecycle statuses, and denormalized merchant/category fields. If a dimension lacks dbt description, do not invent Steep-specific help text; either omit the dimension description or, if the user asked to improve dbt docs, add a neutral data description in `schema.yml` first.

**Metric rules:**

- Every metric needs `time:` as `<physical_table_name>.<default_time_column>` where `physical_table_name` equals `target_table` (e.g. `fact_transactions.created_at`).
- Prefer `reference_metrics` from `schema.yml` when they match the user's ask.
- Every metric needs a **`description:`**. Write one concise business sentence that explains what the metric measures, the grain/counting logic, and any important filter (for example “completed transactions only” or “monthly active subscription snapshot”). Do not leave metric descriptions blank and do not use marketing copy.
- Every metric needs a **non-empty `dimensions:` list** with relevant slice columns. Pick a focused list that helps answer the business question: start with applicable defaults from `business-context.md` (`country`, `customer_tier`, `plan_name`, `transaction_type`), add obvious local slices from `schema.yml` (`status`, `payment_method`, `merchant_category`, `risk_flag`, `network`, `channel`, etc.), and include joined dimensions only when the join graph supports them. Do **not** use join keys, sensitive fields, raw IDs, lat/long, or huge free-text fields as metric dimensions.
- Prefer explicit dimension lists over `"this.*"` for demo readability. `"this.*"` is acceptable only for quick internal experiments, not for sales/demo output.
- Use [metric-patterns.md](references/metric-patterns.md) for structure (`filters`, **`slices`** on the metric, `custom-ratio`, `time_grains`). Default slices from `business-context.md` section 3 belong **on metrics**, duplicated per metric when several should expose the same named slice.
- Set `category` and `owner_emails` from the active team in `business-context.md` when applicable.

**Uniqueness:** `identifier` values must be unique across **all** files you write in this workspace in the session.

## Step 5 — Validate

Before returning to the user, re-read each written YAML and check against [yaml-schema-reference.md](references/yaml-schema-reference.md): allowed keys, calculation variants, filter operators, joinPath shape, **every metric has `description`**, and **every metric has a relevant non-empty `dimensions` list**.

## Step 6 — Present

Summarize files written, metric count per module, join paths added, how metric dimensions were selected, any columns skipped due to the deny list, and whether **`dimensions[].description`** was copied from dbt column docs only (or omitted for plain-dbt runs). **Always include the git branch name** (from Step 2b) and remind the user to test Steep sync on that branch before merging the PR to `main`.

## Important rules

- **Proactively create and use a feature branch** (Step 2b) before touching `modules/` in git — do not ask “should I create a branch?” unless git is disallowed.
- **Never invent columns or tables** — only names present in `schema.yml` (and mart SQL under `star-schema/models/marts/` if you need to disambiguate).
- **Never invent categorical filter values** — use `schema.yml` `example_values` or explicit user-provided literals.
- Prefer **2-space** indentation and no trailing spaces in YAML.
