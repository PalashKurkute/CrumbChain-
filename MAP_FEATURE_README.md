# Map Feature for CrumbChain Receivers

This document describes the new map feature that allows receivers to view all available food donation listings on an interactive map.

## Features

### 1. **Interactive Map View**
- Displays all active food listings on an OpenStreetMap
- Custom markers for food donation locations
- Tap markers to view listing details
- Current location indicator (blue marker)
- Smooth map navigation and zoom controls

### 2. **Listing Details**
Each listing shows:
- Food type and description
- Donor name
- Quantity available
- Dietary tags (Vegetarian, Non-Vegetarian, Vegan)
- Temperature status (Hot, Cold, Room Temperature)
- Packaging type
- Location address
- Pickup time
- Prepared date
- Payment information (if applicable)

### 3. **Map Controls**
- **My Location Button**: Quickly center map on your current location
- **Refresh Button**: Reload listings from the server
- **Listings Counter**: Shows number of available listings
- **Zoom/Pan**: Standard map navigation gestures

### 4. **Listing Actions**
From the details sheet, receivers can:
- **Claim Food**: Reserve a listing (coming soon)
- **Get Directions**: Navigate to the pickup location (coming soon)

## File Structure

```
lib/
├── models/
│   └── listing.dart              # Listing data model
├── pages/
│   ├── listings_map_page.dart    # Main map page
│   └── receiver_home_page.dart   # Updated with map navigation
└── services/
    └── listing_service.dart      # API service for listings

backend/
├── app.py                         # Updated with coordinate support
└── create_test_listings.py       # Script to create test data
```

## Setup Instructions

### 1. Flutter Dependencies
The required packages are already in `pubspec.yaml`:
```yaml
dependencies:
  flutter_map: ^7.0.2      # Map widget
  latlong2: ^0.9.0         # Coordinate handling
  geolocator: ^13.0.1      # Location services
  geocoding: ^3.0.0        # Address to coordinates
  http: ^1.1.0             # API calls
```

### 2. Permissions

#### Android (android/app/src/main/AndroidManifest.xml)
Add these permissions:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

#### iOS (ios/Runner/Info.plist)
Add these keys:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to show nearby food donations</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to your location to show nearby food donations</string>
```

### 3. Backend Setup
The backend now supports storing coordinates with listings. When creating a listing, you can optionally include:
```json
{
  "latitude": 19.0760,
  "longitude": 72.8777,
  ... other fields
}
```

### 4. Testing with Sample Data

#### Step 1: Start the backend
```bash
cd backend
python app.py
```

#### Step 2: Create a donor account (if you don't have one)
Use the app or any API client to register a donor account.

#### Step 3: Update test script credentials
Edit `backend/create_test_listings.py` and update:
```python
DONOR_EMAIL = "your-donor-email@example.com"
DONOR_PASSWORD = "your-password"
```

#### Step 4: Run the test script
```bash
cd backend
python create_test_listings.py
```

This will create 6 sample listings at various locations in Mumbai.

## Usage

### For Receivers:
1. Open the CrumbChain app as a Receiver
2. On the home page, tap **"Explore Listings"**
3. The map will load showing all available listings
4. Grant location permission when prompted (optional)
5. Tap any marker to view listing details
6. Use the **My Location** button to center the map on your location
7. Use **Refresh** to reload the latest listings

### For Donors:
When creating a listing:
- The app will automatically geocode the entered location address
- Coordinates are cached to improve map loading performance
- Accurate addresses result in better marker placement

## How It Works

### Geocoding Process:
1. Listings are fetched from MongoDB (active status only)
2. For each listing:
   - If coordinates are stored in the database, use them directly
   - Otherwise, geocode the location address string
   - Create a map marker at the coordinates
3. Display all markers on the map

### Performance Optimizations:
- Coordinates are stored in the database to avoid repeated geocoding
- Only active listings are fetched
- Map uses efficient tile loading from OpenStreetMap
- Markers are rendered in a single layer

## Data Model

### Listing Model
```dart
class Listing {
  final String id;
  final String userId;
  final String foodType;
  final String quantity;
  final String location;
  final double? latitude;   // Optional coordinates
  final double? longitude;  // Optional coordinates
  final String status;      // active, claimed, completed, cancelled
  // ... other fields
}
```

### MongoDB Document
```json
{
  "_id": "...",
  "userId": "...",
  "foodType": "Fresh Vegetable Curry",
  "quantity": "10 servings",
  "location": "Andheri West, Mumbai, Maharashtra, India",
  "latitude": 19.1136,
  "longitude": 72.8697,
  "status": "active",
  "createdAt": "2025-10-25T...",
  ...
}
```

## Troubleshooting

### Map not loading
- Check internet connection
- Verify that the backend is running
- Check console for error messages

### Markers not appearing
- Ensure listings exist in the database
- Run the test script to create sample listings
- Check that listings have status "active"
- Verify location addresses are valid

### Location permission denied
- The map will still work, but won't show your current location
- You can manually navigate the map
- Re-enable permission in device settings if needed

### Geocoding errors
- Some addresses may fail to geocode
- Those listings won't appear on the map
- Donors should provide complete addresses with city and country

## Future Enhancements

1. **Claim Functionality**: Allow receivers to claim listings from the map
2. **Navigation Integration**: Open Google Maps/Apple Maps for directions
3. **Filters**: Filter by dietary tags, distance, food type
4. **Search**: Search for specific locations or food types
5. **Clustering**: Group nearby markers when zoomed out
6. **Real-time Updates**: WebSocket integration for live listing updates
7. **Distance Calculation**: Show distance from user to each listing
8. **Route Optimization**: Multi-stop route planning for multiple pickups

## API Endpoints Used

### Get All Active Listings
```
GET /api/listings?status=active
Authorization: Bearer <token>
```

### Response Format
```json
{
  "success": true,
  "data": {
    "listings": [
      {
        "_id": "...",
        "foodType": "...",
        "location": "...",
        "latitude": 19.1136,
        "longitude": 72.8697,
        ...
      }
    ],
    "count": 6
  }
}
```

## Credits

- **Maps**: OpenStreetMap contributors
- **Flutter Map**: flutter_map package
- **Geocoding**: geocoding package
- **Location**: geolocator package

## License

Part of the CrumbChain project.
