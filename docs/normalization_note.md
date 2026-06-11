# Normalization Note

## 1. Overview

This document explains the normalization decisions used in the FinPulse OLTP database design.

The FinPulse OLTP model is designed for a simulated financial transaction system. It supports customer management, administrator management, account management, card management, transaction processing, fee charging, fraud rule monitoring, and risk alert review.

The database design follows normalization principles to reduce redundancy, improve data consistency, and prepare the OLTP layer for future analytics, data warehouse modeling, machine learning, and reporting.

This project uses synthetic data only. No real customer data, card data, or financial data is used.

## 2. Normalization Goals

The main goals of normalization in this project are:

* Avoid duplicate data.
* Keep each entity focused on one business concept.
* Separate reference data from transaction data.
* Avoid repeating groups inside a table.
* Store many-to-many relationships in separate associative tables.
* Keep status history separate from the main transaction table.
* Keep fee configuration separate from actual fee charges.
* Keep fraud rule configuration separate from generated risk alerts.
* Make the OLTP schema easier to maintain, validate, and extend.

## 3. First Normal Form

A table is in First Normal Form when:

* Each column stores atomic values.
* There are no repeating groups.
* Each row can be uniquely identified by a primary key.

The FinPulse design satisfies First Normal Form because each table stores atomic attributes.

Examples:

* Customer name is mapped into atomic attributes:

  * `first_name`
  * `middle_initial`
  * `last_name`
* A card stores only one masked card number in `masked_card_number`.
* A transaction stores one transaction amount in `transaction_amount`.
* A transaction stores one transaction type through `transaction_type_id`.
* A transaction stores one channel through `channel_id`.
* Multiple status changes are not stored as repeated columns in `transactions`; they are stored in `transaction_status_history`.

Bad design example:

```text
transactions(transaction_id, status_1, status_2, status_3)
```

Normalized design:

```text
transactions(transaction_id, ...)
transaction_status_history(transaction_id, status_sequence_no, old_status, new_status, changed_at, change_reason)
```

## 4. Second Normal Form

A table is in Second Normal Form when:

* It is already in First Normal Form.
* Every non-key attribute depends on the whole primary key.
* Partial dependency is removed.

Most tables in the FinPulse OLTP model use a single-column primary key, so they naturally satisfy Second Normal Form.

The main table that needs special attention is `transaction_status_history`, because it uses a composite primary key.

Composite primary key:

```text
transaction_id + status_sequence_no
```

The non-key attributes depend on the full composite key:

* `old_status`
* `new_status`
* `changed_at`
* `change_reason`

These attributes describe one specific status change record for one specific transaction and one specific sequence number.

They do not depend only on `transaction_id`, and they do not depend only on `status_sequence_no`.

Therefore, `transaction_status_history` satisfies Second Normal Form.

## 5. Third Normal Form

A table is in Third Normal Form when:

* It is already in Second Normal Form.
* Non-key attributes do not depend on other non-key attributes.
* Transitive dependency is removed.

The FinPulse design satisfies Third Normal Form by separating lookup, reference, and configuration data into separate tables.

Examples:

### 5.1 Currency Data

Bad design example:

```text
accounts(account_id, account_number, currency_code, currency_name, currency_symbol)
```

Problem:

* `currency_name` and `currency_symbol` depend on `currency_code`, not directly on `account_id`.

Normalized design:

```text
accounts(account_id, account_number, currency_code, ...)
currencies(currency_code, currency_name, symbol, country)
```

### 5.2 Channel Data

Bad design example:

```text
transactions(transaction_id, channel_id, channel_name, channel_type)
```

Problem:

* `channel_name` and `channel_type` depend on `channel_id`, not directly on `transaction_id`.

Normalized design:

```text
transactions(transaction_id, channel_id, ...)
channels(channel_id, channel_name, channel_type, channel_status)
```

### 5.3 Transaction Type Data

Bad design example:

```text
transactions(transaction_id, transaction_type_id, transaction_type_name, transaction_type_description)
```

Problem:

* Transaction type details depend on `transaction_type_id`.

Normalized design:

```text
transactions(transaction_id, transaction_type_id, ...)
transaction_types(transaction_type_id, transaction_type_name, description)
```

