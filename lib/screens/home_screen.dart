// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:studify/tabs/feed_tab.dart';
import 'package:studify/tabs/friends_tab.dart';
import 'package:studify/tabs/groups_tab.dart';
import 'package:studify/tabs/menu_tab.dart';
import 'package:studify/tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  late final List<Widget> tabs;

  // --- We still need the other dummy data for the other tabs ---

  final List<Map<String, dynamic>> sampleGroups = [
    {
      "id": "g1",
      "title": "CSE 3rd Year - Section A",
      "members": 42,
      "lastMessage": "Samin: I will upload the slides tonight"
    },
    // ... other groups
  ];

  final List<Map<String, dynamic>> sampleFriends = [
    {"name": "Ibrahim", "type": "Student", "mutual": 12},
    {"name": "Dr. Rahman", "type": "Faculty", "mutual": 0},
    // ... other friends
  ];

  final Map<String, dynamic> sampleProfile = {
    "name": "MD Sazzad Anam Samin",
    "id": "ID -429",
    // ... other profile data
  };

  final List<Map<String, dynamic>> notifications = [
    {"title": "New announcement: Classes start Sep 14", "time": "1h"},
    // ... other notifications
  ];

  final List<Map<String, dynamic>> resources = [
    {"title": "DB Systems Lecture Slides", "type": "pdf"},
    // ... other resources
  ];

  final List<Map<String, dynamic>> announcements = [
    {"title": "Campus closed on Eid", "date": "2025-04-10"},
    // ... other announcements
  ];

  final Map<String, List<Map<String, dynamic>>> groupMessages = {
    "g1": [
      {
        "sender": "Samin",
        "text": "I will upload the slides tonight",
        "time": "10:12"
      },
      // ... other messages
    ],
    // ... other group messages
  };

  @override
  void initState() {
    super.initState();
    tabs = [
      // --- THIS IS THE FIX ---
      const FeedTab(), // We no longer pass samplePosts
      // ----------------------
      GroupsTab(
        groups: sampleGroups,
        groupMessages: groupMessages,
      ),
      FriendsTab(),
      ProfileTab(),
      MenuTab(
        //profile: sampleProfile,
        //notifications: notifications,
        //resources: resources,
        //announcements: announcements,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey[600],
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Groups"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Friends"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
        ],
      ),
    );
  }
}