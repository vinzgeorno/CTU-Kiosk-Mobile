# CTU Kiosk Mobile - Deployment Checklist

## ✅ Pre-Deployment Checklist

### Database Setup
- [ ] Create `tickets` table in Supabase
- [ ] Run the SQL schema from README.md
- [ ] Create indexes on `reference_number` and `visit_date`
- [ ] Insert sample data for testing (optional)
- [ ] Configure Row Level Security policies (optional)
- [ ] Test database connection from Supabase dashboard

### App Configuration
- [ ] Verify Supabase credentials in `lib/config/supabase_config.dart`
- [ ] Test connection to Supabase from app
- [ ] Verify all dependencies are installed (`flutter pub get`)
- [ ] Run `flutter analyze` (should show no issues)
- [ ] Test on development device/emulator

### Testing
- [ ] **Scanner Tab**
  - [ ] QR code scanning works
  - [ ] Manual reference input works
  - [ ] Valid tickets show correct information
  - [ ] Invalid tickets show error message
  - [ ] "Mark as Used" button updates database
  - [ ] Camera permissions are requested
  
- [ ] **Dashboard Tab**
  - [ ] Payment cards display correct totals
  - [ ] Visitor cards display correct counts
  - [ ] Pie chart renders with facility data
  - [ ] Bar chart renders with payment data
  - [ ] Pull-to-refresh updates data
  - [ ] Empty state handled gracefully

- [ ] **Navigation**
  - [ ] Bottom navigation switches between tabs
  - [ ] App doesn't crash on tab switching
  - [ ] State is maintained when switching tabs

### Performance
- [ ] App loads in under 3 seconds
- [ ] Database queries complete in under 1 second
- [ ] Charts render smoothly without lag
- [ ] No memory leaks during extended use
- [ ] Camera releases properly when leaving scanner

### UI/UX
- [ ] All text is readable and properly sized
- [ ] Colors are consistent with design
- [ ] Buttons have proper touch targets (min 44x44)
- [ ] Loading indicators show during async operations
- [ ] Error messages are user-friendly
- [ ] Success feedback is clear

## 📱 Android Deployment

### Pre-Build
- [ ] Update `android/app/build.gradle` with proper app ID
- [ ] Set proper `applicationId` (e.g., com.ctu.kiosk.admin)
- [ ] Update version code and version name
- [ ] Configure app icon in `android/app/src/main/res/mipmap-*/`
- [ ] Update app name in `android/app/src/main/AndroidManifest.xml`
- [ ] Verify camera and internet permissions are in manifest

### Build Release APK
```bash
flutter build apk --release
```
- [ ] APK builds successfully
- [ ] APK size is reasonable (<50MB)
- [ ] Test APK on physical device
- [ ] Verify all features work in release mode

### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
- [ ] App bundle builds successfully
- [ ] Bundle size is reasonable

### Play Store Preparation (if publishing)
- [ ] Create signing key
- [ ] Configure signing in `android/app/build.gradle`
- [ ] Prepare store listing (title, description, screenshots)
- [ ] Create privacy policy
- [ ] Prepare promotional graphics

## 🍎 iOS Deployment (if applicable)

### Pre-Build
- [ ] Configure bundle identifier in Xcode
- [ ] Set up signing certificates
- [ ] Update version and build number
- [ ] Configure app icon
- [ ] Add camera usage description in Info.plist

### Build
```bash
flutter build ios --release
```
- [ ] Build completes successfully
- [ ] Test on physical iOS device
- [ ] Verify all features work

## 🌐 Web Deployment (if applicable)

### Build
```bash
flutter build web --release
```
- [ ] Build completes successfully
- [ ] Test in multiple browsers (Chrome, Firefox, Safari)
- [ ] Camera access works in web browsers
- [ ] Deploy to hosting service (Firebase, Netlify, etc.)

## 🔒 Security Checklist

- [ ] API keys are not hardcoded in public repositories
- [ ] Row Level Security is enabled in Supabase (for production)
- [ ] HTTPS is enforced for all API calls
- [ ] No sensitive data in error messages
- [ ] Camera permissions are properly requested
- [ ] Database queries use parameterized inputs

## 📊 Post-Deployment

### Monitoring
- [ ] Set up error tracking (e.g., Sentry, Firebase Crashlytics)
- [ ] Monitor database usage in Supabase dashboard
- [ ] Track app performance metrics
- [ ] Monitor API rate limits

### User Training
- [ ] Create user manual/guide
- [ ] Train administrators on how to use the app
- [ ] Provide troubleshooting guide
- [ ] Set up support channel

### Maintenance
- [ ] Schedule regular database backups
- [ ] Plan for app updates
- [ ] Monitor user feedback
- [ ] Keep dependencies up to date

## 🐛 Known Issues to Address

- [ ] Enable Developer Mode on Windows (documented in SETUP_GUIDE.md)
- [ ] Camera permissions must be granted manually on first use
- [ ] No offline mode (requires internet connection)
- [ ] No authentication system (uses anon key)

## 📝 Documentation

- [ ] README.md is complete and accurate
- [ ] SETUP_GUIDE.md has clear instructions
- [ ] ARCHITECTURE.md explains technical details
- [ ] PROJECT_SUMMARY.md provides overview
- [ ] Code comments are clear and helpful

## 🎯 Success Criteria

The app is ready for deployment when:
- ✅ All tests pass
- ✅ No analyzer warnings or errors
- ✅ Performance is acceptable
- ✅ UI/UX is polished
- ✅ Database is properly configured
- ✅ Documentation is complete
- ✅ Security measures are in place

## 📞 Emergency Contacts

**Database Issues:**
- Supabase Dashboard: https://nzcprxadltjbhuohwbix.supabase.co
- Supabase Support: https://supabase.com/support

**Flutter Issues:**
- Flutter Docs: https://docs.flutter.dev/
- Flutter Community: https://flutter.dev/community

**App Issues:**
- Check logs: `flutter logs`
- Debug mode: `flutter run --debug`
- Verbose output: `flutter run --verbose`

---

**Deployment Date:** _________________
**Deployed By:** _________________
**Version:** 1.0.0
**Status:** ⬜ Ready ⬜ In Progress ⬜ Completed
