# 5-minute client demo script

Use this flow when you want the repo to feel fast, precise, and honest: Cursor starts from an empty `modules/` folder, reads the questionnaire plus dbt star schema, and writes Steep-as-code YAML in front of the client.

## 0:00 - Set the frame

Show three files only:

- `business-context.md` — the business questionnaire: teams, questions, categories, owner emails, safe default slices.
- `star-schema/models/marts/schema.yml` — dbt docs plus enriched semantic hints: mart columns, examples, join graph, reference metric recipes.
- `modules/` — empty output folder for live generation.

Say: "The point is not that Cursor guesses everything from column names. The point is that semantic intent can live next to dbt, and Cursor can turn it into reviewed Steep-as-code very quickly."

## 1:00 - Run the prompt

In a fresh Cursor chat, attach only `@README.md` and use:

> Generate Steep-as-code YAML under `modules/` for the Finance team’s top questions from this repo. Use the example questionnaire as-is, follow the Steep join-path guidance, and keep sensitive fields out of dimensions.

Expected output:

- `customers.yaml` for customer attributes and parent-to-fact join paths.
- `transactions.yaml` for revenue, transaction volume, and country/payment slices.
- `agg_arr.yaml` for MRR/ARR monthly snapshot metrics by plan.

## 3:00 - Show precision, not volume

Inspect the generated YAML for these proof points:

- `schema:` and `table:` use physical dbt mart names, not module identifiers.
- Metric `time:` uses `table.column`, with ARR restricted to monthly/quarterly/yearly grains.
- Join paths use only Steep-supported `one-to-one` or `one-to-many` types.
- `email`, names, latitude/longitude, and free-text risk notes are not dimensions.
- Filters use documented `example_values`, not invented enum values.

## 4:00 - Answer the pre-enrichment question

If the client asks whether the repo is pre-enriched:

Say: "Yes. This is the deterministic version of the workflow: dbt tells Cursor the data contract, the questionnaire tells it the business questions, and Cursor generates the Steep layer. We can also run a plain-dbt challenge mode that ignores `meta.steep`, but it will be less deterministic because joins, safe dimensions, and metric grains have to be inferred."

Point to `examples/expected-output/` only as a baseline for reviewers. It is outside `modules/`, so it does not pre-populate the live Steep sync folder.

## 5:00 - Validate

Run:

```bash
ruby scripts/validate_semantic_contract.rb
```

When dbt is installed:

```bash
cd star-schema
mkdir -p /tmp/demo-cursor-dbt-profile
cp profiles.example.yml /tmp/demo-cursor-dbt-profile/profiles.yml
dbt parse --profiles-dir /tmp/demo-cursor-dbt-profile --target-path /tmp/demo-cursor-dbt-target --log-path /tmp/demo-cursor-dbt-logs
```
