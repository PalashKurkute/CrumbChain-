"""
Script to create test listings with various locations for map testing
Run this after starting the backend server
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:5000/api"

# Test credentials - You'll need to create a donor account first or use existing credentials
DONOR_EMAIL = "donor@test.com"
DONOR_PASSWORD = "password123"

# Sample listings with real locations in Mumbai/India
SAMPLE_LISTINGS = [
    {
        "foodType": "Fresh Vegetable Curry",
        "description": "Homemade vegetable curry with rice, enough for 10 people",
        "quantity": "10 servings",
        "dietaryTag": "Vegetarian",
        "temperatureStatus": "Hot",
        "location": "Andheri West, Mumbai, Maharashtra, India",
        "pickupTime": "6:00 PM - 8:00 PM",
        "packagingType": "Sealed Containers",
        "isPaidDonation": False,
        "amount": 0,
        "latitude": 19.1136,
        "longitude": 72.8697
    },
    {
        "foodType": "Biryani and Raita",
        "description": "Fresh chicken biryani with raita and salad",
        "quantity": "15 servings",
        "dietaryTag": "Non-Vegetarian",
        "temperatureStatus": "Hot",
        "location": "Bandra West, Mumbai, Maharashtra, India",
        "pickupTime": "7:00 PM - 9:00 PM",
        "packagingType": "Sealed Containers",
        "isPaidDonation": False,
        "amount": 0,
        "latitude": 19.0596,
        "longitude": 72.8295
    },
    {
        "foodType": "Mixed Fruit Salad",
        "description": "Fresh seasonal fruits, perfect for healthy snacking",
        "quantity": "5kg",
        "dietaryTag": "Vegan",
        "temperatureStatus": "Cold",
        "location": "Powai, Mumbai, Maharashtra, India",
        "pickupTime": "5:00 PM - 7:00 PM",
        "packagingType": "Sealed Containers",
        "isPaidDonation": False,
        "amount": 0,
        "latitude": 19.1176,
        "longitude": 72.9060
    },
    {
        "foodType": "Dal and Roti",
        "description": "Homemade dal tadka with fresh rotis",
        "quantity": "20 servings",
        "dietaryTag": "Vegetarian",
        "temperatureStatus": "Hot",
        "location": "Colaba, Mumbai, Maharashtra, India",
        "pickupTime": "6:30 PM - 8:30 PM",
        "packagingType": "Sealed Containers",
        "isPaidDonation": False,
        "amount": 0,
        "latitude": 18.9067,
        "longitude": 72.8147
    },
    {
        "foodType": "Sandwich Platter",
        "description": "Assorted vegetable and cheese sandwiches",
        "quantity": "30 pieces",
        "dietaryTag": "Vegetarian",
        "temperatureStatus": "Room Temperature",
        "location": "Dadar West, Mumbai, Maharashtra, India",
        "pickupTime": "4:00 PM - 6:00 PM",
        "packagingType": "Cardboard Boxes",
        "isPaidDonation": False,
        "amount": 0,
        "latitude": 19.0178,
        "longitude": 72.8478
    },
    {
        "foodType": "Pasta and Garlic Bread",
        "description": "Italian style pasta with garlic bread and sauce",
        "quantity": "12 servings",
        "dietaryTag": "Vegetarian",
        "temperatureStatus": "Hot",
        "location": "Juhu, Mumbai, Maharashtra, India",
        "pickupTime": "7:30 PM - 9:30 PM",
        "packagingType": "Sealed Containers",
        "isPaidDonation": True,
        "amount": 50.0,
        "latitude": 19.0990,
        "longitude": 72.8265
    }
]

def login():
    """Login and get auth token"""
    print(f"🔐 Logging in as {DONOR_EMAIL}...")
    
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "email": DONOR_EMAIL,
            "password": DONOR_PASSWORD
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        token = data['data']['token']
        print("✅ Login successful!")
        return token
    else:
        print(f"❌ Login failed: {response.text}")
        return None

def create_listing(token, listing_data):
    """Create a single listing"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    response = requests.post(
        f"{BASE_URL}/listings",
        headers=headers,
        json=listing_data
    )
    
    if response.status_code == 201:
        data = response.json()
        print(f"✅ Created listing: {listing_data['foodType']} at {listing_data['location']}")
        return data
    else:
        print(f"❌ Failed to create listing: {response.text}")
        return None

def main():
    print("=" * 60)
    print("🍽️  CrumbChain Test Listings Creator")
    print("=" * 60)
    print()
    
    # Login
    token = login()
    if not token:
        print("\n❌ Cannot proceed without authentication token")
        print("Please ensure:")
        print("1. Backend server is running (python app.py)")
        print("2. A donor account exists with the credentials above")
        print("3. Or update DONOR_EMAIL and DONOR_PASSWORD in this script")
        return
    
    print()
    print("📝 Creating test listings...")
    print()
    
    # Create all listings
    created_count = 0
    for listing in SAMPLE_LISTINGS:
        result = create_listing(token, listing)
        if result:
            created_count += 1
    
    print()
    print("=" * 60)
    print(f"✨ Successfully created {created_count} out of {len(SAMPLE_LISTINGS)} listings")
    print("=" * 60)
    print()
    print("🗺️  Open the CrumbChain app as a Receiver and tap")
    print("   'Explore Listings' to see the listings on the map!")

if __name__ == "__main__":
    main()
