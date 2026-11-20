# Release Plan and Roadmap

## 1. Version 1.0 (MVP)

The initial version delivers basic tracking, encryption, and sync.

### Rust Core Capabilities
- Double-entry event-sourced models.

- Transaction validation logic.

- PDS client for encrypted financial records.

- PDS reference resolver for unencrypted receipt entries and image files.

- Aggregate calculation pipeline for month, category, and net worth data.

### Interop Layer
- Native JNI and C bindings through `flutter_rust_bridge`.

### Android Client (Flutter)
- Account overview screen with asset totals.

- Manual transaction creation and currency conversion interface.

- Debt management view with partial settlements, interest rates, and due dates.

- Flat category selector and multi-tag editor.

- DAG divergence resolution screen for conflicting sync records.

### Visualizations and Alerts
- Income vs. Expense chart.

- Category breakdown chart.

- Net worth trend chart.

- Cash flow summary chart.

- Scheduled payment local reminder notifications.

## 2. Version 2.0 (Planned Additions)

- Direct statement file import (CSV, MT940, CAMT.053, OFX).

- Extended analytical metrics (savings rate, runway length, burn rate).

- Category budget limits with spending alerts.

- Desktop application builds (Linux, macOS, Windows) with the Rust core.
