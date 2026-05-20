# Diagnostic Questions - Dashboard Not Updating

## Critical Information Needed

Please answer these questions to help diagnose the issue:

### 1. Platform & Testing
- [ ] Are you testing on **Mobile** (Android/iOS) or **Web**?
- [ ] If Mobile, which device/emulator?
- [ ] If Web, which browser?

### 2. Console Logs
- [ ] Can you see the debug logs in the console?
- [ ] Do you see "✅ QR CHECK-IN SUCCESSFUL"?
- [ ] Do you see "🔄 USER CLICKED OK - STARTING REFRESH FLOW"?
- [ ] Do you see all 5 steps completing?
- [ ] Do you see "🔍 FIRESTORE: getTodayActiveAttendance()"?
- [ ] Do you see "✅ Found active attendance"?

### 3. Actual Behavior
- [ ] Does the success popup appear after scanning QR?
- [ ] When you click "OK", does it navigate back to dashboard?
- [ ] Does the dashboard show "Not Checked In" or does it show loading?
- [ ] If you manually pull-to-refresh on the dashboard, does it update?
- [ ] If you close the app completely and reopen, does it show "Checked In"?

### 4. Firestore Check
- [ ] Can you check Firebase Console → Firestore?
- [ ] Navigate to: `users/{employeeUID}/attendance/`
- [ ] Is there a new attendance record created?
- [ ] What is the `status` field value? (`checked_in` or `pending`?)
- [ ] What is the `checkInTime` value?
- [ ] Does the date match today's date?

### 5. QR Code Check
- [ ] When you edit the project in web admin, does it show the QR code?
- [ ] Copy the QR code text - does it start with "PROJECT:" and contain the correct project ID?
- [ ] Does the project ID in the QR match the project ID in Firestore?

### 6. Error Messages
- [ ] Are there any error messages in the console (red text)?
- [ ] Are there any "❌" markers in the logs?
- [ ] Does it say "No active attendance found"?

## Quick Test Steps

### Test A: Verify Check-In Actually Saves
1. Before scanning QR, open Firebase Console
2. Navigate to `users/{your employee UID}/attendance/`
3. Note the number of attendance records
4. Do QR check-in
5. Refresh Firebase Console
6. **Did a new record appear?**
   - ✅ YES → Issue is with dashboard refresh
   - ❌ NO → Issue is with check-in save

### Test B: Verify Dashboard Query
1. After check-in, check console logs
2. Look for: "🔍 FIRESTORE: getTodayActiveAttendance()"
3. Check the date range in the logs
4. Look for: "📊 Query returned X documents from SERVER"
5. **What is the X value?**
   - X = 0 → Query not finding the record
   - X = 1 → Record found, but dashboard not updating
   - No log → Query not executing

### Test C: Verify Dashboard Lifecycle
1. After check-in and clicking OK
2. Look for: "🏠 EMPLOYEE DASHBOARD - initState()"
3. Look for: "🔄 EMPLOYEE DASHBOARD - didChangeDependencies()"
4. **Do these appear in console?**
   - ✅ YES → Lifecycle executing
   - ❌ NO → Navigation might be failing

### Test D: Manual Verification
1. After check-in, on dashboard screen
2. Pull down to manually refresh (swipe down gesture)
3. **Does it update to "Checked In"?**
   - ✅ YES → Auto-refresh is the issue
   - ❌ NO → Query or data issue

## Common Issues & Solutions

### Issue 1: Testing on Web Instead of Mobile
**Symptom**: QR scanner doesn't work properly
**Solution**: The mobile_scanner package only works on actual mobile devices. Test on Android/iOS emulator or real device.

### Issue 2: Old App Version Running
**Symptom**: No debug logs appear
**Solution**: 
```bash
cd /Users/mac/Documents/straights_psyroll
flutter clean
flutter pub get
flutter run
```

### Issue 3: Firestore Rules Blocking Read
**Symptom**: Query returns 0 documents but record exists in Firestore
**Solution**: Check Firestore security rules allow employee to read their own attendance:
```javascript
match /users/{userId}/attendance/{attendanceId} {
  allow read: if request.auth.uid == userId;
}
```

### Issue 4: Date/Time Mismatch
**Symptom**: Query returns 0 documents
**Solution**: Device clock might be wrong. Check:
- Device date/time settings
- Timezone settings
- Compare checkInTime in Firestore with query date range in logs

### Issue 5: Provider Not Rebuilding
**Symptom**: Data is fetched but UI doesn't update
**Solution**: The widget might not be watching the provider. Verify:
```dart
final todayAttendance = ref.watch(todayActiveAttendanceProvider);
// NOT: ref.read()
```

## Next Steps

1. **Answer the questions above**
2. **Run Tests A, B, C, and D**
3. **Copy and paste the console logs** from:
   - After clicking "Check-In"
   - After scanning QR code
   - After clicking "OK" on success dialog
   - The first 20 seconds after returning to dashboard

4. **Take screenshots** of:
   - The success popup
   - The dashboard showing "Not Checked In"
   - Firebase Console showing the attendance record
   - The console logs

This information will help pinpoint the exact issue.
