# Relationship Rules

## 1. Overview

This document defines the main relationship rules used in the FinPulse OLTP database design.

The relationship rules are based on the Chen-style Enhanced Entity Relationship Diagram of the financial transaction system.

The goal of this document is to describe:

* Business relationships between entities
* Cardinality constraints
* Mandatory and optional participation
* Weak entity rules
* Superclass and subclass rules
* Recursive relationship rules
* Associative relationship rules
* How conceptual EERD relationships will be mapped into relational tables

This project uses synthetic data only. No real customer data, card data, or financial data is used.

## 2. EERD Notation Used

The EERD uses Chen-style notation.

Main notation:

* Rectangle: entity
* Double rectangle: weak entity
* Oval: attribute
* Underlined oval: primary key attribute
* Diamond: relationship
* Double diamond: identifying relationship
* Double line: total participation or mandatory participation
* Single line: partial participation or optional participation
* Circle with `d`: disjoint specialization
* Relationship with attributes: associative relationship that will become a table in the relational schema

## 3. Superclass and Subclass Rule

## 3.1 users, customers, and admins

Relationship type:

```text
USERS → CUSTOMERS
USERS → ADMINS
```

The `users` entity is the superclass.

The subclasses are:

* `customers`
* `admins`

Specialization constraints:

* Total specialization
* Disjoint specialization

Business rules:

* Every user must be either a customer or an admin.
* A user cannot be both a customer and an admin at the same time.
* Common user information is stored in `users`.
* Customer-specific information is stored in `customers`.
* Admin-specific information is stored in `admins`.

Relational mapping:

```text
users(user_id, ...)
customers(customer_id, user_id, ...)
admins(admin_id, user_id, ...)
```

Implementation notes:

* `customers.user_id` references `users.user_id`.
* `admins.user_id` references `users.user_id`.
* Additional constraints should be used later to enforce disjoint and total specialization if needed.

## 4. User and Administrator Relationships

## 4.1 Admin Grants Permission to Admin

Relationship:

```text
ADMINS — Grants Permission — ADMINS
```

Relationship type:

* Recursive relationship
* Many-to-many relationship

Cardinality:

```text
ADMINS N — Grants Permission — N ADMINS
```

Participation:

* Optional on the grantor admin side
* Optional on the grantee admin side

Business rules:

* One admin can grant permissions to many other admins.
* One admin can receive permissions from many other admins.
* An admin may exist without granting any permission.
* An admin may exist without receiving any permission.
* The same `admins` entity participates in the relationship with two roles:

  * Grantor
  * Grantee

Relationship attributes:

* `granted_at`
* `permission_scope`
* `permission_content`

Relational mapping:

```text
Grants Permission → admin_permissions
```

Implementation table:

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

Implementation notes:

* `grantor_admin_id` references `admins.admin_id`.
* `grantee_admin_id` references `admins.admin_id`.
* `grantor_admin_id` and `grantee_admin_id` should not be the same for normal permission delegation.

## 5. Customer, Account, Branch, Currency, and Card Relationships

## 5.1 Customer Owns Account

Relationship:

```text
CUSTOMERS — Owns — ACCOUNTS
```

Relationship type:

* One-to-many

Cardinality:

```text
CUSTOMERS 1 — Owns — N ACCOUNTS
```

Participation:

* Optional on the customer side
* Mandatory on the account side

Business rules:

* A customer can own zero or many accounts.
* Each account must belong to exactly one customer.
* An account cannot exist without a customer.

Relational mapping:

```text
accounts.customer_id → customers.customer_id
```

## 5.2 Branch Manages Account

Relationship:

```text
BRANCHES — Manages — ACCOUNTS
```

Relationship type:

* One-to-many

Cardinality:

```text
BRANCHES 1 — Manages — N ACCOUNTS
```

Participation:

* Optional on the branch side
* Mandatory on the account side

Business rules:

* A branch can manage zero or many accounts.
* Each account must be managed by exactly one branch.
* An account cannot exist without a managing branch.

Relational mapping:

```text
accounts.branch_id → branches.branch_id
```

## 5.3 Currency Denominates Account

Relationship:

```text
CURRENCIES — Denominated In — ACCOUNTS
```

