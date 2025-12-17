import 'package:cloud_firestore/cloud_firestore.dart';

class ZooModel {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final Map<String, dynamic> notificationConfig;
  final DateTime createdAt;
  final DateTime updatedAt;

  ZooModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    required this.notificationConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ZooModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ZooModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'],
      phone: data['phone'],
      notificationConfig: Map<String, dynamic>.from(data['notification_config'] ?? {
        'feeding_reminder_times': ['08:00', '12:00', '16:00'],
        'reminder_before_minutes': 15,
        'daily_summary_time': '17:00',
        'missed_feeding_threshold_hours': 24,
      }),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      'notification_config': notificationConfig,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  List<String> get feedingReminderTimes {
    final times = notificationConfig['feeding_reminder_times'];
    if (times is List) {
      return List<String>.from(times);
    }
    return ['08:00', '12:00', '16:00'];
  }

  int get reminderBeforeMinutes => notificationConfig['reminder_before_minutes'] ?? 15;
  String get dailySummaryTime => notificationConfig['daily_summary_time'] ?? '17:00';
  int get missedFeedingThreshold => notificationConfig['missed_feeding_threshold_hours'] ?? 24;
}