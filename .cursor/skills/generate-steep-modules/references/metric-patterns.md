# Metric patterns (Steep-as-code)

Patterns distilled from the production-style demo modules. Use with `star-schema/models/marts/schema.yml` `meta.steep.reference_metrics`. For full metric and module YAML rules, see [Steep Code Reference](https://help.steep.app/setup-and-manage/code-reference). For join placement, `identifier` vs `table`, metric `time` choices, and required metric descriptions/dimensions, see [docs/cursor-steep-guidance.md](../../../../docs/cursor-steep-guidance.md).

## 1. Count with filter

Use for volume of rows matching a status or flag.

```yaml
metrics:
  - identifier: completed_transactions
    name: Completed Transactions
    description: Count of transaction rows where processing status is completed.
    calculation: count
    time: fact_transactions.created_at
    filters:
      - column: status
        operator: equals
        expression: completed
    category: Operations
    dimensions:
      - country
      - transaction_type
      - payment_method
```

## 2. Sum with filter (revenue / TPV)

Use for money metrics where only a subset of rows counts (e.g. `status = completed`).

```yaml
metrics:
  - identifier: revenue
    name: Revenue
    description: Sum of completed transaction amount in USD, sliced by geography and merchant context.
    calculation: sum
    value: fact_transactions.amount
    time: fact_transactions.created_at
    filters:
      - column: status
        operator: equals
        expression: completed
    category: Commercial
    dimensions:
      - country
      - transaction_type
      - payment_method
      - merchant_category
```

## 3. Slices (saved common filters)

```yaml
slices:
  - name: US
    filter:
      column: country
      operator: equals
      expression: US
```

## 4. Percentage via custom-ratio

```yaml
metrics:
  - identifier: success_rate
    name: Transaction Success Rate
    description: Share of transaction rows completed out of all transaction rows.
    calculation: custom-ratio
    numerator_sql: "SUM(CASE WHEN fact_transactions.status = 'completed' THEN 1 END)"
    denominator_sql: "COUNT(*)"
    format: percentage
    time: fact_transactions.created_at
    category: Operations
    dimensions:
      - country
      - payment_method
      - transaction_type
```

## 5. Average via custom-value

```yaml
metrics:
  - identifier: avg_kyb_completion_days
    name: Avg KYB Completion Days
    description: Average number of days between KYB start and approval for customer records.
    calculation: custom-value
    sql_expression: "AVG(dim_customer.kyb_completion_days)"
    time: dim_customer.created_at
    category: Operations
    dimensions:
      - country
      - kyb_status
      - customer_tier
```

## 6. Average amount (ratio of sum to count)

```yaml
metrics:
  - identifier: avg_transaction_amount
    name: Avg Transaction Amount
    description: Average completed transaction amount, calculated as completed amount divided by completed row count.
    calculation: custom-ratio
    numerator_sql: "SUM(fact_transactions.amount)"
    denominator_sql: "COUNT(*)"
    format: number
    time: fact_transactions.created_at
    filters:
      - column: status
        operator: equals
        expression: completed
    dimensions:
      - country
      - payment_method
      - transaction_type
```

## 7. Count-distinct

```yaml
metrics:
  - identifier: unique_customers
    name: Unique Customers
    description: Count of distinct customers represented in transaction activity.
    calculation: count-distinct
    distinct_on: fact_transactions.customer_id
    time: fact_transactions.created_at
    dimensions:
      - country
      - transaction_type
```

## 8. Cross-module dimensions

After join paths exist, reference joined dimensions as `dim_customer.customer_tier`, `dim_account.account_type`, `fact_risk_events.severity`, etc. Prefer a focused list over `this.*` when demoing explainability.

## 9. Time grains on subscription / ARR facts

For `fact_agg_arr` and subscription metrics that are monthly snapshots, set:

```yaml
time_grains:
  - monthly
  - quarterly
  - yearly
```

## 10. `in` operator for filters

```yaml
filters:
  - column: risk_flag
    operator: in
    expression: high_risk,suspicious,aml_review
```

Use comma-separated values in `expression` (no spaces), matching `schema.yml` `example_values` (or values the user confirmed in chat).
