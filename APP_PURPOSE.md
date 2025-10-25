# CTU Kiosk Mobile - App Purpose & Functionality

## Overview

This is a **read-only ticket checker application**. It does NOT modify any data in the database.

---

## What This App Does

### ✅ Reads & Displays
- Fetches ticket data from Supabase
- Shows ticket details (name, facility, amount, dates)
- Displays dashboard statistics
- Shows facility-wise analytics

### ✅ Validates by Checking
- Compares current time with `date_expiry`
- Checks `transaction_status` field
- Shows validation result (Valid/Expired/Invalid)
- Displays time remaining or time since expiry

### ❌ Does NOT Do
- Does NOT mark tickets as "used"
- Does NOT modify any database records
- Does NOT update transaction status
- Does NOT change expiry dates

---

## How Validation Works

```
┌─────────────────────────────────────┐
│  Ticket Created in Kiosk System    │
│  - Gets reference number            │
│  - Gets expiry date (date_expiry)   │
│  - Status set to 'completed'        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  User Scans QR in Mobile App        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  App Fetches Ticket from Database   │
│  (READ ONLY - No modifications)     │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  App Checks:                        │
│  1. Is date_expiry > now?           │
│  2. Is transaction_status valid?    │
└─────────────────────────────────────┘
              ↓
        ┌─────┴─────┐
        ↓           ↓
    ✅ VALID    ❌ INVALID
    Green       Red
```

---

## Validation Logic

### Valid Ticket ✅
**Conditions:**
- `date_expiry` is in the future
- `transaction_status` == 'completed'

**Display:**
- Green checkmark icon
- "Valid Ticket" heading
- Badge showing: "Valid for X days/hours/minutes"
- All ticket details
- Green "Accept & Close" button

### Expired Ticket ❌
**Conditions:**
- `date_expiry` is in the past

**Display:**
- Red X icon
- "Expired Ticket" heading
- Badge showing: "Expired X days/hours/minutes ago"
- All ticket details
- Gray "Close" button

### Invalid Ticket ❌
**Conditions:**
- `transaction_status` is not 'completed'
- (e.g., 'cancelled', 'refunded', 'pending')

**Display:**
- Red X icon
- "Invalid Ticket" heading
- Transaction status shown
- All ticket details
- Gray "Close" button

---

## Database Operations

### Read Operations (Allowed)
```dart
// Fetch single ticket
supabaseService.validateTicket(referenceNumber)

// Fetch all tickets for dashboard
supabaseService.getDashboardStats()

// Get all tickets
supabaseService.getAllTickets()

// Test connection
supabaseService.testConnection()
```

### Write Operations (REMOVED)
```dart
// ❌ REMOVED - App doesn't modify data
// supabaseService.invalidateTicket(referenceNumber)
```

---

## User Workflow

### Scenario 1: Valid Ticket
1. User scans QR code
2. App shows: ✅ "Valid Ticket - Valid for 2 more days"
3. Staff allows entry
4. User clicks "Accept & Close"
5. **No database changes made**

### Scenario 2: Expired Ticket
1. User scans QR code
2. App shows: ❌ "Expired Ticket - Expired 3 hours ago"
3. Staff denies entry
4. User clicks "Close"
5. **No database changes made**

### Scenario 3: Check Later
1. Same ticket scanned again
2. App re-checks expiry date
3. Shows current status
4. **No history of previous checks stored**

---

## Key Points

1. **Stateless Checking**: Each scan is independent, no state stored
2. **Real-Time Validation**: Always checks against current time
3. **No Audit Trail**: App doesn't log who checked what ticket
4. **Read-Only Access**: Uses Supabase anon key with read permissions
5. **No Side Effects**: Scanning a ticket doesn't affect anything

---

## Security Implications

### Safe to Use
- Can't accidentally delete tickets
- Can't modify payment amounts
- Can't change expiry dates
- Can't alter transaction status

### Permissions Needed
- **Database**: Read-only access to `tickets` table
- **Device**: Camera permission for QR scanning
- **Network**: Internet connection to query Supabase

---

## Comparison with Other Systems

### Kiosk System (Creates Tickets)
- ✅ Creates new tickets
- ✅ Sets expiry dates
- ✅ Processes payments
- ✅ Generates QR codes

### Mobile App (Checks Tickets)
- ❌ Cannot create tickets
- ❌ Cannot modify expiry
- ❌ Cannot process payments
- ✅ Only reads and displays

---

## Future Considerations

If you need to track ticket usage:
- Add a separate `ticket_checks` table
- Log each scan with timestamp
- Track which staff member checked
- Keep `tickets` table unchanged

If you need to prevent reuse:
- Modify tickets in the kiosk system
- Set expiry to past date after use
- Or add `times_used` counter
- Mobile app still just reads

---

## Summary

**This app is a digital ticket checker** - like a staff member looking at a ticket to see if it's valid. It doesn't punch, stamp, or modify the ticket in any way. It just reads the expiry date and tells you if the ticket is still good.

**Analogy**: It's like checking if milk is expired by looking at the date on the carton. You're not changing the date, just reading it and making a decision.
