# ADF Metadata-Driven Incremental Load

## Overview
This project implements a metadata-driven incremental ingestion framework using Azure Data Factory to move data from an on-premises SQL Server to Azure Data Lake Storage Gen2.

The framework processes multiple dimension and fact tables using a centralized watermark table and reusable parent/child pipelines.

## Architecture
On-Premises SQL Server
→ Self-Hosted Integration Runtime
→ Azure Data Factory
→ ADLS Gen2
→ Parquet files

## Key Components
- Azure Data Factory
- Azure Data Lake Storage Gen2
- SQL Server
- Self-Hosted Integration Runtime
- Parquet with Snappy compression
- Metadata-driven pipelines
- Watermark-based incremental loading

## Pipeline Design

### Parent Pipeline
`PL_Parent_Orchestration`

Flow:

Lookup Watermark Table  
→ ForEach Table  
→ Execute Child Incremental Pipeline

### Child Incremental Pipeline
`PL_Child_IncrementalLoad`

Flow:

Lookup MAX Watermark  
→ IF New Records Exist  
→ Copy Incremental Records  
→ Execute Watermark Update Pipeline

### Watermark Update Pipeline
`PL_Child_UpdateWatermark`

Executes SQL Server stored procedure:

`dbo.UpdateWatermark`

## Watermark Table

Columns:

- TableSchema
- TableName
- WatermarkColumn
- LastLoadValue

Example:

| TableName | WatermarkColumn | LastLoadValue |
|---|---|---:|
| FactSales | SalesKey | 500003 |
| DimCustomer | CustomerKey | 10000 |
| FactOrders | OrderKey | 24964 |

## Incremental Logic

The pipeline compares:

Current `MAX(WatermarkColumn)`

with

`LastLoadValue`

If new records exist, only records greater than the previous watermark are copied.

Example:

Previous watermark:

`SalesKey = 500000`

New maximum:

`SalesKey = 500003`

Only records:

`500001, 500002, 500003`

are processed.

## ADLS Output

Files are stored dynamically as Parquet:

`retail-data/bronze/<TableName>/<TableName>_yyyyMMdd_HHmmss.parquet`

Example:

`retail-data/bronze/FactSales/FactSales_20260816_103844.parquet`

Timestamp-based filenames prevent incremental files from overwriting existing data.

## Tables Processed

The framework processes 20 dimension and fact tables including:

- DimCustomer
- DimProduct
- DimStore
- DimEmployee
- FactSales
- FactOrders
- FactPayments
- FactInventory
- FactReturns
- FactShipment
- FactProductPerformance

## Testing

Initial load:
- FactSales: 500,000 records

Incremental test:
- Added 3 new FactSales records
- Previous watermark: 500000
- New watermark: 500003
- Only 3 new records were processed

## Technologies Used

- Azure Data Factory
- Azure Data Lake Storage Gen2
- SQL Server
- Self-Hosted Integration Runtime
- T-SQL
- Parquet
- GitHub
