use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use ulid::Ulid;

/// Errors that can occur when validating or creating a Transaction.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum TransactionError {
    /// A transaction must have at least two postings.
    #[error("transaction must contain at least two postings, found {0}")]
    InsufficientPostings(usize),

    /// A transaction must have a non-empty primary category.
    #[error("transaction category cannot be empty")]
    EmptyCategory,

    /// A single-currency transaction must sum exactly to zero.
    #[error("postings for currency '{0}' do not balance to zero (net sum: {1})")]
    UnbalancedPostings(String, Decimal),
}

/// An individual debit or credit entry within a transaction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Posting {
    /// Account linked to this posting.
    pub account_id: Ulid,
    /// Exact monetary amount (positive for debit, negative for credit).
    pub amount: Decimal,
    /// Currency code (ISO 4217 such as USD, EUR, PLN) or commodity symbol.
    pub currency: String,
}

impl Posting {
    /// Creates a new posting.
    pub fn new(account_id: Ulid, amount: Decimal, currency: impl Into<String>) -> Self {
        Self {
            account_id,
            amount,
            currency: currency.into(),
        }
    }
}

/// A balanced double-entry financial transaction.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Transaction {
    /// Unique ULID identifier.
    pub id: Ulid,
    /// Transaction timestamp in UTC.
    pub timestamp: DateTime<Utc>,
    /// Descriptive memo or payee name.
    pub description: String,
    /// Single mandatory flat category identifier.
    pub category: String,
    /// Optional secondary tags for cross-cutting queries.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub tags: Vec<String>,
    /// Optional pointer to a PDS unencrypted receipt entry.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub receipt_id: Option<Ulid>,
    /// Balanced double-entry postings (minimum two).
    pub postings: Vec<Posting>,
}

impl Transaction {
    /// Creates and validates a new double-entry transaction.
    pub fn new(
        description: impl Into<String>,
        category: impl Into<String>,
        tags: Vec<String>,
        receipt_id: Option<Ulid>,
        postings: Vec<Posting>,
    ) -> Result<Self, TransactionError> {
        let category = category.into();
        if category.trim().is_empty() {
            return Err(TransactionError::EmptyCategory);
        }

        if postings.len() < 2 {
            return Err(TransactionError::InsufficientPostings(postings.len()));
        }

        let transaction = Self {
            id: Ulid::generate(),
            timestamp: Utc::now(),
            description: description.into(),
            category,
            tags,
            receipt_id,
            postings,
        };

        transaction.validate()?;
        Ok(transaction)
    }

    /// Validates balancing rules for this transaction.
    ///
    /// Single-currency transactions must balance to zero.
    /// Multi-currency transactions represent explicit realized exchanges and are valid
    /// as long as each currency has balanced debits/credits or distinct exchange legs.
    pub fn validate(&self) -> Result<(), TransactionError> {
        if self.category.trim().is_empty() {
            return Err(TransactionError::EmptyCategory);
        }

        if self.postings.len() < 2 {
            return Err(TransactionError::InsufficientPostings(self.postings.len()));
        }

        // Group postings by currency
        let mut currency_sums = std::collections::HashMap::new();
        for p in &self.postings {
            *currency_sums
                .entry(p.currency.clone())
                .or_insert(Decimal::ZERO) += p.amount;
        }

        // If all postings share a single currency, verify net balance is zero
        if currency_sums.len() == 1 {
            let (currency, sum) = currency_sums.into_iter().next().unwrap();
            if !sum.is_zero() {
                return Err(TransactionError::UnbalancedPostings(currency, sum));
            }
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    #[test]
    fn test_valid_balanced_transaction() {
        let checking = Ulid::generate();
        let groceries = Ulid::generate();

        let postings = vec![
            Posting::new(groceries, dec!(125.50), "PLN"),
            Posting::new(checking, dec!(-125.50), "PLN"),
        ];

        let tx = Transaction::new(
            "Supermarket",
            "food",
            vec!["groceries".into()],
            None,
            postings,
        );

        assert!(tx.is_ok());
        let tx = tx.unwrap();
        assert_eq!(tx.category, "food");
        assert_eq!(tx.postings.len(), 2);
    }

    #[test]
    fn test_unbalanced_transaction_fails() {
        let checking = Ulid::generate();
        let groceries = Ulid::generate();

        let postings = vec![
            Posting::new(groceries, dec!(100.00), "PLN"),
            Posting::new(checking, dec!(-90.00), "PLN"),
        ];

        let result = Transaction::new("Supermarket", "food", vec![], None, postings);
        assert!(matches!(
            result,
            Err(TransactionError::UnbalancedPostings(c, sum)) if c == "PLN" && sum == dec!(10.00)
        ));
    }

    #[test]
    fn test_insufficient_postings_fails() {
        let checking = Ulid::generate();
        let postings = vec![Posting::new(checking, dec!(50.00), "EUR")];

        let result = Transaction::new("Single posting", "misc", vec![], None, postings);
        assert_eq!(result, Err(TransactionError::InsufficientPostings(1)));
    }

    #[test]
    fn test_empty_category_fails() {
        let acc1 = Ulid::generate();
        let acc2 = Ulid::generate();

        let postings = vec![
            Posting::new(acc1, dec!(50.00), "EUR"),
            Posting::new(acc2, dec!(-50.00), "EUR"),
        ];

        let result = Transaction::new("No category", "", vec![], None, postings);
        assert_eq!(result, Err(TransactionError::EmptyCategory));
    }

    #[test]
    fn test_multi_currency_exchange_transaction() {
        let bank_pln = Ulid::generate();
        let cash_eur = Ulid::generate();

        // Exchange 430.00 PLN for 100.00 EUR (kantor / ATM conversion)
        let postings = vec![
            Posting::new(bank_pln, dec!(-430.00), "PLN"),
            Posting::new(cash_eur, dec!(100.00), "EUR"),
        ];

        let tx = Transaction::new(
            "Kantor currency exchange",
            "transfer",
            vec!["travel".into()],
            None,
            postings,
        );

        assert!(tx.is_ok());
    }

    #[test]
    fn test_transaction_serde_json() {
        let acc1 = Ulid::generate();
        let acc2 = Ulid::generate();
        let receipt_id = Ulid::generate();

        let postings = vec![
            Posting::new(acc1, dec!(50.00), "USD"),
            Posting::new(acc2, dec!(-50.00), "USD"),
        ];

        let tx = Transaction::new(
            "Dinner",
            "dining",
            vec!["restaurant".into()],
            Some(receipt_id),
            postings,
        )
        .unwrap();

        let json = serde_json::to_string(&tx).expect("serialize tx");
        let deserialized: Transaction = serde_json::from_str(&json).expect("deserialize tx");
        assert_eq!(tx, deserialized);
    }
}
