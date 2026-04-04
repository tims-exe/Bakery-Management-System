# Backing Up App & Setting Up New Financial Year

A step-by-step guide to backing up the current app and resetting the original app for a new financial year.

---

## Part 1 — Create the Backup App

### 1. Update Application ID
In `android/app/build.gradle.kts`, update the `applicationId`:
```kotlin
defaultConfig {
    applicationId = "com.example.nissy_bakes_XXXX"
}
```

Replace all other occurrences of `nissy_bakes_original` with `nissy_bakes_XXXX` across the project.

---

### 2. Rename the App Label
In `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="Nissy Bakes XXXX"
```

---

### 3. Update the Database
- Replace the DB with the latest version in assets
- Delete the existing DB using the dbhelper

---

### 4. Update Backup Folder Reference
Rename the backup folder reference throughout the project:
```
NissyBakesBackup  →  NissyBakesBackupXXXX
```

---

### 5. Build & Run
```bash
flutter clean
flutter pub get
# Run via F5 (VS Code) or your IDE's run command
```

---

### 6. Test the Backup App
- Test backup functionality
- Test insert operations

---

### 7. Update the Logo
1. Replace the logo file with the new logo
2. Update `pubspec.yaml` if the logo filename has changed
3. Replace all references to the old logo filename with the new one (global find & replace)
4. Regenerate launcher icons:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

---

### 8. Final Run of Backup App
```bash
flutter clean
flutter pub get
# Run via F5
```

---

## Part 2 — Reset the Original App for New Financial Year

### 9. Clear Order Data
Run the following SQL on the original app's database:
```sql
DELETE FROM order_details;
DELETE FROM order_header;
```

---

### 10. Update Financial Year
- Update the `settings` table with the new financial year
- Update `.env` with the new financial year

---

### 11. Test the Original App
- Run the app
- Insert a new order and verify the value is saved correctly in the DB
- Test the database backup feature

---

### 12. Build the Original App APK
```bash
flutter build apk
```
















<!-- replace all nissy_bakes_original with nissy_bakes_XXXX
especially in android/app/build.gradle.kts 
defaultConfig {
    applicationId = "com.example.nissy_bakes_XXXX"
}


rename app in
android/app/src/main/AndroidManifest.xml
android:label="Nissy Bakes XXXX"


replace db with the latest version
delete existing db

replace backup folder
NissyBakesBackup -> NissyBakesBackupXXXX


flutter clean
flutter pub get
f5

test backup
test insert 


UPDATE LOGO

replace logo with new logo
update pubspec.yaml if needed with the new logo name
update all instances of the old logo with new logo (replace globally)
run
flutter pub get
flutter pub run flutter_launcher_icons


rerun app
flutter clean
flutter pub get
f5



updating the original app

clear order details and header
DELETE FROM order_details;
DELETE FROM order_header;

update settings table with new financial year
update env with new financial year

flutter build apk -->