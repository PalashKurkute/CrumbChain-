from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from dotenv import load_dotenv
import os
import bcrypt
import jwt
from datetime import datetime, timedelta
from werkzeug.utils import secure_filename
from functools import wraps

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Configuration
app.config['SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'your-secret-key')
app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER', 'uploads/id_proofs')
app.config['MAX_CONTENT_LENGTH'] = int(os.getenv('MAX_FILE_SIZE', 5242880))  # 5MB default

# Ensure upload folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# MongoDB connection
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
DATABASE_NAME = os.getenv('DATABASE_NAME', 'crumbchain')

try:
    client = MongoClient(MONGODB_URI)
    db = client[DATABASE_NAME]
    users_collection = db['users']
    listings_collection = db['listings']
    print(f"✅ Connected to MongoDB: {DATABASE_NAME}")
except Exception as e:
    print(f"❌ MongoDB connection error: {e}")

# Allowed file extensions
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Token required decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token:
            return jsonify({'error': 'Token is missing'}), 401
        
        try:
            # Remove 'Bearer ' prefix if present
            if token.startswith('Bearer '):
                token = token[7:]
            
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user = users_collection.find_one({'_id': data['user_id']})
            
            if not current_user:
                return jsonify({'error': 'User not found'}), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        
        return f(current_user, *args, **kwargs)
    
    return decorated

# Routes

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'message': 'CrumbChain API is running',
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/api/auth/register', methods=['POST'])
def signup():
    """User registration endpoint"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['email', 'password', 'name', 'userType']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'Missing required field: {field}'
                }), 400
        
        # Check if user already exists
        if users_collection.find_one({'email': data['email']}):
            return jsonify({
                'success': False,
                'message': 'Email already registered'
            }), 409
        
        # Validate user type
        if data['userType'].lower() not in ['donor', 'receiver']:
            return jsonify({
                'success': False,
                'message': 'Invalid user type. Must be donor or receiver'
            }), 400
        
        # Hash password
        hashed_password = bcrypt.hashpw(data['password'].encode('utf-8'), bcrypt.gensalt())
        
        # Create user document
        user_doc = {
            'email': data['email'],
            'password': hashed_password,
            'name': data['name'],
            'userType': data['userType'].lower(),
            'created_at': datetime.now(),
            'updated_at': datetime.now(),
            'is_active': True
        }
        
        # Insert user
        result = users_collection.insert_one(user_doc)
        
        # Generate JWT token
        token = jwt.encode({
            'user_id': str(result.inserted_id),
            'email': data['email'],
            'userType': data['userType'].lower(),
            'exp': datetime.utcnow() + timedelta(days=30)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        return jsonify({
            'success': True,
            'message': 'User registered successfully',
            'data': {
                'token': token,
                'user': {
                    'id': str(result.inserted_id),
                    'email': data['email'],
                    'name': data['name'],
                    'userType': data['userType'].lower()
                }
            }
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    """User login endpoint"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('email') or not data.get('password'):
            return jsonify({
                'success': False,
                'message': 'Email and password are required'
            }), 400
        
        # Find user
        user = users_collection.find_one({'email': data['email']})
        
        if not user:
            return jsonify({
                'success': False,
                'message': 'Invalid email or password'
            }), 401
        
        # Check password
        if not bcrypt.checkpw(data['password'].encode('utf-8'), user['password']):
            return jsonify({
                'success': False,
                'message': 'Invalid email or password'
            }), 401
        
        # Check if user is active
        if not user.get('is_active', True):
            return jsonify({
                'success': False,
                'message': 'Account is deactivated'
            }), 403
        
        # Generate JWT token
        token = jwt.encode({
            'user_id': str(user['_id']),
            'email': user['email'],
            'userType': user.get('userType', user.get('user_type', 'donor')),
            'exp': datetime.utcnow() + timedelta(days=30)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'data': {
                'token': token,
                'user': {
                    'id': str(user['_id']),
                    'email': user['email'],
                    'name': user.get('name', user.get('full_name', '')),
                    'userType': user.get('userType', user.get('user_type', 'donor'))
                }
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/user/profile', methods=['GET'])
@token_required
def get_profile(current_user):
    """Get user profile"""
    try:
        return jsonify({
            'user': {
                'id': str(current_user['_id']),
                'email': current_user['email'],
                'full_name': current_user['full_name'],
                'user_type': current_user['user_type'],
                'created_at': current_user['created_at'].isoformat(),
                'is_active': current_user.get('is_active', True)
            }
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/user/profile', methods=['PUT'])
@token_required
def update_profile(current_user):
    """Update user profile"""
    try:
        data = request.get_json()
        
        # Fields that can be updated
        update_fields = {}
        if 'full_name' in data:
            update_fields['full_name'] = data['full_name']
        
        if update_fields:
            update_fields['updated_at'] = datetime.now()
            users_collection.update_one(
                {'_id': current_user['_id']},
                {'$set': update_fields}
            )
        
        return jsonify({'message': 'Profile updated successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/auth/google-signin', methods=['POST'])
def google_signin():
    """Google Sign-In endpoint"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('email'):
            return jsonify({'error': 'Email is required'}), 400
        
        email = data.get('email')
        display_name = data.get('displayName', '')
        user_type = data.get('userType', 'donor').lower()
        
        # Check if user exists
        existing_user = users_collection.find_one({'email': email})
        
        if existing_user:
            # User exists, generate token and return
            token = jwt.encode({
                'user_id': str(existing_user['_id']),
                'email': existing_user['email'],
                'userType': existing_user.get('userType', existing_user.get('user_type', user_type)),
                'exp': datetime.utcnow() + timedelta(days=30)
            }, app.config['SECRET_KEY'], algorithm='HS256')
            
            return jsonify({
                'token': token,
                'user': {
                    '_id': str(existing_user['_id']),
                    'email': existing_user['email'],
                    'full_name': existing_user.get('name', display_name),
                    'user_type': existing_user.get('userType', existing_user.get('user_type', user_type))
                }
            }), 200
        else:
            # Create new user
            user_doc = {
                'email': email,
                'name': display_name,
                'userType': user_type,
                'created_at': datetime.now(),
                'updated_at': datetime.now(),
                'is_active': True,
                'auth_provider': 'google'
            }
            
            result = users_collection.insert_one(user_doc)
            
            # Generate token
            token = jwt.encode({
                'user_id': str(result.inserted_id),
                'email': email,
                'userType': user_type,
                'exp': datetime.utcnow() + timedelta(days=30)
            }, app.config['SECRET_KEY'], algorithm='HS256')
            
            return jsonify({
                'token': token,
                'user': {
                    '_id': str(result.inserted_id),
                    'email': email,
                    'full_name': display_name,
                    'user_type': user_type
                }
            }), 201
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/listings', methods=['POST'])
@token_required
def create_listing(current_user):
    """Create a new food listing"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = [
            'foodType', 'quantity', 'dietaryTag', 
            'temperatureStatus', 'location', 'packagingType'
        ]
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'Missing required field: {field}'
                }), 400
        
        # Create listing document
        listing_doc = {
            'userId': str(current_user['_id']),
            'userEmail': current_user['email'],
            'userName': current_user.get('name', current_user.get('full_name', '')),
            'foodType': data['foodType'],
            'description': data.get('description', ''),
            'quantity': data['quantity'],
            'datePrepared': data.get('datePrepared'),
            'dietaryTag': data['dietaryTag'],
            'temperatureStatus': data['temperatureStatus'],
            'location': data['location'],
            'pickupTime': data.get('pickupTime'),
            'packagingType': data['packagingType'],
            'isPaidDonation': data.get('isPaidDonation', False),
            'amount': data.get('amount', 0),
            'imageUrl': data.get('imageUrl', ''),
            'status': 'active',  # active, claimed, completed, cancelled
            'createdAt': datetime.now(),
            'updatedAt': datetime.now()
        }
        
        # Insert listing
        result = listings_collection.insert_one(listing_doc)
        
        return jsonify({
            'success': True,
            'message': 'Listing created successfully',
            'data': {
                'listingId': str(result.inserted_id),
                'listing': {
                    'id': str(result.inserted_id),
                    'foodType': data['foodType'],
                    'quantity': data['quantity'],
                    'location': data['location'],
                    'status': 'active'
                }
            }
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/listings', methods=['GET'])
@token_required
def get_listings(current_user):
    """Get all listings or user's listings"""
    try:
        # Query parameters
        user_only = request.args.get('userOnly', 'false').lower() == 'true'
        status = request.args.get('status', None)
        
        # Build query
        query = {}
        if user_only:
            query['userId'] = str(current_user['_id'])
        if status:
            query['status'] = status
        
        # Fetch listings
        listings = list(listings_collection.find(query).sort('createdAt', -1))
        
        # Convert ObjectId to string
        for listing in listings:
            listing['_id'] = str(listing['_id'])
            if 'createdAt' in listing:
                listing['createdAt'] = listing['createdAt'].isoformat()
            if 'updatedAt' in listing:
                listing['updatedAt'] = listing['updatedAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'listings': listings,
                'count': len(listings)
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/listings/<listing_id>', methods=['GET'])
@token_required
def get_listing(current_user, listing_id):
    """Get a specific listing by ID"""
    try:
        from bson import ObjectId
        
        listing = listings_collection.find_one({'_id': ObjectId(listing_id)})
        
        if not listing:
            return jsonify({
                'success': False,
                'message': 'Listing not found'
            }), 404
        
        # Convert ObjectId to string
        listing['_id'] = str(listing['_id'])
        if 'createdAt' in listing:
            listing['createdAt'] = listing['createdAt'].isoformat()
        if 'updatedAt' in listing:
            listing['updatedAt'] = listing['updatedAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'listing': listing
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/listings/<listing_id>', methods=['PUT'])
@token_required
def update_listing(current_user, listing_id):
    """Update a listing"""
    try:
        from bson import ObjectId
        
        data = request.get_json()
        
        # Check if listing exists and belongs to user
        listing = listings_collection.find_one({'_id': ObjectId(listing_id)})
        
        if not listing:
            return jsonify({
                'success': False,
                'message': 'Listing not found'
            }), 404
        
        if listing['userId'] != str(current_user['_id']):
            return jsonify({
                'success': False,
                'message': 'Unauthorized to update this listing'
            }), 403
        
        # Fields that can be updated
        update_fields = {}
        updatable_fields = [
            'foodType', 'description', 'quantity', 'datePrepared',
            'dietaryTag', 'temperatureStatus', 'location', 'pickupTime',
            'packagingType', 'isPaidDonation', 'amount', 'imageUrl', 'status'
        ]
        
        for field in updatable_fields:
            if field in data:
                update_fields[field] = data[field]
        
        if update_fields:
            update_fields['updatedAt'] = datetime.now()
            listings_collection.update_one(
                {'_id': ObjectId(listing_id)},
                {'$set': update_fields}
            )
        
        return jsonify({
            'success': True,
            'message': 'Listing updated successfully'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/listings/<listing_id>', methods=['DELETE'])
@token_required
def delete_listing(current_user, listing_id):
    """Delete a listing"""
    try:
        from bson import ObjectId
        
        # Check if listing exists and belongs to user
        listing = listings_collection.find_one({'_id': ObjectId(listing_id)})
        
        if not listing:
            return jsonify({
                'success': False,
                'message': 'Listing not found'
            }), 404
        
        if listing['userId'] != str(current_user['_id']):
            return jsonify({
                'success': False,
                'message': 'Unauthorized to delete this listing'
            }), 403
        
        # Delete listing
        listings_collection.delete_one({'_id': ObjectId(listing_id)})
        
        return jsonify({
            'success': True,
            'message': 'Listing deleted successfully'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
