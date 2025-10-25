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
    requirements_collection = db['requirements']
    notifications_collection = db['notifications']
    print(f"✅ Connected to MongoDB: {DATABASE_NAME}")
except Exception as e:
    print(f"❌ MongoDB connection error: {e}")

# Allowed file extensions
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ============= NOTIFICATION HELPER FUNCTIONS =============

def create_notification(user_id, notification_type, title, message, **kwargs):
    """
    Create a new notification
    
    Args:
        user_id: ID of the user to receive the notification
        notification_type: Type of notification (order_status, listing_claimed, etc.)
        title: Notification title
        message: Notification message
        **kwargs: Additional fields (listingId, orderId, relatedUserId, orderStatus, etc.)
    
    Returns:
        The created notification document
    """
    try:
        from bson import ObjectId
        
        notification = {
            'userId': ObjectId(user_id) if isinstance(user_id, str) else user_id,
            'type': notification_type,
            'title': title,
            'message': message,
            'isRead': False,
            'createdAt': datetime.now()
        }
        
        # Add optional fields
        if 'listingId' in kwargs and kwargs['listingId']:
            notification['listingId'] = ObjectId(kwargs['listingId']) if isinstance(kwargs['listingId'], str) else kwargs['listingId']
        if 'orderId' in kwargs and kwargs['orderId']:
            notification['orderId'] = ObjectId(kwargs['orderId']) if isinstance(kwargs['orderId'], str) else kwargs['orderId']
        if 'relatedUserId' in kwargs and kwargs['relatedUserId']:
            notification['relatedUserId'] = ObjectId(kwargs['relatedUserId']) if isinstance(kwargs['relatedUserId'], str) else kwargs['relatedUserId']
        if 'relatedUserName' in kwargs:
            notification['relatedUserName'] = kwargs['relatedUserName']
        if 'orderStatus' in kwargs:
            notification['orderStatus'] = kwargs['orderStatus']
        if 'metadata' in kwargs:
            notification['metadata'] = kwargs['metadata']
        
        result = notifications_collection.insert_one(notification)
        notification['_id'] = result.inserted_id
        
        print(f"✅ Notification created for user {user_id}: {title}")
        return notification
        
    except Exception as e:
        print(f"❌ Error creating notification: {str(e)}")
        return None


def notify_listing_claimed(listing, claimant):
    """Notify donor when their listing is claimed"""
    try:
        create_notification(
            user_id=listing['userId'],
            notification_type='approval_request',
            title='New Order Request',
            message=f"{claimant.get('name', claimant.get('full_name', 'Someone'))} wants to claim your food donation \"{listing.get('foodType', 'item')}\"",
            listingId=str(listing['_id']),
            relatedUserId=str(claimant['_id']),
            relatedUserName=claimant.get('name', claimant.get('full_name', 'User')),
            orderStatus='pending_approval'
        )
    except Exception as e:
        print(f"❌ Error creating listing claimed notification: {str(e)}")


def notify_order_status_change(listing, donor, receiver, new_status):
    """Create notifications when an order status changes"""
    try:
        # Notification for receiver
        receiver_messages = {
            'approved': f"Your order has been approved by {donor.get('name', donor.get('full_name', 'the donor'))}",
            'in_transit': "Your order is now in transit",
            'out_for_delivery': "Your order is out for delivery",
            'delivered': "Your order has been delivered successfully",
            'completed': "Your order has been completed. Thank you for using CrumbChain!"
        }
        
        if new_status in receiver_messages:
            create_notification(
                user_id=str(receiver['_id']),
                notification_type='order_status',
                title=f"Order {new_status.replace('_', ' ').title()}",
                message=receiver_messages[new_status],
                listingId=str(listing['_id']),
                orderStatus=new_status,
                relatedUserId=str(donor['_id']),
                relatedUserName=donor.get('name', donor.get('full_name', 'Donor'))
            )
        
        # Notification for donor
        donor_messages = {
            'in_transit': f"{receiver.get('name', receiver.get('full_name', 'The receiver'))} has picked up the order",
            'delivered': f"Your donation has been delivered to {receiver.get('name', receiver.get('full_name', 'the receiver'))}",
            'completed': "Your donation order has been completed successfully"
        }
        
        if new_status in donor_messages:
            create_notification(
                user_id=str(donor['_id']),
                notification_type='order_status',
                title=f"Order {new_status.replace('_', ' ').title()}",
                message=donor_messages[new_status],
                listingId=str(listing['_id']),
                orderStatus=new_status,
                relatedUserId=str(receiver['_id']),
                relatedUserName=receiver.get('name', receiver.get('full_name', 'Receiver'))
            )
            
    except Exception as e:
        print(f"❌ Error creating order status notifications: {str(e)}")

