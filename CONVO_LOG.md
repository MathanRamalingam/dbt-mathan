# DBT Work Log

Purpose: track what was done, why it was done, and what changed.

## Session Summary

Date: 2026-04-17
Project: dbt_bridge_gold
Workspace root: C:/Users/MathanRamalingam/OneDrive - tradesolution.no/Desktop/mathan/DBT

### 1) Python environment
- Created virtual environment: .venv
- Verified Python in env
- Notes: terminal session differences caused initial confusion about activation visibility

### 2) dbt project setup
- Initialized dbt project: dbt_bridge_gold
- Confirmed standard folders and dbt_project.yml

### 3) Fabric profile setup
- Created profile file in user home: C:/Users/MathanRamalingam/.dbt/profiles.yml
- Configured:
  - server: xcu5l2rnjj4u3ohvhpx7m4yle4-ufb4if2zcnnulhvmfcmbbxwxjy.datawarehouse.fabric.microsoft.com
  - database: dwh_dbttest
  - schema: bridgegold
  - authentication: CLI

### 4) Connection troubleshooting
- Ran dbt debug
- Found ODBC error: configured Driver 18 not installed
- Checked installed drivers and found ODBC Driver 17
- Updated profiles.yml driver to ODBC Driver 17
- Re-ran dbt debug: success

### 5) Project path troubleshooting
- Found run/debug failure when command executed from wrong folder
- Correct working folder confirmed: .../DBT/dbt_bridge_gold

### 6) Source and model troubleshooting
- Model: models/staging/stg_customers.sql
- Initial error: source raw.customers not found
- Added source config and then fixed schema/database mapping
- Updated models/sources/raw.yaml with:
  - source raw -> database dwh_dbttest, schema bridgegold
  - tables customers, orders
- Re-ran dbt run: stg_customers built successfully

### 7) Added second source from another database/schema
- Requirement: use bridgeflow_gold.gold_layer.dim_source
- Updated models/sources/raw.yaml:
  - source name bridgeflow_gold
  - database bridgeflow_gold
  - schema gold_layer
  - table dim_source
- Created new model: models/staging/stg_dim_source.sql
- Ran dbt run --select stg_dim_source: success

## Current State
- Connection to Fabric warehouse works
- Source definitions for both raw and bridgeflow_gold are configured
- Staging models built successfully:
  - stg_customers
  - stg_dim_source

### 2026-04-17 16:20
- Task: Add source freshness check for daily recency monitoring
- Files changed:
  - models/sources/raw.yaml
- Changes made:
  - Added freshness policy to source table bridgeflow_gold.dim_source
  - loaded_at_field: created_ts
  - warn_after: 1 day
  - error_after: 2 days
- Command(s) run:
  - dbt source freshness --select source:dbt_bridge_gold.bridgeflow_gold.dim_source
- Result:
  - Freshness check executed
  - Current status returned STALE/ERROR (data older than configured threshold)
- Next action:
  - Either adjust threshold to business expectation or confirm upstream ingestion schedule

### 2026-04-17 19:28
- Task: Add data quality test for dim_source created_ts year boundary
- Files changed:
  - tests/dim_source_created_ts_before_2000.sql
- Changes made:
  - Added singular test to fail rows where created_ts is 2000-01-01 or newer (or null)
- Command(s) run:
  - dbt test --select dim_source_created_ts_before_2000
- Result:
  - Test failed with 4 rows
  - This indicates current created_ts values are not older than year 2000
- Next action:
  - Confirm intended business rule (older than 2000 vs newer than 2000) and invert logic if needed

### 2026-04-17 19:33
- Task: Move created_ts rule back to SQL test file and keep YAML only for sourceId not_null
- Files changed:
  - models/sources/raw.yaml
  - tests/dim_source_created_ts_before_2000.sql
- Changes made:
  - Removed YAML expression test from source table
  - Added YAML column test: dim_source.sourceId -> not_null
  - Recreated singular SQL test file for created_ts < 2000-01-01 rule
- Command(s) run:
  - dbt test --select source:dbt_bridge_gold.bridgeflow_gold.dim_source dim_source_created_ts_before_2000
- Result:
  - PASS: source_not_null_bridgeflow_gold_dim_source_sourceId
  - FAIL: dim_source_created_ts_before_2000 (4 failing rows)
- Next action:
  - Keep as-is if this failure should alert data quality issue
  - Or invert/adjust year-rule logic if business expectation is different

### 2026-04-17 19:37
- Task: Add reusable generic custom test example
- Files changed:
  - tests/generic/test_greater_than_zero.sql
  - models/sources/raw.yaml
- Changes made:
  - Added custom generic test macro `greater_than_zero(model, column_name)` using `{% test %}` / `{% endtest %}`
  - Applied generic test to source column `bridgeflow_gold.dim_source.sourceId`
- Command(s) run:
  - dbt test --select source:dbt_bridge_gold.bridgeflow_gold.dim_source