Relationship type:

* One-to-many

Cardinality:

```text
CURRENCIES 1 — Denominated In — N ACCOUNTS
```

Participation:

* Optional on the currency side
* Mandatory on the account side

Business rules:

* A currency can be used by zero or many accounts.
* Each account must use exactly one currency.
* An account cannot exist without a currency.

Relational mapping:

```text
accounts.currency_code → currencies.currency_code
```

## 5.4 Account Has Card

Relationship:

```text
ACCOUNTS — Has — CARDS
```

Relationship type:

* One-to-many

Cardinality:

```text
ACCOUNTS 1 — Has — N CARDS
```

Participation:

* Optional on the account side
* Mandatory on the card side

Business rules:

* An account can have zero or many cards.
* Each card must belong to exactly one account.
* A card cannot exist without an account.
* Only masked card numbers are stored.
* Full card numbers must not be stored.

Relational mapping:

```text
cards.account_id → accounts.account_id
```

## 6. Transaction Processing Relationships

## 6.1 Account Generates Transaction

Relationship:

```text
ACCOUNTS — Generates — TRANSACTIONS
```

Relationship type:

* One-to-many

Cardinality:

```text
ACCOUNTS 1 — Generates — N TRANSACTIONS
```

Participation:

* Optional on the account side
* Mandatory on the transaction side

Business rules:

* An account can generate zero or many transactions.
* Each transaction must belong to exactly one account.
* A transaction cannot exist without an account.

Relational mapping:

```text
transactions.account_id → accounts.account_id
```

## 6.2 Card Used in Transaction

Relationship:

```text
CARDS — Used In — TRANSACTIONS
```

Relationship type:

* One-to-many

Cardinality:

```text
CARDS 1 — Used In — N TRANSACTIONS
```

Participation:

* Optional on the card side
* Optional on the transaction side

Business rules:

* A card can be used in zero or many transactions.
* A transaction may or may not use a card.
* Card-based transactions use a card.
* Non-card transactions such as internal transfers, branch deposits, or some account operations may not use a card.

Relational mapping:

```text
transactions.card_id → cards.card_id
```

Implementation note:

```text
transactions.card_id is nullable
```

## 6.3 Channel Processes Transaction

Relationship:

```text
CHANNELS — Through — TRANSACTIONS
```

Relationship type:

* One-to-many

Cardinality:

```text
CHANNELS 1 — Through — N TRANSACTIONS
```

Participation:

* Optional on the channel side
* Mandatory on the transaction side

Business rules:

* A channel can process zero or many transactions.
* Each transaction must be processed through exactly one channel.
* A transaction cannot exist without a processing channel.

Relational mapping:

```text
transactions.channel_id → channels.channel_id
```

## 6.4 Transaction Type Classifies Transaction

Relationship:

```text
TRANSACTION TYPE — Has Type — TRANSACTIONS
```

Relationship type:

* One-to-many

Cardinality:

```text
TRANSACTION TYPE 1 — Has Type — N TRANSACTIONS
```

Participation:

* Optional on the transaction type side
* Mandatory on the transaction side

Business rules:

* A transaction type can be used by zero or many transactions.
* Each transaction must have exactly one transaction type.
* A transaction cannot exist without a transaction type.

Relational mapping:

```text
transactions.transaction_type_id → transaction_types.transaction_type_id
```

## 6.5 Currency Used by Transaction

Relationship:

```text
CURRENCIES — Uses — TRANSACTIONS
```

Relationship type:

* One-to-many

Cardinality:

```text
CURRENCIES 1 — Uses — N TRANSACTIONS
```

Participation:

* Optional on the currency side
* Mandatory on the transaction side

Business rules:

* A currency can be used by zero or many transactions.
* Each transaction must use exactly one currency.
* A transaction cannot exist without a currency.

Relational mapping:

```text
transactions.currency_code → currencies.currency_code
```

## 7. Merchant Relationships

## 7.1 Merchant Category Contains Merchant

Relationship:

```text
MERCHANT CATEGORIES — Belonged To — MERCHANTS
```

Relationship type:

* One-to-many

Cardinality:

```text
MERCHANT CATEGORIES 1 — Belonged To — N MERCHANTS
```

