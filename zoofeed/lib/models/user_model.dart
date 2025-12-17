import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String zooId;
  final String? phone;
  final Map<String, dynamic> notificationSettings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.zooId,
    this.phone,
    Map<String, dynamic>? notificationSettings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : notificationSettings = notificationSettings ?? {
       'push_enabled': true,
       'email_enabled': true,
       'feeding_reminders': true,
       'daily_summary': true,
     };

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['full_name'] ?? '',
      role: data['role'] ?? '',
      zooId: data['zoo_id'] ?? '',
      phone: data['phone'],
      notificationSettings: data['notification_settings'] != null
          ? Map<String, dynamic>.from(data['notification_settings'])
          : null,
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'full_name': fullName,
      'role': role,
      'zoo_id': zooId,
      'phone': phone,
      'notification_settings': notificationSettings,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? role,
    String? zooId,
    String? phone,
    Map<String, dynamic>? notificationSettings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      zooId: zooId ?? this.zooId,
      phone: phone ?? this.phone,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}