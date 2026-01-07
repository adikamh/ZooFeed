import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/animal_model.dart';

class JadwalMakanScreen extends StatefulWidget {
  final String zooId;

  const JadwalMakanScreen({super.key, required this.zooId});

  @override
  State<JadwalMakanScreen> createState() => _JadwalMakanScreenState();
}

class _JadwalMakanScreenState extends State<JadwalMakanScreen> {
  final List<Map<String, dynamic>> _jadwalHarian = [
    {'waktu': '06:00', 'binatang': [], 'color': Colors.blue[50]},
    {'waktu': '07:00', 'binatang': [], 'color': Colors.blue[100]},
    {'waktu': '08:00', 'binatang': [], 'color': Colors.blue[50]},
    {'waktu': '09:00', 'binatang': [], 'color': Colors.blue[100]},
    {'waktu': '10:00', 'binatang': [], 'color': Colors.blue[50]},
    {'waktu': '11:00', 'binatang': [], 'color': Colors.blue[100]},
    {'waktu': '12:00', 'binatang': [], 'color': Colors.blue[50]},
    {'waktu': '13:00', 'binatang': [], 'color': Colors.blue[100]},
    {'waktu': '14:00', 'binatang': [], 'color': Colors.blue[50]},
    {'waktu': '15:00', 'binatang': [], 'color': Colors.blue[100]},
    {'waktu': '16:00', 'binatang': [], 'color': Colors.blue[50]},
    {'waktu': '17:00', 'binatang': [], 'color': Colors.blue[100]},
    {'waktu': '18:00', 'binatang': [], 'color': Colors.blue[50]},
    {'waktu': '19:00', 'binatang': [], 'color': Colors.blue[100]},
    {'waktu': '20:00', 'binatang': [], 'color': Colors.blue[50]},
  ];

  List<AnimalModel> _animals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('zoo_id', isEqualTo: widget.zooId)
          .where('is_active', isEqualTo: true)
          .get();

      final animals = snapshot.docs
          .map((doc) => AnimalModel.fromFirestore(doc))
          .toList();

      // Reset jadwal
      for (var jadwal in _jadwalHarian) {
        jadwal['binatang'] = [];
      }

      // Group animals by feeding time
      for (var animal in animals) {
        if (animal.feedingSchedule.contains(',')) {
          // Multiple times (e.g., "08:00, 12:00, 16:00")
          final times = animal.feedingSchedule.split(',');
          for (var time in times) {
            final trimmedTime = time.trim();
            _addAnimalToSchedule(animal, trimmedTime);
          }
        } else {
          // Single time or schedule description
          if (animal.feedingSchedule.contains('08:00') ||
              animal.feedingSchedule.contains('pagi')) {
            _addAnimalToSchedule(animal, '08:00');
          }
          if (animal.feedingSchedule.contains('12:00') ||
              animal.feedingSchedule.contains('siang')) {
            _addAnimalToSchedule(animal, '12:00');
          }
          if (animal.feedingSchedule.contains('16:00') ||
              animal.feedingSchedule.contains('sore')) {
            _addAnimalToSchedule(animal, '16:00');
          }
        }
      }

      setState(() {
        _animals = animals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addAnimalToSchedule(AnimalModel animal, String waktu) {
    for (var jadwal in _jadwalHarian) {
      if (jadwal['waktu'] == waktu) {
        (jadwal['binatang'] as List).add(animal);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Makan Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAnimals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSchedule(),
    );
  }

  Widget _buildSchedule() {
    return ListView.builder(
      itemCount: _jadwalHarian.length,
      itemBuilder: (context, index) {
        final jadwal = _jadwalHarian[index];
        // Ensure we have a proper Dart List<AnimalModel>
        final rawList = jadwal['binatang'] ?? [];
        final binatang = List<AnimalModel>.from(
          (rawList is List ? rawList : []).whereType<AnimalModel>());
        final color = jadwal['color'] as Color?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: color,
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                jadwal['waktu'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              '${binatang.length} Binatang',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: binatang.isEmpty
                ? const Text('Tidak ada jadwal makan')
                : Text(
                    binatang
                        .take(2)
                        .map((a) => a.name)
                        .join(', ') +
                        (binatang.length > 2 ? '...' : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            children: binatang.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Tidak ada binatang yang makan pada jam ini',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ]
                : binatang
                    .map((animal) => _buildAnimalItem(animal))
                    .toList(),
          ),
        );
      },
    );
  }

  Widget _buildAnimalItem(AnimalModel animal) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: animal.statusColor,
        child: Icon(
          animal.statusIcon,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        animal.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${animal.species} - ${animal.enclosure}'),
      trailing: Chip(
        label: Text(
          animal.feedingSchedule.contains(',')
              ? '${animal.feedingSchedule.split(',').length}x'
              : '1x',
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: Colors.green[100],
      ),
    );
  }
}