Participation:

* Optional on the merchant category side
* Mandatory on the merchant side

Business rules:

* A merchant category can contain zero or many merchants.
* Each merchant must belong to exactly one merchant category.
* A merchant cannot exist without a merchant category.

Relational mapping:

```text
merchants.merchant_category_id → merchant_categories.merchant_category_id
```

## 7.2 Merchant Occurs at Transaction

Relationship:

```text
MERCHANTS — Occurred At — TRANSACTIONS
```

Relationship type:

* One-to-many

Cardinality:

```text
MERCHANTS 1 — Occurred At — N TRANSACTIONS
```

Participation:

* Optional on the merchant side
* Optional on the transaction side

Business rules:

* A merchant can be involved in zero or many transactions.
* A transaction may or may not involve a merchant.
* Merchant payment transactions usually involve a merchant.
* Internal transfers, ATM withdrawals, and some branch transactions may not involve a merchant.

Relational mapping:

```text
transactions.merchant_id → merchants.merchant_id
```

Implementation note:

```text
transactions.merchant_id is nullable
```

## 8. Transaction Status History Relationship

## 8.1 Transaction Has Status History

Relationship:

```text
TRANSACTIONS — Has Status History — TRANSACTION STATUS HISTORY
```

Relationship type:

* One-to-many
* Identifying relationship

Cardinality:

```text
TRANSACTIONS 1 — Has Status History — N TRANSACTION STATUS HISTORY
```

Participation:

* Optional on the transaction side
* Mandatory on the transaction status history side

EERD modeling:

* `transaction_status_history` is a weak entity.
* `Has Status History` is an identifying relationship.
* The weak entity is shown using a double rectangle.
* The identifying relationship is shown using a double diamond.

Business rules:

* A transaction can have zero or many status history records.
* Each status history record must belong to exactly one transaction.
* A status history record cannot exist without its parent transaction.
* A transaction status history record is identified by the parent transaction and a sequence number.

Primary key:

```text
transaction_id + status_sequence_no
```

Relational mapping:

```text
transaction_status_history.transaction_id → transactions.transaction_id
```

Implementation table:

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

## 9. Fee Management Relationships

## 9.1 Fee Rule Applies to Transaction Type

Relationship:

```text
FEE RULES — Applies To — TRANSACTION TYPE
```

Relationship type:

* One-to-many from transaction type to fee rules

Cardinality:

```text
TRANSACTION TYPE 1 — Applies To — N FEE RULES
```

Participation:

* Optional on the transaction type side
* Mandatory on the fee rule side

Business rules:

* A transaction type can have zero or many fee rules.
* Each fee rule must apply to exactly one transaction type.

Relational mapping:

```text
fee_rules.transaction_type_id → transaction_types.transaction_type_id
```

## 9.2 Fee Rule Applies Through Channel

Relationship:

```text
FEE RULES — Applies Through — CHANNELS
```

Relationship type:

* One-to-many from channel to fee rules

Cardinality:

```text
CHANNELS 1 — Applies Through — N FEE RULES
```

Participation:

* Optional on the channel side
* Mandatory on the fee rule side

Business rules:

* A channel can have zero or many fee rules.
* Each fee rule must apply through exactly one channel.

Relational mapping:

```text
fee_rules.channel_id → channels.channel_id
```

## 9.3 Fee Rule Applies in Currency

Relationship:

```text
FEE RULES — Applies In — CURRENCIES
```

Relationship type:

* One-to-many from currency to fee rules

Cardinality:

```text
CURRENCIES 1 — Applies In — N FEE RULES
```

Participation:

* Optional on the currency side
* Mandatory on the fee rule side

Business rules:

* A currency can have zero or many fee rules.
* Each fee rule must apply in exactly one currency.
* Fee rules are configured by transaction type, channel, and currency.

Relational mapping:

```text
fee_rules.currency_code → currencies.currency_code
```

## 9.4 Transaction Charged Fee by Fee Rule

Relationship:

```text
TRANSACTIONS — Charged Fee — FEE RULES
```

Relationship type:

* Many-to-many
* Associative relationship with attributes

Cardinality:

```text
TRANSACTIONS N — Charged Fee — N FEE RULES
```

