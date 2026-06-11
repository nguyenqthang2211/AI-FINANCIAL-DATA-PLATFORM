# System Architecture

## 1. Overview

FinPulse is an end-to-end financial data platform designed for a simulated bank or fintech environment.

The platform is built to demonstrate the full data lifecycle, from OLTP database design to analytical processing, business intelligence, fraud detection, MLOps, and future AI-powered financial data exploration.

The current implementation focuses on the OLTP conceptual and logical design. Later phases will extend the system into a complete modern data platform.

## 2. Architecture Goals

The main goals of the FinPulse architecture are:

* Design a realistic financial transaction OLTP system.
* Store structured banking and transaction data in SQL Server.
* Support transaction analytics, customer analytics, merchant analytics, fee analysis, and fraud monitoring.
* Prepare clean relational data for future data warehouse modeling.
* Support future batch processing, streaming processing, machine learning, MLOps, and RAG-based financial analysis.
* Use synthetic data only to avoid privacy and compliance risks.

## 3. High-Level Architecture

The complete FinPulse platform is planned with the following layers:

```text
Synthetic Data Sources
        |
        v
OLTP Database - SQL Server
        |
        v
Data Lake - Raw / Bronze / Silver / Gold
        |
        v
Batch Processing - PySpark
        |
        v
Data Warehouse
        |
        v
BI Dashboards - Power BI
        |
        v
Machine Learning - Fraud Detection
        |
        v
MLOps - Model Tracking and Deployment
        |
        v
RAG Assistant - Financial Data Q&A
```

## 4. Current Implementation Scope

The current phase focuses on the OLTP database foundation.

This includes:

* Business requirements definition
* Core entity identification
* Chen-style Enhanced Entity Relationship Diagram design
* Entity, attribute, and relationship modeling
* Superclass and subclass modeling
* Weak entity modeling
* Recursive relationship modeling
* Associative relationship modeling
* SQL Server database and schema preparation
* Future OLTP table creation using T-SQL

The OLTP design will be used as the source system for later analytical and machine learning components.

## 5. OLTP Conceptual Design

The OLTP database is designed using a Chen-style Enhanced Entity Relationship Diagram.

Diagram file:

```text
diagrams/finpulse_eerd_chen.png
```

Editable diagram source:

```text
diagrams/finpulse_eerd_chen.drawio
```

The EERD represents the main business entities and relationships of the financial transaction system.

It includes:

* User and administrator management
* Customer profile management
* Account and card management
* Branch and currency management
* Transaction processing
* Transaction status tracking
* Merchant and merchant category management
* Fee rule configuration
* Transaction fee charging
* Fraud rule configuration
* Risk alert monitoring
* Risk alert review
* Administrator permission delegation

## 6. OLTP Database Schemas

The SQL Server OLTP database is organized into multiple schemas to separate business domains clearly.

Planned schemas:

```text
core
ref
txn
risk
audit
```

### 6.1 core Schema

The `core` schema stores main operational business entities.

Main entities:

* `users`
* `customers`
* `admins`
* `admin_permissions`
* `branches`
* `accounts`
* `cards`

### 6.2 ref Schema

The `ref` schema stores reference and configuration data.

Main entities:

* `currencies`
* `channels`
* `transaction_types`
* `merchant_categories`
* `fee_rules`
* `fraud_rules`

### 6.3 txn Schema

The `txn` schema stores transaction-related data.

Main entities:

* `transactions`
* `transaction_status_history`
* `transaction_fee_charges`

### 6.4 risk Schema

The `risk` schema stores fraud monitoring and risk alert data.

Main entities:

* `risk_alerts`
* `alert_reviews`

### 6.5 audit Schema

The `audit` schema is reserved for future auditing and data change tracking.

Possible future entities:

* `audit_logs`
* `data_quality_checks`
* `pipeline_run_logs`

## 7. Key OLTP Design Concepts

### 7.1 Superclass and Subclass Design

The EERD models `users` as a superclass.

The subclasses are:

* `customers`
* `admins`

The specialization is total and disjoint:

* Every user must be either a customer or an admin.
* A user cannot be both a customer and an admin at the same time.

In the relational schema, this will be implemented using:

* A base `users` table
* A `customers` table referencing `users`
* An `admins` table referencing `users`

### 7.2 Recursive Relationship

The EERD models administrator permission delegation as a recursive relationship on `admins`.

Relationship:

```text
ADMINS — Grants Permission — ADMINS
```

