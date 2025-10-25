# CTU Kiosk Mobile - Ticket Checker Application

A Flutter-based ticket validation and monitoring application for CTU Kiosk system. This app provides **read-only** access to check ticket validity and view analytics.

## Features

- **QR Code Scanner**: Scan ticket QR codes for instant validation check
- **Manual Reference Checker**: Input ticket reference numbers manually
- **Expiry-Based Validation**: Automatically checks if tickets are still valid based on expiry date
  - Tickets are validated when created in the system
  - App checks validity by comparing current time with `date_expiry`
  - No database modifications - read-only checker
- **Dashboard Analytics**: 
  - Payment summaries (Today, Week, Month)
  - Visitor statistics
  - Facility-wise breakdowns
  - Interactive charts and visualizations
- **Modern UI**: Clean, fast, and intuitive interface

## Important Note

This app is a **read-only ticket checker**. It does not modify any data in the database. Tickets are validated and assigned expiry dates when they are created in the system. This app simply checks if a ticket is still within its valid period.

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Supabase account and project

## Database Setup

Create a `tickets` table in your Supabase database with the following schema:

```sql
CREATE TABLE tickets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reference_number TEXT UNIQUE NOT NULL,
  facility TEXT,
  amount DECIMAL(10, 2),
  visit_date TIMESTAMP WITH TIME ZONE,
  is_valid BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX idx_tickets_reference ON tickets(reference_number);
CREATE INDEX idx_tickets_visit_date ON tickets(visit_date);
```

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd CTU-Kiosk-Mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Supabase credentials in `lib/config/supabase_config.dart` (already configured)

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart      # Supabase configuration
├── models/
│   ├── ticket.dart                # Ticket data model
│   └── dashboard_stats.dart       # Dashboard statistics model
├── screens/
│   ├── dashboard_screen.dart      # Analytics dashboard
│   └── scanner_screen.dart        # QR scanner & reference checker
├── services/
│   └── supabase_service.dart      # Database operations
├── widgets/
│   └── ticket_validation_dialog.dart  # Validation result dialog
└── main.dart                      # App entry point
```

## Usage

### Scanner Tab
1. Point camera at QR code to scan automatically
2. Or manually enter reference number in the text field
3. View validation results with ticket details
4. Check expiry status:
   - **Valid**: Green checkmark + time remaining (e.g., "Valid for 2 more days")
   - **Expired**: Red X + time since expiry (e.g., "Expired 3 hours ago")
   - **Invalid**: Red X for tickets with invalid status

### Dashboard Tab
1. View real-time payment and visitor statistics
2. Analyze data by time periods (Today, Week, Month)
3. See facility-wise breakdowns in charts
4. Pull down to refresh data

**Note**: All operations are read-only. The app does not modify any ticket data.

## Dependencies

- `supabase_flutter`: Database integration
- `mobile_scanner`: QR code scanning
- `fl_chart`: Data visualization
- `google_fonts`: Typography
- `intl`: Date/number formatting
- `permission_handler`: Camera permissions

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## License

This project is part of a capstone project for CTU.
