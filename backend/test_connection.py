from pymongo import MongoClient
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Get MongoDB URI from .env
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'crumbchain')

print("=" * 60)
print("Testing MongoDB Connection")
print("=" * 60)
print(f"Database: {DATABASE_NAME}")
print(f"URI: {MONGODB_URI[:50]}...") # Print first 50 chars for security
print()

try:
    # Connect to MongoDB
    print("Connecting to MongoDB Atlas...")
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
    
    # Verify connection by running a command
    client.admin.command('ping')
    print("✅ Successfully connected to MongoDB!")
    
    # Access the database
    db = client[DATABASE_NAME]
    print(f"✅ Connected to database: {DATABASE_NAME}")
    
    # List collections
    collections = db.list_collection_names()
    print(f"📁 Collections in database: {collections if collections else 'No collections yet'}")
    
    # Check users collection
    users_collection = db['users']
    user_count = users_collection.count_documents({})
    print(f"👥 Users in database: {user_count}")
    
    # If there are users, show a sample (without password)
    if user_count > 0:
        print("\n📋 Sample user data:")
        sample_user = users_collection.find_one({}, {'password': 0})  # Exclude password
        for key, value in sample_user.items():
            if key != '_id':
                print(f"   {key}: {value}")
    
    print("\n" + "=" * 60)
    print("✅ MongoDB Connection Test: PASSED")
    print("=" * 60)
    
except Exception as e:
    print(f"\n❌ MongoDB Connection Error:")
    print(f"   Error Type: {type(e).__name__}")
    print(f"   Error Message: {str(e)}")
    print("\n" + "=" * 60)
    print("❌ MongoDB Connection Test: FAILED")
    print("=" * 60)
finally:
    try:
        client.close()
        print("\n🔌 Connection closed.")
    except:
        pass
