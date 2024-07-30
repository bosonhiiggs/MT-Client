import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'change_password_page.dart';

class VerifyCodePage extends StatefulWidget {
  @override
  _VerifyCodePageState createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  TextEditingController _codeController = TextEditingController();
  String email = '';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
    _sendVerificationCode();
  }

  Future<void> _fetchUserEmail() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      final response = await http.get(
        Uri.parse('http://80.90.187.60:8001/api/auth/aboutme/'),
        headers: {
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
        },
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData);
        setState(() {
          email = data['email'];
        });
      } else {
        print('Не удалось загрузить данные пользователя. Код статуса: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Не удалось загрузить данные пользователя');
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      throw Exception('Не удалось загрузить данные пользователя');
    }
  }

  Future<void> _sendVerificationCode() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      final response = await http.post(
        Uri.parse('http://80.90.187.60:8001/api/auth/send_verification_code/'),
        headers: {
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        print('Не удалось отправить код подтверждения. Код статуса: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Не удалось отправить код подтверждения');
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      throw Exception('Не удалось отправить код подтверждения');
    }
  }

  Future<void> _verifyCode() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      final response = await http.post(
        Uri.parse('http://80.90.187.60:8001/api/auth/verify_code/'),
        headers: {
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({'code': _codeController.text}),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChangePasswordPage()),
        );
      } else {
        setState(() {
          errorMessage = 'Неправильный код';
        });
        print('Не удалось подтвердить код. Код статуса: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Не удалось подтвердить код');
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      throw Exception('Не удалось подтвердить код');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Подтверждение кода'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Вам отправлен код подтверждения на почту $email',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Введите код',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _verifyCode,
                child: Text('Далее'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFF48FB1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
