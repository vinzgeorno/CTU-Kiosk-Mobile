# CTU Kiosk Mobile - Setup Guide

## Quick Start Guide

### 1. Database Setup in Supabase

1. **Go to your Supabase Dashboard**: https://nzcprxadltjbhuohwbix.supabase.co

2. **Navigate to SQL Editor** (left sidebar)

3. **Create the tickets table** by running this SQL:

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

-- Create indexes for better performance
CREATE INDEX idx_tickets_reference ON tickets(reference_number);
CREATE INDEX idx_tickets_visit_date ON tickets(visit_date);
```

4. **Insert sample data** (optional, for testing):
   - Open `sample_data.sql` file in this project
   - Copy and paste the SQL into Supabase SQL Editor
   - Run it to populate test data

### 2. Enable Row Level Security (RLS) - Optional

If you want to add security policies:

```sql
-- Enable RLS
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access (for the admin app)
CREATE POLICY "Allow anonymous read access" ON tickets
  FOR SELECT
  TO anon
  USING (true);

-- Allow anonymous update access (for marking tickets as used)
CREATE POLICY "Allow anonymous update access" ON tickets
  FOR UPDATE
  TO anon
  USING (true);
```

### 3. Flutter App Setup

1. **Enable Developer Mode** (Windows):
   - Press `Win + I` to open Settings
   - Go to "Privacy & Security" > "For developers"
   - Turn on "Developer Mode"
   - This is required for Flutter to work properly on Windows

2. **Install Dependencies**:
```bash
cd CTU-Kiosk-Mobile
flutter pub get
```

3. **Check Flutter Setup**:
```bash
flutter doctor
```
Make sure you have:
- Flutter SDK installed
- Android Studio or VS Code with Flutter extension
- Android SDK (for Android development)
- Chrome (for web development)

4. **Run the App**:

For Android device/emulator:
```bash
flutter run
```

For Chrome (web):
```bash
flutter run -d chrome
```

For Windows desktop:
```bash
flutter run -d windows
```

### 4. Testing the App

#### Scanner Tab:
1. Go to Scanner tab (bottom navigation)
2. Test manual entry:
   - Enter `TKT-2024-001` in the text field
   - Click "Validate Ticket"
   - You should see a valid ticket dialog
3. Test QR scanning:
   - Generate a QR code containing `TKT-2024-002`
   - Scan it with the camera
   - Validation dialog should appear

#### Dashboard Tab:
1. Go to Dashboard tab (bottom navigation)
2. You should see:
   - Payment summaries (Today, Week, Month)
   - Visitor counts
   - Pie chart showing visitors by facility
   - Bar chart showing payments by facility
3. Pull down to refresh data

### 5. Common Issues & Solutions

#### Issue: "Building with plugins requires symlink support"
**Solution**: Enable Developer Mode in Windows Settings (see step 3.1 above)

#### Issue: Camera not working
**Solution**: 
- Make sure you granted camera permissions
- For Android: Check AndroidManifest.xml has camera permission (already added)
- For physical device: Ensure camera is not being used by another app

#### Issue: "No tickets found"
**Solution**: 
- Verify the tickets table exists in Supabase
- Check that sample data was inserted correctly
- Verify Supabase credentials in `lib/config/supabase_config.dart`

#### Issue: Charts not showing data
**Solution**:
- Make sure tickets have `visit_date` set
- Check that tickets have `facility` and `amount` values
- Pull down to refresh the dashboard

### 6. Generating QR Codes for Testing

You can use online QR code generators:
- https://www.qr-code-generator.com/
- https://www.the-qrcode-generator.com/

Generate QR codes with these values:
- `TKT-2024-001`
- `TKT-2024-002`
- `TKT-2024-003`

### 7. Database Schema Reference

**tickets table columns:**
- `id` (UUID): Primary key, auto-generated
- `reference_number` (TEXT): Unique ticket reference (e.g., "TKT-2024-001")
- `facility` (TEXT): Name of facility (e.g., "Swimming Pool", "Gymnasium")
- `amount` (DECIMAL): Payment amount in pesos
- `visit_date` (TIMESTAMP): Date and time of visit
- `is_valid` (BOOLEAN): Whether ticket is still valid (true) or used (false)
- `created_at` (TIMESTAMP): When ticket was created

### 8. Next Steps

After setup, you can:
1. Customize the UI colors in `lib/main.dart`
2. Add more facilities to your database
3. Modify the dashboard charts in `lib/screens/dashboard_screen.dart`
4. Add authentication if needed
5. Deploy to Google Play Store or App Store

### 9. Building for Production

**Android APK:**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Support

For issues or questions:
1. Check the Flutter documentation: https://docs.flutter.dev/
2. Check Supabase documentation: https://supabase.com/docs
3. Review the code comments in the project files
