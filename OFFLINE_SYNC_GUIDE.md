# Offline Data Sync Implementation Guide

## Overview

The CTU Kiosk Mobile app has been enhanced with **full offline capabilities**. The app now:

- ✅ Automatically syncs data from Supabase on startup
- ✅ Stores all ticket data locally using Hive database
- ✅ Works completely offline - users can still validate tickets without internet
- ✅ Periodically syncs in the background every 30 minutes (when online)
- ✅ Shows sync status and last sync time to users

## How It Works

### 1. **Initial Startup Sync**

When the app starts:

1. Supabase is initialized
2. Local database (Hive) is initialized
3. **All tickets from Supabase are downloaded and cached locally**
4. If sync fails, the app still runs with previously cached data

```
App Start
    ↓
Initialize Supabase
    ↓
Initialize Hive Local DB
    ↓
Force Sync: Download all tickets from Supabase
    ↓
Run App (even if sync fails)
```

### 2. **Offline-First Data Lookup**

When scanning or validating tickets:

```
User Scans QR Code
    ↓
Search Local Database (Hive) First
    ├─ FOUND → Show ticket immediately (offline-ready) ✓
    └─ NOT FOUND
         ↓
         Check if Online
         ├─ YES → Fetch from Supabase
         │         ├─ FOUND → Show ticket
         │         └─ NOT FOUND → Show "Not Found" error
         └─ NO → Show "Offline - Not in local cache" message
```

### 3. **Background Periodic Sync**

Every 30 minutes, the app automatically:

