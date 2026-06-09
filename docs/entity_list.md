# Entity List and Attribute Description

## 1. Overview

This document describes the main entities and attributes of the **Financial Transaction OLTP Database** in the **AI-powered Financial Transaction Analytics Platform** project.

The design follows an EER-style structure. It includes superclass/subclass entities, core operational entities, lookup entities, weak entities, recursive relationships, and associative entities. This structure is intended to support ERD design, SQL schema design, and later extensions such as data warehouse, fraud detection, and risk monitoring.

---

## 2. Entity-Attribute Summary

### 2.1 `users`

**Purpose:** Stores common account information for all system users.

**Primary Key:**
- `user_id`

**Foreign Key:**
- None

**Attributes:**
- `username`
- `email`
- `phone_number`
- `address`
- `account_status`
- `registered_at`

---

### 2.2 `customers`

**Purpose:** Stores customer-specific information. This entity is a subclass of `users`.

**Primary Key:**
- `customer_id`

**Foreign Key:**
- `customer_id` references `users.user_id`

**Attributes:**
- `full_name`
- `gender`
- `date_of_birth`
- `kyc_status`
- `customer_segment`
- `customer_status`

---

### 2.3 `admins`

**Purpose:** Stores administrator-specific information. This entity is a subclass of `users`.

**Primary Key:**
- `admin_id`

**Foreign Key:**
- `admin_id` references `users.user_id`

**Attributes:**
- `role`
- `department`
- `admin_status`

---

### 2.4 `admin_permissions`

**Purpose:** Stores recursive permission delegation between administrators.

**Primary Key:**
- `grantor_admin_id`
- `grantee_admin_id`

**Foreign Key:**
- `grantor_admin_id` references `admins.admin_id`
- `grantee_admin_id` references `admins.admin_id`

**Attributes:**
- `granted_at`
- `permission_scope`
- `permission_content`

---

### 2.5 `branches`

**Purpose:** Stores information about bank branches or transaction offices.

**Primary Key:**
- `branch_id`

**Foreign Key:**
- None

**Attributes:**
- `branch_name`
- `branch_code`
- `city`
- `address`
- `status`

---

### 2.6 `currencies`

**Purpose:** Stores information about currencies used in accounts and transactions.

**Primary Key:**
- `currency_code`

**Foreign Key:**
- None

**Attributes:**
- `currency_name`
- `symbol`
- `country`

---

### 2.7 `accounts`

**Purpose:** Stores financial accounts owned by customers.

**Primary Key:**
- `account_id`

**Foreign Key:**
- `customer_id`
- `branch_id`
- `currency_code`

**Attributes:**
- `account_number`
- `account_type`
- `opened_date`
- `current_balance`
- `account_status`

---

### 2.8 `cards`

**Purpose:** Stores payment cards linked to accounts.

**Primary Key:**
- `card_id`

**Foreign Key:**
- `account_id`

**Attributes:**
- `card_number_masked`
- `card_type`
- `issued_date`
- `expiry_date`
- `card_status`

---

### 2.9 `channels`

**Purpose:** Stores transaction channels.

**Primary Key:**
- `channel_id`

**Foreign Key:**
- None

**Attributes:**
- `channel_name`
- `channel_type`
- `status`

---

### 2.10 `transaction_types`

**Purpose:** Stores transaction types.

**Primary Key:**
- `transaction_type_id`

**Foreign Key:**
- None

**Attributes:**
- `transaction_type_name`
- `description`

---

### 2.11 `merchant_categories`

**Purpose:** Stores merchant business categories.

**Primary Key:**
- `merchant_category_id`

**Foreign Key:**
- None

**Attributes:**
- `category_name`
- `risk_level`
- `description`

---

### 2.12 `merchants`

**Purpose:** Stores merchants that receive payments.

**Primary Key:**
- `merchant_id`

**Foreign Key:**
- `merchant_category_id`

**Attributes:**
- `merchant_code`
- `merchant_name`
- `country`
- `city`
- `status`

---

### 2.13 `transactions`

**Purpose:** Stores individual financial transactions generated in the system.

**Primary Key:**
- `transaction_id`

**Foreign Key:**
- `account_id`
- `card_id`
- `merchant_id`
- `channel_id`
- `transaction_type_id`
- `currency_code`

**Attributes:**
- `external_transaction_ref`
- `transaction_time`
- `amount`
- `status`
- `description`
- `created_at`

---

### 2.14 `transaction_status_history`

**Purpose:** Stores the status change history of a transaction. This is modeled as a weak entity identified by `transactions`.

**Primary Key:**
- `transaction_id`
- `status_sequence_no`

**Foreign Key:**
- `transaction_id`

**Attributes:**
- `old_status`
- `new_status`
- `changed_at`
- `reason`

---

### 2.15 `fee_rules`

**Purpose:** Stores fee calculation rules based on transaction type, channel, and currency.

**Primary Key:**
- `fee_rule_id`

**Foreign Key:**
- `transaction_type_id`
- `channel_id`
- `currency_code`

**Attributes:**
- `fixed_fee`
- `percentage_fee`
- `min_fee`
- `max_fee`
- `effective_from`
- `effective_to`
- `status`

---

### 2.16 `transaction_fee_charges`

**Purpose:** Stores actual fee charges applied to transactions.

**Primary Key:**
- `fee_charge_id`

**Foreign Key:**
- `transaction_id`
- `fee_rule_id`

**Attributes:**
- `fee_amount`
- `calculated_at`
- `calculation_note`

---

### 2.17 `fraud_rules`

**Purpose:** Stores rule-based conditions for detecting transaction risk or fraud.

**Primary Key:**
- `fraud_rule_id`

**Foreign Key:**
- None

**Attributes:**
- `rule_name`
- `rule_type`
- `threshold_value`
- `description`
- `is_active`

---

### 2.18 `risk_alerts`

**Purpose:** Stores risk alerts generated when a transaction shows suspicious behavior.

**Primary Key:**
- `alert_id`

**Foreign Key:**
- `transaction_id`
- `fraud_rule_id`

**Attributes:**
- `risk_score`
- `alert_status`
- `alert_reason`
- `created_at`
- `resolved_at`

---

### 2.19 `alert_reviews`

**Purpose:** Stores admin review actions for risk alerts.

**Primary Key:**
- `review_id`

**Foreign Key:**
- `alert_id`
- `admin_id`

**Attributes:**
- `reviewed_at`
- `review_decision`
- `review_note`

---

## 3. Entity Groups

### 3.1 User Entities

The system is organized around the superclass `users`. A user can be specialized into either a `customer` or an `admin`. Customers perform financial transactions, while admins manage permissions, monitor alerts, and review suspicious transactions.

### 3.2 Core Financial Entities

The core financial entities are `customers`, `accounts`, `cards`, and `transactions`. A customer can own many accounts. An account can have many cards and generate many transactions. The `transactions` entity is the central entity of the OLTP database.

### 3.3 Reference Entities

Reference entities include `branches`, `currencies`, `channels`, `transaction_types`, `merchant_categories`, and `merchants`. These entities normalize repeated business values and help support clean reporting and analytics.

### 3.4 Monitoring and Risk Entities

Monitoring and risk-related entities include `transaction_status_history`, `fee_rules`, `transaction_fee_charges`, `fraud_rules`, `risk_alerts`, and `alert_reviews`. These entities support transaction traceability, fee calculation, fraud detection, and alert investigation.
