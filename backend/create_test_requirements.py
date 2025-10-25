"""
Script to create 15 test requirements from various NGOs and orphanages
"""

from pymongo import MongoClient
from datetime import datetime
from dotenv import load_dotenv
import os
import random

# Load environment variables
load_dotenv()

# MongoDB connection using environment variables
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'crumbchain')

try:
    client = MongoClient(MONGODB_URI)
    db = client[DATABASE_NAME]
    requirements_collection = db['requirements']
    users_collection = db['users']
    print(f"✅ Connected to MongoDB: {DATABASE_NAME}")
except Exception as e:
    print(f"❌ MongoDB connection error: {e}")
    exit(1)

# Clear existing test requirements (optional - comment out if you want to keep existing data)
# requirements_collection.delete_many({})

def get_or_create_receiver_user():
    """Get or create a test receiver user for requirements"""
    test_email = "test_receiver@ngo.org"
    
    user = users_collection.find_one({'email': test_email})
    
    if not user:
        from werkzeug.security import generate_password_hash
        
        user_doc = {
            'email': test_email,
            'password': generate_password_hash('TestPass123'),
            'name': 'Test NGO Admin',
            'role': 'receiver',
            'phoneNumber': '+1234567890',
            'location': 'Test City',
            'createdAt': datetime.now()
        }
        
        result = users_collection.insert_one(user_doc)
        user = users_collection.find_one({'_id': result.inserted_id})
        print(f"Created test receiver user: {test_email}")
    
    return user

