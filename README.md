# Demo Cursor — Steep-as-code (fintech star schema)

Sales-friendly Cursor workspace: generate **Steep-as-code** YAML (`modules/*.yaml`) from an enriched star schema. No pre-built modules, no data generators inside this repo. **Official Steep docs** (YAML, GitHub sync, migration): [docs/README.md](docs/README.md).

**Handoff:** This repo is a **template** — the bundled skill and YAML reference are **portable**; the mart names, join graph, and questionnaire content are **examples** until you replace them.

**Also read:** [AGENTS.md](AGENTS.md) · **[docs/cursor-steep-guidance.md](docs/cursor-steep-guidance.md)** (canonical Steep conventions — joins, metrics, anti-bias) · [docs/](docs/) (index + Steep Help links) · [docs/STEEP-AS-CODE.md](docs/STEEP-AS-CODE.md) (`@` if the skill does not trigger)

---

## 1. Fill the questionnaire first (strongly recommended)

Open **[business-context.md](business-context.md)** before you ask Cursor to generate metrics.

| Why | What happens if you skip |
|-----|---------------------------|
| Teams, top questions, and categories tell the agent **which** metrics to build and how to label them (`Commercial`, `Operations`, owner emails). | You get generic metrics that do not match the story you want to tell. |
| The deny-list (sensitive fields) keeps **email / names / lat-long** off default dimension lists. | Risk of surfacing PII-style fields in YAML. |
| It ships **pre-filled** (Acme Pay, B2B neobank) so you can demo in 30 seconds **or** overwrite for a real prospect. | — |

**Suggested flow:** edit `business-context.md` (or confirm the defaults) → then use prompts like *“Using business-context.md, generate the Finance team’s metrics under `modules/`.”*

---

## 2. Ground truth for Cursor (keep it simple)

**Default — no BigQuery MCP:** everything comes from **[`star-schema/models/marts/schema.yml`](star-schema/models/marts/schema.yml)** — column names, join graph, `example_values` for filters/slices, metric recipes, and descriptions. Optional: mart **SQL** under [`star-schema/models/marts/`](star-schema/models/marts/) if you need exact `SELECT` lists.

**Optional — BigQuery MCP:** use MCP to list tables, inspect types, or preview rows. Still treat **`schema.yml`** as the semantic contract (Steep module ids, join paths, reference metrics) so YAML matches this demo’s intent. MCP replaces ad-hoc row peeking; you do **not** need extra CSVs in this repo.

---

## 3. BigQuery MCP (optional — for reps with warehouse access)

Use this when the dataset already lives in BigQuery and you want Cursor to **verify** names or types against the warehouse.

### What MCP adds

| Capability | In this repo without MCP |
|------------|---------------------------|
| Live table/column list and types | `schema.yml` + dbt SQL |
| Preview rows from BQ | Not shipped here; use MCP when configured |
| Catch drift (renamed columns, new fields) | Manual edits to `schema.yml` |

The **bundled skill** is built around **repo files only**. If MCP is available, say so in chat (e.g. *“Cross-check `fact_transactions` columns in BigQuery then generate YAML using schema.yml”*).

### One-time setup (Cursor)

1. **Install Google’s MCP toolbox** (example: macOS Apple Silicon). Other platforms: [mcp-toolbox quick start](https://github.com/googleapis/mcp-toolbox#quick-start-custom-tools).

```bash
export VERSION=1.1.0
curl -L -o toolbox https://storage.googleapis.com/mcp-toolbox-for-databases/v$VERSION/darwin/arm64/toolbox
chmod +x toolbox
# Move `toolbox` somewhere permanent, e.g. ~/bin/toolbox
```

2. **Register BigQuery in Cursor MCP config** — user-level `~/.cursor/mcp.json` or project-level `.cursor/mcp.json`. Replace paths and project id:

```json
{
  "mcpServers": {
    "bigquery": {
      "command": "/full/path/to/toolbox",
      "args": ["--prebuilt", "bigquery", "--stdio"],
      "env": {
        "BIGQUERY_PROJECT": "your-gcp-project-id"
      }
    }
  }
}
```

Exact JSON shape depends on your Cursor version. **Flat server key** alternative:

```json
{
  "bigquery": {
    "command": "/full/path/to/toolbox",
    "args": ["--prebuilt", "bigquery", "--stdio"],
    "env": {
      "BIGQUERY_PROJECT": "your-gcp-project-id"
    }
  }
}
```

See [Cursor MCP](https://docs.cursor.com/context/mcp) if tools do not appear. Authenticate per the toolbox README.

3. **Restart Cursor** (or reload MCP).

### Prompt ideas when MCP is on

- *“Using business-context.md and schema.yml, generate Finance metrics; use BigQuery MCP to confirm `fact_transactions` columns match before writing YAML.”*
- *“List tables in `my-project.steep_demo_v2` and suggest Steep modules; align join paths with schema.yml.”*

---

## 4. Try these prompts (after step 1)

1. **Finance:** *“Using business-context.md, generate the metrics our Finance team asked for as Steep modules under `modules/`.”*
2. **Risk:** *“Add fraud-style metrics on transactions with risk joins; follow join paths in `star-schema/models/marts/schema.yml`.”*
3. **Bootstrap:** *“Create Steep modules for transactions, subscriptions, and fact_agg_arr with dimensions and join paths.”*

Cursor should follow [.cursor/skills/generate-steep-modules/SKILL.md](.cursor/skills/generate-steep-modules/SKILL.md) and [.cursor/rules/steep-conventions.mdc](.cursor/rules/steep-conventions.mdc).

---

## 5. What is in this repo

| Path | Purpose |
|------|---------|
| [business-context.md](business-context.md) | Questionnaire: company, teams, questions, categories, deny-list. |
| [star-schema/](star-schema/) | dbt mart SQL + enriched [models/marts/schema.yml](star-schema/models/marts/schema.yml). |
| [modules/](modules/) | Output folder for generated YAML (see [modules/README.md](modules/README.md)). |
| [.cursor/skills/generate-steep-modules/](.cursor/skills/generate-steep-modules/) | Skill + local YAML reference + metric patterns. |
| [docs/](docs/) | **Steep Help Center links**, [cursor-steep-guidance.md](docs/cursor-steep-guidance.md) (**deep conventions**), [STEEP-AS-CODE.md](docs/STEEP-AS-CODE.md) (short fallback). |

---

## 6. BigQuery and dbt (optional)

Mart SQL under `star-schema/models/marts/` may reference fixed project/dataset names (e.g. `steep-demo.steep_demo_v2`). Replace with yours, load data, then run `dbt run` from `star-schema/` when you want warehouse-backed tables. For Cursor-only demos, **sections 1–2** are enough; add **section 3** when BigQuery MCP is configured.
