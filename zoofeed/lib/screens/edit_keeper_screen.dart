import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditKeeperScreen extends StatefulWidget {
  final Map<String, String> keeper;

  const EditKeeperScreen({super.key, required this.keeper});

  @override
  State<EditKeeperScreen> createState() => _EditKeeperScreenState();
}

class _EditKeeperScreenState extends State<EditKeeperScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  String? _error;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.keeper['name'] ?? '');
    _phoneController = TextEditingController(text: widget.keeper['phone'] ?? '');
    _isActive = (widget.keeper['status'] ?? 'active') == 'active';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final keeperId = widget.keeper['id'];
    if (keeperId == null || keeperId.isEmpty) {
      setState(() => _error = 'ID keeper tidak tersedia');
      return;
    }

    if (_fullNameController.text.isEmpty) {
      setState(() => _error = 'Nama lengkap harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(keeperId).update({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'is_active': _isActive,
        'updated_at': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keeper berhasil diperbarui')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan perubahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Keeper'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: Colors.red[700])),
              ),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Nomor Telepon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status: '),
                const SizedBox(width: 8),
                DropdownButton<bool>(
                  value: _isActive,
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Aktif')),
                    DropdownMenuItem(value: false, child: Text('Nonaktif')),
                  ],
                  onChanged: (v) => setState(() => _isActive = v ?? true),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdate,
                    child: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