Business meaning:

* One admin can grant permission to another admin.
* The same admin entity participates in the relationship with two roles:

  * Grantor
  * Grantee

This relationship will be implemented as the `admin_permissions` table.

### 7.3 Weak Entity

The EERD models `transaction_status_history` as a weak entity.

It depends on `transactions`.

Primary key:

```text
transaction_id + status_sequence_no
```

Business meaning:

* A transaction can have many status history records.
* Each status history record must belong to exactly one transaction.
* A status history record cannot exist without its parent transaction.

### 7.4 Associative Relationships

Some Chen-style relationships contain their own attributes. These relationships will become tables in the relational schema.

Examples:

```text
Grants Permission → admin_permissions
Charged Fee → transaction_fee_charges
Reviewed By → alert_reviews
```

This allows the relational schema to store many-to-many relationships with additional business attributes.

## 8. Main Data Flow

The expected OLTP transaction flow is:

```text
Customer
   |
   v
Account
   |
   v
Transaction
   |
   +--> Transaction Status History
   |
   +--> Transaction Fee Charge
   |
   +--> Risk Alert
```

A transaction may also be connected to:

* A card, if the transaction uses a card
* A merchant, if the transaction involves a merchant
* A channel, such as mobile banking, ATM, POS, internet banking, or branch
* A transaction type
* A currency

## 9. Future Data Platform Layers

### 9.1 Data Generation Layer

Synthetic financial data will be generated for:

* Users
* Customers
* Admins
* Accounts
* Cards
* Merchants
* Transactions
* Transaction status history
* Fee charges
* Fraud alerts
* Alert reviews

No real financial or personal data will be used.

### 9.2 Data Lake Layer

The data lake will store files across multiple zones:

```text
data/raw
data/bronze
data/silver
data/gold
```

Expected use:

* Raw zone: original extracted data
* Bronze zone: lightly cleaned data
* Silver zone: validated and standardized data
* Gold zone: analytics-ready data

### 9.3 Batch Processing Layer

PySpark will be used in future phases for:

* Data cleaning
* Data transformation
* Feature engineering
* Aggregation
* Large-scale transaction analysis

### 9.4 Data Warehouse Layer

The data warehouse will support analytical reporting.

Possible fact tables:

* `fact_transactions`
* `fact_transaction_fees`
* `fact_risk_alerts`

Possible dimension tables:

* `dim_customer`
* `dim_account`
* `dim_card`
* `dim_merchant`
* `dim_channel`
* `dim_transaction_type`
* `dim_currency`
* `dim_date`

### 9.5 BI Layer

Power BI dashboards will be built for:

* Transaction overview
* Channel performance
* Customer behavior
* Merchant performance
* Fee analysis
* Fraud and risk monitoring

### 9.6 Streaming Layer

Kafka may be used in future phases to simulate real-time financial transaction events.

Possible streaming use cases:

* Real-time transaction ingestion
* Real-time fraud alert generation
* Real-time transaction monitoring dashboard

### 9.7 Machine Learning Layer

Fraud detection models may be developed using transaction and risk-related features.

Possible ML tasks:

* Fraud classification
* Risk score prediction
* Suspicious transaction detection
* Alert prioritization

### 9.8 MLOps Layer

The MLOps layer may include:

* Experiment tracking
* Model versioning
* Model evaluation
* Batch scoring
* Model monitoring

### 9.9 RAG Assistant Layer

A future RAG-based assistant may support financial data Q&A.

Possible use cases:

* Ask questions about transaction trends
* Explain dashboard metrics
* Retrieve business definitions
* Search project documentation
* Support financial analyst workflows

## 10. Technology Stack

Planned technologies:

```text
Database: SQL Server
SQL Language: T-SQL
Diagram Tool: draw.io / diagrams.net
Data Processing: Python, PySpark
Workflow Orchestration: Apache Airflow
Streaming: Apache Kafka
Data Visualization: Power BI
Machine Learning: scikit-learn / Python ML stack
MLOps: MLflow
Version Control: Git and GitHub
Containerization: Docker
```

## 11. Design Principles

The FinPulse architecture follows these principles:

* Use a realistic financial transaction domain.
* Keep OLTP data normalized.
* Separate operational, reference, transaction, risk, and audit domains.
* Use synthetic data only.
* Design the OLTP layer as the source system for analytics.
* Keep documentation aligned with the EERD and SQL implementation.
* Build the project incrementally from database foundation to AI-powered analytics.
