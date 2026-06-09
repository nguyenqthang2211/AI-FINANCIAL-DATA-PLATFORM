# Entity Relationship Rules and Semantic Constraints

## 1. Overview

This document describes the relationship rules, cardinalities, foreign keys, and semantic constraints of the **Financial Transaction OLTP Database**.

The model includes standard 1:N relationships, optional relationships, superclass/subclass specialization, recursive relationships, weak entities, and associative entities.

---

## 2. Specialization Rules

### 2.1 `users` – `customers` – `admins`

**Specialization Type:** Disjoint and total specialization

A user must be either a customer or an admin. In this learning project, a user is not allowed to be both a customer and an admin at the same time.

**Rules:**
- `customers.customer_id` references `users.user_id`
- `admins.admin_id` references `users.user_id`
- `customers` and `admins` inherit common user information from `users`

---

## 3. Recursive Relationship

### 3.1 `admins` – `admin_permissions` – `admins`

**Relationship:** Recursive N:N

One admin can grant permissions to many other admins. One admin can also receive permissions from many other admins.

**Foreign Keys:**
- `admin_permissions.grantor_admin_id` references `admins.admin_id`
- `admin_permissions.grantee_admin_id` references `admins.admin_id`

**Relationship Attributes:**
- `granted_at`
- `permission_scope`
- `permission_content`

This relationship is similar to an administrator delegation relationship.

---

## 4. Core Relationship Rules

### 4.1 `customers` – `accounts`

**Relationship:** 1:N

One customer can own many accounts. Each account belongs to exactly one customer.

**Foreign Key:**
- `accounts.customer_id` references `customers.customer_id`

---

### 4.2 `branches` – `accounts`

**Relationship:** 1:N

One branch can manage many accounts. Each account may be opened at one branch.

**Foreign Key:**
- `accounts.branch_id` references `branches.branch_id`

---

### 4.3 `currencies` – `accounts`

**Relationship:** 1:N

One currency can be used by many accounts. Each account uses one primary currency.

**Foreign Key:**
- `accounts.currency_code` references `currencies.currency_code`

---

### 4.4 `accounts` – `cards`

**Relationship:** 1:N

One account can have many cards. Each card belongs to one account.

**Foreign Key:**
- `cards.account_id` references `accounts.account_id`

---

### 4.5 `accounts` – `transactions`

**Relationship:** 1:N

One account can generate many transactions. Each transaction must belong to one account.

**Foreign Key:**
- `transactions.account_id` references `accounts.account_id`

---

### 4.6 `cards` – `transactions`

**Relationship:** 1:N, optional on transaction side

One card can be used in many transactions. However, a transaction may not use a card.

**Foreign Key:**
- `transactions.card_id` references `cards.card_id`

**Optional Rule:**
- `transactions.card_id` may be null.

---

### 4.7 `merchant_categories` – `merchants`

**Relationship:** 1:N

One merchant category can contain many merchants. Each merchant belongs to one merchant category.

**Foreign Key:**
- `merchants.merchant_category_id` references `merchant_categories.merchant_category_id`

---

### 4.8 `merchants` – `transactions`

**Relationship:** 1:N, optional on transaction side

One merchant can appear in many transactions. However, a transaction such as ATM withdrawal or personal transfer may not involve a merchant.

**Foreign Key:**
- `transactions.merchant_id` references `merchants.merchant_id`

**Optional Rule:**
- `transactions.merchant_id` may be null.

---

### 4.9 `channels` – `transactions`

**Relationship:** 1:N

One channel can be used in many transactions. Each transaction is performed through one channel.

**Foreign Key:**
- `transactions.channel_id` references `channels.channel_id`

---

### 4.10 `transaction_types` – `transactions`

**Relationship:** 1:N

One transaction type can appear in many transactions. Each transaction has one transaction type.

**Foreign Key:**
- `transactions.transaction_type_id` references `transaction_types.transaction_type_id`

---

### 4.11 `currencies` – `transactions`

**Relationship:** 1:N

One currency can appear in many transactions. Each transaction uses one currency.

**Foreign Key:**
- `transactions.currency_code` references `currencies.currency_code`

---

## 5. Weak Entity Rule

### 5.1 `transactions` – `transaction_status_history`

**Relationship:** 1:N identifying relationship

`transaction_status_history` is modeled as a weak entity because it depends on `transactions` for identification.

