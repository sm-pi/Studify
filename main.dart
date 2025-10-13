// main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(UniversityConnectApp());
}

class UniversityConnectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginScreen(),
    );
  }
}


class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // --- ADDED THIS SECTION ---
                Image.asset(
                  'assets/images/logo.png',
                  height: 180,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.school, // University icon
                      size: 120,
                      color: Colors.indigo,
                    );
                  },
                ),
                const SizedBox(height: 24),
                // -------------------------

                /*Text("Studify",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    )),*/
                const SizedBox(height: 5),
                Text("Login",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800])),
                const SizedBox(height: 40),
                CustomTextField(
                  hintText: "University Email",
                  controller: emailController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Placeholder
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Forgot password tapped")));
                    },
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: "Login",
                  onPressed: () {
                    // For this prototype, go to AddFriends screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Login with Gmail tapped")));
                  },
                  icon: const Icon(Icons.mail_outline),
                  label: const Text("Login with Gmail"),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      ),
                      child: Text("Sign up",
                          style: TextStyle(color: Colors.indigo[700])),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  "Please use your university email address for verification.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text("Join the community",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                const SizedBox(height: 26),
                CustomTextField(hintText: "Full Name", controller: nameController),
                const SizedBox(height: 16),
                CustomTextField(
                    hintText: "University Email (Gmail)",
                    controller: emailController),
                const SizedBox(height: 16),
                CustomTextField(
                    hintText: "Password",
                    obscureText: true,
                    controller: passwordController),
                const SizedBox(height: 22),
                CustomButton(
                  text: "Register",
                  onPressed: () {
                    // For prototype, go to AddFriends
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AddFriendsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  "By registering, you agree to our Terms of Service and Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddFriendsScreen extends StatefulWidget {
  AddFriendsScreen({super.key});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> allSuggestions = [
    {"name": "Ibrahim", "mutual": 12},
    {"name": "Meherin", "mutual": 8},
    {"name": "Jahid Hossain", "mutual": 5},
    {"name": "Shanta", "mutual": 3},
    {"name": "Rafi", "mutual": 4},
    {"name": "Anika", "mutual": 2},
  ];

  List<Map<String, dynamic>> filtered = [];

  final Set<String> added = {};

  @override
  void initState() {
    super.initState();
    filtered = List.from(allSuggestions);
  }

  void onSearch(String q) {
    setState(() {
      filtered = allSuggestions
          .where((f) => f['name'].toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  void toggleAdd(String name) {
    setState(() {
      if (added.contains(name)) {
        added.remove(name);
      } else {
        added.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Friends"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: "Search for friends",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final friend = filtered[index];
                    final name = friend['name'] as String;
                    final mutual = friend['mutual'] as int;
                    final isAdded = added.contains(name);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(name[0]),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$mutual mutual friends"),
                        trailing: ElevatedButton(
                          onPressed: () => toggleAdd(name),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: isAdded ? Colors.white70 : Colors.white),
                          child: Text(isAdded ? "Added" : "Add"),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: "Continue",
                onPressed: () {
                  // Navigate to HomeScreen with bottom navigation
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  // Dummy data share across tabs
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

  // Chat message store (for demo per group id)
  final Map<String, List<Map<String, dynamic>>> groupMessages = {
    "g1": [
      {"sender": "Samin", "text": "I will upload the slides tonight", "time": "10:12"},
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

  @override
  Widget build(BuildContext context) {
    final tabs = [
      FeedTab(samplePosts: samplePosts),
      GroupsTab(
        groups: sampleGroups,
        groupMessages: groupMessages,
      ),
      FriendsTab(friends: sampleFriends),
      ProfileTab(profile: sampleProfile),
      MenuTab(
        notifications: notifications,
        resources: resources,
        announcements: announcements,
      ),
    ];

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

/* ------------------------------------------------------------
   FEED TAB
   ------------------------------------------------------------ */

class FeedTab extends StatelessWidget {
  final List<Map<String, dynamic>> samplePosts;

  const FeedTab({required this.samplePosts, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: samplePosts.length,
          itemBuilder: (context, index) {
            final post = samplePosts[index];
            return PostCard(
                author: post['author'],
                time: post['time'],
                text: post['text'],
                likes: post['likes'],
                comments: post['comments']);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // placeholder create post
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create post tapped")));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final String author;
  final String time;
  final String text;
  final int likes;
  final int comments;

  const PostCard({
    required this.author,
    required this.time,
    required this.text,
    required this.likes,
    required this.comments,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(child: Text(author[0])),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ]),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
            ]),
            const SizedBox(height: 10),
            Text(text),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text("$likes"),
                const SizedBox(width: 18),
                Icon(Icons.comment, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text("$comments"),
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------
   GROUPS TAB -> opens GroupChatScreen when tapped (Frame 3)
   ------------------------------------------------------------ */

class GroupsTab extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final Map<String, List<Map<String, dynamic>>> groupMessages;

  const GroupsTab({required this.groups, required this.groupMessages, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Groups"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final g = groups[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(child: Text(g['title'][0])),
                title: Text(g['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${g['members']} members\n${g['lastMessage']}", maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                isThreeLine: true,
                onTap: () {
                  // navigate to group chat page
                  final groupId = g['id'] as String;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                        groupId: groupId,
                        title: g['title'],
                        initialMessages: groupMessages[groupId] ?? [],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------
   FRIENDS / CONNECTIONS TAB (Frame 2)
   ------------------------------------------------------------ */

class FriendsTab extends StatelessWidget {
  final List<Map<String, dynamic>> friends;

  const FriendsTab({required this.friends, super.key});

  @override
  Widget build(BuildContext context) {
    final faculty = friends.where((f) => f['type'] == 'Faculty').toList();
    final students = friends.where((f) => f['type'] == 'Student').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 8),
            const Text("Suggestions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...students.map((s) => ConnectionTile(name: s['name'], subtitle: "${s['mutual']} mutual friends")).toList(),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text("Faculty", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...faculty.map((f) => ConnectionTile(name: f['name'], subtitle: f['type'])).toList(),
          ],
        ),
      ),
    );
  }
}

class ConnectionTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const ConnectionTile({required this.name, required this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(child: Text(name[0])),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text("Request"),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------
   PROFILE TAB (Frame 2)
   ------------------------------------------------------------ */

class ProfileTab extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileTab({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 34, child: Text(profile['name'][0])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(profile['id'], style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 6),
                        Text(profile['university'], style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  ElevatedButton(onPressed: () {}, child: const Text("Edit"))
                ],
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(profile['description']),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(profile['email']),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text("Activity", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(leading: Icon(Icons.post_add), title: Text("Posted new notes in Feed")),
                    ListTile(leading: Icon(Icons.group), title: Text("Joined AI Club")),
                    ListTile(leading: Icon(Icons.star), title: Text("Completed Flutter Workshop")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------
   MENU TAB - Notifications, Resources, Announcements
   ------------------------------------------------------------ */

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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // close dialog
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                                (route) => false,
                          );
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );
              },
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

/* ------------------------------------------------------------
   GROUP CHAT SCREEN (separate window with back button)
   - displays list in group section, messages, input to append
   ------------------------------------------------------------ */

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String title;
  final List<Map<String, dynamic>> initialMessages;

  const GroupChatScreen({
    required this.groupId,
    required this.title,
    required this.initialMessages,
    super.key,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late List<Map<String, dynamic>> messages;
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.initialMessages);
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({"sender": "You", "text": text, "time": _nowTimeString()});
      messageController.clear();
    });
    // For prototype: no backend, messages are local to screen instance
  }

  String _nowTimeString() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Widget messageBubble(Map<String, dynamic> msg) {
    final bool mine = msg['sender'] == "You";
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? Colors.indigo[200] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(mine ? 12 : 0),
            bottomRight: Radius.circular(mine ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine) Text(msg['sender'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(msg['text']),
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.bottomRight,
                child: Text(msg['time'], style: TextStyle(fontSize: 10, color: Colors.grey[700]))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) => messageBubble(messages[index]),
              ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(onPressed: sendMessage, icon: const Icon(Icons.send, color: Colors.indigo)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------
   Reusable Widgets (TextField, Button)
   ------------------------------------------------------------ */

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;

  const CustomTextField({
    required this.hintText,
    this.obscureText = false,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({required this.text, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}

