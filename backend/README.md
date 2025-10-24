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
- **POST** `/api/auth/signup`
- Body (form-data):
  - `email`: string
  - `password`: string
  - `full_name`: string
  - `user_type`: "Donor" or "Receiver"
  - `id_proof`: file (optional)

#### Login
- **POST** `/api/auth/login`
- Body (JSON):
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
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

## Database Schema

### Users Collection
```javascript
{
  _id: ObjectId,
  email: String (unique),
  password: String (hashed),
  full_name: String,
  user_type: String ("Donor" | "Receiver"),
  id_proof_path: String (optional),
  created_at: DateTime,
  updated_at: DateTime,
  is_active: Boolean
}
```

## Testing the API

### Using curl:

```bash
# Sign up
curl -X POST http://localhost:5000/api/auth/signup \
  -F "email=test@example.com" \
  -F "password=password123" \
  -F "full_name=Test User" \
  -F "user_type=Donor"

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```
