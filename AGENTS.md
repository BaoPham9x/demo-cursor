# Agent instructions

When the user asks for Steep metrics, KPIs, semantic modules, YAML for Steep-as-code, or join paths for this demo dataset:

0. Read [docs/cursor-steep-guidance.md](docs/cursor-steep-guidance.md) for **conventions** (join cardinality, `identifier` vs `table`, metric time, cross-table metrics) that are easy to get wrong when translating dbt or BigQuery — do not rely on SQL intuition alone.
1. Read [business-context.md](business-context.md) first.
2. Follow [.cursor/skills/generate-steep-modules/SKILL.md](.cursor/skills/generate-steep-modules/SKILL.md).
3. Use [star-schema/models/marts/schema.yml](star-schema/models/marts/schema.yml) as the source of truth for columns, types, `example_values`, join paths, and reference metrics. Use mart SQL under [star-schema/models/marts/](star-schema/models/marts/) only when you need to confirm a column list. Optional: BigQuery MCP if the user asks to verify against the warehouse.
4. For **canonical Steep YAML rules and sync**, prefer [Steep Code Reference](https://help.steep.app/setup-and-manage/code-reference); our [yaml-schema-reference.md](.cursor/skills/generate-steep-modules/references/yaml-schema-reference.md) is a local mirror — if they conflict, follow Steep.

If the skill does not auto-trigger, point the user at [README.md](README.md) (**`@README.md`** in chat — one attachment) or [docs/STEEP-AS-CODE.md](docs/STEEP-AS-CODE.md). Index: [docs/README.md](docs/README.md).
