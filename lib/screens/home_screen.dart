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
  // FIX: (This was missing from your code, but I fixed it before)
  // Initialize tabs list in initState to preserve state
  late final List<Widget> tabs;

  // Dummy data
  final List<Map<String, dynamic>> samplePosts = [
    {
      "author": "Samin",
      "time": "2h",
      "text": "Excited to start the semester! Anyone up for a study group?",
      "likes": 34,
      "comments": 6
    },
    {
      "author": "Meherin",
      "time": "Yesterday",
      "text": "Shared my notes on Database Systems. Check resources tab!",
      "likes": 19,
      "comments": 4
    },
    {
      "author": "Ibrahim",
      "time": "3d",
      "text": "Looking for partner for mobile app project",
      "likes": 8,
      "comments": 3
    },
  ];

  final List<Map<String, dynamic>> sampleGroups = [
    {
      "id": "g1",
      "title": "CSE 3rd Year - Section A",
      "members": 42,
      "lastMessage": "Samin: I will upload the slides tonight"
    },
    {
      "id": "g2",
      "title": "AI Club",
      "members": 120,
      "lastMessage": "Anika: Workshop on Friday"
    },
    {
      "id": "g3",
      "title": "Final Year Project Group",
      "members": 6,
      "lastMessage": "Jahid: Meeting at 6pm"
    },
  ];

  final List<Map<String, dynamic>> sampleFriends = [
    {"name": "Ibrahim", "type": "Student", "mutual": 12},
    {"name": "Dr. Rahman", "type": "Faculty", "mutual": 0},
    {"name": "Meherin", "type": "Student", "mutual": 8},
    {"name": "Shanta", "type": "Student", "mutual": 3},
  ];

  final Map<String, dynamic> sampleProfile = {
    "name": "MD Sazzad Anam Samin",
    "id": "ID -429",
    "description": "CSE student, AI major. Building Twinker Social.",
    "university": "Example University",
    "email": "samin@university.edu"
  };

  final List<Map<String, dynamic>> notifications = [
    {"title": "New announcement: Classes start Sep 14", "time": "1h"},
    {"title": "Group invite: AI Club", "time": "5h"},
    {"title": "Friend request from Rafi", "time": "Yesterday"},
  ];

  final List<Map<String, dynamic>> resources = [
    {"title": "DB Systems Lecture Slides", "type": "pdf"},
    {"title": "Flutter Starter Kit", "type": "link"},
    {"title": "AI Club Repo", "type": "link"},
  ];

  final List<Map<String, dynamic>> announcements = [
    {"title": "Campus closed on Eid", "date": "2025-04-10"},
    {"title": "Midterm results published", "date": "2025-03-20"},
  ];

  final Map<String, List<Map<String, dynamic>>> groupMessages = {
    "g1": [
      {
        "sender": "Samin",
        "text": "I will upload the slides tonight",
        "time": "10:12"
      },
      {"sender": "Ibrahim", "text": "Thanks!", "time": "10:15"},
    ],
    "g2": [
      {"sender": "Anika", "text": "Workshop on Friday", "time": "Yesterday"},
      {"sender": "Dr. Rahman", "text": "See you there", "time": "Yesterday"},
    ],
    "g3": [
      {"sender": "Jahid", "text": "Meeting at 6pm", "time": "2:00"},
    ],
  };

  // FIX: Initialize tabs in initState
  @override
  void initState() {
    super.initState();
    tabs = [
      FeedTab(samplePosts: samplePosts),
      GroupsTab(
        groups: sampleGroups,
        groupMessages: groupMessages,
      ),
      FriendsTab(friends: sampleFriends),
      ProfileTab(),
      MenuTab(
        notifications: notifications,
        resources: resources,
        announcements: announcements,
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