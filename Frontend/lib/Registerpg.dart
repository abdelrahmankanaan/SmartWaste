import 'package:flutter/material.dart';
import 'package:senior_project/gotoapp.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Registerpg extends StatefulWidget {
  Registerpg({Key? key}) : super(key: key);

  @override
  _RegisterpgState createState() => _RegisterpgState();
}

class _RegisterpgState extends State<Registerpg> {
  final String apiUrl = "http://127.0.0.1:8000";

  String? selectedValue = "Sign up";
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  Widget buildButtonChild() {
    if (isLoading) {
      return CircularProgressIndicator(color: Colors.white);
    } else {
      return Icon(Icons.app_registration);
    }
  }


  Future<void> _handleAuth() async {
    if (txtEmail.text.trim().isEmpty || txtPassword.text.isEmpty) {
      setState(() {
        errorMessage = 'Email and password must not be empty.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      if (selectedValue == 'Sign up') {
        await _registerUser();
      } else {
        await _loginUser();
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => gotoapp()),
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _registerUser() async {
    final response = await http.post(
      Uri.parse('$apiUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': txtEmail.text,
        'email': txtEmail.text,
        'password': txtPassword.text,
      }),
    );

    if (response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Registration failed');
    }
  }

  Future<void> _loginUser() async {
    final response = await http.post(
      Uri.parse('$apiUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': txtEmail.text,
        'password': txtPassword.text,
        'grant_type': 'password',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed. Please check your credentials.');
    }

    final tokenData = json.decode(response.body);
  }

  @override
  void dispose() {
    txtEmail.dispose();
    txtPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart waste"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Center(
          child: Column(
            children: [
              SizedBox(height: 10),
              SizedBox(height: 60, width: 300, child: TextField(
                  controller: txtEmail,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    labelText: "Enter your E-mail:",
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(height: 60, width: 300, child: TextField(
                  controller: txtPassword,
                  obscureText: true,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    labelText: "Enter your Password:",
                  ),
                ),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedValue,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedValue = newValue;
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: "Sign up",
                    child: Text("Sign up"),
                  ),
                  DropdownMenuItem(
                    value: "Sign in",
                    child: Text("Sign in"),
                  ),
                ],
              ),
              SizedBox(height: 5),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (!isLoading) {
                    _handleAuth();
                  }
                },
                child: buildButtonChild(),
              )

            ],
          ),
      ),
    );
  }
}