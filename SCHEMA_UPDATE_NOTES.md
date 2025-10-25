# Database Schema Update Notes

## Date: October 25, 2025

### Changes Made

The app has been updated to match the actual Supabase database schema.

### Old Schema (Expected)
```sql
- id (UUID)
- reference_number (TEXT)
- facility (TEXT, nullable)
- amount (DECIMAL, nullable)
- visit_date (TIMESTAMPTZ, nullable)
- is_valid (BOOLEAN)
- created_at (TIMESTAMPTZ)
```

### New Schema (Actual)
```sql
- id (BIGINT)
- reference_number (TEXT)
- name (TEXT)
- age (INTEGER, nullable)
- captured_image_url (TEXT, nullable)
- facility (TEXT)
- payment_amount (NUMERIC)
- original_price (NUMERIC, nullable)
- has_discount (BOOLEAN)
- date_created (TIMESTAMPTZ)
- date_expiry (TIMESTAMPTZ)
- qr_code_data (TEXT, nullable)
- transaction_status (TEXT)
- method_type (TEXT, nullable)
- amount_inserted (NUMERIC, nullable)
- change_given (NUMERIC, nullable)
- synced_at (TIMESTAMPTZ, nullable)
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ, nullable)
```

### Files Updated

1. **lib/models/ticket.dart**
   - Updated all fields to match actual schema
   - Added helper getters for backward compatibility:
     - `amount` → returns `paymentAmount`
     - `visitDate` → returns `dateCreated`
     - `isValid` → checks if `transactionStatus` is 'completed' or 'valid'

2. **lib/services/supabase_service.dart**
   - Updated `invalidateTicket()` to set `transaction_status = 'used'` instead of `is_valid = false`
   - Added `updated_at` timestamp when invalidating tickets

3. **lib/widgets/ticket_validation_dialog.dart**
   - Updated UI to display new fields:
     - Name
     - Age (if available)
     - Original Price (if has discount)
     - Expiry Date
     - Transaction Status

### Backward Compatibility

The Ticket model includes helper getters to maintain compatibility with existing code:
- `ticket.amount` → `ticket.paymentAmount`
- `ticket.visitDate` → `ticket.dateCreated`
- `ticket.isValid` → checks `ticket.transactionStatus`

### Testing

After these changes, the app should:
1. ✅ Connect to Supabase successfully
2. ✅ Fetch and display tickets from the database
3. ✅ Show dashboard statistics with real data
4. ✅ Validate tickets by scanning QR codes or entering reference numbers
5. ✅ Mark tickets as "used" when validated

### Debug Output

The app now logs detailed information:
- Connection test results
- Number of tickets fetched
- Dashboard statistics calculated
- Ticket validation attempts

Check the console/debug output for these messages to verify data syncing is working.
