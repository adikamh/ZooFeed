import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingHistoryModel {
  final String id;
  final String animalId;
  final String animalName;
  final String species;
  final String enclosure;
  final String fedByUserId;
  final String feedingStatus;
  final String notes;
  final DateTime fedAt;

  FeedingHistoryModel({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.species,
    required this.enclosure,
    required this.fedByUserId,
    required this.feedingStatus,
    required this.notes,
    required this.fedAt,
  });

  factory FeedingHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FeedingHistoryModel(
      id: doc.id,
      animalId: data['animal_id'],
      animalName: data['animal_name'],
      species: data['species'],
      enclosure: data['enclosure'],
      fedByUserId: data['fed_by_user_id'],
      feedingStatus: data['feeding_status'],
      notes: data['notes'] ?? '',
      fedAt: (data['fed_at'] as Timestamp).toDate(),
    );
  }
}
