# Entity List

## 1. Overview

This document defines the main entities used in the FinPulse OLTP database design.

The entity list is based on the Chen-style Enhanced Entity Relationship Diagram of the financial transaction system.

The OLTP model contains entities for user management, customer management, account and card management, transaction processing, merchant management, fee charging, fraud rule monitoring, and risk alert review.

This project uses synthetic data only. No real customer data, card data, or financial data is used.

## 2. Naming Convention

The EERD uses business-friendly entity and attribute names.

The relational database implementation will use snake_case naming convention.

Examples:

* `UserID` → `user_id`
* `CustomerID` → `customer_id`
* `TransactionID` → `transaction_id`
* `RiskID` → `risk_alert_id`
* `FeeID` → `fee_rule_id`
* `ReviewedID` → `review_id`
* `Transaction Type` → `transaction_type`

## 3. Entity Groups

The OLTP entities are grouped into the following business domains:

* User and administrator management
* Customer management
* Account and card management
* Reference and configuration data
* Merchant management
* Transaction processing
* Fee management
* Fraud and risk management

## 4. Core Entities

## 4.1 users

### Description

The `users` entity stores common user information shared by both customers and administrators.

In the EERD, `users` is the superclass of `customers` and `admins`.

### Primary Key

* `user_id`

### Attributes

* `username`
* `phone`
* `email`
* `address`
* `account_status`
* `registered_at`

### Notes

* Every user must be either a customer or an admin.
* A user cannot be both a customer and an admin at the same time.
* This is modeled as total and disjoint specialization in the EERD.

## 4.2 customers

### Description

The `customers` entity stores customer-specific information.

A customer is a subclass of `users`.

### Primary Key

* `customer_id`

### Foreign Key

* `user_id`

### Attributes

* `first_name`
* `middle_initial`
* `last_name`
* `gender`
* `date_of_birth`
* `kyc_status`
* `customer_segment`
* `customer_status`

### Notes

* In the EERD, customer name is represented as a composite attribute:

  * `Name`
  * `FName`
  * `MInit`
  * `LName`
* In the relational schema, the composite name is mapped into atomic columns:

  * `first_name`
  * `middle_initial`
  * `last_name`

## 4.3 admins

### Description

The `admins` entity stores administrator-specific information.

An admin is a subclass of `users`.

### Primary Key

* `admin_id`

### Foreign Key

* `user_id`

### Attributes

* `role`
* `department`
* `admin_status`

### Notes

* Admins can review risk alerts.
* Admins can grant permissions to other admins through a recursive relationship.

## 4.4 admin_permissions

### Description

The `admin_permissions` entity stores permission delegation between administrators.

This table is created from the recursive relationship:

`ADMINS — Grants Permission — ADMINS`

### Primary Key

* `admin_permission_id`

### Foreign Keys

* `grantor_admin_id`
* `grantee_admin_id`

### Attributes

* `granted_at`
* `permission_scope`
* `permission_content`

### Notes

* `grantor_admin_id` references the admin who grants the permission.
* `grantee_admin_id` references the admin who receives the permission.
* This is a recursive many-to-many relationship on the `admins` entity.

## 4.5 branches

### Description

The `branches` entity stores bank branch information.

A branch can manage multiple accounts.

### Primary Key

* `branch_id`

### Attributes

* `branch_name`
* `branch_code`
* `city`
* `address`
* `branch_status`

### Notes

* Each account must be managed by one branch.
* A branch can manage zero or many accounts.

## 4.6 accounts

### Description

The `accounts` entity stores customer bank account information.

Each account belongs to one customer, is managed by one branch, and is denominated in one currency.

### Primary Key

* `account_id`

### Foreign Keys

* `customer_id`
* `branch_id`
* `currency_code`

### Attributes

* `account_number`
* `account_type`
* `balance`
* `opened_date`
* `account_status`

### Notes

* A customer can own multiple accounts.
* Each account must belong to exactly one customer.
* Each account must be managed by exactly one branch.
* Each account must use exactly one currency.
* An account can have zero or many cards.
* An account can generate zero or many transactions.

## 4.7 cards

### Description

The `cards` entity stores payment card information linked to customer accounts.

### Primary Key

* `card_id`

### Foreign Key

* `account_id`

### Attributes

* `masked_card_number`
* `card_type`
* `expiry_date`
* `card_status`

### Notes

* A card must belong to exactly one account.
* An account can have zero or many cards.
* Only masked card numbers are stored.
* Full card numbers must not be stored.
* A transaction may or may not use a card.

