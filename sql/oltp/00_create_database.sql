/*
    Project: AI Financial Data Platform
    Script: 00_create_database.sql
    Purpose: Create OLTP database and schemas for financial transaction system
    Engine: SQL Server / T-SQL

    Note:
    This script is idempotent. It does not drop the database.
    It only creates the database and schemas if they do not already exist.
*/

USE master;
GO

IF DB_ID('AI_Financial_OLTP') IS NULL
BEGIN
    CREATE DATABASE AI_Financial_OLTP;
END;
GO

ALTER DATABASE AI_Financial_OLTP
SET MULTI_USER
WITH ROLLBACK IMMEDIATE;
GO

USE AI_Financial_OLTP;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core')
BEGIN
    EXEC('CREATE SCHEMA core');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ref')
BEGIN
    EXEC('CREATE SCHEMA ref');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'txn')
BEGIN
    EXEC('CREATE SCHEMA txn');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'risk')
BEGIN
    EXEC('CREATE SCHEMA risk');
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit')
BEGIN
    EXEC('CREATE SCHEMA audit');
END;
GO
