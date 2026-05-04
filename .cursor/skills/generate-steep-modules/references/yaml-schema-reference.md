# Steep-as-Code YAML Schema Reference

This is a **local convenience mirror** of Steep-as-Code YAML rules, derived from internal Zod-style validation notes. **Authoritative product documentation:** [Steep Code Reference](https://help.steep.app/setup-and-manage/code-reference) — use that when validating edge cases, new fields, or sync behavior; see also [Define in Code](https://help.steep.app/setup-and-manage/define-in-code) and [App-to-Code Migration](https://help.steep.app/setup-and-manage/app-to-code-migration-guide).

## File structure

Each `.yaml` file must have exactly one root key: `module`, `metric`, or `dimension`. Files with unrecognized root keys are rejected. All schemas use `strict()` mode - extra fields cause validation errors.

The primary file type is `module`, which can contain dimensions, metrics, and join paths inline.

---

## Module

```yaml
module:
  identifier: string        # Required. Unique within the workspace.
  schema: string            # Required. Database schema name (in BigQuery, this is the dataset name).
  table: string             # Required. Database table name.
  label: string             # Optional. Display name.
  description: string       # Optional. Explanation of the table's contents.
  dimensions: []            # Optional. Array of Dimension objects.
  metrics: []               # Optional. Array of Metric objects.
  joinPaths: []             # Optional. Array of JoinPath objects.
```

---

## Dimension

```yaml
- column: string            # Required. Database column name. Acts as the dimension identifier.
  label: string             # Optional. Display name (defaults to column name).
  description: string       # Optional. Explanation of what the dimension represents.
  type: enum                # Required. One of: categorical, city, country, h3-cell-index, time
```

### Type mapping notes
- `categorical` is for string and boolean columns
- `city` is for city-name columns
- `country` is for country-name or country-code columns
- `h3-cell-index` is for H3 geospatial cell indices
- `time` is for timestamp/date columns used as dimension filters (not the metric time column)

---

## Metric

All metrics share a base schema, then add calculation-specific fields.

### Base fields (all metrics)

```yaml
- identifier: string        # Required. Unique metric identifier.
  name: string              # Required. Display name.
  description: string       # Optional. What the metric measures.
  calculation: enum         # Required. One of: sum, count, count-distinct, ratio, custom-value, custom-ratio
  time: string              # Required. Column for time analysis. Format: table.column
  dimensions: [string]      # Optional. List of dimension columns. Format: schema.table.column (schema/table optional if same module). Use "this.*" for all dims in current module, "schema.table.*" for all dims from a joined module.
  category: string          # Optional. Single category name.
  owner_emails: [string]    # Optional. Email addresses of metric owners (must be workspace members).
  is_private: boolean       # Optional. Default false.
  is_unlisted: boolean      # Optional. Default false.
  time_grains: [enum]       # Optional. Subset of: daily, weekly, monthly, quarterly, yearly. Default: all.
  time_resampling: enum     # Optional. One of: "sum/divide", "average/repeat".
  filters: [Filter]         # Optional. Array of Filter objects.
  slices: [Slice]           # Optional. Array of Slice objects.
```

### Calculation-specific fields

**sum**
```yaml
  calculation: sum
  value: string             # Required. Column to sum. Format: table.column
```

**count**
```yaml
  calculation: count
  # No additional fields
```

**count-distinct**
```yaml
  calculation: count-distinct
  distinct_on: string       # Required. Column to count distinct values. Format: table.column
```

**ratio**
```yaml
  calculation: ratio
  numerator: string         # Required. Numerator column. Format: table.column
  denominator: string       # Required. Denominator column. Format: table.column
  format: enum              # Required. One of: number, percentage
```

**custom-value**
```yaml
  calculation: custom-value
  sql_expression: string    # Required. SQL expression returning the metric value. Columns as table.column
```

**custom-ratio**
```yaml
  calculation: custom-ratio
  numerator_sql: string     # Required. SQL expression for numerator. Columns as table.column
  denominator_sql: string   # Required. SQL expression for denominator. Columns as table.column
  format: enum              # Required. One of: number, percentage
```

---

## Filter

Used in metric `filters` and slice `filter`:

```yaml
schema: string              # Optional. Database schema (omit if same as module).
table: string               # Optional. Database table (omit if same as module).
column: string              # Required. Database column name.
operator: enum              # Required. One of: equals, not-equals, less-than, less-than-or-equal, greater-than, greater-than-or-equal, in, not-in, is, is-not, like, not-like
expression: string          # Required. The filter value/expression.
```

---

## Slice

```yaml
- name: string              # Required. Display name of the slice.
  filter:                   # Required. A single Filter object.
    column: string
    operator: enum
    expression: string
```

---

## Join Path

```yaml
- from:
    column: string          # Required. Column in the current module to join from.
  to:
    schema: string          # Optional. Target schema (omit if same).
    table: string           # Required. Target table name.
    column: string          # Required. Target column name.
  type: enum                # Required. One of: one-to-one, one-to-many
```

---

## Example: complete module file

```yaml
module:
  identifier: orders
  schema: analytics
  table: orders
  label: Orders
  description: All customer orders with status and amounts.
  dimensions:
    - column: status
      label: Order Status
      type: categorical
    - column: country
      label: Country
      type: country
    - column: created_at
      label: Created At
      type: time
  metrics:
    - identifier: orders_count
      name: Orders Count
      calculation: count
      time: orders.created_at
      dimensions:
        - "this.*"
    - identifier: orders_revenue_total
      name: Total Revenue
      calculation: sum
      value: orders.amount
      time: orders.created_at
      dimensions:
        - "this.*"
    - identifier: orders_unique_customers
      name: Unique Customers
      calculation: count-distinct
      distinct_on: orders.customer_id
      time: orders.created_at
      dimensions:
        - "this.*"
  joinPaths:
    - from:
        column: customer_id
      to:
        schema: analytics
        table: customers
        column: id
      type: one-to-many
```

## Validation rules

1. Each file must have exactly one root key (`module`, `metric`, or `dimension`).
2. All schemas are strict - no extra fields allowed.
3. `identifier` must be unique across all modules/metrics in the workspace.
4. Column references in metrics use `table.column` format.
5. `dimensions` array items can use shorthand: `"this.*"` for all dims in current module.
6. A single invalid file causes the entire sync to fail (no partial success).
