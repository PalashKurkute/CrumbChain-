"""
Create a test listing in MongoDB
This simulates what happens when a user creates a listing from the Flutter app
"""
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from datetime import datetime

# Load environment variables
load_dotenv()

MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'crumbchain')

def create_test_listing():
    """Create a test food listing"""
    print("\n🍕 Creating Test Listing in MongoDB...")
    print("=" * 60)
    
    try:
        # Connect to MongoDB
        client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        db = client[DATABASE_NAME]
        listings_collection = db['listings']
        
        print("✅ Connected to MongoDB")
        
        # Create a realistic test listing
        test_listing = {
            'userId': 'test_user_001',
            'userEmail': 'donor@crumbchain.com',
            'userName': 'Test Donor',
            'foodType': 'Vegetable Biryani',
            'description': 'Freshly made vegetable biryani with raita and salad. Perfect for 20 people. Made with organic vegetables and premium basmati rice.',
            'quantity': 'Serves 20 people (approx 10kg)',
            'datePrepared': '2025-10-25',
            'dietaryTag': 'Veg',
            'temperatureStatus': 'Hot/Freshly cooked',
            'location': 'Andheri West, Mumbai, Maharashtra 400058',
            'pickupTime': '19:00',
            'packagingType': 'Bulk container',
            'isPaidDonation': False,
            'amount': 0,
            'imageUrl': '/uploads/biryani_sample.jpg',
            'status': 'active',
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        }
        
        # Insert the listing
        result = listings_collection.insert_one(test_listing)
        
        print("\n✅ Test listing created successfully!")
        print(f"📋 Listing ID: {result.inserted_id}")
        print("\n📦 Listing Details:")
        print(f"   • Food Type: {test_listing['foodType']}")
        print(f"   • Quantity: {test_listing['quantity']}")
        print(f"   • Dietary Tag: {test_listing['dietaryTag']}")
        print(f"   • Location: {test_listing['location']}")
        print(f"   • Pickup Time: {test_listing['pickupTime']}")
        print(f"   • Status: {test_listing['status']}")
        print(f"   • Free Donation: {'Yes' if not test_listing['isPaidDonation'] else 'No'}")
        
        # Show total listings count
        total_listings = listings_collection.count_documents({})
        active_listings = listings_collection.count_documents({'status': 'active'})
        
        print("\n📊 Database Statistics:")
        print(f"   • Total Listings: {total_listings}")
        print(f"   • Active Listings: {active_listings}")
        
        # Show all listings
        print("\n📋 All Listings in Database:")
        all_listings = list(listings_collection.find())
        for i, listing in enumerate(all_listings, 1):
            print(f"\n   {i}. {listing['foodType']}")
            print(f"      ID: {listing['_id']}")
            print(f"      Donor: {listing['userName']}")
            print(f"      Quantity: {listing['quantity']}")
            print(f"      Status: {listing['status']}")
        
        client.close()
        print("\n" + "=" * 60)
        print("✅ Test listing created and saved to MongoDB Atlas!")
        print("🌐 View your data at: https://cloud.mongodb.com")
        print("=" * 60 + "\n")
        
    except Exception as e:
        print(f"\n❌ Error creating test listing: {e}")
        print("Please check your MongoDB connection.\n")

if __name__ == '__main__':
    create_test_listing()
