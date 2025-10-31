import 'package:flutter/material.dart';
import 'package:studify/screens/login_screen.dart';

class MenuTab extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> resources;
  final List<Map<String, dynamic>> announcements;

  const MenuTab({
    required this.notifications,
    required this.resources,
    required this.announcements,
    super.key,
  });

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> myTabs = const <Tab>[
    Tab(text: "Notifications"),
    Tab(text: "Resources"),
    Tab(text: "Announcements"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildNotifications() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.notifications.length,
      itemBuilder: (context, index) {
        final n = widget.notifications[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(n['title']),
            subtitle: Text(n['time']),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget buildResources() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.resources.length,
      itemBuilder: (context, index) {
        final r = widget.resources[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.folder_open),
            title: Text(r['title']),
            subtitle: Text(r['type']),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget buildAnnouncements() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.announcements.length,
      itemBuilder: (context, index) {
        final a = widget.announcements[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.announcement),
            title: Text(a['title']),
            subtitle: Text(a['date'] ?? ''),
            onTap: () {},
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            // --- THIS IS THE FULLY CORRECTED CODE ---
            onPressed: () {
              // This 'context' is the safe one from the MenuTab
              showDialog(
                context: context,
                // We rename the new context to 'dialogContext'
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    // Use 'dialogContext' to pop the dialog
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Cancel")),
                    TextButton(
                      onPressed: () {
                        // 1. Pop the dialog using 'dialogContext'
                        Navigator.pop(dialogContext);

                        // 2. Navigate using the safe, original 'context'
                        // This line uses the import, so the warning will go away.
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
            // -----------------------------------------
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildNotifications(),
          buildResources(),
          buildAnnouncements(),
        ],
      ),
    );
  }
}