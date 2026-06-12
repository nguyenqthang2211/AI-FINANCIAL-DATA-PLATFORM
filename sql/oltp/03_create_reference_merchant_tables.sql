/*
    Project: FinPulse
    Script: 03_create_reference_merchant_tables.sql
    Purpose: Create channel, transaction type, merchant category, and merchant tables
    Engine: SQL Server / T-SQL

    Notes:
    - This script creates reference and merchant-related tables based on the Chen-style EERD.
    - It implements:
        CHANNELS
        TRANSACTION TYPE
        MERCHANT CATEGORIES - Belonged To - MERCHANTS
*/

USE AI_Financial_OLTP;
GO

/* ============================================================
   Drop tables in dependency order for development reruns
   ============================================================ */

IF OBJECT_ID('ref.merchants', 'U') IS NOT NULL
    DROP TABLE ref.merchants;
GO

IF OBJECT_ID('ref.merchant_categories', 'U') IS NOT NULL
    DROP TABLE ref.merchant_categories;
GO

IF OBJECT_ID('ref.transaction_types', 'U') IS NOT NULL
    DROP TABLE ref.transaction_types;
GO

IF OBJECT_ID('ref.channels', 'U') IS NOT NULL
    DROP TABLE ref.channels;
GO

/* ============================================================
   Table: ref.channels
   Entity: CHANNELS
   ============================================================ */

CREATE TABLE ref.channels (
    channel_id          BIGINT IDENTITY(1,1) NOT NULL,
    channel_name        NVARCHAR(100) NOT NULL,
    channel_type        VARCHAR(50) NOT NULL,
    channel_status      VARCHAR(30) NOT NULL,

    CONSTRAINT pk_ref_channels
        PRIMARY KEY (channel_id),

    CONSTRAINT uq_ref_channels_channel_name
        UNIQUE (channel_name),

    CONSTRAINT ck_ref_channels_channel_type
        CHECK (channel_type IN ('DIGITAL', 'ATM', 'POS', 'BRANCH', 'API')),

    CONSTRAINT ck_ref_channels_channel_status
        CHECK (channel_status IN ('ACTIVE', 'INACTIVE', 'DISABLED'))
);
GO

/* ============================================================
   Table: ref.transaction_types
   Entity: TRANSACTION TYPE
   ============================================================ */

CREATE TABLE ref.transaction_types (
    transaction_type_id      BIGINT IDENTITY(1,1) NOT NULL,
    transaction_type_name    NVARCHAR(100) NOT NULL,
    description              NVARCHAR(500) NULL,

    CONSTRAINT pk_ref_transaction_types
        PRIMARY KEY (transaction_type_id),

    CONSTRAINT uq_ref_transaction_types_name
        UNIQUE (transaction_type_name)
);
GO

/* ============================================================
   Table: ref.merchant_categories
   Entity: MERCHANT CATEGORIES
   ============================================================ */

CREATE TABLE ref.merchant_categories (
    merchant_category_id     BIGINT IDENTITY(1,1) NOT NULL,
    category_name            NVARCHAR(150) NOT NULL,
    risk_level               VARCHAR(30) NOT NULL,
    description              NVARCHAR(500) NULL,

    CONSTRAINT pk_ref_merchant_categories
        PRIMARY KEY (merchant_category_id),

    CONSTRAINT uq_ref_merchant_categories_name
        UNIQUE (category_name),

    CONSTRAINT ck_ref_merchant_categories_risk_level
        CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);
GO

/* ============================================================
   Table: ref.merchants
   Entity: MERCHANTS
   Relationship:
   - MERCHANT CATEGORIES 1 - Belonged To - N MERCHANTS
   ============================================================ */

CREATE TABLE ref.merchants (
    merchant_id              BIGINT IDENTITY(1,1) NOT NULL,
    merchant_category_id     BIGINT NOT NULL,
    merchant_code            VARCHAR(50) NOT NULL,
    merchant_name            NVARCHAR(200) NOT NULL,
    country                  NVARCHAR(100) NOT NULL,
    city                     NVARCHAR(100) NOT NULL,
    merchant_status          VARCHAR(30) NOT NULL,

    CONSTRAINT pk_ref_merchants
        PRIMARY KEY (merchant_id),

    CONSTRAINT uq_ref_merchants_merchant_code
        UNIQUE (merchant_code),

    CONSTRAINT fk_ref_merchants_merchant_categories
        FOREIGN KEY (merchant_category_id)
        REFERENCES ref.merchant_categories(merchant_category_id),

    CONSTRAINT ck_ref_merchants_merchant_status
        CHECK (merchant_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'CLOSED'))
);
GO
