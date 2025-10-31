import 'package:flutter/material.dart';
import 'package:studify/screens/group_chat_screen.dart';

class GroupsTab extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final Map<String, List<Map<String, dynamic>>> groupMessages;

  const GroupsTab(
      {required this.groups, required this.groupMessages, super.key});

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(child: Text(g['title'][0])),
                title: Text(g['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${g['members']} members\n${g['lastMessage']}",
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                isThreeLine: true,
                onTap: () {
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