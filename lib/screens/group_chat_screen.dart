import 'package:flutter/material.dart';

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
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
            if (!mine)
              Text(msg['sender'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(msg['text']),
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.bottomRight,
                child: Text(msg['time'],
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]))),
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
                reverse: true, // Show newest messages at the bottom
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final reversedIndex = messages.length - 1 - index;
                  final message = messages[reversedIndex];
                  return messageBubble(message);
                },
              ),
            ),
            // Message Input Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}