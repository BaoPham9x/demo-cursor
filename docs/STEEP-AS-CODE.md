# Steep-as-code — manual guide (fallback)

**Sales (one attachment):** in Cursor use **`@README.md`** at the repo root, then your prompt — see the **New chat in Cursor** section there.

If you still need this fallback checklist, **`@` this file** (`docs/STEEP-AS-CODE.md`) in chat or paste the checklist below.

**Deep conventions (joins, cardinality, `identifier` vs `table`, metric time):** read [cursor-steep-guidance.md](cursor-steep-guidance.md) first — this file is the short checklist only.

**Official YAML and sync behavior:** Steep Help Center — [Code Reference](https://help.steep.app/setup-and-manage/code-reference), [Define in Code](https://help.steep.app/setup-and-manage/define-in-code), [App-to-Code Migration](https://help.steep.app/setup-and-manage/app-to-code-migration-guide).

## Inputs (read in order)

1. [business-context.md](../business-context.md) — teams, top questions, categories, owner emails, sensitive-field deny list.
2. [star-schema/models/marts/schema.yml](../star-schema/models/marts/schema.yml) — per-model `meta.steep` (module id, default time column, join paths, reference metrics), per-column `meta.dimension_type` and `example_values`. Use these for filter/slice literals.
3. *(Optional)* BigQuery MCP — only if configured and the user wants live schema or preview rows cross-checked.

## Output

- Write one YAML file per Steep module under `modules/` (create the folder if missing): `modules/<module_identifier>.yaml`.
- Follow [yaml-schema-reference.md](../.cursor/skills/generate-steep-modules/references/yaml-schema-reference.md) for structure; validate ambiguous fields against [Steep Code Reference](https://help.steep.app/setup-and-manage/code-reference).
- Use `schema` and `table` from `meta.steep.target_schema` and `meta.steep.target_table` in `schema.yml` (default dataset: `steep_demo_v2`).
- Map `meta.steep.join_paths` with the direction rules in [cursor-steep-guidance.md](cursor-steep-guidance.md): declare `one-to-many` paths from the parent/grain-owner module when a dimension row reaches many fact rows, and use `one-to-one` only when one row on the declaring module reaches at most one target row. Do not copy `many-to-one` into Steep YAML.
- Use `meta.steep.default_time_column` for every metric's `time:` field as `fact_table.column` (e.g. `fact_transactions.created_at`).
- Dimensions: include columns where `meta.dimension_type` is not `none`, except `is_join_key: true` (treat join keys like `customer_key` on facts as join keys, not filter dimensions, unless `schema.yml` intentionally exposes them).
- Apply the deny list from `business-context.md` section 3: never add those columns to `dimensions` on metrics.
- Metric identifiers must be unique across all modules in the workspace.

## Patterns

See [metric-patterns.md](../.cursor/skills/generate-steep-modules/references/metric-patterns.md).
