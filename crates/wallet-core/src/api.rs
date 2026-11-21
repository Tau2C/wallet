use crate::account::{Account, AccountType};
use crate::transaction::{Posting, Transaction};
use flutter_rust_bridge::frb;
use rust_decimal::Decimal;
use std::str::FromStr;
use ulid::Ulid;

/// DTO for creating an account from Dart.
#[frb]
pub struct AccountDto {
    pub id: String,
    pub name: String,
    pub account_type: String,
    pub currency: String,
    pub created_at: String,
}

impl From<Account> for AccountDto {
    fn from(acc: Account) -> Self {
        let account_type = match acc.account_type {
            AccountType::Asset => "asset".to_string(),
            AccountType::Liability => "liability".to_string(),
            AccountType::Equity => "equity".to_string(),
        };
        Self {
            id: acc.id.to_string(),
            name: acc.name,
            account_type,
            currency: acc.currency,
            created_at: acc.created_at.to_rfc3339(),
        }
    }
}

/// DTO for a transaction posting.
#[frb]
pub struct PostingDto {
    pub account_id: String,
    pub amount: String,
    pub currency: String,
}

/// DTO for a full transaction.
#[frb]
pub struct TransactionDto {
    pub id: String,
    pub timestamp: String,
    pub description: String,
    pub category: String,
    pub tags: Vec<String>,
    pub receipt_id: Option<String>,
    pub postings: Vec<PostingDto>,
}

impl From<Transaction> for TransactionDto {
    fn from(tx: Transaction) -> Self {
        Self {
            id: tx.id.to_string(),
            timestamp: tx.timestamp.to_rfc3339(),
            description: tx.description,
            category: tx.category,
            tags: tx.tags,
            receipt_id: tx.receipt_id.map(|r| r.to_string()),
            postings: tx
                .postings
                .into_iter()
                .map(|p| PostingDto {
                    account_id: p.account_id.to_string(),
                    amount: p.amount.to_string(),
                    currency: p.currency,
                })
                .collect(),
        }
    }
}

/// Initializes logging and core engine runtime.
#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

/// Returns the wallet core engine version.
pub fn get_core_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

/// Creates a new Account and returns its DTO.
pub fn create_account(
    name: String,
    account_type_str: String,
    currency: String,
) -> Result<AccountDto, String> {
    let account_type = match account_type_str.to_lowercase().as_str() {
        "asset" => AccountType::Asset,
        "liability" => AccountType::Liability,
        "equity" => AccountType::Equity,
        other => return Err(format!("Nieznany typ konta: {}", other)),
    };

    let account = Account::new(name, account_type, currency);
    Ok(account.into())
}

/// Creates and validates a double-entry transaction.
pub fn create_transaction(
    description: String,
    category: String,
    tags: Vec<String>,
    receipt_id_str: Option<String>,
    postings_dto: Vec<PostingDto>,
) -> Result<TransactionDto, String> {
    let receipt_id = match receipt_id_str {
        Some(r) => Some(Ulid::from_string(&r).map_err(|e| format!("Błędny ULID paragonu: {}", e))?),
        None => None,
    };

    let mut postings = Vec::with_capacity(postings_dto.len());
    for p in postings_dto {
        let acc_id = Ulid::from_string(&p.account_id)
            .map_err(|e| format!("Błędny ULID konta {}: {}", p.account_id, e))?;
        let amount = Decimal::from_str(&p.amount)
            .map_err(|e| format!("Błędna kwota {}: {}", p.amount, e))?;
        postings.push(Posting::new(acc_id, amount, p.currency));
    }

    let tx = Transaction::new(description, category, tags, receipt_id, postings)
        .map_err(|e| e.to_string())?;

    Ok(tx.into())
}
