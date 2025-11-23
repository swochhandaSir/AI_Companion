import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class ChatPage extends StatefulWidget {
  final String username;
  const ChatPage({super.key, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, String>> messages = [
    {"role": "bot", "text": "Hello! How can I help you today?"},
  ];
  TextEditingController controller = TextEditingController();

  Future<void> sendMessage() async {
    final msg = controller.text;
    if (msg.isEmpty) return;
    controller.clear();

    setState(() {
      messages.add({"role": "user", "text": msg});
    });

    // Convert local messages to API history format
    final history = messages
        .where(
          (m) =>
              m["role"] != "bot" ||
              m["text"] != "Hello! How can I help you today?",
        ) // Optional: skip initial greeting
        .map(
          (m) => {
            "role": m["role"] == "user" ? "user" : "assistant",
            "content": m["text"],
          },
        )
        .toList();

    try {
      final response = await http.post(
        // Use localhost for web/iOS simulator, or 10.0.2.2 for Android emulator
        Uri.parse("http://localhost:3000/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "message": msg,
          "history": history,
          "username": widget.username,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages.add({"role": "bot", "text": data["reply"]});
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          messages.add({
            "role": "bot",
            "text": "Error: ${errorData['error'] ?? response.statusCode}",
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "bot",
          "text": "Error: Failed to connect to server. Is it running?",
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Companion"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (c, i) {
                final m = messages[i];
                return Align(
                  alignment: m["role"] == "user"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: m["role"] == "user"
                          ? Colors.blue[100]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m["text"]!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
