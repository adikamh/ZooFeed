import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../models/user_model.dart';

/// Centralized logic for feeding an animal: update animal doc, create notification,
/// and add a feeding_history entry.
Future<Map<String, dynamic>> feedAnimalAndRecord(
    AnimalModel animal, UserModel user,
    {String? notes}) async {
  try {
    final now = DateTime.now();

    await FirebaseFirestore.instance.collection('animals').doc(animal.id).update({
      'last_fed_date': Timestamp.fromDate(now),
      'last_fed_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'fed_by_user_id': user.uid,
      'feeding_status': 'fed',
      'missed_feeding_count': 0,
      'updated_at': Timestamp.fromDate(now),
    });

    final notif = {
      'zoo_id': animal.zooId,
      'user_id': user.uid,
      'type': 'feeding_event',
      'title': 'Hewan diberi makan',
      'message': '${animal.name} diberi makan oleh ${user.fullName}',
      'animal_id': animal.id,
      'priority': 'medium',
      'delivery_method': 'push',
      'is_read': false,
      'is_sent': false,
      'metadata': {'fed_by': user.uid},
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    };

    await FirebaseFirestore.instance.collection('notifications').add(notif);

    final history = {
      'zoo_id': animal.zooId,
      'animal_id': animal.id,
      'animal_name': animal.name,
      'animal_species': animal.species,
      'time': Timestamp.fromDate(now),
      'notes': notes ?? '',
      'fed_by': user.uid,
      'status': 'completed',
    };

    await FirebaseFirestore.instance.collection('feeding_history').add(history);

    return {'success': true};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