### 5.4 Merchant Category Data

Bad design example:

```text
merchants(merchant_id, merchant_name, category_name, risk_level)
```

Problem:

* `category_name` and `risk_level` describe the merchant category, not the merchant itself.

Normalized design:

```text
merchants(merchant_id, merchant_category_id, merchant_name, ...)
merchant_categories(merchant_category_id, category_name, risk_level, description)
```

## 6. Superclass and Subclass Mapping

The EERD models `users` as a superclass.

Subclasses:

* `customers`
* `admins`

The specialization is total and disjoint:

* Every user must be either a customer or an admin.
* A user cannot be both a customer and an admin at the same time.

Relational mapping:

```text
users(user_id, username, phone, email, address, account_status, registered_at)

customers(customer_id, user_id, first_name, middle_initial, last_name, gender, date_of_birth, kyc_status, customer_segment, customer_status)

admins(admin_id, user_id, role, department, admin_status)
```

Normalization reason:

* Common attributes are stored once in `users`.
* Customer-specific attributes are stored in `customers`.
* Admin-specific attributes are stored in `admins`.
* This avoids storing customer-only fields for admins or admin-only fields for customers.

## 7. Recursive Relationship Mapping

The EERD contains a recursive relationship:

```text
ADMINS — Grants Permission — ADMINS
```

This means one admin can grant permission to another admin.

The relationship is many-to-many and has its own attributes.

Relational mapping:

```text
admin_permissions(
    admin_permission_id,
    grantor_admin_id,
    grantee_admin_id,
    granted_at,
    permission_scope,
    permission_content
)
```

Normalization reason:

* Permission delegation is not stored repeatedly inside the `admins` table.
* The same admin can grant permissions to many admins.
* The same admin can receive permissions from many admins.
* Relationship attributes such as `granted_at`, `permission_scope`, and `permission_content` are stored in the associative table where they belong.

## 8. Weak Entity Mapping

The EERD models `transaction_status_history` as a weak entity.

It depends on the parent entity:

```text
TRANSACTIONS
```

The identifying relationship is:

```text
TRANSACTIONS — Has Status History — TRANSACTION STATUS HISTORY
```

Relational mapping:

```text
transaction_status_history(
    transaction_id,
    status_sequence_no,
    old_status,
    new_status,
    changed_at,
    change_reason
)
```

Primary key:

```text
transaction_id + status_sequence_no
```

Normalization reason:

* A status history record cannot exist without a transaction.
* Multiple status changes are stored as multiple rows.
* The `transactions` table stores only the current transaction status.
* Historical status changes are stored separately.

This avoids a design like:

```text
transactions(transaction_id, status_1, status_2, status_3, status_4)
```

## 9. Many-to-Many Relationship Mapping

Many-to-many relationships are not stored directly in relational tables.

They are mapped into associative tables.

## 9.1 Transaction Fee Charges

The EERD relationship is:

```text
TRANSACTIONS — Charged Fee — FEE RULES
```

This is a many-to-many relationship because:

* One transaction can have zero or many fee charges.
* One fee rule can be applied to zero or many transactions.

Relational mapping:

```text
transaction_fee_charges(
    fee_charge_id,
    transaction_id,
    fee_rule_id,
    fee_amount,
    calculated_at,
    calculation_note
)
```

Normalization reason:

* `fee_rules` stores fee configuration.
* `transaction_fee_charges` stores actual fee charges.
* The actual charged amount may be different depending on the transaction amount, fee rule, time, and business logic.
* Fee charge details should not be repeated inside the `transactions` table.

## 9.2 Alert Reviews

The EERD relationship is:

```text
ADMINS — Reviewed By — RISK ALERTS
```

This is a many-to-many relationship because:

* One admin can review many risk alerts.
* One risk alert can be reviewed by zero or many admins.

Relational mapping:

```text
alert_reviews(
    review_id,
    risk_alert_id,
    admin_id,
    reviewed_at,
    review_decision,
    review_note
)
```

Normalization reason:

* Review information is separated from the `risk_alerts` table.
* A risk alert may remain unreviewed.
* Multiple review records can be stored when needed.
* Review attributes belong to the relationship between admins and risk alerts.

