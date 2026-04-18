select *
from {{ source('bridgeflow_gold', 'dim_source') }}
