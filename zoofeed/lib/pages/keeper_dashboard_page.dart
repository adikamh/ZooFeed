import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/animal_model.dart';
import '../../models/notification_model.dart';
import '../screens/animal_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/keeper_quick_report_screen.dart';
import '../screens/keeper_reports_history_screen.dart';

const EdgeInsets _kListTilePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

class KeeperDashboardPage extends StatefulWidget {
  final UserModel user;

  const KeeperDashboardPage({super.key, required this.user});

  @override
  State<KeeperDashboardPage> createState() => _KeeperDashboardPageState();
}

class _KeeperDashboardPageState extends State<KeeperDashboardPage> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;
  List<AnimalModel> _myAnimals = [];
  List<AnimalModel> _todaysTasks = [];
  List<NotificationModel> _notifications = [];
  List<Map<String, dynamic>> _feedingHistory = [];

  StreamSubscription? _animalsSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _historySub;

  @override
  void initState() {
    super.initState();
    _unreadNotifications = _notifications.where((n) => !n.isRead).length;
    // Listen to animals in the same zoo and filter assigned to this keeper if field exists
    _animalsSub = FirebaseFirestore.instance
        .collection('animals')
        .where('zoo_id', isEqualTo: widget.user.zooId)
        .snapshots()
        .listen((snap) {
      final docs = snap.docs;
      final all = <AnimalModel>[];
      for (final d in docs) {
        try {
          all.add(AnimalModel.fromFirestore(d));
        } catch (_) {
          // ignore parse errors
        }
      }

      // some documents may have 'assigned_keeper_id' in raw data - filter if present
      final my = <AnimalModel>[];
      for (final d in docs) {
        final data = d.data() as Map<String, dynamic>;
        final assigned = data['assigned_keeper_id'];
        if (assigned != null) {
          if (assigned == widget.user.uid) {
            try {
              my.add(AnimalModel.fromFirestore(d));
            } catch (_) {}
          }
        }
      }

      setState(() {
        _myAnimals = my.isNotEmpty ? my : all; // fallback to all if no assignment
        _todaysTasks = _myAnimals.where((a) => a.shouldBeFedNow && a.isHungry).toList();
      });
    });

    // Notifications for this keeper
    _notificationsSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('zoo_id', isEqualTo: widget.user.zooId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
      setState(() {
        // show notifications relevant to user or zoo
        _notifications = list.where((n) => n.userId == widget.user.uid || n.zooId == widget.user.zooId).toList();
        _unreadNotifications = _notifications.where((n) => !n.isRead).length;
      });
    });

    // Load feeding history for this keeper
    _historySub = FirebaseFirestore.instance
        .collection('feeding_history')
        .where('fed_by', isEqualTo: widget.user.uid)
        .orderBy('time', descending: true)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {
          'animal_id': data['animal_id'],
          'animal_name': data['animal_name'],
          'animal_species': data['animal_species'],
          'time': (data['time'] as Timestamp).toDate(),
          'notes': data['notes'],
          'status': data['status'],
        };
      }).toList();
      setState(() => _feedingHistory = list);
    });
  }

  @override
  void dispose() {
    _animalsSub?.cancel();
    _notificationsSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }

  List<Widget> get _dashboardTabs => [
        StaffHomeTab(
          user: widget.user,
          myAnimals: _myAnimals,
          todaysTasks: _todaysTasks,
          notifications: _notifications,
        ),
        FeedingTasksTab(
          todaysTasks: _todaysTasks,
          onFeedAnimal: _handleFeedAnimal,
          currentUser: widget.user,
        ),
        MyAnimalsTab(
          myAnimals: _myAnimals,
          onFeedAnimal: _handleFeedAnimal,
          currentUser: widget.user,
        ),
        FeedingHistoryTab(history: _feedingHistory),
        StaffNotificationsTab(notifications: _notifications),
      ];

  final List<String> _tabTitles = [
    'Dashboard',
    'Tugas Hari Ini',
    'Hewan Saya',
    'Riwayat',
    'Notifikasi',
  ];

  Future<void> _handleFeedAnimal(AnimalModel animal) async {
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FeedingDialog(animal: animal),
    );

    if (result != null && result['fed'] == true) {
      setState(() {
        final index = _todaysTasks.indexWhere((a) => a.id == animal.id);
        if (index != -1) {
          _todaysTasks[index] = animal.markAsFed(widget.user.uid);
        }
      });

      // Simpan perubahan ke Firestore
      try {
        final now = DateTime.now();
        await FirebaseFirestore.instance
            .collection('animals')
            .doc(animal.id)
            .update({
          'last_fed_date': Timestamp.fromDate(now),
          'last_fed_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          'fed_by_user_id': widget.user.uid,
          'feeding_status': 'fed',
          'missed_feeding_count': 0,
          'updated_at': Timestamp.fromDate(now),
        });

        // Tambah notifikasi
        final notif = {
          'zoo_id': animal.zooId,
          'user_id': widget.user.uid,
          'type': 'feeding_event',
          'title': 'Hewan diberi makan',
          'message': '${animal.name} diberi makan oleh ${widget.user.fullName}',
          'animal_id': animal.id,
          'priority': 'medium',
          'delivery_method': 'push',
          'is_read': false,
          'is_sent': false,
          'metadata': {'fed_by': widget.user.uid},
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        };

        await FirebaseFirestore.instance.collection('notifications').add(notif);

        // Tambah riwayat pemberian makan
        final history = {
          'zoo_id': animal.zooId,
          'animal_id': animal.id,
          'animal_name': animal.name,
          'animal_species': animal.species,
          'time': Timestamp.fromDate(now),
          'notes': result['notes'] ?? '',
          'fed_by': widget.user.uid,
          'status': 'completed',
        };
        await FirebaseFirestore.instance.collection('feeding_history').add(history);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${animal.name} berhasil ditandai sudah makan'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan ke database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.logout();

        if (!mounted) return;
        // Ensure we return to the login screen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedIndex]),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedIndex = 4),
                icon: const Icon(Icons.notifications_outlined),
                padding: const EdgeInsets.all(8),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _dashboardTabs[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _selectedIndex == 1 ? _buildQuickFeedButton() : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          
          UserAccountsDrawerHeader(
            accountName: Text(widget.user.fullName),
            accountEmail: Text(widget.user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                widget.user.fullName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
          ),
          _buildDrawerItem(
            icon: Icons.assignment,
            title: 'Tugas Hari Ini',
            index: 1,
            badge: _todaysTasks.length.toString(),
          ),
          _buildDrawerItem(
            icon: Icons.pets,
            title: 'Hewan Saya',
            index: 2,
            badge: _myAnimals.length.toString(),
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: 'Riwayat',
            index: 3,
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Notifikasi',
            index: 4,
            badge: _unreadNotifications > 0 ? '$_unreadNotifications' : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Saya'),
            onTap: () {
              Navigator.pop(context);
              
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Row(
        children: [
          Text(title),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

Widget _buildBottomNavBar() {
  return BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (index) => setState(() => _selectedIndex = index),
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.blue,
    unselectedItemColor: Colors.grey,
    selectedFontSize: 12,
    unselectedFontSize: 12,
    iconSize: 24,
    items: [
      BottomNavigationBarItem(
        icon: Container(
          height: 24,
          width: 24,
          child: const Icon(Icons.dashboard),
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Container(
          height: 24,
          width: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.assignment),
              if (_todaysTasks.isNotEmpty)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
        label: 'Tugas',
      ),
      BottomNavigationBarItem(
        icon: Container(
          height: 24,
          width: 24,
          child: const Icon(Icons.pets),
        ),
        label: 'Hewan',
      ),
      BottomNavigationBarItem(
        icon: Container(
          height: 24,
          width: 24,
          child: const Icon(Icons.history),
        ),
        label: 'Riwayat',
      ),
      BottomNavigationBarItem(
        icon: Container(
          height: 24,
          width: 24, // Add width constraint
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications),
              if (_unreadNotifications > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1), // Add border for visibility
                    ),
                  ),
                ),
            ],
          ),
        ),
        label: 'Notif',
      ),
    ],
  );
}

  Widget _buildQuickFeedButton() {
    return FloatingActionButton(
      onPressed: () {
        if (_todaysTasks.isNotEmpty) {
          _handleFeedAnimal(_todaysTasks.first);
        }
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.restaurant, color: Colors.white),
    );
  }
}

// ==============================
// DIALOG UNTUK FEEDING
// ==============================
class _FeedingDialog extends StatefulWidget {
  final AnimalModel animal;

  const _FeedingDialog({required this.animal});

  @override
  State<_FeedingDialog> createState() => __FeedingDialogState();
}

class __FeedingDialogState extends State<_FeedingDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Beri Makan ${widget.animal.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.animal.species} - ${widget.animal.enclosure}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Catatan (opsional):'),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Makan dengan lahap, minum banyak air...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan akan disimpan di riwayat pemberian makan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tandai Sudah Makan'),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    if (mounted) {
      Navigator.pop(context, {
        'fed': true,
        'notes': _notesController.text.trim(),
        'timestamp': DateTime.now(),
      });
    }
  }
}