- Checks connection to Supabase
- Downloads latest tickets from Supabase
- Updates local cache
- Continues silently in the background (doesn't interrupt user)

## Key Features

### Local Database (Hive)

- **Fast**: Stores data locally on device for instant lookups
- **Reliable**: Works without internet connection
- **Automatic**: Syncs in background every 30 minutes
- **What's stored**: All tickets with reference numbers, facility, amount, dates, status

### Sync Status Widget

Users can see:

- **Number of tickets cached**: How many tickets are available offline
- **Last sync time**: When data was last updated from Supabase
  - "Just now" = Within last minute
  - "5m ago" = 5 minutes ago
  - "1h ago" = 1 hour ago
  - "Never synced" = No sync has occurred yet

Appears on:

- **Dashboard**: Below the tab bar
- **Scanner**: At the top of the screen

### Manual Refresh

Users can manually refresh data:

1. **Dashboard**: Tap the 🔄 Refresh button in the app bar
2. **Scanner**: Pull down to refresh (or tap refresh)
3. **Or wait**: 30-minute automatic background sync

## Offline Scenarios

### Scenario 1: App Starts Online

```
✓ Initial sync completes successfully
✓ All tickets cached
✓ App shows "X tickets cached - Last sync: just now"
✓ User can work online OR offline
```

### Scenario 2: App Starts Offline

```
⚠ Initial sync fails (no internet)
✓ App still launches
✓ Uses tickets from previous session cache
✓ Shows "X tickets cached - Last sync: 2 hours ago"
✓ User can scan and validate tickets offline
```

### Scenario 3: Scanning Ticket Offline

```
User enters ticket: ABC123
    ↓
App searches local cache
    ✓ FOUND → Shows ticket details immediately
    ✗ NOT FOUND → Shows "Offline - Ticket not in local cache"
         (Would find it if connection restored)
```

### Scenario 4: App Goes Offline During Use

```
User was online, scanning works
    ↓
Internet disconnects
    ↓
User continues scanning
    ✓ Previously cached tickets → Show results
    ✗ New tickets (not yet cached) → "Offline - Not in cache"
    ↓
Background sync waits for connection
    ↓
When online again → Automatically syncs new data
```

## Database Schema

### Cached Ticket Data

```dart
class TicketCache {
  String id;                          // Unique ID
  String referenceNumber;             // Ticket QR code
  int? age;                          // Customer age (optional)
  String facility;                   // Which facility (e.g., "Library")
  double amount;                     // Amount paid
  DateTime visitDate;                // Visit date
  DateTime createdAt;                // Created timestamp
  String transactionStatus;          // "completed", "pending", etc.
}
```

### Metadata Stored

- **Last sync timestamp**: When tickets were last updated
- **Ticket count**: How many tickets are in cache

## Configuration

### Sync Interval

Currently set to **30 minutes**. To change:

1. Open `lib/main.dart`
2. Find: `Timer.periodic(const Duration(minutes: 30), (_) {`
3. Change `30` to desired minutes

### Connection Check Timeout

Handled automatically. If connection check takes too long, the app continues with cached data.

## Error Handling

### If Initial Sync Fails

- ✓ App still launches normally
- ✓ Uses tickets from previous session
- ✓ Continues to work offline
- ✓ Retries sync in 30 minutes

### If Supabase is Down

- ✓ Validation uses local cache
- ✓ App continues to function
- ✓ No crashes or stuck screens

### If Local Database is Corrupted

- ✓ App detects and reinitializes
- ✓ Attempts fresh sync from Supabase
- ✓ Shows error message to user

## User-Facing Information

### The Sync Status Widget Shows:

| Status                    | Meaning                             |
| ------------------------- | ----------------------------------- |
| "X tickets cached"        | Number of tickets available locally |
| "Last sync: just now"     | Data is fresh (within 1 minute)     |
| "Last sync: 10m ago"      | Data was updated 10 minutes ago     |
| "Last sync: Never synced" | First run or sync never succeeded   |

### What Users Should Know:

1. **No internet needed**: Ticket validation works offline
2. **Data auto-updates**: Background sync every 30 minutes
3. **Manual refresh**: Tap refresh button for immediate update
4. **Cache indicator**: Shows how many tickets are available
5. **Offline badge**: "From Local Cache" appears on tickets validated offline

## Technical Details

### Libraries Used

- **Hive**: Local data storage (key-value NoSQL database)
- **Connectivity Plus**: Network status monitoring
- **Supabase Flutter**: Backend sync

### File Structure

```
lib/
├── services/
│   ├── local_database_service.dart    # Hive database management
│   ├── supabase_service.dart          # Sync from Supabase
│   └── connectivity_service.dart      # Connection monitoring
├── models/
│   ├── ticket.dart                    # Online ticket model
│   └── ticket_cache.dart              # Offline cache model
├── widgets/
│   ├── sync_status_widget.dart        # Shows sync status
│   └── ticket_validation_dialog.dart  # Shows ticket with offline badge
└── screens/
    ├── dashboard_screen.dart          # With sync status
    └── scanner_screen.dart            # Offline-first validation
```

### Key Methods

#### `LocalDatabaseService.getTicketByReferenceNumber()`

- Searches local cache for ticket
- Used for offline-first validation
- Returns immediately (no network needed)

#### `LocalDatabaseService.syncFromSupabase()`

- Downloads latest tickets from Supabase
- Updates local cache
- Happens on app start and every 30 minutes

#### `LocalDatabaseService.getCacheStats()`

- Returns: ticket count, last sync time
- Used to display sync status widget

## Testing Offline Mode

### To Test Offline Functionality:

**Test 1: Airplane Mode**

1. Open app normally (online)
2. Wait for initial sync
3. Enable Airplane mode
4. Try scanning tickets
5. ✓ Should still work with cached tickets

**Test 2: Offline App Start**

1. Enable Airplane mode
2. Restart app
3. ✓ App should start and show cached tickets
4. ✓ Should show "Last sync: [previous time]"

**Test 3: New Ticket (Offline)**

1. Be offline
2. Scan a ticket not in cache
3. ✓ Should show "Offline - Not in local cache"
4. Disable Airplane mode
5. Tap refresh
6. ✓ Should now show the ticket

**Test 4: Auto-Refresh**

1. Start app online
2. Disable internet (Airplane mode)
3. Wait 30 minutes
4. Enable internet
5. ✓ Should automatically sync in background

## Troubleshooting

### Issue: "Offline - Ticket not in local cache"

**Solution:**

1. Tap Refresh button
2. Wait for sync to complete
3. Try scanning again
4. If still not found, ticket may not exist in database

### Issue: App doesn't sync automatically

**Solution:**

1. Check app is not closed
2. Ensure device has internet
3. Manually tap Refresh button
4. Check Hive database is initialized properly

### Issue: Sync takes a long time

**Solution:**

1. Normal if many tickets in database (first sync)
2. Should be faster after initial sync
3. Background sync happening (doesn't block UI)
4. Can continue using app while syncing

### Issue: "Never synced" message

**Solution:**

1. First install/app cleared
2. Tap Refresh to sync immediately
3. Or wait for background sync in 30 minutes

## Future Enhancements

Potential improvements:

- [ ] Selective sync (specific date ranges)
- [ ] Compression for faster sync
- [ ] User-configurable sync interval
- [ ] Sync status notifications
- [ ] Local search with filters
- [ ] Data export to CSV
- [ ] Sync history logging

---

## Summary

✅ **Your app is now fully offline-capable!**

- Tickets sync automatically on startup
- Data searches work instantly (no internet needed)
- Background sync keeps local data fresh
- Users always know the status via sync widget
- Gracefully handles network failures

**Result**: Personnel can now use the app even with unreliable or no internet connection.
