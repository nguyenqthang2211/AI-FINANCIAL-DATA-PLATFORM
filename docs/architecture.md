# FinPulse - System Architecture

## Overview

FinPulse is designed as an end-to-end financial transaction data platform that covers operational data storage, analytical processing, fraud detection, business intelligence, machine learning, MLOps, and LLM/RAG-based knowledge retrieval.

## High-Level Architecture

```text
Synthetic Financial Data
        ↓
SQL Server OLTP Database
        ↓
Batch Extract / CDC-style Extract
        ↓
Data Lake: Raw / Bronze / Silver / Gold
        ↓
PySpark Batch Processing
        ↓
SQL Server Data Warehouse
        ↓
Power BI Dashboard
        ↓
Fraud Feature Engineering
        ↓
MLflow Experiment Tracking + Model Registry
        ↓
FastAPI Fraud Scoring Service
        ↓
Kafka Real-time Transaction Stream
        ↓
Streaming Fraud Alerts
        ↓
RAG Assistant for Business Rules, Data Dictionary, and Fraud Explanation
```

## Component Responsibilities

| Layer | Technology | Responsibility |
|---|---|---|
| OLTP | SQL Server, T-SQL | Store normalized operational financial transaction data |
| Data Generation | Python, Faker | Generate synthetic customers, accounts, cards, merchants, transactions, fees, and risk alerts |
| Data Lake | Local folders, Parquet | Store raw, bronze, silver, and gold datasets |
| Batch Processing | PySpark | Clean, transform, enrich, and aggregate transaction data |
| Orchestration | Airflow | Schedule and monitor batch workflows |
| Streaming | Kafka / Redpanda | Simulate real-time transaction events |
| Warehouse | SQL Server Data Warehouse | Store dimensional models for analytics and BI |
| BI | Power BI | Build dashboards for transaction, customer, merchant, and fraud monitoring |
| Data Science | Python, scikit-learn | Train and evaluate fraud detection models |
| MLOps | MLflow, FastAPI, Docker | Track experiments, register models, and serve fraud scoring APIs |
| AI Engineering | RAG, vector store, LLM | Build a question-answering assistant for business rules and data documentation |
| Governance | Data quality checks, masking, validation SQL | Improve data reliability and privacy awareness |

## Data Modeling Direction

The OLTP layer follows a normalized EER-style design centered around financial transactions. The model includes users, customers, admins, accounts, cards, merchants, transaction types, channels, fee rules, fraud rules, risk alerts, and alert reviews.

The analytical layer will transform the normalized OLTP model into a dimensional warehouse using fact and dimension tables.

## Security and Privacy

This project uses synthetic data only. No real customer or financial data should be committed to the repository.

Sensitive values must be stored in local `.env` files. Card numbers must be masked before storage or analysis.
