// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studify/tabs/feed_tab.dart';
import 'package:studify/tabs/friends_tab.dart';
import 'package:studify/tabs/menu_tab.dart';
import 'package:studify/tabs/profile_tab.dart';
import 'package:studify/tabs/groups_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // --- 1. TABS FOR STUDENTS & FACULTY ---
  final List<Widget> _userTabs = [
    const FeedTab(),
    const GroupsTab(),
    const FriendsTab(),
    const MenuTab(),
    ProfileTab(),
  ];

  // --- 2. TABS FOR ADMINS ---
  final List<Widget> _adminTabs = [
    const MenuTab(),
    const GroupsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        String role = 'Student';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          role = data['role'] ?? 'Student';
        }

        bool isAdmin = role == 'Admin';
        List<Widget> currentTabs = isAdmin ? _adminTabs : _userTabs;

        // Prevent crash if switching roles changes tab count
        if (_currentIndex >= currentTabs.length) _currentIndex = 0;

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: currentTabs),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: isAdmin
                ? const [
              NavigationDestination(icon: Icon(Icons.campaign), label: 'Announcements'),
              NavigationDestination(icon: Icon(Icons.inbox), label: 'Requests'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ]
                : const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Feed'),
              NavigationDestination(icon: Icon(Icons.groups), label: 'Groups'),
              // --- CHANGED FROM 'Network' TO 'Friends' HERE ---
              NavigationDestination(icon: Icon(Icons.people), label: 'Friends'),
              NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}