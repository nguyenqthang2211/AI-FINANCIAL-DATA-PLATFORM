# Entity List

## 1. customers

Purpose: Stores customer information

Attributes:
- customer_id
- full_name
- gender
- date_of_birth
- phone_number
- email
- kyc_status
- customer_segment
- created_at

## 2. accounts

Purpose: Stores financial accounts owned by customers.

Attributes:
- account_id
- customer_id
- branch_id
- account_number
- account_type
- opened_date
- current_balance
- account_status
- currency_code

## 3. cards

Purpose: Stores payment cards linked to accounts.

Attributes:
- card_id
- account_id
- card_number_masked
- card_type
- issued_date
- expiry_date
- card_status

# 4. transactions

Purpose: Stores financial transaction records.

Attributes:
- transaction_id
- account_id
- card_id
- merchant_id
- channel_id
- transaction_type_id
- transaction_time
- amount
- fee_amount
- currency_code
- status
- description
- created_at

## 5. merchants

Purpose:
Stores merchant information.

Attributes:
- merchant_id
- merchant_name
- merchant_category_id
- country
- city

## 6. merchant_categories

Purpose:
Stores merchant category information.

Attributes:
- merchant_category_id
- category_name

## 7. channels

Purpose:
Stores transaction channels.

Attributes:
- channel_id
- channel_name

## 8. transaction_types

Purpose:
Stores transaction type information.

Attributes:
- transaction_type_id
- transaction_type_name

## 9. currencies

Purpose:
Stores currency information.

Attributes:
- currency_code
- currency_name

## 10. branches

Purpose:
Stores bank branch information.

Attributes:
- branch_id
- branch_name
- city
- address