# Test data for 15 diverse requirements
test_requirements = [
    {
        'organizationName': 'Sunrise Orphanage',
        'organizationType': 'Orphanage',
        'operatingHours': 'Breakfast: 7:00 AM - 9:00 AM',
        'crowdSize': '50',
        'foodPreferenceTag': 'Vegetarian',
        'category': 'Breakfast',
        'location': 'Mumbai, Maharashtra',
        'contactPerson': 'Sister Mary',
        'contactPhone': '+91-9876543210',
        'additionalNotes': 'Need healthy breakfast for 50 children daily',
        'latitude': 19.0760,
        'longitude': 72.8777
    },
    {
        'organizationName': 'Hope Community Kitchen',
        'organizationType': 'NGO',
        'operatingHours': 'Lunch: 12:00 PM - 2:00 PM',
        'crowdSize': '120',
        'foodPreferenceTag': 'Non-Vegetarian',
        'category': 'Lunch',
        'location': 'Delhi, Delhi',
        'contactPerson': 'Rajesh Kumar',
        'contactPhone': '+91-9876543211',
        'additionalNotes': 'Serving homeless and underprivileged people',
        'latitude': 28.7041,
        'longitude': 77.1025
    },
    {
        'organizationName': 'Little Angels Children Home',
        'organizationType': 'Orphanage',
        'operatingHours': 'Dinner: 6:00 PM - 8:00 PM',
        'crowdSize': '35',
        'foodPreferenceTag': 'Vegetarian',
        'category': 'Dinner',
        'location': 'Pune, Maharashtra',
        'contactPerson': 'Priya Sharma',
        'contactPhone': '+91-9876543212',
        'additionalNotes': 'Prefer freshly cooked meals',
        'latitude': 18.5204,
        'longitude': 73.8567
    },
    {
        'organizationName': 'Helping Hands Foundation',
        'organizationType': 'NGO',
        'operatingHours': 'Breakfast: 6:30 AM - 8:30 AM',
        'crowdSize': '80',
        'foodPreferenceTag': 'Vegan',
        'category': 'Breakfast',
        'location': 'Bangalore, Karnataka',
        'contactPerson': 'Dr. Suresh',
        'contactPhone': '+91-9876543213',
        'additionalNotes': 'Food for elderly care center residents',
        'latitude': 12.9716,
        'longitude': 77.5946
    },
    {
        'organizationName': 'Grace Orphanage',
        'organizationType': 'Orphanage',
        'operatingHours': 'Lunch: 12:30 PM - 2:00 PM',
        'crowdSize': '60',
        'foodPreferenceTag': 'Non-Vegetarian',
        'category': 'Lunch',
        'location': 'Chennai, Tamil Nadu',
        'contactPerson': 'Father John',
        'contactPhone': '+91-9876543214',
        'additionalNotes': 'Need protein-rich meals for growing children',
        'latitude': 13.0827,
        'longitude': 80.2707
    },
    {
        'organizationName': 'Mercy Home for Children',
        'organizationType': 'Orphanage',
        'operatingHours': 'Dinner: 7:00 PM - 8:30 PM',
        'crowdSize': '45',
        'foodPreferenceTag': 'Vegetarian',
        'category': 'Dinner',
        'location': 'Kolkata, West Bengal',
        'contactPerson': 'Asha Devi',
        'contactPhone': '+91-9876543215',
        'additionalNotes': 'Evening meals for 45 children',
        'latitude': 22.5726,
        'longitude': 88.3639
    },
    {
        'organizationName': 'Salvation Army Center',
        'organizationType': 'NGO',
        'operatingHours': 'Breakfast & Lunch: 8:00 AM - 2:00 PM',
        'crowdSize': '150',
        'foodPreferenceTag': 'Non-Vegetarian',
        'category': 'Breakfast',
        'location': 'Hyderabad, Telangana',
        'contactPerson': 'Captain Singh',
        'contactPhone': '+91-9876543216',
        'additionalNotes': 'Large shelter serving homeless people',
        'latitude': 17.3850,
        'longitude': 78.4867
    },
    {
        'organizationName': 'Rainbow Children Society',
        'organizationType': 'NGO',
        'operatingHours': 'Lunch: 1:00 PM - 2:30 PM',
        'crowdSize': '90',
        'foodPreferenceTag': 'Vegetarian',
        'category': 'Lunch',
        'location': 'Ahmedabad, Gujarat',
        'contactPerson': 'Meena Patel',
        'contactPhone': '+91-9876543217',
        'additionalNotes': 'Day care center for underprivileged children',
        'latitude': 23.0225,
        'longitude': 72.5714
    },
    {
        'organizationName': 'Divine Care Orphanage',
        'organizationType': 'Orphanage',
        'operatingHours': 'Breakfast: 7:30 AM - 9:00 AM',
        'crowdSize': '40',
        'foodPreferenceTag': 'Vegan',
        'category': 'Breakfast',
        'location': 'Jaipur, Rajasthan',
        'contactPerson': 'Sunita Devi',
        'contactPhone': '+91-9876543218',
        'additionalNotes': 'Special dietary requirements for sensitive children',
        'latitude': 26.9124,
        'longitude': 75.7873
    },
    {
        'organizationName': 'Faith Community Shelter',
        'organizationType': 'NGO',
        'operatingHours': 'Dinner: 6:00 PM - 8:00 PM',
        'crowdSize': '100',
        'foodPreferenceTag': 'Non-Vegetarian',
        'category': 'Dinner',
        'location': 'Surat, Gujarat',
        'contactPerson': 'Ahmed Khan',
        'contactPhone': '+91-9876543219',
        'additionalNotes': 'Evening meal program for migrant workers',
        'latitude': 21.1702,
        'longitude': 72.8311
    },
    {
        'organizationName': 'St. Joseph Orphanage',
        'organizationType': 'Orphanage',
        'operatingHours': 'Lunch: 12:00 PM - 1:30 PM',
        'crowdSize': '55',
        'foodPreferenceTag': 'Vegetarian',
        'category': 'Lunch',
        'location': 'Lucknow, Uttar Pradesh',
        'contactPerson': 'Brother Thomas',
        'contactPhone': '+91-9876543220',
        'additionalNotes': 'Nutritious meals for orphan children',
        'latitude': 26.8467,
        'longitude': 80.9462
    },
    {
        'organizationName': 'Smile Foundation Center',
        'organizationType': 'NGO',
        'operatingHours': 'Breakfast: 7:00 AM - 9:00 AM',
        'crowdSize': '70',
        'foodPreferenceTag': 'Non-Vegetarian',
        'category': 'Breakfast',
        'location': 'Nagpur, Maharashtra',
        'contactPerson': 'Deepak Rao',
        'contactPhone': '+91-9876543221',
        'additionalNotes': 'Morning meals for slum children before school',
        'latitude': 21.1458,
        'longitude': 79.0882
    },
    {
        'organizationName': 'Love and Care Home',
        'organizationType': 'Orphanage',
        'operatingHours': 'Dinner: 7:00 PM - 8:30 PM',
        'crowdSize': '30',
        'foodPreferenceTag': 'Vegetarian',
        'category': 'Dinner',
        'location': 'Indore, Madhya Pradesh',
        'contactPerson': 'Rita Singh',
        'contactPhone': '+91-9876543222',
        'additionalNotes': 'Small orphanage with home-like environment',
        'latitude': 22.7196,
        'longitude': 75.8577
    },
    {
        'organizationName': 'United Welfare Society',
        'organizationType': 'NGO',
        'operatingHours': 'Lunch: 12:00 PM - 2:00 PM',
        'crowdSize': '110',
        'foodPreferenceTag': 'Vegan',
        'category': 'Lunch',
        'location': 'Bhopal, Madhya Pradesh',
        'contactPerson': 'Ramesh Gupta',
        'contactPhone': '+91-9876543223',
        'additionalNotes': 'Community lunch program for senior citizens',
        'latitude': 23.2599,
        'longitude': 77.4126
    },
    {
        'organizationName': 'Heavenly Angels Orphanage',
        'organizationType': 'Orphanage',
        'operatingHours': 'Breakfast: 8:00 AM - 9:30 AM',
        'crowdSize': '65',
        'foodPreferenceTag': 'Non-Vegetarian',
        'category': 'Breakfast',
        'location': 'Coimbatore, Tamil Nadu',
        'contactPerson': 'Sister Angelina',
        'contactPhone': '+91-9876543224',
        'additionalNotes': 'Morning breakfast for children aged 5-15',
        'latitude': 11.0168,
        'longitude': 76.9558
    }
]

