use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use ulid::Ulid;

/// Account category for balance sheet reporting.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AccountType {
    /// Liquid cash, checking, savings, or investment accounts.
    Asset,
    /// Debts, loans, credit cards, or accounts payable.
    Liability,
    /// Opening balances and retained equity.
    Equity,
}

/// A financial account entity.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Account {
    /// Unique ULID identifier.
    pub id: Ulid,
    /// Human-readable label for the account.
    pub name: String,
    /// Balance classification (asset, liability, equity).
    pub account_type: AccountType,
    /// Currency code (ISO 4217 such as USD, EUR, PLN) or commodity symbol.
    pub currency: String,
    /// Creation timestamp in UTC.
    pub created_at: DateTime<Utc>,
}

impl Account {
    /// Creates a new account with a newly generated ULID and the current UTC time.
    pub fn new(
        name: impl Into<String>,
        account_type: AccountType,
        currency: impl Into<String>,
    ) -> Self {
        Self {
            id: Ulid::generate(),
            name: name.into(),
            account_type,
            currency: currency.into(),
            created_at: Utc::now(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_account() {
        let account = Account::new("Main Checking", AccountType::Asset, "PLN");
        assert_eq!(account.name, "Main Checking");
        assert_eq!(account.account_type, AccountType::Asset);
        assert_eq!(account.currency, "PLN");
    }

    #[test]
    fn test_account_serde_json() {
        let account = Account::new("Cash", AccountType::Asset, "EUR");
        let serialized = serde_json::to_string(&account).expect("serialize account");
        let deserialized: Account = serde_json::from_str(&serialized).expect("deserialize account");
        assert_eq!(account, deserialized);
    }
}
