import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'password_reset_screen.dart';


class PasswordRecoveryScreen extends StatefulWidget {
  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final emailController = TextEditingController();

  Future<void> sendPasswordRecoveryRequest(String email) async {
    final url = Uri.parse('http://80.90.187.60:8001/api/auth/reset-request/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      // Logging response content to console
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Navigate to the confirmation code screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetScreen(),
          ),
        );
      } else if (response.statusCode == 400) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Такой почты не существует')),
        );
      } else {
        // Handle other status codes or errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла ошибка. Пожалуйста, попробуйте позже.')),
        );
      }
    } catch (e) {
      // Handle network or server errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF48FB1),
      appBar: AppBar(
        title: Text('Music Trainee'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Восстановление пароля',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48.0),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Электронная почта',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    child: Text('Восстановить'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFF48FB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        side: BorderSide(color: Colors.white),
                      ),
                    ),
                    onPressed: () {
                        sendPasswordRecoveryRequest(emailController.text);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PasswordResetScreen()),
                      );
                    },

                  ),
                ),
              ],
            ),
            Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