def create_requirements():
    """Create all test requirements"""
    
    # Get or create receiver user
    user = get_or_create_receiver_user()
    user_id = str(user['_id'])
    user_email = user['email']
    
    created_count = 0
    
    print(f"\nCreating 15 test requirements...")
    print("-" * 60)
    
    for req in test_requirements:
        # Add user and metadata fields
        requirement_doc = {
            'userId': user_id,
            'userEmail': user_email,
            'organizationName': req['organizationName'],
            'organizationType': req['organizationType'],
            'operatingHours': req['operatingHours'],
            'crowdSize': req['crowdSize'],
            'foodPreferenceTag': req['foodPreferenceTag'],
            'category': req['category'],
            'location': req['location'],
            'contactPerson': req['contactPerson'],
            'contactPhone': req['contactPhone'],
            'additionalNotes': req['additionalNotes'],
            'latitude': req['latitude'],
            'longitude': req['longitude'],
            'status': 'active',
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        }
        
        # Insert into database
        result = requirements_collection.insert_one(requirement_doc)
        created_count += 1
        
        print(f"✓ Created: {req['organizationName']} ({req['organizationType']}) - {req['category']}")
    
    print("-" * 60)
    print(f"\nSuccessfully created {created_count} requirements!")
    
    # Verify count
    total_count = requirements_collection.count_documents({})
    print(f"Total requirements in database: {total_count}")
    
    print("\n📊 Summary by Organization Type:")
    ngo_count = requirements_collection.count_documents({'organizationType': 'NGO'})
    orphanage_count = requirements_collection.count_documents({'organizationType': 'Orphanage'})
    print(f"  NGOs: {ngo_count}")
    print(f"  Orphanages: {orphanage_count}")
    
    print("\n🍽️  Summary by Meal Type:")
    breakfast_count = requirements_collection.count_documents({'category': 'Breakfast'})
    lunch_count = requirements_collection.count_documents({'category': 'Lunch'})
    dinner_count = requirements_collection.count_documents({'category': 'Dinner'})
    print(f"  Breakfast: {breakfast_count}")
    print(f"  Lunch: {lunch_count}")
    print(f"  Dinner: {dinner_count}")
    
    print("\n🥗 Summary by Food Preference:")
    veg_count = requirements_collection.count_documents({'foodPreferenceTag': 'Vegetarian'})
    non_veg_count = requirements_collection.count_documents({'foodPreferenceTag': 'Non-Vegetarian'})
    vegan_count = requirements_collection.count_documents({'foodPreferenceTag': 'Vegan'})
    print(f"  Vegetarian: {veg_count}")
    print(f"  Non-Vegetarian: {non_veg_count}")
    print(f"  Vegan: {vegan_count}")

if __name__ == '__main__':
    try:
        create_requirements()
        print("\n✅ Test requirements creation completed successfully!")
    except Exception as e:
        print(f"\n❌ Error creating requirements: {e}")
        import traceback
        traceback.print_exc()
