import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'config.dart';

class ChatPage extends StatefulWidget {
  final String username;
  final String initialAvatar;
  const ChatPage({
    super.key,
    required this.username,
    required this.initialAvatar,
  });

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

  // Avatar State
  late String _currentAvatar;
  final List<String> _avatars = ["robot", "anime", "human", "abstract"];

  // Voice Mode State
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _voiceModeEnabled = false; // Toggle for auto-read

  @override
  void initState() {
    super.initState();
    _currentAvatar = widget.initialAvatar;
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _updateAvatar(String newAvatar) async {
    setState(() => _currentAvatar = newAvatar);
    try {
      await http.post(
        Uri.parse("${Config.baseUrl}/update_avatar"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": widget.username, "avatar": newAvatar}),
      );
    } catch (e) {
      print("Failed to update avatar: $e");
    }
  }

  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Choose Your Companion"),
        content: Container(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatar = _avatars[index];
              return GestureDetector(
                onTap: () {
                  _updateAvatar(avatar);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: _currentAvatar == avatar
                        ? Border.all(color: Colors.pink, width: 3)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      "assets/avatars/$avatar.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9); // Slightly slower for better clarity

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    _flutterTts.stop();
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

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              controller.text = val.recognizedWords;
            });
            if (val.finalResult && val.recognizedWords.isNotEmpty) {
              setState(() => _isListening = false);
              _speech.stop();
              sendMessage(isVoice: true);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak(String text) async {
    // Ensure mic is off before speaking
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
    await _flutterTts.speak(text);
  }

  Future<void> sendMessage({bool isVoice = false}) async {
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
        Uri.parse("${Config.baseUrl}/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "message": msg,
          "history": history,
          "username": widget.username,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reply = data["reply"];
        setState(() {
          messages.add({"role": "bot", "text": reply});
          _isLoading = false;
        });

        if (_voiceModeEnabled || isVoice) {
          _speak(reply);
        }
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
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _showAvatarDialog,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    "assets/avatars/$_currentAvatar.png",
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.smart_toy, size: 20),
                  ),
                ),
              ),
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
            icon: Icon(Icons.palette, color: Colors.white),
            tooltip: "Customize Avatar",
            onPressed: _showAvatarDialog,
          ),
          IconButton(
            icon: Icon(
              _voiceModeEnabled ? Icons.volume_up : Icons.volume_off,
              color: _voiceModeEnabled ? Colors.white : Colors.white70,
            ),
            tooltip: "Toggle Voice Mode",
            onPressed: () {
              setState(() {
                _voiceModeEnabled = !_voiceModeEnabled;
                if (!_voiceModeEnabled) _flutterTts.stop();
              });
            },
          ),
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
                    // Mic Button
                    GestureDetector(
                      onTap: _listen,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.redAccent : cream,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.white : darkPurple,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? "Listening..."
                                : "Type a message...",
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
