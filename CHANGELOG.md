# Changelog

All notable changes to the CTU Kiosk Mobile Admin app will be documented in this file.

## [1.1.0] - 2025-11-03

### Added
- **All Time Statistics**: Added "All Time" payment and visitor cards to dashboard
  - Total revenue across all time periods
  - Total visitor count across all time periods
  - Displayed with distinctive colors (Deep Purple for payments, Deep Orange for visitors)

- **Month Selector**: Added interactive month picker to dashboard
  - Select any month from 2020 to present
  - View historical data for specific months
  - Clear filter button to return to current month
  - Visual indicator showing currently selected period
  - Automatic data refresh when month changes

### Changed
- **Dashboard Data Model**: Updated `DashboardStats` to include:
  - `totalPaymentAllTime` field
  - `visitorsAllTime` field

- **Service Layer**: Enhanced `getDashboardStats()` method:
  - Added optional `selectedMonth` parameter
  - Calculates statistics for selected month or current month
  - Filters today/week stats only when viewing current month
  - Improved date filtering logic for accurate month boundaries

- **UI Layout**: Reorganized dashboard cards:
  - Payment Summary: Today → Week → Month → All Time
  - Visitor Summary: Today → Week → Month → All Time
  - All cards maintain consistent styling and spacing

### Technical Details

#### New Features Implementation

**Month Selector UI:**
```dart
// Located at top of dashboard
- Blue-tinted container with calendar icon
- Shows current viewing period
- "Change" button opens date picker
- "Clear" button (X icon) removes filter
```

**Date Picker:**
```dart
// Configuration
- Initial mode: Year selection
- Date range: 2020 to present
- Returns first day of selected month
- Triggers automatic data refresh
```

**All Time Stats Calculation:**
```dart
// Fetches all tickets from database
- Sums all payment amounts
- Counts all ticket records
- Independent of month filter
- Always shows complete historical data
```

### UI Screenshots Description

**Month Selector (Default State):**
- Shows "Current Month (November 2025)"
- Blue background with calendar icon
- "Change" button on the right

**Month Selector (Filtered State):**
- Shows selected month (e.g., "October 2025")
- Includes "X" close button to clear filter
- "Change" button to select different month

**All Time Cards:**
- Deep Purple gradient for payment card
- Deep Orange gradient for visitor card
- Infinity icon (∞) to represent "all time"
- Full-width cards below month cards

### Performance Impact
- Minimal: All-time calculation done in single database query
- Month filtering performed client-side for efficiency
- No additional database calls when changing months

### Backward Compatibility
- Fully backward compatible with existing database schema
- No database migrations required
- Works with existing ticket data

## [1.0.0] - 2025-10-11

### Initial Release
- QR Code Scanner for ticket validation
- Manual reference number input
- Real-time ticket validation
- Dashboard with payment and visitor statistics
- Facility-wise breakdown charts (Pie & Bar)
- Material 3 design with modern UI
- Supabase database integration
- Cross-platform support (Android, iOS, Web, Desktop)

---

## Upgrade Instructions

### From 1.0.0 to 1.1.0

1. **Update Dependencies** (if needed):
   ```bash
   flutter pub get
   ```

2. **No Database Changes Required**:
   - The app works with existing database schema
   - No migrations needed

3. **Test the New Features**:
   - Open Dashboard tab
   - Click "Change" button in month selector
   - Select a different month
   - Verify All Time stats are displayed
   - Clear filter and return to current month

4. **Verify Functionality**:
   - All Time cards show cumulative data
   - Month selector filters data correctly
   - Today/Week stats only show when viewing current month
   - Charts update based on selected month

### Known Issues
- None reported

### Future Enhancements
- Date range selector (custom start and end dates)
- Export reports for selected periods
- Comparison view (month vs month)
- Trend analysis and predictions
