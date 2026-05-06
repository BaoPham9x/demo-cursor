# Demo Cursor — Steep-as-code (fintech star schema)

Sales-friendly Cursor workspace: generate **Steep-as-code** YAML (`modules/*.yaml`) from an enriched star schema. No pre-built modules, no data generators inside this repo. **Official Steep docs** (YAML, GitHub sync, migration): [docs/README.md](docs/README.md).

**Handoff:** This repo is a **template** — the bundled skill and YAML reference are **portable**; the mart names, join graph, and questionnaire content are **examples** until you replace them.

## Two demo modes

**Enriched deterministic demo (recommended for sales):** Cursor reads the pre-filled questionnaire plus enriched dbt metadata in [`star-schema/models/marts/schema.yml`](star-schema/models/marts/schema.yml): table shape, column docs, Steep module targets, join hints, safe dimension types, `example_values`, and reference metric recipes. This is the fast, precise path that shows how a team can encode business intent next to dbt and generate Steep-as-code reliably.

**Plain-dbt challenge mode:** Ask Cursor to ignore `meta.steep` and infer from mart SQL plus standard dbt descriptions only. This is useful for proving what is possible from a normal dbt project, but it is intentionally less deterministic: the assistant must infer joins, metric grains, filter values, and safe dimensions instead of reading an explicit semantic contract.

---

## New chat in Cursor — one attachment

**Sales / new chat:** In Cursor, type **`@README.md`** and then your request in plain English. You do **not** need to attach `business-context.md`, `schema.yml`, or other folders — the agent opens those files from this repo when generating Steep-as-code YAML under [`modules/`](modules/).

**Quick options in the same message:**

- *“Use the example questionnaire as-is.”* — keeps the pre-filled Acme Pay defaults in [`business-context.md`](business-context.md) (fine for internal demos).
- *“I have BigQuery MCP configured.”* — optional; ask for a warehouse cross-check on columns if something looks ambiguous; YAML shape should still follow [`star-schema/models/marts/schema.yml`](star-schema/models/marts/schema.yml).

**Copy-paste prompts** (put these right after `@README.md`):

1. **Finance (default story):** *“Generate Steep-as-code YAML under `modules/` for the Finance team’s top questions from this repo.”*
2. **Example questionnaire:** *“Generate Steep modules for Operations using the example business context as-is.”*
3. **One mart:** *“Generate Steep YAML for the transactions mart only; respect the deny list in business-context.”*
4. **Risk:** *“Add fraud-style metrics on transactions with risk joins; follow join paths in schema.yml.”*
5. **Bootstrap several marts:** *“Create Steep modules for transactions, subscriptions, and fact_agg_arr with dimensions and join paths from this repo.”*

**If the assistant seems lost:** add **`@docs/STEEP-AS-CODE.md`** once, or write *“Follow AGENTS.md and docs/cursor-steep-guidance.md for this repo.”*

**Repo index (browse anytime):** [AGENTS.md](AGENTS.md) · **[docs/cursor-steep-guidance.md](docs/cursor-steep-guidance.md)** (joins, metrics, anti-bias) · [docs/demo-script.md](docs/demo-script.md) (5-minute client flow) · [docs/](docs/) (Steep Help links) · [docs/STEEP-AS-CODE.md](docs/STEEP-AS-CODE.md) (short fallback checklist).

---

## 1. Fill the questionnaire first (strongly recommended)

Open **[business-context.md](business-context.md)** before you ask Cursor to generate metrics.

| Why | What happens if you skip |
|-----|---------------------------|
| Teams, top questions, and categories tell the agent **which** metrics to build and how to label them (`Commercial`, `Operations`, owner emails). | You get generic metrics that do not match the story you want to tell. |
| The deny-list (sensitive fields) keeps **email / names / lat-long** off default dimension lists. | Risk of surfacing PII-style fields in YAML. |
| It ships **pre-filled** (Acme Pay, B2B neobank) so you can demo in 30 seconds **or** overwrite for a real prospect. | — |

**Suggested flow:** edit [`business-context.md`](business-context.md) (or confirm the defaults) → in Cursor use **`@README.md`** plus a prompt from **New chat in Cursor** above (no need to list other paths).

---

## 2. Ground truth for Cursor (keep it simple)

**Default — no BigQuery MCP:** everything comes from **[`star-schema/models/marts/schema.yml`](star-schema/models/marts/schema.yml)** — column names, join graph, `example_values` for filters/slices, metric recipes, and **model/column descriptions**. Optional: mart **SQL** under [`star-schema/models/marts/`](star-schema/models/marts/) if you need exact `SELECT` lists.

