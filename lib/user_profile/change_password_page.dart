import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main_pages/profile_page.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _changePassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      final response = await http.post(
        Uri.parse('http://80.90.187.60:8001/api/auth/change_password/'),
        headers: {
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'new_password': _newPasswordController.text,
          'confirm_password': _confirmPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      } else {
        print('Не удалось изменить пароль. Код статуса: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Не удалось изменить пароль');
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      throw Exception('Не удалось изменить пароль');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Смена пароля'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                hintText: 'Новый пароль',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                hintText: 'Подтвердите пароль',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Сохранить'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFF48FB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
