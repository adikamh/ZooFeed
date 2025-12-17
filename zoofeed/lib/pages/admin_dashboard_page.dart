import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/animal_model.dart';
import '../../models/notification_model.dart';
import '../../screens/logout_screen.dart';

class AdminDashboardPage extends StatefulWidget {
  final UserModel user;

  const AdminDashboardPage({super.key, required this.user});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;

  // Dummy data - nanti akan diganti dengan data dari Firestore
  final List<AnimalModel> _animals = [
    AnimalModel(
      id: '1',
      zooId: 'zoo1',
      name: 'Simba',
      species: 'Singa',
      enclosure: 'Kandang A',
      feedingSchedule: '2x sehari',
      lastFedDate: DateTime.now().subtract(const Duration(hours: 2)),
      lastFedTime: DateTime.now().subtract(const Duration(hours: 2)),
      fedByUserId: 'user1',
      feedingStatus: 'fed',
      missedFeedingCount: 0,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AnimalModel(
      id: '2',
      zooId: 'zoo1',
      name: 'Dumbo',
      species: 'Gajah',
      enclosure: 'Kandang B',
      feedingSchedule: '3x sehari',
      lastFedDate: DateTime.now().subtract(const Duration(days: 1)),
      lastFedTime: DateTime.now().subtract(const Duration(days: 1)),
      fedByUserId: null,
      feedingStatus: 'hungry',
      missedFeedingCount: 1,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now(),
    ),
    AnimalModel(
      id: '3',
      zooId: 'zoo1',
      name: 'Koko',
      species: 'Orangutan',
      enclosure: 'Kandang C',
      feedingSchedule: '2x sehari',
      lastFedDate: DateTime.now().subtract(const Duration(hours: 3)),
      lastFedTime: DateTime.now().subtract(const Duration(hours: 3)),
      fedByUserId: 'user2',
      feedingStatus: 'fed',
      missedFeedingCount: 0,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AnimalModel(
      id: '4',
      zooId: 'zoo1',
      name: 'Raja',
      species: 'Harimau',
      enclosure: 'Kandang D',
      feedingSchedule: '2x sehari',
      lastFedDate: DateTime.now().subtract(const Duration(days: 2)),
      lastFedTime: DateTime.now().subtract(const Duration(days: 2)),
      fedByUserId: null,
      feedingStatus: 'hungry',
      missedFeedingCount: 2,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
  ];

  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      zooId: 'zoo1',
      userId: 'user1',
      type: 'feeding_reminder',
      title: 'Waktunya memberi makan',
      message: 'Ada 5 hewan yang belum makan',
      priority: 'medium',
      deliveryMethod: 'push',
      isRead: false,
      isSent: true,
      scheduledTime: DateTime.now().subtract(const Duration(hours: 1)),
      sentTime: DateTime.now().subtract(const Duration(hours: 1)),
      metadata: {'animal_count': 5},
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: '2',
      zooId: 'zoo1',
      userId: 'user1',
      type: 'missed_feeding',
      title: 'Hewan terlewat makan',
      message: 'Simba belum makan sejak kemarin',
      animalId: '1',
      priority: 'high',
      deliveryMethod: 'push',
      isRead: false,
      isSent: true,
      scheduledTime: DateTime.now().subtract(const Duration(minutes: 30)),
      sentTime: DateTime.now().subtract(const Duration(minutes: 30)),
      metadata: {'hours_since_last_feed': 26},
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    NotificationModel(
      id: '3',
      zooId: 'zoo1',
      userId: 'user1',
      type: 'daily_summary',
      title: 'Laporan harian',
      message: '40/45 hewan sudah makan hari ini',
      priority: 'low',
      deliveryMethod: 'push',
      isRead: true,
      isSent: true,
      scheduledTime: DateTime.now().subtract(const Duration(hours: 3)),
      sentTime: DateTime.now().subtract(const Duration(hours: 3)),
      metadata: {'fed_count': 40, 'total_count': 45, 'percentage': 89},
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  final List<Map<String, String>> _keepers = [
    {'id': '1', 'name': 'Budi Santoso', 'email': 'budi@zoo.com', 'status': 'active'},
    {'id': '2', 'name': 'Sari Wijaya', 'email': 'sari@zoo.com', 'status': 'active'},
    {'id': '3', 'name': 'Rudi Hartono', 'email': 'rudi@zoo.com', 'status': 'inactive'},
    {'id': '4', 'name': 'Dewi Lestari', 'email': 'dewi@zoo.com', 'status': 'active'},
  ];

  @override
  void initState() {
    super.initState();
    // Hitung notifikasi belum dibaca
    _unreadNotifications = _notifications.where((n) => !n.isRead).length;
  }

  void _navigateToLogoutScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const LogoutScreen(),
    ),
  );
}

  // Tab yang akan ditampilkan
  List<Widget> get _dashboardTabs => [
        DashboardHomeTab(
          animals: _animals,
          notifications: _notifications,
          user: widget.user,
        ),
        AnimalsManagementTab(animals: _animals),
        KeepersManagementTab(keepers: _keepers),
        NotificationsTab(notifications: _notifications),
        const ReportsTab(),
      ];

  final List<String> _tabTitles = [
    'Dashboard',
    'Hewan',
    'Keeper',
    'Notifikasi',
    'Laporan',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedIndex]),
        actions: [
          // Notification Badge
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _selectedIndex = 3);
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Settings
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _dashboardTabs[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _selectedIndex == 1 ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          UserAccountsDrawerHeader(
            accountName: Text(widget.user.fullName),
            accountEmail: Text(widget.user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                widget.user.fullName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
          ),
          // Menu Items
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
          ),
          _buildDrawerItem(
            icon: Icons.pets,
            title: 'Kelola Hewan',
            index: 1,
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Kelola Keeper',
            index: 2,
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Notifikasi',
            index: 3,
            badge: _unreadNotifications > 0 ? '$_unreadNotifications' : null,
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            title: 'Laporan',
            index: 4,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
               _navigateToLogoutScreen(context);
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
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.pets),
              if (_animals.where((a) => a.isHungry).isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 4,
                      minHeight: 4,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Hewan',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Keeper',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Notif',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Laporan',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        // Add new animal
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

// ==============================
// DASHBOARD HOME TAB
// ==============================
class DashboardHomeTab extends StatelessWidget {
  final List<AnimalModel> animals;
  final List<NotificationModel> notifications;
  final UserModel user;

  const DashboardHomeTab({
    super.key,
    required this.animals,
    required this.notifications,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final totalAnimals = animals.length;
    final fedAnimals = animals.where((a) => a.isFed).length;
    final hungryAnimals = animals.where((a) => a.isHungry).length;
    final urgentAlerts = animals.where((a) => a.needsUrgentAttention).length;
    final urgentNotifications = notifications.where((n) => n.isHighPriority && !n.isRead).length;

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
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.pets,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang, ${user.fullName}!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola ${totalAnimals} hewan di kebun binatang Anda',
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

          // Stats Overview
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
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                title: 'Total Hewan',
                value: totalAnimals.toString(),
                icon: Icons.pets,
                color: Colors.blue,
              ),
              _buildStatCard(
                context,
                title: 'Sudah Makan',
                value: fedAnimals.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
                subtitle: '${totalAnimals > 0 ? ((fedAnimals / totalAnimals) * 100).round() : 0}%',
              ),
              _buildStatCard(
                context,
                title: 'Belum Makan',
                value: hungryAnimals.toString(),
                icon: Icons.error_outline,
                color: Colors.orange,
              ),
              _buildStatCard(
                context,
                title: 'Alert Penting',
                value: (urgentAlerts + urgentNotifications).toString(),
                icon: Icons.warning,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Urgent Alerts
          if (animals.any((a) => a.needsUrgentAttention) ||
              notifications.any((n) => n.isHighPriority && !n.isRead))
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
                          'Alert Penting',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Hewan yang perlu perhatian
                    ...animals
                        .where((a) => a.needsUrgentAttention)
                        .map((animal) => _buildAlertItem(
                              '${animal.name} belum makan ${animal.missedFeedingCount}x berturut-turut',
                              '${animal.species} - ${animal.enclosure}',
                              Icons.pets,
                            ))
                        .toList(),
                    // Notifikasi penting
                    ...notifications
                        .where((n) => n.isHighPriority && !n.isRead)
                        .map((notification) => _buildAlertItem(
                              notification.title,
                              notification.message,
                              notification.icon,
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
          if (animals.any((a) => a.needsUrgentAttention) ||
              notifications.any((n) => n.isHighPriority && !n.isRead))
            const SizedBox(height: 20),

          // Today's Feeding Schedule
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
                  _buildScheduleItem('08:00', 'Sarapan',
                      animals.where((a) => a.shouldBeFedNow && DateTime.now().hour == 8).length),
                  _buildScheduleItem('12:00', 'Makan Siang',
                      animals.where((a) => a.shouldBeFedNow && DateTime.now().hour == 12).length),
                  _buildScheduleItem('16:00', 'Makan Malam',
                      animals.where((a) => a.shouldBeFedNow && DateTime.now().hour == 16).length),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
  BuildContext context, {
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  String? subtitle,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24), // Kurangi ukuran icon
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10, // Perkecil font
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // Kurangi ukuran font
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12, // Kurangi ukuran font
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.red[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // Navigate to detail
      },
    );
  }

  Widget _buildScheduleItem(String time, String title, int animalCount) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('$animalCount hewan perlu makan'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // Navigate to feeding schedule
      },
    );
  }
}

// ==============================
// ANIMALS MANAGEMENT TAB
// ==============================
class AnimalsManagementTab extends StatefulWidget {
  final List<AnimalModel> animals;

  const AnimalsManagementTab({super.key, required this.animals});

  @override
  State<AnimalsManagementTab> createState() => _AnimalsManagementTabState();
}

class _AnimalsManagementTabState extends State<AnimalsManagementTab> {
  late List<AnimalModel> _filteredAnimals;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _filteredAnimals = widget.animals;
  }

  void _applyFilter() {
    setState(() {
      _filteredAnimals = widget.animals.where((animal) {
        // Filter berdasarkan search query
        final matchesSearch = animal.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            animal.species
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            animal.enclosure
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        // Filter berdasarkan kategori
        switch (_selectedFilter) {
          case 'Belum Makan':
            return matchesSearch && animal.isHungry;
          case 'Sudah Makan':
            return matchesSearch && animal.isFed;
          case 'Perlu Perhatian':
            return matchesSearch && animal.needsUrgentAttention;
          default:
            return matchesSearch;
        }
      }).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFilter();
            },
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
        // Filter Chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('Semua', _selectedFilter == 'Semua'),
              _buildFilterChip('Belum Makan', _selectedFilter == 'Belum Makan'),
              _buildFilterChip('Sudah Makan', _selectedFilter == 'Sudah Makan'),
              _buildFilterChip('Perlu Perhatian',
                  _selectedFilter == 'Perlu Perhatian'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Animals List
        Expanded(
          child: _filteredAnimals.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada hewan yang ditemukan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredAnimals.length,
                  itemBuilder: (context, index) {
                    return _buildAnimalCard(_filteredAnimals[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.green,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
        onSelected: (value) {
          setState(() {
            _selectedFilter = label;
            _applyFilter();
          });
        },
      ),
    );
  }

  Widget _buildAnimalCard(AnimalModel animal, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: animal.statusColor,
          child: Icon(
            animal.statusIcon,
            color: Colors.white,
          ),
        ),
        title: Text(
          animal.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${animal.species} - ${animal.enclosure}'),
            const SizedBox(height: 2),
            Text(
              'Status: ${animal.statusText}',
              style: TextStyle(
                color: animal.statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (animal.lastFedDate != null)
              Text(
                'Terakhir: ${animal.lastFedFormatted}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (animal.isHungry)
              const PopupMenuItem(
                value: 'feed',
                child: Row(
                  children: [
                    Icon(Icons.restaurant, size: 20),
                    SizedBox(width: 8),
                    Text('Tandai Makan'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20),
                  SizedBox(width: 8),
                  Text('Hapus'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            // Handle menu selection
          },
        ),
        onTap: () {
          // Navigate to animal detail
        },
      ),
    );
  }
}

// ==============================
// KEEPERS MANAGEMENT TAB
// ==============================
class KeepersManagementTab extends StatelessWidget {
  final List<Map<String, String>> keepers;

  const KeepersManagementTab({super.key, required this.keepers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add Keeper Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to add keeper
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah Keeper Baru'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        // Keepers List
        Expanded(
          child: keepers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada keeper',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Tambahkan keeper untuk mulai bekerja',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: keepers.length,
                  itemBuilder: (context, index) {
                    return _buildKeeperCard(keepers[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKeeperCard(Map<String, String> keeper, BuildContext context) {
    final isActive = keeper['status'] == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isActive ? Colors.green[100] : Colors.grey[200],
          child: Icon(
            Icons.person,
            color: isActive ? Colors.green[800] : Colors.grey[600],
          ),
        ),
        title: Text(
          keeper['name']!,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(keeper['email']!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  color: isActive ? Colors.green[800] : Colors.red[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                // Edit keeper
              },
              icon: const Icon(Icons.edit, size: 20),
            ),
          ],
        ),
        onTap: () {
          // View keeper details
        },
      ),
    );
  }
}

// ==============================
// NOTIFICATIONS TAB
// ==============================
class NotificationsTab extends StatefulWidget {
  final List<NotificationModel> notifications;

  const NotificationsTab({super.key, required this.notifications});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  String _selectedFilter = 'Semua';

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Belum Dibaca':
        return widget.notifications.where((n) => !n.isRead).toList();
      case 'Tinggi':
        return widget.notifications.where((n) => n.isHighPriority).toList();
      case 'Sedang':
        return widget.notifications.where((n) => n.isMediumPriority).toList();
      case 'Rendah':
        return widget.notifications.where((n) => n.isLowPriority).toList();
      default:
        return widget.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        widget.notifications.where((n) => !n.isRead).length;

    return Column(
      children: [
        // Header dengan filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to notification settings
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Pengaturan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Mark all as read
                  },
                  icon: const Icon(Icons.done_all),
                  label: Text('Tandai Semua ($unreadCount)'),
                ),
              ),
            ],
          ),
        ),
        // Filter Chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildNotificationFilterChip('Semua'),
              _buildNotificationFilterChip('Belum Dibaca'),
              _buildNotificationFilterChip('Tinggi'),
              _buildNotificationFilterChip('Sedang'),
              _buildNotificationFilterChip('Rendah'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Notifications List
        Expanded(
          child: _filteredNotifications.isEmpty
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
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredNotifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(
                        _filteredNotifications[index], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.green,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
        onSelected: (value) {
          setState(() => _selectedFilter = label);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
      NotificationModel notification, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: Icon(notification.icon, color: notification.color),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              notification.formattedTime,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: notification.priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {
          // Mark as read and show details
        },
      ),
    );
  }
}

// ==============================
// REPORTS TAB
// ==============================
class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan & Analitik',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),

          // Ganti GridView.count di ReportsTab.build()
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6, // Ubah dari 1.8 menjadi 1.6
            children: [
              _buildReportCard(
                'Laporan Harian',
                Icons.today,
                'Ringkasan aktivitas hari ini',
                Colors.blue,
              ),
              _buildReportCard(
                'Laporan Mingguan',
                Icons.calendar_view_week,
                'Statistik 7 hari terakhir',
                Colors.green,
              ),
              _buildReportCard(
                'Laporan Bulanan',
                Icons.calendar_month,
                'Performa bulan ini',
                Colors.purple,
              ),
              _buildReportCard(
                'Laporan Keeper',
                Icons.people,
                'Aktivitas keeper',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Export Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ekspor Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildExportOption(
                      'CSV', 'Format spreadsheet', Icons.table_chart),
                  _buildExportOption(
                      'PDF', 'Dokumen printable', Icons.picture_as_pdf),
                  _buildExportOption(
                      'Excel', 'File Excel lengkap', Icons.insert_chart),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Data Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup Data'),
                    subtitle: const Text('Backup semua data ke cloud'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore Data'),
                    subtitle: const Text('Pulihkan data dari backup'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep),
                    title: const Text('Hapus Data Lama'),
                    subtitle: const Text('Hapus data lebih dari 1 tahun'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildReportCard(
      String title, IconData icon, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12), // Kurangi padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Ubah menjadi center
          children: [
            Icon(icon, color: color, size: 28), // Kurangi ukuran icon
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14, // Kurangi ukuran font
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11, // Kurangi ukuran font
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.download),
      onTap: () {
        // Export data
      },
    );
  }
}