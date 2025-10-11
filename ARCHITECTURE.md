# CTU Kiosk Mobile - Architecture Overview

## Application Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     CTU Kiosk Admin                      │
│                   (Flutter Mobile App)                   │
└─────────────────────────────────────────────────────────┘
                            │
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌───────────────┐                      ┌───────────────┐
│   Dashboard   │                      │    Scanner    │
│    Screen     │                      │    Screen     │
└───────────────┘                      └───────────────┘
        │                                       │
        │                                       │
        │                              ┌────────┴────────┐
        │                              │                 │
        │                              ▼                 ▼
        │                      ┌──────────────┐  ┌─────────────┐
        │                      │  QR Scanner  │  │   Manual    │
        │                      │   (Camera)   │  │    Input    │
        │                      └──────────────┘  └─────────────┘
        │                              │                 │
        └──────────────────────────────┴─────────────────┘
                                       │
                                       ▼
                            ┌─────────────────┐
                            │ Supabase Service│
                            └─────────────────┘
                                       │
                                       ▼
                            ┌─────────────────┐
                            │    Supabase     │
                            │    Database     │
                            │   (PostgreSQL)  │
                            └─────────────────┘
```

## Component Breakdown

### 1. Main App (`main.dart`)
- **Purpose**: Entry point, app initialization
- **Responsibilities**:
  - Initialize Supabase connection
  - Configure app theme (Material 3, Google Fonts)
  - Set up navigation structure
  - Manage bottom navigation bar

### 2. Dashboard Screen (`screens/dashboard_screen.dart`)
- **Purpose**: Display analytics and statistics
- **Features**:
  - Payment summary cards (Today, Week, Month)
  - Visitor count cards (Today, Week, Month)
  - Pie chart: Visitors by facility
  - Bar chart: Payments by facility
  - Pull-to-refresh functionality
- **Data Flow**:
  1. Fetches data from SupabaseService
  2. Calculates statistics (today, week, month)
  3. Renders charts using fl_chart
  4. Updates on refresh

### 3. Scanner Screen (`screens/scanner_screen.dart`)
- **Purpose**: Validate tickets via QR or manual input
- **Features**:
  - Real-time QR code scanning
  - Manual reference number input
  - Validation feedback
  - Ticket details display
- **Data Flow**:
  1. Captures QR code or text input
  2. Sends to SupabaseService for validation
  3. Shows TicketValidationDialog with results
  4. Allows marking ticket as used

### 4. Ticket Validation Dialog (`widgets/ticket_validation_dialog.dart`)
- **Purpose**: Display ticket validation results
- **Features**:
  - Visual status indicator (valid/invalid)
  - Ticket details display
  - "Mark as Used" action button
  - Formatted date and currency display
- **States**:
  - Valid ticket (green, can be marked as used)
  - Invalid ticket (red, already used)

### 5. Supabase Service (`services/supabase_service.dart`)
- **Purpose**: Handle all database operations
- **Methods**:
  - `validateTicket(referenceNumber)`: Check if ticket exists and is valid
  - `getDashboardStats()`: Fetch and calculate statistics
  - `invalidateTicket(referenceNumber)`: Mark ticket as used
- **Data Processing**:
  - Filters by date ranges (today, week, month)
  - Aggregates by facility
  - Calculates totals and counts

### 6. Models

#### Ticket Model (`models/ticket.dart`)
```dart
{
  id: UUID
  referenceNumber: String
  facility: String?
  amount: double?
  visitDate: DateTime?
  isValid: bool
  createdAt: DateTime
}
```

#### Dashboard Stats Model (`models/dashboard_stats.dart`)
```dart
{
  totalPaymentToday: double
  totalPaymentWeek: double
  totalPaymentMonth: double
  visitorsToday: int
  visitorsWeek: int
  visitorsMonth: int
  visitorsByFacility: Map<String, int>
  paymentsByFacility: Map<String, double>
}
```

## Data Flow Diagrams

### Ticket Validation Flow
```
User Action (Scan/Input)
        │
        ▼
Scanner Screen
        │
        ▼
Extract Reference Number
        │
        ▼
Supabase Service
        │
        ▼
Query Database
        │
        ├─── Ticket Found ────► Show Valid/Invalid Dialog
        │                              │
        │                              ▼
        │                       User Marks as Used?
        │                              │
        │                              ▼
        │                       Update Database
        │                              │
        │                              ▼
        │                       Show Success Message
        │
        └─── Not Found ────────► Show Error Dialog
```

### Dashboard Data Flow
```
Dashboard Screen Load
        │
        ▼
Supabase Service
        │
        ▼
Fetch All Tickets (Current Month)
        │
        ▼
Calculate Statistics
        │
        ├─── Filter by Today ────► Today Stats
        ├─── Filter by Week ─────► Week Stats
        ├─── Filter by Month ────► Month Stats
        └─── Group by Facility ──► Facility Stats
        │
        ▼
Return DashboardStats Object
        │
        ▼
Render UI Components
        │
        ├─── Stat Cards
        ├─── Pie Chart
        └─── Bar Chart
```

## Technology Stack

### Frontend
- **Framework**: Flutter 3.9.2+
- **Language**: Dart
- **UI Components**: Material 3
- **Charts**: fl_chart
- **Fonts**: Google Fonts (Inter)
- **QR Scanner**: mobile_scanner

### Backend
- **Database**: Supabase (PostgreSQL)
- **API**: Supabase REST API
- **Authentication**: Supabase Auth (anon key)

### Permissions
- **Android**: CAMERA, INTERNET
- **iOS**: Camera usage description

## Security Considerations

1. **API Key**: Currently using anon key (public)
   - Safe for read operations
   - Consider RLS policies for production

2. **Data Validation**: 
   - All inputs validated before database queries
   - Error handling for network failures

3. **Permissions**:
   - Camera permission requested at runtime
   - Internet permission for API calls

## Performance Optimizations

1. **Database Queries**:
   - Indexed on `reference_number` for fast lookups
   - Indexed on `visit_date` for date filtering
   - Single query for dashboard (filters client-side)

2. **UI Rendering**:
   - Lazy loading of charts
   - Pull-to-refresh instead of auto-refresh
   - Async operations with loading indicators

3. **State Management**:
   - Local state with setState
   - No global state management needed
   - Minimal rebuilds

## Future Enhancements

1. **Authentication**: Add admin login
2. **Offline Mode**: Cache data locally
3. **Push Notifications**: Alert for new tickets
4. **Export Reports**: PDF/Excel generation
5. **Multi-language**: i18n support
6. **Dark Mode**: Theme switching
7. **Advanced Filters**: Date range picker, facility filter
8. **Ticket Creation**: Add tickets from admin app
