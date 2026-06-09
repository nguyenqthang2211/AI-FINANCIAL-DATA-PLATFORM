# Day 04 - Project Foundation

## Goal

Set up the repository foundation for the 90-day AI Financial Data Platform project.

## Completed Tasks

- Created a new Git branch: `day-04-project-foundation`
- Created project folder structure for SQL Server, Spark, Airflow, streaming, ML, MLOps, RAG, Power BI, and tests
- Added `.gitkeep` files to preserve empty folders
- Added local data lake folders: raw, bronze, silver, and gold
- Added `.env.example`
- Added Docker Compose configuration for SQL Server
- Started SQL Server 2022 container locally
- Connected to SQL Server using SSMS
- Created `AI_Financial_OLTP` database
- Created initial schemas: `core`, `ref`, `txn`, `risk`, and `audit`
- Added initial OLTP database creation script
- Added architecture documentation

## Validation

The following schemas were successfully created in `AI_Financial_OLTP`:

- `audit`
- `core`
- `ref`
- `risk`
- `txn`

## Key Decision

The project will use SQL Server and T-SQL as the core database layer because the developer is already familiar with T-SQL.

Spark, Airflow, Kafka, MLflow, FastAPI, Power BI, and RAG will be added in later phases.

## Next Day Plan

Day 05 will focus on SQL Server OLTP user-related tables:

- `users`
- `customers`
- `admins`
- `admin_permissions`
