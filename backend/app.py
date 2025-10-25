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
from PIL import Image
import numpy as np
import io

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Configuration
app.config['SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'your-secret-key')
app.config['UPLOAD_FOLDER'] = os.getenv('UPLOAD_FOLDER', 'uploads/id_proofs')
app.config['MAX_CONTENT_LENGTH'] = int(os.getenv('MAX_FILE_SIZE', 16777216))  # 16MB default (increased for images)

# Ensure upload folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# ============= ERROR HANDLERS =============

@app.errorhandler(413)
def request_entity_too_large(error):
    """Handle file size exceeded error"""
    return jsonify({
        'success': False,
        'message': 'File too large. Maximum file size is 16MB.'
    }), 413

@app.errorhandler(Exception)
def handle_exception(error):
    """Handle general exceptions"""
    print(f"❌ Unhandled exception: {error}")
    import traceback
    traceback.print_exc()
    return jsonify({
        'success': False,
        'message': f'Server error: {str(error)}'
    }), 500

# ============= END ERROR HANDLERS =============

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

# ============= FOOD DETECTION MODEL LOADING =============

# Global variables for food detection model
FOOD_MODEL = None
FOOD_CLASSES = []
IMG_SIZE = (299, 299)  # InceptionV3 input size

def load_food_detection_model():
    """Load the trained food detection model (InceptionV3)"""
    global FOOD_MODEL, FOOD_CLASSES
    
    try:
        import tensorflow as tf
        from tensorflow import keras
        
        model_path = os.path.join(os.path.dirname(__file__), 'models', 'food_model.h5')
        labels_path = os.path.join(os.path.dirname(__file__), 'models', 'labels.txt')
        
        if not os.path.exists(model_path):
            print(f"⚠️  Food model not found at {model_path}")
            return
        
        if not os.path.exists(labels_path):
            print(f"⚠️  Labels file not found at {labels_path}")
            return
        
        # Load model
        print("🔄 Loading food detection model...")
        FOOD_MODEL = keras.models.load_model(model_path)
        print("✅ Food detection model loaded successfully!")
        
        # Load class labels
        with open(labels_path, 'r') as f:
            FOOD_CLASSES = [line.strip() for line in f.readlines() if line.strip()]
        
        print(f"✅ Loaded {len(FOOD_CLASSES)} food classes: {', '.join(FOOD_CLASSES[:5])}...")
        
    except ImportError:
        print("⚠️  TensorFlow not installed. Food detection will not be available.")
        print("   Install with: pip install tensorflow")
    except Exception as e:
        print(f"❌ Failed to load food detection model: {e}")

# Load the model when app starts
load_food_detection_model()

# ============= END FOOD DETECTION MODEL LOADING =============

# Allowed file extensions
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'pdf'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# ============= REWARD SYSTEM HELPER FUNCTIONS =============

def calculate_reward_points(listing):
    """
    Calculate reward points based on listing details
    
    Base points: 10
    Bonus points for:
    - Meal type (breakfast: +5, lunch: +7, dinner: +7, snacks: +3)
    - Quantity (per serving: +2, max bonus: +20)
    - Urgency (immediate: +10, today: +7, this_week: +5)
    
    Returns:
        int: Total reward points
    """
    base_points = 10
    bonus_points = 0
    
    # Meal type bonus
    meal_type = listing.get('mealType', '').lower()
    meal_bonuses = {
        'breakfast': 5,
        'lunch': 7,
        'dinner': 7,
        'snacks': 3,
        'dessert': 4
    }
    for meal, bonus in meal_bonuses.items():
        if meal in meal_type:
            bonus_points += bonus
            break
    
    # Quantity bonus (parse quantity string)
    quantity_str = listing.get('quantity', '0')
    try:
        # Extract number from quantity string (e.g., "5 servings" -> 5)
        quantity = int(''.join(filter(str.isdigit, quantity_str)))
        quantity_bonus = min(quantity * 2, 20)  # Max 20 bonus points
        bonus_points += quantity_bonus
    except:
        pass
    
    # Urgency bonus (if exists)
    urgency = listing.get('urgency', '').lower()
    urgency_bonuses = {
        'immediate': 10,
        'today': 7,
        'this_week': 5,
        'this_month': 3
    }
    bonus_points += urgency_bonuses.get(urgency, 0)
    
    total_points = base_points + bonus_points
    
    print(f"💎 Reward calculation: Base({base_points}) + Bonus({bonus_points}) = {total_points} points")
    
    return total_points

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
        if 'rewardPoints' in kwargs:
            notification['rewardPoints'] = kwargs['rewardPoints']
        if 'rating' in kwargs:
            notification['rating'] = kwargs['rating']
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
        if data['userType'].lower() not in ['donor', 'receiver', 'driver']:
            return jsonify({
                'success': False,
                'message': 'Invalid user type. Must be donor, receiver, or driver'
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
            'is_active': True,
            'rewardPoints': 0,  # Initialize reward points for receivers
            'totalOrdersReceived': 0,  # Track total orders received
            'rating': 0.0,  # Average rating for donors
            'totalRatings': 0,  # Total number of ratings received
            'ratingSum': 0  # Sum of all ratings (for calculating average)
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
                    'userType': data['userType'].lower(),
                    'rewardPoints': 0,
                    'totalOrdersReceived': 0,
                    'rating': 0.0,
                    'totalRatings': 0
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
                    'userType': user.get('userType', user.get('user_type', 'donor')),
                    'rewardPoints': user.get('rewardPoints', 0),
                    'totalOrdersReceived': user.get('totalOrdersReceived', 0),
                    'rating': user.get('rating', 0.0),
                    'totalRatings': user.get('totalRatings', 0)
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
        
        # Convert ObjectId to string and add donor rating info
        for listing in listings:
            listing['_id'] = str(listing['_id'])
            if 'createdAt' in listing:
                listing['createdAt'] = listing['createdAt'].isoformat()
            if 'updatedAt' in listing:
                listing['updatedAt'] = listing['updatedAt'].isoformat()
            
            # Add donor rating information
            if 'userId' in listing:
                from bson import ObjectId
                donor = users_collection.find_one({'_id': ObjectId(listing['userId'])})
                if donor:
                    listing['donorRating'] = donor.get('rating', 0.0)
                    listing['donorTotalRatings'] = donor.get('totalRatings', 0)
        
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
                
                # Award reward points when order is delivered
                if new_status == 'delivered':
                    reward_points = calculate_reward_points(listing)
                    users_collection.update_one(
                        {'_id': ObjectId(listing.get('claimedBy'))},
                        {
                            '$inc': {
                                'rewardPoints': reward_points,
                                'totalOrdersReceived': 1
                            }
                        }
                    )
                    
                    # Create reward notification for receiver
                    create_notification(
                        listing.get('claimedBy'),
                        'reward_earned',
                        '🎉 Reward Points Earned!',
                        f'You earned {reward_points} points for receiving this order!',
                        listingId=listing_id,
                        rewardPoints=reward_points
                    )
                    
                    print(f'✅ Awarded {reward_points} points to receiver {receiver["name"]}')
        
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

# ============= DRIVER ENDPOINTS =============

@app.route('/api/driver/available-orders', methods=['GET'])
@token_required
def get_available_orders_for_drivers(current_user):
    """Get all approved orders available for drivers to claim for delivery"""
    try:
        # Check if user is a driver
        if current_user.get('userType', '').lower() != 'driver':
            return jsonify({
                'success': False,
                'message': 'Only drivers can access this endpoint'
            }), 403
        
        # Get all approved orders that don't have a driver assigned yet
        available_orders = list(listings_collection.find({
            'orderStatus': 'approved',
            'claimedBy': {'$exists': True},  # Must be claimed by a receiver
            '$or': [
                {'driverId': {'$exists': False}},  # No driver assigned yet
                {'driverId': None}  # Driver field is null
            ]
        }).sort('approvedAt', -1))
        
        # Convert ObjectId to string and format dates
        for order in available_orders:
            order['_id'] = str(order['_id'])
            if 'createdAt' in order:
                order['createdAt'] = order['createdAt'].isoformat()
            if 'updatedAt' in order:
                order['updatedAt'] = order['updatedAt'].isoformat()
            if 'claimedAt' in order:
                order['claimedAt'] = order['claimedAt'].isoformat()
            if 'approvedAt' in order:
                order['approvedAt'] = order['approvedAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'orders': available_orders,
                'count': len(available_orders)
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/driver/claim-delivery/<order_id>', methods=['POST'])
@token_required
def claim_delivery(current_user, order_id):
    """Driver claims an approved order for delivery"""
    try:
        from bson import ObjectId
        
        # Check if user is a driver
        if current_user.get('userType', '').lower() != 'driver':
            return jsonify({
                'success': False,
                'message': 'Only drivers can claim deliveries'
            }), 403
        
        driver_id = str(current_user['_id'])
        
        # Check if order exists and is approved
        order = listings_collection.find_one({'_id': ObjectId(order_id)})
        
        if not order:
            return jsonify({
                'success': False,
                'message': 'Order not found'
            }), 404
        
        if order.get('orderStatus') != 'approved':
            return jsonify({
                'success': False,
                'message': f'Order must be approved to claim. Current status: {order.get("orderStatus")}'
            }), 400
        
        if order.get('driverId'):
            return jsonify({
                'success': False,
                'message': 'This order has already been claimed by another driver'
            }), 400
        
        # Assign driver to order and update status to in_transit
        listings_collection.update_one(
            {'_id': ObjectId(order_id)},
            {
                '$set': {
                    'driverId': driver_id,
                    'driverEmail': current_user['email'],
                    'driverName': current_user.get('name', current_user.get('full_name', '')),
                    'driverClaimedAt': datetime.now(),
                    'orderStatus': 'in_transit',
                    'inTransitAt': datetime.now(),
                    'updatedAt': datetime.now()
                }
            }
        )
        
        # Create notifications for donor and receiver
        donor = users_collection.find_one({'_id': ObjectId(order['userId'])})
        receiver = users_collection.find_one({'_id': ObjectId(order.get('claimedBy'))})
        
        driver_name = current_user.get('name', current_user.get('full_name', 'A driver'))
        
        if donor:
            create_notification(
                order['userId'],
                'order_status',
                '🚗 Driver Assigned',
                f'{driver_name} has picked up your donation and is on the way to deliver it!',
                listingId=order_id,
                orderStatus='in_transit',
                relatedUserId=driver_id,
                relatedUserName=driver_name
            )
        
        if receiver:
            create_notification(
                order.get('claimedBy'),
                'order_status',
                '🚗 Order is on the Way!',
                f'{driver_name} has picked up your order and is delivering it now!',
                listingId=order_id,
                orderStatus='in_transit',
                relatedUserId=driver_id,
                relatedUserName=driver_name
            )
        
        return jsonify({
            'success': True,
            'message': 'Delivery claimed successfully',
            'data': {
                'orderId': order_id,
                'orderStatus': 'in_transit'
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/driver/my-deliveries', methods=['GET'])
@token_required
def get_driver_deliveries(current_user):
    """Get all deliveries assigned to the current driver"""
    try:
        # Check if user is a driver
        if current_user.get('userType', '').lower() != 'driver':
            return jsonify({
                'success': False,
                'message': 'Only drivers can access this endpoint'
            }), 403
        
        driver_id = str(current_user['_id'])
        
        # Get all orders assigned to this driver
        deliveries = list(listings_collection.find({
            'driverId': driver_id
        }).sort('driverClaimedAt', -1))
        
        # Convert ObjectId to string and format dates
        for delivery in deliveries:
            delivery['_id'] = str(delivery['_id'])
            if 'createdAt' in delivery:
                delivery['createdAt'] = delivery['createdAt'].isoformat()
            if 'updatedAt' in delivery:
                delivery['updatedAt'] = delivery['updatedAt'].isoformat()
            if 'claimedAt' in delivery:
                delivery['claimedAt'] = delivery['claimedAt'].isoformat()
            if 'approvedAt' in delivery:
                delivery['approvedAt'] = delivery['approvedAt'].isoformat()
            if 'driverClaimedAt' in delivery:
                delivery['driverClaimedAt'] = delivery['driverClaimedAt'].isoformat()
            if 'inTransitAt' in delivery:
                delivery['inTransitAt'] = delivery['inTransitAt'].isoformat()
            if 'deliveredAt' in delivery:
                delivery['deliveredAt'] = delivery['deliveredAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'deliveries': deliveries,
                'count': len(deliveries)
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

# ============= END DRIVER ENDPOINTS =============

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

# ============= RATING ENDPOINTS =============

@app.route('/api/ratings/submit', methods=['POST'])
@token_required
def submit_rating(current_user):
    """Submit a rating for a donor after order completion"""
    try:
        from bson import ObjectId
        
        data = request.get_json()
        listing_id = data.get('listingId')
        donor_id = data.get('donorId')
        rating = data.get('rating')
        review = data.get('review', '')
        
        # Validate inputs
        if not listing_id or not donor_id or rating is None:
            return jsonify({
                'success': False,
                'message': 'listingId, donorId, and rating are required'
            }), 400
        
        if not isinstance(rating, (int, float)) or rating < 1 or rating > 5:
            return jsonify({
                'success': False,
                'message': 'Rating must be between 1 and 5'
            }), 400
        
        # Check if user is a receiver
        if current_user.get('userType', '').lower() != 'receiver':
            return jsonify({
                'success': False,
                'message': 'Only receivers can submit ratings'
            }), 403
        
        receiver_id = str(current_user['_id'])
        
        # Check if rating already exists for this order
        existing_rating = db['ratings'].find_one({
            'listingId': listing_id,
            'receiverId': receiver_id
        })
        
        if existing_rating:
            return jsonify({
                'success': False,
                'message': 'You have already rated this order'
            }), 400
        
        # Create rating document
        rating_doc = {
            'listingId': listing_id,
            'donorId': donor_id,
            'receiverId': receiver_id,
            'rating': float(rating),
            'review': review,
            'createdAt': datetime.now()
        }
        
        # Insert rating
        db['ratings'].insert_one(rating_doc)
        
        # Update donor's average rating
        donor = users_collection.find_one({'_id': ObjectId(donor_id)})
        if donor:
            current_rating_sum = donor.get('ratingSum', 0)
            current_total_ratings = donor.get('totalRatings', 0)
            
            new_rating_sum = current_rating_sum + rating
            new_total_ratings = current_total_ratings + 1
            new_average = new_rating_sum / new_total_ratings
            
            users_collection.update_one(
                {'_id': ObjectId(donor_id)},
                {
                    '$set': {
                        'rating': round(new_average, 2),
                        'totalRatings': new_total_ratings,
                        'ratingSum': new_rating_sum
                    }
                }
            )
            
            # Create notification for donor
            create_notification(
                donor_id,
                'rating_received',
                '⭐ New Rating Received!',
                f'You received a {rating}-star rating! Your new average is {round(new_average, 2)}⭐',
                listingId=listing_id,
                rating=rating
            )
        
        return jsonify({
            'success': True,
            'message': 'Rating submitted successfully',
            'data': {
                'rating': rating,
                'review': review
            }
        }), 201
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/ratings/check/<listing_id>', methods=['GET'])
@token_required
def check_rating_submitted(current_user, listing_id):
    """Check if user has already submitted rating for this listing"""
    try:
        receiver_id = str(current_user['_id'])
        
        rating = db['ratings'].find_one({
            'listingId': listing_id,
            'receiverId': receiver_id
        })
        
        return jsonify({
            'success': True,
            'hasRated': rating is not None,
            'rating': {
                'rating': rating.get('rating'),
                'review': rating.get('review'),
                'createdAt': rating.get('createdAt').isoformat()
            } if rating else None
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/api/ratings/donor/<donor_id>', methods=['GET'])
def get_donor_ratings(donor_id):
    """Get all ratings for a donor (public endpoint)"""
    try:
        from bson import ObjectId
        
        # Get donor info
        donor = users_collection.find_one({'_id': ObjectId(donor_id)})
        
        if not donor:
            return jsonify({
                'success': False,
                'message': 'Donor not found'
            }), 404
        
        # Get all ratings for this donor
        ratings = list(db['ratings'].find({'donorId': donor_id}).sort('createdAt', -1))
        
        # Convert ObjectId and dates
        for rating in ratings:
            rating['_id'] = str(rating['_id'])
            rating['createdAt'] = rating['createdAt'].isoformat()
        
        return jsonify({
            'success': True,
            'data': {
                'averageRating': donor.get('rating', 0.0),
                'totalRatings': donor.get('totalRatings', 0),
                'ratings': ratings
            }
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

# ============= FOOD DETECTION API =============

@app.route('/api/detect-food', methods=['POST'])
@token_required
def detect_food(current_user):
    """
    Detect food type from uploaded image using InceptionV3 model
    """
    try:
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'message': 'No image file provided'
            }), 400
        
        image_file = request.files['image']
        
        if image_file.filename == '':
            return jsonify({
                'success': False,
                'message': 'No image selected'
            }), 400
        
        # Check if model is loaded
        if FOOD_MODEL is None:
            return jsonify({
                'success': False,
                'message': 'Food detection model not available. Please ensure TensorFlow is installed.'
            }), 500
        
        # Read and preprocess image
        print("🔍 Processing image for food detection...")
        img = Image.open(io.BytesIO(image_file.read()))
        
        # Convert to RGB if needed (handle PNG with alpha channel, grayscale, etc.)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to model input size (299x299 for InceptionV3)
        img = img.resize(IMG_SIZE)
        
        # Convert to array and normalize to 0-1 range
        img_array = np.array(img, dtype=np.float32) / 255.0
        
        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)
        
        print(f"📊 Image preprocessed. Shape: {img_array.shape}")
        
        # Make prediction
        print("🤖 Running model prediction...")
        predictions = FOOD_MODEL.predict(img_array, verbose=0)
        
        # Get predicted class and confidence
        predicted_class_idx = int(np.argmax(predictions[0]))
        confidence = float(predictions[0][predicted_class_idx])
        
        # Get food name from classes
        if predicted_class_idx < len(FOOD_CLASSES):
            detected_food = FOOD_CLASSES[predicted_class_idx]
            # Format food name nicely (replace underscores with spaces, title case)
            detected_food = detected_food.replace('_', ' ').title()
        else:
            detected_food = "Unknown"
        
        print(f"✅ Detected: {detected_food} (confidence: {confidence:.2%})")
        
        return jsonify({
            'success': True,
            'data': {
                'foodName': detected_food,
                'confidence': round(confidence, 2),
                'message': 'Food detected successfully'
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Error in food detection: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'message': f'Food detection failed: {str(e)}'
        }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    
    # Print all registered routes for debugging
    print("\n" + "="*60)
    print("📋 REGISTERED ROUTES:")
    print("="*60)
    for rule in app.url_map.iter_rules():
        methods = ','.join(sorted(rule.methods - {'HEAD', 'OPTIONS'}))
        print(f"{rule.endpoint:30s} {methods:15s} {rule.rule}")
    print("="*60 + "\n")
    
    app.run(host='0.0.0.0', port=port, debug=True, use_reloader=False)
