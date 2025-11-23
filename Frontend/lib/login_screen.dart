import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = "";

  Future<void> _authenticate(String endpoint) async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatPage(username: username)),
        );
      } else {
        final data = json.decode(response.body);
        setState(
          () => _errorMessage = data["error"] ?? "Authentication failed",
        );
      }
    } catch (e) {
      setState(() => _errorMessage = "Failed to connect to server");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _authenticate("login"),
                  child: Text("Login"),
                ),
                OutlinedButton(
                  onPressed: () => _authenticate("signup"),
                  child: Text("Sign Up"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