## 5. Reference and Configuration Entities

## 5.1 currencies

### Description

The `currencies` entity stores currency reference data.

### Primary Key

* `currency_code`

### Attributes

* `currency_name`
* `symbol`
* `country`

### Notes

* Each account must use one currency.
* Each transaction must use one currency.
* Fee rules are also configured by currency.

## 5.2 channels

### Description

The `channels` entity stores banking and payment channel information.

Examples include mobile banking, internet banking, ATM, POS, and branch.

### Primary Key

* `channel_id`

### Attributes

* `channel_name`
* `channel_type`
* `channel_status`

### Notes

* Each transaction must be processed through one channel.
* Fee rules are configured by channel.

## 5.3 transaction_types

### Description

The `transaction_types` entity stores transaction type reference data.

Examples include deposit, withdrawal, transfer, payment, refund, and reversal.

### Primary Key

* `transaction_type_id`

### Attributes

* `transaction_type_name`
* `description`

### Notes

* Each transaction must have one transaction type.
* Fee rules are configured by transaction type.

## 5.4 merchant_categories

### Description

The `merchant_categories` entity stores merchant category information.

Examples include retail, restaurant, travel, entertainment, utilities, and online services.

### Primary Key

* `merchant_category_id`

### Attributes

* `category_name`
* `risk_level`
* `description`

### Notes

* A merchant category can contain many merchants.
* Each merchant must belong to one merchant category.

## 5.5 merchants

### Description

The `merchants` entity stores merchant information.

A merchant is a business or organization involved in payment transactions.

### Primary Key

* `merchant_id`

### Foreign Key

* `merchant_category_id`

### Attributes

* `merchant_code`
* `merchant_name`
* `country`
* `city`
* `merchant_status`

### Notes

* Each merchant must belong to one merchant category.
* A merchant can be involved in zero or many transactions.
* A transaction may or may not involve a merchant.

## 5.6 fee_rules

### Description

The `fee_rules` entity stores fee configuration rules for transactions.

Fee rules are configured by transaction type, channel, and currency.

### Primary Key

* `fee_rule_id`

### Foreign Keys

* `transaction_type_id`
* `channel_id`
* `currency_code`

### Attributes

* `fixed_fee`
* `percentage`
* `minimum_amount`
* `maximum_amount`
* `valid_from`
* `valid_to`
* `fee_rule_status`

### Notes

* A fee rule applies to one transaction type.
* A fee rule applies through one channel.
* A fee rule applies in one currency.
* A transaction can have zero or many fee charges.
* A fee rule can be applied to zero or many transactions.

## 5.7 fraud_rules

### Description

The `fraud_rules` entity stores fraud detection rule configurations.

Fraud rules are used to generate risk alerts for suspicious transactions.

### Primary Key

* `fraud_rule_id`

### Attributes

* `rule_name`
* `rule_type`
* `threshold_value`
* `description`
* `is_active`

### Notes

* A fraud rule can generate zero or many risk alerts.
* Each risk alert must be based on one fraud rule.

## 6. Transaction Entities

## 6.1 transactions

### Description

The `transactions` entity is the central entity of the OLTP model.

It stores financial transaction records generated by customer accounts.

### Primary Key

* `transaction_id`

### Foreign Keys

* `account_id`
* `card_id`
* `channel_id`
* `transaction_type_id`
* `currency_code`
* `merchant_id`

### Attributes

* `transaction_amount`
* `transaction_time`
* `reference_number`
* `description`
* `transaction_status`
* `created_at`

### Notes

* Each transaction must belong to exactly one account.
* Each transaction must have one transaction type.
* Each transaction must be processed through one channel.
* Each transaction must use one currency.
* A transaction may or may not use a card.
* A transaction may or may not involve a merchant.
* A transaction can have multiple status history records.
* A transaction can have zero or many fee charges.
* A transaction can trigger zero or many risk alerts.

### Nullable Foreign Keys

The following foreign keys are optional:

* `card_id`
* `merchant_id`

Reason:

* Some transactions do not use cards.
* Some transactions do not involve merchants.

## 6.2 transaction_status_history

### Description

The `transaction_status_history` entity stores the status change history of each transaction.

In the EERD, this is modeled as a weak entity.

### Primary Key

Composite primary key:

* `transaction_id`
* `status_sequence_no`

### Foreign Key

* `transaction_id`

### Attributes

