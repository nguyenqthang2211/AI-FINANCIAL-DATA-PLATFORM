# Normalization Note

## 1. Overview

This document reviews the normalization quality of the **Financial Transaction OLTP Database** in the **AI-powered Financial Transaction Analytics Platform** project.

The goal of normalization is to reduce data redundancy, avoid update anomalies, insertion anomalies, and deletion anomalies, and ensure that each table stores data about one clear business concept.

The current database design is checked against **First Normal Form (1NF)**, **Second Normal Form (2NF)**, and **Third Normal Form (3NF)** before moving to SQL schema implementation.

---

## 2. First Normal Form (1NF)

A table is in First Normal Form when each attribute contains only atomic values, there are no repeating groups, and each row can be uniquely identified by a primary key.

In this project, the main entities satisfy 1NF because each attribute stores a single value. For example, `users.email`, `users.phone_number`, `accounts.account_number`, `transactions.amount`, and `transactions.transaction_time` are atomic attributes.

The `transactions` table also satisfies 1NF because each row represents exactly one financial transaction, and each field stores one value only.

If the system needs to support multiple phone numbers or multiple addresses for one user in the future, these should be separated into additional tables such as `user_phone_numbers` or `user_addresses`.

---

## 3. Second Normal Form (2NF)

A table is in Second Normal Form when it is already in 1NF and every non-key attribute depends on the entire primary key.

Most entities in this project use a single-column primary key, such as `user_id`, `customer_id`, `account_id`, `transaction_id`, `merchant_id`, and `alert_id`. Therefore, partial dependency is not a major issue for these tables.

For tables with composite primary keys, such as `admin_permissions` and `transaction_status_history`, the non-key attributes depend on the full key.

In `admin_permissions`, the attributes `granted_at`, `permission_scope`, and `permission_content` describe the permission delegation between a specific grantor admin and a specific grantee admin.

In `transaction_status_history`, the attributes `old_status`, `new_status`, `changed_at`, and `reason` describe a specific status change of a specific transaction at a specific sequence number.

Therefore, the current design satisfies 2NF.

---

## 4. Third Normal Form (3NF)

A table is in Third Normal Form when it is already in 2NF and there is no transitive dependency between non-key attributes.

The current design avoids storing descriptive information from other entities inside the `transactions` table. For example, `transactions` does not store `customer_name`, `merchant_name`, `channel_name`, or `transaction_type_name`.

Instead, the `transactions` table stores foreign keys such as `account_id`, `merchant_id`, `channel_id`, `transaction_type_id`, and `currency_code`.

This design reduces redundancy and avoids update anomalies. For example, if a merchant name changes, only the `merchants` table needs to be updated. The `transactions` table remains unchanged.

The lookup entities such as `channels`, `transaction_types`, `currencies`, and `merchant_categories` also support 3NF because repeated business values are stored in separate reference tables.

Therefore, the current design satisfies 3NF for the main OLTP structure.

---

## 5. Normalization Review by Entity Group

### 5.1 User Entities

The `users`, `customers`, and `admins` structure avoids repeated account information. Common user attributes are stored in `users`, while customer-specific and admin-specific attributes are stored in separate subclass tables.

This design reduces redundancy and supports an EER-style superclass/subclass model.

### 5.2 Core Financial Entities

The `customers`, `accounts`, `cards`, and `transactions` entities are properly separated. The `transactions` table stores transaction-level facts and references other entities through foreign keys.

The design avoids storing customer, account, merchant, channel, and transaction type descriptions directly inside `transactions`.

### 5.3 Reference Entities

The reference entities `branches`, `currencies`, `channels`, `transaction_types`, `merchant_categories`, and `merchants` reduce repeated values and improve data consistency.

These lookup tables make the design easier to maintain and extend.

### 5.4 Status History Entity

The `transaction_status_history` table is modeled as a weak entity identified by the composite key:

- `transaction_id`
- `status_sequence_no`

This design allows the system to preserve transaction status changes instead of overwriting previous states.

### 5.5 Fee Entities

The `fee_rules` and `transaction_fee_charges` entities are separated to avoid mixing fee calculation rules and actual fee charges in the `transactions` table.

`fee_rules` stores reusable fee calculation logic, while `transaction_fee_charges` stores the actual fee applied to each transaction.

### 5.6 Risk and Monitoring Entities

The `fraud_rules`, `risk_alerts`, and `alert_reviews` entities are separated to avoid mixing fraud detection rules, generated alerts, and admin review actions in one table.

This separation improves traceability, auditability, and future extensibility for fraud detection and risk monitoring.

---

## 6. Potential Design Notes

The `current_balance` attribute in `accounts` can be considered a derived or operational value because it may be calculated from transactions. However, in real financial systems, current balance is often stored for performance and operational reasons. Therefore, it is acceptable to keep `current_balance` in the OLTP design, but it must be carefully updated.

The `currency_code` in `transactions` may duplicate the account currency if the system only supports single-currency accounts. However, storing transaction currency is useful for historical accuracy and future support for foreign exchange transactions.

The `card_id` and `merchant_id` attributes in `transactions` are optional because not all transactions use a card or involve a merchant.

The `transaction_fee_charges` table is kept separate from `transactions` because a transaction may have different fee components or may need to preserve the exact fee rule applied at the time of calculation.

The `risk_alerts` table is kept separate because a transaction can violate multiple fraud rules and generate multiple alerts.

---

## 7. Examples of Avoided Redundancy

### 7.1 Merchant Information

Incorrect design:

```text
transactions(
  transaction_id,
  merchant_name,
  merchant_category_name,
  amount
)
```

Correct design:

```text
transactions(
  transaction_id,
  merchant_id,
  amount
)

merchants(
  merchant_id,
  merchant_name,
  merchant_category_id
)

merchant_categories(
  merchant_category_id,
  category_name
)
```

This avoids repeating merchant information in every transaction.

### 7.2 Channel Information

Incorrect design:

```text
transactions(
  transaction_id,
  channel_name,
  channel_type,
  amount
)
```

Correct design:

```text
transactions(
  transaction_id,
  channel_id,
  amount
)

channels(
  channel_id,
  channel_name,
  channel_type
)
```

This avoids inconsistent channel naming and improves data quality.

### 7.3 Transaction Type Information

Incorrect design:

```text
transactions(
  transaction_id,
  transaction_type_name,
  amount
)
```

Correct design:

```text
transactions(
  transaction_id,
  transaction_type_id,
  amount
)

transaction_types(
  transaction_type_id,
  transaction_type_name
)
```

This makes it easier to add, rename, or manage transaction types.

---

## 8. Conclusion

The current Financial Transaction OLTP Database design satisfies the main requirements of 1NF, 2NF, and 3NF.

The design separates core entities, lookup entities, weak entities, and associative entities clearly. It reduces data redundancy, supports data consistency, and prepares the system for SQL schema implementation, data warehouse modeling, fraud detection, and analytics in later phases.