Participation:

* Optional on the transaction side
* Optional on the fee rule side

Business rules:

* A transaction can have zero or many fee charges.
* A fee rule can be applied to zero or many transactions.
* A transaction may have no fee.
* A fee rule may exist before being applied to any transaction.
* The actual charged fee amount is stored on the relationship.

Relationship attributes:

* `amount`
* `time`
* `note`

Relational mapping:

```text
Charged Fee → transaction_fee_charges
```

Implementation table:

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

Implementation notes:

* `fee_amount` stores the actual calculated fee.
* `fixed_fee` and `percentage` are configuration attributes in `fee_rules`.
* `fee_amount` is the actual charged value for a specific transaction.

## 10. Fraud and Risk Relationships

## 10.1 Transaction Triggers Risk Alert

Relationship:

```text
TRANSACTIONS — Triggers — RISK ALERTS
```

Relationship type:

* One-to-many

Cardinality:

```text
TRANSACTIONS 1 — Triggers — N RISK ALERTS
```

Participation:

* Optional on the transaction side
* Mandatory on the risk alert side

Business rules:

* A transaction can trigger zero or many risk alerts.
* Each risk alert must belong to exactly one transaction.
* A risk alert cannot exist without a related transaction.

Relational mapping:

```text
risk_alerts.transaction_id → transactions.transaction_id
```

## 10.2 Fraud Rule Generates Risk Alert

Relationship:

```text
FRAUD RULES — Based On — RISK ALERTS
```

Relationship type:

* One-to-many

Cardinality:

```text
FRAUD RULES 1 — Based On — N RISK ALERTS
```

Participation:

* Optional on the fraud rule side
* Mandatory on the risk alert side

Business rules:

* A fraud rule can generate zero or many risk alerts.
* Each risk alert must be based on exactly one fraud rule.
* A risk alert cannot exist without a fraud rule.

Relational mapping:

```text
risk_alerts.fraud_rule_id → fraud_rules.fraud_rule_id
```

## 10.3 Admin Reviews Risk Alert

Relationship:

```text
ADMINS — Reviewed By — RISK ALERTS
```

Relationship type:

* Many-to-many
* Associative relationship with attributes

Cardinality:

```text
ADMINS N — Reviewed By — N RISK ALERTS
```

Participation:

* Optional on the admin side
* Optional on the risk alert side

Business rules:

* An admin can review zero or many risk alerts.
* A risk alert can be reviewed by zero or many admins.
* A risk alert may remain unreviewed.
* Review information is stored on the relationship.

Relationship attributes:

* `review_id`
* `reviewed_at`
* `review_decision`
* `review_note`

Relational mapping:

```text
Reviewed By → alert_reviews
```

Implementation table:

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

## 11. Summary Relationship Table

| No. | Relationship                                    | Cardinality | Mandatory Side               | Relational Mapping                  |
| --: | ----------------------------------------------- | ----------- | ---------------------------- | ----------------------------------- |
|   1 | `users` specialization to `customers`           | 1:1         | `customers`                  | `customers.user_id`                 |
|   2 | `users` specialization to `admins`              | 1:1         | `admins`                     | `admins.user_id`                    |
|   3 | `admins` grants permission to `admins`          | N:N         | None                         | `admin_permissions`                 |
|   4 | `customers` owns `accounts`                     | 1:N         | `accounts`                   | `accounts.customer_id`              |
|   5 | `branches` manages `accounts`                   | 1:N         | `accounts`                   | `accounts.branch_id`                |
|   6 | `currencies` denominates `accounts`             | 1:N         | `accounts`                   | `accounts.currency_code`            |
|   7 | `accounts` has `cards`                          | 1:N         | `cards`                      | `cards.account_id`                  |
|   8 | `accounts` generates `transactions`             | 1:N         | `transactions`               | `transactions.account_id`           |
|   9 | `cards` used in `transactions`                  | 1:N         | None                         | `transactions.card_id` nullable     |
|  10 | `channels` processes `transactions`             | 1:N         | `transactions`               | `transactions.channel_id`           |
|  11 | `transaction_types` classifies `transactions`   | 1:N         | `transactions`               | `transactions.transaction_type_id`  |
|  12 | `currencies` used by `transactions`             | 1:N         | `transactions`               | `transactions.currency_code`        |
|  13 | `merchant_categories` contains `merchants`      | 1:N         | `merchants`                  | `merchants.merchant_category_id`    |
|  14 | `merchants` occurs at `transactions`            | 1:N         | None                         | `transactions.merchant_id` nullable |
|  15 | `transactions` has `transaction_status_history` | 1:N         | `transaction_status_history` | composite PK                        |
|  16 | `transaction_types` applies to `fee_rules`      | 1:N         | `fee_rules`                  | `fee_rules.transaction_type_id`     |
|  17 | `channels` applies through `fee_rules`          | 1:N         | `fee_rules`                  | `fee_rules.channel_id`              |
|  18 | `currencies` applies in `fee_rules`             | 1:N         | `fee_rules`                  | `fee_rules.currency_code`           |
|  19 | `transactions` charged fee by `fee_rules`       | N:N         | None                         | `transaction_fee_charges`           |
|  20 | `transactions` triggers `risk_alerts`           | 1:N         | `risk_alerts`                | `risk_alerts.transaction_id`        |
|  21 | `fraud_rules` based on `risk_alerts`            | 1:N         | `risk_alerts`                | `risk_alerts.fraud_rule_id`         |
|  22 | `admins` reviews `risk_alerts`                  | N:N         | None                         | `alert_reviews`                     |