- Result:
  - PASS: source_not_null_bridgeflow_gold_dim_source_sourceId
  - PASS: source_greater_than_zero_bridgeflow_gold_dim_source_sourceId
  - FAIL: dim_source_created_ts_before_2000 (4 failing rows)
- Next action:
  - Keep custom generic test as reusable template for other numeric ID columns

## Update Template (append for each change)

### YYYY-MM-DD HH:MM
- Task:
- Files changed:
- Command(s) run:
- Result:
- Error(s) and fix:
- Next action:

## Q&A Log

Format:
- Q: <your question>
- A: <short answer>

### 2026-04-17
- Q: What does "no sample profile found for fabric" mean?
- A: dbt-fabric does not auto-generate a profile template; create `C:/Users/MathanRamalingam/.dbt/profiles.yml` manually.

- Q: Is `dbt_project.yml` the same as `profiles.yml`?
- A: No. `dbt_project.yml` is project behavior/config. `profiles.yml` is connection/auth settings.

- Q: What does `select * from {{ source('raw', 'customers') }}` mean?
- A: dbt resolves it to the fully qualified source table from source YAML, then runs normal SQL select.

- Q: If `orders` is listed in source YAML but table is missing, what happens?
- A: Nothing breaks until a model/test/freshness uses that table; then dbt errors with object not found.

- Q: Do I need a new `profiles.yml` entry for another database/schema?
- A: Usually no, if server/auth are same. Add another source block in YAML with different database/schema.

- Q: Is view name taken from file name?
- A: Yes by default. `stg_dim_source.sql` builds object `stg_dim_source` unless alias is configured.

- Q: Why is the command `dbt source freshness`?
- A: Because it operates on dbt resource type `source`, not because the file is inside a folder named `sources`.

- Q: How to test freshness for one source table?
- A: `dbt source freshness --select source:dbt_bridge_gold.bridgeflow_gold.dim_source`

- Q: My source file name is raw.yaml. Is that right?
- A: Yes. dbt accepts both .yml and .yaml files. The file name can be raw.yaml; what matters is valid YAML content with `version: 2` and `sources:`.

- Q: Does source YAML have to be inside a sources folder, or can it be without that folder?
- A: It does not have to be in a folder named sources. It can be anywhere under the project model-paths (usually models). Folder name is for organization only.

- Q: What does `version: 2` mean in source YAML? Can it be 1, 0, or another number?
- A: `version: 2` is dbt's supported schema format for properties files (sources/tests/docs). Use 2. Other values are not valid for modern dbt projects.

- Q: Add test: dim_source created_ts should be older than year 2000
- A: Added singular test file tests/dim_source_created_ts_before_2000.sql and executed it; result failed with 4 rows, meaning current data does not satisfy that rule.

- Q: Keep date check in test file (not in YAML) and set YAML test for sourceId not null
- A: Done. `created_ts` rule is in tests/dim_source_created_ts_before_2000.sql, and YAML now contains `not_null` test for source `dim_source` column `sourceId`.

- Q: Always auto commit CONVO_LOG
- A: Cannot enable yet because current folder is not a Git repository (`git rev-parse` failed). After `git init`, set a pre-commit hook to auto-stage CONVO_LOG.md on every commit.

- Q: Why is there no test and endtest in dim_source_created_ts_before_2000.sql? Is it needed?
- A: Not needed for singular tests. Files in tests/ are plain SQL assertions (failing rows). test/endtest blocks are only for reusable generic test macros defined in tests/generic or macros and referenced from YAML.

- Q: Add an example generic reusable test
- A: Added `tests/generic/test_greater_than_zero.sql` and used it in YAML for `dim_source.sourceId`. It runs as `source_greater_than_zero_bridgeflow_gold_dim_source_sourceId`.

- Q: Can `greater_than_zero` be added to any columns?
- A: Use it only on numeric columns where business logic requires positive values (IDs, counts, quantities). Do not apply to text/date/boolean columns or numeric fields that can validly be 0/negative.

- Q: Is it possible to not use ref function? Will it cause an error? What are impacts besides lineage?
- A: Yes, possible. It will not always error, but you lose dependency-aware build order, environment-safe naming resolution, automatic relation renames, and reliable selective runs. Hardcoded object names can break when schemas or aliases change.

- Q: What is raw.yaml called in general in dbt terminology?
- A: It is called a "properties file" (any .yml/.yaml file containing metadata). Specifically, it is a "source properties file" since it defines sources. Other metadata files (tests, descriptions) also use the same properties file format.

- Q: I have new dbt project for MS Fabric. Plan: silver layer (source) → transform → gold layer (target). How to bring dbt into Fabric? Better to create outside and import, or create in Fabric?
- A: Best practice: Create and test locally outside (like we're doing now), keep in Git, then deploy to Fabric using Fabric Git integration or scheduled jobs. This gives you version control, testing, and safe deployment. Not recommended to build directly in Fabric UI.
