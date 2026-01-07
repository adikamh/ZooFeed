import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import '../models/user_model.dart';

class AnimalDetailScreen extends StatefulWidget {
  final AnimalModel animal;
  final UserModel? currentUser;

  const AnimalDetailScreen({super.key, required this.animal, this.currentUser});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool _isLoading = false;

  Future<void> _markAsFed() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    try {
      await FirebaseFirestore.instance.collection('animals').doc(widget.animal.id).update({
        'last_fed_date': Timestamp.fromDate(now),
        'last_fed_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'fed_by_user_id': widget.currentUser?.uid ?? 'unknown',
        'feeding_status': 'fed',
        'missed_feeding_count': 0,
        'updated_at': Timestamp.fromDate(now),
      });

      // write a notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'zoo_id': widget.animal.zooId,
        'user_id': widget.currentUser?.uid ?? 'unknown',
        'type': 'feeding_event',
        'title': 'Hewan diberi makan',
        'message': '${widget.animal.name} diberi makan oleh ${widget.currentUser?.fullName ?? 'Staff'}',
        'animal_id': widget.animal.id,
        'priority': 'medium',
        'delivery_method': 'push',
        'is_read': false,
        'is_sent': false,
        'metadata': {'fed_by': widget.currentUser?.uid ?? 'unknown'},
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menandai sudah makan'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnimal() async {
    final should = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Binatang'),
        content: Text('Yakin ingin menghapus ${widget.animal.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (should != true) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('animals').doc(widget.animal.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Binatang dihapus'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.animal;
    final isKeeper = widget.currentUser?.role == 'keeper';
    final isAdmin = widget.currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Binatang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 32, backgroundColor: a.statusColor, child: Icon(a.statusIcon, color: Colors.white, size: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${a.species} — ${a.enclosure}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Jadwal: ${a.feedingScheduleDisplay}'),
            const SizedBox(height: 8),
            Text('Status: ${a.statusText}', style: TextStyle(color: a.statusColor)),
            const SizedBox(height: 8),
            Text('Terakhir makan: ${a.lastFedFormatted}'),
            const SizedBox(height: 12),
            if (a.notes != null) ...[
              const Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(a.notes!),
            ],
            const Spacer(),
            if (_isLoading) const LinearProgressIndicator(),
            Row(
              children: [
                if (isKeeper)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _markAsFed,
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Tandai Makan'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                if (isAdmin) ...[
                  ElevatedButton.icon(onPressed: () { Navigator.pop(context); }, icon: const Icon(Icons.edit), label: const Text('Edit')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: _isLoading ? null : _deleteAnimal, icon: const Icon(Icons.delete), label: const Text('Hapus'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
