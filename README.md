# Wallet (PDS-backed Financial Management)

Privacy-focused personal finance, account, and transaction management app backed by Personal Data Server (PDS).

## Features

- **Double-Entry Accounting Engine**: Core accounting models and balance validation written in Rust (`crates/wallet-core`).
- **Encrypted Local Storage & Sync**: Selective E2EE encryption for financial data with PDS backend (`top.tau2c.pds.core`).
- **Cross-Platform UI**: Built with Flutter and integrated via `flutter_rust_bridge`.
- **F-Droid Publishing**: Automated CI pipeline publishing APK releases to `git@github.com:Tau2C/fdroid-repo`.

## Architecture & Documentation

Full specifications are located in the [`docs/`](docs/) directory:
- [01-architecture.md](docs/01-architecture.md): System architecture and Flutter-Rust-PDS communication.
- [02-data-model.md](docs/02-data-model.md): Double-entry ledgers, ULID, and account models.
- [03-pds-sync-and-storage.md](docs/03-pds-sync-and-storage.md): PDS sync, Pub/Sub, and DAG conflict resolution.
- [04-analytics-and-processing.md](docs/04-analytics-and-processing.md): Aggregates and reporting.
- [05-roadmap.md](docs/05-roadmap.md): Version milestones and release roadmap.