## 12. Optional Relationship Summary

The following relationships are optional and must be handled carefully in the relational schema:

### 12.1 Optional Card Usage

A transaction may not use a card.

```text
transactions.card_id nullable
```

### 12.2 Optional Merchant Involvement

A transaction may not involve a merchant.

```text
transactions.merchant_id nullable
```

### 12.3 Optional Fee Charges

A transaction may not have fee charges.

```text
transaction_fee_charges may have no row for a transaction
```

### 12.4 Optional Risk Alert Review

A risk alert may not have been reviewed yet.

```text
alert_reviews may have no row for a risk alert
```

### 12.5 Optional Permission Delegation

An admin may not grant or receive permissions.

```text
admin_permissions may have no row for an admin
```

## 13. Mandatory Relationship Summary

The following relationships are mandatory on the child or dependent side:

* Each account must belong to one customer.
* Each account must be managed by one branch.
* Each account must use one currency.
* Each card must belong to one account.
* Each transaction must belong to one account.
* Each transaction must have one transaction type.
* Each transaction must be processed through one channel.
* Each transaction must use one currency.
* Each transaction status history record must belong to one transaction.
* Each merchant must belong to one merchant category.
* Each fee rule must apply to one transaction type.
* Each fee rule must apply through one channel.
* Each fee rule must apply in one currency.
* Each risk alert must belong to one transaction.
* Each risk alert must be based on one fraud rule.

## 14. EERD-to-Relational Mapping Summary

The Chen-style EERD contains conceptual modeling features that will be mapped into relational tables.

Mapping rules:

* Superclass/subclass:

  * `users`
  * `customers`
  * `admins`

* Recursive relationship:

  * `Grants Permission` → `admin_permissions`

* Weak entity:

  * `Transaction Status History` → `transaction_status_history`

* Associative relationships:

  * `Charged Fee` → `transaction_fee_charges`
  * `Reviewed By` → `alert_reviews`

* Optional entity relationships:

  * `transactions.card_id` is nullable
  * `transactions.merchant_id` is nullable

* Mandatory entity relationships:

  * Implemented using `NOT NULL` foreign keys where appropriate

## 15. Design Notes

Important design notes:

* The `transactions` entity is the central entity of the OLTP model.
* `transaction_status_history` is modeled as a weak entity because it depends on `transactions`.
* `admin_permissions`, `transaction_fee_charges`, and `alert_reviews` are shown as relationships with attributes in the EERD, but they will become tables in the relational schema.
* Fee rules are configured by transaction type, channel, and currency.
* Fraud rules generate risk alerts, but alert reviews are handled separately by admins.
* Derived attributes are not stored directly in the OLTP schema.
* Only masked card numbers are stored.
* Full card numbers must not be stored.
* All project data must be synthetic.
