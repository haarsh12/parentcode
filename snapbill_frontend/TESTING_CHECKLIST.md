# SnapBill Testing Checklist

## ✅ Pre-Testing Setup
- [ ] Run `flutter pub get`
- [ ] Connect Android device or start emulator
- [ ] Pair Bluetooth thermal printer
- [ ] Run `flutter run`

---

## 🔴 CRITICAL ISSUE 1: Voice Page Printing

### Test Steps:
1. [ ] Open Voice Page
2. [ ] Tap microphone
3. [ ] Say "Chawal 1 kg" (or any item)
4. [ ] Verify item appears in live bill with:
   - [ ] Item name visible
   - [ ] Quantity visible (1kg)
   - [ ] Rate visible (₹XX)
   - [ ] Total visible (₹XX)
5. [ ] Add 2-3 more items
6. [ ] Connect printer
7. [ ] Press PRINT button
8. [ ] Check printed bill shows:
   - [ ] Shop name and phone
   - [ ] Bill number (sequential)
   - [ ] ALL item names
   - [ ] ALL quantities
   - [ ] ALL rates (without Rs)
   - [ ] ALL prices (with Rs)
   - [ ] Total amount

### Expected Result:
✅ Full bill prints with all items and details

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 🔴 CRITICAL ISSUE 2: QR Code Persistence

### Test Steps:
1. [ ] Go to Profile screen
2. [ ] Tap "Upload QR Code"
3. [ ] Select image from gallery
4. [ ] Verify QR appears in preview
5. [ ] Switch to Voice page
6. [ ] Switch to Frequent page
7. [ ] Switch back to Profile
8. [ ] Verify QR still visible
9. [ ] Close app completely (swipe from recent apps)
10. [ ] Reopen app
11. [ ] Go to Profile
12. [ ] Verify QR still visible

### Expected Result:
✅ QR persists across screens and app restarts

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 🔴 CRITICAL ISSUE 2B: QR Code Printing

### Test Steps:
1. [ ] Ensure QR is uploaded (from test above)
2. [ ] Go to Voice or Frequent page
3. [ ] Add items to bill
4. [ ] Print bill
5. [ ] Check printed bill shows:
   - [ ] QR code image at bottom
   - [ ] "Scan to Pay" text below QR
   - [ ] Proper alignment

