# Cursor × Steep-as-code — canonical guidance

**Audience:** Cursor agents and humans generating Steep `module` YAML from a warehouse / dbt star schema.

**Purpose:** Reduce wrong assumptions. Steep Help Center defines **syntax**; this document defines **conventions and failure modes** we have seen when mapping dbt or BigQuery to Steep (join paths, cardinality, metric time, cross-table SQL, etc.). If anything here conflicts with [Steep Code Reference](https://help.steep.app/setup-and-manage/code-reference), **follow Steep**.

---

## 1. Hierarchy of truth (read in this order)

| Priority | Source | Use for |
|----------|--------|---------|
| 1 | [Steep Code Reference](https://help.steep.app/setup-and-manage/code-reference) | Allowed keys, calculation types, strict validation, new product fields |
| 2 | [yaml-schema-reference.md](../.cursor/skills/generate-steep-modules/references/yaml-schema-reference.md) | Local checklist of shapes (mirror of product rules) |
| 3 | [schema.yml](../star-schema/models/marts/schema.yml) in this repo | Tables, columns, joins, `example_values`, reference metrics for **this** dataset |
| 4 | [business-context.md](../business-context.md) | Teams, questions, categories, owner emails, sensitive-field deny list |
| 5 | Warehouse (BigQuery MCP or introspection) | Live column names and types when they might have drifted from `schema.yml` |

**Bias guard:** Do not invent columns, tables, filter literals, or join edges. If missing from `schema.yml` and not confirmed in chat or warehouse, **omit or ask** — do not guess.

---

## 2. Official Steep resources (product behavior)

| Topic | Link |
|--------|------|
| YAML reference (modules, metrics, dimensions) | [Code Reference](https://help.steep.app/setup-and-manage/code-reference) |
| Git repo + sync | [Define in Code](https://help.steep.app/setup-and-manage/define-in-code) |
| UI → code migration | [App-to-Code Migration](https://help.steep.app/setup-and-manage/app-to-code-migration-guide) |

---

## 3. Module identity: `identifier` vs `table` (common mistake)

- **`module.identifier`** — stable handle in the Steep workspace (often short: `transactions`, `customers`).
- **`module.table`** — **physical** warehouse table or view name (often prefixed: `fact_transactions`, `dim_customer`).
- **Metric `time`**, **`value`**, **`distinct_on`**, and SQL in `numerator_sql` / `denominator_sql` / `sql_expression` must use the **`table` name as Steep expects in SQL** (typically `fact_transactions.amount`, not `transactions.amount`), unless Code Reference explicitly allows another form for your workspace version.

**Bias guard:** Never assume `identifier` equals BigQuery table name. Always copy the physical name from `schema.yml` `meta.steep.target_table` or the warehouse.

---

## 4. Join paths — semantics Steep allows vs how SQL thinks

### 4.1 Allowed `type` values only

Steep accepts **`one-to-one`** and **`one-to-many`** only. There is **no** `many-to-one` in YAML.

**SQL habit:** “Many fact rows → one dimension row” (many-to-one).

**Steep habit:** Express cardinality from the **module file where you declare the path**, walking **from** a row on the **current** `module.table` **to** rows on `to.table`:

- On a **dimension** module (high-level entity): one dimension row relates to **many** fact rows → use **`one-to-many`** from `dim_*` → `fact_*` (e.g. one `customer_key` → many `fact_transactions` rows).
- On a **fact** module when you must declare a path to another fact: use the pair that matches the product’s expectation (often **`one-to-one`** when at most one target row per source row, e.g. optional `transaction_id` on a risk event).

**Bias guard:** Do not label a path `one-to-many` because SQL “feels” many-to-one from the fact side. Re-read from the **declaring module’s** row: “one row here → how many rows there?”

### 4.2 Where to declare `joinPaths`

Paths belong on the module whose YAML you are editing:

- **`from.column`** must exist on **`module.table`** for that file.
- **`to.table` / `to.column`** must match the **joined** physical table and column (optionally `to.schema` if not default).

**Patterns that work:**

| Declaring module | Typical pattern | `type` |
|------------------|-----------------|--------|
| `dim_customer` | `customer_key` → `fact_transactions.customer_key` | `one-to-many` |
| `dim_account` | `account_id` → `fact_transactions.account_key` | `one-to-many` (note: column names can differ on each side) |
| `fact_visitors` | `visitor_key` → `fact_ad_spend.visitor_key` | `one-to-many` (composite keys are still single columns) |
| `fact_risk_events` | `transaction_id` → `fact_transactions.transaction_id` | `one-to-one` when business says ≤1 transaction per risk row |

**Bias guard:** dbt `ref()` direction does not dictate YAML direction. **FK location** matters: the FK column lives on the fact; the **join path can still be declared on the dimension** from dimension key → fact FK column, as long as `from`/`to` columns match real columns.

### 4.3 Key rename mismatches (star schema vs Steep)

dbt often exposes `account_key` on facts but `account_id` on dimensions. **Every `from` / `to` column must match the actual mart column name.** Do not assume `<table>_id` on both sides without checking `schema.yml` or SQL.

### 4.4 Facts listing cross-module dimensions without local `joinPaths`

A fact module (e.g. `fact_transactions`) may list `dimensions: dim_customer.customer_tier` **without** defining `joinPaths` on that same file, if other modules already declare enough of the graph for Steep to resolve the workspace.

**Bias guard:** Do not delete dimension-module join paths because “the fact already lists `dim_customer.*`”. Prefer **keeping** canonical paths on grain-owner modules unless Steep workspace rules say otherwise.

---

## 5. Dimensions — warehouse types vs Steep types

- Steep dimensions use a **small enum** (`categorical`, `country`, `city`, `time`, `h3-cell-index`, …). BigQuery `INT64` / `FLOAT64` are usually **metrics**, not dimensions, unless the product treats them as categorical labels (rare).
- **Join keys** (`*_id`, `*_key`) are often **not** user-facing dimensions; sometimes they are exposed as `categorical` for power users — follow `schema.yml` `meta.is_join_key` / `dimension_type` for this repo; in new datasets, document explicitly.
- **Sensitive fields** (email, name, lat/long): respect `business-context.md` deny list even if the column exists in SQL.

**Bias guard:** Do not turn every string column into a dimension; do not expose PII because “it’s in the star schema”.

---

## 6. Metrics — `time`, grains, and calculations

### 6.1 `time` is per metric, not only “the table’s created_at”

Each metric needs `time: <physical_table>.<column>`. Different metrics on the same table may use **different** time columns (e.g. opened vs resolved). dbt’s single `partition_by` or “primary timestamp” is **not** enough — choose the business-meaningful time for that metric.

### 6.2 `time_grains`

If a fact is a **monthly snapshot** (ARR, subscription rollups), restrict `time_grains` to `monthly` / `quarterly` / `yearly` when daily would be wrong. Document in `schema.yml` so agents do not default to daily everywhere.

### 6.3 `custom-ratio` and `custom-value` across tables

`numerator_sql` / `denominator_sql` / `sql_expression` may reference **multiple** physical tables when joins exist in the workspace (e.g. ratio of distinct keys on a fact vs count of rows on a dimension).

**Bias guard:** Every table alias in SQL must match a **real** `module.table` name in the workspace. Do not invent `JOIN` syntax Steep does not support — stay within what Code Reference allows for expressions.

### 6.4 `count` vs `count-distinct`

Use **`count-distinct`** with explicit `distinct_on` when the question is “how many unique X”. Plain `count` is row count at the fact grain.

### 6.5 Filters and slices

- **`filters`:** `operator` and `expression` must match [Code Reference](https://help.steep.app/setup-and-manage/code-reference). For `in`, use comma-separated values **without spaces** unless the product docs say otherwise.
- **`slices`:** named saved filters; same literal rules as filters.
- Filter values must appear in `schema.yml` `example_values` or be user-supplied — **no invented enums**.

---

## 7. Governance and UX fields

Optional but common in real modules:

- `category` — grouping in Steep UI (align with `business-context.md` teams when generating for a demo).
- `owner_emails` — workspace members; use questionnaire emails when present.
- `description` — business meaning; keep accurate, not marketing fluff unless requested.
- `is_unlisted` / `is_private` — only when product supports them and the user asks.

**Bias guard:** Do not add `owner_emails` with fake addresses; omit if unknown.

---

## 8. Metric identifiers and workspace scope

- **`identifier`** must be **unique across all modules** in the workspace, not only within one file.
- Prefer a stable prefix or naming convention documented in `business-context.md` when multiple teams generate metrics in one session.

---

## 9. dbt / BigQuery → Steep workflow (generalized)

1. **Inventory physical marts** (fact + dim tables) and their columns from dbt or warehouse.
2. **Choose module boundaries** — usually one YAML file per primary analytic table (often per fact + key dims); align with how Steep expects modules for your org.
3. **Emit dimensions** from Steep types + business rules (not raw SQL types alone).
4. **Declare join paths** on the correct module with correct `from`/`to` columns and **`one-to-one` / `one-to-many` only**, following §4.
5. **Add metrics** with correct `time`, `time_grains`, calculations, filters; use **`table.column`** consistently.
6. **Cross-check** against Code Reference; use MCP or queries to verify column names if `schema.yml` might be stale.

---

## 10. When uncertain (anti-bias checklist)

1. Check [Code Reference](https://help.steep.app/setup-and-manage/code-reference).
2. Check [yaml-schema-reference.md](../.cursor/skills/generate-steep-modules/references/yaml-schema-reference.md).
3. Check [schema.yml](../star-schema/models/marts/schema.yml) and [business-context.md](../business-context.md).
4. If still unclear: **ask the user** or **omit** the optional field — do not fill with guesses.
5. After writing YAML: re-read for **join direction**, **physical table names in SQL**, and **filter literals**.

---

## 11. Relation to other files in this repo

| File | Role |
|------|------|
| [STEEP-AS-CODE.md](STEEP-AS-CODE.md) | Short operational checklist (fallback when skill does not run). |
| [metric-patterns.md](../.cursor/skills/generate-steep-modules/references/metric-patterns.md) | Copy-paste YAML snippets. |
| [SKILL.md](../.cursor/skills/generate-steep-modules/SKILL.md) | Step order for generation. |

**This file (`cursor-steep-guidance.md`)** is the **deep** convention layer — read it when modeling joins, metrics, or dimensions from dbt so Cursor does not default to SQL-only mental models that break Steep.

---

## 12. Summary

- Steep Help = **syntax and product truth**.
- This doc = **how to think** when translating star schemas: join path placement, allowed cardinality enums, `identifier` vs `table`, per-metric time, cross-table metrics, filters, and uniqueness.
- **`schema.yml` + `business-context.md`** = dataset- and demo-specific facts; keep them accurate so agents do not drift.
