# 🏥 Pharma Commercial Analytics

An end-to-end pharma sales analytics project — from raw CSV to a fully modeled SQL Server database to an interactive Power BI dashboard. Built to answer real commercial questions a pharma company (or the consultants advising one) would actually ask: product performance, market concentration, sales-force effectiveness, and growth trends.

## 📊 What's in here

- **`pharma-data.csv`** — raw source data (254k rows): sales transactions across Germany and Poland, spanning distributors, customers, products, channels, and sales reps.
- **`01_data_cleaning.sql`** — identifying and resolving data quality issues: null revenue values (recovered as returns), invalid fractional quantities, and duplicate rows.
- **`02_data_modeling.sql`** — building a proper star schema (5 dimension tables + 1 fact table) from the flat source data, with surrogate keys.
- **`03`–`08_*.sql`** — analysis across six business themes: Product Performance, Geography, Channel Strategy, Distributor/Customer Concentration, Sales Force Effectiveness, and Time Trends & Seasonality. Each file documents the business question, the query, and the interpretation.
- **`Visualization_pannels.pbix`** — the Power BI dashboard: 7 pages translating the SQL findings into an executive-ready report.

## 🧱 Tech stack

SQL Server Management Studio (T-SQL) for data modeling and analysis · Power BI for the dashboard · Git/GitHub for version control.

## 🔍 A few things worth knowing before you dig in

- The data spans **Germany (2017–2020)** and **Poland (2018 only)** — this unequal time coverage was discovered mid-analysis and initially skewed the country comparison. The Geography analysis includes both the original (flawed) comparison and a corrected, fair 2018-only comparison, documented transparently rather than quietly fixed.
- Distributor revenue is highly concentrated (top distributor ≈ 31% of revenue), while customer revenue is broadly and evenly spread — two very different risk profiles within the same business.
- Sales team/rep rankings are normalized by headcount (avg revenue per rep), not raw totals, since raw totals were misleading team sizes differ.

## 🚀 Reproducing this

1. Run `01_data_cleaning.sql` and `02_data_modeling.sql` against the raw CSV (imported into SQL Server) to rebuild the star schema.
2. Run `03`–`08` in order to reproduce the analysis.
3. Open `Visualization_pannels.pbix` in Power BI Desktop and point it at your local SQL Server instance.

---

Built as a portfolio project to practice SQL, data modeling, and business analysis end-to-end. Made with care (and a lot of debugging) 🩵