## 10. Fee Rule Normalization

Fee configuration is separated into the `fee_rules` table.

A fee rule is defined by:

* Transaction type
* Channel
* Currency
* Fixed fee
* Percentage
* Minimum amount
* Maximum amount
* Valid date range
* Status

Relational mapping:

```text
fee_rules(
    fee_rule_id,
    transaction_type_id,
    channel_id,
    currency_code,
    fixed_fee,
    percentage,
    minimum_amount,
    maximum_amount,
    valid_from,
    valid_to,
    fee_rule_status
)
```

Normalization reason:

* Fee configuration is not duplicated in the `transactions` table.
* Fee rules can be reused by many transactions.
* Fee rules can be managed independently from transaction records.
* Actual charged fees are stored separately in `transaction_fee_charges`.

## 11. Fraud and Risk Normalization

Fraud rule configuration and generated risk alerts are separated.

### 11.1 Fraud Rules

The `fraud_rules` table stores rule configuration.

```text
fraud_rules(
    fraud_rule_id,
    rule_name,
    rule_type,
    threshold_value,
    description,
    is_active
)
```

### 11.2 Risk Alerts

The `risk_alerts` table stores generated alerts.

```text
risk_alerts(
    risk_alert_id,
    transaction_id,
    fraud_rule_id,
    risk_score,
    risk_reason,
    alert_status,
    created_at,
    resolved_at
)
```

Normalization reason:

* A fraud rule can generate many risk alerts.
* Each risk alert is based on one fraud rule.
* Rule configuration is not repeated in every risk alert.
* Risk alert data is separated from transaction data.
* Alert review data is stored separately in `alert_reviews`.

## 12. Optional Relationship Handling

Some relationships in the EERD are optional.

These optional relationships are represented using nullable foreign keys or separate relationship tables.

### 12.1 Optional Card in Transactions

A transaction may or may not use a card.

Example:

* Card payment: uses a card.
* Bank transfer: may not use a card.
* Cash deposit: may not use a card.

Relational design:

```text
transactions.card_id nullable
```

### 12.2 Optional Merchant in Transactions

A transaction may or may not involve a merchant.

Example:

* POS payment: involves a merchant.
* Internal transfer: may not involve a merchant.
* ATM withdrawal: may not involve a merchant.

Relational design:

```text
transactions.merchant_id nullable
```

### 12.3 Optional Alert Review

A risk alert may or may not be reviewed by an admin.

Relational design:

```text
risk_alerts
alert_reviews
```

A risk alert can exist without any related row in `alert_reviews`.

### 12.4 Optional Fee Charge

A transaction may or may not have fee charges.

Relational design:

```text
transactions
transaction_fee_charges
```

A transaction can exist without any related row in `transaction_fee_charges`.

## 13. Derived Attribute Decision

The current OLTP design does not store derived attributes directly.

For example, the following values should be calculated when needed:

* Total fee amount per transaction
* Customer age
* Number of transactions per account
* Number of alerts per transaction
* Total transaction amount per customer

Example:

```text
Total Fee Amount = SUM(fee_amount) from transaction_fee_charges
```

Reason:

* Derived values may change when source data changes.
* Storing derived values in OLTP tables can create update anomalies.
* Derived values are better calculated using SQL queries, analytical views, Power BI measures, or data warehouse transformations.

## 14. Data Privacy and Security Normalization Notes

The design avoids storing sensitive raw financial or card data.

Important rules:

* Only masked card numbers are stored.
* Full card numbers must not be stored.
* Synthetic data is used for all project data.
* Real customer information must not be inserted into the database.
* Sensitive fields should be handled carefully in future pipeline and dashboard layers.

## 15. Summary

The FinPulse OLTP design follows normalization principles by:

* Separating common user attributes from customer and admin attributes.
* Separating reference data from transaction data.
* Separating fee configuration from actual fee charges.
* Separating fraud rule configuration from generated risk alerts.
* Separating alert review information from risk alerts.
* Mapping many-to-many relationships into associative tables.
* Mapping the weak entity `transaction_status_history` using a composite primary key.
* Avoiding derived attributes in the OLTP schema.
* Keeping the OLTP model clean, consistent, and ready for future analytics.
