# Agent instructions

When the user asks for Steep metrics, KPIs, semantic modules, YAML for
Steep-as-code, or join paths for this example dataset:

0. Read [agent-guidance.md](agent-guidance.md) first. It is the repo's main
   implementation guidance for agents.
1. Read [business-context.md](business-context.md) for teams, questions,
   categories, owner emails, default slices, and the sensitive-field deny list.
2. Follow [agent-playbook/generate-steep-modules/README.md](agent-playbook/generate-steep-modules/README.md)
   when a step-by-step execution guide is useful. Before any `modules/*.yaml`
   edits in a git repo, create a feature branch unless the user explicitly asks
   to work on the current branch.
3. Use [star-schema/models/marts/schema.yml](star-schema/models/marts/schema.yml)
   for columns, types, `example_values`, and `meta.steep` hints for this example.
   Column `description` in `schema.yml` is dbt documentation only: business/data
   semantics, not Steep help text. When writing Steep `dimensions[].description`,
   mirror that dbt text verbatim when present. If the user wants a plain-dbt
   experiment, infer the layer from descriptions plus SQL and do not rely on
   `meta.steep`.
4. For canonical Steep YAML rules and sync behavior, prefer Steep's official
   Code Reference and Define in Code docs linked from [agent-guidance.md](agent-guidance.md).

If the agent needs a starting point, point the user at
[agent-guidance.md](agent-guidance.md).
