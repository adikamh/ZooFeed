import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnimalModel {
  final String id;
  final String zooId;
  final String name;
  final String species;
  final String enclosure;
  final String feedingSchedule;
  final DateTime? lastFedDate;
  final DateTime? lastFedTime;
  final String? fedByUserId;
  final String feedingStatus;
  final int missedFeedingCount;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnimalModel({
    required this.id,
    required this.zooId,
    required this.name,
    required this.species,
    required this.enclosure,
    required this.feedingSchedule,
    this.lastFedDate,
    this.lastFedTime,
    this.fedByUserId,
    required this.feedingStatus,
    required this.missedFeedingCount,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnimalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return AnimalModel(
      id: doc.id,
      zooId: data['zoo_id'] ?? '',
      name: data['name'] ?? '',
      species: data['species'] ?? '',
      enclosure: data['enclosure'] ?? '',
      feedingSchedule: data['feeding_schedule'] ?? '2x sehari',
      lastFedDate: data['last_fed_date'] != null 
          ? DateTime.parse(data['last_fed_date'])
          : null,
      lastFedTime: data['last_fed_time'] != null 
          ? DateTime.parse('1970-01-01 ${data['last_fed_time']}')
          : null,
      fedByUserId: data['fed_by_user_id'],
      feedingStatus: data['feeding_status'] ?? 'hungry',
      missedFeedingCount: data['missed_feeding_count'] ?? 0,
      notes: data['notes'],
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zoo_id': zooId,
      'name': name,
      'species': species,
      'enclosure': enclosure,
      'feeding_schedule': feedingSchedule,
      if (lastFedDate != null) 'last_fed_date': lastFedDate!.toIso8601String().split('T')[0],
      if (lastFedTime != null) 'last_fed_time': '${lastFedTime!.hour.toString().padLeft(2, '0')}:${lastFedTime!.minute.toString().padLeft(2, '0')}',
      if (fedByUserId != null) 'fed_by_user_id': fedByUserId,
      'feeding_status': feedingStatus,
      'missed_feeding_count': missedFeedingCount,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  bool get isFed => feedingStatus == 'fed';
  bool get isHungry => feedingStatus == 'hungry';
  
  bool get hasMissedFeeding => missedFeedingCount > 0;
  bool get needsUrgentAttention => missedFeedingCount >= 2; // 2 kali terlewat

  // Waktu terakhir makan dalam format yang mudah dibaca
  String get lastFedFormatted {
    if (lastFedDate == null) return 'Belum pernah makan';
    
    final now = DateTime.now();
    final lastFed = DateTime(
      lastFedDate!.year,
      lastFedDate!.month,
      lastFedDate!.day,
      lastFedTime?.hour ?? 0,
      lastFedTime?.minute ?? 0,
    );
    
    final difference = now.difference(lastFed);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inDays} hari yang lalu';
    }
  }

  // Status color untuk UI
  Color get statusColor {
    if (!isActive) return Colors.grey;
    
    if (isFed) return Colors.green;
    if (needsUrgentAttention) return Colors.red;
    if (isHungry) return Colors.orange;
    
    return Colors.grey;
  }

  // Status text untuk UI
  String get statusText {
    if (!isActive) return 'Nonaktif';
    
    if (isFed) return 'Sudah Makan';
    if (needsUrgentAttention) return 'Perlu Perhatian!';
    if (isHungry) return 'Belum Makan';
    
    return 'Tidak Diketahui';
  }

  // Icon berdasarkan status
  IconData get statusIcon {
    if (!isActive) return Icons.block;
    
    if (isFed) return Icons.check_circle;
    if (needsUrgentAttention) return Icons.warning;
    if (isHungry) return Icons.error_outline;
    
    return Icons.help;
  }

  // Jadwal makan dalam teks
  String get feedingScheduleText {
    switch (feedingSchedule) {
      case '1x':
        return '1x sehari';
      case '2x':
        return '2x sehari';
      case '3x':
        return '3x sehari';
      default:
        return feedingSchedule;
    }
  }

  // Update status setelah makan
  AnimalModel markAsFed(String userId) {
    final now = DateTime.now();
    
    return AnimalModel(
      id: id,
      zooId: zooId,
      name: name,
      species: species,
      enclosure: enclosure,
      feedingSchedule: feedingSchedule,
      lastFedDate: now,
      lastFedTime: now,
      fedByUserId: userId,
      feedingStatus: 'fed',
      missedFeedingCount: 0, // Reset counter
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  // Update status menjadi lapar
  AnimalModel markAsHungry() {
    return AnimalModel(
      id: id,
      zooId: zooId,
      name: name,
      species: species,
      enclosure: enclosure,
      feedingSchedule: feedingSchedule,
      lastFedDate: lastFedDate,
      lastFedTime: lastFedTime,
      fedByUserId: fedByUserId,
      feedingStatus: 'hungry',
      missedFeedingCount: missedFeedingCount + 1,
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Check if animal should be fed based on schedule
  bool get shouldBeFedNow {
    if (!isActive || isFed) return false;
    
    final now = DateTime.now();
    final hour = now.hour;
    
    // Default feeding times based on schedule
    switch (feedingSchedule) {
      case '1x':
        return hour == 12; // Siang hari
      case '2x':
        return hour == 8 || hour == 16; // Pagi & Sore
      case '3x':
        return hour == 8 || hour == 12 || hour == 16; // Pagi, Siang, Sore
      default:
        return false;
    }
  }
}