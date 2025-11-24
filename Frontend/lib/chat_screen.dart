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
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [
    {"role": "bot", "text": "Hello! How can I help you today?"},
  ];
  TextEditingController controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage() async {
    final msg = controller.text.trim();
    if (msg.isEmpty || _isLoading) return;

    controller.clear();
    setState(() {
      messages.add({"role": "user", "text": msg});
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Convert local messages to API history format
    final history = messages
        .where(
          (m) =>
              m["role"] != "bot" ||
              m["text"] != "Hello! How can I help you today?",
        )
        .map(
          (m) => {
            "role": m["role"] == "user" ? "user" : "assistant",
            "content": m["text"],
          },
        )
        .toList();

    try {
      final response = await http.post(
        Uri.parse("https://ai-companion-nyvp.onrender.com/chat"),
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
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          messages.add({
            "role": "bot",
            "text": "Error: ${errorData['error'] ?? response.statusCode}",
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "bot",
          "text": "Error: Failed to connect to server. Is it running?",
        });
        _isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    const Color cream = Color(0xFFF8F4EC);
    const Color lightPink = Color(0xFFFF8FB7);
    const Color primaryPink = Color(0xFFE83C91);
    const Color darkPurple = Color(0xFF43334C);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.smart_toy, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Companion",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.username,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Logout",
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cream, cream, Colors.white],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && _isLoading) {
                    return _buildLoadingIndicator();
                  }
                  final m = messages[index];
                  return _buildMessageBubble(m, context);
                },
              ),
            ),
          ),
          // Input Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: darkPurple.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            hintStyle: TextStyle(
                              color: darkPurple.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => sendMessage(),
                          enabled: !_isLoading,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: primaryPink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryPink.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : sendMessage,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 48,
                            height: 48,
                            child: _isLoading
                                ? Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, String> message,
    BuildContext context,
  ) {
    const Color cream = Color(0xFFF8F4EC);
    const Color lightPink = Color(0xFFFF8FB7);
    const Color primaryPink = Color(0xFFE83C91);
    const Color darkPurple = Color(0xFF43334C);

    final isUser = message["role"] == "user";
    final isError = message["text"]!.startsWith("Error:");

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: lightPink,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryPink
                    : isError
                    ? Colors.red.shade50
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? primaryPink : darkPurple).withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message["text"]!,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : isError
                      ? Colors.red.shade700
                      : darkPurple,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: lightPink,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    const Color primaryPink = Color(0xFFE83C91);
    const Color darkPurple = Color(0xFF43334C);

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFFFF8FB7),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "Thinking...",
                  style: TextStyle(
                    color: darkPurple.withOpacity(0.6),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
