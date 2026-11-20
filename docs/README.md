# Architecture Overview

This project is a personal finance archival and analysis tool. It uses a Rust backend core and an Android client.

## Core Properties

- **Privacy**: The client encrypts financial records and account data before storage.

- **Storage**: The tool stores entries in an existing Personal Data Server (PDS).

- **Audit**: The PDS maintains full revision history for all records.

- **Attachments**: The PDS stores receipt files without encryption.

- Other projects can access these receipt files directly.

## Document Index

1. [Architecture and System Design](file:///home/tau2c/Projects/wallet/docs/01-architecture.md)

2. [Data Model and Ledgers](file:///home/tau2c/Projects/wallet/docs/02-data-model.md)

3. [PDS Storage, Encryption, and Sync](file:///home/tau2c/Projects/wallet/docs/03-pds-sync-and-storage.md)

4. [Analytics, Processing, and Reporting](file:///home/tau2c/Projects/wallet/docs/04-analytics-and-processing.md)

5. [Release Plan and Roadmap](file:///home/tau2c/Projects/wallet/docs/05-roadmap.md)