// ==============================
// STAFF HOME TAB
// ==============================
class StaffHomeTab extends StatelessWidget {
  final UserModel user;
  final List<AnimalModel> myAnimals;
  final List<AnimalModel> todaysTasks;
  final List<NotificationModel> notifications;

  const StaffHomeTab({
    super.key,
    required this.user,
    required this.myAnimals,
    required this.todaysTasks,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final completedTasks = myAnimals.where((a) => a.isFed).length;
    final pendingTasks = todaysTasks.length;
    final urgentTasks = todaysTasks.where((a) => a.needsUrgentAttention).length;
    final unreadNotifications = notifications.where((n) => !n.isRead).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: Text(
                      user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user.fullName}!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${myAnimals.length} hewan di bawah tanggung jawab Anda',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          Text(
            'Statistik Hari Ini',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildStatCard(
                context,
                title: 'Hewan Saya',
                value: myAnimals.length.toString(),
                icon: Icons.pets,
                color: Colors.blue,
              ),
              _buildStatCard(
                context,
                title: 'Tugas Selesai',
                value: completedTasks.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatCard(
                context,
                title: 'Tugas Menunggu',
                value: pendingTasks.toString(),
                icon: Icons.access_time,
                color: Colors.orange,
              ),
              _buildStatCard(
                context,
                title: 'Notifikasi',
                value: unreadNotifications.toString(),
                icon: Icons.notifications,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Urgent Tasks
          if (urgentTasks > 0)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Tugas Penting!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...todaysTasks
                        .where((a) => a.needsUrgentAttention)
                        .map((animal) => ListTile(
                              leading: Icon(Icons.pets, color: Colors.red[700]),
                              title: Text(
                                animal.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                  '${animal.species} - ${animal.enclosure}'),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnimalDetailScreen(animal: animal, currentUser: user),
                                  ),
                                );
                              },
                            )),
                  ],
                ),
              ),
            ),
          if (urgentTasks > 0) const SizedBox(height: 20),

          // Today's Schedule
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Makan Hari Ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildFeedingSchedule(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aksi Cepat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.restaurant,
                        label: 'Beri Makan',
                        color: Colors.green,
                        onTap: () {
                          // Navigate to feeding tasks
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Icons.note_add,
                        label: 'Catat',
                        color: Colors.blue,
                        onTap: () {
                          // Add notes
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Icons.history,
                        label: 'Riwayat',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KeeperReportsHistoryScreen(currentUser: user),
                            ),
                          );
                        },
                      ),
                      _buildQuickActionButton(
                        icon: Icons.report,
                        label: 'Lapor',
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KeeperQuickReportScreen(currentUser: user),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ganti method _buildStatCard dengan ini:
Widget _buildStatCard(
  BuildContext context, {
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Card(
    elevation: 1,
    child: Container(
      padding: const EdgeInsets.all(10), // Reduced padding
      constraints: const BoxConstraints(
        minHeight: 90, // Minimum height
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon row
          Row(
            children: [
              Icon(icon, color: color, size: 20), // Smaller icon
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18, // Smaller font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11, // Smaller font size
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

  List<Widget> _buildFeedingSchedule() {
    final times = {'08:00': 'Pagi', '12:00': 'Siang', '16:00': 'Sore'};
    final now = DateTime.now();
    final currentHour = now.hour;

    return times.entries.map((entry) {
      final hour = int.parse(entry.key.split(':')[0]);
      final isPast = currentHour > hour;
      final isCurrent = currentHour == hour;

      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.blue[50]
                : isPast
                    ? Colors.grey[200]
                    : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.key,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrent
                  ? Colors.blue
                  : isPast
                      ? Colors.grey
                      : Colors.green,
            ),
          ),
        ),
        title: Text(
          'Makan ${entry.value}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isCurrent ? Colors.blue : null,
          ),
        ),
        subtitle: Text(
          isCurrent
              ? 'Sedang berlangsung'
              : isPast
                  ? 'Sudah selesai'
                  : 'Akan datang',
        ),
        trailing: Icon(
          isCurrent
              ? Icons.access_time
              : isPast
                  ? Icons.check_circle
                  : Icons.schedule,
          color: isCurrent
              ? Colors.blue
              : isPast
                  ? Colors.grey
                  : Colors.green,
        ),
        contentPadding: EdgeInsets.zero,
      );
    }).toList();
  }

  // Perbaiki method _buildQuickActionButton:
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 100,
      height: 90, // Tambahkan fixed height
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8), // Kurangi padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center content
              mainAxisSize: MainAxisSize.min, // Gunakan mainAxisSize.min
              children: [
                Icon(icon, color: color, size: 28), // Kurangi size icon
                const SizedBox(height: 6), // Kurangi spacing
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11, // Kurangi font size
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================
// FEEDING TASKS TAB
// ==============================
class FeedingTasksTab extends StatelessWidget {
  final List<AnimalModel> todaysTasks;
  final Function(AnimalModel) onFeedAnimal;
  final UserModel currentUser;

  const FeedingTasksTab({
    super.key,
    required this.todaysTasks,
    required this.onFeedAnimal,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.assignment, size: 48, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    'Tugas Pemberian Makan Hari Ini',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${todaysTasks.length} hewan perlu diberi makan',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tasks List
        Expanded(
          child: todaysTasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Semua tugas selesai!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tidak ada hewan yang perlu diberi makan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: todaysTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(todaysTasks[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(AnimalModel animal, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: animal.statusColor,
          child: Icon(animal.statusIcon, color: Colors.white),
        ),
        title: Text(
          animal.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${animal.species} - ${animal.enclosure}'),
            if (animal.lastFedDate != null)
              Text(
                'Terakhir: ${animal.lastFedFormatted}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        contentPadding: _kListTilePadding,
        trailing: animal.isHungry
            ? ElevatedButton(
                onPressed: () => onFeedAnimal(animal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Beri Makan'),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Sudah Makan',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnimalDetailScreen(animal: animal, currentUser: currentUser)),
          );
        },
      ),
    );
  }
}

// ==============================
// MY ANIMALS TAB
// ==============================
class MyAnimalsTab extends StatelessWidget {
  final List<AnimalModel> myAnimals;
  final Function(AnimalModel) onFeedAnimal;
  final UserModel currentUser;

  const MyAnimalsTab({
    super.key,
    required this.myAnimals,
    required this.onFeedAnimal,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari hewan...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        // Animals List
        Expanded(
          child: myAnimals.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada hewan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: myAnimals.length,
                  itemBuilder: (context, index) {
                    return _buildAnimalCard(myAnimals[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnimalCard(AnimalModel animal, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: _kListTilePadding,
        leading: CircleAvatar(
          backgroundColor: animal.statusColor,
          child: Icon(animal.statusIcon, color: Colors.white),
        ),
        title: Text(
          animal.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${animal.species} - ${animal.enclosure}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Jadwal: ${animal.feedingScheduleText}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              animal.statusText,
              style: TextStyle(
                color: animal.statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (animal.isHungry)
              TextButton(
                onPressed: () => onFeedAnimal(animal),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(64, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Beri Makan'),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnimalDetailScreen(animal: animal, currentUser: currentUser)),
          );
        },
      ),
    );
  }
}

// ==============================
// FEEDING HISTORY TAB
// ==============================
class FeedingHistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const FeedingHistoryTab({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Options
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  // Show filter dialog
                },
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter',
              ),
            ],
          ),
        ),
        // History List
        Expanded(
          child: history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Riwayat pemberian makan akan muncul di sini',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(history[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, BuildContext context) {
    final time = item['time'] as DateTime;
    final status = item['status'] as String;
    final isCompleted = status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: _kListTilePadding,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.pending,
            color: isCompleted ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          item['animal_name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['animal_species']),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(time),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (item['notes'] != null && item['notes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Catatan: ${item['notes']}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            isCompleted ? 'Selesai' : 'Pending',
            style: TextStyle(
              fontSize: 12,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
          ),
          backgroundColor: isCompleted ? Colors.green[50] : Colors.orange[50],
        ),
        onTap: () {
          // View history details
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateText;
    if (date == today) {
      dateText = 'Hari ini';
    } else if (date == yesterday) {
      dateText = 'Kemarin';
    } else {
      dateText = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateText $time';
  }
}

// ==============================
// STAFF NOTIFICATIONS TAB
// ==============================
class StaffNotificationsTab extends StatelessWidget {
  final List<NotificationModel> notifications;

  const StaffNotificationsTab({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifikasi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Mark all as read
                    },
                    icon: const Icon(Icons.mark_email_read),
                    tooltip: 'Tandai semua telah dibaca',
                  ),
                  IconButton(
                    onPressed: () {
                      // Clear all
                    },
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Hapus semua',
                  ),
                ],
              ),
            ],
          ),
        ),
        // Notifications List
        Expanded(
          child: notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada notifikasi',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Notifikasi baru akan muncul di sini',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationItem(notifications[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, BuildContext context) {
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case 'feeding_reminder':
        icon = Icons.restaurant;
        iconColor = Colors.blue;
        break;
      case 'missed_feeding':
        icon = Icons.warning;
        iconColor = Colors.red;
        break;
      case 'daily_summary':
        icon = Icons.summarize;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    Color priorityColor;
    switch (notification.priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : Colors.blue[50],
          child: ListTile(
        contentPadding: _kListTilePadding,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatNotificationTime(notification.scheduledTime ?? DateTime.now()),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          // View notification details
        },
        onLongPress: () {
          // Show options menu
        },
      ),
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// ==============================
// EXTENSION METHODS FOR MODELS
// ==============================

extension AnimalModelExtensions on AnimalModel {
  bool get isFed => feedingStatus == 'fed';
  bool get isHungry => feedingStatus == 'hungry';
  bool get needsUrgentAttention => isHungry && missedFeedingCount > 0;

  String get lastFedFormatted {
    if (lastFedTime == null) return 'Belum pernah';
    
    final now = DateTime.now();
    final difference = now.difference(lastFedTime!);
    
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  String get feedingScheduleText {
    switch (feedingSchedule) {
      case '2x sehari':
        return '2x/hari';
      case '3x sehari':
        return '3x/hari';
      case '1x sehari':
        return '1x/hari';
      default:
        return feedingSchedule;
    }
  }

  String get statusText {
    switch (feedingStatus) {
      case 'fed':
        return 'Sudah Makan';
      case 'hungry':
        return 'Perlu Makan';
      default:
        return feedingStatus;
    }
  }

  Color get statusColor {
    switch (feedingStatus) {
      case 'fed':
        return Colors.green;
      case 'hungry':
        return missedFeedingCount > 0 ? Colors.red : Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (feedingStatus) {
      case 'fed':
        return Icons.check_circle;
      case 'hungry':
        return missedFeedingCount > 0 ? Icons.warning : Icons.access_time;
      default:
        return Icons.help;
    }
  }

  AnimalModel markAsFed(String userId) {
    return AnimalModel(
      id: id,
      zooId: zooId,
      name: name,
      species: species,
      enclosure: enclosure,
      feedingSchedule: feedingSchedule,
      lastFedDate: DateTime.now(),
      lastFedTime: DateTime.now(),
      fedByUserId: userId,
      feedingStatus: 'fed',
      missedFeedingCount: 0,
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}