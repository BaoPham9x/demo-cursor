# Star schema (dbt marts)

SQL views/tables that model a **fintech company**: customers, accounts, transactions, subscriptions, ARR snapshots, marketing visitors and ad spend, risk events, and product feature adoption.

## Files

- `dbt_project.yml` — dbt project `demo_fintech` (configure `profiles.yml` for BigQuery).
- `models/sources.yml` — raw tables in dataset `demo_raw` (adjust to your environment).
- `models/marts/*.sql` — mart definitions. **Note:** SQL still references `` `steep-demo.steep_demo_v2` `` — replace with your GCP project and dataset before running in BigQuery.
- `models/marts/schema.yml` — **semantic layer source for Cursor**: join paths, Steep module identifiers, dimension types, example values, and reference metric recipes distilled from the internal generator + existing Steep modules.

## Order of operations

1. Load raw CSVs into BigQuery (or your warehouse).
2. Replace project/dataset literals in mart SQL if needed.
3. Copy `profiles.example.yml` to a temporary `profiles.yml` path when you only need local parsing, or configure your real `~/.dbt/profiles.yml` for BigQuery.
4. Run `dbt run` from this directory when you want warehouse-backed marts.

For the **sales demo without BigQuery**, Cursor only needs **`models/marts/schema.yml`** (and optionally these `.sql` files for column lists). No separate sample CSVs live in the demo repo.

## Local parse smoke test

```bash
mkdir -p /tmp/demo-cursor-dbt-profile
cp profiles.example.yml /tmp/demo-cursor-dbt-profile/profiles.yml
dbt parse --profiles-dir /tmp/demo-cursor-dbt-profile --target-path /tmp/demo-cursor-dbt-target --log-path /tmp/demo-cursor-dbt-logs
```