# Token required decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token:
            return jsonify({'error': 'Token is missing'}), 401
        
        try:
            from bson import ObjectId
            
            # Remove 'Bearer ' prefix if present
            if token.startswith('Bearer '):
                token = token[7:]
            
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            
            # Convert user_id to ObjectId for MongoDB query
            user_id = data['user_id']
            if isinstance(user_id, str):
                user_id = ObjectId(user_id)
            
            current_user = users_collection.find_one({'_id': user_id})
            
            if not current_user:
                return jsonify({'error': 'User not found'}), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        except Exception as e:
            return jsonify({'error': f'Authentication error: {str(e)}'}), 401
        
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
        
        # Add coordinates if provided
        if 'latitude' in data and 'longitude' in data:
            listing_doc['latitude'] = float(data['latitude'])
            listing_doc['longitude'] = float(data['longitude'])
        
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
def get_listings():
    """Get all listings or user's listings (public endpoint for browsing, auth optional)"""
    try:
        # Check if user is authenticated (optional)
        token = request.headers.get('Authorization')
        current_user_id = None
        
        if token:
            try:
                if token.startswith('Bearer '):
                    token = token[7:]
                data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
                current_user_id = data['user_id']
            except:
                pass  # Token invalid or expired, continue as public access
        
        # Query parameters
        user_only = request.args.get('userOnly', 'false').lower() == 'true'
        status = request.args.get('status', None)
        
        # Build query
        query = {}
        
        # If userOnly is requested, authentication is required
        if user_only:
            if not current_user_id:
                return jsonify({
                    'success': False,
                    'message': 'Authentication required for user-specific listings'
                }), 401
            query['userId'] = current_user_id
        
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
def get_listing(listing_id):
    """Get a specific listing by ID (public endpoint)"""
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

# ============= REQUIREMENTS ENDPOINTS =============

