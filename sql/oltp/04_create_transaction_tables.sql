/*
    Project: FinPulse
    Script: 04_create_transaction_tables.sql
    Purpose: Create transaction and transaction status history tables
    Engine: SQL Server / T-SQL

    Notes:
    - This script creates the central transaction group based on the Chen-style EERD.
    - It implements:
        ACCOUNTS - Generates - TRANSACTIONS
        CARDS - Used In - TRANSACTIONS
        CHANNELS - Through - TRANSACTIONS
        TRANSACTION TYPE - Has Type - TRANSACTIONS
        CURRENCIES - Uses - TRANSACTIONS
        MERCHANTS - Occurred At - TRANSACTIONS
        TRANSACTIONS - Has Status History - TRANSACTION STATUS HISTORY

    - transaction_status_history is modeled as a weak entity.
    - The primary key of transaction_status_history is:
        transaction_id + status_sequence_no
*/

USE AI_Financial_OLTP;
GO

/* ============================================================
   Drop tables in dependency order for development reruns
   ============================================================ */

IF OBJECT_ID('txn.transaction_status_history', 'U') IS NOT NULL
    DROP TABLE txn.transaction_status_history;
GO

IF OBJECT_ID('txn.transactions', 'U') IS NOT NULL
    DROP TABLE txn.transactions;
GO

/* ============================================================
   Table: txn.transactions
   Entity: TRANSACTIONS
   Central transaction entity of the OLTP model
   ============================================================ */

CREATE TABLE txn.transactions (
    transaction_id          BIGINT IDENTITY(1,1) NOT NULL,
    account_id              BIGINT NOT NULL,
    card_id                 BIGINT NULL,
    channel_id              BIGINT NOT NULL,
    transaction_type_id     BIGINT NOT NULL,
    currency_code           CHAR(3) NOT NULL,
    merchant_id             BIGINT NULL,
    transaction_amount      DECIMAL(19,4) NOT NULL,
    transaction_time        DATETIME2(0) NOT NULL,
    reference_number        VARCHAR(100) NOT NULL,
    description             NVARCHAR(500) NULL,
    transaction_status      VARCHAR(30) NOT NULL,
    created_at              DATETIME2(0) NOT NULL,

    CONSTRAINT pk_txn_transactions
        PRIMARY KEY (transaction_id),

    CONSTRAINT uq_txn_transactions_reference_number
        UNIQUE (reference_number),

    CONSTRAINT fk_txn_transactions_accounts
        FOREIGN KEY (account_id)
        REFERENCES core.accounts(account_id),

    CONSTRAINT fk_txn_transactions_cards
        FOREIGN KEY (card_id)
        REFERENCES core.cards(card_id),

    CONSTRAINT fk_txn_transactions_channels
        FOREIGN KEY (channel_id)
        REFERENCES ref.channels(channel_id),

    CONSTRAINT fk_txn_transactions_transaction_types
        FOREIGN KEY (transaction_type_id)
        REFERENCES ref.transaction_types(transaction_type_id),

    CONSTRAINT fk_txn_transactions_currencies
        FOREIGN KEY (currency_code)
        REFERENCES ref.currencies(currency_code),

    CONSTRAINT fk_txn_transactions_merchants
        FOREIGN KEY (merchant_id)
        REFERENCES ref.merchants(merchant_id),

    CONSTRAINT ck_txn_transactions_amount
        CHECK (transaction_amount > 0),

    CONSTRAINT ck_txn_transactions_status
        CHECK (transaction_status IN (
            'PENDING',
            'PROCESSING',
            'SUCCESS',
            'FAILED',
            'REVERSED',
            'CANCELLED'
        ))
);
GO

/* ============================================================
   Table: txn.transaction_status_history
   Weak Entity: TRANSACTION STATUS HISTORY
   Identifying relationship:
   TRANSACTIONS - Has Status History - TRANSACTION STATUS HISTORY
   ============================================================ */

CREATE TABLE txn.transaction_status_history (
    transaction_id          BIGINT NOT NULL,
    status_sequence_no      INT NOT NULL,
    old_status              VARCHAR(30) NULL,
    new_status              VARCHAR(30) NOT NULL,
    changed_at              DATETIME2(0) NOT NULL,
    change_reason           NVARCHAR(500) NULL,

    CONSTRAINT pk_txn_transaction_status_history
        PRIMARY KEY (transaction_id, status_sequence_no),

    CONSTRAINT fk_txn_status_history_transactions
        FOREIGN KEY (transaction_id)
        REFERENCES txn.transactions(transaction_id),

    CONSTRAINT ck_txn_status_history_sequence_no
        CHECK (status_sequence_no > 0),

    CONSTRAINT ck_txn_status_history_old_status
        CHECK (
            old_status IN (
                'PENDING',
                'PROCESSING',
                'SUCCESS',
                'FAILED',
                'REVERSED',
                'CANCELLED'
            )
            OR old_status IS NULL
        ),

    CONSTRAINT ck_txn_status_history_new_status
        CHECK (new_status IN (
            'PENDING',
            'PROCESSING',
            'SUCCESS',
            'FAILED',
            'REVERSED',
            'CANCELLED'
        ))
);
GO
