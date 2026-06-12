/*
    Project: FinPulse
    Script: 02_create_account_card_tables.sql
    Purpose: Create branch, currency, account, and card tables
    Engine: SQL Server / T-SQL

    Notes:
    - This script creates the account core group based on the Chen-style EERD.
    - It implements:
        BRANCHES - Manages - ACCOUNTS
        CURRENCIES - Denominated In - ACCOUNTS
        CUSTOMERS - Owns - ACCOUNTS
        ACCOUNTS - Has - CARDS
*/

USE AI_Financial_OLTP;
GO

/* ============================================================
   Drop tables in dependency order for development reruns
   ============================================================ */

IF OBJECT_ID('core.cards', 'U') IS NOT NULL
    DROP TABLE core.cards;
GO

IF OBJECT_ID('core.accounts', 'U') IS NOT NULL
    DROP TABLE core.accounts;
GO

IF OBJECT_ID('core.branches', 'U') IS NOT NULL
    DROP TABLE core.branches;
GO

IF OBJECT_ID('ref.currencies', 'U') IS NOT NULL
    DROP TABLE ref.currencies;
GO

/* ============================================================
   Table: core.branches
   Entity: BRANCHES
   ============================================================ */

CREATE TABLE core.branches (
    branch_id          BIGINT IDENTITY(1,1) NOT NULL,
    branch_name        NVARCHAR(150) NOT NULL,
    branch_code        VARCHAR(30) NOT NULL,
    city               NVARCHAR(100) NOT NULL,
    address            NVARCHAR(500) NULL,
    branch_status      VARCHAR(30) NOT NULL,

    CONSTRAINT pk_core_branches
        PRIMARY KEY (branch_id),

    CONSTRAINT uq_core_branches_branch_code
        UNIQUE (branch_code),

    CONSTRAINT ck_core_branches_branch_status
        CHECK (branch_status IN ('ACTIVE', 'INACTIVE', 'CLOSED'))
);
GO

/* ============================================================
   Table: ref.currencies
   Entity: CURRENCIES
   ============================================================ */

CREATE TABLE ref.currencies (
    currency_code      CHAR(3) NOT NULL,
    currency_name      NVARCHAR(100) NOT NULL,
    symbol             NVARCHAR(10) NOT NULL,
    country            NVARCHAR(100) NOT NULL,

    CONSTRAINT pk_ref_currencies
        PRIMARY KEY (currency_code),

    CONSTRAINT uq_ref_currencies_currency_name
        UNIQUE (currency_name)
);
GO

/* ============================================================
   Table: core.accounts
   Entity: ACCOUNTS
   Relationships:
   - CUSTOMERS 1 - Owns - N ACCOUNTS
   - BRANCHES 1 - Manages - N ACCOUNTS
   - CURRENCIES 1 - Denominated In - N ACCOUNTS
   ============================================================ */

CREATE TABLE core.accounts (
    account_id         BIGINT IDENTITY(1,1) NOT NULL,
    customer_id        BIGINT NOT NULL,
    branch_id          BIGINT NOT NULL,
    currency_code      CHAR(3) NOT NULL,
    account_number     VARCHAR(50) NOT NULL,
    account_type       VARCHAR(30) NOT NULL,
    balance            DECIMAL(19,4) NOT NULL,
    opened_date        DATE NOT NULL,
    account_status     VARCHAR(30) NOT NULL,

    CONSTRAINT pk_core_accounts
        PRIMARY KEY (account_id),

    CONSTRAINT uq_core_accounts_account_number
        UNIQUE (account_number),

    CONSTRAINT fk_core_accounts_customers
        FOREIGN KEY (customer_id)
        REFERENCES core.customers(customer_id),

    CONSTRAINT fk_core_accounts_branches
        FOREIGN KEY (branch_id)
        REFERENCES core.branches(branch_id),

    CONSTRAINT fk_core_accounts_currencies
        FOREIGN KEY (currency_code)
        REFERENCES ref.currencies(currency_code),

    CONSTRAINT ck_core_accounts_account_type
        CHECK (account_type IN ('SAVINGS', 'CURRENT', 'CHECKING', 'PAYMENT', 'LOAN')),

    CONSTRAINT ck_core_accounts_balance
        CHECK (balance >= 0),

    CONSTRAINT ck_core_accounts_account_status
        CHECK (account_status IN ('ACTIVE', 'INACTIVE', 'FROZEN', 'CLOSED'))
);
GO

/* ============================================================
   Table: core.cards
   Entity: CARDS
   Relationship:
   - ACCOUNTS 1 - Has - N CARDS
   ============================================================ */

CREATE TABLE core.cards (
    card_id             BIGINT IDENTITY(1,1) NOT NULL,
    account_id          BIGINT NOT NULL,
    masked_card_number  VARCHAR(30) NOT NULL,
    card_type           VARCHAR(30) NOT NULL,
    expiry_date         DATE NOT NULL,
    card_status         VARCHAR(30) NOT NULL,

    CONSTRAINT pk_core_cards
        PRIMARY KEY (card_id),

    CONSTRAINT uq_core_cards_masked_card_number
        UNIQUE (masked_card_number),

    CONSTRAINT fk_core_cards_accounts
        FOREIGN KEY (account_id)
        REFERENCES core.accounts(account_id),

    CONSTRAINT ck_core_cards_card_type
        CHECK (card_type IN ('DEBIT', 'CREDIT', 'PREPAID', 'VIRTUAL')),

    CONSTRAINT ck_core_cards_card_status
        CHECK (card_status IN ('ACTIVE', 'INACTIVE', 'BLOCKED', 'EXPIRED', 'CANCELLED'))
);
GO
