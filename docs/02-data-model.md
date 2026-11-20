# Data Model and Ledgers

## 1. Value Formats

The data model uses strict value formats:

- **Identifiers**: 26-character Universally Unique Lexicographically Sortable Identifier (ULID) strings.

- **Monetary Amounts**: Exact string-encoded decimal numbers (using `rust_decimal`).

- **Timestamps**: UTC ISO 8601 strings (format: `YYYY-MM-DDTHH:MM:SSZ`).

## 2. Account Schema

Accounts use a unified structure:

- `id`: ULID string.

- `name`: Human-readable label.

- `account_type`: Liquid asset (`asset`), liability (`liability`), or equity (`equity`).

- `currency`: ISO 4217 code (such as `USD`, `EUR`, `PLN`) or custom asset string.

- `created_at`: UTC ISO 8601 string.

- Savings accounts use standard `asset` accounts without virtual buckets.

## 3. Transaction Schema

Transactions represent balanced double-entry events:

- `id`: ULID string.

- `timestamp`: UTC ISO 8601 string.

- `description`: Text note for the transaction.

- `category`: Single flat category identifier string (mandatory).

- `tags`: List of optional tag strings.

- `receipt_id`: Optional pointer string to a PDS receipt entry.

- `postings`: List of postings (minimum two):
  - `account_id`: ULID string.
  - `amount`: Exact decimal string (positive for debit, negative for credit).
  - `currency`: ISO 4217 code.

## 4. Currency Exchange Operations

The system does not fetch automated market exchange rates:

- Exchange operations are explicit conversion transactions.

- The transaction takes an exact amount of source currency.

- The transaction delivers an exact amount of target currency.

- The entry reflects the realized rate from a bank, an exchange office, or cash ATM.

## 5. Counterparty and Debt Schema

Debts use counterparty profiles and loan accounts:

- **Counterparty Profile**:
  - `id`: ULID string.
  - `name`: Person or organization name.

- **Debt Contract Record**:
  - `id`: ULID string.
  - `counterparty_id`: ULID pointer to the counterparty.
  - `direction`: `receivable` (lent to party) or `payable` (borrowed from party).
  - `principal`: Decimal string for the initial loan amount.
  - `currency`: ISO 4217 code.
  - `interest_rate_annual`: Optional decimal string (annual percentage rate).
  - `due_date`: Optional ISO 8601 date string (`YYYY-MM-DD`).
  - `settled`: Boolean status flag.

- **Repayment Tracking**:
  - Each repayment creates a transaction linking the cash account and debt liability.
  - A partial repayment record links the transaction to the parent debt record.
  - Every repayment decreases the open principal balance.

## 6. Receipts and File References

- Receipt files stay unencrypted in PDS storage.

- A transaction includes an optional `receipt_id` pointing to a PDS receipt entry.

- The PDS receipt entry references the content hash of the physical image blob.

- Non-essential relations between transactions and files remain optional.
