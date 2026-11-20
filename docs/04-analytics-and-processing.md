# Analytics, Processing, and Reporting

## 1. Pre-Calculated Aggregates

The wallet stores analysis aggregates directly in PDS:

- **Monthly Summaries**: Total income, expenses, cash flow, and final balance per account.

- **Category Totals**: Aggregate spend per flat category for month and year intervals.

- **Net Worth History**: Snapshots of combined asset and liability balances across calendar dates.

## 2. PDS Processing Pipeline

PDS gives a native `processing` relation system:

- Each processing result binds to a specific transaction revision version.

- When a user modifies an older transaction:
  - The previous processing record becomes invalid for the new revision.
  - A new processing task starts to recompute affected aggregates.
  - PDS marks the task status as incomplete while computation runs.
  - After computation finishes, the engine stores the encrypted aggregate in PDS.

## 3. Visualizations

The Android interface renders four standard analytical views:

1. **Income vs. Expense**: Comparative bar charts across monthly intervals.

2. **Category Breakdown**: Proportional breakdown of expenses across categories.

3. **Net Worth Over Time**: Trend line that shows total assets minus total liabilities.

4. **Cash Flow Summary**: Inflow, outflow, and net balance changes per period.

## 4. Notifications for Scheduled Payments

- The system does not run automated financial operations.

- The app checks scheduled dates against local calendar time.

- The app emits local device notifications to prompt the user to log transactions.