**Primary Key of Weak Entity:**
- `transaction_id`
- `status_sequence_no`

**Foreign Key:**
- `transaction_status_history.transaction_id` references `transactions.transaction_id`

**Meaning:**
A transaction can have many status history records. Each status history record cannot exist without its parent transaction.

---

## 6. Associative Entity Rules

### 6.1 `transactions` – `fee_rules` through `transaction_fee_charges`

**Relationship:** M:N resolved by associative entity

A transaction can have one or more fee charges. A fee rule can be applied to many transactions.

**Associative Entity:**
- `transaction_fee_charges`

**Foreign Keys:**
- `transaction_fee_charges.transaction_id` references `transactions.transaction_id`
- `transaction_fee_charges.fee_rule_id` references `fee_rules.fee_rule_id`

**Relationship Attributes:**
- `fee_amount`
- `calculated_at`
- `calculation_note`

---

### 6.2 `transactions` – `fraud_rules` through `risk_alerts`

**Relationship:** M:N resolved by associative entity

A transaction can violate many fraud rules. A fraud rule can generate alerts for many transactions.

**Associative Entity:**
- `risk_alerts`

**Foreign Keys:**
- `risk_alerts.transaction_id` references `transactions.transaction_id`
- `risk_alerts.fraud_rule_id` references `fraud_rules.fraud_rule_id`

**Relationship Attributes:**
- `risk_score`
- `alert_status`
- `alert_reason`
- `created_at`
- `resolved_at`

---

### 6.3 `admins` – `risk_alerts` through `alert_reviews`

**Relationship:** M:N resolved by associative entity

An admin can review many risk alerts. A risk alert can have multiple review records over time.

**Associative Entity:**
- `alert_reviews`

**Foreign Keys:**
- `alert_reviews.admin_id` references `admins.admin_id`
- `alert_reviews.alert_id` references `risk_alerts.alert_id`

**Relationship Attributes:**
- `reviewed_at`
- `review_decision`
- `review_note`

---

## 7. ERD Checklist

When drawing the ERD, make sure it includes the following elements:

- Superclass: `users`
- Subclasses: `customers`, `admins`
- Recursive relationship: `admin_permissions`
- Weak entity: `transaction_status_history`
- Central entity: `transactions`
- Associative entity for fee application: `transaction_fee_charges`
- Associative entity for fraud detection: `risk_alerts`
- Associative entity for alert review: `alert_reviews`
- Optional foreign keys: `transactions.card_id`, `transactions.merchant_id`

---

## 8. Semantic Constraints

### 8.1 Transaction Constraints

- `amount` must be greater than 0.
- `transaction.status` must be one of: `PENDING`, `SUCCESS`, `FAILED`, `REVERSED`, `REFUNDED`.
- `card_id` may be null if the transaction does not use a card.
- `merchant_id` may be null for non-merchant transactions.
- `currency_code` should be consistent with the account currency if foreign exchange is not supported.

### 8.2 Customer and Account Constraints

- `kyc_status` must be one of: `PENDING`, `VERIFIED`, `REJECTED`.
- A blocked or closed account should not generate new transactions.
- `account_number` must be unique.

### 8.3 Card Constraints

- Card numbers must not be stored in full.
- Only masked card numbers should be stored in `card_number_masked`.
- Expired, blocked, or cancelled cards should not be used for new transactions.

### 8.4 Status History Constraints

- Every transaction status change should create a new record in `transaction_status_history`.
- `old_status` and `new_status` should not be the same.
- Finalized transactions should not be updated without a corresponding status history record.

### 8.5 Fee Rule Constraints

- `fixed_fee`, `percentage_fee`, `min_fee`, and `max_fee` must not be negative.
- Fee rules are valid only between `effective_from` and `effective_to`.
- If multiple fee rules match, the system must define a priority rule.

### 8.6 Risk and Fraud Constraints

- `risk_score` should be within a defined range, such as 0 to 1 or 0 to 100.
- `alert_status` should be one of: `OPEN`, `INVESTIGATING`, `RESOLVED`, `FALSE_POSITIVE`.
- Each alert review must be performed by a valid admin.

### 8.7 Security and Privacy Constraints

- Customer and transaction data are sensitive.
- Card numbers must be masked.
- Real customer data must not be used in this learning project.
- In real systems, access control, audit logging, and data masking are required.
