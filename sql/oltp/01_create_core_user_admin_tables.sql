/*
    Project: FinPulse
    Script: 01_create_core_user_admin_tables.sql
    Purpose: Create core user, customer, admin, and admin permission tables
    Engine: SQL Server / T-SQL

    Notes:
    - This script creates the first OLTP table group based on the Chen-style EERD.
    - It implements the USERS superclass, CUSTOMERS and ADMINS subclasses,
      and the recursive Grants Permission relationship between ADMINS.
*/

USE AI_Financial_OLTP;
GO

/* ============================================================
   Drop tables in dependency order for development reruns
   ============================================================ */

IF OBJECT_ID('core.admin_permissions', 'U') IS NOT NULL
    DROP TABLE core.admin_permissions;
GO

IF OBJECT_ID('core.customers', 'U') IS NOT NULL
    DROP TABLE core.customers;
GO

IF OBJECT_ID('core.admins', 'U') IS NOT NULL
    DROP TABLE core.admins;
GO

IF OBJECT_ID('core.users', 'U') IS NOT NULL
    DROP TABLE core.users;
GO

/* ============================================================
   Table: core.users
   Superclass entity for customers and admins
   ============================================================ */

CREATE TABLE core.users (
    user_id             BIGINT IDENTITY(1,1) NOT NULL,
    username            NVARCHAR(100) NOT NULL,
    phone               VARCHAR(20) NULL,
    email               NVARCHAR(255) NOT NULL,
    address             NVARCHAR(500) NULL,
    account_status      VARCHAR(30) NOT NULL,
    registered_at       DATETIME2(0) NOT NULL,

    CONSTRAINT pk_core_users
        PRIMARY KEY (user_id),

    CONSTRAINT uq_core_users_username
        UNIQUE (username),

    CONSTRAINT uq_core_users_email
        UNIQUE (email),

    CONSTRAINT ck_core_users_account_status
        CHECK (account_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'CLOSED'))
);
GO

/* ============================================================
   Table: core.customers
   Subclass of users
   ============================================================ */

CREATE TABLE core.customers (
    customer_id         BIGINT IDENTITY(1,1) NOT NULL,
    user_id             BIGINT NOT NULL,
    first_name          NVARCHAR(100) NOT NULL,
    middle_initial      NVARCHAR(10) NULL,
    last_name           NVARCHAR(100) NOT NULL,
    gender              VARCHAR(20) NULL,
    date_of_birth       DATE NULL,
    kyc_status          VARCHAR(30) NOT NULL,
    customer_segment    VARCHAR(50) NOT NULL,
    customer_status     VARCHAR(30) NOT NULL,

    CONSTRAINT pk_core_customers
        PRIMARY KEY (customer_id),

    CONSTRAINT uq_core_customers_user_id
        UNIQUE (user_id),

    CONSTRAINT fk_core_customers_users
        FOREIGN KEY (user_id)
        REFERENCES core.users(user_id),

    CONSTRAINT ck_core_customers_gender
        CHECK (gender IN ('MALE', 'FEMALE', 'OTHER', 'UNKNOWN') OR gender IS NULL),

    CONSTRAINT ck_core_customers_kyc_status
        CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED', 'EXPIRED')),

    CONSTRAINT ck_core_customers_customer_segment
        CHECK (customer_segment IN ('RETAIL', 'PREMIUM', 'BUSINESS', 'VIP')),

    CONSTRAINT ck_core_customers_customer_status
        CHECK (customer_status IN ('ACTIVE', 'INACTIVE', 'BLOCKED', 'CLOSED'))
);
GO

/* ============================================================
   Table: core.admins
   Subclass of users
   ============================================================ */

CREATE TABLE core.admins (
    admin_id            BIGINT IDENTITY(1,1) NOT NULL,
    user_id             BIGINT NOT NULL,
    role                VARCHAR(50) NOT NULL,
    department          VARCHAR(100) NOT NULL,
    admin_status        VARCHAR(30) NOT NULL,

    CONSTRAINT pk_core_admins
        PRIMARY KEY (admin_id),

    CONSTRAINT uq_core_admins_user_id
        UNIQUE (user_id),

    CONSTRAINT fk_core_admins_users
        FOREIGN KEY (user_id)
        REFERENCES core.users(user_id),

    CONSTRAINT ck_core_admins_role
        CHECK (role IN ('SUPER_ADMIN', 'RISK_ANALYST', 'FRAUD_ANALYST', 'OPERATIONS_ADMIN', 'DATA_ADMIN')),

    CONSTRAINT ck_core_admins_admin_status
        CHECK (admin_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
);
GO

/* ============================================================
   Table: core.admin_permissions
   Associative table from recursive relationship:
   ADMINS - Grants Permission - ADMINS
   ============================================================ */

CREATE TABLE core.admin_permissions (
    admin_permission_id     BIGINT IDENTITY(1,1) NOT NULL,
    grantor_admin_id        BIGINT NOT NULL,
    grantee_admin_id        BIGINT NOT NULL,
    granted_at              DATETIME2(0) NOT NULL,
    permission_scope        VARCHAR(100) NOT NULL,
    permission_content      NVARCHAR(500) NOT NULL,

    CONSTRAINT pk_core_admin_permissions
        PRIMARY KEY (admin_permission_id),

    CONSTRAINT fk_core_admin_permissions_grantor
        FOREIGN KEY (grantor_admin_id)
        REFERENCES core.admins(admin_id),

    CONSTRAINT fk_core_admin_permissions_grantee
        FOREIGN KEY (grantee_admin_id)
        REFERENCES core.admins(admin_id),

    CONSTRAINT ck_core_admin_permissions_not_self
        CHECK (grantor_admin_id <> grantee_admin_id)
);
GO
