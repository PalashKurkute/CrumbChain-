"""
Test MongoDB Connection and Listing Operations
Run this script to verify MongoDB is properly configured
"""
from pymongo import MongoClient
from dotenv import load_dotenv
import os
from datetime import datetime

# Load environment variables
load_dotenv()

MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'crumbchain')

def test_connection():
    """Test MongoDB connection"""
    print("\n🔍 Testing MongoDB Connection...")
    try:
        client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        # Force connection
        client.server_info()
        print("✅ Successfully connected to MongoDB!")
        
        # Get database
        db = client[DATABASE_NAME]
        print(f"✅ Database '{DATABASE_NAME}' is accessible")
        
        # List collections
        collections = db.list_collection_names()
        print(f"📦 Existing collections: {collections}")
        
        return client, db
    except Exception as e:
        print(f"❌ MongoDB connection failed: {e}")
        return None, None

def test_listing_operations(db):
    """Test CRUD operations on listings collection"""
    if db is None:
        print("❌ Cannot test operations - no database connection")
        return
    
    print("\n🧪 Testing Listing Operations...")
    listings_collection = db['listings']
    
    # Create test listing
    print("\n1️⃣ Creating test listing...")
    test_listing = {
        'userId': 'test_user_123',
        'userEmail': 'test@example.com',
        'userName': 'Test User',
        'foodType': 'Test Pizza',
        'description': 'Delicious test pizza',
        'quantity': 'Serves 5 people',
        'datePrepared': '2025-10-25',
        'dietaryTag': 'Veg',
        'temperatureStatus': 'Hot/Freshly cooked',
        'location': 'Test Location, Mumbai',
        'pickupTime': '18:00',
        'packagingType': 'Individual boxes',
        'isPaidDonation': False,
        'amount': 0,
        'imageUrl': '',
        'status': 'active',
        'createdAt': datetime.now(),
        'updatedAt': datetime.now()
    }
    
    result = listings_collection.insert_one(test_listing)
    print(f"✅ Test listing created with ID: {result.inserted_id}")
    
    # Read listing
    print("\n2️⃣ Reading test listing...")
    found_listing = listings_collection.find_one({'_id': result.inserted_id})
    if found_listing:
        print(f"✅ Listing found: {found_listing['foodType']}")
        print(f"   - Quantity: {found_listing['quantity']}")
        print(f"   - Status: {found_listing['status']}")
    
    # Update listing
    print("\n3️⃣ Updating test listing...")
    update_result = listings_collection.update_one(
        {'_id': result.inserted_id},
        {'$set': {'status': 'completed', 'updatedAt': datetime.now()}}
    )
    print(f"✅ Listing updated - Modified count: {update_result.modified_count}")
    
    # Verify update
    updated_listing = listings_collection.find_one({'_id': result.inserted_id})
    print(f"   - New status: {updated_listing['status']}")
    
    # Count listings
    print("\n4️⃣ Counting all listings...")
    total_count = listings_collection.count_documents({})
    print(f"✅ Total listings in database: {total_count}")
    
    # Delete test listing
    print("\n5️⃣ Deleting test listing...")
    delete_result = listings_collection.delete_one({'_id': result.inserted_id})
    print(f"✅ Test listing deleted - Deleted count: {delete_result.deleted_count}")
    
    print("\n✅ All operations completed successfully!")

def show_stats(db):
    """Show database statistics"""
    if db is None:
        return
    
    print("\n📊 Database Statistics:")
    
    # Users collection
    if 'users' in db.list_collection_names():
        users_count = db['users'].count_documents({})
        print(f"   - Users: {users_count}")
    
    # Listings collection
    if 'listings' in db.list_collection_names():
        listings_count = db['listings'].count_documents({})
        active_listings = db['listings'].count_documents({'status': 'active'})
        print(f"   - Total Listings: {listings_count}")
        print(f"   - Active Listings: {active_listings}")

if __name__ == '__main__':
    print("=" * 60)
    print("   MongoDB Connection & Listing Operations Test")
    print("=" * 60)
    
    # Test connection
    client, db = test_connection()
    
    if client is not None and db is not None:
        # Test operations
        test_listing_operations(db)
        
        # Show stats
        show_stats(db)
        
        # Close connection
        client.close()
        print("\n👋 MongoDB connection closed")
    else:
        print("\n❌ Tests failed - please check your MongoDB configuration")
        print("\nQuick fixes:")
        print("  1. Make sure MongoDB is running")
        print("  2. Check MONGODB_URI in .env file")
        print("  3. Verify network connectivity")
    
    print("\n" + "=" * 60)
