import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class KeeperQuickReportScreen extends StatefulWidget {
  final UserModel currentUser;

  const KeeperQuickReportScreen({super.key, required this.currentUser});

  @override
  State<KeeperQuickReportScreen> createState() => _KeeperQuickReportScreenState();
}

class _KeeperQuickReportScreenState extends State<KeeperQuickReportScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi catatan laporan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('reports').add({
        'zoo_id': widget.currentUser.zooId,
        'keeper_id': widget.currentUser.uid,
        'report_date': DateTime(now.year, now.month, now.day),
        'notes': notes,
        'is_read_by_admin': false,
        'read_at': null,
        'is_sent': true,
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim laporan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Cepat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catatan Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan laporan singkat... (mis. kondisi hewan, kejadian, kebutuhan barang)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kirim Laporan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
