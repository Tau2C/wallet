# PDS Storage, Encryption, and Synchronization

## 1. Storage and Encryption Boundary

The system uses selective encryption before it writes records to PDS:

| Record Type | Encrypted in PDS | Visible to External Apps |
|---|---|---|
| Accounts | Yes | No |
| Transactions & Postings | Yes | No |
| Debts & Repayments | Yes | No |
| Analytic Aggregates | Yes | No |
| Receipt Metadata Entries | No | Yes |
| Receipt Image Files | No | Yes |

## 2. Offline Synchronization

- The local PDS daemon buffers writes during offline periods.

- The wallet core writes transactions directly to the local PDS daemon.

- When network connectivity returns, the PDS daemon manages sync queues.

## 3. Real-Time Event Subscription

- The wallet subscribes to a PDS PubSub event channel.

- The PDS daemon pushes updates to the wallet in real time.

- If the application starts after sleep, the channel replays missed sync events.

## 4. DAG Divergence and Conflict Policy

PDS models concurrent edits as branches in a Directed Acyclic Graph (DAG):

- **Automatic Merges**: Non-conflicting attributes merge automatically.

- **Manual Conflicts**: Conflicting field modifications create a branch divergence.

- **Resolution Priority**: Correcting divergent branches has high priority.

### Resolution Steps

- **Input Deferral**: When the user enters a transaction, the app defers the prompt.

- The prompt waits until the user finishes the active input.

- **Merge Screen**: When the user is idle, the application shows the divergence view.
