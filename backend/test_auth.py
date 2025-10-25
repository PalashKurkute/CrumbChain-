import requests
import json

# Test backend authentication endpoints
BASE_URL = "http://127.0.0.1:5000/api"

print("=" * 60)
print("Testing Authentication Endpoints")
print("=" * 60)

# Test 1: Register a new user
print("\n1. Testing Registration...")
register_data = {
    "email": "test_user_" + str(hash("test"))[-6:] + "@test.com",
    "password": "test123456",
    "name": "Test User",
    "userType": "donor"
}

try:
    response = requests.post(f"{BASE_URL}/auth/register", json=register_data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 201:
        print("✅ Registration successful!")
        token = response.json()['data']['token']
        test_email = register_data['email']
    else:
        print("❌ Registration failed")
        # Try with existing user for login test
        test_email = "test2@test.com"
        token = None
except Exception as e:
    print(f"❌ Error: {e}")
    test_email = "test2@test.com"
    token = None

# Test 2: Login with existing user
print("\n2. Testing Login...")
login_data = {
    "email": test_email if token is None else register_data['email'],
    "password": "Test@123" if token is None else register_data['password']
}

try:
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        print("✅ Login successful!")
        token = response.json()['data']['token']
    else:
        print("❌ Login failed")
except Exception as e:
    print(f"❌ Error: {e}")

# Test 3: Invalid login
print("\n3. Testing Invalid Login...")
invalid_login = {
    "email": "wrong@test.com",
    "password": "wrongpassword"
}

try:
    response = requests.post(f"{BASE_URL}/auth/login", json=invalid_login)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 401:
        print("✅ Correctly rejected invalid credentials")
    else:
        print("❌ Unexpected response")
except Exception as e:
    print(f"❌ Error: {e}")

print("\n" + "=" * 60)
print("✅ Authentication Test Complete")
print("=" * 60)