* `old_status`
* `new_status`
* `changed_at`
* `change_reason`

### Notes

* A transaction can have many status history records.
* Each status history record must belong to exactly one transaction.
* A status history record cannot exist without its parent transaction.
* The combination of `transaction_id` and `status_sequence_no` uniquely identifies each status history record.

## 6.3 transaction_fee_charges

### Description

The `transaction_fee_charges` entity stores actual fee charges applied to transactions.

This table is created from the associative relationship:

`TRANSACTIONS — Charged Fee — FEE RULES`

### Primary Key

* `fee_charge_id`

### Foreign Keys

* `transaction_id`
* `fee_rule_id`

### Attributes

* `fee_amount`
* `calculated_at`
* `calculation_note`

### Notes

* `fee_amount` stores the actual calculated fee for a transaction.
* A transaction can have zero or many fee charges.
* A fee rule can be applied to zero or many transactions.
* `fee_amount` is different from `fixed_fee` in `fee_rules`.
* `fixed_fee` is a configuration value.
* `fee_amount` is the actual charged value.

## 7. Risk Management Entities

## 7.1 risk_alerts

### Description

The `risk_alerts` entity stores suspicious transaction alerts.

Risk alerts are generated when a transaction matches a fraud rule or receives a high risk score.

### Primary Key

* `risk_alert_id`

### Foreign Keys

* `transaction_id`
* `fraud_rule_id`

### Attributes

* `risk_score`
* `risk_reason`
* `alert_status`
* `created_at`
* `resolved_at`

### Notes

* A transaction can trigger zero or many risk alerts.
* Each risk alert must belong to exactly one transaction.
* Each risk alert must be based on exactly one fraud rule.
* A risk alert may or may not be reviewed by an admin.

## 7.2 alert_reviews

### Description

The `alert_reviews` entity stores admin reviews of risk alerts.

This table is created from the associative relationship:

`ADMINS — Reviewed By — RISK ALERTS`

### Primary Key

* `review_id`

### Foreign Keys

* `risk_alert_id`
* `admin_id`

### Attributes

* `reviewed_at`
* `review_decision`
* `review_note`

### Notes

* An admin can review zero or many risk alerts.
* A risk alert can be reviewed by zero or many admins.
* A risk alert may remain unreviewed.
* Review information is stored separately from the risk alert itself.

## 8. Summary of Entities

| No. | Entity                       | Main Purpose                         |
| --: | ---------------------------- | ------------------------------------ |
|   1 | `users`                      | Common user information              |
|   2 | `customers`                  | Customer-specific information        |
|   3 | `admins`                     | Administrator-specific information   |
|   4 | `admin_permissions`          | Permission delegation between admins |
|   5 | `branches`                   | Bank branch information              |
|   6 | `currencies`                 | Currency reference data              |
|   7 | `accounts`                   | Customer bank accounts               |
|   8 | `cards`                      | Payment cards linked to accounts     |
|   9 | `channels`                   | Banking and payment channels         |
|  10 | `transaction_types`          | Transaction type reference data      |
|  11 | `merchant_categories`        | Merchant category information        |
|  12 | `merchants`                  | Merchant information                 |
|  13 | `transactions`               | Financial transaction records        |
|  14 | `transaction_status_history` | Transaction status change history    |
|  15 | `fee_rules`                  | Transaction fee configuration rules  |
|  16 | `transaction_fee_charges`    | Actual transaction fee charges       |
|  17 | `fraud_rules`                | Fraud detection rule configurations  |
|  18 | `risk_alerts`                | Suspicious transaction alerts        |
|  19 | `alert_reviews`              | Admin reviews of risk alerts         |

## 9. EERD-to-Relational Mapping Notes

The Chen-style EERD contains several conceptual modeling features.

When mapping to the relational schema:

* The `users` superclass is mapped to a base `users` table.
* The `customers` subclass is mapped to a separate table referencing `users`.
* The `admins` subclass is mapped to a separate table referencing `users`.
* The recursive relationship `Grants Permission` is mapped to `admin_permissions`.
* The weak entity `Transaction Status History` is mapped to `transaction_status_history`.
* The associative relationship `Charged Fee` is mapped to `transaction_fee_charges`.
* The associative relationship `Reviewed By` is mapped to `alert_reviews`.
* The composite customer name is mapped into atomic columns:

  * `first_name`
  * `middle_initial`
  * `last_name`
* No derived attributes are stored directly in the OLTP schema.
