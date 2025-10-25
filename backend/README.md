# CrumbChain Backend API

Flask-based REST API for CrumbChain food donation app with MongoDB integration.

## Setup Instructions

### 1. Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment Variables

1. Copy `.env.example` to `.env`:
```bash
copy .env.example .env
```

2. Edit `.env` file with your MongoDB credentials:
   - For local MongoDB: `mongodb://localhost:27017/`
   - For MongoDB Atlas: `mongodb+srv://username:password@cluster.mongodb.net/`

### 3. Run the Server

```bash
python app.py
```

The API will run on `http://localhost:5000`

## API Endpoints

### Health Check
- **GET** `/api/health`
- Returns server status

### Authentication

#### Sign Up
- **POST** `/api/auth/register`
- Body (JSON):
  ```json
  {
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe",
    "userType": "donor"
  }
  ```

#### Login
- **POST** `/api/auth/login`
- Body (JSON):
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```

#### Google Sign-In
- **POST** `/api/auth/google-signin`
- Body (JSON):
  ```json
  {
    "email": "user@example.com",
    "displayName": "John Doe",
    "userType": "donor"
  }
  ```

### User Profile

#### Get Profile
- **GET** `/api/user/profile`
- Headers: `Authorization: Bearer <token>`

#### Update Profile
- **PUT** `/api/user/profile`
- Headers: `Authorization: Bearer <token>`
- Body (JSON):
  ```json
  {
    "full_name": "Updated Name"
  }
  ```

### Food Listings (NEW)

#### Create Listing
- **POST** `/api/listings`
- Headers: `Authorization: Bearer <token>`
- Body (JSON):
  ```json
  {
    "foodType": "Biryani",
    "description": "Delicious chicken biryani",
    "quantity": "Serves 20 people",
    "datePrepared": "2025-10-25",
    "dietaryTag": "Non-Veg",
    "temperatureStatus": "Hot/Freshly cooked",
    "location": "123 Main St, Mumbai",
    "pickupTime": "18:30",
    "packagingType": "Bulk container",
    "isPaidDonation": false,
    "amount": 0,
    "imageUrl": ""
  }
  ```

#### Get All Listings
- **GET** `/api/listings`
- Headers: `Authorization: Bearer <token>`
- Query Parameters:
  - `userOnly=true` - Get only current user's listings
  - `status=active` - Filter by status (active, claimed, completed, cancelled)

#### Get Single Listing
- **GET** `/api/listings/:listingId`
- Headers: `Authorization: Bearer <token>`

#### Update Listing
- **PUT** `/api/listings/:listingId`
- Headers: `Authorization: Bearer <token>`
- Body (JSON): Include only fields to update
  ```json
  {
    "status": "completed",
    "quantity": "Serves 15 people"
  }
  ```

#### Delete Listing
- **DELETE** `/api/listings/:listingId`
- Headers: `Authorization: Bearer <token>`

## Database Schema

### Users Collection
```javascript
{
  _id: ObjectId,
  email: String (unique),
  password: String (hashed),
  name: String,
  userType: String ("donor" | "receiver"),
  created_at: DateTime,
  updated_at: DateTime,
  is_active: Boolean,
  auth_provider: String (optional, "google")
}
```

### Listings Collection (NEW)
```javascript
{
  _id: ObjectId,
  userId: String,              // Reference to user
  userEmail: String,
  userName: String,
  foodType: String,
  description: String,
  quantity: String,
  datePrepared: String,        // YYYY-MM-DD
  dietaryTag: String,          // "Veg", "Non-Veg", "Jain", "Halal"
  temperatureStatus: String,
  location: String,
  pickupTime: String,          // HH:MM
  packagingType: String,
  isPaidDonation: Boolean,
  amount: Number,
  imageUrl: String,
  status: String,              // "active", "claimed", "completed", "cancelled"
  createdAt: DateTime,
  updatedAt: DateTime
}
```

## Testing the API

### Test MongoDB Connection
```bash
# Run the test script to verify MongoDB setup
python test_listings.py
```

### Using curl:

```bash
# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"test@example.com",
    "password":"password123",
    "name":"Test User",
    "userType":"donor"
  }'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Create Listing (replace YOUR_TOKEN with actual token from login)
curl -X POST http://localhost:5000/api/listings \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "foodType": "Pizza",
    "quantity": "10 servings",
    "dietaryTag": "Veg",
    "temperatureStatus": "Hot/Freshly cooked",
    "location": "Mumbai",
    "packagingType": "Individual boxes"
  }'

# Get All Listings
curl http://localhost:5000/api/listings \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Additional Documentation

For detailed MongoDB setup and configuration, see [MONGODB_SETUP.md](MONGODB_SETUP.md)
