-- Fails when created_ts is not older than 2000-01-01
select *
from {{ source('bridgeflow_gold', 'dim_source') }}
where created_ts >= cast('2000-01-01' as datetime2)
   or created_ts is null
