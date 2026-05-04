# Agent instructions

When the user asks for Steep metrics, KPIs, semantic modules, YAML for Steep-as-code, or join paths for this demo dataset:

0. Read [docs/cursor-steep-guidance.md](docs/cursor-steep-guidance.md) for **conventions** (join cardinality, `identifier` vs `table`, metric time, cross-table metrics) that are easy to get wrong when translating dbt or BigQuery — do not rely on SQL intuition alone.
1. Read [business-context.md](business-context.md) first.
2. Follow [.cursor/skills/generate-steep-modules/SKILL.md](.cursor/skills/generate-steep-modules/SKILL.md). **Step 2b:** proactively **`git checkout -b …`** (or equivalent) before any `modules/*.yaml` edits when in a git repo — do not wait for the user to request a branch; merge to `main` only after Steep sync / review via PR.
3. Use [star-schema/models/marts/schema.yml](star-schema/models/marts/schema.yml) for columns, types, `example_values`, and **`meta.steep`** (join paths, reference metrics, module targets). **Column `description` in `schema.yml` is dbt documentation only**—business/data semantics, not Steep help text. When writing Steep `dimensions[].description`, mirror that dbt text verbatim when present; add missing **data** descriptions in `schema.yml`, not Steep-specific prose. If the user wants a **plain-dbt** experiment, infer the layer from descriptions + SQL and **do not rely on `meta.steep`**. Optional: BigQuery MCP if the user asks to verify against the warehouse.
4. For **canonical Steep YAML rules and sync**, prefer [Steep Code Reference](https://help.steep.app/setup-and-manage/code-reference); our [yaml-schema-reference.md](.cursor/skills/generate-steep-modules/references/yaml-schema-reference.md) is a local mirror — if they conflict, follow Steep.

If the skill does not auto-trigger, point the user at [README.md](README.md) (**`@README.md`** in chat — one attachment) or [docs/STEEP-AS-CODE.md](docs/STEEP-AS-CODE.md). Index: [docs/README.md](docs/README.md).
