# CTU Kiosk Mobile Admin

Flutter admin application for monitoring CTU kiosk activity directly from Supabase.

## Current Data Source

The active app flow now reads from the new Supabase project instead of the old local ticket cache.

Configured project:

- Supabase URL: `https://hahvllylxvdmdsdmtate.supabase.co`
- Public key type: publishable key

## Active Table Mapping

- `transactions`
  - Main completed transaction source
  - Used by dashboard totals, recent transactions, transaction list, search, print status, and duration monitoring
- `transaction_breakdown`
  - Per-category quantity and subtotal rows
  - Used by dashboard reporting and transaction details
- `ticket_counters`
  - Intended source for the counters screen
  - If the table is not available in Supabase, the app derives counter values from recent transactions and marks them read-only

The current Supabase project was verified to expose `transactions` and `transaction_breakdown`. The other planned admin tables are not currently reachable from the configured public key, so the app degrades safely where needed.

## Main Screens

- Dashboard
  - Sales, units, transaction counts, average duration, status summaries, recent transactions, and report charts
- Transactions
  - Filtered transaction list with search by ticket label, session ID, facility, or local transaction ID
- Counters
  - Displays per-facility counters and allows editing only when `ticket_counters` is available
- Search / Reprint
  - QR or manual lookup that opens full transaction details

## Transaction Details

Each transaction detail page shows:

- Transaction ID and session ID
- Facility code and facility name
- Ticket label and range
- Amount due and amount paid
- Started/completed timestamps
- Duration, payment status, print status, sync marker, and source mode
- Full `transaction_breakdown` rows

## Project Structure

```text
lib/
├── config/
│   └── supabase_config.dart
├── models/
│   ├── admin_transaction.dart
│   ├── dashboard_stats.dart
│   ├── ticket_counter.dart
│   └── transaction_breakdown_item.dart
├── screens/
│   ├── admin_dashboard_screen.dart
│   ├── counters_screen.dart
│   ├── search_screen.dart
│   ├── transaction_detail_screen.dart
│   └── transactions_screen.dart
├── services/
│   └── supabase_service.dart
├── utils/
│   └── taipei_time.dart
└── widgets/
    └── sync_status_widget.dart
```

## Development Notes

- The old local cache path is no longer used by the active app flow.
- `local_database_service.dart` remains only as a compatibility adapter for legacy imports.
- Time displays use the shared UTC+8 helper already present in the project.

## Running

```bash
flutter pub get
flutter run
```

## Validation Status

- Dart analysis: clean
- Widget test execution: blocked by local Flutter CLI path configuration in this workspace
