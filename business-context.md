# Business context

The agent reads this file first and uses your answers to decide which modules and metrics to generate, what to slice on, and who to assign as owners.

> **Pre-filled** with the default demo persona (Acme Pay, a B2B SMB neobank). Edit any field for a real prospect, or run as-is for a generic walkthrough.

## 1. Who is the company?

- **Company name**: Acme Pay
- **Industry / segment**: B2B SMB neobank (fintech)
- **Stage / scale**: Series B, ~$8M ARR, ~5,000 SMB customers, ~2M transactions/month
- **Geographies**: US (primary), GB, NL, SE, ES; reporting currency USD
- **Demo persona(s)**: CFO, Head of Operations, Head of Risk, Head of Marketing

## 2. Which teams will use Steep?

- **Finance**
  - Top questions:
    - "What is our MRR and ARR trend by plan?"
    - "How is TPV (transaction volume) growing month over month?"
    - "What is our revenue by country?"
  - Category label: Commercial
  - Owner email: finance@acmepay.com
- **Operations**
  - Top questions:
    - "What is our transaction success rate?"
    - "Where are failed transactions concentrated (geo, payment method)?"
    - "How long does KYB approval take?"
  - Category label: Operations
  - Owner email: ops@acmepay.com
- **Risk**
  - Top questions:
    - "What is our fraud rate by geography and payment method?"
    - "How many high-severity risk events are open right now?"
    - "How fast are we resolving risk events?"
  - Category label: Risk
  - Owner email: risk@acmepay.com
- **Marketing**
  - Top questions:
    - "What is our customer acquisition by channel?"
    - "What is our activation rate by registration source?"
    - "What is our ROI on ad spend by network?"
  - Category label: Marketing
  - Owner email: marketing@acmepay.com

## 3. Cross-cutting analytics preferences

- **Time grains to support**: daily, weekly, monthly
- **Default slices everyone wants**: country, customer_tier, plan_name, transaction_type
- **Currencies / units**: all amounts in USD
- **Sensitive data to exclude as default dimensions**: email, last_name, first_name, latitude, longitude

## 4. Naming and conventions (optional)

- **Module identifier style**: snake_case
- **Metric identifier prefix**: none
- **BigQuery dataset for Steep YAML `schema:` field**: steep_demo_v2