@app.route('/api/requirements', methods=['POST'])
@token_required
def create_requirement(current_user):
    """Create a new food requirement"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['organizationName', 'organizationType', 'operatingHours', 'crowdSize']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'message': f'Missing required field: {field}'
                }), 400
        
        # Create requirement document
        requirement_doc = {
            'userId': str(current_user['_id']),
            'userEmail': current_user['email'],
            'organizationName': data['organizationName'],
            'organizationType': data['organizationType'],
            'operatingHours': data['operatingHours'],
            'crowdSize': data['crowdSize'],
            'foodPreferenceTag': data.get('foodPreferenceTag', ''),
            'category': data.get('category', ''),
            'location': data.get('location', ''),
            'contactPerson': data.get('contactPerson', ''),
            'contactPhone': data.get('contactPhone', ''),
            'additionalNotes': data.get('additionalNotes', ''),
            'status': 'active',  # active, fulfilled, inactive
            'createdAt': datetime.now(),
            'updatedAt': datetime.now(),
            'latitude': data.get('latitude'),
            'longitude': data.get('longitude'),
        }
        
        # Insert requirement
        result = requirements_collection.insert_one(requirement_doc)
        
        return jsonify({
            'success': True,
            'message': 'Requirement created successfully',
            'data': {
                'requirementId': str(result.inserted_id)
            }
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/requirements', methods=['GET'])
def get_requirements():
    """Get all requirements (public endpoint for donors to browse)"""
    try:
        # Check if user is authenticated (optional)
        token = request.headers.get('Authorization')
        current_user_id = None
        
        if token:
            try:
                if token.startswith('Bearer '):
                    token = token[7:]
                data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
                current_user_id = data['user_id']
            except:
                pass  # Token invalid or expired, continue as public access
        
        # Query parameters
        user_only = request.args.get('userOnly', 'false').lower() == 'true'
        status = request.args.get('status', None)
        org_type = request.args.get('organizationType', None)
        
        # Build query
        query = {}
        
        # If userOnly is requested, authentication is required
        if user_only:
            if not current_user_id:
                return jsonify({
                    'success': False,
                    'message': 'Authentication required for user-specific requirements'
                }), 401
            query['userId'] = current_user_id
        
        if status:
            query['status'] = status
        
        if org_type:
            query['organizationType'] = org_type
        
        # Fetch requirements
        requirements = list(requirements_collection.find(query).sort('createdAt', -1))
        
        # Convert ObjectId to string
        for requirement in requirements:
            requirement['_id'] = str(requirement['_id'])
            if 'createdAt' in requirement:
                requirement['createdAt'] = requirement['createdAt'].isoformat()
            if 'updatedAt' in requirement:
                requirement['updatedAt'] = requirement['updatedAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'requirements': requirements,
                'count': len(requirements)
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/requirements/<requirement_id>', methods=['GET'])
def get_requirement(requirement_id):
    """Get a specific requirement by ID (public endpoint)"""
    try:
        from bson import ObjectId
        
        requirement = requirements_collection.find_one({'_id': ObjectId(requirement_id)})
        
        if not requirement:
            return jsonify({
                'success': False,
                'message': 'Requirement not found'
            }), 404
        
        # Convert ObjectId to string
        requirement['_id'] = str(requirement['_id'])
        if 'createdAt' in requirement:
            requirement['createdAt'] = requirement['createdAt'].isoformat()
        if 'updatedAt' in requirement:
            requirement['updatedAt'] = requirement['updatedAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'requirement': requirement
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/requirements/<requirement_id>', methods=['PUT'])
@token_required
def update_requirement(current_user, requirement_id):
    """Update a requirement"""
    try:
        from bson import ObjectId
        
        data = request.get_json()
        
        # Check if requirement exists and belongs to user
        requirement = requirements_collection.find_one({'_id': ObjectId(requirement_id)})
        
        if not requirement:
            return jsonify({
                'success': False,
                'message': 'Requirement not found'
            }), 404
        
        if requirement['userId'] != str(current_user['_id']):
            return jsonify({
                'success': False,
                'message': 'Unauthorized to update this requirement'
            }), 403
        
        # Fields that can be updated
        update_fields = {}
        updatable_fields = [
            'organizationName', 'organizationType', 'operatingHours', 'crowdSize',
            'foodPreferenceTag', 'category', 'location', 'contactPerson',
            'contactPhone', 'additionalNotes', 'status', 'latitude', 'longitude'
        ]
        
        for field in updatable_fields:
            if field in data:
                update_fields[field] = data[field]
        
        if update_fields:
            update_fields['updatedAt'] = datetime.now()
            requirements_collection.update_one(
                {'_id': ObjectId(requirement_id)},
                {'$set': update_fields}
            )
        
        return jsonify({
            'success': True,
            'message': 'Requirement updated successfully'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/requirements/<requirement_id>', methods=['DELETE'])
@token_required
def delete_requirement(current_user, requirement_id):
    """Delete a requirement"""
    try:
        from bson import ObjectId
        
        # Check if requirement exists and belongs to user
        requirement = requirements_collection.find_one({'_id': ObjectId(requirement_id)})
        
        if not requirement:
            return jsonify({
                'success': False,
                'message': 'Requirement not found'
            }), 404
        
        if requirement['userId'] != str(current_user['_id']):
            return jsonify({
                'success': False,
                'message': 'Unauthorized to delete this requirement'
            }), 403
        
        # Delete requirement
        requirements_collection.delete_one({'_id': ObjectId(requirement_id)})
        
        return jsonify({
            'success': True,
            'message': 'Requirement deleted successfully'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

# ============= ORDERS/CLAIMS ENDPOINTS =============

@app.route('/api/orders/claim/<listing_id>', methods=['POST'])
@token_required
def claim_listing(current_user, listing_id):
    """Claim a listing (receiver claims donor's food)"""
    try:
        from bson import ObjectId
        
        # Check if listing exists
        listing = listings_collection.find_one({'_id': ObjectId(listing_id)})
        
        if not listing:
            return jsonify({
                'success': False,
                'message': 'Listing not found'
            }), 404
        
        # Check if listing is still active
        if listing['status'] != 'active':
            return jsonify({
                'success': False,
                'message': f'Listing is already {listing["status"]}'
            }), 400
        
        # Update listing status to claimed
        listings_collection.update_one(
            {'_id': ObjectId(listing_id)},
            {
                '$set': {
                    'status': 'claimed',
                    'claimedBy': str(current_user['_id']),
                    'claimedByEmail': current_user['email'],
                    'claimedByName': current_user.get('name', current_user.get('full_name', '')),
                    'claimedAt': datetime.now(),
                    'updatedAt': datetime.now(),
                    'orderStatus': 'pending_approval'  # pending_approval, approved, in_transit, delivered, completed
                }
            }
        )
        
        # Create notification for donor
        notify_listing_claimed(listing, current_user)
        
        return jsonify({
            'success': True,
            'message': 'Listing claimed successfully',
            'data': {
                'listingId': listing_id,
                'orderStatus': 'pending_approval'
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/orders/<listing_id>/approve', methods=['PUT'])
@token_required
def approve_order(current_user, listing_id):
    """Approve a claimed order (donor approves receiver's claim)"""
    try:
        from bson import ObjectId
        
        # Check if listing exists and belongs to current user
        listing = listings_collection.find_one({'_id': ObjectId(listing_id)})
        
        if not listing:
            return jsonify({
                'success': False,
                'message': 'Listing not found'
            }), 404
        
        # Check if user is the donor
        if listing['userId'] != str(current_user['_id']):
            return jsonify({
                'success': False,
                'message': 'Only the donor can approve this order'
            }), 403
        
        # Check if listing is claimed
        if listing['status'] != 'claimed':
            return jsonify({
                'success': False,
                'message': 'Listing must be claimed before approval'
            }), 400
        
        # Update order status to approved
        listings_collection.update_one(
            {'_id': ObjectId(listing_id)},
            {
                '$set': {
                    'orderStatus': 'approved',
                    'approvedAt': datetime.now(),
                    'updatedAt': datetime.now()
                }
            }
        )
        
        # Create notification for receiver
        receiver = users_collection.find_one({'_id': ObjectId(listing['claimedBy'])})
        if receiver:
            create_notification(
                user_id=listing['claimedBy'],
                notification_type='order_status',
                title='Order Approved',
                message=f'Your order for "{listing.get("foodType", "food item")}" has been approved by {current_user.get("name", current_user.get("full_name", "the donor"))}',
                listingId=listing_id,
                orderStatus='approved',
                relatedUserId=str(current_user['_id']),
                relatedUserName=current_user.get('name', current_user.get('full_name', 'Donor'))
            )
        
        return jsonify({
            'success': True,
            'message': 'Order approved successfully',
            'data': {
                'listingId': listing_id,
                'orderStatus': 'approved'
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/orders/<listing_id>/update-status', methods=['PUT'])
@token_required
def update_order_status(current_user, listing_id):
    """Update order status (for simulating delivery tracking)"""
    try:
        from bson import ObjectId
        
        data = request.get_json()
        new_status = data.get('orderStatus')
        
        if not new_status:
            return jsonify({
                'success': False,
                'message': 'orderStatus is required'
            }), 400
        
        # Valid order statuses
        valid_statuses = ['pending_approval', 'approved', 'in_transit', 'out_for_delivery', 'delivered', 'completed']
        
        if new_status not in valid_statuses:
            return jsonify({
                'success': False,
                'message': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'
            }), 400
        
        # Check if listing exists
        listing = listings_collection.find_one({'_id': ObjectId(listing_id)})
        
        if not listing:
            return jsonify({
                'success': False,
                'message': 'Listing not found'
            }), 404
        
        # Check if user is involved (donor or receiver)
        user_id = str(current_user['_id'])
        if listing['userId'] != user_id and listing.get('claimedBy') != user_id:
            return jsonify({
                'success': False,
                'message': 'You are not authorized to update this order'
            }), 403
        
        # Update order status
        update_fields = {
            'orderStatus': new_status,
            'updatedAt': datetime.now()
        }
        
        # Add status-specific timestamps
        if new_status == 'in_transit':
            update_fields['inTransitAt'] = datetime.now()
        elif new_status == 'out_for_delivery':
            update_fields['outForDeliveryAt'] = datetime.now()
        elif new_status == 'delivered':
            update_fields['deliveredAt'] = datetime.now()
        elif new_status == 'completed':
            update_fields['completedAt'] = datetime.now()
            update_fields['status'] = 'completed'
        
        # Create notifications for status changes BEFORE updating/deleting
        if new_status in ['in_transit', 'out_for_delivery', 'delivered', 'completed']:
            donor = users_collection.find_one({'_id': ObjectId(listing['userId'])})
            receiver = users_collection.find_one({'_id': ObjectId(listing.get('claimedBy'))})
            
            if donor and receiver:
                notify_order_status_change(listing, donor, receiver, new_status)
        
        # If status is completed, DELETE the listing instead of updating
        if new_status == 'completed':
            listings_collection.delete_one({'_id': ObjectId(listing_id)})
            print(f'✅ Listing {listing_id} automatically deleted after completion')
        else:
            # Update listing for other statuses
            listings_collection.update_one(
                {'_id': ObjectId(listing_id)},
                {'$set': update_fields}
            )
        
        return jsonify({
            'success': True,
            'message': f'Order status updated to {new_status}',
            'data': {
                'listingId': listing_id,
                'orderStatus': new_status
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/orders/my-orders', methods=['GET'])
@token_required
def get_my_orders(current_user):
    """Get all orders for current user (both as donor and receiver)"""
    try:
        user_id = str(current_user['_id'])
        
        # Get orders where user is the donor
        donated_orders = list(listings_collection.find({
            'userId': user_id,
            'status': {'$in': ['claimed', 'completed']}
        }).sort('updatedAt', -1))
        
        # Get orders where user is the receiver (claimed listings)
        received_orders = list(listings_collection.find({
            'claimedBy': user_id
        }).sort('updatedAt', -1))
        
        # Convert ObjectId to string and format dates
        for order in donated_orders + received_orders:
            order['_id'] = str(order['_id'])
            if 'createdAt' in order:
                order['createdAt'] = order['createdAt'].isoformat()
            if 'updatedAt' in order:
                order['updatedAt'] = order['updatedAt'].isoformat()
            if 'claimedAt' in order:
                order['claimedAt'] = order['claimedAt'].isoformat()
            if 'approvedAt' in order:
                order['approvedAt'] = order['approvedAt'].isoformat()
            if 'deliveredAt' in order:
                order['deliveredAt'] = order['deliveredAt'].isoformat()
            if 'completedAt' in order:
                order['completedAt'] = order['completedAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'donatedOrders': donated_orders,
                'receivedOrders': received_orders,
                'totalOrders': len(donated_orders) + len(received_orders)
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/orders/active', methods=['GET'])
@token_required
def get_active_orders(current_user):
    """Get active orders (approved and in progress) for live tracking"""
    try:
        user_id = str(current_user['_id'])
        
        # Get orders where user is involved and status is active
        active_orders = list(listings_collection.find({
            '$or': [
                {'userId': user_id},
                {'claimedBy': user_id}
            ],
            'orderStatus': {'$in': ['approved', 'in_transit', 'out_for_delivery']}
        }).sort('updatedAt', -1))
        
        # Convert ObjectId to string and format dates
        for order in active_orders:
            order['_id'] = str(order['_id'])
            if 'createdAt' in order:
                order['createdAt'] = order['createdAt'].isoformat()
            if 'updatedAt' in order:
                order['updatedAt'] = order['updatedAt'].isoformat()
            if 'claimedAt' in order:
                order['claimedAt'] = order['claimedAt'].isoformat()
            if 'approvedAt' in order:
                order['approvedAt'] = order['approvedAt'].isoformat()
            if 'inTransitAt' in order:
                order['inTransitAt'] = order['inTransitAt'].isoformat()
            if 'outForDeliveryAt' in order:
                order['outForDeliveryAt'] = order['outForDeliveryAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'activeOrders': active_orders,
                'count': len(active_orders)
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/orders/<order_id>', methods=['DELETE'])
@token_required
def delete_order(current_user, order_id):
    """Delete a pending order (receiver can delete their pending orders)"""
    try:
        from bson import ObjectId
        user_id = str(current_user['_id'])
        
        # Find the order
        order = listings_collection.find_one({'_id': ObjectId(order_id)})
        
        if not order:
            return jsonify({
                'success': False,
                'message': 'Order not found'
            }), 404
        
        # Check if user is the receiver (claimedBy)
        if order.get('claimedBy') != user_id:
            return jsonify({
                'success': False,
                'message': 'You can only delete your own orders'
            }), 403
        
        # Only allow deletion of pending orders
        order_status = order.get('orderStatus', 'pending_approval')
        if order_status != 'pending_approval':
            return jsonify({
                'success': False,
                'message': f'Cannot delete order with status: {order_status}. Only pending orders can be deleted.'
            }), 400
        
        # Delete the order by updating the listing to remove claimedBy
        result = listings_collection.update_one(
            {'_id': ObjectId(order_id)},
            {
                '$unset': {
                    'claimedBy': '',
                    'claimedAt': '',
                    'orderStatus': ''
                },
                '$set': {
                    'status': 'active',
                    'updatedAt': datetime.utcnow()
                }
            }
        )
        
        if result.modified_count == 0:
            return jsonify({
                'success': False,
                'message': 'Failed to delete order'
            }), 500
        
        # Delete any related notifications
        notifications_collection.delete_many({
            'listingId': order_id,
            'type': 'approval_request'
        })
        
        return jsonify({
            'success': True,
            'message': 'Order deleted successfully'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

# ============= NOTIFICATIONS ENDPOINTS =============

@app.route('/api/notifications', methods=['GET'])
@token_required
def get_notifications(current_user):
    """Get all notifications for the current user"""
    try:
        from bson import ObjectId
        
        # Query notifications for the user, sorted by creation date (newest first)
        notifications = list(notifications_collection.find({
            'userId': current_user['_id']
        }).sort('createdAt', -1).limit(100))
        
        # Count unread notifications
        unread_count = notifications_collection.count_documents({
            'userId': current_user['_id'],
            'isRead': False
        })
        
        # Convert ObjectId to string for JSON serialization
        for notif in notifications:
            notif['_id'] = str(notif['_id'])
            notif['userId'] = str(notif['userId'])
            if 'listingId' in notif and notif['listingId']:
                notif['listingId'] = str(notif['listingId'])
            if 'orderId' in notif and notif['orderId']:
                notif['orderId'] = str(notif['orderId'])
            if 'relatedUserId' in notif and notif['relatedUserId']:
                notif['relatedUserId'] = str(notif['relatedUserId'])
            notif['createdAt'] = notif['createdAt'].isoformat()
        
        return jsonify({
            'success': True,
            'notifications': notifications,
            'unreadCount': unread_count
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Failed to fetch notifications: {str(e)}'
        }), 500


@app.route('/api/notifications/unread-count', methods=['GET'])
@token_required
def get_unread_count(current_user):
    """Get count of unread notifications"""
    try:
        count = notifications_collection.count_documents({
            'userId': current_user['_id'],
            'isRead': False
        })
        
        return jsonify({
            'success': True,
            'count': count
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Failed to get unread count: {str(e)}'
        }), 500


@app.route('/api/notifications/<notification_id>/read', methods=['PUT'])
@token_required
def mark_notification_as_read(current_user, notification_id):
    """Mark a notification as read"""
    try:
        from bson import ObjectId
        
        # Update the notification if it belongs to the current user
        result = notifications_collection.update_one(
            {
                '_id': ObjectId(notification_id),
                'userId': current_user['_id']
            },
            {
                '$set': {'isRead': True}
            }
        )
        
        if result.modified_count > 0:
            return jsonify({
                'success': True,
                'message': 'Notification marked as read'
            }), 200
        else:
            return jsonify({
                'success': False,
                'message': 'Notification not found or already read'
            }), 404
            
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Failed to mark notification as read: {str(e)}'
        }), 500


@app.route('/api/notifications/mark-all-read', methods=['PUT'])
@token_required
def mark_all_notifications_as_read(current_user):
    """Mark all notifications as read for the current user"""
    try:
        result = notifications_collection.update_many(
            {
                'userId': current_user['_id'],
                'isRead': False
            },
            {
                '$set': {'isRead': True}
            }
        )
        
        return jsonify({
            'success': True,
            'message': f'{result.modified_count} notifications marked as read'
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Failed to mark all as read: {str(e)}'
        }), 500


@app.route('/api/notifications/<notification_id>', methods=['DELETE'])
@token_required
def delete_notification(current_user, notification_id):
    """Delete a notification"""
    try:
        from bson import ObjectId
        
        result = notifications_collection.delete_one({
            '_id': ObjectId(notification_id),
            'userId': current_user['_id']
        })
        
        if result.deleted_count > 0:
            return jsonify({
                'success': True,
                'message': 'Notification deleted'
            }), 200
        else:
            return jsonify({
                'success': False,
                'message': 'Notification not found'
            }), 404
            
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Failed to delete notification: {str(e)}'
        }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
