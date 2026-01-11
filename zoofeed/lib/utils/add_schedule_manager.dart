import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import '../models/user_model.dart';

/// Helper that shows a "Tambah Jadwal Pemberian Makan" dialog and
/// persists the schedule to Firestore. Returns a map with
/// { 'saved': bool, 'animalId': String?, 'schedule': String?, 'error': String? }
Future<Map<String, dynamic>> showAddScheduleAndSave(
    BuildContext context, List<AnimalModel> myAnimals, UserModel currentUser) async {
  if (myAnimals.isEmpty) {
    return {'saved': false, 'error': 'no_animals'};
  }

  String selectedAnimalId = myAnimals.first.id;
  final presetTimes = <String>[
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'
  ];
  final selectedTimes = <String>{};

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        void toggleTime(String t) {
          setState(() {
            if (selectedTimes.contains(t)) selectedTimes.remove(t);
            else selectedTimes.add(t);
          });
        }

        Future<void> pickCustomTime() async {
          final tod = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
          if (tod != null) {
            final hh = tod.hour.toString().padLeft(2, '0');
            final mm = tod.minute.toString().padLeft(2, '0');
            setState(() => selectedTimes.add('$hh:$mm'));
          }
        }

        return AlertDialog(
          title: const Text('Tambah Jadwal Pemberian Makan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedAnimalId,
                  items: myAnimals.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (v) => setState(() => selectedAnimalId = v ?? selectedAnimalId),
                  decoration: const InputDecoration(labelText: 'Pilih Hewan'),
                ),
                const SizedBox(height: 12),
                const Text('Pilih waktu (boleh lebih dari satu):'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presetTimes.map((t) {
                    final on = selectedTimes.contains(t);
                    return ChoiceChip(
                      label: Text(t),
                      selected: on,
                      onSelected: (_) => toggleTime(t),
                    );
                  }).toList()
                    ..add(ChoiceChip(
                      label: const Text('+ Tambah waktu'),
                      selected: false,
                      onSelected: (_) => pickCustomTime(),
                    )),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTimes.add('12:00');
                        });
                      },
                      child: const Text('1x'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTimes.addAll(['08:00', '16:00']);
                        });
                      },
                      child: const Text('2x'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTimes.addAll(['08:00', '12:00', '16:00']);
                        });
                      },
                      child: const Text('3x'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: selectedTimes.isEmpty ? null : () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        );
      });
    },
  );

  if (result != true) return {'saved': false};

  final animal = myAnimals.firstWhere((a) => a.id == selectedAnimalId, orElse: () => myAnimals.first);
  final timesList = selectedTimes.toList()..sort();
  final scheduleString = timesList.join(', ');

  try {
    final now = DateTime.now();
    await FirebaseFirestore.instance.collection('animals').doc(animal.id).update({
      'feeding_schedule': scheduleString,
      'updated_at': Timestamp.fromDate(now),
    });

    return {'saved': true, 'animalId': animal.id, 'schedule': scheduleString};
  } catch (e) {
    return {'saved': false, 'error': e.toString()};
  }
}