### Test Without QR:
1. [ ] Go to Profile
2. [ ] Remove QR (if there's a delete option, or clear app data)
3. [ ] Print a bill
4. [ ] Verify no blank space where QR would be

### Expected Result:
✅ QR prints when saved, no blank space when not saved

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 🔴 CRITICAL ISSUE 3: Live Bill Reset

### Test Steps - Voice Page:
1. [ ] Go to Voice page
2. [ ] Add 3 items via voice
3. [ ] Verify items visible in live bill
4. [ ] Switch to Frequent page
5. [ ] Switch back to Voice page
6. [ ] Verify all 3 items still there
7. [ ] Switch to Profile page
8. [ ] Switch back to Voice page
9. [ ] Verify all 3 items still there
10. [ ] Minimize app (home button)
11. [ ] Reopen app
12. [ ] Go to Voice page
13. [ ] Verify all 3 items still there

### Test Steps - Frequent Page:
1. [ ] Go to Frequent page
2. [ ] Tap 3 items to add to bill
3. [ ] Verify items visible in live bill
4. [ ] Switch to Voice page
5. [ ] Switch back to Frequent page
6. [ ] Verify all 3 items still there

### Test Steps - Clear Bill:
1. [ ] Add items to bill
2. [ ] Press "Cancel Bill" button
3. [ ] Verify bill is empty
4. [ ] Add items again
5. [ ] Print bill
6. [ ] Verify bill clears after printing

### Expected Result:
✅ Bill persists across screens
✅ Bill only clears on Cancel or after Print

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 🔴 CRITICAL ISSUE 4: Sequential Bill Numbering

### Test Steps:
1. [ ] Print first bill
2. [ ] Note bill number (should be 1 or next in sequence)
3. [ ] Print second bill
4. [ ] Verify number is previous + 1
5. [ ] Print third bill
6. [ ] Verify number is previous + 1
7. [ ] Close app completely
8. [ ] Reopen app
9. [ ] Print another bill
10. [ ] Verify number continues sequence (not reset)

### Expected Result:
✅ Bill numbers: 1, 2, 3, 4... (sequential)
✅ Numbers persist across app restarts

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 🔴 CRITICAL ISSUE 5: Printed Bill Font

### Test Steps:
1. [ ] Print a bill
2. [ ] Examine printed output
3. [ ] Check font weight:
   - [ ] Shop name is BOLD
   - [ ] Total amount is BOLD
   - [ ] Table headers are NORMAL (not bold)
   - [ ] Item names are NORMAL
   - [ ] Quantities are NORMAL
   - [ ] Rates are NORMAL
   - [ ] Prices are NORMAL
4. [ ] Overall appearance is clean and professional

### Expected Result:
✅ Only shop name and total are bold
✅ Professional, readable appearance

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 🔴 CRITICAL ISSUE 6: Quantity Display Logic

### Test Steps - Less than 1kg:
1. [ ] Add item with 0.4kg
2. [ ] Check live bill shows: 400gm (not 0.4kg)
3. [ ] Print bill
4. [ ] Check printed bill shows: 400gm

### Test Steps - More than 1kg with decimal:
1. [ ] Add item with 1.2kg
2. [ ] Check live bill shows: 1200gm (not 1.2kg)
3. [ ] Print bill
4. [ ] Check printed bill shows: 1200gm

### Test Steps - Exact kg:
1. [ ] Add item with 2kg
2. [ ] Check live bill shows: 2kg
3. [ ] Print bill
4. [ ] Check printed bill shows: 2kg

### Test Steps - Large grams:
1. [ ] Add item with 2000gm
2. [ ] Check live bill shows: 2kg (not 2000gm)
3. [ ] Print bill
4. [ ] Check printed bill shows: 2kg

### Expected Result:
✅ Smart conversion applied consistently
✅ No confusing decimals

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 🔴 CRITICAL ISSUE 7: Bill Layout & Structure

### Test Steps:
1. [ ] Print a bill with multiple items
2. [ ] Check printed format:
   - [ ] 4 columns visible: Item | Qty | Rate | Price
   - [ ] Columns properly aligned
   - [ ] No decimal .0 anywhere
   - [ ] Rate column has NO "Rs" (e.g., 50/kg)
   - [ ] Price column has "Rs" (e.g., Rs50)
   - [ ] Short units used (doz, plt, pic, lit)
   - [ ] Proper spacing between rows
   - [ ] Professional appearance

### Check Live Bill UI:
1. [ ] Add items to live bill
2. [ ] Verify same formatting rules apply
3. [ ] Check no .0 decimals
4. [ ] Check short unit names

### Expected Result:
✅ Clean 4-column layout
✅ Consistent formatting
✅ Professional appearance

### Current Status:
- [ ] PASS
- [ ] FAIL (describe issue): _______________

---

## 📱 Additional Tests

### Second Phone Number:
1. [ ] Go to Profile
2. [ ] Add second phone number
3. [ ] Save profile
4. [ ] Print a bill
5. [ ] Verify both phone numbers print

### Short Unit Names:
1. [ ] Add item with "dozen" unit
2. [ ] Verify shows as "doz"
3. [ ] Add item with "plate" unit
4. [ ] Verify shows as "plt"
5. [ ] Add item with "pieces" unit
6. [ ] Verify shows as "pic"
7. [ ] Add item with "litre" unit
8. [ ] Verify shows as "lit"

---

## 🎯 Final Verification

### All Issues Resolved:
- [ ] Issue 1: Voice page prints items ✅
- [ ] Issue 2: QR persists ✅
- [ ] Issue 2B: QR prints ✅
- [ ] Issue 3: Bill doesn't reset ✅
- [ ] Issue 4: Sequential numbers ✅
- [ ] Issue 5: Clean font ✅
- [ ] Issue 6: Smart quantity ✅
- [ ] Issue 7: Professional layout ✅

### Overall Assessment:
- [ ] ALL TESTS PASSED
- [ ] SOME TESTS FAILED (list below)

### Failed Tests:
1. _______________
2. _______________
3. _______________

### Notes:
_______________________________________________
_______________________________________________
_______________________________________________
