# Documentation

Long-form and reference material for this demo workspace. **Start at the repo root** with [README.md](../README.md); keep [AGENTS.md](../AGENTS.md) at root so Cursor picks it up reliably.

## Official Steep Help Center (source of truth)

Use these when validating YAML, sync behavior, or product semantics. Our bundled [yaml-schema-reference](../.cursor/skills/generate-steep-modules/references/yaml-schema-reference.md) is a convenient mirror; **defer to Steep** if anything disagrees.

| Topic | Link |
|--------|------|
| **Define in Code** — connect a GitHub repo and sync | [help.steep.app — Define in Code](https://help.steep.app/setup-and-manage/define-in-code) |
| **Code Reference** — full YAML for modules, metrics, dimensions | [help.steep.app — Code Reference](https://help.steep.app/setup-and-manage/code-reference) |
| **App-to-Code Migration** — move existing definitions to code | [help.steep.app — App-to-Code Migration Guide](https://help.steep.app/setup-and-manage/app-to-code-migration-guide) |

## Guides in this folder

| Doc | Purpose |
|-----|---------|
| **[cursor-steep-guidance.md](cursor-steep-guidance.md)** | **Canonical deep guidance** for Cursor: hierarchy of truth, join-path semantics (`one-to-one` / `one-to-many` only), `identifier` vs `table`, metric time and grains, cross-table SQL, filters, governance, dbt→Steep workflow, anti-bias checklist. **Agents should read this before inventing join or metric structure.** |
| [demo-script.md](demo-script.md) | 5-minute sales walkthrough: setup, prompt, expected output, how to explain enriched metadata vs plain dbt inference. |
| [STEEP-AS-CODE.md](STEEP-AS-CODE.md) | Short operational checklist if the Cursor skill does not fire (`@` this file in chat). |

## Elsewhere in the repo

| Path | Purpose |
|------|---------|
| [../business-context.md](../business-context.md) | Questionnaire (stays at root for easy editing). |
| [../star-schema/models/marts/schema.yml](../star-schema/models/marts/schema.yml) | Enriched semantic + join graph for this dataset. |
| [../.cursor/skills/generate-steep-modules/](../.cursor/skills/generate-steep-modules/) | Bundled skill + local YAML reference + metric patterns. |
| [../star-schema/README.md](../star-schema/README.md) | dbt / warehouse setup for mart SQL. |
