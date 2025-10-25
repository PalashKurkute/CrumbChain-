# Quick Setup Guide - Map Feature

## Prerequisites
- Backend server running on port 5000
- MongoDB running and accessible
- Flutter development environment set up
- Physical device or emulator with location services

## Step-by-Step Setup

### 1. Install Backend Dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 2. Start Backend Server
```bash
cd backend
python app.py
```

You should see:
```
✅ Connected to MongoDB: crumbchain
 * Running on http://0.0.0.0:5000
```

### 3. Install Flutter Dependencies
```bash
flutter pub get
```

### 4. Update Android Permissions
The permissions are already added if you're using the existing project. Verify in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 5. Create Test Data (Optional)

First, create a donor account in the app, then:

1. Edit `backend/create_test_listings.py`:
   ```python
   DONOR_EMAIL = "your-donor-email@test.com"
   DONOR_PASSWORD = "your-password"
   ```

2. Run the script:
   ```bash
   cd backend
   python create_test_listings.py
   ```

### 6. Run the App
```bash
flutter run
```

### 7. Test the Feature

1. **Login as Receiver**
   - Use an existing receiver account or create a new one
   - Select "Receiver" as user type during signup

2. **Navigate to Map**
   - On the receiver home page
   - Tap the "Explore Listings" card
   - Grant location permission if prompted

3. **Interact with Map**
   - View markers for available listings
   - Tap markers to see listing details
   - Use the "My Location" button to center on your location
   - Use "Refresh" to reload listings

## Common Issues and Solutions

### Issue: "Connection error" when loading listings
**Solution**: 
- Ensure backend is running
- Check API URL in `lib/config/api_config.dart`
- For physical device, update `localIp` to your computer's IP
- For emulator, set `_useEmulator = true`

### Issue: No markers appearing on map
**Solution**:
- Run the test script to create sample listings
- Ensure listings have status "active"
- Check backend console for any errors
- Verify MongoDB connection

### Issue: Location permission not working
**Solution**:
- Go to device Settings → Apps → CrumbChain → Permissions
- Enable Location permission
- Restart the app

### Issue: Map tiles not loading
**Solution**:
- Check internet connection
- OpenStreetMap servers might be slow - wait a moment
- Try refreshing the map

### Issue: Geocoding fails for some addresses
**Solution**:
- Use complete addresses with city, state, and country
- Example: "Andheri West, Mumbai, Maharashtra, India"
- Avoid abbreviations or incomplete addresses

## Quick Test Checklist

- [ ] Backend server running
- [ ] MongoDB connected
- [ ] Test listings created
- [ ] App running on device/emulator
- [ ] Logged in as receiver
- [ ] Can navigate to map page
- [ ] Map loads with tiles
- [ ] Markers visible on map
- [ ] Can tap markers to see details
- [ ] Location permission granted (optional)
- [ ] Current location marker visible (if permission granted)

## File Locations

| Component | File Path |
|-----------|-----------|
| Map Page | `lib/pages/listings_map_page.dart` |
| Listing Model | `lib/models/listing.dart` |
| API Service | `lib/services/listing_service.dart` |
| Backend API | `backend/app.py` |
| Test Script | `backend/create_test_listings.py` |
| API Config | `lib/config/api_config.dart` |

## Next Steps

After basic setup:
1. Customize map appearance
2. Add more test listings
3. Implement claim functionality
4. Add filtering options
5. Integrate navigation

## Need Help?

Check the detailed documentation in `MAP_FEATURE_README.md`