**dbt docs vs Steep contract:** In `schema.yml`, **model and column `description`** fields should stay **business and warehouse meaning** (grain, definitions, caveats)—the same text you would show in dbt docs to someone who never uses Steep. **Do not** paste Steep product jargon or UI-only explanations there. Steep-specific wiring (module ids, join graph, `dimension_type` for codegen helpers, reference metric recipes) belongs under **`meta.steep`** and in generated **`modules/*.yaml`**, not in dbt descriptions. When Steep YAML lists a `dimensions[].description`, copy **only** that neutral dbt column `description` verbatim (or leave the Steep field empty if unset). To **test Cursor on “plain dbt”**, ask for a semantic layer from **mart SQL + standard `schema.yml` descriptions** and say to **ignore or omit `meta.steep`** in that run—harder and less deterministic than this template, but a fair experiment.

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

- *“`@README.md` — generate Finance metrics; use BigQuery MCP to confirm `fact_transactions` columns match before writing YAML.”*
- *“`@README.md` — list tables in `my-project.steep_demo_v2` and suggest Steep modules; align join paths with schema.yml.”*

---

## 4. What is in this repo

| Path | Purpose |
|------|---------|
| [business-context.md](business-context.md) | Questionnaire: company, teams, questions, categories, deny-list. |
| [star-schema/](star-schema/) | dbt mart SQL + enriched [models/marts/schema.yml](star-schema/models/marts/schema.yml). |
| [modules/](modules/) | Output for Steep-as-code YAML (e.g. `transactions.yaml`). Git tracks only a **`.gitkeep`** placeholder until you generate files (`@README.md` + prompt); treat generated `*.yaml` as local unless you commit them. |
| [examples/expected-output/](examples/expected-output/) | Golden examples for Finance and Operations demos. These are intentionally outside `modules/` so live generation still starts empty. |
| [.cursor/skills/generate-steep-modules/](.cursor/skills/generate-steep-modules/) | Skill + local YAML reference + metric patterns. |
| [docs/](docs/) | **Steep Help Center links**, [cursor-steep-guidance.md](docs/cursor-steep-guidance.md) (**deep conventions**), [STEEP-AS-CODE.md](docs/STEEP-AS-CODE.md) (short fallback checklist). |
| [scripts/validate_semantic_contract.rb](scripts/validate_semantic_contract.rb) | Local validation for schema/SQL alignment, join paths, metric ids, safe dimensions, and expected YAML examples. |

### Git branch for `modules/` (create, commit, **push**)

When generating Steep-as-code YAML, follow [AGENTS.md](AGENTS.md) / the bundled skill: **create a feature branch before editing `modules/`**, then **commit** the new or changed `*.yaml` files. **Push that branch to the remote** (for example `git push -u origin steep/your-topic`) as part of the same flow. A branch that only exists locally does **not** show up on GitHub/GitLab or in teammates’ clones, and Steep **Define in Code** sync expects a branch on the host you connected. If you skip the push, you will not see the branch on the remote until you run it yourself.

### Removing the semantic layer (Steep + Git)

When you intend to **delete the whole Steep-as-code semantic layer** from the repo (for example clearing `modules/*.yaml` before a fresh generation), **leave exactly one metric** in YAML on purpose for the last sync. That makes the change obviously deliberate—an empty tree can look like an accident or a bad sync. After reviewers agree the layer is gone, **remove that last metric manually** (follow-up commit or delete in the Steep app), depending on how you manage the workspace.

**Disconnecting GitHub from Steep** (turning off the integration or unlinking the repo) **does not delete** metrics, modules, or definitions that already live in Steep. They remain until you remove or replace them inside Steep or via a later sync that actually deletes content per [Steep Define in Code](https://help.steep.app/setup-and-manage/define-in-code) behavior.

---

## 5. BigQuery and dbt (optional)

Mart SQL under `star-schema/models/marts/` may reference fixed project/dataset names (e.g. `steep-demo.steep_demo_v2`). Replace with yours, load data, then run `dbt run` from `star-schema/` when you want warehouse-backed tables. For Cursor-only demos, **sections 1–2** are enough; add **section 3** when BigQuery MCP is configured.

For a local syntax smoke test without using your hidden `~/.dbt/profiles.yml`, run:

```bash
cd star-schema
mkdir -p /tmp/demo-cursor-dbt-profile
cp profiles.example.yml /tmp/demo-cursor-dbt-profile/profiles.yml
dbt parse --profiles-dir /tmp/demo-cursor-dbt-profile --target-path /tmp/demo-cursor-dbt-target --log-path /tmp/demo-cursor-dbt-logs
```

For the repo semantic contract check:

```bash
ruby scripts/validate_semantic_contract.rb
```
