# Notification Backend Implementation for Flask/Python

"""
This file contains the implementation for notification endpoints.
Add these routes to your Flask application (app.py or a separate blueprint).
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, timedelta
from bson import ObjectId

# Create a blueprint for notifications
notifications_bp = Blueprint('notifications', __name__, url_prefix='/api/notifications')

# MongoDB collections (assuming you have db setup)
# from your_db_module import db
# notifications_collection = db['notifications']
# users_collection = db['users']

@notifications_bp.route('/', methods=['GET'])
@jwt_required()
def get_notifications():
    """Get all notifications for the current user"""
    try:
        current_user_id = get_jwt_identity()
        
        # Query notifications for the user, sorted by creation date (newest first)
        notifications = list(notifications_collection.find({
            'userId': ObjectId(current_user_id)
        }).sort('createdAt', -1).limit(100))
        
        # Count unread notifications
        unread_count = notifications_collection.count_documents({
            'userId': ObjectId(current_user_id),
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


@notifications_bp.route('/unread-count', methods=['GET'])
@jwt_required()
def get_unread_count():
    """Get count of unread notifications"""
    try:
        current_user_id = get_jwt_identity()
        
        count = notifications_collection.count_documents({
            'userId': ObjectId(current_user_id),
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


@notifications_bp.route('/<notification_id>/read', methods=['PUT'])
@jwt_required()
def mark_as_read(notification_id):
    """Mark a notification as read"""
    try:
        current_user_id = get_jwt_identity()
        
        # Update the notification if it belongs to the current user
        result = notifications_collection.update_one(
            {
                '_id': ObjectId(notification_id),
                'userId': ObjectId(current_user_id)
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


@notifications_bp.route('/mark-all-read', methods=['PUT'])
@jwt_required()
def mark_all_as_read():
    """Mark all notifications as read for the current user"""
    try:
        current_user_id = get_jwt_identity()
        
        result = notifications_collection.update_many(
            {
                'userId': ObjectId(current_user_id),
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


@notifications_bp.route('/<notification_id>', methods=['DELETE'])
@jwt_required()
def delete_notification(notification_id):
    """Delete a notification"""
    try:
        current_user_id = get_jwt_identity()
        
        result = notifications_collection.delete_one({
            '_id': ObjectId(notification_id),
            'userId': ObjectId(current_user_id)
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


# Helper function to create notifications
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
        notification = {
            'userId': ObjectId(user_id),
            'type': notification_type,
            'title': title,
            'message': message,
            'isRead': False,
            'createdAt': datetime.utcnow()
        }
        
        # Add optional fields
        if 'listingId' in kwargs and kwargs['listingId']:
            notification['listingId'] = ObjectId(kwargs['listingId'])
        if 'orderId' in kwargs and kwargs['orderId']:
            notification['orderId'] = ObjectId(kwargs['orderId'])
        if 'relatedUserId' in kwargs and kwargs['relatedUserId']:
            notification['relatedUserId'] = ObjectId(kwargs['relatedUserId'])
        if 'relatedUserName' in kwargs:
            notification['relatedUserName'] = kwargs['relatedUserName']
        if 'orderStatus' in kwargs:
            notification['orderStatus'] = kwargs['orderStatus']
        if 'metadata' in kwargs:
            notification['metadata'] = kwargs['metadata']
        
        result = notifications_collection.insert_one(notification)
        notification['_id'] = result.inserted_id
        
        return notification
        
    except Exception as e:
        print(f"Error creating notification: {str(e)}")
        return None


# Example: Creating notifications when order status changes
def notify_order_status_change(order, old_status, new_status):
    """
    Create notifications when an order status changes
    
    Args:
        order: The order document
        old_status: Previous order status
        new_status: New order status
    """
    try:
        # Get user information
        donor = users_collection.find_one({'_id': order['donorId']})
        receiver = users_collection.find_one({'_id': order['receiverId']})
        
        if not donor or not receiver:
            return
        
        # Notification for receiver
        receiver_messages = {
            'approved': f"Your order has been approved by {donor.get('name', 'the donor')}",
            'in_transit': "Your order is now in transit",
            'out_for_delivery': "Your order is out for delivery",
            'delivered': "Your order has been delivered successfully",
            'completed': "Your order has been completed. Thank you for using CrumbChain!"
        }
        
        if new_status in receiver_messages:
            create_notification(
                user_id=str(order['receiverId']),
                notification_type='order_status',
                title=f"Order {new_status.replace('_', ' ').title()}",
                message=receiver_messages[new_status],
                listingId=str(order.get('listingId')),
                orderId=str(order['_id']),
                orderStatus=new_status,
                relatedUserId=str(donor['_id']),
                relatedUserName=donor.get('name', 'Donor')
            )
        
        # Notification for donor
        donor_messages = {
            'in_transit': f"{receiver.get('name', 'The receiver')} has picked up the order",
            'delivered': f"Your donation has been delivered to {receiver.get('name', 'the receiver')}",
            'completed': "Your donation order has been completed successfully"
        }
        
        if new_status in donor_messages:
            create_notification(
                user_id=str(order['donorId']),
                notification_type='order_status',
                title=f"Order {new_status.replace('_', ' ').title()}",
                message=donor_messages[new_status],
                listingId=str(order.get('listingId')),
                orderId=str(order['_id']),
                orderStatus=new_status,
                relatedUserId=str(receiver['_id']),
                relatedUserName=receiver.get('name', 'Receiver')
            )
            
    except Exception as e:
        print(f"Error creating order status notifications: {str(e)}")


def notify_listing_claimed(listing, claimant):
    """
    Notify donor when their listing is claimed
    
    Args:
        listing: The listing document
        claimant: The user who claimed the listing
    """
    try:
        create_notification(
            user_id=str(listing['userId']),
            notification_type='approval_request',
            title='New Order Request',
            message=f"{claimant.get('name', 'Someone')} wants to claim your food donation \"{listing.get('foodType', 'item')}\"",
            listingId=str(listing['_id']),
            relatedUserId=str(claimant['_id']),
            relatedUserName=claimant.get('name', 'User'),
            orderStatus='pending_approval'
        )
    except Exception as e:
        print(f"Error creating listing claimed notification: {str(e)}")


# Cleanup old notifications (run this periodically)
def cleanup_old_notifications(days=30):
    """Delete notifications older than specified days"""
    try:
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        result = notifications_collection.delete_many({
            'createdAt': {'$lt': cutoff_date}
        })
        print(f"Deleted {result.deleted_count} old notifications")
        return result.deleted_count
    except Exception as e:
        print(f"Error cleaning up notifications: {str(e)}")
        return 0


# Register the blueprint in your main app.py:
"""
from notifications import notifications_bp
app.register_blueprint(notifications_bp)
"""
