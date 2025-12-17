import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String zooId;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? animalId;
  final String priority;
  final String deliveryMethod;
  final bool isRead;
  final bool isSent;
  final DateTime? scheduledTime;
  final DateTime? sentTime;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.zooId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.animalId,
    required this.priority,
    required this.deliveryMethod,
    required this.isRead,
    required this.isSent,
    this.scheduledTime,
    this.sentTime,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      zooId: data['zoo_id'] ?? '',
      userId: data['user_id'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      animalId: data['animal_id'],
      priority: data['priority'] ?? 'medium',
      deliveryMethod: data['delivery_method'] ?? 'push',
      isRead: data['is_read'] ?? false,
      isSent: data['is_sent'] ?? false,
      scheduledTime: data['scheduled_time'] != null 
          ? (data['scheduled_time'] as Timestamp).toDate()
          : null,
      sentTime: data['sent_time'] != null 
          ? (data['sent_time'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zoo_id': zooId,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      if (animalId != null) 'animal_id': animalId,
      'priority': priority,
      'delivery_method': deliveryMethod,
      'is_read': isRead,
      'is_sent': isSent,
      if (scheduledTime != null) 'scheduled_time': Timestamp.fromDate(scheduledTime!),
      if (sentTime != null) 'sent_time': Timestamp.fromDate(sentTime!),
      'metadata': metadata,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  bool get isFeedingReminder => type == 'feeding_reminder';
  bool get isMissedFeeding => type == 'missed_feeding';
  bool get isDailySummary => type == 'daily_summary';
  bool get isSystemAlert => type == 'system_alert';

  bool get isHighPriority => priority == 'high';
  bool get isMediumPriority => priority == 'medium';
  bool get isLowPriority => priority == 'low';

  bool get isPushNotification => deliveryMethod == 'push';
  bool get isEmailNotification => deliveryMethod == 'email';
  bool get isBothNotification => deliveryMethod == 'both';

  // Format untuk display
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes}m yang lalu';
    if (difference.inDays < 1) return '${difference.inHours}j yang lalu';
    if (difference.inDays < 7) return '${difference.inDays}h yang lalu';
    
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Icon berdasarkan type
  IconData get icon {
    switch (type) {
      case 'feeding_reminder':
        return Icons.access_time;
      case 'missed_feeding':
        return Icons.warning;
      case 'daily_summary':
        return Icons.bar_chart;
      case 'system_alert':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  // Color berdasarkan type
  Color get color {
    switch (type) {
      case 'feeding_reminder':
        return Colors.orange;
      case 'missed_feeding':
        return Colors.red;
      case 'daily_summary':
        return Colors.green;
      case 'system_alert':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Color berdasarkan priority
  Color get priorityColor {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Mark as read
  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      zooId: zooId,
      userId: userId,
      type: type,
      title: title,
      message: message,
      animalId: animalId,
      priority: priority,
      deliveryMethod: deliveryMethod,
      isRead: true,
      isSent: isSent,
      scheduledTime: scheduledTime,
      sentTime: sentTime,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}