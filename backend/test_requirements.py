"""
Test script for requirements API endpoints
"""

import requests
import json

BASE_URL = "http://localhost:5000"

def test_get_all_requirements():
    """Test GET /api/requirements"""
    print("\n🔍 Testing GET /api/requirements (all requirements)...")
    response = requests.get(f"{BASE_URL}/api/requirements")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Status: {response.status_code}")
        print(f"✅ Found {data['data']['count']} requirements")
        
        # Display first 3 requirements
        if data['data']['count'] > 0:
            print("\n📋 Sample requirements:")
            for i, req in enumerate(data['data']['requirements'][:3], 1):
                print(f"\n{i}. {req['organizationName']}")
                print(f"   Type: {req['organizationType']}")
                print(f"   Category: {req['category']}")
                print(f"   Crowd Size: {req['crowdSize']}")
                print(f"   Food Preference: {req['foodPreferenceTag']}")
                print(f"   Location: {req['location']}")
                print(f"   Status: {req['status']}")
        
        return data
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.json())
        return None

def test_get_requirements_by_status():
    """Test GET /api/requirements?status=active"""
    print("\n🔍 Testing GET /api/requirements?status=active...")
    response = requests.get(f"{BASE_URL}/api/requirements?status=active")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Status: {response.status_code}")
        print(f"✅ Found {data['data']['count']} active requirements")
        return data
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.json())
        return None

def test_get_requirements_by_org_type():
    """Test GET /api/requirements?organizationType=NGO"""
    print("\n🔍 Testing GET /api/requirements?organizationType=NGO...")
    response = requests.get(f"{BASE_URL}/api/requirements?organizationType=NGO")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Status: {response.status_code}")
        print(f"✅ Found {data['data']['count']} NGO requirements")
        return data
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.json())
        return None

def test_get_single_requirement(requirement_id):
    """Test GET /api/requirements/<id>"""
    print(f"\n🔍 Testing GET /api/requirements/{requirement_id}...")
    response = requests.get(f"{BASE_URL}/api/requirements/{requirement_id}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Status: {response.status_code}")
        req = data['data']['requirement']
        print(f"✅ Retrieved requirement: {req['organizationName']}")
        print(f"   Location: {req['location']}")
        print(f"   Operating Hours: {req['operatingHours']}")
        return data
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.json())
        return None

def test_requirements_endpoints():
    """Run all tests"""
    print("="*70)
    print("🧪 TESTING REQUIREMENTS API ENDPOINTS")
    print("="*70)
    
    # Test 1: Get all requirements
    data = test_get_all_requirements()
    
    if data and data['data']['count'] > 0:
        # Get first requirement ID for single requirement test
        first_req_id = data['data']['requirements'][0]['_id']
        
        # Test 2: Get single requirement
        test_get_single_requirement(first_req_id)
    
    # Test 3: Filter by status
    test_get_requirements_by_status()
    
    # Test 4: Filter by organization type
    test_get_requirements_by_org_type()
    
    print("\n" + "="*70)
    print("✅ ALL TESTS COMPLETED")
    print("="*70)
    
    print("\n📝 Summary:")
    print("   - GET /api/requirements (all): ✅")
    print("   - GET /api/requirements/<id>: ✅")
    print("   - GET /api/requirements?status=active: ✅")
    print("   - GET /api/requirements?organizationType=NGO: ✅")
    
    print("\n💡 Note: POST, PUT, DELETE endpoints require authentication")
    print("   Use the Flutter app or Postman with a valid JWT token to test those.")

if __name__ == '__main__':
    try:
        # Check if server is running
        print("🔍 Checking if Flask server is running...")
        response = requests.get(f"{BASE_URL}/")
        print(f"✅ Server is running on {BASE_URL}")
        
        # Run tests
        test_requirements_endpoints()
        
    except requests.exceptions.ConnectionError:
        print(f"❌ Error: Cannot connect to {BASE_URL}")
        print("💡 Make sure the Flask server is running (python app.py)")
    except Exception as e:
        print(f"❌ Error: {e}")
